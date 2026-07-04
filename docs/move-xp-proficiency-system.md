# Gladiator Ultra — Move XP & Proficiency System

> **Earn:** Each strike type gains XP based on damage dealt in fights.
> **Spend:** XP unlocks variant purchase options for that specific move.
> **Weight:** Rare/high-risk moves earn more XP per damage than common moves.

---

## 1. Core Loop

```
Fight → Land Jab (10 dmg × ×1.0 weight = 10 XP to "jab")
       → Land Head Kick (35 dmg × ×2.0 weight = 70 XP to "head_kick")
       → Win by KO (+50 XP to finishing move)

Between Fights → Check per-strike XP totals
                → Unlock variant purchase options
                → Buy variants with accumulated XP (per-strike, not global)
                → Equip one variant per strike type
```

**Key rule:** XP is tracked per strike type and never spent globally. Landing 100 jabs earns 1000 XP to the "jab" pool — you spend that jab XP on jab variants. You cannot use jab XP to buy a roundhouse variant.

---

## 2. XP Earned Per Landing

```gdscript
# Applied in FighterStateMachine when strike_landed signal fires

func _on_strike_landed(result, strike_type: int, attacker_fighter_data) -> void:
	var xp_weight = XP_WEIGHT.get(_strike_id(strike_type), 1.0)
	var xp_gained = int(result.mitigated_damage * xp_weight)
	
	# Bonus XP:
	if result.is_counter:     xp_gained = int(xp_gained * 1.5)  # +50% for counters
	if result.stun_level >= 3: xp_gained = int(xp_gained * 1.3)  # +30% for stuns
	if result.is_ko:          xp_gained = int(xp_gained * 2.0)  # +100% for KO strikes
	
	attacker_fighter_data.add_strike_xp(_strike_id(strike_type), xp_gained)
```

### 2.1 XP Weight Table

| Move ID | XP Weight | Rationale |
|---------|-----------|-----------|
| jab | ×1.0 | Most common strike, slowest progression |
| cross | ×1.2 | Slightly rarer, more committal |
| hook | ×1.4 | Higher risk, wider arc |
| uppercut | ×1.6 | Close-range only, situational |
| front_kick | ×1.3 | Range finder, moderate use |
| roundhouse | ×1.5 | Committal kick |
| leg_kick | ×1.0 | Common, low risk |
| head_kick | ×2.0 | Very high risk, rewarded heavily |
| knee | ×1.8 | Close range, clinch only |
| elbow | ×2.0 | Very close range, cut chance |
| switch_kick | ×2.0 | Unorthodox, timing-based |
| double_leg | ×2.5 | High stamina cost, high reward |
| single_leg | ×2.2 | Moderately common TD |
| clinch_td | ×2.0 | Clinch-only |
| sprawl_counter | ×2.5 | Defensive, reactive |
| submission | ×3.0 | Highest risk, must be locked in |
| gnp | ×1.5 | Ground strikes, moderate weight |
| sweep | ×2.5 | Reversal from bottom |

### 2.2 XP Bonus Events

| Event | XP Bonus | Condition |
|-------|----------|-----------|
| Counter hit | ×1.5 | Strike landed during opponent's attack |
| Stun | ×1.3 | Strike caused stun (tier 3+) |
| KD | ×1.8 | Strike caused knockdown |
| KO | ×2.0 | Strike ended the fight |
| Perfect timing | ×1.25 | LT tap on contact frame |
| First use in fight | +10 | First time using this strike type this fight |

---

## 3. XP → Variant Unlock Thresholds

Each strike type has level thresholds. When cumulative XP crosses a threshold, new variant purchase options unlock.

| Level | Total XP Needed | Unlocks | Example Variants Unlocked |
|-------|----------------|---------|--------------------------|
| 1 | 0 | Standard variant (free) | standard_generic |
| 2 | 100 | Core modifier variants | heavy, fast, efficient, extended, body |
| 3 | 300 | Basic style variants | snap_jab, thai_jab, flicker_jab |
| 4 | 600 | Advanced style variants | power_jab_setup, shoulder_roll_jab |
| 5 | 1000 | Signature / combo variants | superman_jab, jab_cross_link |

