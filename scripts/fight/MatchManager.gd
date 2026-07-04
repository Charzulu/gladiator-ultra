# scripts/fight/MatchManager.gd
# Orchestrates a fight between two fighters.
# Manages round timer, scoring, fight outcome resolution (KO/TKO/SUB/DEC).
# Extends Node — attach to the fight scene's root.
extends Node

# ── Round states ──
enum MatchState { PRE_FIGHT, ROUND_ACTIVE, BETWEEN_ROUNDS, POST_FIGHT }

signal match_state_changed(old_state: int, new_state: int)
signal round_started(round_num: int)
signal round_ended(round_num: int, scores: Dictionary)
signal fight_ended(result: Dictionary)  # { winner, method, round, time, scores }
signal timer_updated(time_remaining: float, round_num: int)
signal score_updated(scores: Dictionary)
signal fighter_ko_event(fighter_id: int)  # 0 = fighter1, 1 = fighter2

# ── Configuration ──
@export var rounds_count: int = 3
@export var round_duration: float = 300.0  # 5 minutes in seconds
@export var between_round_duration: float = 60.0  # 1 minute
@export var ko_count: int = 10  # referee count for KO

# ── Fighter references ──
var fighter1_data    # FighterData
var fighter2_data    # FighterData
var fighter1_fsm     # FighterStateMachine
var fighter2_fsm     # FighterStateMachine

# ── Internal state ──
var current_state: int = MatchState.PRE_FIGHT
var current_round: int = 0
var round_timer: float = 0.0
var rest_timer: float = 0.0
var ko_count_timer: float = 0.0
var ko_count_active: bool = false
var ko_count_fighter: int = 0  # which fighter is down

# ── Scoring ──
var judge_scores: Array = []  # [{ 'round': N, 'f1_landed': N, 'f2_landed': N, ... }]

# ── Fight result ──
var fight_result: Dictionary = {}
var _finished: bool = false

# ── Dependencies ──
const _FighterFactory = preload("res://scripts/fighter/FighterFactory.gd")
const _FighterFSM = preload("res://scripts/fighter/FighterStateMachine.gd")

# ──────────────────────────────────────────────────────
# INIT
# ──────────────────────────────────────────────────────

func setup(f1_data, f2_data) -> void:
	"""Initialize the match with two fighters."""
	fighter1_data = f1_data
	fighter2_data = f2_data
	
	# Create FSMs
	fighter1_fsm = _FighterFSM.new(fighter1_data)
	fighter2_fsm = _FighterFSM.new(fighter2_data)
	
	# Cross-link opponents
	fighter1_fsm.opponent_state = fighter2_fsm
	fighter2_fsm.opponent_state = fighter1_fsm
	
	# Connect KO signal
	fighter1_fsm.fighter_ko.connect(_on_fighter_ko.bind(0))
	fighter2_fsm.fighter_ko.connect(_on_fighter_ko.bind(1))
	fighter1_fsm.fighter_stunned.connect(_on_fighter_stunned.bind(0))
	fighter2_fsm.fighter_stunned.connect(_on_fighter_stunned.bind(1))
	
	# Start sequence
	_start_match_prep()

func _start_match_prep() -> void:
	"""Prepare fighters and start round 1 immediately."""
	_reset_fighter_round_states()
	current_round = 0
	_change_state(MatchState.PRE_FIGHT)
	_start_round()

# ──────────────────────────────────────────────────────
# ROUND MANAGEMENT
# ──────────────────────────────────────────────────────

func _start_round() -> void:
	"""Begin the next round."""
	current_round += 1
	round_timer = round_duration
	_reset_fighter_round_states()
	_reset_stamina_for_round()
	_change_state(MatchState.ROUND_ACTIVE)
	round_started.emit(current_round)
	
	# Release fighters from any held state
	if fighter1_fsm.is_knocked_out:
		return  # can't start if fighter is KO'd
	fighter1_fsm._reset_state()
	fighter2_fsm._reset_state()

func _end_round() -> void:
	"""End the current round and score it."""
	var f1_stats = _get_round_stats(0)
	var f2_stats = _get_round_stats(1)
	var round_score = _score_round(f1_stats, f2_stats)
	
	var round_entry = {
		"round": current_round,
		"f1": f1_stats,
		"f2": f2_stats,
		"score": round_score,
	}
	judge_scores.append(round_entry)
	
	round_ended.emit(current_round, round_entry)
	score_updated.emit(_get_total_scores())
	
	if current_round >= rounds_count:
		# Fight goes to decision
		_end_fight("decision")
	else:
		_change_state(MatchState.BETWEEN_ROUNDS)
		rest_timer = between_round_duration
		await get_tree().create_timer(rest_timer).timeout
		_start_round()

