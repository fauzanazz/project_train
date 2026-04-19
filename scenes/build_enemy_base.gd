extends SceneTree
## Scene builder for enemy_base.tscn — CharacterBody2D with NavigationAgent2D, HitArea, HPBar.

func _initialize() -> void:
	var root = CharacterBody2D.new()
	root.name = "EnemyBase"
	root.set_script(load("res://scripts/enemy_base.gd"))
	root.collision_layer = 2   # enemies
	root.collision_mask = 17    # player(1) + village(16) = 17

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
	nav.avoidance_enabled = false
	root.add_child(nav)

	# Hit area — detects projectiles (layer 3) and player contact (layer 1)
	var hit_area = Area2D.new()
	hit_area.name = "HitArea"
	hit_area.collision_layer = 2  # enemies (so projectiles/bodies detect it)
	hit_area.collision_mask = 5    # player(1) + projectiles(4) = 5
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
	ResourceSaver.save(packed, "res://scenes/enemy_base.tscn")
	print("Saved: res://scenes/enemy_base.tscn")
	quit(0)

func _set_owners(node: Node, owner: Node) -> void:
	for c in node.get_children():
		c.owner = owner
		if c.scene_file_path.is_empty():
			_set_owners(c, owner)