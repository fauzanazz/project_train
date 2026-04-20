extends SceneTree
## Scene builder for enemy_shooter.tscn — standalone build script.
## Run: /Applications/Godot.app/Contents/MacOS/Godot --headless --script scenes/build_enemy_shooter.gd --quit

func _initialize() -> void:
	var root = CharacterBody2D.new()
	root.name = "EnemyShooter"
	root.set_script(load("res://scripts/enemy_shooter.gd"))
	root.collision_layer = 2   # enemies
	root.collision_mask = 17    # player(1) + village(16) = 17

	# Set exported properties
	root.set("max_hp", 40.0)
	root.set("base_speed", 45.0)
	root.set("body_damage", 3.0)
	root.set("wall_damage", 2.0)
	root.set("xp_value", 15)
	root.set("ai_type", 2)  # AIType.HYBRID

	# Collision shape
	var col = CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var circle = CircleShape2D.new()
	circle.radius = 12.0
	col.shape = circle
	root.add_child(col)

	# Navigation agent
	var nav = NavigationAgent2D.new()
	nav.name = "NavigationAgent2D"
	nav.path_desired_distance = 10.0
	nav.target_desired_distance = 10.0
	root.add_child(nav)

	# Hit area
	var hit_area = Area2D.new()
	hit_area.name = "HitArea"
	hit_area.collision_layer = 2
	hit_area.collision_mask = 5  # player + projectiles
	var hit_col = CollisionShape2D.new()
	hit_col.name = "CollisionShape2D"
	var hit_circle = CircleShape2D.new()
	hit_circle.radius = 14.0
	hit_col.shape = hit_circle
	hit_area.add_child(hit_col)
	root.add_child(hit_area)

	# HPBar visual node
	var hp_bar = Node2D.new()
	hp_bar.name = "HPBar"
	root.add_child(hp_bar)

	_set_owners(root, root)
	var packed = PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://scenes/enemy_shooter.tscn")
	print("Saved: res://scenes/enemy_shooter.tscn")
	quit(0)

func _set_owners(node: Node, owner: Node) -> void:
	for c in node.get_children():
		c.owner = owner
		if c.scene_file_path.is_empty():
			_set_owners(c, owner)
