extends SceneTree
## Scene builder for all enemy type scenes including elites and boss.
## Each inherits from enemy_base structure but with specific scripts and properties.

func _initialize() -> void:
	_build_enemy("EnemyShambler", "res://scripts/enemy_shambler.gd", 30.0, 60.0, 5.0, 3.0, 10, 0, "res://scenes/enemy_shambler.tscn", 12.0)
	_build_enemy("EnemyRunner", "res://scripts/enemy_runner.gd", 15.0, 140.0, 3.0, 2.0, 15, 1, "res://scenes/enemy_runner.tscn", 9.0)
	_build_enemy("EnemyBloater", "res://scripts/enemy_bloater.gd", 80.0, 40.0, 8.0, 5.0, 20, 0, "res://scenes/enemy_bloater.tscn", 16.0)
	_build_enemy("EnemyCrawler", "res://scripts/enemy_crawler.gd", 20.0, 90.0, 4.0, 2.0, 12, 2, "res://scenes/enemy_crawler.tscn", 10.0)
	_build_enemy("EnemyShooter", "res://scripts/enemy_shooter.gd", 40.0, 45.0, 3.0, 2.0, 15, 2, "res://scenes/enemy_shooter.tscn", 12.0)
	# Elite enemies
	_build_elite("EnemyBrute", "res://scripts/enemy_brute.gd", 300.0, 50.0, 8.0, 5.0, 50, 0, "res://scenes/enemy_brute.tscn", 14.0)
	_build_elite("EnemyScreamer", "res://scripts/enemy_screamer.gd", 60.0, 120.0, 3.0, 2.0, 30, 1, "res://scenes/enemy_screamer.tscn", 11.0)
	_build_elite("EnemySwarmerQueen", "res://scripts/enemy_swarmer_queen.gd", 150.0, 70.0, 5.0, 3.0, 40, 2, "res://scenes/enemy_swarmer_queen.tscn", 13.0)
	_build_elite("EnemyChain", "res://scripts/enemy_chain.gd", 200.0, 55.0, 6.0, 4.0, 35, 0, "res://scenes/enemy_chain.tscn", 12.0)
	quit(0)

func _build_enemy(name: String, script_path: String, max_hp: float, base_speed: float,
		body_damage: float, wall_damage: float, xp_value: int, ai_type: int, save_path: String, radius: float) -> void:
	var root = CharacterBody2D.new()
	root.name = name
	root.set_script(load(script_path))
	root.collision_layer = 2   # enemies
	root.collision_mask = 17    # player(1) + village(16) = 17

	# Set exported properties
	root.set("max_hp", max_hp)
	root.set("base_speed", base_speed)
	root.set("body_damage", body_damage)
	root.set("wall_damage", wall_damage)
	root.set("xp_value", xp_value)
	root.set("ai_type", ai_type)

	# Collision shape
	var col = CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var circle = CircleShape2D.new()
	circle.radius = radius
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
	hit_circle.radius = radius + 2.0
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

func _build_elite(name: String, script_path: String, max_hp: float, base_speed: float,
		body_damage: float, wall_damage: float, xp_value: int, ai_type: int, save_path: String, radius: float) -> void:
	var root = CharacterBody2D.new()
	root.name = name
	root.set_script(load(script_path))
	root.collision_layer = 2   # enemies
	root.collision_mask = 17    # player(1) + village(16) = 17

	# Set exported properties
	root.set("max_hp", max_hp)
	root.set("base_speed", base_speed)
	root.set("body_damage", body_damage)
	root.set("wall_damage", wall_damage)
	root.set("xp_value", xp_value)
	root.set("ai_type", ai_type)

	# Collision shape
	var col = CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var circle = CircleShape2D.new()
	circle.radius = radius
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
	hit_area.collision_mask = 5
	var hit_col = CollisionShape2D.new()
	hit_col.name = "CollisionShape2D"
	var hit_circle = CircleShape2D.new()
	hit_circle.radius = radius + 2.0
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