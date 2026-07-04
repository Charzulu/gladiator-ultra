# scripts/fighter/FighterCharacter.gd
# 3D fighter character with Skeleton3D, IK targets, and collision hitboxes.
# Extends CharacterBody3D for physics movement.
# Wires into LimbTracker for velocity capture and StrikePlanner for IK.
extends CharacterBody3D

# ── Exports ──
@export var fighter_data_ref = null  # FighterData
@export var fighter_fsm_ref = null   # FighterStateMachine

# ── Skeleton ──
var skeleton: Skeleton3D
var bone_indices: Dictionary = {}  # bone_name -> int index

# ── Hitbox areas (one per body zone) ──
var hitbox_head: Area3D
var hitbox_torso: Area3D
var hitbox_left_arm: Area3D
var hitbox_right_arm: Area3D
var hitbox_left_leg: Area3D
var hitbox_right_leg: Area3D

# ── IK target markers ──
var ik_shoulder_l: Marker3D
var ik_elbow_l: Marker3D
var ik_fist_l: Marker3D
var ik_shoulder_r: Marker3D
var ik_elbow_r: Marker3D
var ik_fist_r: Marker3D
var ik_head: Marker3D

# ── LimbTracker limb config ──
var _limb_config: Dictionary = {}

# ── Visual mesh (placeholder) ──
var _visual_root: Node3D

# ── Team color ──
var team: int = 0  # 0=red, 1=blue
var team_color: Color = Color(0.8, 0.2, 0.2)

# ──────────────────────────────────────────────────────
# CONSTRUCTION
# ──────────────────────────────────────────────────────

func _ready() -> void:
	_build_skeleton()
	_build_hitboxes()
	_build_ik_targets()
	_build_visual_mesh()
	_register_with_limb_tracker()
	
	# Apply team color
	_update_team_color()

func _build_skeleton() -> void:
	"""Create the bone hierarchy."""
	skeleton = Skeleton3D.new()
	skeleton.name = "Skeleton"
	add_child(skeleton)
	
	# Define bone hierarchy: [name, parent_index, rest_position, rest_rotation (euler)]
	var bone_defs = [
		["Hips", -1, Vector3(0, 0.85, 0), Vector3.ZERO],
		["Spine", 0, Vector3(0, 0.25, 0), Vector3.ZERO],
		["Chest", 1, Vector3(0, 0.20, 0), Vector3.ZERO],
		["Head", 2, Vector3(0, 0.20, 0), Vector3.ZERO],
		["LeftUpperArm", 2, Vector3(-0.25, 0.05, 0), Vector3(0, 0, -15)],
		["LeftForearm", 4, Vector3(0, -0.30, 0), Vector3.ZERO],
		["LeftHand", 5, Vector3(0, -0.25, 0), Vector3.ZERO],
		["RightUpperArm", 2, Vector3(0.25, 0.05, 0), Vector3(0, 0, 15)],
		["RightForearm", 7, Vector3(0, -0.30, 0), Vector3.ZERO],
		["RightHand", 8, Vector3(0, -0.25, 0), Vector3.ZERO],
		["LeftUpperLeg", 0, Vector3(-0.10, -0.45, 0), Vector3.ZERO],
		["LeftLowerLeg", 10, Vector3(0, -0.45, 0), Vector3.ZERO],
		["LeftFoot", 11, Vector3(0, -0.40, 0), Vector3(10, 0, 0)],
		["RightUpperLeg", 0, Vector3(0.10, -0.45, 0), Vector3.ZERO],
		["RightLowerLeg", 13, Vector3(0, -0.45, 0), Vector3.ZERO],
		["RightFoot", 14, Vector3(0, -0.40, 0), Vector3(10, 0, 0)],
	]
	
	for def in bone_defs:
		var name = def[0]
		var parent = def[1]
		var pos = def[2]
		var rot_euler = def[3]
		
		var idx = skeleton.get_bone_count()
		skeleton.add_bone(name)
		if parent >= 0:
			skeleton.set_bone_parent(idx, parent)
		
		# Set rest pose
		var rest = Transform3D.IDENTITY
		rest.origin = pos
		rest.basis = Basis.from_euler(rot_euler * deg_to_rad(1.0))
		skeleton.set_bone_rest(idx, rest)
		# Set initial pose to match rest
		skeleton.set_bone_pose_position(idx, pos)
		skeleton.set_bone_pose_rotation(idx, Quaternion.from_euler(rot_euler * deg_to_rad(1.0)))
		
		bone_indices[name] = idx

