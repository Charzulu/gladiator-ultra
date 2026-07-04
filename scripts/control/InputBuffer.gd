# scripts/control/InputBuffer.gd
# Buffers player inputs over a time window for combo detection and denial timing.
# Captures directional inputs + button presses + timestamps.
# The fight state machine queries this to detect combos, denial matches, and special inputs.
extends RefCounted

# ── Buffer entry ──
class InputEntry:
	var action: String = ""
	var data: Dictionary = {}
	var timestamp: float = 0.0
	var directional: Vector2 = Vector2.ZERO

	func _init(a: String, d: Dictionary, t: float, dir: Vector2):
		action = a; data = d; timestamp = t; directional = dir

# ── Configuration ──
var buffer_window: float = 0.4       # seconds to keep entries
var combo_window: float = 0.6        # window for detecting combos
var max_entries: int = 32

# ── State ──
var _entries: Array = []
var _combo_sequence: Array = []

# ── Public API ──

func push(action: String, data: Dictionary = {}, directional: Vector2 = Vector2.ZERO) -> void:
	var now = Time.get_ticks_usec() / 1000000.0
	_entries.append(InputEntry.new(action, data, now, directional))

	if _entries.size() > max_entries:
		_entries.pop_front()

	# Update combo sequence
	_combo_sequence.append(action)
	_prune_combo()

func clear() -> void:
	_entries.clear()
	_combo_sequence.clear()

# ── Queries ──

# Check if a specific action was pressed within the buffer window
func was_pressed(action: String, within: float = -1.0) -> bool:
	var window = within if within > 0.0 else buffer_window
	var now = Time.get_ticks_usec() / 1000000.0
	for entry in _entries:
		if entry.action == action and (now - entry.timestamp) <= window:
			return true
	return false

# Get the most recent entry matching an action
func get_last(action: String) -> InputEntry:
	for i in range(_entries.size() - 1, -1, -1):
		if _entries[i].action == action:
			return _entries[i]
	return null

# Check combo sequence (e.g. ["jab", "cross", "hook"])
func check_combo(sequence) -> bool:
	if _combo_sequence.size() < sequence.size():
		return false
	var start = _combo_sequence.size() - sequence.size()
	for i in range(sequence.size()):
		if _combo_sequence[start + i] != sequence[i]:
			return false
	return true

# Check if a denial should succeed based on direction match
func check_deny(opponent_direction: Vector2) -> bool:
	var now = Time.get_ticks_usec() / 1000000.0
	for entry in _entries:
		if (now - entry.timestamp) > 0.15:  # denial window: 150ms
			continue
		if entry.directional.length_squared() > 0.3:
			var dot = entry.directional.normalized().dot(opponent_direction.normalized())
			if dot > 0.7:  # within 45 degrees
				return true
	return false

# Check if a lunge or dash was input (double-tap LS in a direction)
func check_directional_double_tap(direction: Vector2, threshold: float = 0.7) -> bool:
	if direction.length_squared() < threshold:
		return false
	var now = Time.get_ticks_usec() / 1000000.0
	var count = 0
	var last_time = 0.0
	for entry in _entries:
		if entry.action in ["move"] and (now - entry.timestamp) <= 0.3:
			if entry.directional.length_squared() >= threshold:
				var dot = entry.directional.normalized().dot(direction.normalized())
				if dot > 0.8:
					count += 1
					if count >= 2:
						return true
	return false

# Get the current combo string for debugging
func get_combo_string() -> String:
	return " → ".join(_combo_sequence)

# ── Internal ──

func _prune_combo() -> void:
	var now = Time.get_ticks_usec() / 1000000.0
	# Remove entries outside the combo window from the start
	while _combo_sequence.size() > 1:
		# Find the timestamp of the oldest entry matching the second-to-last action
		var target = _combo_sequence[0]
		var found = false
		for entry in _entries:
			if entry.action == target:
				if (now - entry.timestamp) > combo_window:
					_combo_sequence.pop_front()
					found = true
					break
				found = true
				break
		if not found:
			_combo_sequence.pop_front()
		else:
			break

	# Also prune old entries
	while _entries.size() > 0 and (now - _entries[0].timestamp) > buffer_window:
		_entries.pop_front()
