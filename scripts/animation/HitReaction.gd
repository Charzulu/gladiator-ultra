# scripts/animation/HitReaction.gd
# Procedural hit reaction system — translates stun tiers into bone poses.
# Runs on FighterCharacter's skeleton each physics frame during stun.
extends RefCounted

# ── Per-tier reaction config ──
class ReactionConfig:
	var tier: int
	var head_pitch: float       # degrees
	var head_roll: float
	var chest_pitch: float
	var arm_angle: float        # outward rotation
	var knee_buckle: float      # shin angle increase
	var stumble_distance: float  # meters backward
	var ragdoll_blend: float     # 0.0-1.0 physics blend
	var duration: float          # seconds to complete return

var _active: bool = false
var _current_tier: int = 0
var _elapsed: float = 0.0
var _duration: float = 0.0
var _return_progress: float = 0.0

# ── Bone references ──
var skeleton: Skeleton3D
var _head_bone: int = -1
var _chest_bone: int = -1
var _spine_bone: int = -1
var _l_arm_bone: int = -1
var _r_arm_bone: int = -1
var _l_leg_bone: int = -1
var _r_leg_bone: int = -1

# ── Initial pose storage for return blending ──
var _initial_poses: Dictionary = {}

const TIER_CONFIGS: Dictionary = {
	1: { head_pitch=-15, head_roll=0, chest_pitch=0, arm_angle=0, knee_buckle=0, stumble=0.0, ragdoll=0.0, duration=0.05 },
	2: { head_pitch=-25, head_roll=5, chest_pitch=-5, arm_angle=10, knee_buckle=0, stumble=0.0, ragdoll=0.0, duration=0.15 },
	3: { head_pitch=-35, head_roll=10, chest_pitch=-20, arm_angle=25, knee_buckle=5, stumble=0.0, ragdoll=0.0, duration=0.8 },
	4: { head_pitch=-45, head_roll=15, chest_pitch=-25, arm_angle=35, knee_buckle=10, stumble=0.5, ragdoll=0.4, duration=1.5 },
	5: { head_pitch=-60, head_roll=20, chest_pitch=-30, arm_angle=45, knee_buckle=20, stumble=0.0, ragdoll=1.0, duration=3.0 },
}

func setup(skel: Skeleton3D) -> void:
	skeleton = skel
	if not skeleton: return
	_head_bone = skeleton.find_bone("Head")
	_chest_bone = skeleton.find_bone("Chest")
	_spine_bone = skeleton.find_bone("Spine")
	_l_arm_bone = skeleton.find_bone("LeftUpperArm")
	_r_arm_bone = skeleton.find_bone("RightUpperArm")
	_l_leg_bone = skeleton.find_bone("LeftUpperLeg")
	_r_leg_bone = skeleton.find_bone("RightUpperLeg")

func trigger(tier: int, duration: float) -> void:
	if tier <= 0 or tier > 5: return
	_active = true
	_current_tier = tier
	_duration = duration
	_elapsed = 0.0
	_return_progress = 0.0
	_save_initial_poses()

func _save_initial_poses() -> void:
	_initial_poses = {}
	for bone_idx in [_head_bone, _chest_bone, _spine_bone, _l_arm_bone, _r_arm_bone]:
		if bone_idx >= 0:
			_initial_poses[bone_idx] = {
				"rot": skeleton.get_bone_pose_rotation(bone_idx),
				"pos": skeleton.get_bone_pose_position(bone_idx),
			}

func update(delta: float) -> void:
	if not _active or not skeleton: return
	
	_elapsed += delta
	
	if _elapsed >= _duration:
		_finish_recovery()
		return
	
	var cfg = TIER_CONFIGS.get(_current_tier, TIER_CONFIGS[1])
	var t = _elapsed / _duration
	
	# Apply hit reaction (first 30% of duration)
	if t < 0.3:
		var hit_t = t / 0.3  # 0→1 during hit phase
		_apply_hit_pose(cfg, hit_t)
	# Recovery blend (last 70%)
	else:
		var rec_t = (t - 0.3) / 0.7  # 0→1 during recovery
		_apply_recovery_pose(cfg, rec_t)

func _apply_hit_pose(cfg: Dictionary, t: float) -> void:
	var ease = 1.0 - pow(1.0 - t, 2)  # ease-out quad
	
	if _head_bone >= 0:
		var rot = Quaternion.from_euler(Vector3(
			deg_to_rad(cfg.head_pitch) * ease,
			deg_to_rad(cfg.head_roll) * ease, 0
		))
		skeleton.set_bone_pose_rotation(_head_bone, rot * _initial_poses.get(_head_bone, {}).get("rot", Quaternion.IDENTITY))
	
	if _chest_bone >= 0:
		var rot = Quaternion.from_euler(Vector3(
			deg_to_rad(cfg.chest_pitch) * ease, 0, 0
		))
		skeleton.set_bone_pose_rotation(_chest_bone, rot * _initial_poses.get(_chest_bone, {}).get("rot", Quaternion.IDENTITY))
	
	# Arms drop outward
	for arm in [_l_arm_bone, _r_arm_bone]:
		if arm >= 0:
			var rot = Quaternion.from_euler(Vector3(0, 0, deg_to_rad(cfg.arm_angle) * ease))
			skeleton.set_bone_pose_rotation(arm, rot * _initial_poses.get(arm, {}).get("rot", Quaternion.IDENTITY))

func _apply_recovery_pose(cfg: Dictionary, t: float) -> void:
	var ease = 1.0 - pow(1.0 - t, 3)  # ease-out cubic
	
	for bone_idx in _initial_poses:
		var initial = _initial_poses[bone_idx]
		var current_rot = skeleton.get_bone_pose_rotation(bone_idx)
		var target_rot = initial.rot
		var blended = current_rot.slerp(target_rot, ease * delta * 8.0)
		skeleton.set_bone_pose_rotation(bone_idx, blended)
		
		var current_pos = skeleton.get_bone_pose_position(bone_idx)
		var target_pos = initial.pos
		skeleton.set_bone_pose_position(bone_idx, current_pos.lerp(target_pos, ease * delta * 8.0))

func _finish_recovery() -> void:
	_active = false
	_current_tier = 0
	# Restore all bone poses
	for bone_idx in _initial_poses:
		var data = _initial_poses[bone_idx]
		skeleton.set_bone_pose_rotation(bone_idx, data.rot)
		skeleton.set_bone_pose_position(bone_idx, data.pos)
	_initial_poses = {}

func is_active() -> bool:
	return _active

func get_current_tier() -> int:
	return _current_tier
