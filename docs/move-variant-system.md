# Gladiator Ultra — Move Variant System (Corrected)

> **Core rule:** Variants are BUILD CHOICES selected during character creation or career progression.
> **Not:** In-fight modifier gimmicks.
> **Acquisition:** Earn skill XP from fights → spend XP to purchase/unlock variants.
> **Equip:** Once purchased, equip ONE variant per strike type. It replaces the default.

---

## 1. How It Works

```
Career Loop:
  Fight → Earn XP → Spend XP on Variants → Equip Variants → Fight with new options

Per-Fighter State:
  FighterData.equipped_variants = {
    "jab":    "snap_jab_boxing",      ← purchased and equipped
    "cross":  "power_cross_boxing",   ← purchased and equipped
    "hook":   "check_hook_boxing",    ← purchased and equipped
    "front_kick": "teep_muay_thai",   ← purchased and equipped
    "roundhouse": "standard_generic", ← default (free, always available)
    ...
  }

In Combat:
  Player presses A → jab → StrikePlanner reads equipped_variants["jab"] → "snap_jab_boxing"
    → jab.startup × 0.7 (faster), jab.damage × 0.9 (slightly less), jab.recovery × 0.7 (quick return)
    → Fighter throws a Boxing snap jab, which has different feel than a standard jab
```

**Key constraints:**
- One variant equipped per strike type
- Cannot change variants mid-fight
- Can change between fights in career mode (loadout screen)
- Default variant "standard_generic" is always available and free
- Purchased variants are permanent unlocks

---

## 2. Variant Categories

### 2.1 Core Modifier Types (Available to Everyone)

These change the NUMBERS of a strike. The animation stays the same but properties shift.

| Type | Cost (XP) | Stat Pre-req | Theme |
|------|-----------|-------------|-------|
| Standard | Free | None | Default, balanced |
| Heavy | 100 | STR ≥ 40 | +40% startup, +50% damage, +60% stamina |
| Fast | 100 | SPD ≥ 40 | -30% startup, -20% damage, -30% stamina |
| Efficient | 100 | END ≥ 40 | Same startup, -20% recovery, -40% stamina, -5% range |
| Extended | 100 | AGI ≥ 40 | +10% startup, +40% reach, +40% recovery, very counterable |
| Body | 75 | Any | Shifts target to body, +20% body damage, -10% stun |

### 2.2 Style Variants (Require Style Proficiency)

These change the TRAJECTORY and FEEL of a strike — not just numbers but the animation shape.

| Type | Cost (XP) | Pre-req | Effect |
|------|-----------|---------|--------|
| Snap Jab (Boxing) | 200 | Boxing ≥ 40 | Rec×0.7, combo window +0.1s |
| Power Cross (Boxing) | 250 | Boxing ≥ 60 | Dmg×1.6, Start×1.3, Stam×1.5 |
| Check Hook (Boxing) | 200 | Boxing ≥ 40 | Evasive, Start×0.8, Rec×1.2, Dmg×0.85 |
| Teep (Muay Thai) | 200 | Muay Thai ≥ 40 | FB kick, Dmg×0.7, push×2.0 |
| Thai Roundhouse (Muay Thai) | 250 | Muay Thai ≥ 60 | Dmg×1.3, Start×1.2, Rec×1.2 |
| Thai Clinch Knee (Muay Thai) | 200 | Muay Thai ≥ 40 | Clinch knee Dmg×1.25 |
| Front Snap Kick (Karate) | 200 | Kickboxing ≥ 40 | Start×0.7, Dmg×0.8, Rec×0.7 |
| Reverse Punch (Karate) | 250 | Boxing ≥ 40 | Cross variant, Dmg×1.2 |
| Blast Double (Wrestling) | 250 | TD Off ≥ 50 | Double leg, Start×0.8, Distance×1.3 |

### 2.3 Signature Variants (Unique, High Cost)

One-of-a-kind variants with dramatic property shifts. Usually tied to a specific fighter archetype.

| Type | Cost (XP) | Pre-req | Effect |
|------|-----------|---------|--------|
| Question Mark Kick | 500 | Kickboxing ≥ 70 + SPD ≥ 60 | Head kick variant, switches trajectory mid-strike |
| Superman Punch | 400 | SPD ≥ 60 + Boxing ≥ 50 | Extended leap + cross, huge range, very punishable |
| Lead Leg Roundhouse | 300 | Kickboxing ≥ 50 | Roundhouse from lead leg, faster, less power |
| Axe Kick | 450 | Kickboxing ≥ 65 | Vertical head kick, Start×1.5, Dmg×1.2, KD chance +20% |

