# Gladiator Ultra — Claude Code Build Prompt

> **Target:** Build a complete, playable MMA simulation game in Godot 4.4+
> **Design DNA:** EA Sports UFC 6 mechanics × Virtua Fighter low-poly aesthetic
> **Style:** Physics-driven combat, procedural animation, deep career mode
> **Engine:** Godot 4.4+ (GDScript), GL Compatibility renderer, headless-testable

---

## PART 1: GAME OVERVIEW & DESIGN PHILOSOPHY

### Core Identity
Gladiator Ultra is a **physics-driven MMA simulation** where every strike is a calculated velocity × angle × range event, rendered in Virtua Fighter 1-era low-poly (300-600 vertex characters, vertex-colored, unlit flat shading). The animation system reads physics results — not the other way around.

### Design Pillars
1. **Physics-first combat** — Damage, stun, and knockback are computed from velocity vectors, limb tip speed, and angle of incidence. No pre-baked "this animation deals X damage" tables.
2. **UFC 6 frame data accuracy** — Every strike has startup, active, and recovery frames that match real UFC game timing. Hitboxes are capsule-based, matching known UFC 6 hurtbox dimensions.
3. **VF1 low-poly aesthetic** — 300-600 vertex character models, vertex-colored with no textures, flat unlit shading. Clean silhouettes, no over-detailing.
4. **Deep career mode** — Attribute training camps, per-strike XP progression, injury management with broken bones, fight card scheduling, ranking ladder.
5. **Character uniqueness** — Every fighter is defined by 4 core stats + 18 skills + 12 style affinities + equipped move variants. No two fighters play the same.
6. **Modular architecture** — Every system is an independent module. Combat core can be extracted for beat-em-ups or fighting games.

### Reference Translations

| UFC 6 Feature | Gladiator Ultra Equivalent |
|---------------|---------------------------|
| Real-time damage model (swelling, cuts, broken bones) | Body-part health pools with blunt/sharp/break thresholds |
| Clinch/ground transition wheel | State machine with physics-interrupted states |
| Fighter attributes + perks | 4 core stats + 18 skills + Move Variant system |
| Career mode (training, fights, ranking, injuries) | TrainingCamp + CareerMap + InjurySystem |
| Health events (broken orbital, torn ACL, etc.) | 10+ injury types with recovery timelines and stat penalties |
| Post-fight damage assessment | Medical review screen with injury diagnosis |
| Per-strike XP progression | Strike XP weighted by damage → variant unlocks |
| Fighter creation | Height/reach/body type sliders + attribute allocation |

| Virtua Fighter Concept | Gladiator Ultra Equivalent |
|------------------------|---------------------------|
| Low-poly characters with clean silhouettes | 300-600 vertex meshes, vertex-colored |
| 3D movement in a plane | Physics-aware footwork with directional influence |
| Clear, readable attack animations | Procedural strike trajectories via parametric curves |
| Minimal UI, pure gameplay focus | HUD overlay with health/stamina/timer only |

---

## PART 2: ARCHITECTURE & FILE TREE

