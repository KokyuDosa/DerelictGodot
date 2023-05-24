extends Node2D

const TILE_SIZE = 16

const HEIGHT = 20
const WIDTH = 40



# Node (Class) References -----------------------------------------------------
@onready var tiles = $ScifiTileSet
#@onready var player = null
#@onready var player = $Player
var player = null

var fovrpas = FOVRPAS.new(Vector2i(WIDTH, HEIGHT))

# Current Map -----------------------------------------------------------------
var map = []


# Game State ------------------------------------------------------------------
var player_pos: Vector2i = Vector2i(0, 0)
var explored_tiles: Array = []
var visible_tiles: Array = []

# Called when the node enters the scene tree for the first time.
func _ready():
	var scene = load("res://Entities/player.tscn")
	player = scene.instantiate()
	add_child(player)
	
	# Build level
	build_level()
	var player_x = 5
	var player_y = 5
	player_pos = Vector2i(player_x, player_y)
	update_visuals()
	
func _input(event):
	if !event.is_pressed():
		return
	
	if event.is_action("left"):
		if not player.flip_h:
			player.flip_h = true
		try_move(-1, 0)
	elif event.is_action("right"):
		if player.flip_h:
			player.flip_h = false
		try_move(1, 0)
	elif event.is_action("up"):
		try_move(0, -1)
	elif event.is_action("down"):
		try_move(0, 1)
	elif event.is_action("enter"):
		try_get_current_tile_data()
		
	elif event.is_action("trackpadclick"):
		print_tile_info()
		var mouse_pos = get_global_mouse_position()
		var tile_position = tiles.local_to_map(mouse_pos)
		print("mouse click at: ", tile_position)
		var transparency = fovrpas.is_transparent(tile_position)
		print("Tile is transparent: ", transparency)


func print_tile_info():
	var clicked_cell = tiles.local_to_map(tiles.get_local_mouse_position())
	var data = tiles.get_cell_tile_data(0, clicked_cell)
	if data:
		print(data.get_custom_data("_tile_name"))
		return data.get_custom_data("_tile_name")
	else:
		return 0


#func _unhandled_input(event):
	#if event is InputEventMouseMotion:
	#	var mouse_pos = get_global_mouse_position()
	#	var tile_position = tiles.local_to_map(mouse_pos)
	#	if tile_position.x >= 0 and tile_position.y >= 0:
	#		print("mouse at: ", tile_position)



func try_move(dx, dy):
	var x = player_pos.x + dx
	var y = player_pos.y + dy
	
	if !determine_collision(x, y):
		player_pos = Vector2i(x, y)
		call_deferred("update_visuals")
		
		# Print player current position for debug purposes.
		print("Current player pos: " + str(player_pos.x) + ", " + str(player_pos.y))
	return
	
func determine_collision(x, y) -> bool:
	var space_state = get_world_2d().direct_space_state
	
	var query = PhysicsRayQueryParameters2D.create(tile_to_pixel_center(player_pos.x, player_pos.y), tile_to_pixel_center(x, y), 1)
	var result = space_state.intersect_ray(query)
	if result.is_empty():
		return false
	else:
		return true


func try_get_current_tile_data() -> TileData:	
	var at_cor = tiles.get_cell_atlas_coords(0, Vector2i(player_pos))
	var tile_data: TileData = tiles.get_cell_tile_data(0, at_cor)
	
	if tile_data:
		return tile_data
	else:
		return


