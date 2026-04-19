extends SceneTree
## Scene builder for boss_locomotive.tscn — The Locomotive boss enemy.

func _initialize() -> void:
	var root = CharacterBody2D.new()
	root.name = "BossLocomotive"
	root.set_script(load("res://scripts/boss_locomotive.gd"))
	root.collision_layer = 2   # enemies
	root.collision_mask = 17    # player(1) + village(16) = 17

	# Collision shape — large for the boss
	var col = CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var rect = RectangleShape2D.new()
	rect.size = Vector2(80, 40)
	col.shape = rect
	root.add_child(col)

	# Navigation agent
	var nav = NavigationAgent2D.new()
	nav.name = "NavigationAgent2D"
	nav.path_desired_distance = 20.0
	nav.target_desired_distance = 20.0
	nav.avoidance_enabled = false
	root.add_child(nav)

	_set_owners(root, root)
	var packed = PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://scenes/boss_locomotive.tscn")
	print("Saved: res://scenes/boss_locomotive.tscn")
	quit(0)

func _set_owners(node: Node, owner: Node) -> void:
	for c in node.get_children():
		c.owner = owner
		if c.scene_file_path.is_empty():
			_set_owners(c, owner)