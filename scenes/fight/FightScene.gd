# scenes/fight/FightScene.gd
# Main fight scene — arena, fighters, camera, match manager, AI, input.
# Built entirely in code (no .tscn dependency).
extends Node3D

# ── Dependencies ──
const _FighterFactory = preload("res://scripts/fighter/FighterFactory.gd")
const _FighterFSM = preload("res://scripts/fighter/FighterStateMachine.gd")
const _FighterChar = preload("res://scripts/fighter/FighterCharacter.gd")
const _MatchMgr = preload("res://scripts/fight/MatchManager.gd")
const _Cam = preload("res://scripts/camera/FightCamera.gd")
const _AI = preload("res://scripts/ai/AIController.gd")

# ── Fighters ──
var fighter1_data
var fighter2_data
var fighter1_char: Node3D
var fighter2_char: Node3D
var fighter1_fsm
var fighter2_fsm

# ── Systems ──
var match_manager: Node
var fight_camera: Node3D
var ai_controller
var fight_hud: CanvasLayer

# ── Arena ──
var _arena_root: Node3D
var _floor_mesh: MeshInstance3D
var _cage_walls: Array[MeshInstance3D] = []

# ── Config ──
var player_fighter_id: String = "ivan_drakov"
var opponent_fighter_id: String = "kenji_takeshi"
var arena_radius: float = 4.5
var cage_height: float = 1.8

func _ready() -> void:
	OS.set_environment("GODOT_SILENCE_ROOT_WARNING", "1")
	_build_arena()
	_create_fighters()
	_setup_match()
	_setup_camera()
	_setup_ai()
	_setup_hud()
	print("[FightScene] Ready — %s vs %s" % [fighter1_data.fighter_name, fighter2_data.fighter_name])

func _build_arena() -> void:
	_arena_root = Node3D.new()
	_arena_root.name = "Arena"
	add_child(_arena_root)
	
	# Floor — dark grey octagon
	var floor_mesh_instance = MeshInstance3D.new()
	floor_mesh_instance.name = "Floor"
	
	var floor_mesh_geo = CylinderMesh.new()
	floor_mesh_geo.top_radius = arena_radius
	floor_mesh_geo.bottom_radius = arena_radius
	floor_mesh_geo.height = 0.1
	floor_mesh_geo.sides = 8  # octagon
	
	var floor_mat = StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.25, 0.25, 0.27)
	floor_mat.metallic = 0.1
	floor_mat.roughness = 0.9
	floor_mesh_geo.material = floor_mat
	
	floor_mesh_instance.mesh = floor_mesh_geo
	floor_mesh_instance.position = Vector3(0, -0.05, 0)
	_arena_root.add_child(floor_mesh_instance)
	
	# Cage walls — 8 fence panels
	var wall_mat = StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.4, 0.4, 0.42)
	wall_mat.metallic = 0.8
	wall_mat.roughness = 0.3
	
	for i in range(8):
		var angle = (TAU / 8.0) * i - PI / 8.0
		var wall = MeshInstance3D.new()
		wall.name = "CageWall_%d" % i
		
		var wall_mesh = BoxMesh.new()
		wall_mesh.size = Vector3(0.05, cage_height, arena_radius * 0.75)
		wall_mesh.material = wall_mat
		wall.mesh = wall_mesh
		
		wall.position = Vector3(
			sin(angle) * (arena_radius - 0.1),
			cage_height * 0.5,
			cos(angle) * (arena_radius - 0.1)
		)
		wall.rotation.y = -angle
		_arena_root.add_child(wall)
		_cage_walls.append(wall)
	
	# Ambient light
	var ambient = DirectionalLight3D.new()
	ambient.name = "ArenaLight"
	ambient.position = Vector3(5, 8, 5)
	ambient.look_at(Vector3.ZERO)
	_arena_root.add_child(ambient)

