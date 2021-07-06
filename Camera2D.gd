extends Camera2D


const SPEED = 25

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var fps = Engine.get_frames_per_second()
	get_node("Label").text = "FPS: " + str(fps)
	
	var is_moved = false
	if Input.is_key_pressed(KEY_A): # A
		global_position.x -= SPEED
		is_moved = true

	if Input.is_key_pressed(KEY_D): # D
		global_position.x += SPEED
		is_moved = true
		
	if Input.is_key_pressed(KEY_W): # W
		global_position.y -= SPEED
		is_moved = true
		
	if Input.is_key_pressed(KEY_S): # S
		global_position.y += SPEED
		is_moved = true
		
	if is_moved:
		get_parent().move_selected(get_global_mouse_position() + offset)
		
func _input(event):
	var offset = Vector2(global_position.x, global_position.y)
	
	if event is InputEventMouseButton and event.is_pressed():
		if event.get_button_index() == 1:
			get_parent().select_dot(event.position + offset)
			
	if event is InputEventMouseMotion:
		get_parent().move_selected(event.position + offset)
