# Gladiator Ultra — Move Data & Combo Tree Reference

> **Frame baseline:** 60fps (1 frame = 16.67ms)
> **Stat baseline:** SPD=50, STR=50, all combat skills=50 (no style modifiers)
> **Stance:** Orthodox, neutral range
> **Values marked †** are stat-modified at runtime by StrikePlanner

---

## 1. Stand-up Strikes

### 1.1 Punch Table

| ID | Move | Input | Startup | Active | Recovery | Total | Reach | Base Dmg | Stun | Stamina | Target | Skill |
|----|------|-------|---------|--------|----------|-------|-------|----------|------|---------|--------|-------|
| S01 | Jab | A (tap) | 3† | 3† | 5† | 11† | 1.2m | 5 | Daze | 2.0 | Any | Boxing |
| S02 | Cross | A (hold) | 5† | 4† | 7† | 16† | 1.3m | 9 | Daze | 3.5 | Any | Boxing |
| S03 | Hook | B (tap) | 7† | 4† | 9† | 20† | 1.0m | 12 | Stun | 4.0 | Any | Boxing |
| S04 | Uppercut | B (hold) | 6† | 4† | 8† | 18† | 0.8m | 11 | Stun | 4.0 | Head/Body | Boxing |
| S05 | Overhand | LS→+B | 9† | 5† | 12† | 26† | 1.1m | 14 | KD | 5.0 | Head | Boxing |
| S06 | Superman Punch | LS→+A+LT | 12† | 4† | 14† | 30† | 1.6m | 13 | Stun | 6.0 | Head | Boxing |

### 1.2 Kick Table

| ID | Move | Input | Startup | Active | Recovery | Total | Reach | Base Dmg | Stun | Stamina | Target | Skill |
|----|------|-------|---------|--------|----------|-------|-------|----------|------|---------|--------|-------|
| S07 | Front Kick (teep) | X | 7† | 4† | 8† | 19† | 1.6m | 8 | Push | 3.0 | Body | Kickboxing |
| S08 | Roundhouse | Y | 10† | 5† | 14† | 29† | 1.8m | 14 | Stun | 5.5 | Body/Head | Kickboxing |
| S09 | Leg Kick | RB+X | 7† | 4† | 8† | 19† | 1.5m | 7 | Limb | 3.5 | Leg | Kickboxing |
| S10 | Head Kick | LB+Y | 13† | 5† | 18† | 36† | 1.8m | 18 | KO | 7.0 | Head | Kickboxing |
| S11 | Switch Kick | LT+Y | 14† | 5† | 16† | 35† | 1.8m | 15 | Stun | 6.5 | Body/Head | Kickboxing |
| S12 | Front Kick (body) | LT+X | 8† | 4† | 9† | 21† | 1.6m | 9 | Daze | 3.5 | Body | Kickboxing |
| S13 | Question Mark Kick | LS→+LT+Y | 15† | 5† | 20† | 40† | 1.9m | 17 | KO | 7.5 | Head | Kickboxing |
| S14 | Axe Kick | LS↓+LT+Y | 16† | 5† | 18† | 39† | 1.7m | 16 | KD | 7.0 | Head | Kickboxing |

### 1.3 Close-range Strikes

| ID | Move | Input | Startup | Active | Recovery | Total | Reach | Base Dmg | Stun | Stamina | Target | Skill |
|----|------|-------|---------|--------|----------|-------|-------|----------|------|---------|--------|-------|
| S15 | Knee | LB+A (clinch range) | 4† | 3† | 6† | 13† | 0.6m | 10 | Stun | 3.0 | Body | Muay Thai |
| S16 | Elbow | LB+B (clinch range) | 5† | 3† | 8† | 16† | 0.5m | 13 | Cut | 3.5 | Head | Muay Thai |
| S17 | Body Knee | X (clinch) | 4† | 3† | 6† | 13† | 0.6m | 9 | Daze | 3.0 | Body | Muay Thai |
| S18 | Foot Stomp | LS↓+A (clinch) | 3† | 2† | 4† | 9† | 0.3m | 3 | Limb | 1.0 | Foot | Clinch Off |