**Cost to purchase** a specific variant is separate from the XP threshold. You must:
1. Reach the XP level threshold (unlocks the category)
2. Pay the variant's XP cost from that strike's XP pool (reduces pool)
3. Meet any stat/style prerequisites

### 3.1 Example Progression: Jab

| Step | XP Pool | Action | Remaining XP | New Options |
|------|---------|--------|-------------|-------------|
| Start | 0 | — | 0 | standard_generic only |
| Land 10 jabs | 100 | Crosses Level 2 | 100 | Can buy: heavy, fast, efficient, extended (100xp each) |
| Buy "heavy" | 100 → 0 | Spend 100xp | 0 | Equip heavy_jab OR standard |
| Land 20 more jabs | 200 | — | 200 | Still Level 2 (need 300 for Level 3) |
| Land 40 jabs total | 420 | Crosses Level 3 | 120 | Can buy: snap_jab (200xp), thai_jab (200xp) |
| Buy "snap_jab" | 120 → 0 | Spend 120xp (need 200? must earn more) | — | Must land more jabs to afford it |

---

## 4. FighterData Integration

```gdscript
# scripts/fighter/FighterData.gd

# ── Per-strike XP ──
var strike_xp: Dictionary = {}  # { "jab": 0, "cross": 50, "hook": 120, ... }

# ── Earned/owned variants ──
var owned_variants: Array[String] = ["standard_generic"]  # always own the default

# ── Currently equipped variant per strike ──
var equipped_variants: Dictionary = {}  # { "jab": "standard_generic", ... }

# ── Methods ──

func add_strike_xp(strike_id: String, amount: int) -> void:
	var current = strike_xp.get(strike_id, 0)
	strike_xp[strike_id] = current + amount
	_check_variant_unlocks(strike_id)

func get_strike_level(strike_id: String) -> int:
	var xp = strike_xp.get(strike_id, 0)
	if xp >= 1000: return 5
	if xp >= 600:  return 4
	if xp >= 300:  return 3
	if xp >= 100:  return 2
	return 1

func get_unlocked_variant_categories(strike_id: String) -> Array:
	var level = get_strike_level(strike_id)
	match level:
		1: return ["standard"]
		2: return ["standard", "core"]
		3: return ["standard", "core", "style_basic"]
		4: return ["standard", "core", "style_basic", "style_advanced"]
		5: return ["standard", "core", "style_basic", "style_advanced", "signature", "combo"]
		_: return ["standard"]

func purchase_variant(strike_id: String, variant_id: String) -> bool:
	var v = MoveVariantDatabase.get_variant(variant_id)
	if not v: return false
	if variant_id in owned_variants: return false  # already own it
	if v.base_move_id != strike_id: return false
	
	# Check level requirement
	var level_req = _variant_level_requirement(v.category)
	if get_strike_level(strike_id) < level_req:
		return false
	
	# Check stat/style requirements
	for req in v.requirements:
		var val = get(req) if req in self else 0.0
		if val < v.requirements[req]:
			return false
	
	# Check XP cost (from this strike's pool)
	var cost = v.xp_cost
	var pool = strike_xp.get(strike_id, 0)
	if pool < cost:
		return false
	
	strike_xp[strike_id] = pool - cost
	owned_variants.append(variant_id)
	return true

func equip_variant(strike_id: String, variant_id: String) -> bool:
	if variant_id not in owned_variants:
		return false
	equipped_variants[strike_id] = variant_id
	return true

func get_equipped_variant(strike_id: String):
	var vid = equipped_variants.get(strike_id, "standard_generic")
	return MoveVariantDatabase.get_variant(vid)

# ── Internal ──

func _variant_level_requirement(category: String) -> int:
	match category:
		"standard":  return 1
		"core":      return 2
		"style":     return 3
		"advanced":  return 4
		"signature", "combo": return 5
		_:           return 1

func _check_variant_unlocks(strike_id: String) -> void:
	# Called automatically by add_strike_xp — signals UI to refresh available variants
	pass  # Signal to UI layer: variant_unlocks_changed.emit(strike_id, get_strike_level(strike_id))
```