---

## 3. Data Schema

```gdscript
# scripts/combat/MoveVariantData.gd
extends RefCounted

class MoveVariant:
	var variant_id: String          # "heavy_jab"
	var display_name: String        # "Heavy Jab"
	var description: String         # "A powerful, telegraphed jab with knockback force."
	var base_move_id: String        # "jab" — matches StrikePlanner strike names
	var category: String            # "generic", "style", "signature"
	var style_origin: String        # "generic", "boxing", "muay_thai", etc.
	
	# ── Frame data multipliers (applied to base move values) ──
	var startup_mult: float = 1.0
	var active_mult: float = 1.0
	var recovery_mult: float = 1.0
	var damage_mult: float = 1.0
	var stamina_cost_mult: float = 1.0
	var reach_mult: float = 1.0
	
	# ── Combat modifiers ──
	var hit_chance_mult: float = 1.0
	var guard_damage_mult: float = 1.0   # stamina damage through block
	var stun_chance_add: float = 0.0     # flat bonus to stun level
	var push_force: float = 0.0          # meters of knockback
	var cut_chance_add: float = 0.0      # flat cut chance bonus
	
	# ── Risk ──
	var counter_window_add: int = 0      # extra frames opponent has to counter
	
	# ── Combo ──
	var combo_link_reduction: int = 0    # frames reduced on next strike's recovery
	
	# ── Trajectory ──
	var trajectory_override: String = ""  # if non-empty, use this trajectory function
	
	# ── Unlock requirements ──
	var xp_cost: int = 100
	var requirements: Dictionary = {}    # { "boxing": 40, "strength": 50 }
```

---

## 4. FighterData Integration

```gdscript
# In FighterData.gd — new field
var equipped_variants: Dictionary = {}  # { "jab": "standard_generic", ... }

# Default: all strikes set to standard_generic
func reset_variants() -> void:
	equipped_variants = {}
	for strike_id in _ALL_STRIKE_IDS:
		equipped_variants[strike_id] = "standard_generic"

# Equip a variant for a specific strike
func equip_variant(strike_id: String, variant_id: String) -> bool:
	if not _is_variant_owned(variant_id):
		return false
	equipped_variants[strike_id] = variant_id
	return true

# Get the equipped variant for a strike
func get_variant(strike_id: String):
	var vid = equipped_variants.get(strike_id, "standard_generic")
	return MoveVariantDatabase.get_variant(vid)

# Purchase a variant
func purchase_variant(variant_id: String) -> bool:
	var v = MoveVariantDatabase.get_variant(variant_id)
	if not v: return false
	if _owned_variants.has(variant_id): return false  # already owned
	if skill_xp < v.xp_cost: return false
	# Check stat requirements
	for stat in v.requirements:
		var val = get(stat) if stat in self else 0.0
		if val < v.requirements[stat]:
			return false
	skill_xp -= v.xp_cost
	_owned_variants.append(variant_id)
	return true
```

---

## 5. StrikePlanner Variant Integration

The `plan()` function already accepts `StatsMod`. Now it also reads the fighter's equipped variant:

```gdscript
static func plan(
	strike_type: int,
	target_zone: String,
	stats: StatsMod,
	variant: MoveVariant = null  # ← NEW
) -> StrikePlan:
	
	var plan = StrikePlan.new()
	plan.strike_type = strike_type
	plan.target_zone = target_zone
	
	# Get base move data (existing)
	match strike_type: _plan_jab(plan, stats) ...
	
	# ── Apply variant multipliers ──
	if variant:
		plan.startup_frames   = max(1, int(plan.startup_frames * variant.startup_mult))
		plan.active_frames    = max(1, int(plan.active_frames * variant.active_mult))
		plan.recovery_frames  = max(1, int(plan.recovery_frames * variant.recovery_mult))
		plan.base_damage      = plan.base_damage * variant.damage_mult
		plan.stamina_cost     = plan.stamina_cost * variant.stamina_cost_mult
		plan.reach_meters     = plan.reach_meters * variant.reach_mult
		plan.base_damage     += variant.stun_chance_add  # flat damage for stun threshold
	
	# Then apply stat modifiers as before (SPD, STR, gassed, etc.)
	_apply_stat_modifiers(plan, stats, variant)
	
	return plan
```

