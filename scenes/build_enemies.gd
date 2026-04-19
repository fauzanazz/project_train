extends SceneTree
## Scene builder for all 4 enemy type scenes.
## Each inherits from enemy_base structure but with specific scripts and properties.

func _initialize() -> void:
	_build_enemy("EnemyShambler", "res://scripts/enemy_shambler.gd", 30.0, 60.0, 5.0, 3.0, 10, 0, "res://scenes/enemy_shambler.tscn")
	_build_enemy("EnemyRunner", "res://scripts/enemy_runner.gd", 15.0, 140.0, 3.0, 2.0, 15, 1, "res://scenes/enemy_runner.tscn")
	_build_enemy("EnemyBloater", "res://scripts/enemy_bloater.gd", 80.0, 40.0, 8.0, 5.0, 20, 0, "res://scenes/enemy_bloater.tscn")
	_build_enemy("EnemyCrawler", "res://scripts/enemy_crawler.gd", 20.0, 90.0, 4.0, 2.0, 12, 2, "res://scenes/enemy_crawler.tscn")
	quit(0)

func _build_enemy(name: String, script_path: String, max_hp: float, base_speed: float,
		body_damage: float, wall_damage: float, xp_value: int, ai_type: int, save_path: String) -> void:
	var root = CharacterBody2D.new()
	root.name = name
	root.set_script(load(script_path))
	root.collision_layer = 2   # enemies
	root.collision_mask = 17    # player(1) + village(16) = 17

	# Set exported properties (must use set() since script not loaded yet in editor)
	root.set("max_hp", max_hp)
	root.set("base_speed", base_speed)
	root.set("body_damage", body_damage)
	root.set("wall_damage", wall_damage)
	root.set("xp_value", xp_value)
	root.set("ai_type", ai_type)

	# Collision shape — size varies by type
	var col = CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var circle = CircleShape2D.new()
	# Radius varies: shambler=12, runner=9, bloater=16, crawler=10
	var radii := {"EnemyShambler": 12.0, "EnemyRunner": 9.0, "EnemyBloater": 16.0, "EnemyCrawler": 10.0}
	circle.radius = radii.get(name, 12.0)
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
	hit_circle.radius = circle.radius + 2.0
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
	ResourceSaver.save(packed, save_path)
	print("Saved: " + save_path)

func _set_owners(node: Node, owner: Node) -> void:
	for c in node.get_children():
		c.owner = owner
		if c.scene_file_path.is_empty():
			_set_owners(c, owner)