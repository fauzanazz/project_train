extends SceneTree
## Scene builder for projectile.tscn — Area2D with collision, visual node.

func _initialize() -> void:
	var root = Area2D.new()
	root.name = "Projectile"
	root.set_script(load("res://scripts/projectile.gd"))
	root.collision_layer = 4   # projectiles (layer 3 = bit 3 = value 4)
	root.collision_mask = 2    # enemies

	# Collision shape
	var col = CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var circle = CircleShape2D.new()
	circle.radius = 4.0
	col.shape = circle
	root.add_child(col)

	# Visual node
	var vis = Node2D.new()
	vis.name = "VisualNode"
	root.add_child(vis)

	_set_owners(root, root)
	var packed = PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://scenes/projectile.tscn")
	print("Saved: res://scenes/projectile.tscn")
	quit(0)

func _set_owners(node: Node, owner: Node) -> void:
	for c in node.get_children():
		c.owner = owner
		if c.scene_file_path.is_empty():
			_set_owners(c, owner)