---

## 5. FighterFactory Starting State

Pre-made fighters start with XP appropriate to their record:

```gdscript
# Ivan Drakov (18-2, 16 KOs)
f.strike_xp = {
	"jab": 450,      # Level 3 (300+) — uses heavy jab
	"cross": 600,    # Level 4 (600+) — uses power cross
	"hook": 400,     # Level 3
	"uppercut": 150, # Level 2
	"roundhouse": 50, # Level 1
	"leg_kick": 80,  # Level 1
}
f.owned_variants = [
	"standard_generic", "heavy_generic", "fast_generic",
	"power_cross_boxing", "snap_jab_boxing", "check_hook_boxing",
]
f.equip_variant("jab",    "heavy_generic")
f.equip_variant("cross",  "power_cross_boxing")
f.equip_variant("hook",   "check_hook_boxing")
```

---

## 6. Complete Data Flow

```
IN-FIGHT:
  Strike lands → FighterStateMachine._on_strike_landed()
    → mitigated_damage × XP_WEIGHT → add_strike_xp(strike_id, amount)
    → strike_xp[strike_id] += amount
    → Check if new level reached → variant_unlocks_changed signal

BETWEEN FIGHTS (Career Mode):
  Player opens "Move Proficiency" screen
    → Shows per-strike: current XP, level, owned variants, purchase options
    → Purchase variant: checks XP pool + stat prereqs → deducts XP → adds to owned
    → Equip variant: selects which owned variant is active for each strike

IN NEXT FIGHT:
  When strike is thrown → StrikePlanner.plan(..., variant=get_equipped_variant(strike_id))
    → Reads variant.startup_mult, .damage_mult, .stamina_mult, etc.
    → Applies multipliers to base move data
    → Fighter throws the selected variant
    → If it lands → more XP gained → progression continues
```

---

## 7. Prestige System

Each strike type can be **prestiged** when it reaches max level (5). Prestiging resets the strike's XP to 0 (and level to 1) in exchange for a permanent stacking modifier that persists forever.

### 7.1 Prestige Flow

```
Strike reaches Level 5 (1000+ XP earned)
  → Player chooses "Prestige" in loadout screen
  → strike_xp[strike_id] resets to 0
  → get_strike_level(strike_id) returns 1
  → strike_prestige[strike_id] += 1 (e.g. 0 → 1)
  → Permanent modifier applied permanently to that strike type

Fighter now uses the strike again:
  → Earns XP from 0 again (faster this time — familiarity bonus)
  → Re-levels from 1→2→3→4→5
  → Can prestige again for another permanent bonus
  → Infinite loop: use → level → prestige → bonus → use → level → prestige → bonus
```

### 7.2 Prestige Modifier Table

Each prestige level grants stacking bonuses to that specific strike type:

| Prestige | Bonus | Cumulative Effect (at Prestige 5) |
|----------|-------|-----------------------------------|
| 1 | +3% damage | +3% damage |
| 2 | -3% stamina cost | +3% dmg, -3% stam |
| 3 | +2% hit chance | +3% dmg, -3% stam, +2% hit |
| 4 | +3% damage | +6% dmg, -3% stam, +2% hit |
| 5 | -2% recovery frames | +6% dmg, -3% stam, +2% hit, -2% rec |
| 6 | +2% damage | +8% dmg, -3% stam, +2% hit, -2% rec |
| 7 | -2% stamina cost | +8% dmg, -5% stam, +2% hit, -2% rec |
| 8 | +2% hit chance | +8% dmg, -5% stam, +4% hit, -2% rec |
| 9 | +3% damage | +11% dmg, -5% stam, +4% hit, -2% rec |
| 10 | +1% startup speed | +11% dmg, -5% stam, +4% hit, -3% rec, -1% start |

**Pattern:** Every 5 prestiges cycle through [dmg, stam, hit, dmg, rec] and repeat with small increments. There is no cap — a fighter with 100 prestige levels on their jab has an absurdly good jab, earned through thousands of fights.

### 7.3 FighterData Integration