func _reset_fighter_round_states() -> void:
	"""Reset round-specific state on both fighters."""
	if fighter1_data:
		fighter1_data.health_pools = fighter1_data.health_pools.duplicate()
		fighter1_data.reset_health()
	if fighter2_data:
		fighter2_data.health_pools = fighter2_data.health_pools.duplicate()
		fighter2_data.reset_health()

func _reset_stamina_for_round() -> void:
	"""Restore stamina between rounds (partial recovery)."""
	if fighter1_data:
		fighter1_data.stamina_state.current = fighter1_data.stamina_state.current * 0.5 + \
			fighter1_data.derived.get("max_stamina", 100.0) * 0.5
		fighter1_data.stamina_state.is_gassed = false
	if fighter2_data:
		fighter2_data.stamina_state.current = fighter2_data.stamina_state.current * 0.5 + \
			fighter2_data.derived.get("max_stamina", 100.0) * 0.5
		fighter2_data.stamina_state.is_gassed = false

# ──────────────────────────────────────────────────────
# MAIN UPDATE LOOP
# ──────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	if _finished:
		return
	
	match current_state:
		MatchState.ROUND_ACTIVE:
			_update_round(delta)
		MatchState.PRE_FIGHT, MatchState.BETWEEN_ROUNDS, MatchState.POST_FIGHT:
			pass

func _update_round(delta: float) -> void:
	# Update both FSMs
	if fighter1_fsm and not fighter1_fsm.is_knocked_out:
		fighter1_fsm.update(delta)
	if fighter2_fsm and not fighter2_fsm.is_knocked_out:
		fighter2_fsm.update(delta)
	
	# Round timer
	round_timer -= delta
	if round_timer <= 0.0:
		round_timer = 0.0
		_end_round()
	
	# KO count timer
	if ko_count_active:
		ko_count_timer -= delta
		if ko_count_timer <= 0.0:
			_ko_count_complete()
	
	timer_updated.emit(round_timer, current_round)

# ──────────────────────────────────────────────────────
# KO / TKO / SUBMISSION HANDLING
# ──────────────────────────────────────────────────────

func _on_fighter_ko(fighter_id: int) -> void:
	"""A fighter has been knocked out."""
	if _finished:
		return
	var winner_id = 1 - fighter_id
	_end_fight("ko", winner_id, fighter_id)

func _on_fighter_stunned(level: int, fighter_id: int) -> void:
	"""Track knockdowns for scoring. Level 5+ = knockdown."""
	if level >= 5 and not _finished:
		# Track knockdown for scoring
		pass  # Scoring tracks via damage stats
	if level == 5:
		# Start 10-count
		_start_ko_count(fighter_id)

func _start_ko_count(fighter_id: int) -> void:
	"""Begin the referee count for a downed fighter."""
	ko_count_active = true
	ko_count_timer = ko_count * 0.1  # 10 count, ~1s per count (ref at 60fps)
	ko_count_fighter = fighter_id

func _ko_count_complete() -> void:
	"""The count has finished — fighter either gets up or is KO'd."""
	ko_count_active = false
	var fsm = fighter1_fsm if ko_count_fighter == 0 else fighter2_fsm
	if fsm and fsm.knockdown_timer > 0.0:
		# Fighter got up during the count — continue
		pass
	else:
		# Fighter didn't get up — TKO
		var winner_id = 1 - ko_count_fighter
		_end_fight("tko", winner_id, ko_count_fighter)

# ──────────────────────────────────────────────────────
# FIGHT END
# ──────────────────────────────────────────────────────

