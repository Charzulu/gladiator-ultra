# scripts/progression/MoveVariantData.gd
# Defines a single variant of a combat move.
# Variants are purchased with per-strike XP and equipped permanently in the fighter's loadout.
extends RefCounted

class MoveVariant:
	var variant_id: String           # "jab_heavy"
	var display_name: String         # "Heavy Jab"
	var description: String          # "A powerful, telegraphed jab with extra push."
	var base_move_id: String         # "jab" — matches StrikePlanner strike id
	var category: String             # "standard", "core", "style", "advanced", "signature", "combo"
	var style_origin: String         # "generic", "boxing", "muay_thai", etc.
	
	# ── Frame data multipliers ──
	var startup_mult: float = 1.0
	var active_mult: float = 1.0
	var recovery_mult: float = 1.0
	var damage_mult: float = 1.0
	var stamina_cost_mult: float = 1.0
	var reach_mult: float = 1.0
	
	# ── Combat modifiers ──
	var hit_chance_mult: float = 1.0
	var guard_damage_mult: float = 1.0
	var stun_chance_add: float = 0.0
	var push_force: float = 0.0
	var cut_chance_add: float = 0.0
	
	# ── Risk ──
	var counter_window_add: int = 0
	
	# ── Combo ──
	var combo_link_reduction: int = 0
	
	# ── Trajectory ──
	var trajectory_override: String = ""
	
	# ── Unlock ──
	var xp_cost: int = 100
	var requirements: Dictionary = {}  # { "boxing": 40 }
	var level_required: int = 2

	func _to_string() -> String:
		return "[MoveVariant id=%s name=%s move=%s cat=%s]" % [variant_id, display_name, base_move_id, category]

static func create(
	p_variant_id: String,
	p_display: String,
	p_desc: String,
	p_move: String,
	p_cat: String,
	p_style: String,
	p_startup: float,
	p_active: float,
	p_recovery: float,
	p_damage: float,
	p_stamina: float,
	p_reach: float,
	p_hit_chance: float = 1.0,
	p_guard_dmg: float = 1.0,
	p_stun_add: float = 0.0,
	p_push: float = 0.0,
	p_cut_add: float = 0.0,
	p_counter_add: int = 0,
	p_combo_red: int = 0,
	p_traj: String = "",
	p_cost: int = 100,
	p_reqs: Dictionary = {},
	p_level: int = 2
) -> MoveVariant:
	var v = MoveVariant.new()
	v.variant_id = p_variant_id
	v.display_name = p_display
	v.description = p_desc
	v.base_move_id = p_move
	v.category = p_cat
	v.style_origin = p_style
	v.startup_mult = p_startup
	v.active_mult = p_active
	v.recovery_mult = p_recovery
	v.damage_mult = p_damage
	v.stamina_cost_mult = p_stamina
	v.reach_mult = p_reach
	v.hit_chance_mult = p_hit_chance
	v.guard_damage_mult = p_guard_dmg
	v.stun_chance_add = p_stun_add
	v.push_force = p_push
	v.cut_chance_add = p_cut_add
	v.counter_window_add = p_counter_add
	v.combo_link_reduction = p_combo_red
	v.trajectory_override = p_traj
	v.xp_cost = p_cost
	v.requirements = p_reqs
	v.level_required = p_level
	return v
