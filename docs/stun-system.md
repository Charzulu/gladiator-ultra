# Gladiator Ultra — Stun & Hit Reaction System

> **Design rule 1:** Every clean hit (unblocked damage event) guarantees at least a daze.
> **Design rule 2:** Counter hits (parry/slip/recovery punish) guarantee at least a stun.
> **Design rule 3:** Higher stun levels (stun/KD/KO) outside of counters are rare — tied to high-damage moves and damage accumulation.

---

## 1. Hit Reaction Tiers

| Tier | Name | Duration | Effect | Trigger (clean hit) | Trigger (counter hit) |
|------|------|----------|--------|---------------------|-----------------------|
| 0 | None | 0s | No reaction | Blocked / glancing | — |
| 1 | **Daze** | 0.15-0.35s | Brief flinch, fighter recovers instantly. Can block/move at reduced speed (×0.8) during last 0.05s. | **ALWAYS** — any clean hit with mitigated > 0 | Minimum on counter |
| 2 | **Heavy Daze** | 0.35-0.5s | Fighter visibly rocked, can still block. Guard drops 0.3s in. Movement disabled during daze. | mitigated > chin × 0.6 | mitigated > chin × 0.4 (counter lowers threshold) |
| 3 | **Stun** | 0.8-1.5s | Guard completely drops. Fighter vulnerable. Can't block or attack. Can only attempt to clinch to survive. | mitigated > chin × 1.0 | **GUARANTEED** on any counter hit (minimum) |
| 4 | **Heavy Stun** | 1.5-2.5s | Fighter stumbles backward. Can't act at all. Face shows damage. | mitigated > chin × 1.5 | mitigated > chin × 1.0 + counter |
| 5 | **Knockdown** | 3.0-5.0s | Fighter falls to ground. Referee steps in. Fighter can attempt to rise at timer × 0.6. | mitigated > chin × 2.0 | mitigated > chin × 1.5 + counter |
| 6 | **KO** | Fight over | Fighter unconscious. Fight ends via KO. | mitigated > chin × 3.0 | mitigated > chin × 2.0 + counter |

**Threshold comparison (old vs new):**

| Tier | Old threshold | New threshold | Change |
|------|--------------|---------------|--------|
| Daze (T1) | mitigated > chin × 0.8 | **ALWAYS on clean hit** | Massive buff — every hit matters |
| Stun (T3) | mitigated > chin × 1.2 | mitigated > chin × 1.0 (or counter) | Lowered threshold + counter guarantee |
| KD (T5) | mitigated > chin × 1.8 | mitigated > chin × 2.0 | Slightly higher outside counters |
| KO (T6) | mitigated > chin × 3.0 | mitigated > chin × 3.0 (counter: × 2.0) | Unchanged normally, much easier on counters |

---

## 2. Stun Duration Formulas

```gdscript
# Duration in seconds, 60fps

func daze_duration(mitigated: float, chin: float) -> float:
    return clampf(0.15 + mitigated * 0.002, 0.15, 0.35)

func heavy_daze_duration(mitigated: float, chin: float) -> float:
    return clampf(0.35 + mitigated * 0.004, 0.35, 0.5)

func stun_duration(mitigated: float, chin: float) -> float:
    return clampf(0.8 + (mitigated / chin) * 0.5, 0.8, 1.5)

func heavy_stun_duration(mitigated: float, chin: float) -> float:
    return clampf(1.5 + (mitigated / chin) * 1.0, 1.5, 2.5)

func kd_duration(mitigated: float, chin: float) -> float:
    var tgh_mult = 1.0 - (toughness * 0.003)  # tougher = faster to rise
    return clampf((3.0 + (mitigated / chin) * 2.0) * tgh_mult, 3.0, 5.0)
```

---

## 3. ImpactCalculator — Revised Stun Logic

