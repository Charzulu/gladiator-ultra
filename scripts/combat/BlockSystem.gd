# scripts/combat/BlockSystem.gd
# UFC 6-accurate block/parry/guard break system.
# RefCounted — attached to each FighterStateMachine.
extends RefCounted

# ── Block types ──
enum BlockType { NONE, HIGH, LOW, PARRY }

# ── Configuration ──
const BLOCK_DAMAGE_REDUCTION_HIGH: float = 0.70  # 70% reduction
const BLOCK_DAMAGE_REDUCTION_LOW: float = 0.50   # 50% reduction
const PARRY_DAMAGE_REDUCTION: float = 1.0        # 100% reduction (no damage)
const STAMINA_PER_HIT_HIGH: float = 1.5
const STAMINA_PER_HIT_LOW: float = 2.0
const STAMINA_PARRY_COST: float = 2.0
const GUARD_BREAK_THRESHOLD: float = 0.0          # stamina at 0 = guard break
const GUARD_BREAK_PENALTY_MULT: float = 0.7       # 70% damage even on block

var fighter_data  # FighterData reference
var current_block: int = BlockType.NONE
var parry_window_active: bool = false
var parry_window_frames: int = 3
var _parry_frames_remaining: int = 0
var is_guard_broken: bool = false
var guard_break_timer: float = 0.0
var guard_break_duration: float = 1.5  # seconds

func _init(fd) -> void:
	fighter_data = fd

func set_block(block_type: int) -> void:
	current_block = block_type
	if block_type == BlockType.PARRY:
		parry_window_active = true
		_parry_frames_remaining = parry_window_frames

func clear_block() -> void:
	current_block = BlockType.NONE
	parry_window_active = false

func update(delta: float) -> void:
	# Guard break recovery
	if is_guard_broken:
		guard_break_timer -= delta
		if guard_break_timer <= 0.0:
			is_guard_broken = false
			guard_break_timer = 0.0
			# Restore small amount of stamina on recovery
			fighter_data.stamina_state.current = max(
				fighter_data.stamina_state.current,
				fighter_data.derived.get("max_stamina", 100.0) * 0.15
			)
	
	# Parry window timeout (counted in frames via delta)
	if parry_window_active and _parry_frames_remaining > 0:
		_parry_frames_remaining -= 1
		if _parry_frames_remaining <= 0:
			parry_window_active = false

func resolve_block(incoming_damage: float, incoming_stamina_damage: float, 
				   target_zone: String, attacker_velocity: Vector3) -> Dictionary:
	"""Returns { mitigated_damage, stamina_damage, guard_broken, parried }"""
	if is_guard_broken:
		return {
			"mitigated_damage": incoming_damage * GUARD_BREAK_PENALTY_MULT,
			"stamina_damage": 0.0,
			"guard_broken": true,
			"parried": false,
		}
	
	match current_block:
		BlockType.NONE:
			return {
				"mitigated_damage": incoming_damage,
				"stamina_damage": 0.0,
				"guard_broken": false,
				"parried": false,
			}
		
		BlockType.HIGH:
			var reduction = BLOCK_DAMAGE_REDUCTION_HIGH
			# Leg kicks bypass high block
			if target_zone in ["left_leg", "right_leg"]:
				reduction = 0.3  # Can't check kicks with high block
			var mitigated = incoming_damage * (1.0 - reduction)
			var stam_cost = STAMINA_PER_HIT_HIGH + incoming_stamina_damage * 0.3
			return _apply_block_cost(mitigated, stam_cost)
		
		BlockType.LOW:
			var reduction = BLOCK_DAMAGE_REDUCTION_LOW
			# Head shots partially bypass low block
			if target_zone == "head":
				reduction = 0.3
			var mitigated = incoming_damage * (1.0 - reduction)
			var stam_cost = STAMINA_PER_HIT_LOW + incoming_stamina_damage * 0.3
			return _apply_block_cost(mitigated, stam_cost)
		
		BlockType.PARRY:
			if parry_window_active:
				return {
					"mitigated_damage": 0.0,
					"stamina_damage": STAMINA_PARRY_COST,
					"guard_broken": false,
					"parried": true,
				}
			else:
				# Late parry = no block at all
				return {
					"mitigated_damage": incoming_damage,
					"stamina_damage": 0.0,
					"guard_broken": false,
					"parried": false,
				}
	
	return {
		"mitigated_damage": incoming_damage,
		"stamina_damage": 0.0,
		"guard_broken": false,
		"parried": false,
	}

func _apply_block_cost(mitigated: float, stamina_cost: float) -> Dictionary:
	fighter_data.spend_stamina(stamina_cost)
	# Body shots drain more stamina through block
	var stamina = fighter_data.stamina_state.current
	var guard_broken = stamina <= GUARD_BREAK_THRESHOLD
	if guard_broken:
		is_guard_broken = true
		guard_break_timer = guard_break_duration
	return {
		"mitigated_damage": mitigated,
		"stamina_damage": stamina_cost,
		"guard_broken": guard_broken,
		"parried": false,
	}

func is_blocking() -> bool:
	return current_block in [BlockType.HIGH, BlockType.LOW]
