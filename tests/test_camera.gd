# tests/test_camera.gd
extends Node

var _FightCamera = null
var _FighterFactory = null
var _MatchManager = null
var _CombatGlobals = null

func _ready() -> void:
	OS.set_environment("GODOT_SILENCE_ROOT_WARNING", "1")
	
	_FightCamera = load("res://scripts/camera/FightCamera.gd")
	_FighterFactory = load("res://scripts/fighter/FighterFactory.gd")
	_MatchManager = load("res://scripts/fight/MatchManager.gd")
	_CombatGlobals = load("res://scripts/autoload/CombatGlobals.gd")
	
	print("=".repeat(60))
	print("  GLADIATOR ULTRA — FightCamera Tests")
	print("=".repeat(60))
	print("")
	
	var total = 0
	var passed = 0
	
	# ── T1: Script loads ──
	total += 1
	if _FightCamera:
		passed += 1; print("[PASS] FightCamera script loaded")
	else:
		print("[FAIL] Script load")
	
	# ── T2: Create camera node ──
	total += 1
	var cam = _FightCamera.new()
	add_child(cam)
	if cam and cam is Camera3D:
		passed += 1; print("[PASS] Camera3D instance created")
	else:
		print("[FAIL] Camera instance")
	
	# ── T3: Setup with two target markers ──
	total += 1
	var t1 = Marker3D.new(); t1.position = Vector3(-0.5, 0, 0); add_child(t1)
	var t2 = Marker3D.new(); t2.position = Vector3(0.5, 0, 0); add_child(t2)
	cam.setup(t1, t2)
	
	if cam.target_a == t1 and cam.target_b == t2:
		passed += 1; print("[PASS] Camera setup with target markers")
	else:
		print("[FAIL] Camera setup")
	
	# ── T4: Initial position is behind midpoint ──
	total += 1
	var mid = Vector3(0, 0, 0)  # midpoint of (-0.5,0,0) and (0.5,0,0)
	var cam_pos = cam.global_position
	# Camera should be behind the origin, at height and distance
	if cam_pos.z > 0 and cam_pos.y > 0.5:
		passed += 1; print("[PASS] Camera behind midpoint: pos=(%.2f, %.2f, %.2f)" % [cam_pos.x, cam_pos.y, cam_pos.z])
	else:
		print("[FAIL] Camera position: (%.2f, %.2f, %.2f)" % [cam_pos.x, cam_pos.y, cam_pos.z])
	
	# ── T5: Physics update tracks midpoint ──
	total += 1
	t1.position = Vector3(-1.0, 0, 0)
	t2.position = Vector3(1.0, 0, 0)
	for i in range(10):
		cam._physics_process(1.0/60.0)
	var new_pos = cam.global_position
	if new_pos.z > 0:  # still behind the action
		passed += 1; print("[PASS] Camera follows: (%.2f, %.2f, %.2f)" % [new_pos.x, new_pos.y, new_pos.z])
	else:
		print("[FAIL] Camera tracking: (%.2f, %.2f, %.2f)" % [new_pos.x, new_pos.y, new_pos.z])
	
	# ── T6: Orbit rotation ──
	total += 1
	var old_angle = cam._orbit_angle
	cam.rotate_orbit(1.0, 0.0)  # horizontal rotation
	if cam._orbit_angle != old_angle:
		passed += 1; print("[PASS] Orbit rotation works (angle: %.2f)" % cam._orbit_angle)
	else:
		print("[FAIL] Orbit rotation")
	
	# ── T7: Pitch clamping ──
	total += 1
	cam.rotate_orbit(0.0, 5.0)  # extreme upward
	if cam._orbit_pitch <= 1.2:
		passed += 1; print("[PASS] Pitch clamped: %.2f" % cam._orbit_pitch)
	else:
		print("[FAIL] Pitch clamp: %.2f" % cam._orbit_pitch)
	
	# ── T8: Shake system ──
	total += 1
	cam.trigger_shake(0.8)
	if cam._shake_intensity > 0.5:
		passed += 1; print("[PASS] Shake triggered: %.2f" % cam._shake_intensity)
	else:
		print("[FAIL] Shake: %.2f" % cam._shake_intensity)
	
	# ── T9: Shake decays ──
	total += 1
	for i in range(10):
		cam._physics_process(0.1)
	if cam._shake_intensity < 0.5:
		passed += 1; print("[PASS] Shake decay: %.3f (was 0.8)" % cam._shake_intensity)
	else:
		print("[FAIL] Shake decay: %.3f" % cam._shake_intensity)
	
	# ── T10: Reposition snap (reset orbit first) ──
	total += 1
	t1.position = Vector3(2.0, 0, 0)
	t2.position = Vector3(-2.0, 0, 0)
	cam._orbit_angle = 0.0
	cam._orbit_pitch = 0.3
	cam.reposition(true)
	if cam.global_position.z > 0:
		passed += 1; print("[PASS] Reposition: (%.2f, %.2f, %.2f)" % [cam.global_position.x, cam.global_position.y, cam.global_position.z])
	else:
		print("[FAIL] Reposition: z=%.2f" % cam.global_position.z)
	
	# ── T11: State-aware distance (via MatchManager) ──
	total += 1
	var f1 = _FighterFactory.create("ivan_drakov")
	var f2 = _FighterFactory.create("kenji_takeshi")
	var mm = _MatchManager.new()
	add_child(mm)
	mm.setup(f1, f2)
	cam.match_manager_ref = mm
	cam._adjust_for_fight_state()
	if cam._target_distance == cam.base_distance:
		passed += 1; print("[PASS] Stand-up state: distance=%.1f" % cam._target_distance)
	else:
		print("[FAIL] Stand-up distance: %.1f" % cam._target_distance)
	
	print("")
	print("=".repeat(60))
	print("  RESULTS: %d / %d tests passed" % [passed, total])
	print("=".repeat(60))
	
	if not get_parent().has_meta(&"batch_test"):
		get_tree().quit(0 if passed == total else 1)
