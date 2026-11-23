class_name Chain
extends Node2D


var lenght: float = 150.0

@onready var line: Line2D = $Line2D
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

var global_chain_end: Vector2 = Vector2.INF
var chain_visible: bool = false
var chain_removing: bool = false
var grabable: Area2D = null

func throw(direction: Vector2, override_lenght: float = lenght) -> Dictionary:
	var chain_end: Vector2 = direction * override_lenght
	var dic: Dictionary = {}
	
	global_chain_end = chain_end + global_position
	chain_visible = true
	
	# Using raycasts in order to know what was grabbed (or not)
	# Order of priority:
	# - Grabable area (player not inside it)
	# - Grabable area (player inside it)
	# - Terrain
	
	var state := get_world_2d().direct_space_state
	var params := PhysicsRayQueryParameters2D.new()
	params.collision_mask = 8 # grabable layer
	params.collide_with_bodies = false
	params.collide_with_areas = true
	params.hit_from_inside = false
	params.from = global_position
	params.to = global_position + chain_end
	var result := state.intersect_ray(params)
	if not result.is_empty():
		chain_end = result["collider"].global_position - global_position
		dic = {"collision_point": chain_end, "collider": result["collider"], "type": "grabable"}
		global_chain_end = chain_end + global_position
		grabable = result["collider"]
		grabable.get_node("AnimationPlayer").play("grab")
		return dic
	
	state = get_world_2d().direct_space_state
	params = PhysicsRayQueryParameters2D.new()
	params.collision_mask = 8 # grabable layer
	params.collide_with_bodies = false
	params.collide_with_areas = true
	params.hit_from_inside = true
	params.from = global_position
	params.to = global_position + chain_end
	result = state.intersect_ray(params)
	if not result.is_empty():
		chain_end = result["collider"].global_position - global_position
		dic = {"collision_point": chain_end, "collider": result["collider"], "type": "grabable"}
		global_chain_end = chain_end + global_position
		grabable = result["collider"]
		grabable.get_node("AnimationPlayer").play("grab")
		return dic
	
	state = get_world_2d().direct_space_state
	params = PhysicsRayQueryParameters2D.new()
	params.collision_mask = 1
	params.collide_with_bodies = true
	params.collide_with_areas = false
	params.from = global_position
	params.to = global_position + chain_end
	result = state.intersect_ray(params)
	if not result.is_empty():
		chain_end = result["position"] - global_position
		dic = {"collision_point": chain_end, "collider": result["collider"], "type": "ground"}
		global_chain_end = chain_end + global_position
		return dic
	
	return dic


func play_sound() -> void:
	audio_stream_player.pitch_scale = 0.90 + randf_range(-0.05, 0.05)
	audio_stream_player.play()


func _process(delta: float) -> void:
	# Draw chain
	line.clear_points()
	if chain_visible:
		line.add_point(Vector2.ZERO)
		if global_chain_end == Vector2.INF:
			global_chain_end = global_position
		if chain_removing:
			global_chain_end = lerp(global_chain_end, global_position, delta / 0.1)
		line.add_point(global_chain_end - global_position)


func remove_chain() -> void:
	chain_removing = true
	await get_tree().create_timer(0.1).timeout
	chain_removing = false
	chain_visible = false
	if grabable:
		grabable.get_node("AnimationPlayer").play("idle")
		grabable = null