func _build_hitboxes() -> void:
	"""Create Area3D hitboxes for each body zone."""
	var zone_defs = [
		["head", "Head", Vector3(0, 0.12, 0), 0.12, Vector3(0.10, 0.10, 0.10)],
		["torso", "Chest", Vector3(0, 0.05, 0), 0.15, Vector3(0.18, 0.22, 0.12)],
		["left_arm", "LeftUpperArm", Vector3.ZERO, 0.06, Vector3(0.06, 0.25, 0.06)],
		["right_arm", "RightUpperArm", Vector3.ZERO, 0.06, Vector3(0.06, 0.25, 0.06)],
		["left_leg", "LeftUpperLeg", Vector3.ZERO, 0.08, Vector3(0.08, 0.35, 0.08)],
		["right_leg", "RightUpperLeg", Vector3.ZERO, 0.08, Vector3(0.08, 0.35, 0.08)],
	]
	
	for def in zone_defs:
		var zone_name = def[0]
		var bone_name = def[1]
		var local_pos = def[2]
		var radius = def[3]
		var half_extents = def[4]
		
		var area = Area3D.new()
		area.name = "Hitbox_%s" % zone_name
		add_child(area)
		
		# Position relative to bone (simplified: at skeleton root level)
		area.position = local_pos + _get_bone_world_offset(bone_name)
		
		# Add collision shape (capsule)
		var shape = CapsuleShape3D.new()
		shape.radius = radius
		shape.height = half_extents.y * 2.0
		
		var col = CollisionShape3D.new()
		col.shape = shape
		area.add_child(col)
		
		# Set collision layers/mask
		area.collision_layer = 2  # Layer 2 = hitboxes
		area.collision_mask = 0   # Don't detect anything
		
		# Store reference
		match zone_name:
			"head": hitbox_head = area
			"torso": hitbox_torso = area
			"left_arm": hitbox_left_arm = area
			"right_arm": hitbox_right_arm = area
			"left_leg": hitbox_left_leg = area
			"right_leg": hitbox_right_leg = area

func _build_ik_targets() -> void:
	"""Create Marker3D targets for IK solvers."""
	# Left arm IK chain
	ik_shoulder_l = _make_ik_marker("IK_ShoulderL", bone_indices.get("LeftUpperArm", -1))
	ik_elbow_l = _make_ik_marker("IK_ElbowL", bone_indices.get("LeftForearm", -1))
	ik_fist_l = _make_ik_marker("IK_FistL", bone_indices.get("LeftHand", -1))
	
	# Right arm IK chain
	ik_shoulder_r = _make_ik_marker("IK_ShoulderR", bone_indices.get("RightUpperArm", -1))
	ik_elbow_r = _make_ik_marker("IK_ElbowR", bone_indices.get("RightForearm", -1))
	ik_fist_r = _make_ik_marker("IK_FistR", bone_indices.get("RightHand", -1))
	
	# Head target
	ik_head = _make_ik_marker("IK_Head", bone_indices.get("Head", -1))

func _make_ik_marker(name: String, bone_idx: int) -> Marker3D:
	var m = Marker3D.new()
	m.name = name
	add_child(m)
	# Position at bone rest position
	if bone_idx >= 0:
		m.position = skeleton.get_bone_rest(bone_idx).origin
	return m