func build_level():
	for i in WIDTH:
		for j in HEIGHT:
			# these are non-walkable tiles
			if i > 10 && i < WIDTH - 10 && j > 5 && j < HEIGHT - 5:
				var current_cell = Vector2i(i, j)
				tiles.set_cell(1, current_cell, 0, Vector2i(7, 4))
				tiles.set_cell(0, current_cell, 0, Vector2i(7, 4))
				fovrpas.set_transparent(current_cell, false)

			# these are walkable tiles
			else:
				tiles.set_cell(1, Vector2i(i, j), 0, Vector2i(6, 0))
				tiles.set_cell(0, Vector2i(i, j), 0, Vector2i(6, 0))
		
	for i in WIDTH:
		tiles.set_cell(1, Vector2i(i, 0), 0, Vector2i(7,4))
		tiles.set_cell(0, Vector2i(i, 0), 0, Vector2i(7,4))

		tiles.set_cell(1, Vector2i(i, HEIGHT - 1), 0, Vector2i(7, 4))
		tiles.set_cell(0, Vector2i(i, HEIGHT - 1), 0, Vector2i(7, 4))
		
		fovrpas.set_transparent(Vector2i(i, 0), false)
		fovrpas.set_transparent(Vector2i(i, HEIGHT - 1), false)

	for j in HEIGHT:
		tiles.set_cell(1, Vector2i(0, j), 0, Vector2i(7, 4))
		tiles.set_cell(0, Vector2i(0, j), 0, Vector2i(7, 4))

		tiles.set_cell(1, Vector2i(WIDTH - 1, j), 0, Vector2i(7, 4))
		tiles.set_cell(0, Vector2i(WIDTH - 1, j), 0, Vector2i(7, 4))
		
		fovrpas.set_transparent(Vector2i(0, j), false)
		fovrpas.set_transparent(Vector2i(WIDTH - 1, j), false)

	# Set the layer of black cells to hide the map on layer 2.
	for i in WIDTH:
		for j in HEIGHT:
			tiles.set_cell(2, Vector2i(i,j), 0, Vector2i(0,0))
		
	# Random cell for collision and occlusion testing.
	tiles.set_cell(1, Vector2i(6, 4), 0, Vector2i(7, 4))
	tiles.set_cell(0, Vector2i(6, 4), 0, Vector2i(7, 4))
	fovrpas.set_transparent(Vector2i(6, 4), false)
	
	tiles.set_cell(1, Vector2i(5, 4), 0, Vector2i(7, 4))
	tiles.set_cell(0, Vector2i(5, 4), 0, Vector2i(7, 4))
	fovrpas.set_transparent(Vector2i(5, 4), false)
	
	tiles.set_cell(1, Vector2i(4, 4), 0, Vector2i(7, 4))
	tiles.set_cell(0, Vector2i(4, 4), 0, Vector2i(7, 4))
	fovrpas.set_transparent(Vector2i(4, 4), false)
	
	tiles.set_cell(1, Vector2i(4, 7), 0, Vector2i(7, 4))
	tiles.set_cell(0, Vector2i(4, 7), 0, Vector2i(7, 4))
	fovrpas.set_transparent(Vector2i(4, 7), false)
	
	tiles.set_cell(1, Vector2i(4, 8), 0, Vector2i(7, 4))
	tiles.set_cell(0, Vector2i(4, 8), 0, Vector2i(7, 4))
	fovrpas.set_transparent(Vector2i(4, 8), false)
	
	tiles.set_cell(1, Vector2i(4, 9), 0, Vector2i(7, 4))
	tiles.set_cell(0, Vector2i(4, 9), 0, Vector2i(7, 4))
	fovrpas.set_transparent(Vector2i(4, 9), false)
	
	call_deferred("update_visuals")



func update_visuals():
	player.position = (player_pos * TILE_SIZE) + (Vector2i.ONE*TILE_SIZE/2)
	
	# Call function to update visible tiles
	set_and_update_visible_tiles()


# Returns the pixel center of a given tile.
func tile_to_pixel_center(x, y):
	return Vector2((x + 0.5) * TILE_SIZE, (y + 0.5) * TILE_SIZE)


# Call this function whenever the tiles a player can see are updated or altered
func set_and_update_visible_tiles() -> void:
	# Set shadow tiles to active using the current visible tiles array, should work
	# fine if we do this before we clear the array during each update
	for tile in visible_tiles:
		tiles.set_cell(1, tile, 0, tiles.get_cell_atlas_coords(0, tile))
	
	# Clears the visible tile array.
	visible_tiles.clear()
	
	# The tile that a player is in is guaranteed to be visible in all circumstances
	visible_tiles.append(player_pos)
	
	# Compute currently visible tiles from FOVAlgorithm class
	fovrpas.clear_in_view()
	fovrpas.compute_field_of_view(player_pos, 7)
	for x in range(fovrpas._size.x):
		for y in range(fovrpas._size.y):
			if(fovrpas.is_in_view(Vector2i(x,y))):
				visible_tiles.append(Vector2i(x,y))

	# Set squares marked as visible to lit status by removing "shadow" tiles
	# in layer 1 of the map, and the undiscovered tiles in layer 2
	for tile in visible_tiles:
		tiles.set_cell(1, tile, -1)
		tiles.set_cell(2, tile, -1)