```gdscript
# Inside resolve_strike(), after computing mitigated damage:

var is_counter = result.is_counter
var chin_val = defn.chin
var mitigated = result.mitigated_damage

# ── TIER 1: Every clean hit = at least daze ──
if mitigated > 0.0:
    result.stun_level = 1  # Daze minimum
    result.stun_duration = daze_duration(mitigated, chin_val)
    
    # ── COUNTER: minimum stun (T3) ──
    if is_counter:
        result.stun_level = 3  # Counter = at least stun
        result.stun_duration = stun_duration(mitigated, chin_val)
    
    # ── TIER 2: Heavy Daze ──
    if (mitigated > chin_val * 0.6) or (is_counter and mitigated > chin_val * 0.4):
        result.stun_level = max(result.stun_level, 2)
        result.stun_duration = heavy_daze_duration(mitigated, chin_val)
    
    # ── TIER 3: Stun ──
    if (mitigated > chin_val * 1.0) or is_counter:
        result.stun_level = max(result.stun_level, 3)
        result.stun_duration = stun_duration(mitigated, chin_val)
    
    # ── TIER 4: Heavy Stun ──
    if (mitigated > chin_val * 1.5) or (is_counter and mitigated > chin_val * 1.0):
        result.stun_level = max(result.stun_level, 4)
        result.stun_duration = heavy_stun_duration(mitigated, chin_val)
    
    # ── TIER 5: Knockdown ──
    if (mitigated > chin_val * 2.0) or (is_counter and mitigated > chin_val * 1.5):
        result.stun_level = max(result.stun_level, 5)
        result.stun_duration = kd_duration(mitigated, chin_val, defn.toughness)
        result.is_knockdown = true
    
    # ── TIER 6: KO ──
    if (mitigated > chin_val * 3.0) or (is_counter and mitigated > chin_val * 2.0):
        result.stun_level = max(result.stun_level, 6)
        result.is_ko = true
```

---

## 4. Block Interaction

| Defense | Damage Mitigation | Stun Effect |
|---------|-----------------|-------------|
| No block | Full damage | Full stun as above |
| Block (high) | -70% damage | Tier 1 daze only (0.1s) — no higher tiers |
| Block (low) | -50% damage, stamina×1.5 | Tier 1 daze (0.1s) |
| Block broken (stamina depleted) | -30% damage | Full stun as clean hit + guard break animation |
| Partial block (late block) | -40% damage | Tier 1-2 only (daze/heavy daze) |
| Parry | 0 damage to defender | No stun — attacker enters recovery penalty |
| Slip/Duck | 0 damage if successful | No stun — counter window opens |

---

## 5. Stun State Effects (per tier applied in FighterStateMachine)

| Tier | Can Block? | Can Move? | Can Strike? | Can Clinch? | Can Deny? | Camera |
|------|-----------|-----------|-------------|-------------|-----------|--------|
| 0 (none) | ✓ | ✓ | ✓ | ✓ | ✓ | Normal |
| 1 (daze) | ✓ (×0.8 effect) | ✓ (×0.8 speed) | ✓ (×0.9 acc) | ✓ (×0.85) | ✓ (×0.9) | Subtle shake |
| 2 (heavy daze) | ✓ (×0.5 effect) | ✗ | ✓ (×0.7 acc) | ✓ (×0.6) | ✓ (×0.7) | Medium shake |
| 3 (stun) | ✗ | ✗ | ✗ | ✓ (×0.4) | ✗ | Strong shake, edge blur |
| 4 (heavy stun) | ✗ | ✗ | ✗ | ✗ | ✗ | Extreme shake, fighter voice |
| 5 (KD) | ✗ | ✗ | ✗ | ✗ | ✗ | Slow-mo, crowd roar |
| 6 (KO) | Fight ends. | | | | | White flash, slow-mo fall |

---

## 6. Counter Frame Windows

| Action | Counter Window (frames) | How It Opens | Guaranteed Stun? |
|--------|------------------------|--------------|------------------|
| Parry | 10 frames after deflect | Press parry 3 frames before strike connection | ✓ |
| Slip (perfect) | 8 frames after slip | RS direction matches strike trajectory | ✓ |
| Duck (perfect) | 8 frames after duck | Duck under hook/head kick | ✓ |
| Recovery punish | Active recovery of opponent | Opponent whiffs strike and is in recovery frames | ✓ |
| Interrupt | Startup frames of opponent | Hit opponent during their startup (before active frames) | ✓ (but limited) |

**Counter doesn't stack —** a counter hit in response to a parry is just +35% damage and guaranteed stun. Not +70%.

---

