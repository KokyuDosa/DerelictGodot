"""
Copyright 2023 Nikolas Kanetomi

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

--------------------------------------------------------------------------------

This is an implementation of Restrictive Precise Angle Shadowcasting.

See below link for a description of the algorithm:
https://www.roguebasin.com/index.php?title=Restrictive_Precise_Angle_Shadowcasting

Intended to be used with tile based games for calculating which map tile are
visible from a given entity position on the map.

Usage:
	var map_size = Vector2i(x, y)
	var fovrpas = FOVRPAS.new(map_size)
	
	# Set all opaque cells to false, by default all cells in the map
	# representation are marked as transparent = true
	foreach opaque cell:
		fovrpas.set_transparent(tile, false)
		
	# Whenever visibility would be updated to the following.
	# Clear visible cells
	fovrpas.clear_in_view()
	
	# Update visible cells
	fovrpas.compute_field_of_view(position, vision_radius)
	
	# Check for in_view or not, do appropriate action for your map
	if fovrpas.is_in_view(tile):
		make visible on map, etc
"""

extends RefCounted

class_name FOVRPAS


# Size of the map in tiles. (x, y)
var _size: Vector2i

# Each element of this (instantiated as 2d) array is a bool indicating true if
# it allows unobstructed vision, and false if not.
var _transparent_cells: Array = []

# Each element of this (instantiated as 2d) array is a bool indicating true if
# the tile is currently in view, false if not.
var _fov_cells: Array = []


# Constructor for the object.
func _init(size: Vector2i) -> void:
	_size = size
	
	# Build 2d array for both transparency and field of view. Make it possible to track each tile
	for _x in range(_size.x):
		var transparent_row = []
		var fov_row = []
		
		for _y in range(_size.y):
			transparent_row.push_back(true)
			fov_row.push_back(true)
			
		_transparent_cells.push_back(transparent_row)
		_fov_cells.push_back(fov_row)


func compute_simple_FOV_radius(view_position: Vector2i, view_radius: int) -> Array[Vector2i]:
	# Declare return array.
	var res: Array[Vector2i] = []
	for x in range(_size.x):
		for y in range(_size.y):
			if (x - view_position.x) ** 2 + (y - view_position.y) ** 2 <= view_radius ** 2:
				res.append(Vector2i(x, y))
	return res


func compute_field_of_view(view_position: Vector2i, view_radius: int) -> void:
	# Must compute field of view for each octant. Need to know whether vertical orthogonal octant
	# processing is quadrant 1, 2, 3, or 4.
	
	_process_octant(view_position, view_radius, true, 1, 1)
	_process_octant(view_position, view_radius, false, 1, 1)
	_process_octant(view_position, view_radius, true, 0, 0)
	_process_octant(view_position, view_radius, false, 0, 0)
	_process_octant(view_position, view_radius, true, 0, 1)
	_process_octant(view_position, view_radius, false, 0, 1)
	_process_octant(view_position, view_radius, true, 1, 0)
	_process_octant(view_position, view_radius, false, 1, 0)