### 1.4 Strike Modifiers

| Modifier | Effect | Input | Stamina Bonus |
|----------|--------|-------|---------------|
| **High mod** | Target shifts to HEAD zone | Hold LB | — |
| **Low mod** | Target shifts to BODY/LEG zone | Hold RB | — |
| **Perfect timing** | Damage ×1.25, +10% hit chance | Tap LT on contact frame | +1.0 |
| **Counter** | Damage ×1.35, +15% hit chance | Parry / slip → strike | +2.0 |
| **Lunge** | Forward movement during strike (+0.3m reach) | LS→ + strike | +1.5 |
| **Step-back** | Backward movement during strike (-0.2m reach) | LS↓ + strike | +1.0 |

---

## 2. Takedown & Clinch

### 2.1 Takedowns

| ID | Move | Input | Startup | Active | Recovery | Reach | Base Chance | Stamina | Skill |
|----|------|-------|---------|--------|----------|-------|-------------|---------|-------|
| T01 | Double Leg | LS→+A+LT (hold) | 6† | 8† | 12† | 1.8m | 40%† | 8.0 | TD Off |
| T02 | Single Leg | LS→+X+LT | 8† | 6† | 10† | 1.6m | 35%† | 7.0 | TD Off |
| T03 | Level Change Feint | LS↓+LT+A (tap) | 4† | — | 6† | — | Sets up strike | 2.0 | TD Off |
| T04 | Body Lock TD | LS→+A (clinch) | 4† | 5† | 8† | — | 45%† | 6.0 | Clinch TD |
| T05 | Trip | LS→+B (clinch) | 5† | 4† | 8† | — | 40%† | 6.0 | Clinch TD |
| T06 | Hip Throw | LS↓+LT+B (clinch) | 6† | 4† | 10† | — | 35%† | 7.0 | Judo style |
| T07 | Ankle Pick | LS↓+A (clinch, low) | 5† | 5† | 8† | — | 30%† | 5.0 | Clinch TD |
| T08 | Reactive Shot | LT+LS→+A (after caught kick) | 3† | 5† | 8† | — | 50%† | 5.0 | Counter TD |

### 2.2 Clinch Actions

| ID | Move | Input | Startup | Active | Recovery | Stamina | Effect |
|----|------|-------|---------|--------|----------|---------|--------|
| C01 | Clinch Entry | LS→+A+RB | 5† | — | — | 4.0 | Enters clinch state (range 0.3-0.6m) |
| C02 | Clinch Break | Y (escape) | 3† | — | 6† | 3.0 | Returns to stand-up, contested |
| C03 | Pummel Win | Y (pummel) | 2† | 4† | 2† | 2.0 | Gains control advantage (+20% next clinch action) |
| C04 | Cage Push | RS→+RT | 3† | 6† | 3† | 3.0 | Moves opponent toward cage wall |
| C05 | Wall Walk | LS↑ (near cage, bottom) | 8† | 6† | 4† | 5.0 | Stands up using cage (ground only) |
| C06 | Clinch Knee | LB+A | 4† | 3† | 6† | 3.0 | Body strike, short range |
| C07 | Clinch Elbow | LB+B | 5† | 3† | 8† | 3.5 | Head strike, high cut chance |
| C08 | Dirty Boxing | A→B→A (rapid) | 3† | 2† | 4† | 2.0/short | Flurries at close range |

### 2.3 Counter / Defensive Actions

