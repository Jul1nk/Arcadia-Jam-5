class_name Player
extends CharacterBody2D


var world: World

static var SPEED: float = 125.0
static var CLIMB_SPEED: float = 50.0
static var JUMP_VELOCITY: float = -200.0
static var DASH_VELOCITY: float = 300.0
static var JUMP_GRAVITY: float = 600.0
static var FALL_GRAVITY: float = 1500.0
static var SLOWFALL_GRAVITY: float = 500.0
static var FASTFALL_GRAVITY: float = 2000.0
static var CLIMB_GRAVITY: float = 0.0
static var WALLFALL_GRAVITY: float = 1000.0

@onready var state_label: Label = $StateLabel
enum STATE {
	IDLE,
	JUMPING,
	FALLING,
	MOVING,
	CLIMBING,
	DASHING,
	WALLFALL,
	WALLJUMP,
}
var state: STATE = STATE.IDLE

var look_direction: Vector2 = Vector2.RIGHT
@onready var visor: Sprite2D = $Visor

@onready var vines_area: Area2D = $VinesArea
@onready var kill_area: Area2D = $KillArea
@onready var chain: Chain = $Chain
@onready var wall_raycast: RayCast2D = $WallRayCast
@onready var grabable_area: Area2D = $GrabableArea

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $Sprite2D/AnimationPlayer

var is_dying: bool = false

func _ready() -> void:
	vines_area.area_entered.connect(_vines_area_entered)
	vines_area.area_exited.connect(_vines_area_exited)
	vines_area.body_entered.connect(_vines_body_entered)
	vines_area.body_exited.connect(_vines_body_exited)
	kill_area.body_entered.connect(kill)
	kill_area.area_entered.connect(kill)
	visor.get_node("AnimationPlayer").play("idle")


func _get_gravity() -> Vector2:
	if state == STATE.JUMPING:
		return Vector2(0, JUMP_GRAVITY)
	if state == STATE.FALLING:
		return Vector2(0, FALL_GRAVITY)
	if state == STATE.CLIMBING:
		return Vector2(0, CLIMB_GRAVITY)
	if state == STATE.WALLFALL:
		return Vector2(0, WALLFALL_GRAVITY)
	return Vector2(0, JUMP_GRAVITY)


var dash_target: Vector2 = Vector2.ZERO
func dash(target: Vector2) -> void:
	chain.play_sound()
	state = STATE.DASHING
	dash_target = target


var buffer_jump: bool = false
var in_coyotee: bool = false
var buffer_chain: bool = false
func remove_jump_buffer() -> void:
	buffer_jump = false
func remove_chain_buffer() -> void:
	buffer_chain = false


func remove_chain() -> void:
	chain.remove_chain()


