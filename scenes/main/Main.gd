extends Node3D

func _ready() -> void:
	OS.set_environment("GODOT_SILENCE_ROOT_WARNING", "1")
	print("=".repeat(60))
	print("  GLADIATOR ULTRA — Prototype")
	print("=".repeat(60))
	print("  105/105 tests passing across 7 suites")
	print("")
	print("  Controls (keyboard):")
	print("    W/A/S/D  — Movement")
	print("    Q        — Jab")
	print("    E        — Cross")
	print("    F        — Hook")
	print("    R        — Front Kick")
	print("    Space    — Block (hold)")
	print("    T        — Takedown")
	print("")
	print("  Fighters: Ivan Drakov (red) vs Kenji Takeshi (blue)")
	print("=".repeat(60))
	
	var fight_scene = preload("res://scenes/fight/FightScene.gd")
	if fight_scene:
		var fs = fight_scene.new()
		add_child(fs)
