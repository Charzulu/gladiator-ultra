# scripts/autoload/LimbTracker.gd
# Tracks physics-bone positions each frame and calculates limb-tip velocities.
# Provides velocity data to StrikePlanner for physics-driven impact calculation.
# Designed as an autoload (registered in project.godot).
extends Node

# ── Per-bone tracking data ──
class BoneData:
	var bone_name: String
	var limb_type: String  # "fist", "foot", "elbow", "knee", "head"
	var body_side: String  # "left", "right", "center"
	
	var current_position: Vector3 = Vector3.ZERO
	var last_position: Vector3 = Vector3.ZERO
	var velocity: Vector3 = Vector3.ZERO
	var prev_velocity: Vector3 = Vector3.ZERO
	var acceleration: Vector3 = Vector3.ZERO
	var has_data: bool = false
	
	func _init(name: String, type: String, side: String):
		bone_name = name
		limb_type = type
		body_side = side
	
	func update_position(pos: Vector3, delta: float) -> void:
		if has_data:
			last_position = current_position
			current_position = pos
			prev_velocity = velocity
			velocity = (current_position - last_position) / max(delta, 0.0001)
			acceleration = (velocity - prev_velocity) / max(delta, 0.0001)
		else:
			current_position = pos
			last_position = pos
			has_data = true
			velocity = Vector3.ZERO
			acceleration = Vector3.ZERO
	
	func get_tip_speed() -> float:
		return velocity.length()

# ── Skeleton tracking container ──
class SkeletonData:
	var skeleton: Skeleton3D
	var bones: Dictionary = {}  # bone_name -> BoneData
	var is_valid: bool = false
	var _transform_cache: Array = []  # cached global poses
	
	func _init(skel: Skeleton3D):
		skeleton = skel
		is_valid = is_instance_valid(skeleton)

# ── Registry ──
var _skeletons: Dictionary = {}  # int (skeleton instance ID) -> SkeletonData

# ── Autoload setup ──
func _init() -> void:
	set_process_mode(PROCESS_MODE_ALWAYS)
	set_physics_process(true)

# ──────────────────────────────────────────────────────
# PUBLIC API
# ──────────────────────────────────────────────────────

func track_skeleton(skeleton: Skeleton3D, limb_config: Dictionary = {}) -> bool:
	"""Start tracking a Skeleton3D. limb_config maps bone names to limb types.
	
	Example config:
	{
		"RightHand": {"type": "fist", "side": "right"},
		"LeftHand":  {"type": "fist", "side": "left"},
		"RightFoot": {"type": "foot", "side": "right"},
		"LeftFoot":  {"type": "foot", "side": "left"},
		"Head":      {"type": "head", "side": "center"},
	}
	"""
	if not is_instance_valid(skeleton):
		return false
	
	var sid = skeleton.get_instance_id()
	if _skeletons.has(sid):
		return true  # Already tracking
	
	var sd = SkeletonData.new(skeleton)
	
	# If no config provided, auto-detect bones by name pattern
	if limb_config.is_empty():
		limb_config = _auto_detect_bones(skeleton)
	
	for bone_name in limb_config:
		var cfg = limb_config[bone_name]
		var bone_idx = skeleton.find_bone(bone_name)
		if bone_idx >= 0:
			var bd = BoneData.new(bone_name, cfg.get("type", "fist"), cfg.get("side", "center"))
			sd.bones[bone_name] = bd
	
	if sd.bones.is_empty():
		return false
	
	_skeletons[sid] = sd
	# Register for cleanup
	skeleton.tree_exited.connect(_on_skeleton_freed.bind(sid))
	return true

func untrack_skeleton(skeleton: Skeleton3D) -> void:
	"""Stop tracking a skeleton."""
	if not is_instance_valid(skeleton):
		return
	var sid = skeleton.get_instance_id()
	_skeletons.erase(sid)

func get_limb_velocity(skeleton_instance_id: int, bone_name: String) -> Vector3:
	"""Get the current velocity of a tracked limb bone."""
	var sd = _skeletons.get(skeleton_instance_id)
	if not sd or not sd.bones.has(bone_name):
		return Vector3.ZERO
	return sd.bones[bone_name].velocity

func get_limb_tip_position(skeleton: Skeleton3D, bone_name: String) -> Vector3:
	"""Get the current global position of a bone tip."""
	if not is_instance_valid(skeleton):
		return Vector3.ZERO
	var bone_idx = skeleton.find_bone(bone_name)
	if bone_idx < 0:
		return Vector3.ZERO
	# Read pose position directly and convert through skeleton transform
	var local_pos = skeleton.get_bone_pose_position(bone_idx)
	return skeleton.to_global(local_pos)