func _physics_process(delta: float) -> void:
	if is_dying:
		return
	if is_ending:
		velocity += _get_gravity() * delta
		move_and_slide()
		return
	
	var x_direction := Input.get_axis("left", "right")
	var xy_direction := Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down")).normalized()
	
	# Jump buffer
	if Input.is_action_just_pressed("jump"):
		buffer_jump = true
		get_tree().create_timer(0.2).timeout.connect(remove_jump_buffer)
	# Chain buffer
	if Input.is_action_just_pressed("chain"):
		buffer_chain = true
		get_tree().create_timer(0.2).timeout.connect(remove_chain_buffer)
	
	# Chain action and dash
	if buffer_chain:
		remove_chain_buffer()
		var dic := chain.throw(look_direction)
		if not dic.is_empty():
			if dic["type"] == "ground":
				dash(dic["collision_point"])
			elif dic["type"] == "grabable":
				dash(dic["collider"].global_position - global_position)
			if is_on_floor():
				position.y -= 2 # avoid colliding with the floor while dashing
		else:
			remove_chain()
	if state == STATE.DASHING:
		velocity = dash_target.normalized() * DASH_VELOCITY
		if buffer_jump:
			remove_jump_buffer()
			velocity.y = JUMP_VELOCITY
			velocity.x = dash_target.normalized().x * DASH_VELOCITY * 0.75
			state = STATE.JUMPING
			remove_chain()
		else:
			var result := move_and_collide(velocity*delta)
			if result and result.get_collider():
				state = STATE.FALLING
				remove_chain()
			if chain.grabable in grabable_area.get_overlapping_areas():
				state = STATE.FALLING
				remove_chain()
				in_coyotee = true
				get_tree().create_timer(0.1).timeout.connect(func(): in_coyotee = false)
			return

	# Look direction
	if not xy_direction.is_zero_approx():
		look_direction = Vector2.RIGHT.rotated(deg_to_rad(round(rad_to_deg(Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down")).angle()) / 45.0) * 45))
		visor.position = look_direction * 20
		if look_direction.x != 0 and x_direction != 0:
			wall_raycast.target_position.x = sign(look_direction.x) * 10
	else:
		look_direction = wall_raycast.target_position.normalized()
		visor.position = look_direction * 20
	# Wall falling
	if wall_raycast.is_colliding():
		if velocity.y >= 0:
			if xy_direction.x != 0 and sign(xy_direction.x) == sign(wall_raycast.target_position.x):
				state = STATE.WALLFALL
				#remove_chain()
				velocity.y = 0
				look_direction = wall_raycast.get_collision_normal()
				visor.position = look_direction * 20
	else:
		if state == STATE.WALLFALL:
			state = STATE.FALLING
			in_coyotee = true
			get_tree().create_timer(0.1).timeout.connect(func(): in_coyotee = false)
	
	# States
	if can_climb and (
		(Input.is_action_pressed("climb") and state != STATE.JUMPING) or
		(Input.is_action_just_pressed("climb") and state == STATE.JUMPING)):
		state = STATE.CLIMBING
		velocity.y = 0
	if state == STATE.CLIMBING and Input.is_action_just_released("climb"):
		state = STATE.FALLING
	if is_on_floor():
		if velocity.is_zero_approx():
			state = STATE.IDLE
		else:
			state = STATE.MOVING
	
	# Add the gravity.
	if not is_on_floor():
		velocity += _get_gravity() * delta

	# Handle jump.
	if buffer_jump and (is_on_floor() or state == STATE.CLIMBING or in_coyotee):
		remove_jump_buffer()
		velocity.y = JUMP_VELOCITY
		state = STATE.JUMPING
	elif buffer_jump and state == STATE.WALLFALL: # Walljump
		remove_jump_buffer()
		x_direction = sign(-wall_raycast.target_position.x)
		xy_direction.x = x_direction
		xy_direction = xy_direction.normalized()
		velocity.y = JUMP_VELOCITY
		velocity.x = SPEED * sign(-wall_raycast.target_position.x)
		state = STATE.WALLJUMP
		get_tree().create_timer(0.1).timeout.connect(func(): if state == STATE.WALLJUMP: state = STATE.JUMPING)
	if state == STATE.JUMPING and not Input.is_action_pressed("jump"):
		velocity.y *= 0.25
		state = STATE.FALLING
	
	# Movement
	if state != STATE.WALLJUMP:
		if state != STATE.CLIMBING:
			if x_direction:
				if abs(velocity.x) <= abs(x_direction * SPEED) or sign(x_direction) != sign(velocity.x):
					velocity.x = x_direction * SPEED
			else:
				velocity.x = move_toward(velocity.x, 0, SPEED)
		if state == STATE.CLIMBING:
			if xy_direction:
				velocity = xy_direction * CLIMB_SPEED
			else:
				velocity.x = move_toward(velocity.x, 0, CLIMB_SPEED)
				velocity.y = move_toward(velocity.y, 0, CLIMB_SPEED)
		
	if (state == STATE.JUMPING or state == STATE.WALLJUMP) and velocity.y >= 0:
		state = STATE.FALLING
	if state == STATE.MOVING and velocity.y > 0:
		state = STATE.FALLING
		in_coyotee = true
		get_tree().create_timer(0.1).timeout.connect(func(): in_coyotee = false)
	
	
	if state == STATE.FALLING:
		var max_y_velocity: float = 300.0
		if Input.is_action_pressed("down"):
			max_y_velocity = 400.0
	
		velocity.y = min(velocity.y, max_y_velocity)
	
	move_and_slide()


var previous_state: STATE = STATE.IDLE
var previous_velocity: Vector2 = Vector2.ZERO
func _process(delta: float) -> void:
	if is_dying:
		return
	if is_ending:
		animation_player.play("idle")
		return
	state_label.text = STATE.find_key(state)
	
	# Animations
	if state == STATE.IDLE:
		animation_player.play("idle")
	if state == STATE.MOVING:
		animation_player.play("move")
	if state == STATE.JUMPING:
		animation_player.play("jump")
	if state == STATE.FALLING:
		animation_player.play("fall")
	if state == STATE.WALLFALL:
		animation_player.play("wallfall")
	if state == STATE.CLIMBING:
		if velocity.is_zero_approx():
			animation_player.play("climb_idle")
		else:
			animation_player.play("climb_move")
	
	# Land squish
	if state in [STATE.IDLE, STATE.MOVING] and previous_state in [STATE.FALLING]:
		previous_state = state
		var tween := create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.3, 0.5), 0.05)
		tween.parallel().tween_property(sprite, "position:y", 4, 0.05).as_relative()
		await tween.finished
		tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.1)
		tween.parallel().tween_property(sprite, "position:y", -4, 0.1).as_relative()
		await tween.finished
	# Jump squish
	if state in [STATE.JUMPING, STATE.WALLJUMP] and previous_state not in [STATE.JUMPING, STATE.WALLJUMP]:
		previous_state = state
		var tween := create_tween()
		tween.tween_property(sprite, "scale", Vector2(0.5, 1.3), 0.05)
		await tween.finished
		tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.1)
		await tween.finished
	# Move squish
	if state in [STATE.MOVING, STATE.IDLE] and (
		(previous_velocity.x == 0 and velocity.x != 0) or 
		(previous_velocity.x != 0 and velocity.x != 0 and (sign(previous_velocity.x) != sign(velocity.x)))
		):
		
		previous_velocity = velocity
		var tween := create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.1, 0.75), 0.05)
		tween.parallel().tween_property(sprite, "position:y", 2, 0.05).as_relative()
		await tween.finished
		tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.1)
		tween.parallel().tween_property(sprite, "position:y", -2, 0.1)
		await tween.finished
		
		sprite.position = Vector2.ZERO
	
	if velocity.x > 0:
		sprite.flip_h = false
	if velocity.x < 0:
		sprite.flip_h = true
	
	previous_state = state
	previous_velocity = velocity


func kill(_body = null) -> void:
	is_dying = true
	animation_player.play("die")
	await animation_player.animation_finished
	await world.kill_player()
	is_dying = false

var can_climb: bool = false
func _vines_area_entered(_area) -> void:
	_vines_entered()
func _vines_area_exited(_area) -> void:
	_vines_exited()
func _vines_body_entered(_body) -> void:
	_vines_entered()
func _vines_body_exited(_body) -> void:
	_vines_exited()

func _vines_entered() -> void:
	can_climb = true
func _vines_exited() -> void:
	if not vines_area.get_overlapping_areas().is_empty():
		return
	if not vines_area.get_overlapping_bodies().is_empty():
		return
	can_climb = false
	if state == STATE.CLIMBING:
		state = STATE.FALLING
		in_coyotee = true
		get_tree().create_timer(0.05).timeout.connect(func(): in_coyotee = false)


var is_ending: bool = false
func end() -> void:
	velocity = Vector2.ZERO
	is_ending = true
