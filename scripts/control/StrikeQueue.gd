# scripts/control/StrikeQueue.gd
# Per-fighter input queue. Stores pending attacks and dispatches them
# to the per-limb AttackState as limbs become available.
#
# Integrates with:
#   - AttackState (per-limb phase tracking)
#   - FighterStateMachine (dequeue loop, stun/block drain)
#   - ControlMap / humanInput (queue input routing)
#   - StrikePlanner (combo bonuses)
#   - Combo tree data (combo detection)
extends RefCounted

# ═══════════════════════════════════════════
# SIGNALS
# ═══════════════════════════════════════════
signal move_queued(move_id: String, position: int)
signal move_dequeued(move_id: String, reason: String)
signal combo_detected(combo_id: String, combo_name: String, ender: String, damage_bonus: float)
signal feint_performed(limb: String, move_id: String)

# ═══════════════════════════════════════════
# CONSTANTS
# ═══════════════════════════════════════════

# Max entries the queue can hold (adjusted by SPD)
const MAX_QUEUE_BASE: int = 5

# How long an entry stays valid in the queue (seconds)
const QUEUE_TTL: float = 0.8

# Cancel window: fraction of recovery frames where cancel is allowed
const CANCEL_WINDOW_FRAC: float = 0.6

# Cancel surcharge multiplier on stamina cost
const CANCEL_SURCHARGE: float = 0.3

# Feint cost as fraction of move's base stamina
const FEINT_COST_FRAC: float = 0.4

# Combo detection window (seconds between first and last queued entry)
const COMBO_WINDOW: float = 0.6

# ═══════════════════════════════════════════
# CLASSES
# ═══════════════════════════════════════════

class QueueEntry:
	var move_id: String = ""
	var target_zone: String = "head"
	var modifiers: Dictionary = {}  # { perfect: false, high: false, low: false }
	var timestamp: float = 0.0
	var limb: String = "rightArm"

# Combo tree definition
class ComboDef:
	var id: String = ""
	var sequence: Array[String] = []
	var timing_window: float = 0.6
	var recovery_reduction: float = 0.0
	var damage_bonus: float = 0.0
	var hit_chance_bonus: float = 0.0
	var ender: String = ""

# ═══════════════════════════════════════════
# STATE
# ═══════════════════════════════════════════

var _queue: Array[QueueEntry] = []
var _max_queue: int = 3
var _combo_trees: Dictionary = {}    # id -> ComboDef
var _move_limb_map: Dictionary = {}  # move_id -> limb name

# ═══════════════════════════════════════════
# INIT
# ═══════════════════════════════════════════

func _init() -> void:
	_register_combo_trees()

func update_max_queue(speed_stat: float) -> void:
	# SPD stat directly limits combo length
	# SPD 0-19: 2,  SPD 20-49: 3, SPD 50-74: 4, SPD 75-100: 5
	_max_queue = max(2, min(MAX_QUEUE_BASE, int(speed_stat / 15) + 2))

func register_move_limb(move_id: String, limb: String) -> void:
	_move_limb_map[move_id] = limb

# ═══════════════════════════════════════════
# PUBLIC API — Queue Operations
# ═══════════════════════════════════════════

# Queue a move for execution.
# Returns true if queued successfully, false if rejected.
func queue_move(move_id: String, target_zone: String = "head",
				modifiers: Dictionary = {}) -> bool:
	if not _move_limb_map.has(move_id):
		return false

	var limb = _move_limb_map[move_id]

	# Prevent queueing the same limb twice in a row
	if _queue.size() > 0 and _queue[-1].limb == limb:
		return false

	if _queue.size() >= _max_queue:
		return false  # queue full

	var entry = QueueEntry.new()
	entry.move_id = move_id
	entry.target_zone = target_zone
	entry.modifiers = modifiers
	entry.timestamp = Time.get_ticks_usec() / 1000000.0
	entry.limb = limb

	_queue.append(entry)
	move_queued.emit(move_id, _queue.size() - 1)
	return true

# Dequeue the next executable move.
# Returns a QueueEntry or null if nothing can execute right now.
# If the target limb is in early recovery, performs a recovery cancel.
func dequeue_next(attack_state) -> QueueEntry:
	if _queue.is_empty():
		return null

	var entry = _queue[0]

	# Check TTL — discard stale entries silently
	var now = Time.get_ticks_usec() / 1000000.0
	if now - entry.timestamp > QUEUE_TTL:
		_queue.pop_front()
		move_dequeued.emit(entry.move_id, "expired")
		return dequeue_next(attack_state)  # recurse — check next

	if attack_state.is_limb_available(entry.limb):
		# Normal dispatch — limb is free
		_queue.pop_front()
		move_dequeued.emit(entry.move_id, "dispatched")
		return entry

	# ★ Check for recovery cancel
	var limb_state = attack_state.get_limb_state(entry.limb)
	if limb_state != null and limb_state.phase == CombatGlobals.AttackPhase.RECOVERY:
		var cancel_frames = limb_state.total_recovery_frames * CANCEL_WINDOW_FRAC
		if limb_state.frame_counter < cancel_frames:
			# Cancel recovery into the new move
			attack_state.interrupt_limb(entry.limb)
			_queue.pop_front()
			move_dequeued.emit(entry.move_id, "dispatched_via_cancel")
			# Apply stamina surcharge via the entry's modifiers
			entry.modifiers["cancel_surcharge"] = CANCEL_SURCHARGE
			return entry

	return null  # limb busy, no cancel available

