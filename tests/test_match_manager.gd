extends Node3D

func _ready() -> void:
	OS.set_environment("GODOT_SILENCE_ROOT_WARNING", "1")
	
	var _FighterFactory = load("res://scripts/fighter/FighterFactory.gd")
	var _FSM = load("res://scripts/fighter/FighterStateMachine.gd")
	var _MatchManager = load("res://scripts/fight/MatchManager.gd")
	
	print("=".repeat(60))
	print("  GLADIATOR ULTRA — MatchManager Integration Test")
	print("=".repeat(60))
	print("")
	
	var total = 0
	var passed = 0
	
	# ── T1: Scripts load ──
	total += 1
	if _FighterFactory and _FSM and _MatchManager:
		passed += 1; print("[PASS] All scripts loaded")
	else:
		print("[FAIL] Script load failure")
	
	# ── T2: Create two fighters ──
	total += 1
	var f1 = _FighterFactory.create("ivan_drakov")
	var f2 = _FighterFactory.create("kenji_takeshi")
	if f1 and f2 and f1.fighter_name == "Ivan Drakov" and f2.fighter_name == "Kenji Takeshi":
		passed += 1; print("[PASS] Two fighters created: %s vs %s" % [f1.fighter_name, f2.fighter_name])
	else:
		print("[FAIL] Fighter creation")
	
	# ── T3: Setup MatchManager ──
	total += 1
	var match_mgr = _MatchManager.new()
	add_child(match_mgr)
	match_mgr.setup(f1, f2)
	if match_mgr.fighter1_fsm and match_mgr.fighter2_fsm:
		passed += 1; print("[PASS] MatchManager setup: both FSMs exist")
	else:
		print("[FAIL] MatchManager setup")
	
	# ── T4: Initial state ──
	total += 1
	if match_mgr.current_state == _MatchManager.MatchState.ROUND_ACTIVE:
		passed += 1; print("[PASS] Round 1 active")
	elif match_mgr.current_state == _MatchManager.MatchState.PRE_FIGHT:
		# Might still be in pre-fight (1s delay before first round tick)
		passed += 1; print("[PASS] Pre-fight state (1s delay before round start)")
	else:
		print("[FAIL] Initial state: %s" % match_mgr.current_state)
	
	# ── T5: Tick the match for a bit ──
	total += 1
	# Simulate 60 frames of gameplay
	for i in range(60):
		match_mgr._physics_process(1.0 / 60.0)
	
	var round_active = match_mgr.current_state == _MatchManager.MatchState.ROUND_ACTIVE
	if round_active or match_mgr.current_state == _MatchManager.MatchState.POST_FIGHT:
		passed += 1; print("[PASS] Match ticks through 60 frames (state=%s)" % match_mgr.current_state)
	else:
		print("[FAIL] Match state after ticks: %d" % match_mgr.current_state)
	
	# ── T6: Round timer decreased ──
	total += 1
	if match_mgr.round_timer < 300.0 and match_mgr.round_timer >= 0.0:
		passed += 1; print("[PASS] Round timer: %.1f (decreased from 300)" % match_mgr.round_timer)
	else:
		print("[FAIL] Round timer not decreasing: %.1f" % match_mgr.round_timer)
	
	# ── T7: Scoring system ──
	total += 1
	var scores = match_mgr._get_total_scores()
	if scores.has("f1_score") and scores.has("f2_score"):
		passed += 1; print("[PASS] Scoring system ready: f1=%d f2=%d rounds=%d" % [scores.f1_score, scores.f2_score, scores.rounds])
	else:
		print("[FAIL] Scoring system")
	
	# ── T8: Fight outcome query ──
	total += 1
	if match_mgr.is_fight_over() == false:
		passed += 1; print("[PASS] is_fight_over = false (fight ongoing)")
	else:
		print("[FAIL] is_fight_over returned true early")
	
	# ── T9: Fighter data access ──
	total += 1
	var fd0 = match_mgr.get_fighter_data(0)
	var fd1 = match_mgr.get_fighter_data(1)
	if fd0 and fd1 and fd0 == f1 and fd1 == f2:
		passed += 1; print("[PASS] get_fighter_data returns correct fighters")
	else:
		print("[FAIL] get_fighter_data")
	
	# ── T10: FSM access ──
	total += 1
	var fsm0 = match_mgr.get_fighter_fsm(0)
	var fsm1 = match_mgr.get_fighter_fsm(1)
	if fsm0 and fsm1 and fsm0.fighter_data == f1 and fsm1.fighter_data == f2:
		passed += 1; print("[PASS] get_fighter_fsm returns correct FSMs")
	else:
		print("[FAIL] get_fighter_fsm")
	
	print("")
	print("=".repeat(60))
	print("  RESULTS: %d / %d tests passed" % [passed, total])
	print("=".repeat(60))
	
	if not get_parent().has_meta(&"batch_test"):
		get_tree().quit(0 if passed == total else 1)
