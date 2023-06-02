extends Area2D

var current_pos = Vector2i(0, 0)
var updated_pos = Vector2i(0, 0)

var tile_size = 16
var inputs = {
		"right": Vector2.RIGHT,
		"left": Vector2.LEFT,
		"up": Vector2.UP,
		"down": Vector2.DOWN
}

func _ready():
	position = position.snapped(current_pos)
	print(position)
	# position = position.snapped(Vector2.ONE * tile_size)
	# position += Vector2.ONE * tile_size/2

#func _process(delta):
#	if Input.is_action_just_pressed("right"):
#		updated_pos = current_pos + (inputs["right"]*tile_size)
#		position = Vector2(updated_pos.x, updated_pos.y)
#		current_pos = updated_pos
#		print(updated_pos)

#func _unhandled_input(event):
#	for dir in inputs.keys():
#		if event.is_action_pressed(dir):
#			move(dir)


#func move(dir):
#	ray.target_position = inputs[dir] * tile_size
#	ray.force_raycast_update()
#	if !ray.is_colliding() :
#		position += inputs[dir] * tile_size