## 7. Hit Reaction Visual Priority (for the procedural animation)

When a stun/daze is applied, the procedural animation system overrides the current strike with a hit reaction:

```
Tier 1 (Daze): Head bone snaps backward at DAMPED velocity, recovers in 0.15s
               └── Head rotation target: -15° (pitch), 0.1s to reach, 0.05s to recover
               
Tier 2 (Heavy Daze): Head + chest snap back, arms drop 10°
               └── Head: -25° pitch, 0.15s reach, 0.15s recover
               └── Arms: rotate 10° outward, 0.15s recover
               
Tier 3 (Stun): Full upper body back, arms wide, legs wobble
               └── Chest: -20° pitch, arms: +25° outward
               └── Legs: slight knee buckle (shin angle +10°)
               └── Recovery: limbs return to guard over 0.8s
               
Tier 4 (Heavy Stun): Fighter stumbles backward 0.5m, full body recoil
               └── Root position lerped backward 0.5m
               └── Ragdoll blend: 40% physics, 60% pose
               
Tier 5 (KD): Full ragdoll override for 0.3s, then TGH-modified getup attempt
               └── 100% physics ragdoll for 0.3s
               └── Fighter lies on ground for (duration - 0.3s) 
               └── Gets up at (duration × 0.6) — TGH 0 = at end, TGH 100 = at 60%
               
Tier 6 (KO): Permanent ragdoll, no getup
               └── 100% physics, fight over
```

---

## 8. Examples (Damage → Stun)

All examples: attacker = Ivan Drakov (STR 92, Boxing 94), defender = Kenji Takeshi (chin 60, TGH 65)

| Scenario | Mitigated Dmg | is_counter? | Ratio (dmg/chin) | Stun Tier | Duration |
|----------|--------------|------------|-------------------|-----------|----------|
| Jab, no modifier | 8.5 | No | 0.14 | 1 (daze) | 0.17s |
| Cross + lunge | 21.4 | No | 0.36 | 1 (daze) | 0.19s |
| Hook, perfect timing | 18.0 | No | 0.30 | 1 (daze) | 0.19s |
| Jab (counter) | 11.5 | Yes | 0.19 | 3 (stun) | 0.80s |
| Cross (counter) | 28.9 | Yes | 0.48 | 3 (stun) | 0.80s |
| Overhand (counter) | 35.0 | Yes | 0.58 | 3 (stun) | 0.83s |
| Overhand, no counter | 21.0 | No | 0.35 | 1 (daze) | 0.19s |
| Head kick (counter) | 42.0 | Yes | 0.70 | 3 (stun) | 0.85s |
| Head kick, perfect timing | 35.0 | No | 0.58 | 2 (heavy daze) | 0.43s |
| Head kick, counter + perfect | 56.7 | Yes | 0.95 | 3 (stun) | 0.88s |
| Elbow (counter) | 32.0 | Yes | 0.53 | 3 (stun) | 0.82s |
| 3-hit combo (jab→cross→hook) | 8.5+21.4+18.0=47.9 total | No | cumulative | 2 (heavy daze) | 0.38s |

**Key takeaway:** Against a chin 60 fighter, Ivan Drakov's strikes consistently daze but almost never stun without counter. Head kicks (18 base × 1.92 STR × velocity) can heavy daze. Only counters guarantee stun. This creates the flow: exchange → daze → counter-hunt → stun → follow-up.

---

## 9. Implementation Checklist

- [ ] ImpactCalculator: replace stun block with the new progressive threshold logic
- [ ] ImpactCalculator.HitResult: add `is_ko: bool` and `is_knockdown: bool` fields
- [ ] ImpactCalculator.HitResult: add `stun_duration: float` field
- [ ] FighterStateMachine: replace stun handling with tier-based state application
- [ ] FighterStateMachine: add per-tier effect table (can block/move/strike/clinch/deny)
- [ ] Counter detection: StrikePlanner or ContactDetector passes `is_counter` flag
- [ ] LimbSolver/IK: add hit reaction override (head snap, chest recoil, ragdoll blend)
- [ ] Block system: damage mitigation values + stun reduction per block type
- [ ] Test: verify every clean hit produces tier ≥ 1, every counter produces tier ≥ 3