| ID | Move | Input | Startup | Active | Recovery | Stamina | Effect |
|----|------|-------|---------|--------|----------|---------|--------|
| D01 | Block | Hold RT | 1† | hold | 3† | 1.5/hit | Reduces damage by 60-80%, stamina damage passes through |
| D02 | Parry | RS Click (timed) | 3† | 2† | — | 2.0 | Deflects strike, opens counter window (10 frame window) |
| D03 | Slip (left) | RS← | 1† | 4† | 3† | 1.0 | Evades straight punches, head moves off-center |
| D04 | Slip (right) | RS→ | 1† | 4† | 3† | 1.0 | Evades straight punches |
| D05 | Duck | RS↓ | 2† | 5† | 4† | 1.5 | Evades hooks/head kicks, vulnerable to knees/uppercuts |
| D06 | Weave | RS↻ | 3† | 6† | 4† | 2.0 | Circular head movement, evades combos |
| D07 | Pull Counter | LS↓+A (timed) | 3† | 3† | 6† | 2.5 | Step back + cross counter, extra damage |
| D08 | Sprawl | RT+RS↓ (TD defense) | 2† | 6† | 6† | 4.0 | Defends takedown shot, can chain to front headlock |
| D09 | Whizzer Defense | RT+RS→ (single leg) | 2† | 5† | 5† | 3.0 | Defends single leg, can chain to takedown |
| D10 | Guillotine Attempt | LT+RS↓ (on TD shot) | 4† | 6† | 8† | 5.0 | Sub attempt from sprawl position |

---

## 3. Ground Game

### 3.1 Ground Position Chain

```
OPEN GUARD ──→ HALF GUARD ──→ SIDE CONTROL ──→ MOUNT ──→ BACK MOUNT
(top)    ⬆⬇      (top)    ⬆⬇       (top)    ⬆⬇     (top)   ⬆⬇    (top)
  │                    │                    │               │
  │ Sweep              │ Sweep              │ Sweep         │ Sweep
  ▼                    ▼                    ▼               ▼
BOTTOM              BOTTOM               BOTTOM          BOTTOM
GUARD               HALF                 SIDE            MOUNT
```

| Position | ID | Transition | Direction | Skill Needed | Progress Rate | Stamina |
|----------|----|-----------|-----------|-------------|---------------|---------|
| Open Guard → Half Guard | G01 | Pass Guard | RS↑ | Guard Pass vs Guard Ret | 0.03/s per 10 skill advantage | 6.0 |
| Half Guard → Side Control | G02 | Pass | RS↑ | Guard Pass vs Guard Ret | 0.025/s | 5.0 |
| Side Control → Mount | G03 | Advance | RS↑ | Top Control vs Bottom Control | 0.04/s | 5.0 |
| Mount → Back Mount | G04 | Take Back | RS↑ | Top Control vs Bottom Control | 0.035/s | 4.0 |
| Mount → Arm Triangle | G05 | Sub Setup | X (from top) | Top Control | Takedown | 3.0 |
| Side → Knee-on-Belly | G06 | Transition | RS↓ | Top Control | 0.05/s | 3.0 |
| Knee-on-Belly → Back | G07 | Spin to Back | RS→ | Top Control vs Bottom Control | 0.04/s | 4.0 |

### 3.2 Ground Bottom Escapes

| Position → Result | ID | Transition | Direction | Skill Needed | Progress Rate | Stamina |
|-------------------|----|-----------|-----------|-------------|---------------|---------|
| Guard → Stand-up | G08 | Stand-up | RS↑ (hold Y) | Bottom Control vs Top Control | 0.025/s | 5.0 |
| Guard → Sweep to Top | G09 | Sweep | A+RS← (A sweep) | Bottom Control vs Top Control | 0.03/s | 5.0 |
| Guard → Butterfly | G10 | Insert Hook | LS↓ | Bottom Control | 0.04/s | 2.0 |
| Butterfly → Single Leg | G11 | Stand-up Base | RS↑+LT | Bottom Control vs Top Control | 0.02/s | 4.0 |
| Half Guard → Deep Half | G12 | Deep Half | LS↓ | Guard Retention | 0.03/s | 2.0 |
| Deep Half → Sweep | G13 | Electric Chair | A (timed) | Bottom Control | 30% burst chance | 5.0 |
| Side → Recover Guard | G14 | Frame & Shrimp | RS→ (direction away) | Bottom Control vs Top Control | 0.02/s | 3.0 |
| Mount → Escape to Half | G15 | Bridge & Roll | RS→ (direction of opponent weight) | Bottom Control vs Top Control | 0.015/s | 5.0 |
| Back Mount → Escape | G16 | Roll | RS← (toward opponent back) | Bottom Control vs Top Control | 0.01/s | 6.0 |

### 3.3 Ground-and-Pound