```
gladiator_ultra/
├── project.godot                    # Godot project config
├── addons/                          # Plugins (empty for now)
│
├── scripts/
│   ├── autoload/
│   │   ├── CombatGlobals.gd         # Enums, formulas, constants
│   │   └── LimbTracker.gd           # Physics-bone velocity capture
│   │
│   ├── combat/
│   │   ├── ImpactCalculator.gd      # Velocity→damage→stun resolution
│   │   ├── HitDetection.gd          # Capsule-vs-capsule, zone mapping
│   │   └── BlockSystem.gd           # Damage redux, stamina drain, guard break
│   │
│   ├── fighter/
│   │   ├── FighterData.gd           # Stat block, health pools, stamina state
│   │   ├── FighterStateMachine.gd   # STAND_UP/CLINCH/GROUND/SUBMISSION states
│   │   ├── FighterFactory.gd        # Creates FighterData from definitions
│   │   ├── FighterCharacter.gd      # 3D scene: Skeleton3D + hitboxes + IK
│   │   ├── StyleData.gd             # Style definitions and stat modifiers
│   │   └── FighterAnimator.gd       # Procedural animation (IK + bone posing)
│   │
│   ├── animation/
│   │   ├── LimbSolver.gd            # FABRIK IK — 2-bone chain
│   │   ├── StrikePlanner.gd         # 10 parametric strike trajectories
│   │   ├── ContactDetector.gd       # Capsule-vs-point, swept tunnel
│   │   ├── RecoveryPlanner.gd       # Stamina/limb/combo recovery
│   │   └── HitReaction.gd           # Stun-tier bone snapping + ragdoll blend
│   │
│   ├── control/
│   │   ├── InputBuffer.gd           # Input history + combo detection
│   │   ├── InputSetup.gd            # Key/gamepad bindings setup
│   │   └── ControlMap.gd            # Action routing per fight state
│   │
│   ├── match/
│   │   ├── MatchManager.gd          # Round timer, scoring, fight outcome
│   │   └── JudgeScorer.gd           # 10-9 system
│   │
│   ├── camera/
│   │   └── FightCamera.gd           # Third-person orbital, shake
│   │
│   ├── ai/
│   │   ├── AIController.gd          # Tactical decision-making
│   │   └── StyleProfiles.gd         # Behavior weights per style
│   │
│   ├── progression/
│   │   ├── MoveVariantData.gd       # Variant class definition
│   │   ├── MoveVariantDatabase.gd   # 80+ variant registry
│   │   ├── MoveChallengeDatabase.gd # Per-move challenges
│   │   ├── CareerMap.gd             # Fight card scheduling, ranks
│   │   ├── TrainingCamp.gd          # Attribute training system
│   │   ├── FighterProfile.gd        # Career stats, record, injuries
│   │   └── InjurySystem.gd          # Broken bones, cuts, recovery
│   │
│   ├── character_creation/
│   │   ├── CharacterBuilder.gd      # Attribute + appearance setup
│   │   ├── BodyTypeData.gd          # Height/reach/proportion presets
│   │   └── StyleSelector.gd         # Primary style + 2 sub-styles
│   │
│   └── ui/
│       ├── FightHUD.gd              # Health/stamina/timer overlay
│       ├── CareerScreen.gd          # Career main menu
│       ├── TrainingScreen.gd        # Training camp mini-game
│       ├── FightCardScreen.gd       # Upcoming fight selection
│       ├── InjuryReport.gd          # Post-fight medical review
│       ├── CharacterCreationScreen.gd # Full character builder
│       └── PauseMenu.gd             # In-fight pause
│
├── scenes/
│   ├── main/
│   │   ├── Main.tscn                # Entry point scene (runs tests or game)
│   │   └── Main.gd                  # Bootstrap script
│   ├── fight/
│   │   ├── FightScene.tscn          # 3D fight arena scene
│   │   └── FightScene.gd            # Fight orchestration
│   ├── career/
│   │   └── CareerScene.tscn         # Career mode scenes
│   └── ui/
│       └── UIComponents.tscn        # Reusable UI panels
│
├── data/
│   ├── Fighters/                    # Fighter .tres files (or static data)
│   └── Styles/                      # Style .tres files
│
├── tests/
│   ├── test_animation.gd            # IK, trajectories, hit detection, recovery
│   ├── test_fighter_data.gd         # FighterData, Factory, variants (30 tests)
│   ├── test_combat.gd              # ImpactCalculator, stun rules
│   ├── test_career.gd              # CareerMap, TrainingCamp, InjurySystem
│   ├── test_match_manager.gd       # Match flow, scoring
│   └── test_ai_controller.gd       # AI decision-making
│
└── docs/
    ├── move-data-and-combos.md      # 60+ move reference
    ├── stun-system.md               # Hit reaction tiers
    ├── move-xp-proficiency-system.md # Per-strike XP progression
    └── move-variant-system.md       # Variant definitions
```

---

## PART 3: COMBAT SYSTEM (UFC 6 ACCURATE)

### 3.1 Frame Data Standards

UFC 6 runs at 60fps. Frame data is the backbone of every interaction:

**Frame types:**
- **Startup frames** — The time from button press to the first active frame. During this window, the strike can be interrupted (countered). UFC 6 jabs: 2-4f startup. Hooks: 6-8f. Head kicks: 12-15f.
- **Active frames** — The frames where the hitbox is dangerous and can connect. Jabs: 2-3f. Roundhouses: 4-5f.
- **Recovery frames** — The time after active frames where the fighter returns to guard. During recovery, the fighter is vulnerable. UFC 6 whiff recovery is significantly longer than hit recovery.

**UFC 6 Accurate Frame Table (baseline, SPD=50, no modifiers):**

| Move | Startup | Active | Recovery | Total | Reach | Notes |
|------|---------|--------|----------|-------|-------|-------|
| Jab | 3f | 3f | 5f | 11f | 1.2m | Fastest strike, lowest damage |
| Cross | 5f | 4f | 7f | 16f | 1.3m | Power punch, slight tell |
| Hook | 7f | 4f | 9f | 20f | 1.0m | Wide arc, higher stun |
| Uppercut | 6f | 4f | 8f | 18f | 0.8m | Close range only |
| Overhand | 9f | 5f | 12f | 26f | 1.1m | Very telegraphed, KO power |
| Superman | 12f | 4f | 14f | 30f | 1.6m | Huge commit, huge range |
| Front Kick | 7f | 4f | 8f | 19f | 1.6m | Push range, low stun |
| Roundhouse | 10f | 5f | 14f | 29f | 1.8m | Committal, high damage |
| Leg Kick | 7f | 4f | 8f | 19f | 1.5m | Low risk, limb damage |
| Head Kick | 13f | 5f | 18f | 36f | 1.8m | Very high risk, KO potential |
| Switch Kick | 14f | 5f | 16f | 35f | 1.8m | L/R switch, confusing |
| Question Mark | 15f | 5f | 20f | 40f | 1.9m | Mid-trajectory change |
| Axe Kick | 16f | 5f | 18f | 39f | 1.7m | Vertical strike |
| Knee (clinch) | 4f | 3f | 6f | 13f | 0.6m | Clinch powerhouse |
| Elbow (clinch) | 5f | 3f | 8f | 16f | 0.5m | Cut machine |

**Stat-modified frame calculation (exact UFC 6 formula):**
```
startup  = max(1, int(base_startup * SPD_mult * gassed_mult / limb_speed))
active   = max(1, int(base_active * SPD_mult / limb_speed))
recovery = max(1, int(base_recovery * SPD_mult * gassed_mult * combo_penalty / limb_speed))
```

### 3.2 Hitbox System (UFC 6 Accurate)

