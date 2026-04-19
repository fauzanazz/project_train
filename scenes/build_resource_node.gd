extends SceneTree
## Scene builder — run: godot --headless --script scenes/build_resource_node.gd

func _initialize() -> void:
	var root = Area2D.new()
	root.name = "ResourceNode"
	root.set_script(load("res://scripts/resource_node.gd"))
	root.collision_layer = 16  # layer 5 = resources = bit 5 = value 16
	root.collision_mask = 1    # player

	var col = CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var circle = CircleShape2D.new()
	circle.radius = 22.0
	col.shape = circle
	root.add_child(col)

	_set_owners(root, root)
	var packed = PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://scenes/resource_node.tscn")
	print("Saved: res://scenes/resource_node.tscn")
	quit(0)

func _set_owners(node: Node, owner: Node) -> void:
	for c in node.get_children():
		c.owner = owner
		if c.scene_file_path.is_empty():
			_set_owners(c, owner)