---

## 6. Per-Strike Variant Trees

Example: **Jab** — 20 variants path

```
jab/
├── generic/
│   ├── standard_generic     (free, default)
│   ├── heavy_generic        (100xp, STR≥40)
│   ├── fast_generic         (100xp, SPD≥40)
│   ├── efficient_generic    (100xp, END≥40)
│   └── extended_generic     (100xp, SPD≥40)
├── boxing/
│   ├── snap_jab             (200xp, Boxing≥40)     ← replaces base trajectory
│   └── heavy_jab_boxing     (250xp, Boxing≥60)     ← boxing version of heavy
├── muay_thai/
│   ├── thai_jab             (200xp, Muay Thai≥40)  ← heavier, more hip
│   └── long_jab             (250xp, Muay Thai≥50)  ← reach variant
├── karate/
│   ├── snap_jab_karate      (200xp, Boxing≥35)     ← very fast return
│   └── reverse_punch_setup  (300xp, Boxing≥50)     ← jab that chains into reverse punch
├── kickboxing/
│   ├── flicker_jab          (250xp, Footwork≥50)   ← slight range feint before committing
│   └── power_jab_setup      (200xp, Boxing≥40)     ← wide, sets up power cross
├── advanced/
│   ├── superman_jab         (400xp, SPD≥60, Boxing≥50) ← jumping jab, huge range
│   └── shoulder_roll_jab    (350xp, Head Mov≥60)   ← evasive jab, counter follow-up
└── combo_specific/
    ├── jab_cross_link       (150xp, Boxing≥30)     ← faster cross follow-up
    └── jab_hook_setup       (150xp, Boxing≥30)     ← faster hook follow-up
```

---

## 7. Starting Loadouts (FighterFactory integration)

Each fighter archetype starts with pre-purchased/equipped variants:

```gdscript
# FighterFactory — per-archetype variant loadouts

static func _build_ivan_drakov() -> FighterData:
	# ... existing stat block ...
	# Equip variants that match his power-puncher archetype
	f.equip_variant("jab",   "heavy_generic")
	f.equip_variant("cross", "power_cross_boxing")
	f.equip_variant("hook",  "heavy_generic")
	f.equip_variant("roundhouse", "standard_generic")  # not a kicker — no special variant
	f.equip_variant("leg_kick",   "standard_generic")
	
	# Also pre-purchase his owned variants (so they can't be re-purchased)
	f._owned_variants = ["standard_generic", "heavy_generic", "power_cross_boxing", ...]
	return f

static func _build_kenji_takeshi() -> FighterData:
	# Grappler: invests in takedown variants, minimal striking
	f.equip_variant("jab",          "efficient_generic")
	f.equip_variant("double_leg",   "blast_double_wrestling")
	f.equip_variant("single_leg",   "reactive_single_sambo")
	return f
```

---

## 8. Career Mode Progression

```gdscript
# XP earned per fight action:
#   Land a strike: +5 XP per strike type used
#   Win by KO: +50 XP
#   Win by submission: +75 XP
#   Win by decision: +100 XP
#   Train a skill: +5-20 XP (diminishing returns per session)
#   Complete training camp: +50 XP

# Variant costs scale:
#   Core (generic):         100 XP
#   Style (basic):          200 XP
#   Style (advanced):       300 XP
#   Signature:              400-500 XP
#   Legendary:              750-1000 XP

# Stat pre-reqs scale difficulty:
#   Core: stat ≥ 40
#   Style: style skill ≥ 40-60
#   Signature: two stats ≥ 60 + style ≥ 70
#   Legendary: three stats ≥ 80 + elite-level requirements
```

---

## 9. Implementation Checklist

- [ ] MoveVariantData.gd — MoveVariant class with all fields
- [ ] MoveVariantDatabase.gd — static registry dictionary (all variants)
- [ ] FighterData — equipped_variants field + equip/purchase methods
- [ ] FighterFactory — starting loadouts per fighter
- [ ] StrikePlanner — variant parameter in plan() + multiplier application
- [ ] Career XP system — earn from fights, spend on variants
- [ ] Loadout UI — equip variants between fights
- [ ] 20 variants per strike (expand from initial 8)