UFC 6 uses capsule-based hitboxes with per-zone dimensions:

**Fighter Hitbox Zones (in meters, relative to character root):**

| Zone | Shape | Dimensions | Position Offset |
|------|-------|-----------|-----------------|
| Head | Capsule | R=0.12, H=0.20 | y=+1.28 |
| Torso | Capsule | R=0.18, H=0.44 | y=+0.90 |
| Left Arm | Capsule | R=0.06, H=0.30 | x=-0.35, y=+0.95 |
| Right Arm | Capsule | R=0.06, H=0.30 | x=+0.35, y=+0.95 |
| Left Leg | Capsule | R=0.08, H=0.40 | x=-0.12, y=+0.45 |
| Right Leg | Capsule | R=0.08, H=0.40 | x=+0.12, y=+0.45 |

**Strike Hitbox dimensions (attacker's fist/foot tip):**
- Punch: Sphere R=0.08
- Kick: Capsule R=0.10, H=0.20 (shin contact area)
- Knee: Sphere R=0.10
- Elbow: Sphere R=0.08

**Hit detection flow (exact UFC 6 method):**
```
1. During active frames, the strike's hitbox is a SWEPT CAPSULE from the previous frame's
   fist position to the current frame's fist position (prevents tunnel-through at high speed)
2. Intersect the swept capsule against each opponent body capsule
3. The first zone intersected is the hit zone (head > torso > arms > legs priority)
4. Penetration depth = how far the fist traveled INTO the capsule (affects damage)
5. If penetration > 0 → clean hit. If penetration < 0 but within 0.05m → glancing blow
```

### 3.3 Damage Formula (UFC 6 Physics-Based)

```gdscript
func resolve_strike(attacker, defender, strike_type, target_zone, velocity, 
                    is_counter, range_at_impact, perfect_timing) -> HitResult:
    # STEP 1: Base damage from move config
    raw = get_move_config(strike_type).base_damage
    
    # STEP 2: Strength modifier (0-100 STR → ×1.0 to ×2.0)
    raw *= (1 + attacker.strength * 0.01)
    
    # STEP 3: Skill accuracy (governing skill 0-100 → ×0.5 to ×1.0)
    skill = attacker.get_skill(skill_for_strike(strike_type))
    raw *= (0.5 + skill / 200)
    
    # STEP 4: Range falloff (UFC 6: -15% per 0.1m from optimal, min 20%)
    range_error = abs(range_at_impact - optimal_range)
    raw *= max(0.2, 1 - range_error * 0.15)
    
    # STEP 5: Velocity bonus (limb tip speed m/s, +5% per m/s, cap ×2.0)
    raw *= clamp(1 + velocity.length() * 0.05, 0.8, 2.0)
    
    # STEP 6: Counter bonus (UFC 6: ×1.35)
    if is_counter: raw *= 1.35
    
    # STEP 7: Perfect timing (UFC 6: ×1.25 on LT press at contact frame)
    if perfect_timing: raw *= 1.25
    
    # STEP 8: Defender mitigation (toughness 0-100 → ×1.0 to ×0.65)
    mitigated = raw * (1 - defender.toughness * 0.0035)
    
    # STEP 9: Gassed penalty (UFC 6: +20% damage taken when gassed)
    if defender.is_gassed(): mitigated *= 1.2
    
    # STEP 10: Zone-specific multipliers (UFC 6 head shots deal 1.5×)
    match target_zone:
        "head": mitigated *= 1.5
        "torso": mitigated *= 1.0
        "limb": mitigated *= 0.7  # Limb shots drain stamina, not health
    
    return HitResult(damage=raw, mitigated=mitigated, stun_level=..., ...)
```

### 3.4 Stun System (UFC 6 Design Rules)

| Stun Tier | UFC 6 Equivalent | Trigger |
|-----------|-----------------|---------|
| 1 Daze (0.15-0.35s) | Every clean hit causes a brief flinch | mitigated > 0 (ALWAYS on clean hit) |
| 2 Heavy Daze (0.35-0.5s) | Rocked but can still block | mitigated > chin × 0.6 |
| 3 Stun (0.8-1.5s) | Guard drops, can't act | mitigated > chin × 1.0 OR counter hit (GUARANTEED) |
| 4 Heavy Stun (1.5-2.5s) | Staggering backward, full vulnerable | mitigated > chin × 1.5 |
| 5 Knockdown (3-5s) | Fighter falls, referee count begins | mitigated > chin × 2.0 |
| 6 KO (fight over) | Unconscious, fight ends | mitigated > chin × 3.0 |

### 3.5 Block System (UFC 6 Accurate)

| Block Type | Damage Reduction | Stamina Cost | Guard Break At |
|-----------|-----------------|-------------|----------------|
| High Block (head) | -70% | 1.5/hit | Stamina depleted |
| Low Block (body/legs) | -50% | 2.0/hit | Stamina depleted |
| Partial (late block) | -40% | 1.5/hit | — |
| Parry (perfect timing) | 100% (0 dmg) | 2.0 | — |
| Block broken (stamina=0) | -30% + full stun | — | Guard break animation |

---

## PART 4: FIGHTER STATE MACHINE

### 4.1 States & Transitions

```
┌─────────────┐     clinch_entry     ┌──────────┐
│  STAND_UP   │ ──────────────────→ │  CLINCH  │
│             │ ←────────────────── │          │
│  punches,   │   clinch_break      │ knees,   │
│  kicks,     │                     │ elbows,  │
│  head_move, │                     │ pummel,  │
│  takedown   │                     │ cage_push│
└──────┬──────┘                     └────┬─────┘
       │                                 │
       │ takedown              clinch_td │
       ▼                                 ▼
┌──────────────┐               ┌──────────────┐
│ GROUND_TOP   │               │ GROUND_BOTTOM│
│              │               │              │
│ GNP, pass,   │ ←── sweep ──→ │ sweeps,      │
│ posture, sub │               │ frames,      │
│              │               │ getup, sub   │
└──────┬───────┘               └──────┬───────┘
       │                              │
       │ sub_attempt         sub_bottom │
       ▼                              ▼
┌──────────────┐            ┌──────────────┐
│ SUBMISSION   │            │ SUBMISSION   │
│ (top)        │            │ (bottom)     │
│ tap_out=WIN  │            │ tap_out=LOSS │
└──────────────┘            └──────────────┘

KO ←── Any state when chin threshold exceeded
```

### 4.2 Per-State Availability Matrix

| Action | STAND_UP | CLINCH | GROUND_TOP | GROUND_BOTTOM | SUB |
|--------|----------|--------|------------|---------------|-----|
| Jab/Cross/Hook | ✓ | ✓ (dirty) | ✓ (GNP) | ✗ | ✗ |
| Kicks | ✓ | ✗ | ✗ | ✗ | ✗ |
| Knees | ✓ (close) | ✓ | ✗ | ✗ | ✗ |
| Elbows | ✓ (close) | ✓ | ✓ (GNP) | ✗ | ✗ |
| Block | ✓ | ✗ | ✗ | ✗ | ✗ |
| Slip/Duck/Weave | ✓ | ✗ | ✗ | ✗ | ✗ |
| Parry | ✓ | ✗ | ✗ | ✗ | ✗ |
| Clinch Entry | ✓ | — | — | — | — |
| Clinch Break | — | ✓ | — | — | — |
| Takedown (shot) | ✓ | — | — | — | — |
| Takedown (clinch) | — | ✓ | — | — | — |
| Sprawl | ✓ | — | — | — | — |
| Ground Transition | — | — | ✓ | ✓ | ✗ |
| Sweep | — | — | ✗ | ✓ | ✗ |
| GNP | — | — | ✓ | ✗ | ✗ |
| Submission | — | — | ✓ | ✓ | ✓ |
| Cage Push | — | ✓ | — | — | — |
| Wall Walk | — | — | — | ✓ (cage) | — |
| Getup | — | — | ✓ | ✓ | — |

### 4.3 Ground Position Chain

```
OPEN_GUARD → HALF_GUARD → SIDE_CONTROL → MOUNT → BACK_MOUNT
     ↑            ↑            ↑            ↑         ↑
   sweep        sweep        sweep        sweep     sweep

Progress rate = (attacker_skill - defender_skill) * 0.003 + random(0, 0.01)
Fighter advances when bar fills to 100%
```

---

## PART 5: CAREER MODE (UFC 6 DEEP)

### 5.1 Career Loop

```
CREATE FIGHTER → Rank #50 (bottom)
  → Fight local circuit bouts (3 rounds × 3min)
  → Win/Loss affects ranking
  → Training camps between fights (6 weeks)
  → Rise through ranks: Regional → National → World
  → Title fight at Rank #1
  → Defend title or move weight class
  → Retire when age > 42 or record hits 50 fights
```

### 5.2 Training Camp System

Each camp week = 1 training session. You have 6 weeks between fights.

**Training Activities (choose 1 per week):**
| Activity | Stat Gained | XP Gained | Injury Risk |
|----------|------------|-----------|-------------|
| Sparring (Boxing) | Boxing +2-4 | 20 | Medium (cuts) |
| Sparring (Muay Thai) | Muay Thai +2-4 | 20 | Medium (bruising) |
| Wrestling Drills | TD Off/Def +2-4 | 20 | Low |
| BJJ Rolling | Sub Off/Def +2-4 | 20 | Low |
| Pad Work | Power +1-2 | 15 | Very Low |
| Road Work | Endurance +2-3 | 10 | Very Low |
| Speed Drills | Speed +1-2 | 15 | Very Low |
| Strength Training | Strength +1-2 | 10 | Low |
| Technique Film | Skill +1 (all) | 5 | None |
| Weight Cut | — | — | High (health risk) |
| Injury Rehab | — | 10 | Reduces recovery time |

**Training restrictions:**
- Cannot train the same skill twice in a row (UFC 6 prevents grinding)
- Each camp has a "focus" — choose striking, grappling, or cardio
- Focus gives +50% gains to that category, -25% to others
- Overtraining a body part increases injury risk for that zone

### 5.3 Fight Card & Ranking

```
Ranking Ladder (50 → 1):
- Win: +3-8 ranks (varies by opponent rank)
- Loss: -2-5 ranks
- Title shot at Rank #1-3
- Title defense: must defend every 3 fights or be stripped

Fight Card Generation:
- Every 3-5 in-game weeks, a new fight offer appears
- Options: accept, reject (no penalty, but less frequent offers)
- Opponent styles are randomized but weighted toward the division's style mix
- Fight difficulty scales with rank
```

### 5.4 Fighter Profile (Career Stats)

```gdscript
class FighterProfile:
    # Identity
    var fighter_name: String
    var nickname: String
    var age: int (18-42, career starts at 18-25)
    var weight_class: int
    var nationality: String
    var height_ft/in: int
    var reach_inches: float
    
    # Record
    var wins: int
    var losses: int
    var draws: int
    var kos: int
    var subs: int
    var decisions: int
    
    # Ranking
    var rank: int (1-50, 1=champion)
    var rank_progression: Array[int] (history for graph)
    
    # Career earnings
    var fight_purse: int (starts at $500, title fights at $100k+)
    var sponsor_income: int (unlocked at rank ≤ 20)
    var total_earnings: int
    
    # Injury history
    var active_injuries: Array[Injury]
    var healed_injuries: Array[Injury]
    
    # Style
    var primary_style: String
    var secondary_style: String
```

---

## PART 6: INJURY SYSTEM (UFC 6 ACCURATE)

### 6.1 Injury Types

UFC 6 features 12+ injury types with varying severity, recovery times, and stat impacts:

| Injury | Cause | Severity | Recovery | Stat Penalty | Visual |
|--------|-------|----------|----------|-------------|--------|
| Cut (superficial) | Sharp strike (elbow) | Mild | 1-3 days | None | Small blood drip |
| Cut (deep) | Multiple elbow/hook hits | Moderate | 5-10 days | -5% chin | Visible gash, blood stream |
| Cut (severe) | Deep cut reopened | Severe | 2-4 weeks | -15% chin | Doctor check, heavy bleed |
| Swelling (mild) | Blunt head strikes | Mild | 2-4 days | -5% vision | Slight puffiness |
| Swelling (severe) | Repeated head blunt | Moderate | 1-2 weeks | -20% vision | Eye nearly closed |
| Broken nose | Head strike, hook/overhand | Moderate | 3-6 weeks | -10% breathing/stamina | Bent nose, heavy bleed |
| Broken orbital | Head kick, elbow, heavy hook | Severe | 6-10 weeks | -25% vision/chin | Massive swelling |
| Broken jaw | Clean cross/overhand | Critical | 8-12 weeks | -40% chin/breathing | Fighter can't eat (weight issues) |
| Broken hand | Hard punch, poor form | Moderate | 4-8 weeks | -30% punch damage | Hand wrapped, reduced power |
| Broken foot | Hard kick, checked kick | Moderate | 4-6 weeks | -25% kick damage | Limping, reduced mobility |
| Broken ribs | Body kick, knee | Severe | 6-10 weeks | -20% stamina, -15% breathing | Heavy breathing, wincing |
| Torn ACL | Takedown, pivot, kick | Critical | 6-12 months | -30% speed/mobility | Knee brace, obvious limp |
| Torn MCL | Clinch, grappling | Severe | 3-6 months | -20% speed, -15% TD defense | Knee instability |
| Separated shoulder | Fall, heavy punch | Severe | 8-16 weeks | -35% punch damage/speed | Arm dropped, can't raise |
| Broken leg | Checked kick (leg kick) | Critical | 6-12 months | -50% kick, -20% speed | Visible deformity |
| Concussion | Repeated head trauma | Varies | 2-12 weeks | -15% chin/stun resistance | Dazed, slow reactions |

### 6.2 Injury Resolution Flow (UFC 6)

```
IN-FIGHT:
  Strike connects → damage applied to zone
  → Check cut chance (sharp damage to head): cut_skill × cut_resist
  → Check swelling chance (blunt damage to head): blunt_ratio × swell_resist
  → Check bone break (limb damage > threshold): force × 0.01 > bone_health × 0.5
     - Hand break: punch damage > (hand_health × 2.5)
     - Leg break: checked kick damage > (shin_health × 2.0)
     - Rib break: body damage > (torso_health × 3.0)
  
  → If cut: blood starts, doctor may stop fight (corner/round break check)
  → If bone break: immediate stat penalty, fight may be stopped
  → Swelling accumulates over rounds, reducing vision/awareness

POST-FIGHT MEDICAL:
  → Full body scan: all accumulated damage evaluated
  → Injury diagnosis: each zone exceeding threshold generates an injury
  → Severity = accumulated damage / threshold
  → Recovery time = base_recovery × (1 - injury_recovery_stat × 0.005)
  → Medical suspension: fighter CANNOT fight until cleared
     - No training during medical suspension
     - Can still do light technique work (no contact)

BETWEEN FIGHTS:
  → Injuries heal at rate modified by fighter's injury_recovery stat
  → Training exacerbates injuries (increases recovery time)
  → Resting reduces recovery time (doctor's advice)
  → Severe injuries auto-retire the fighter (career-ending)
```

### 6.3 Doctor Stoppage Logic (UFC 6)

```
Between rounds, doctor checks:
  If cut is severe AND blood is affecting vision → doctor stoppage (TKO via cut)
  If swelling has closed an eye → doctor stoppage
  If fighter is showing concussion symptoms (2+ heavy stuns in 1 round) → doctor stoppage

Doctor probability:
  base_chance = 0.2 (per injury check)
  +0.1 if cut is deep
  +0.2 if cut is severe
  +0.1 if swelling is severe (closed eye)
  +0.3 if 2+ heavy stuns in same round
```

### 6.4 Weight Cutting System (UFC 6)

```gdscript
# Fighters must weigh in at their chosen weight class
# Weight cut is optional but improves speed at cost of stamina

class WeightCut:
    var target_weight_class: int
    var water_weight_to_lose: float  # kg
    var current_cut_progress: float  # 0.0-1.0
    
    # Per day of cutting:
    # - Losing weight = -2% stamina per kg (compounds)
    # - Speed bonus = +1% per kg (diminishing at 5kg+)
    # - Health risk: cutting > 5kg adds injury risk to fight
    # - Failed cut: weigh-in miss → fight cancelled OR catchweight (-20% purse)
```

---

## PART 7: CHARACTER CREATION SYSTEM (UNIQUENESS PARAMOUNT)

### 7.1 Creation Flow

```
STEP 1: BODY TYPE
  Height: 5'0" to 7'0" (affects reach, speed, power)
  Reach: proportional to height + slider offset (±4")
  Build: Lean / Athletic / Muscular / Stocky (affects base stats + appearance)
  Weight Class: auto-suggested by height/build, can override

STEP 2: BASE STATS (allocate 200 points across 4 stats, max 85 per stat)
  Strength: Knockout power, clinch control, takedown power
  Speed: Strike speed, reaction time, foot speed
  Endurance: Max stamina, recovery rate, cardio
  Toughness: Damage mitigation, chin, injury resistance

STEP 3: STYLE SELECTION
  Primary Style (determines starting skill distribution + special perks):
    Boxing | Muay Thai | Kickboxing | Karate | Wrestling | BJJ | Judo | Sambo | Taekwondo
  Secondary Style (provides +10 to 2 skills from that style):
    Any style (can be same as primary for specialization)
  
  Style affects:
  - Starting skill distribution (+15 to primary style skills, +5 to related)
  - Preferred combat range
  - Special mechanic (unique per style)

STEP 4: VISUAL CUSTOMIZATION
  Skin Tone: 8 presets
  Hair Style: 12 options (bald, short, long, braids, etc.)
  Hair Color: 8 options
  Shorts Color: Primary + accent
  Gloves Color: Red/Blue team assignment
  Tattoos: 24 placement+design combinations
  Face Shape: 6 presets (affects cut/hit boxes slightly)

STEP 5: NAME & NATIONALITY
  Fighter Name (text input)
  Nickname (text input, shows on HUD during fights)
  Nationality (affects flag display + announcer lines)

STEP 6: STARTING VARIANT LOADOUT
  Primary strike type gets 1 free variant from primary style
  Default variant for all other strikes
```

### 7.2 Uniqueness Guarantee

No two created fighters can be identical because:
1. **206 possible height/reach combinations**
2. **200 stat allocation points across 4 stats** = 1,333,700 possible splits
3. **9 primary × 9 secondary styles** = 81 style combinations
4. **80+ move variants** with purchase history = billions of loadout configurations
5. **Injury history** scars the fighter's career permanently
6. **Fight record + opponent quality** = unique progression path

---

## PART 8: AI OPPONENT (TACTICAL)

### 8.1 AI Behavior Layers

```
TICK RATE: Every physics frame (60fps)

LAYER 1: RANGE MANAGEMENT
  if range > preferred × 1.5 → advance (lunge)
  if range < preferred × 0.5 → retreat (create space)
  if range == preferred → stay, look for openings

LAYER 2: DEFENSE REACTION
  if opponent.is_attacking AND fsm.attack_cooldown > 0.1:
    if range > 1.5 → block (high probability)
    if range < 1.5 → slip/duck (reaction-based)
    if opponent threw hook → duck
    if opponent threw straight → slip left or right
  
LAYER 3: OFFENSE SELECTION
  if opening detected (opponent recovery frames):
    pick strike based on range + style profile:
      close range → hook, uppercut, knee
      medium → cross, front kick, jab
      far → roundhouse, teep, feint
  
LAYER 4: STRATEGIC (UFC 6 AI)
  if won last round → conservative, counter-fighting
  if lost last round → aggressive, pressure
  if stamina < 30% → defensive, minimal output
  if opponent stamina < 30% → swarm, volume strikes
  if round ≤ 2 and losing → desperate, all-or-nothing
```

### 8.2 Style Profiles

| Style | Strike Weight | Grapple Weight | Preferred Range | Aggression | Special Tactic |
|-------|:------------:|:--------------:|:---------------:|:----------:|----------------|
| Boxing | 1.3 | 0.3 | 1.2m | Moderate | Check hooks, body work |
| Muay Thai | 1.2 | 0.7 | 1.5m | High | Clinch knees, leg kicks |
| Kickboxing | 1.3 | 0.2 | 1.8m | Moderate | Switch kicks, combos |
| Karate | 1.2 | 0.2 | 2.0m | Low | Blitz, bladed stance |
| Wrestling | 0.5 | 1.5 | 0.8m | Moderate | Chain takedowns, top pressure |
| BJJ | 0.3 | 1.6 | 0.6m | Low | Pull guard, sub hunting |
| Judo | 0.5 | 1.3 | 0.8m | Moderate | Clinch throws, trips |
| Sambo | 0.7 | 1.2 | 1.0m | High | Leg locks, reactive shots |
| Taekwondo | 1.1 | 0.2 | 2.0m | Moderate | Spinning kicks, head kicks |

---

## PART 9: UI / HUD (MINIMAL, VF1-INSPIRED)

### 9.1 In-Fight HUD Layout

```
┌────────────────────────────────────────────────────────┐
│  RED FIGHTER NAME     [▮▮▮▮▮▮▮▮▮▮] HP     ROUND 1     │
│  RECORD: 18-2 (16 KO) [▮▮▮▮▮▮▮▮▮▮] STM    ⏱ 4:32      │
│                                                   │
│                   [3D ARENA VIEW]                   │
│                                                   │
│  BLUE FIGHTER NAME    [▮▮▮▮▮▮▮▮▮▮] HP              │
│  RECORD: 14-3 (9 SUB) [▮▮▮▮▮▮▮▮▮▮] STM    ⚠ STUNNED │
└────────────────────────────────────────────────────────┘
```

Health bars: Green > Yellow > Red threshold at 30%.
Stamina bars: Green > Orange > Red at 20%.
Status indicators: DAZED | STUNNED | WOBBLY | BLEEDING | BROKEN (limb).

### 9.2 Career Mode Screens

- **Career Dashboard**: Fighter stats, recent fights, next fight offer, injury status
- **Training Camp**: Calendar view, select weekly training, see projected stat changes
- **Fight Card**: Opponent scouting report (height/reach/style/record/strengths/weaknesses)
- **Medical Report**: Full injury breakdown, recovery timeline, recommended rest
- **Move Proficiency**: Per-strike XP, level, purchased/equipped variants
- **Rankings**: Division top 10, championship history

---

## PART 10: DATA TABLES (INLINE)

### 10.1 Core Fighter Attributes Schema

```gdscript
# Each fighter has these fields:
# IDENTITY
fighter_name: String
nickname: String
weight_class: int (0=Straw…8=HW)
nationality: String
age: int
reach_inches: float
height_ft: int / height_in: int
stance: int (0=Orthodox, 1=Southpaw)

# CORE STATS (0-100)
strength: float
speed: float
endurance: float
toughness: float

# 18 SKILLS (0-100)
boxing, kickboxing, muay_thai, head_movement, footwork,
clinch_offense, clinch_defense, clinch_takedown,
td_offense, td_defense, counter_td, cage_wrestling,
top_control, bottom_control, guard_pass, guard_retention,
sub_offense, sub_defense

# HEALTH PROFILE
chin: float
cut_resistance: float
swell_resistance: float
bleed_resistance: float
limb_health: float
injury_recovery: float
bone_density: float   # NEW for UFC 6 bone break system

# STAMINA PROFILE
max_stamina_rating: float
drain_rate_rating: float
recovery_rate_rating: float
gassed_threshold_rating: float
cardio_drop_rating: float

# STYLE
primary_style: String
```

### 10.2 The 6 Pre-Made Fighters

```
1. IVAN DRAKOV — "The Hammer" — HW (8) — Boxing, 18-2 (16 KO)
   STR 92, SPD 38, END 55, TGH 85
   Elite boxing (82), terrible ground game (sub_off=10, td_def=60)
   Glass cannon power puncher. Weak cardio. Chin: 88

2. KENJI TAKESHI — "The Octopus" — LW (4) — Wrestling, 14-3 (9 SUB)
   STR 60, SPD 72, END 82, TGH 65
   Elite TDs (88), suffocating top game. Suspect chin (60). 
   Volume grappler, takes opponents deep.

3. DAMIEN CRUZ — "The Phantom" — WW (5) — Karate, 22-4 (11 KO)
   STR 68, SPD 88, END 72, TGH 58
   Elite kickboxing (92) and footwork (92). Suspect TDD (td_def=62).
   Stay at range, kick the legs, never grapple.

4. MARCUS STEELE — "The All-Around" — MW (6) — Generic MMA, 12-1 (4 KO, 3 SUB)
   STR 65, SPD 68, END 72, TGH 62
   Well-rounded (all skills 50-65). No elite skill, no critical weakness.
   Control the pace, win by decision.

5. HIRO TANAKA — "The Cobra" — FW (3) — BJJ, 16-5 (14 SUB)
   STR 48, SPD 75, END 78, TGH 55
   Elite sub_offense (95). Terrible stand-up (boxing=38).
   Pull guard, hunt submissions, survive the striking exchanges.

6. LUCIANA SANTOS — "The Hurricane" — Straw (0) — Muay Thai, 10-1 (3 KO)
   STR 55, SPD 88, END 85, TGH 48
   Elite muay thai (88), volume striking. Weak TDD (45).
   Smother in clinch, land knees, never let them breathe.
```

---

## PART 11: BUILD ORDER FOR CLAUDE CODE

Follow this exact order to build the game incrementally with testable checkpoints:

### Phase 1: Project Setup & Core Data
```
Files to create:
  project.godot — Godot 4.4 project, GL Compatibility renderer
  scripts/autoload/CombatGlobals.gd — All enums + formulas
  scripts/fighter/FighterData.gd — Stat block, health pools, stamina
  scripts/fighter/FighterFactory.gd — Fighter creation from data
  scripts/fighter/StyleData.gd — Style definitions + modifiers

Validation: Run test_fighter_data.gd — 30 tests, all green
```

### Phase 2: Combat Math (Testable in Isolation)
```
Files to create:
  scripts/combat/ImpactCalculator.gd — Complete damage/stun resolution
  scripts/combat/HitDetection.gd — Capsule intersection
  scripts/animation/StrikePlanner.gd — 10 strike trajectories
  scripts/animation/LimbSolver.gd — FABRIK IK
  scripts/animation/ContactDetector.gd — Swept capsule check
  scripts/animation/RecoveryPlanner.gd — Recovery frame calculation

Validation: Run test_animation.gd — 18 tests, all green
```

### Phase 3: Fighter State Machine
```
Files to create:
  scripts/fighter/FighterStateMachine.gd — Full FSM with all states
  scripts/control/InputBuffer.gd — Input history + combo detection
  scripts/control/InputSetup.gd — Key bindings
  scripts/control/ControlMap.gd — Action routing per state
  scripts/combat/BlockSystem.gd — Block/parry/reduced damage

Validation: Manual — spawn two fighters, verify state transitions
```

### Phase 4: Match System
```
Files to create:
  scripts/match/MatchManager.gd — Round timer, scoring, KO resolution
  scripts/match/JudgeScorer.gd — 10-9 scoring
  scripts/camera/FightCamera.gd — Third-person orbital

Validation: Run test_match_manager.gd — 10 tests
```

### Phase 5: 3D Visual Layer
```
Files to create:
  scripts/fighter/FighterCharacter.gd — Skeleton3D + hitboxes + IK nodes
  scenes/fight/FightScene.tscn — Arena with octagon
  scripts/autoload/LimbTracker.gd — Bone velocity capture

Validation: Run test_limb_tracker.gd + test_fighter_character.gd — 24 tests
```

### Phase 6: Progression & Variants
```
Files to create:
  scripts/progression/MoveVariantData.gd — Variant class
  scripts/progression/MoveVariantDatabase.gd — 80+ variants
  scripts/progression/MoveChallengeDatabase.gd — Challenges

Validation: Run fighter data tests — variant purchase/equip/XP verified
```

### Phase 7: AI
```
Files to create:
  scripts/ai/AIController.gd — Full tactical AI
  scripts/ai/StyleProfiles.gd — Behavior weights

Validation: Run test_ai_controller.gd — 12 tests
```

### Phase 8: Injury System
```
Files to create:
  scripts/progression/InjurySystem.gd — 12+ injuries, recovery, doctor scope
  scripts/progression/FighterProfile.gd — Career record + injury history

Validation: Manual — verify injury triggers, recovery timeline, career stats
```

### Phase 9: Career Mode
```
Files to create:
  scripts/progression/CareerMap.gd — Fight card generation, ranking ladder
  scripts/progression/TrainingCamp.gd — Weekly training loop

Validation: Manual — simulate full career loop
```

### Phase 10: Character Creation
```
Files to create:
  scripts/character_creation/CharacterBuilder.gd — Full creation flow
  scripts/character_creation/BodyTypeData.gd — Height/reach presets
  scripts/character_creation/StyleSelector.gd — Style selection
  scenes/character_creation/ — UI screens

Validation: Manual — create 5 distinct fighters, verify stat spreads
```

### Phase 11: UI & Polish
```
Files to create:
  scripts/ui/FightHUD.gd — In-fight overlay
  scripts/ui/CareerScreen.gd — Career dashboard
  scripts/ui/TrainingScreen.gd — Training camp UI
  scripts/ui/FightCardScreen.gd — Fight selection
  scripts/ui/InjuryReport.gd — Medical review
  scripts/ui/CharacterCreationScreen.gd — Character builder

Validation: Manual — full game flow from character creation → career → fight
```

---

## PART 12: KEY TECHNICAL DECISIONS

### Physics-First, Not Animation-First
Impact velocity is calculated from the attacking limb's tip velocity. The LimbTracker captures actual bone positions each frame and derives velocity from position deltas. Not from a pre-baked animation table.

### Procedural Animation via FABRIK IK
No pre-made animations. The LimbSolver solves a 2-bone IK chain (shoulder→elbow→fist) to place the fist at the strike trajectory target position each frame. The StrikePlanner generates the target path as a parametric curve.

### Capsule-Based Hitboxes
All body zones are capsule colliders. Strike hitboxes are swept-spheres (tunnel prevention). No mesh-based collision. Pure math intersection tests.

### Data-Driven Fighters
All 6 pre-made fighters and the character creation system feed into the same FighterData schema. The same stat block drives both pre-made and created characters.

### Per-Strike XP (Not Global)
XP is earned per strike type based on damage dealt. You cannot grind jabs to unlock head kick variants. This forces strategic diversity.

### Variants Are Build Choices, Not In-Fight Modifiers
Once purchased and equipped, a variant permanently changes that strike's properties. No mid-fight switching. This makes pre-fight strategy meaningful.

---

## PART 13: TESTING STANDARDS

- All combat math must be testable in headless mode (no 3D scene)
- Tests use `xvfb-run godot4 --headless --path . --quit` for full engine boot
- Each test file returns 0 = all passed, 1 = any failed
- Frame data tests must be deterministic (seed RNG)
- Stun/KD/KO probabilities verified with 1000 Monte Carlo trials
- No `class_name` on RefCounted scripts (use preload paths)
- No `@export` untyped vars (Godot 4.4 requirement)

---

> **Claude Code: Begin with Phase 1 (project.godot + CombatGlobals + FighterData + FighterFactory + StyleData).**
> **After each phase, run all tests in that phase before moving to the next.**
> **The existing codebase at /root/gladiator_ultra/ has Phases 1-6 partially implemented.**
> **Use the existing code as reference, but rebuild for Three.js if Joshua specifies a browser target.**