func _create_fighters() -> void:
	# Create fighter data
	fighter1_data = _FighterFactory.create(player_fighter_id)
	fighter2_data = _FighterFactory.create(opponent_fighter_id)
	if not fighter1_data or not fighter2_data:
		push_error("FighterFactory returned null")
		return
	
	# Create 3D characters
	fighter1_char = _FighterChar.new()
	fighter1_char.name = "Fighter1_%s" % fighter1_data.fighter_name.replace(" ", "_")
	fighter1_char.fighter_data_ref = fighter1_data
	fighter1_char.set_team(0)  # Red
	fighter1_char.position = Vector3(0, 0, -1.5)
	fighter1_char.set_fight_position(Vector3(0, 0, -1.5), Vector3.FORWARD)
	add_child(fighter1_char)
	
	fighter2_char = _FighterChar.new()
	fighter2_char.name = "Fighter2_%s" % fighter2_data.fighter_name.replace(" ", "_")
	fighter2_char.fighter_data_ref = fighter2_data
	fighter2_char.set_team(1)  # Blue
	fighter2_char.position = Vector3(0, 0, 1.5)
	fighter2_char.set_fight_position(Vector3(0, 0, 1.5), Vector3.BACK)
	add_child(fighter2_char)

func _setup_match() -> void:
	# Create FSMs
	fighter1_fsm = _FighterFSM.new(fighter1_data)
	fighter2_fsm = _FighterFSM.new(fighter2_data)
	fighter1_fsm.opponent_state = fighter2_fsm
	fighter2_fsm.opponent_state = fighter1_fsm
	
	# Wire fighter data to characters
	fighter1_char.fighter_fsm_ref = fighter1_fsm
	fighter2_char.fighter_fsm_ref = fighter2_fsm
	
	# Create match manager
	match_manager = _MatchMgr.new()
	match_manager.name = "MatchManager"
	add_child(match_manager)
	match_manager.setup(fighter1_data, fighter2_data)
	
	# Connect signals
	match_manager.round_started.connect(_on_round_started)
	match_manager.round_ended.connect(_on_round_ended)
	match_manager.fight_ended.connect(_on_fight_ended)
	match_manager.timer_updated.connect(_on_timer_updated)
	
	# KO signals from FSMs → camera shake
	fighter1_fsm.fighter_stunned.connect(_on_stunner.bind(0))
	fighter2_fsm.fighter_stunned.connect(_on_stunner.bind(1))

func _setup_camera() -> void:
	fight_camera = _Cam.new()
	fight_camera.name = "FightCamera"
	add_child(fight_camera)
	fight_camera.setup(fighter1_char, fighter2_char, match_manager)
	
	# Make it the current camera (safe for headless)
	var viewport = get_viewport()
	if viewport and not Engine.is_editor_hint():
		viewport.camera_3d = fight_camera

func _setup_ai() -> void:
	ai_controller = _AI.new(fighter2_fsm, fighter1_fsm, fighter2_data)

func _setup_hud() -> void:
	fight_hud = preload("res://scripts/ui/FightHUD.gd").new()
	fight_hud.name = "FightHUD"
	fight_hud.match_manager = match_manager
	fight_hud.fighter1 = fighter1_data
	fight_hud.fighter2 = fighter2_data
	fight_hud.fighter1_fsm = fighter1_fsm
	fight_hud.fighter2_fsm = fighter2_fsm
	add_child(fight_hud)

# ──────────────────────────────────────────────────────
# GAME LOOP
# ──────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	if not match_manager or match_manager.is_fight_over():
		return
	
	var match_state = match_manager.current_state
	
	# Only tick FSMs during active rounds
	if match_state == _MatchMgr.MatchState.ROUND_ACTIVE:
		# AI tick
		var range_to_opponent = fighter1_char.global_position.distance_to(
			fighter2_char.global_position)
		var ai_action = ai_controller.tick(delta, range_to_opponent)
		_apply_ai_action(ai_action)
		
		# Player input (processed in _input)
		# Both FSMs update
		fighter1_fsm.update(delta)
		fighter2_fsm.update(delta)
		
		# Simple movement toward opponent
		_update_fighter_position(delta)

func _update_fighter_position(delta: float) -> void:
	if not fighter1_char or not fighter2_char:
		return
	
	# Fighter 1 moves toward fighter 2 (simplified — full footwork later)
	var dir = (fighter2_char.global_position - fighter1_char.global_position).normalized()
	var speed = 2.0 * delta
	var new_pos = fighter1_char.global_position + dir * speed
	# Clamp to arena
	new_pos = _clamp_to_arena(new_pos)
	fighter1_char.global_position = new_pos
	
	# Face each other
	fighter1_char.look_at(fighter2_char.global_position, Vector3.UP)
	fighter2_char.look_at(fighter1_char.global_position, Vector3.UP)