| ID | Strike | Input | Startup | Active | Recovery | Base Dmg | Stamina | Status |
|----|--------|-------|---------|--------|----------|----------|---------|--------|
| GNP01 | Right Straight (postured) | A | 4† | 3† | 5† | 7+STR | 2.0 | Top only |
| GNP02 | Left Hook (postured) | B | 5† | 3† | 5† | 6+STR | 2.0 | Top only |
| GNP03 | Right Straight (smother) | LT+A | 6† | 3† | 6† | 4+STR | 1.5 | Top only, less power but harder to escape |
| GNP04 | Hammer Fist | LT+A (postured) | 7† | 4† | 6† | 10+STR | 3.0 | Top only, high stun chance |
| GNP05 | Elbow (ground) | LT+B (postured) | 6† | 3† | 7† | 12+STR | 3.5 | Top only, high cut chance |
| GNP06 | Body Shot | A (hold, postured) | 5† | 3† | 5† | 5+STR | 2.0 | Top only, drains stamina |
| GNP07 | Upward Strike (bottom) | LT+A (guard) | 5† | 3† | 5† | 4+STR | 2.0 | Bottom only, less damage |

---

## 4. Submission Moves

| ID | Submission | Position | Startup | Lock Speed | Escape Speed | Stamina (attacker) | Stamina (defender) | Skill |
|----|-----------|----------|---------|-----------|-------------|--------------------|--------------------|-------|
| SUB01 | Rear Naked Choke | Back Mount | 3† | 0.4/s† | 0.2/s† | 3.0/s | 2.0/s | Sub Off |
| SUB02 | Armbar | Mount / Guard | 4† | 0.3/s† | 0.25/s† | 3.0/s | 2.0/s | Sub Off |
| SUB03 | Triangle Choke | Guard (bottom) | 5† | 0.35/s† | 0.2/s† | 3.5/s | 2.0/s | Sub Off |
| SUB04 | Kimura | Side Control | 4† | 0.3/s† | 0.3/s† | 3.0/s | 2.5/s | Sub Off |
| SUB05 | Guillotine | Front Headlock / Sprawl | 3† | 0.4/s† | 0.25/s† | 3.5/s | 2.0/s | Sub Off |
| SUB06 | Arm Triangle | Side / Mount | 5† | 0.3/s† | 0.2/s† | 3.0/s | 2.0/s | Sub Off |
| SUB07 | Omoplata | Guard (bottom) | 6† | 0.25/s† | 0.3/s† | 3.5/s | 2.5/s | Sub Off |
| SUB08 | Heel Hook | 50-50 / Leg entangle | 4† | 0.5/s† | 0.15/s† | 4.0/s | 2.0/s | Sub Off |

**Submission victory condition:** Attacker fills submission bar to 100%. Defender fills escape bar to 100% to escape. Bars drain at opposing rates when not actively inputting.

**Chain submission cost:** 15 stamina per chain link (transitioning armbar→triangle, etc.)

---

## 5. Combo Trees

### 5.1 Stand-up Punch Combos

```
Level 1 (0-1 strikes landed):
  jab ──────→ cross           (1-2, +0.2s combo window)
  cross ─────→ hook            (2-3, +0.15s)
  hook ──────→ uppercut        (3-4, +0.1s)

Level 2 (2 strikes landed):
  jab → cross ───→ hook        (1-2-3, +0.15s, +10% damage on final)
  jab → cross ───→ uppercut    (1-2-4, +0.1s, +15% damage)
  jab → hook ────→ cross       (1-3-2, +0.15s)
  cross → hook ──→ uppercut    (2-3-4, +0.1s, +15% damage)

Level 3 (3 strikes landed):
  jab → cross → hook ───→ overhand     (1-2-3-5, +20% damage on ender)
  jab → cross → hook ───→ uppercut     (1-2-3-4, +15%)
  jab → cross → uppercut ──→ hook      (1-2-4-3, +10%)
  jab → hook → cross ────→ front_kick  (1-3-2-7, +15%)

Level 4 (4+ strikes, speed/accuracy/defense tradeoff):
  jab → cross → hook → uppercut ──→ head kick    (1-2-3-4-10, -20% accuracy, +50% stamina)
  jab → cross → hook → overhand ──→ roundhouse   (1-2-3-5-8, -25% accuracy, +60% stamina)
```

