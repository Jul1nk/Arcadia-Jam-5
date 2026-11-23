extends Camera2D

@export var player: Player
@onready var fg_snow: CPUParticles2D = $FGSnow
@onready var bg_snow: CPUParticles2D = $BGSnow
@export var snow_curve: Curve

var current_offset: Vector2 = Vector2.ZERO
func _process(delta: float) -> void:
	global_position = player.global_position
	
	if player.state == player.STATE.IDLE:
		if Input.is_action_pressed("down"):
			current_offset.y = lerp(current_offset.y, 32.0, delta*position_smoothing_speed)
		elif Input.is_action_pressed("up"):
			current_offset.y = lerp(current_offset.y, -32.0, delta*position_smoothing_speed)
		else:
			current_offset.y = lerp(current_offset.y, 0.0, delta*position_smoothing_speed)
	
	elif player.state == player.STATE.JUMPING:
		current_offset.y = lerp(current_offset.y, -32.0, delta*position_smoothing_speed)
	
	elif player.state == player.STATE.FALLING:
		await get_tree().create_timer(0.5).timeout
		if player.state == player.STATE.FALLING:
			current_offset.y = lerp(current_offset.y, 32.0, delta*position_smoothing_speed)
	
	else:
		current_offset.y = lerp(current_offset.y, 0.0, delta*position_smoothing_speed)
	
	if player.state == player.STATE.WALLFALL:
		current_offset.x = lerp(current_offset.x, -sign(player.wall_raycast.target_position.x)*32.0, delta*position_smoothing_speed)
	else:
		current_offset.x = lerp(current_offset.x, sign(player.wall_raycast.target_position.x)*32.0, delta*position_smoothing_speed)
	
	current_offset = current_offset.clamp(
		Vector2(limit_left - get_screen_center_position().x + 320/2.0, limit_top - get_screen_center_position().y + 180/2.0),
		Vector2(limit_right - get_screen_center_position().x - 320/2.0, limit_bottom - get_screen_center_position().y - 180/2.0)
	)
	
	offset = lerp(offset, current_offset, delta*position_smoothing_speed)
	
	offset = offset.clamp(
		Vector2(limit_left - get_screen_center_position().x + 320/2.0, limit_top - get_screen_center_position().y + 180/2.0),
		Vector2(limit_right - get_screen_center_position().x - 320/2.0, limit_bottom - get_screen_center_position().y - 180/2.0)
	)
	
	# The more you climb the more snow the snow is snowing
	var current_snow_amount: float = snow_curve.sample(-global_position.y)
	fg_snow.color_initial_ramp.set_offset(1, clamp(1-current_snow_amount, 0.001, 0.998))
	fg_snow.color_initial_ramp.set_offset(2, clamp(1-current_snow_amount/2.0, 0.002, 0.999))
	fg_snow.gravity.y = 100 + current_snow_amount*150
	bg_snow.color_initial_ramp.set_offset(1, clamp(1-current_snow_amount, 0.001, 0.998))
	bg_snow.color_initial_ramp.set_offset(2, clamp(1-current_snow_amount/2.0, 0.002, 0.999))
	bg_snow.gravity.y = 100 + current_snow_amount*150
