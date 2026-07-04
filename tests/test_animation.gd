# tests/test_animation.gd
# Validates: LimbSolver IK, StrikePlanner trajectories, ContactDetector, RecoveryPlanner.
extends Node

var _LimbSolver = null
var _StrikePlanner = null
var _ContactDetector = null
var _RecoveryPlanner = null

func _ready() -> void:
	OS.set_environment("GODOT_SILENCE_ROOT_WARNING", "1")

	print("=".repeat(60))
	print("  GLADIATOR ULTRA — Procedural Animation Tests")
	print("=".repeat(60))
	print("")

	_LimbSolver = load("res://scripts/animation/LimbSolver.gd")
	_StrikePlanner = load("res://scripts/animation/StrikePlanner.gd")
	_ContactDetector = load("res://scripts/animation/ContactDetector.gd")
	_RecoveryPlanner = load("res://scripts/animation/RecoveryPlanner.gd")

	var total = 0
	var passed = 0

	# T1: Scripts load
	total += 1
	if _LimbSolver and _StrikePlanner and _ContactDetector and _RecoveryPlanner:
		passed += 1; print("[PASS] All 4 animation scripts loaded")
	else:
		print("[FAIL] Script loading")

	# T2: FABRIK IK solve — basic reach
	total += 1
	var result = _LimbSolver.solve_two_bone(
		Vector3(0, 1.2, 0),      # shoulder
		Vector3(0.3, 0.8, -0.6),  # target fist position
		Vector3(0, 0, -1),       # elbow hint
		0.3, 0.28,               # upper_len, lower_len (average arm)
		1.0                      # weight
	)
	if result and result.elbow_position.length_squared() > 0:
		passed += 1
		print("[PASS] IK solve: elbow at (%.2f, %.2f, %.2f), reached=%s, ext=%.0f%%" % [
			result.elbow_position.x, result.elbow_position.y, result.elbow_position.z,
			result.reached_target, result.extension_pct * 100
		])
	else:
		print("[FAIL] IK solve returned null or zero elbow")

	# T3: IK — out of reach clamping
	total += 1
	var far_result = _LimbSolver.solve_two_bone(
		Vector3(0, 1.2, 0),
		Vector3(5, 5, -5),  # way too far
		Vector3(0, 0, -1),
		0.3, 0.28
	)
	if not far_result.reached_target and far_result.extension_pct > 0.98:
		passed += 1
		print("[PASS] IK out-of-reach: extension=%.0f%% (clamped to max)" % (far_result.extension_pct * 100))
	else:
		print("[FAIL] IK out-of-reach: extension=%.0f%%, reached=%s" % [far_result.extension_pct * 100, far_result.reached_target])

	# T4: IK — too close clamping
	total += 1
	var close_result = _LimbSolver.solve_two_bone(
		Vector3(0, 1.2, 0),
		Vector3(0, 1.19, 0),  # essentially same point
		Vector3(0, 0, -1),
		0.3, 0.28
	)
	if not close_result.reached_target and close_result.extension_pct < 0.1:
		passed += 1
		print("[PASS] IK too-close: extension=%.0f%% (pushed to min)" % (close_result.extension_pct * 100))
	else:
		print("[FAIL] IK too-close: extension=%.0f%%, reached=%s" % [close_result.extension_pct * 100, close_result.reached_target])

	# T5: StrikePlanner — plan a jab
	total += 1
	var stats = _StrikePlanner.StatsMod.new()
	stats.speed_mult = 1.0; stats.strength_mult = 1.0
	stats.lunge_distance = 1.5
	var jab = _StrikePlanner.plan(0, "head", stats)
	if jab and jab.startup_frames == 3 and jab.base_damage == 5.0 and jab.reach_meters > 1.0:
		passed += 1
		print("[PASS] Jab plan: startup=%d active=%d recover=%d reach=%.2fm dmg=%.1f" % [
			jab.startup_frames, jab.active_frames, jab.recovery_frames, jab.reach_meters, jab.base_damage
		])
	else:
		print("[FAIL] Jab plan: start=%d act=%d rec=%d reach=%.2f dmg=%.1f" % [
			jab.startup_frames, jab.active_frames, jab.recovery_frames, jab.reach_meters, jab.base_damage
		])

	# T6: StrikePlanner — all 10 strike types plan without error
	total += 1
	var all_ok = true
	for st in range(10):
		var p = _StrikePlanner.plan(st, "head", stats)
		if not p or p.stamina_cost <= 0 or p.reach_meters <= 0:
			all_ok = false
			print("[WARN] Strike %d has invalid plan: stamina=%.1f reach=%.2f" % [st, p.stamina_cost if p else -1, p.reach_meters if p else -1])
	if all_ok:
		passed += 1; print("[PASS] All 10 strike types plan correctly")
	else:
		print("[FAIL] Some strikes have invalid plans")

	# T7: StrikePlanner — trajectory evaluation
	total += 1
	var cross = _StrikePlanner.plan(1, "head", stats)
	var t05 = _StrikePlanner.eval_trajectory(cross, 0.5)
	var t10 = _StrikePlanner.eval_trajectory(cross, 1.0)
	if t05.z < 0 and t10.z < 0 and t10.length_squared() > t05.length_squared():
		passed += 1
		print("[PASS] Cross trajectory: t=0.5 → (%.3f, %.3f, %.3f) t=1.0 → (%.3f, %.3f, %.3f)" % [
			t05.x, t05.y, t05.z, t10.x, t10.y, t10.z
		])
	else:
		print("[FAIL] Cross trajectory not extending properly")

	# T8: StrikePlanner — stat-modulated frame data
	total += 1
	var fast_stats = _StrikePlanner.StatsMod.new()
	fast_stats.speed_mult = 0.6  # SPD 90 → 0.6× speed mult
	fast_stats.strength_mult = 1.5
	var fast_jab = _StrikePlanner.plan(0, "head", fast_stats)
	var slow_stats = _StrikePlanner.StatsMod.new()
	slow_stats.speed_mult = 1.6  # SPD 20 → 1.6×
	var slow_jab = _StrikePlanner.plan(0, "head", slow_stats)
	if fast_jab.startup_frames < slow_jab.startup_frames and fast_jab.base_damage > slow_jab.base_damage:
		passed += 1
		print("[PASS] Stat modulation: fast jab=%df startup vs slow jab=%df startup (dmg %.1f vs %.1f)" % [
			fast_jab.startup_frames, slow_jab.startup_frames, fast_jab.base_damage, slow_jab.base_damage
		])
	else:
		print("[FAIL] Stat modulation: fast=%d slow=%d" % [fast_jab.startup_frames, slow_jab.startup_frames])

	# T9: ContactDetector — capsule math
	total += 1
	var hitbox = _ContactDetector.CapsuleHitbox.new(
		Vector3(0, 1.5, 0), Vector3.UP, 0.12, 0.1, "head"
	)
	if hitbox.contains(Vector3(0, 1.5, 0)) and not hitbox.contains(Vector3(0, 2.0, 0)):
		passed += 1
		print("[PASS] Capsule hitbox: center inside, far point outside")
	else:
		print("[FAIL] Capsule hitbox math wrong")

	# T10: ContactDetector — hit detection
	total += 1
	var weapon_pos = Vector3(0.05, 1.48, -0.02)
	var hr = _ContactDetector.check_contact(weapon_pos, Vector3.FORWARD, [hitbox], Vector3.ZERO)
	if hr.hit and hr.zone == "head":
		passed += 1
		print("[PASS] Contact detection: hit zone=%s, penetration=%.3fm" % [hr.zone, hr.penetration_depth])
	else:
		print("[FAIL] Contact detection: hit=%s zone=%s" % [hr.hit, hr.zone])

	# T11: ContactDetector — miss detection
	total += 1
	var miss_pos = Vector3(2.0, 2.0, -2.0)  # far away
	var mr = _ContactDetector.check_contact(miss_pos, Vector3.FORWARD, [hitbox], Vector3.ZERO)
	if not mr.hit:
		passed += 1
		print("[PASS] Miss detection: no hit confirmed")
	else:
		print("[FAIL] Miss detection: incorrectly hit")

	# T12: ContactDetector — swept check (fast punch through capsule)
	total += 1
	var before = Vector3(0.3, 1.5, 0.15)  # outside capsule, approaching
	var after = Vector3(-0.1, 1.5, -0.05) # through capsule, out other side
	var sr = _ContactDetector.check_contact(after, Vector3.FORWARD * 10, [hitbox], before)
	if sr.hit:
		passed += 1
		print("[PASS] Swept check: hit detected (tunnel prevention)")
	else:
		print("[FAIL] Swept check: missed tunnel")

	# T13: RecoveryPlanner — base recovery
	total += 1
	var rec = _RecoveryPlanner.plan(10, null, 1.0, 0, "", null, false)
	if rec.total_frames >= 10:
		passed += 1
		print("[PASS] Base recovery: %d frames" % rec.total_frames)
	else:
		print("[FAIL] Base recovery: %d frames" % rec.total_frames)

	# T14: RecoveryPlanner — stamina penalty
	total += 1
	var low_stam = _RecoveryPlanner.plan(10, null, 0.2, 0, "", null, false)
	if low_stam.total_frames > 10:
		passed += 1
		print("[PASS] Low stamina penalty: %d frames (base=10)" % low_stam.total_frames)
	else:
		print("[FAIL] Low stamina: %d frames" % low_stam.total_frames)

	# T15: RecoveryPlanner — combo chain bonus
	total += 1
	var combo_rec = _RecoveryPlanner.plan(10, null, 1.0, 3, "", null, false)
	var no_combo = _RecoveryPlanner.plan(10, null, 1.0, 0, "", null, false)
	if combo_rec.total_frames < no_combo.total_frames:
		passed += 1
		print("[PASS] Combo chain bonus: %d frames (no-combo=%d)" % [combo_rec.total_frames, no_combo.total_frames])
	else:
		print("[FAIL] Combo chain: %d >= %d" % [combo_rec.total_frames, no_combo.total_frames])

	# T16: RecoveryPlanner — miss penalty
	total += 1
	var miss_rec = _RecoveryPlanner.plan(10, null, 1.0, 0, "", null, true)
	if miss_rec.total_frames > 10:
		passed += 1
		print("[PASS] Miss penalty: %d frames vs %d" % [miss_rec.total_frames, rec.total_frames])
	else:
		print("[FAIL] Miss penalty: %d" % miss_rec.total_frames)

	# T17: StrikePlanner — compute IK target position
	total += 1
	var shoulder = Vector3(0, 1.2, 0)
	var opponent = Vector3(0, 1.5, -1.0)
	var target_pos = _StrikePlanner.compute_target_position(cross, shoulder, opponent, 0.8)
	if target_pos.distance_to(shoulder) > 0.3:
		passed += 1
		print("[PASS] IK target: shoulder→target=%.2fm (reach=%.2fm)" % [
			target_pos.distance_to(shoulder), cross.reach_meters
		])
	else:
		print("[FAIL] IK target too close to shoulder")

	# T18: LimbSolver — solve both arms
	total += 1
	var both = _LimbSolver.solve_both_arms(
		Vector3(-0.2, 1.2, 0), Vector3(-0.1, 0.8, -0.5),
		Vector3(0.2, 1.2, 0), Vector3(0.1, 0.8, -0.5),
		Vector3(0, 0, -1), 0.3, 0.28
	)
	if both.left and both.right:
		passed += 1
		print("[PASS] Dual-arm IK: both arms solved")
	else:
		print("[FAIL] Dual-arm IK returned null")

	print("")
	print("=".repeat(60))
	print("  RESULTS: %d / %d tests passed" % [passed, total])
	print("=".repeat(60))

	if not get_parent().has_meta(&"batch_test"):
		get_tree().quit(0 if passed == total else 1)