# Drain the queue (on stun, block, knockdown).
func drain(reason: String = "interrupted") -> void:
	for entry in _queue:
		move_dequeued.emit(entry.move_id, reason)
	_queue.clear()

# ═══════════════════════════════════════════
# PUBLIC API — Queries
# ═══════════════════════════════════════════

func is_idle() -> bool:
	return _queue.is_empty()

func peek_next() -> String:
	return _queue[0].move_id if _queue.size() > 0 else ""

func queue_size() -> int:
	return _queue.size()

func get_max_queue() -> int:
	return _max_queue

# Get the next N queued moves for HUD display
func get_next_n(n: int) -> Array[String]:
	var result: Array[String] = []
	for i in range(min(n, _queue.size())):
		result.append(_queue[i].move_id)
	return result

# ═══════════════════════════════════════════
# PUBLIC API — Feint
# ═══════════════════════════════════════════

# Check if any limb can feint (is in WINDUP).
# Returns the limb name that can feint, or empty string.
func get_feintable_limb(attack_state) -> String:
	for limb in ["rightArm", "leftArm", "rightLeg", "leftLeg"]:
		if attack_state.get_phase(limb) == CombatGlobals.AttackPhase.WINDUP:
			return limb
	return ""

# Execute a feint on the given limb.
# Returns the cancelled move_id, or empty string if no feint was possible.
func execute_feint(limb: String, attack_state, fighter_data) -> String:
	if attack_state.get_phase(limb) != CombatGlobals.AttackPhase.WINDUP:
		return ""

	var limb_state = attack_state.get_limb_state(limb)
	if limb_state == null or limb_state.move_data == null:
		return ""

	var cost = limb_state.strike_plan.stamina_cost * FEINT_COST_FRAC
	fighter_data.spend_stamina(cost)
	attack_state.interrupt_limb(limb)

	var move_id = limb_state.move_data.move_id
	feint_performed.emit(limb, move_id)

	# Drain any queued entries for this limb (they're now based on a cancelled action)
	# Actually no — queue is preserved. The next entry on this limb will execute
	# once the limb returns to IDLE (which is immediate after interrupt).

	return move_id

# ═══════════════════════════════════════════
# PUBLIC API — Combo Detection
# ═══════════════════════════════════════════

# Check if dispatch history matches a combo tree.
# Returns the combo definition or null.
func check_combo(dispatch_history: Array[String]) -> ComboDef:
	if dispatch_history.size() < 2:
		return null

	for combo_id in _combo_trees:
		var combo = _combo_trees[combo_id] as ComboDef
		if _matches_suffix(dispatch_history, combo.sequence):
			if combo.ender == "" or combo.ender == dispatch_history[-1]:
				combo_detected.emit(combo.id, combo.id, combo.ender, combo.damage_bonus)
				return combo

	return null

# ═══════════════════════════════════════════
# INTERNAL
# ═══════════════════════════════════════════

func _matches_suffix(history: Array[String], pattern: Array[String]) -> bool:
	if history.size() < pattern.size():
		return false
	var start = history.size() - pattern.size()
	for i in range(pattern.size()):
		if history[start + i] != pattern[i]:
			return false
	return true

func _register_combo_trees() -> void:
	# Level 1 — 2-hit combos
	_add_combo("1-2", ["jab", "cross"], "cross", 0.6, 0.0, 0.05)
	_add_combo("2-3", ["cross", "hook"], "hook", 0.5, 0.0, 0.05)

	# Level 2 — 3-hit combos
	_add_combo("1-2-3", ["jab", "cross", "hook"], "hook", 0.6, 0.10, 0.10)
	_add_combo("1-2-4", ["jab", "cross", "uppercut"], "uppercut", 0.5, 0.10, 0.15)
	_add_combo("1-3-2", ["jab", "hook", "cross"], "cross", 0.5, 0.05, 0.10)

	# Level 3 — 4-hit combos
	_add_combo("1-2-3-5", ["jab", "cross", "hook", "overhand"], "overhand", 0.6, 0.15, 0.20)
	_add_combo("1-2-3-4", ["jab", "cross", "hook", "uppercut"], "uppercut", 0.5, 0.12, 0.15)

	# Kick combos
	_add_combo("low-high", ["leg_kick", "roundhouse"], "roundhouse", 0.6, 0.08, 0.10)
	_add_combo("teep-cross", ["front_kick", "cross"], "cross", 0.7, 0.08, 0.0)
	_add_combo("double-kick", ["front_kick", "head_kick"], "head_kick", 0.5, 0.12, 0.20)

	# Strike → Takedown
	_add_combo("jab-shot", ["jab", "double_leg"], "double_leg", 0.5, 0.0, 0.0)
	_add_combo("cross-shot", ["cross", "single_leg"], "single_leg", 0.5, 0.0, 0.0)

func _add_combo(id: String, sequence: Array[String], ender: String,
				window: float, recovery_red: float, dmg_bonus: float) -> void:
	var c = ComboDef.new()
	c.id = id
	c.sequence = sequence
	c.ender = ender
	c.timing_window = window
	c.recovery_reduction = recovery_red
	c.damage_bonus = dmg_bonus
	_combo_trees[id] = c