```gdscript
# scripts/fighter/FighterData.gd — new fields

var strike_prestige: Dictionary = {}  # { "jab": 0, "cross": 2, "hook": 1, ... }

# ── Prestige method ──
func prestige_strike(strike_id: String) -> bool:
	if get_strike_level(strike_id) < 5:
		return false  # must be max level
	strike_xp[strike_id] = 0
	var current = strike_prestige.get(strike_id, 0)
	strike_prestige[strike_id] = current + 1
	return true

# ── Get prestige modifier for a strike ──
func get_strike_prestige_modifier(strike_id: String) -> Dictionary:
	var prestige = strike_prestige.get(strike_id, 0)
	var mods = { "damage": 0.0, "stamina": 0.0, "hit_chance": 0.0, "startup": 0.0, "recovery": 0.0 }
	
	for i in range(1, prestige + 1):
		var cycle = (i - 1) % 5
		var tier = floori((i - 1) / 5) + 1
		match cycle:
			0: mods["damage"] += 0.02 + (tier * 0.01)     # +2-3% damage
			1: mods["stamina"] -= 0.02 - (tier * 0.005)   # -2-3% stamina cost
			2: mods["hit_chance"] += 0.015 + (tier * 0.005) # +1.5-2.5% hit chance
			3: mods["damage"] += 0.02 + (tier * 0.01)     # +2-3% damage
			4: mods["recovery"] -= 0.015 + (tier * 0.005)  # -1.5-2.5% recovery frames
	return mods
```

### 7.4 StrikePlanner Prestige Integration

```gdscript
# Applied after variant multipliers, before stat modifiers

static func _apply_prestige_modifiers(plan: StrikePlan, fighter_data, strike_id: String) -> void:
	var prestige_mods = fighter_data.get_strike_prestige_modifier(strike_id)
	
	plan.base_damage *= (1.0 + prestige_mods.damage)
	plan.stamina_cost *= (1.0 + prestige_mods.stamina)    # stamina is negative → cost reduction
	plan.hit_chance_mult = plan.hit_chance_mult * (1.0 + prestige_mods.hit_chance)
	plan.startup_frames = max(1, int(plan.startup_frames * (1.0 + prestige_mods.startup)))
	plan.recovery_frames = max(1, int(plan.recovery_frames * (1.0 + prestige_mods.recovery)))
```

### 7.5 FighterFactory Starting State

Pre-made fighters have prestige appropriate to their record length:

```gdscript
# Ivan Drakov — veteran power puncher (18 fights)
f.strike_prestige = {
	"jab": 2,    # +3% dmg, -3% stam
	"cross": 3,  # +3% dmg, -3% stam, +2% hit
	"hook": 1,   # +3% dmg
}

# Kenji Takeshi — young grappler (14 fights)
f.strike_prestige = {
	"td_offense": 2,  # +3% dmg, -3% stam      (takedown XP counts under "td_offense")
	"sub_offense": 1, # +3% dmg
}

# Marcus Steele — veteran all-rounder (13 fights)
f.strike_prestige = {
	"jab": 1,
	"cross": 1,
	"hook": 1,
	"roundhouse": 1,
}
```

---

## 8. Move Challenges System

Each move has 3-5 challenges. Completing them awards large XP bonuses to that move (or its category). Challenges give structure to progression — they reward specific play patterns, not just damage spam.

### 8.1 Challenge Structure

```gdscript
class MoveChallenge:
	var challenge_id: String          # "jab_3_consecutive"
	var display_name: String          # "Snappy Combo"
	var description: String           # "Land 3 consecutive jabs in a single fight"
	
	var target_move: String           # "jab" — which move this applies to
	var target_category: String       # "" — or "boxing", "kicking", "grappling"
	
	var condition_type: String        # "consecutive_hits", "total_hits", "ko_with_move",
	                                  # "counter_hits", "stun_level", "prestige_count",
	                                  # "combo_length", "damage_in_one_strike"
	var condition_value: int          # 3, 10, 1, etc.
	var condition_scope: String       # "per_fight" (resets each fight), "career" (cumulative)
	
	var xp_reward: int = 100          # XP granted to the target move
	var xp_distribution: String       # "single" (to one move), "category" (split across category)
	
	var tier: int = 1                 # 1-3 (Bronze/Silver/Gold = increasing difficulty)
```