func _end_fight(method: String, winner_id: int = -1, loser_id: int = -1) -> void:
	"""End the fight with a given method."""
	if _finished:
		return
	_finished = true
	_change_state(MatchState.POST_FIGHT)
	
	var winner_data = fighter1_data if winner_id == 0 else fighter2_data if winner_id == 1 else null
	var loser_data = fighter1_data if loser_id == 0 else fighter2_data if loser_id == 1 else null
	
	match method:
		"ko":
			fight_result = {
				"winner": winner_id, "loser": loser_id,
				"winner_name": winner_data.fighter_name if winner_data else "Unknown",
				"loser_name": loser_data.fighter_name if loser_data else "Unknown",
				"method": "KO", "round": current_round,
				"time": round_duration - round_timer,
				"scores": _get_total_scores(),
			}
		"tko":
			fight_result = {
				"winner": winner_id, "loser": loser_id,
				"winner_name": winner_data.fighter_name if winner_data else "Unknown",
				"loser_name": loser_data.fighter_name if loser_data else "Unknown",
				"method": "TKO", "round": current_round,
				"time": round_duration - round_timer,
				"scores": _get_total_scores(),
			}
		"decision":
			var total = _get_total_scores()
			# Determine winner by total score
			if total.f1_score > total.f2_score:
				winner_id = 0; loser_id = 1
			elif total.f2_score > total.f1_score:
				winner_id = 1; loser_id = 0
			else:  # draw
				winner_id = -1; loser_id = -1
			winner_data = fighter1_data if winner_id == 0 else fighter2_data
			loser_data = fighter1_data if loser_id == 0 else fighter2_data
			fight_result = {
				"winner": winner_id, "loser": loser_id,
				"winner_name": winner_data.fighter_name if winner_data else "Draw",
				"loser_name": loser_data.fighter_name if loser_data else "Draw",
				"method": "Decision", "round": current_round,
				"time": round_duration,
				"scores": total,
			}
	
	fight_ended.emit(fight_result)

# ──────────────────────────────────────────────────────
# SCORING
# ──────────────────────────────────────────────────────

func _get_round_stats(fighter_id: int):
	"""Collect stats for scoring this round."""
	var fd = fighter1_data if fighter_id == 0 else fighter2_data
	if not fd: return {}
	
	var total_blunt = 0.0
	var total_sharp = 0.0
	for zone in fd.health_pools:
		total_blunt += fd.health_pools[zone].get("blunt", 0.0)
		total_sharp += fd.health_pools[zone].get("sharp", 0.0)
	
	var knockdowns = 0
	# Approximate knockdowns from health pool changes (round start vs now)
	
	return {
		"total_damage_done": 0.0,  # We'd track this via signals
		"total_damage_taken": total_blunt + total_sharp,
		"knockdowns": 0,
		"stuns_inflicted": 0,
		"control_time": 0.0,
	}

func _score_round(f1_stats: Dictionary, f2_stats: Dictionary) -> Dictionary:
	"""Score a round using 10-9 system. Returns { f1_score: int, f2_score: int, winner: int }."""
	# Default 10-10
	var f1_score = 10
	var f2_score = 10
	
	var f1_dmg = f1_stats.get("total_damage_done", 0.0)
	var f2_dmg = f2_stats.get("total_damage_done", 0.0)
	var f1_kd = f1_stats.get("knockdowns", 0)
	var f2_kd = f2_stats.get("knockdowns", 0)
	
	# Knockdowns heavily influence scoring
	if f1_kd > f2_kd:
		f2_score = max(7, f2_score - (f1_kd - f2_kd))
	if f2_kd > f1_kd:
		f1_score = max(7, f1_score - (f2_kd - f1_kd))
	
	# Damage differential
	if f1_dmg > f2_dmg * 1.5:
		f2_score = max(7, f2_score - 1)
	if f2_dmg > f1_dmg * 1.5:
		f1_score = max(7, f1_score - 1)
	
	# Determine round winner
	var winner = -1  # draw
	if f1_score > f2_score:
		winner = 0
	elif f2_score > f1_score:
		winner = 1
	
	return { "f1_score": f1_score, "f2_score": f2_score, "winner": winner }

func _get_total_scores() -> Dictionary:
	"""Aggregate all round scores."""
	var f1_total = 0
	var f2_total = 0
	for entry in judge_scores:
		f1_total += entry.score.f1_score
		f2_total += entry.score.f2_score
	return { "f1_score": f1_total, "f2_score": f2_total, "rounds": judge_scores.size() }

# ──────────────────────────────────────────────────────
# STATE MACHINE
# ──────────────────────────────────────────────────────

func _change_state(new_state: int) -> void:
	var old = current_state
	current_state = new_state
	match_state_changed.emit(old, new_state)

# ──────────────────────────────────────────────────────
# QUERIES
# ──────────────────────────────────────────────────────

func is_fight_over() -> bool:
	return _finished or current_state == MatchState.POST_FIGHT

func get_time_remaining() -> float:
	return round_timer

func get_current_round() -> int:
	return current_round

func get_fighter_data(id: int):
	return fighter1_data if id == 0 else fighter2_data

func get_fighter_fsm(id: int):
	return fighter1_fsm if id == 0 else fighter2_fsm