**Combo rules:**
- Each strike in a chain reduces recovery frames by 5% (combo_chain_bonus)
- Each strike beyond the 3rd suffers -5% accuracy (combo fatigue)
- If ANY strike misses, combo resets and chain bonus is lost
- Chain bonus resets after 0.8s of no strikes landed
- Max chain length: SPD/15 + 2 (SPD 50 = 5 strikes, SPD 90 = 8 strikes)

### 5.2 Kick Combos

```
  front_kick ──→ cross          (long range setup)
  leg_kick ────→ cross ──→ hook (low-high mixup)
  leg_kick ────→ roundhouse     (low-high, +15% hit chance on follow-up)
  roundhouse ──→ hook           (wide strike closes distance)
  front_kick ──→ head_kick      (double kick, +20% stamina cost, high stun)
  switch_kick ─→ cross ──→ leg_kick (L/R switch, confusing rhythm)
```

### 5.3 Strike → Takedown Combos

```
  jab ─────────→ double_leg    (conventional, -20% TD detection)
  cross ───────→ single_leg    (power punch loads into shot)
  hook ────────→ body_lock_td  (close range, hard to deny)
  front_kick ──→ single_leg    (catch kick → reactive shot, +30% success)
  leg_kick ────→ double_leg    (opponent checks kick → level change)
  overhand ────→ double_leg    (overhand → duck under → shot)
```

### 5.4 Clinch Combos

```
  pummel_win ──→ knee ──→ elbow       (control → dirty boxing)
  pummel_win ──→ body_lock_td         (control → takedown)
  knee ────────→ knee ──→ hip_throw   (setup the body for the throw)
  elbow ───────→ clinch_break ──→ cross (create space → power shot)
  cage_push ───→ trip                (cage pressure → trip)
```

### 5.5 Ground Combos

```
TOP:
  gnp_right → gnp_left ────→ gnp_hammer    (standard GNP, low-high mix)
  gnp_right → gnp_left ────→ sub_setup     (stun → submission)
  gnp_elbow ──→ transition_up ──→ mount    (significant strike → advance position)
  posture_up → gnp_heavy ──→ advance_position (choose power or position)

BOTTOM:
  frame(shrimp) → escape_direction ──→ recovery_guard     (defensive chain)
  frame ───────→ sweep (timed) ──→ top_position            (reversal chain)
  hip_escape ──→ arm_drag ──→ take_back                    (advanced reversal)
  pull_guard ──→ sub_attempt (triangle) ──→ sweep_or_finish (offensive guard)
```

---

## 6. Movement & Footwork

| ID | Action | Input | Startup | Active | Recovery | Speed | Stamina | Notes |
|----|--------|-------|---------|--------|----------|-------|---------|-------|
| M01 | Walk Forward | LS↑ | 1† | — | 2† | 1.0-1.8 m/s† | — | Continuous |
| M02 | Walk Backward | LS↓ | 2† | — | 2† | 0.7-1.3 m/s† | — | 70% of forward speed |
| M03 | Lateral Step | LS←/→ | 1† | — | 2† | 0.8-1.5 m/s† | — | Continuous |
| M04 | Lunge (forward burst) | LS↑+A (tap) | 3† | 4† | 4† | 2.0-3.5 m/s† | 2.5 | Closes distance rapidly |
| M05 | Pivot | LS rotation | 3† | — | 4† | Instant direction change | 1.0 | Footwork skill affects speed |
| M06 | Step-back Lunge | LS↓+A (tap) | 3† | — | 5† | 0.5m backward | 2.0 | Evasive, creates space |
| M07 | Blitz (3 rapid steps) | LS↑+A (hold) | 2† | 8† | 6† | 3.0-4.0 m/s† | 3.5 | High commitment rush |
| M08 | Calf Shed | LS↻ (rapid) | 4† | 4† | 4† | In place | 1.5 | Footwork reset, StyleData dependent |