func _clamp_to_arena(pos: Vector3) -> Vector3:
	var dist = Vector2(pos.x, pos.z).length()
	if dist > arena_radius - 0.5:
		var ratio = (arena_radius - 0.5) / dist
		pos.x *= ratio
		pos.z *= ratio
	return pos

func _apply_ai_action(action: Dictionary) -> void:
	if not action or action.action == "idle":
		return
	
	match action.action:
		"strike":
			var strike_id = action.params.get("strike_id", "jab")
			var target = action.params.get("target", "head")
			var perfect = action.params.get("perfect", false)
			var strike_type = _strike_name_to_type(strike_id)
			if strike_type >= 0:
				fighter2_fsm.process_action("strike", {
					"type": strike_type, "target": target, "perfect": perfect,
				})
		"block":
			fighter2_fsm.process_action("block_start", {})
			# In a real impl, would call block_system.set_block(HIGH)
		"lunge":
			pass  # Movement handled by physics
		"retreat":
			pass
		"clinch":
			fighter2_fsm.process_action("clinch_entry", {})

func _strike_name_to_type(name: String) -> int:
	match name:
		"jab": return CombatGlobals.StrikeType.JAB
		"cross": return CombatGlobals.StrikeType.CROSS
		"hook": return CombatGlobals.StrikeType.HOOK
		"uppercut": return CombatGlobals.StrikeType.UPPERCUT
		"front_kick": return CombatGlobals.StrikeType.FRONT_KICK
		"roundhouse": return CombatGlobals.StrikeType.ROUNDHOUSE
		"leg_kick": return CombatGlobals.StrikeType.LEG_KICK
		"head_kick": return CombatGlobals.StrikeType.HEAD_KICK
		"knee": return CombatGlobals.StrikeType.KNEE
		"elbow": return CombatGlobals.StrikeType.ELBOW
	return -1

# ──────────────────────────────────────────────────────
# INPUT
# ──────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if not fighter1_fsm or match_manager.is_fight_over():
		return
	
	# WASD movement
	if event.is_action_pressed("move_up") or event.is_action_pressed("move_down") or \
	   event.is_action_pressed("move_left") or event.is_action_pressed("move_right"):
		pass  # Movement handled in physics process
	
	# Strikes
	if event.is_action_pressed("strike_jab"):
		fighter1_fsm.process_action("strike", {"type": CombatGlobals.StrikeType.JAB, "target": "head"})
	if event.is_action_pressed("strike_cross"):
		fighter1_fsm.process_action("strike", {"type": CombatGlobals.StrikeType.CROSS, "target": "head"})
	if event.is_action_pressed("strike_hook"):
		fighter1_fsm.process_action("strike", {"type": CombatGlobals.StrikeType.HOOK, "target": "head"})
	if event.is_action_pressed("strike_kick"):
		fighter1_fsm.process_action("strike", {"type": CombatGlobals.StrikeType.FRONT_KICK, "target": "body"})
	
	# Block
	if event.is_action_pressed("block"):
		fighter1_fsm.process_action("block_start", {})
	if event.is_action_released("block"):
		fighter1_fsm.process_action("block_end", {})
	
	# Takedown
	if event.is_action_pressed("takedown"):
		fighter1_fsm.process_action("takedown_shot", {"type": "double_leg"})

# ──────────────────────────────────────────────────────
# MATCH SIGNALS
# ──────────────────────────────────────────────────────

func _on_round_started(round_num: int) -> void:
	print("[Match] Round %d start!" % round_num)

func _on_round_ended(round_num: int, scores: Dictionary) -> void:
	print("[Match] Round %d end — f1:%d f2:%d" % [round_num, scores.score.f1_score, scores.score.f2_score])

func _on_fight_ended(result: Dictionary) -> void:
	print("[Match] FIGHT OVER — %s wins by %s (R%d)" % [
		result.get("winner_name", "?"), result.get("method", "?"), result.get("round", 0)
	])

func _on_timer_updated(time_remaining: float, round_num: int) -> void:
	pass  # Handled by HUD

func _on_stunner(level: int, fighter_id: int) -> void:
	if level >= 3 and fight_camera and fight_camera.has_method("trigger_shake"):
		fight_camera.trigger_shake(level * 0.15)