func get_all_velocities(skeleton_instance_id: int) -> Dictionary:
	"""Get all tracked limb velocities for a skeleton. Returns bone_name -> Vector3."""
	var result = {}
	var sd = _skeletons.get(skeleton_instance_id)
	if not sd:
		return result
	for bone_name in sd.bones:
		result[bone_name] = sd.bones[bone_name].velocity
	return result

func get_primary_strike_velocity(skeleton_instance_id: int, stance: int = 0) -> Vector3:
	"""Get the primary strike hand velocity (rear hand for orthodox, lead for southpaw)."""
	var sd = _skeletons.get(skeleton_instance_id)
	if not sd:
		return Vector3.ZERO
	# Orthodox: rear hand = right, Southpaw: rear hand = left
	var rear_side = "right" if stance == 0 else "left"
	var rear_hand_name = _find_bone_by_side(sd, "fist", rear_side)
	if rear_hand_name and sd.bones.has(rear_hand_name):
		return sd.bones[rear_hand_name].velocity
	# Fallback: any fist
	for bone_name in sd.bones:
		if sd.bones[bone_name].limb_type == "fist":
			return sd.bones[bone_name].velocity
	return Vector3.ZERO

# ──────────────────────────────────────────────────────
# MAIN UPDATE
# ──────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	"""Update all tracked bone positions and calculate velocities."""
	var to_remove = []
	
	for sid in _skeletons:
		var sd = _skeletons[sid]
		if not is_instance_valid(sd.skeleton):
			to_remove.append(sid)
			continue
		
		for bone_name in sd.bones:
			var bd = sd.bones[bone_name]
			var bone_idx = sd.skeleton.find_bone(bone_name)
			if bone_idx < 0:
				continue
			
			# Get global position of this bone via pose position + skeleton transform
			var local_pos = sd.skeleton.get_bone_pose_position(bone_idx)
			var global_pos = sd.skeleton.to_global(local_pos)
			
			# Update velocity via delta
			bd.update_position(global_pos, delta)
	
	# Clean up stale references
	for sid in to_remove:
		_skeletons.erase(sid)

# ──────────────────────────────────────────────────────
# INTERNAL HELPERS
# ──────────────────────────────────────────────────────

func _auto_detect_bones(skeleton: Skeleton3D) -> Dictionary:
	"""Auto-detect common bone naming patterns for MMA rigs."""
	var config = {}
	var bone_count = skeleton.get_bone_count()
	
	for i in range(bone_count):
		var name = skeleton.get_bone_name(i).to_lower()
		
		if "hand" in name or "fist" in name or "palm" in name:
			var side = "left" if "left" in name else "right" if "right" in name else "center"
			config[skeleton.get_bone_name(i)] = {"type": "fist", "side": side}
		
		elif "foot" in name or "ankle" in name:
			var side = "left" if "left" in name else "right" if "right" in name else "center"
			config[skeleton.get_bone_name(i)] = {"type": "foot", "side": side}
		
		elif "elbow" in name:
			var side = "left" if "left" in name else "right" if "right" in name else "center"
			config[skeleton.get_bone_name(i)] = {"type": "elbow", "side": side}
		
		elif "knee" in name:
			var side = "left" if "left" in name else "right" if "right" in name else "center"
			config[skeleton.get_bone_name(i)] = {"type": "knee", "side": side}
		
		elif name == "head" or "head" in name:
			if not config.has(skeleton.get_bone_name(i)):
				config[skeleton.get_bone_name(i)] = {"type": "head", "side": "center"}
	
	return config

func _find_bone_by_side(sd: SkeletonData, limb_type: String, side: String) -> String:
	"""Find a tracked bone name matching limb type and side."""
	for bone_name in sd.bones:
		var bd = sd.bones[bone_name]
		if bd.limb_type == limb_type and bd.body_side == side:
			return bone_name
	return ""

func _on_skeleton_freed(sid: int) -> void:
	"""Clean up when a skeleton is freed."""
	_skeletons.erase(sid)

# ── Debug ──
func get_tracked_count() -> int:
	return _skeletons.size()

func get_skeleton_info(skeleton_instance_id: int) -> Dictionary:
	"""Get debug info about tracked skeleton."""
	var sd = _skeletons.get(skeleton_instance_id)
	if not sd:
		return {}
	var info = {}
	for bone_name in sd.bones:
		var bd = sd.bones[bone_name]
		info[bone_name] = {
			"type": bd.limb_type,
			"side": bd.body_side,
			"velocity": bd.velocity,
			"speed": bd.get_tip_speed(),
		}
	return info