func _build_visual_mesh() -> void:
	"""Create placeholder visual meshes for the fighter (low-poly VF1-style)."""
	_visual_root = Node3D.new()
	_visual_root.name = "VisualMeshes"
	add_child(_visual_root)
	
	# Body parts as simple colored box/sphere meshes
	var parts = [
		["Torso", Vector3(0, 0.90, 0), Vector3(0.35, 0.40, 0.20), Color(0.8, 0.7, 0.6)],
		["Head", Vector3(0, 1.28, 0), Vector3(0.15, 0.15, 0.15), Color(0.85, 0.75, 0.65)],
		["LArm", Vector3(-0.35, 0.95, 0), Vector3(0.08, 0.30, 0.08), Color(0.8, 0.7, 0.6)],
		["RArm", Vector3(0.35, 0.95, 0), Vector3(0.08, 0.30, 0.08), Color(0.8, 0.7, 0.6)],
		["LLeg", Vector3(-0.12, 0.45, 0), Vector3(0.10, 0.40, 0.10), Color(0.75, 0.65, 0.55)],
		["RLeg", Vector3(0.12, 0.45, 0), Vector3(0.10, 0.40, 0.10), Color(0.75, 0.65, 0.55)],
	]
	
	for p in parts:
		var mesh = MeshInstance3D.new()
		mesh.name = "Mesh_%s" % p[0]
		mesh.position = p[1]
		
		var box = BoxMesh.new()
		box.size = p[2]
		var mat = StandardMaterial3D.new()
		mat.albedo_color = p[3]
		mat.metallic = 0.0
		mat.roughness = 0.8
		box.material = mat
		mesh.mesh = box
		
		_visual_root.add_child(mesh)

# ──────────────────────────────────────────────────────
# LIMB TRACKER INTEGRATION
# ──────────────────────────────────────────────────────

func _register_with_limb_tracker() -> void:
	"""Register this fighter's skeleton with LimbTracker."""
	_limb_config = {
		"LeftHand": {"type": "fist", "side": "left"},
		"RightHand": {"type": "fist", "side": "right"},
		"LeftFoot": {"type": "foot", "side": "left"},
		"RightFoot": {"type": "foot", "side": "right"},
		"Head": {"type": "head", "side": "center"},
	}
	LimbTracker.track_skeleton(skeleton, _limb_config)

# ──────────────────────────────────────────────────────
# TEAM COLORING
# ──────────────────────────────────────────────────────

func set_team(t: int) -> void:
	team = t
	if t == 0:
		team_color = Color(0.8, 0.2, 0.2)  # Red corner
	else:
		team_color = Color(0.2, 0.3, 0.8)  # Blue corner
	_update_team_color()

func _update_team_color() -> void:
	"""Apply team color to visual meshes."""
	if not _visual_root:
		return
	for child in _visual_root.get_children():
		if child is MeshInstance3D and child.mesh is BoxMesh:
			var mat = child.mesh.material
			if mat is StandardMaterial3D:
				# Tint non-skin parts with team color
				var name = child.name.to_lower()
				if "torso" in name or "leg" in name:
					mat.albedo_color = team_color

# ──────────────────────────────────────────────────────
# HELPERS
# ──────────────────────────────────────────────────────

func _get_bone_world_offset(bone_name: String) -> Vector3:
	"""Get approximate world offset for a bone from rest pose chain."""
	var idx = bone_indices.get(bone_name, -1)
	if idx < 0:
		return Vector3.ZERO
	var pos = Vector3.ZERO
	var current = idx
	while current >= 0:
		var rest = skeleton.get_bone_rest(current)
		pos += rest.origin
		current = skeleton.get_bone_parent(current)
	return pos

func get_limb_velocity(bone_name: String) -> Vector3:
	"""Get current velocity for a tracked limb."""
	return LimbTracker.get_limb_velocity(skeleton.get_instance_id(), bone_name)

func get_primary_strike_velocity() -> Vector3:
	"""Get primary strike velocity based on stance."""
	var stance = 0
	if fighter_data_ref:
		stance = fighter_data_ref.stance
	return LimbTracker.get_primary_strike_velocity(skeleton.get_instance_id(), stance)

# ──────────────────────────────────────────────────────
# FIGHTER POSITION
# ──────────────────────────────────────────────────────

func set_fight_position(pos: Vector3, facing: Vector3 = Vector3.BACK) -> void:
	"""Place the fighter at a position and facing direction."""
	global_position = pos
	# Face the opponent (rotate to face -Z or the given direction)
	if facing != Vector3.ZERO:
		look_at(global_position + facing, Vector3.UP)

func get_fist_position(side: String) -> Vector3:
	"""Get world position of fist tip."""
	var bone = "RightHand" if side == "right" else "LeftHand"
	return LimbTracker.get_limb_tip_position(skeleton, bone)

# ──────────────────────────────────────────────────────
# CLEANUP
# ──────────────────────────────────────────────────────

func _exit_tree() -> void:
	if skeleton and is_instance_valid(skeleton):
		LimbTracker.untrack_skeleton(skeleton)