---

## 7. State Machine: Move Availability Per State

| Move Category | STAND-UP | CLINCH | GROUND TOP | GROUND BOTTOM | SUBMISSION |
|---------------|----------|--------|------------|---------------|------------|
| Punches | ✓ | ✓ (dirty boxing) | ✓ (GNP) | ✗ | ✗ |
| Kicks | ✓ | ✗ | ✗ | ✗ | ✗ |
| Knees | ✓ (close range) | ✓ | ✗ | ✗ | ✗ |
| Elbows | ✓ (close range) | ✓ | ✓ (GNP) | ✗ | ✗ |
| Head Movement | ✓ | ✗ | ✗ | ✗ | ✗ |
| Block | ✓ | ✗ | ✗ | ✗ | ✗ |
| Parry | ✓ | ✗ | ✗ | ✗ | ✗ |
| Clinch Entry | ✓ | — | — | — | — |
| Clinch Break | — | ✓ | — | — | — |
| Pummel | — | ✓ | — | — | — |
| Takedown (shot) | ✓ | — | — | — | — |
| Takedown (clinch) | — | ✓ | — | — | — |
| Sprawl | ✓ | — | — | — | — |
| Transition (advance) | — | — | ✓ | ✓ | — |
| Sweep | — | — | ✗ | ✓ | — |
| Getup / Stand | — | — | ✓ | ✓ | — |
| GNP | — | — | ✓ | ✗ | — |
| Sub Attempt | — | — | ✓ | ✓ | — |
| Sub Defense | — | — | — | — | ✓ |
| Cage Push | — | ✓ | — | — | — |
| Wall Walk | — | — | — | ✓ (near cage) | — |
| Scramble | — | — | ✓ | ✓ | — |

---

## 8. Frame Data Modifier Summary

All values marked † are modified at runtime by StrikePlanner using:

```gdscript
startup   = max(1, int(base_startup * SPD_mult * gassed_mult / limb_speed))
active    = max(1, int(base_active * SPD_mult / limb_speed))
recovery  = max(1, int(base_recovery * SPD_mult * gassed_mult * combo_penalty / limb_speed))
reach     = base_reach * stance_mod * limb_power_mod * gassed_mod
damage    = base_damage * STR_mult * limb_power * perfect_mult * counter_mult
stamina   = base_stamina * gassed_mult * combo_penalty
```

| Modifier Source | Condition | Multiplier |
|----------------|-----------|------------|
| SPD 0 | Slowest | Startup ×1.8, Recovery ×1.6 |
| SPD 50 | Baseline | Startup ×1.0, Recovery ×1.0 |
| SPD 100 | Fastest | Startup ×0.6, Recovery ×0.7 |
| Gassed (active) | Stamina < gas threshold | Startup ×1.3, Recovery ×1.5, Reach ×0.85, Damage ×0.7 |
| Limb compromised | HP < 50% | Speed × limb_speed mult, Power × limb_power mult |
| Counter | Successful parry/slip | Damage ×1.35 |
| Perfect timing | LT tap on contact frame | Damage ×1.25, +10% hit chance |
| Combo chain (chain 2) | 2 strikes landed | Recovery ×0.95 |
| Combo chain (chain 3) | 3 strikes landed | Recovery ×0.90 |
| Combo chain (chain 4+) | 4+ strikes landed | Recovery ×0.85, Accuracy ×0.95 |

---

## 9. Resource Data Format (for future .tres)

Each move is designed to be serialized as a Resource:

```gdscript
# Example: res://data/moves/jab.tres
[gd_resource type="Resource" load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/combat/MoveData.gd"]

[resource]
move_id = "S01"
display_name = "Jab"
input_code = "action_a_punch"
available_states = [0]  # STAND_UP only
min_range = 0.5
max_range = 2.0
base_startup = 3
base_active = 3
base_recovery = 5
base_damage = 5.0
stamina_cost = 2.0
stun_level = 1  # DAZE
target_zones = ["head", "body"]
primary_skill = "boxing"
trajectory_func_ref = 0  # enum: JAB_TRAJ
combo_chain_group = "punch_light"