### 8.2 Per-Move Challenge Examples

| Move | Tier | Name | Condition | Scope | XP Reward |
|------|------|------|-----------|-------|-----------|
| **Jab** | 1 | Snappy Combo | Land 3 consecutive jabs | per_fight | 50 |
| Jab | 2 | Jab Machine | Land 10 jabs in one fight | per_fight | 100 |
| Jab | 3 | Glass Jabber | KO opponent with a jab | career | 500 |
| **Cross** | 1 | Straight Shooter | Land 5 crosses | per_fight | 50 |
| Cross | 2 | Counter Puncher | Land 3 counter crosses | career | 150 |
| Cross | 3 | One Punch | KO opponent with a single cross | career | 500 |
| **Hook** | 1 | Wide Arc | Land 5 hooks | per_fight | 50 |
| Hook | 2 | Body Hunter | Land 10 hooks to the body | career | 150 |
| Hook | 3 | Liver Shot | Cause a stamina stop with body hooks | career | 400 |
| **Head Kick** | 1 | High Risk | Land 2 head kicks | per_fight | 80 |
| Head Kick | 2 | Head Hunter | KO with a head kick | career | 500 |
| Head Kick | 3 | Question Mark | Land a head kick from southpaw stance | career | 750 |
| **Takedown** | 1 | Take Down | Land 3 takedowns | per_fight | 80 |
| Takedown | 2 | Ground Control | Hold top position for 30s cumulative | per_fight | 150 |
| Takedown | 3 | Slam | KO with a slam takedown | career | 600 |
| **Submission** | 1 | Lock In | Attempt 3 submissions | per_fight | 100 |
| Submission | 2 | Tap Out | Win by submission | career | 500 |
| Submission | 3 | Chain | Chain 3 submission attempts in one sequence | career | 750 |

### 8.3 Category Challenges

These reward broader playstyle choices and distribute XP across all moves in a category.

| Category | Name | Condition | Scope | XP Reward | Distribution |
|----------|------|-----------|-------|-----------|-------------|
| **Boxing** | Boxer's Pride | Win a fight without throwing a kick | per_fight | 300 | Split: jab 40%, cross 35%, hook 25% |
| **Kicking** | Kickboxer | Land 30 kicks in one fight | per_fight | 300 | Split across all kick types |
| **Clinch** | Dirty Boxer | Land 15 clinch strikes in one fight | per_fight | 250 | Split: knee 50%, elbow 50% |
| **Ground** | Ground and Pound | Land 20 GNP strikes in one fight | per_fight | 250 | Split across GNP types |
| **Grappling** | Wrestler | Complete 5 takedowns in one fight | per_fight | 300 | Split across TD types |
| **Submissions** | Submission Artist | Win 3 consecutive fights by sub | career | 800 | Split across all sub types |
| **Versatile** | Mix It Up | Land strikes in all 5 ranges in one fight | per_fight | 500 | Split across all strike types |
| **Counter** | Matador | Land 10 counter strikes in one fight | per_fight | 400 | Split across all strike types |

### 8.4 Challenge Progression Flow

```
PER FIGHT:
  Fighter lands a jab (3rd consecutive this fight)
    → FighterStateMachine checks: jab_3_consecutive challenge
    → Challenge progress: 2/3 → 3/3 → COMPLETED
    → +50 XP added to jab's strike_xp immediately
    → Challenge resets at end of fight (scope = "per_fight")
    → Challenge can be completed again next fight

CAREER:
  Fighter KOs opponent with a cross
    → cross_ko_challenge check: progress 0→1 → COMPLETED
    → +500 XP added to cross's strike_xp
    → Challenge marked completed (scope = "career")
    → Never resets — one-time bonus

CATEGORY:
  Fighter wins by submission (3rd consecutive)
    → submission_3_consecutive_wins check: 3/3 → COMPLETED
    → +800 XP distributed: 40% to each submission type
    → Challenge resets if fighter loses (streak broken)
```

