# scripts/progression/MoveChallengeDatabase.gd
# Challenge definitions per move/category. Challenges give large XP bursts.
# Conditions tracked via report_combat_event in FighterStateMachine.
extends RefCounted

class MoveChallenge:
	var challenge_id: String
	var display_name: String
	var description: String
	var target_move: String
	var target_category: String
	var condition_type: String
	var condition_value: int
	var condition_scope: String
	var xp_reward: int = 100
	var tier: int = 1

# ── Registry ──
static var _challenges: Dictionary = {}
static var _built: bool = false

static func _ensure() -> void:
	if not _built:
		_built = true
		_build()

static func get_challenge(cid: String) -> MoveChallenge:
	_ensure()
	return _challenges.get(cid)

static func get_challenges_for_move(move_id: String) -> Array:
	_ensure()
	var result: Array = []
	for c in _challenges.values():
		if c.target_move == move_id: result.append(c)
	return result

static func get_all_challenges() -> Array:
	_ensure()
	return _challenges.values().duplicate()

# ── Event matching ──
static func check_and_award(fighter_data, event_type: String, move_id: String, value: int, is_counter: bool) -> Array:
	_ensure()
	var completed: Array = []
	for cid in _challenges.keys():
		var c = _challenges[cid]
		if c.target_move != move_id and c.target_category != move_id: continue
		
		var pkey = cid + "_prog"
		var p = fighter_data.challenge_progress.get(pkey, { "progress": 0 })
		
		if c.condition_scope == "career" and p.get("completed", false): continue
		
		var np = _calc_progress(p.progress, event_type, value, c.condition_type, c.condition_value, is_counter)
		p.progress = np
		
		if np >= c.condition_value:
			p.progress = c.condition_value
			if not p.get("completed", false):
				p.completed = true
				completed.append(c)
		
		fighter_data.challenge_progress[pkey] = p
	
	return completed

static func reset_fight_challenges(fighter_data) -> void:
	for key in fighter_data.challenge_progress.keys():
		if not key.ends_with("_prog"): continue
		var cid = key.replace("_prog", "")
		var c = _challenges.get(cid)
		if c and c.condition_scope == "per_fight":
			fighter_data.challenge_progress[key] = { "progress": 0 }

static func _calc_progress(current: int, event_type: String, value: int, ctype: String, cval: int, is_counter: bool) -> int:
	match ctype:
		"consecutive_hits": return value if event_type == "consecutive_strike" else 0
		"total_hits_in_fight": return current + 1
		"ko_with_move": return current + 1 if event_type == "ko_with_move" else current
		"counter_hits": return current + 1 if is_counter else current
		"combo_length": return max(current, value)
		_: return current

# ── Builder ──
static func _make(cid: String, name: String, desc: String, move: String, cat: String, ctype: String, cval: int, scope: String, xp: int, tier: int) -> MoveChallenge:
	var c = MoveChallenge.new()
	c.challenge_id = cid; c.display_name = name; c.description = desc
	c.target_move = move; c.target_category = cat
	c.condition_type = ctype; c.condition_value = cval
	c.condition_scope = scope; c.xp_reward = xp; c.tier = tier
	return c

static func _build() -> void:
	_challenges["jab_3_consecutive"] = _make("jab_3_consecutive", "Snappy Combo", "Land 3 consecutive jabs.", "jab", "", "consecutive_hits", 3, "per_fight", 50, 1)
	_challenges["jab_10_in_fight"] = _make("jab_10_in_fight", "Jab Machine", "Land 10 jabs in one fight.", "jab", "", "total_hits_in_fight", 10, "per_fight", 100, 2)
	_challenges["jab_ko"] = _make("jab_ko", "Glass Jabber", "KO opponent with a jab.", "jab", "", "ko_with_move", 1, "career", 500, 3)
	_challenges["cross_5_in_fight"] = _make("cross_5_in_fight", "Straight Shooter", "Land 5 crosses.", "cross", "", "total_hits_in_fight", 5, "per_fight", 50, 1)
	_challenges["cross_3_counter"] = _make("cross_3_counter", "Counter Puncher", "Land 3 counter crosses.", "cross", "", "counter_hits", 3, "career", 150, 2)
	_challenges["cross_ko"] = _make("cross_ko", "One Punch", "KO with a cross.", "cross", "", "ko_with_move", 1, "career", 500, 3)
	_challenges["hook_5_in_fight"] = _make("hook_5_in_fight", "Wide Arc", "Land 5 hooks.", "hook", "", "total_hits_in_fight", 5, "per_fight", 50, 1)
	_challenges["hook_10_body"] = _make("hook_10_body", "Body Hunter", "Land 10 hooks to body.", "hook", "", "total_hits_in_fight", 10, "career", 150, 2)
	_challenges["hook_stun"] = _make("hook_stun", "Hook Stunner", "Stun with a hook.", "hook", "", "ko_with_move", 1, "career", 300, 3)
	_challenges["uppercut_3_in_fight"] = _make("uppercut_3_in_fight", "From the Floor", "Land 3 uppercuts.", "uppercut", "", "total_hits_in_fight", 3, "per_fight", 50, 1)
	_challenges["uppercut_clinch"] = _make("uppercut_clinch", "Inside Game", "Uppercut from clinch.", "uppercut", "", "ko_with_move", 1, "career", 150, 2)
	_challenges["uppercut_kd"] = _make("uppercut_kd", "Bass Drop", "KD with uppercut.", "uppercut", "", "ko_with_move", 1, "career", 400, 3)
	_challenges["front_kick_5"] = _make("front_kick_5", "Kickboxer", "Land 5 front kicks.", "front_kick", "", "total_hits_in_fight", 5, "per_fight", 50, 1)
	_challenges["roundhouse_5"] = _make("roundhouse_5", "Legacy", "Land 5 roundhouses.", "roundhouse", "", "total_hits_in_fight", 5, "per_fight", 80, 1)
	_challenges["roundhouse_ko"] = _make("roundhouse_ko", "Head Hunter", "KO with head kick.", "roundhouse", "", "ko_with_move", 1, "career", 500, 3)
	_challenges["leg_kick_10"] = _make("leg_kick_10", "Low Kick Merchant", "Land 10 leg kicks.", "leg_kick", "", "total_hits_in_fight", 10, "per_fight", 80, 1)
	_challenges["head_kick_2"] = _make("head_kick_2", "High Risk", "Land 2 head kicks.", "head_kick", "", "total_hits_in_fight", 2, "per_fight", 100, 1)
	_challenges["head_kick_ko"] = _make("head_kick_ko", "Highlight Reel", "KO with head kick.", "head_kick", "", "ko_with_move", 1, "career", 500, 2)
	_challenges["knee_5"] = _make("knee_5", "Knee Deep", "Land 5 knees.", "knee", "", "total_hits_in_fight", 5, "per_fight", 80, 1)
	_challenges["knee_clinch_kd"] = _make("knee_clinch_kd", "Clinch Domination", "KD with clinch knee.", "knee", "", "ko_with_move", 1, "career", 350, 2)
	_challenges["cat_boxing"] = _make("cat_boxing", "Boxer's Pride", "Win without kicks.", "", "boxing", "total_hits_in_fight", 1, "per_fight", 300, 2)
	_challenges["cat_10_counters"] = _make("cat_10_counters", "Matador", "Land 10 counters.", "", "counter", "counter_hits", 10, "per_fight", 400, 3)
	_challenges["cat_5_ranges"] = _make("cat_5_ranges", "Mix It Up", "All ranges.", "", "versatile", "combo_length", 5, "per_fight", 500, 3)