# Process the octants depending on whether we're dealing with vertical or
# horizontal orthogonality for an octant.
#
# Now of course what I want is some way to use the various quadrant's x and y signs to change how the values are calculated in the loops
func _process_octant(view_position: Vector2i,
		view_radius: int,
		is_vertical: bool,
		quadrant_x: int,
		quadrant_y: int
		) -> void:

	# track the various occluders that we encounter
	var occluders: Array[Vector2] = []
	var new_occluders: Array[Vector2] = []
	
	
	var j: int					# Declare j in scope
	var j_val: int				# Multiply j * -1 if cartesian quadrant is negative for y values
	var i_val: int				# Multiply i * -1 if cartesian quadrant is negative for x values
	var current_tile: Vector2i	# The current tile being processed
	var num_cells_in_line: int	# Keep track of number of cells in a line
	var angle_range: float		# Angle range per cell in a given line
	var start_angle: float		# Angle at start of cell. Cell number (j) * angle_range
	var end_angle: float		# Angle at end of cell. 
	var mid_angle: float		# Angle at middle of cell
	var angle_half_step: float	# Value to add to angle start to get angle mid
	
	# Declare array for visible cells
	#var visible_cells: Array[Vector2i] = []
	for i in range(1, view_radius + 1): 
		var any_transparent = false	# Flag to use to exit the loop if every cell in a line is opaque
		
		j = 0		# Set the "y axis" value to zero for each new line processed
		i_val = i	# Used for the "x axis" value, set to negative if in quadrant II or III
		if (quadrant_x == 0):
			i_val *= -1
		
		# -----------------------VARIABLES FOR OCCLUSION PROCESSING--------------------------------
		
		# 1) Determine the number of cells in the line being processed. This is equal to i + 1
		num_cells_in_line = i + 1
		
		# 2) Calculate the angle range per cell in a given line.
		angle_range = 1.0 / num_cells_in_line
		
		# -----------------------------------------------------------------------------------------
		
		# Calc clamped range for y values
		# i + 1 is always index of current line operated on + 1
		while (j < i + 1 and j <= view_radius):
			j_val = j	# Used for the "y axis" value, set to negative if in quadrant III or IV
			if (quadrant_y == 0):
				j_val *= -1
			
			# -------------------- calculate the angles of the current cell -----------------------
			# 1) Calculate the slopes of the current cell
			angle_half_step = (angle_range / 2.0)
			start_angle = j * angle_range
			end_angle = start_angle + angle_range
			mid_angle = start_angle + angle_half_step
			
			# 2) Get current tile position, can be checked against the _transparent_cells array
			if is_vertical:
				current_tile = Vector2i(view_position.x + i_val, view_position.y + j_val)
			else:
				current_tile = Vector2i(view_position.x + j_val, view_position.y + i_val)

			# Check if current tile 
			var transparent = is_transparent(current_tile)
			
			if not _is_occluded(occluders, start_angle, angle_half_step, transparent):
				# Not transparent, add the starting and ending angles to the new_occluders array
				set_in_view(current_tile, true)
				
				# This checks if any tile in the current line is transparent, if they are all
				# opaque then we can simply break out of this octant's loop because all
				# subsequent cells will not be in vision.
				if transparent:
					any_transparent = true
					
				# If the cell is opaque we add the starting and ending angles to the occluder list
				else:
					new_occluders.append(Vector2(start_angle, end_angle))
			
			# Increase j count for while loop
			j += 1
			# -------------------------------------------------------------------------------------
			
		if not any_transparent:
			break
			
		occluders.append_array(new_occluders)
		new_occluders.clear()


# Test whether a particular tile is within the bounds of the map
func _in_bounds(position: Vector2) -> bool:
	var x_in_bounds = position.x >= 0 && position.x < _size.x
	var y_in_bounds = position.y >= 0 && position.y < _size.y
	return x_in_bounds && y_in_bounds


# Returns true if the tile at the given position is transparent, else false
func is_transparent(position: Vector2i) -> bool:
	if(_in_bounds(position)):
		return _transparent_cells[position.x][position.y]
	return false


# Sets transparency on the provided tile position
# true = transparent
# false = opaque
func set_transparent(position: Vector2i, transparent: bool) -> void:
	if(_in_bounds(position)):
		_transparent_cells[position.x][position.y] = transparent


# Returns true if a particular cell is currently in view, else false
func is_in_view(position: Vector2i) -> bool:
	if(_in_bounds(position)):
		return _fov_cells[position.x][position.y]
	return false


# Sets whether a particular cell is considered to be "in view" or not
# true = in view
# false = out of view
func set_in_view(position: Vector2i, in_view: bool) -> void:
	if(_in_bounds(position)):
		_fov_cells[position.x][position.y] = in_view


# Clears the array of cells which are currently in view.
# Should be called whenever anything has an effect on a player's visibility.
# Typically called in conjunction with compute_field_of_view.
func clear_in_view() -> void:
	for x in range(_size.x):
		for y in range(_size.y):
			_fov_cells[x][y] = false


# Internal function to determine whether or not a cell is occluded from sight.
#
# For cells which are themselves transparent, require visibility to the mid
# point as well as either of the sides of the cell.
#
# For cells which are not transparent, require only visiblity to one of the
# three tested points.
func _is_occluded(
	occluders: Array,
	angle: float,
	angle_half_step: float,
	transparent: bool
) -> bool:
	
	# the start middle and end angle positions of a cell for
	var start = _is_angle_occluded(occluders, angle)
	var mid = _is_angle_occluded(occluders, angle + angle_half_step)
	var end = _is_angle_occluded(occluders, angle + 2 * angle_half_step)
	
	if not transparent and (not start or not mid or not end):
		return false

	if transparent and not mid and (not start or not end):
		return false

	return true


# Given a list of occluded angle ranges and an angle test test, return
# true if the angle tested is occluded by at least one of the occluders.
func _is_angle_occluded(occluders: Array, angle: float) -> bool:
	for occluder in occluders:
		if angle >= occluder.x and angle <= occluder.y:
			return true
	return false
