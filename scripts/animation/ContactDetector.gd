# scripts/animation/ContactDetector.gd
# Detects when a procedural strike's weapon point overlaps the opponent's hitbox.
# Pure math — no Area3D needed. Tracks IK end-effector position vs capsule hitboxes.
extends RefCounted

# ── Contact result ──
class ContactResult:
	var hit: bool = false
	var zone: String = ""
	var impact_point: Vector3 = Vector3.ZERO
	var impact_normal: Vector3 = Vector3.ZERO
	var penetration_depth: float = 0.0
	var limb_velocity: Vector3 = Vector3.ZERO
	var t_at_impact: float = 0.0  # trajectory progress when contact occurred

# ── Hitbox definition (simplified capsule) ──
class CapsuleHitbox:
	var center: Vector3       # world center of capsule
	var direction: Vector3    # unit vector along capsule axis
	var height: float         # distance from center to each end cap center
	var radius: float         # capsule radius
	var zone: String = ""     # "head", "torso", etc.

	func _init(c: Vector3, d: Vector3, h: float, r: float, z: String):
		center = c; direction = d.normalized(); height = h; radius = r; zone = z

	# Check if a point is inside this capsule
	func contains(point: Vector3) -> bool:
		var delta = point - center
		var proj = delta.dot(direction)
		proj = clampf(proj, -height, height)
		var closest = center + direction * proj
		return (point - closest).length_squared() <= radius * radius

	# Get closest point on capsule surface to a point
	func closest_point(point: Vector3) -> Vector3:
		var delta = point - center
		var proj = delta.dot(direction)
		proj = clampf(proj, -height, height)
		var closest = center + direction * proj
		var diff = point - closest
		var dist = diff.length()
		if dist <= 0.0001:
			return point
		return closest + diff.normalized() * radius

	# Distance from point to capsule surface (negative = inside)
	func distance_to(point: Vector3) -> float:
		var delta = point - center
		var proj = delta.dot(direction)
		proj = clampf(proj, -height, height)
		var closest = center + direction * proj
		return (point - closest).length() - radius

# ── Check a single weapon point against all hitboxes ──
static func check_contact(
	weapon_point: Vector3,        # IK end-effector position (fist/foot/knee/elbow)
	weapon_velocity: Vector3,     # current velocity of the weapon point
	hitboxes: Array,              # Array of CapsuleHitbox
	previous_weapon_point: Vector3 # last frame's position (for swept check)
) -> ContactResult:
	var result = ContactResult.new()

	for hb in hitboxes:
		var dist = hb.distance_to(weapon_point)
		if dist <= 0.0:
			# Inside or touching this hitbox
			result.hit = true
			result.zone = hb.zone
			result.impact_point = weapon_point
			result.impact_normal = (weapon_point - hb.closest_point(weapon_point)).normalized()
			result.penetration_depth = -dist
			result.limb_velocity = weapon_velocity
			return result

		# Swept check: did the weapon pass through this capsule between frames?
		if previous_weapon_point != Vector3.ZERO:
			var prev_dist = hb.distance_to(previous_weapon_point)
			if prev_dist > 0.0 and dist < prev_dist:
				# Approaching — check if the line segment between prev and current
				# passes within radius of the capsule
				var closest_on_seg = _closest_point_on_segment(
					previous_weapon_point, weapon_point, hb.center
				)
				var seg_dist = hb.distance_to(closest_on_seg)
				if seg_dist <= 0.0:
					result.hit = true
					result.zone = hb.zone
					result.impact_point = closest_on_seg
					result.limb_velocity = weapon_velocity
					return result

	return result

# ── Build hitbox array from skeleton bone positions ──
static func build_hitboxes(skeleton: Skeleton3D, bone_map: Dictionary) -> Array:
	# bone_map: { zone_name: { bone: "Bone_head", radius: 0.09, height: 0.09, axis: Vector3.UP } }
	var hitboxes: Array = []
	for zone in bone_map.keys():
		var cfg = bone_map[zone]
		var bone_idx = skeleton.find_bone(cfg.bone)
		if bone_idx == -1: continue
		var bone_pos = skeleton.to_global(skeleton.get_bone_pose_position(bone_idx))
		hitboxes.append(CapsuleHitbox.new(
			bone_pos, cfg.get("axis", Vector3.UP),
			cfg.height, cfg.radius, zone
		))
	return hitboxes

# ── Update hitbox positions to follow skeleton ──
static func update_hitbox_positions(hitboxes: Array, skeleton: Skeleton3D, bone_map: Dictionary) -> void:
	var i = 0
	for zone in bone_map.keys():
		if i >= hitboxes.size(): break
		var cfg = bone_map[zone]
		var bone_idx = skeleton.find_bone(cfg.bone)
		if bone_idx == -1: continue
		var bone_pos = skeleton.to_global(skeleton.get_bone_pose_position(bone_idx))
		hitboxes[i].center = bone_pos
		i += 1

# ── Closest point on a line segment ──
static func _closest_point_on_segment(a: Vector3, b: Vector3, p: Vector3) -> Vector3:
	var ab = b - a
	var ap = p - a
	var t = ap.dot(ab) / max(ab.length_squared(), 0.0001)
	t = clampf(t, 0.0, 1.0)
	return a + ab * t
