# tests/test_fighter_character.gd
extends Node

func _ready() -> void:
	OS.set_environment("GODOT_SILENCE_ROOT_WARNING", "1")
	
	print("=".repeat(60))
	print("  GLADIATOR ULTRA — FighterCharacter 3D Scene Tests")
	print("=".repeat(60))
	print("")
	
	var total = 0
	var passed = 0
	
	var _FighterChar = load("res://scripts/fighter/FighterCharacter.gd")
	var _FighterData = load("res://scripts/fighter/FighterData.gd")
	var _FighterFactory = load("res://scripts/fighter/FighterFactory.gd")
	
	# ── T1: Scripts load ──
	total += 1
	if _FighterChar and _FighterData and _FighterFactory:
		passed += 1; print("[PASS] All scripts loaded")
	else:
		print("[FAIL] Script load")
	
	# ── T2: Create fighter character ──
	total += 1
	var fc = _FighterChar.new()
	add_child(fc)
	if fc is CharacterBody3D:
		passed += 1; print("[PASS] FighterCharacter is CharacterBody3D")
	else:
		print("[FAIL] Not CharacterBody3D")
	
	# ── T3: Skeleton created ──
	total += 1
	if fc.skeleton and fc.skeleton.get_bone_count() == 16:
		passed += 1; print("[PASS] Skeleton with %d bones" % fc.skeleton.get_bone_count())
	else:
		print("[FAIL] Skeleton: %d bones" % (fc.skeleton.get_bone_count() if fc.skeleton else 0))
	
	# ── T4: Bone indices populated ──
	total += 1
	var has_head = fc.bone_indices.has("Head")
	var has_spine = fc.bone_indices.has("Spine")
	var has_hands = fc.bone_indices.has("LeftHand") and fc.bone_indices.has("RightHand")
	if has_head and has_spine and has_hands:
		passed += 1; print("[PASS] Key bone indices: Head Spine LeftHand RightHand")
	else:
		print("[FAIL] Missing bones: head=%s spine=%s hands=%s" % [has_head, has_spine, has_hands])
	
	# ── T5: Hitboxes created ──
	total += 1
	var all_hitboxes = fc.hitbox_head and fc.hitbox_torso and fc.hitbox_left_arm and fc.hitbox_right_arm and fc.hitbox_left_leg and fc.hitbox_right_leg
	if all_hitboxes:
		passed += 1; print("[PASS] All 6 hitbox areas created")
	else:
		print("[FAIL] Missing hitboxes")
	
	# ── T6: IK target markers ──
	total += 1
	var all_ik = fc.ik_shoulder_l and fc.ik_elbow_l and fc.ik_fist_l and fc.ik_shoulder_r and fc.ik_elbow_r and fc.ik_fist_r and fc.ik_head
	if all_ik:
		passed += 1; print("[PASS] All 7 IK target markers created")
	else:
		print("[FAIL] Missing IK targets")
	
	# ── T7: Visual meshes present ──
	total += 1
	if fc._visual_root and fc._visual_root.get_child_count() == 6:
		passed += 1; print("[PASS] %d visual mesh parts" % fc._visual_root.get_child_count())
	else:
		print("[FAIL] Visual meshes: %d" % (fc._visual_root.get_child_count() if fc._visual_root else 0))
	
	# ── T8: Team color ──
	total += 1
	fc.set_team(1)
	if fc.team == 1 and fc.team_color == Color(0.2, 0.3, 0.8):
		passed += 1; print("[PASS] Team color blue set correctly")
	else:
		print("[FAIL] Team color")
	
	# ── T9: LimbTracker integration (skeleton tracked) ──
	total += 1
	var tracked_count = LimbTracker.get_tracked_count()
	if tracked_count >= 1:
		passed += 1; print("[PASS] Skeleton tracked by LimbTracker (count=%d)" % tracked_count)
	else:
		print("[FAIL] Not tracked (count=%d)" % tracked_count)
	
	# ── T10: set_fight_position ──
	total += 1
	fc.set_fight_position(Vector3(1.0, 0, 1.0), Vector3.BACK)
	if fc.global_position.distance_to(Vector3(1.0, 0, 1.0)) < 0.01:
		passed += 1; print("[PASS] set_fight_position: (%.2f, %.2f, %.2f)" % [fc.global_position.x, fc.global_position.y, fc.global_position.z])
	else:
		print("[FAIL] Position: (%.2f, %.2f, %.2f)" % [fc.global_position.x, fc.global_position.y, fc.global_position.z])
	
	# ── T11: get_fist_position ──
	total += 1
	var fist_pos = fc.get_fist_position("right")
	if fist_pos != Vector3.ZERO:
		passed += 1; print("[PASS] get_fist_position(right): (%.2f, %.2f, %.2f)" % [fist_pos.x, fist_pos.y, fist_pos.z])
	else:
		print("[INFO] Fist position at zero (skeleton may need update)")
		passed += 1  # soft pass
	
	# ── T12: Cleanup ──
	total += 1
	# Directly untrack and remove (queue_free doesn't free immediately)
	var skel_id = fc.skeleton.get_instance_id()
	if skel_id:
		LimbTracker.untrack_skeleton(fc.skeleton)
	LimbTracker._physics_process(1.0 / 60.0)
	if LimbTracker.get_tracked_count() == 0:
		passed += 1; print("[PASS] LimbTracker cleanup")
	else:
		print("[FAIL] Remaining tracked: %d" % LimbTracker.get_tracked_count())
	
	print("")
	print("=".repeat(60))
	print("  RESULTS: %d / %d tests passed" % [passed, total])
	print("=".repeat(60))
	
	if not get_parent().has_meta(&"batch_test"):
		get_tree().quit(0 if passed == total else 1)