### 8.5 FighterData Integration

```gdscript
# scripts/fighter/FighterData.gd — new fields

var challenge_progress: Dictionary = {}  
# { "jab_3_consecutive": { "progress": 3, "completed_this_fight": true, "total_career_completions": 47 } }

# ── Report a combat event ──
func report_combat_event(event_type: String, move_id: String, value: int = 1, is_counter: bool = false) -> void:
	# Called by FighterStateMachine when strikes land, KOs happen, etc.
	# Checks all relevant challenges and grants XP for completed ones
	var completed = MoveChallengeDatabase.check_and_award(self, event_type, move_id, value, is_counter)
	for challenge in completed:
		strike_xp[challenge.target_move] = strike_xp.get(challenge.target_move, 0) + challenge.xp_reward

# ── Reset per-fight challenges ──
func reset_fight_challenges() -> void:
	for cid in challenge_progress.keys():
		var challenge = MoveChallengeDatabase.get_challenge(cid)
		if challenge and challenge.condition_scope == "per_fight":
			challenge_progress[cid].progress = 0

# ── Get challenge progress for UI ──
func get_challenge_progress(challenge_id: String) -> Dictionary:
	return challenge_progress.get(challenge_id, { "progress": 0, "completed_this_fight": false })
```

### 8.6 Event → Challenge Mapping

```gdscript
# FighterStateMachine calls report_combat_event for every meaningful action:

# Strike landed:
report_combat_event("strike_landed", strike_id, mitigated_damage, is_counter)

# Consecutive hits tracked internally:
report_combat_event("consecutive_strike", strike_id, combo_count)

# KO:
report_combat_event("ko_with_move", strike_id, round_number)

# KD:
report_combat_event("knockdown_with_move", strike_id, 1)

# Submission:
report_combat_event("submission_win", submission_id, 1)

# Takedown:
report_combat_event("takedown_landed", td_id, 1)

# Etc. — the challenge system listens for these events and tracks progress
```

---

## 9. Complete Progression Architecture

```
FIGHT:
  Player lands cross (counter, 3rd consecutive)
  
  → FighterStateMachine:
      1. ImpactCalculator resolves → damage, stun, etc.
      2. FighterData.add_strike_xp("cross", dmg × weight)
      3. FighterData.report_combat_event("strike_landed", "cross", dmg, true)
  
  → FighterData:
      1. strike_xp["cross"] += 22 (15 dmg × 1.2 weight × 1.5 counter)
      2. Checks cross_3_consecutive → progress 3/3 → COMPLETED → +50 XP
      3. Checks cross_counter_master → progress 1/3 → not yet
      4. Checks category_versatile → checks all ranges used this fight
  
  → If any challenge completed:
      - XP bonus added immediately
      - Visual feedback: "Challenge Complete: Counter Puncher (+150 XP to Cross)"
      - If career challenge: marked done permanently
      - If per-fight challenge: resets next fight

BETWEEN FIGHTS:
  Player sees:
    → Jab: Level 3 (420/600) — 0/3 challenges complete
    → Cross: Level 4 (720/1000) — 2/3 challenges complete  
    → Head Kick: Level 2 (150/300) — 0/3 challenges complete
    → Available challenges: per-move list, category list
```

---

## 10. Updated Implementation Priority

| Step | What | Files |
|------|------|-------|
| 1 | MoveVariantData.gd — variant class + constants | New |
| 2 | MoveVariantDatabase.gd — 80+ variant registry | New |
| 3 | MoveChallengeDatabase.gd — challenge definitions + event matching | New |
| 4 | FighterData: strike_xp, strike_prestige, owned/equipped variants, challenge tracking, methods | Update |
| 5 | FighterFactory: starting XP + prestige + variant loadouts + challenge defaults | Update |
| 6 | StrikePlanner: variant + prestige multiplier integration | Update |
| 7 | FighterStateMachine: _on_strike_landed → add_strike_xp + report_combat_event | Update |
| 8 | Tests: variant application, XP/prestige/challenge progression | New |
