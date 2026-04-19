extends SceneTree
## Scene builder — run: timeout 60 godot --headless --script scenes/build_compartment.gd

func _initialize() -> void:
	var root = Node2D.new()
	root.name = "Compartment"
	root.set_script(load("res://scripts/compartment.gd"))

	# Body damage area
	var bda = Area2D.new()
	bda.name = "BodyDamageArea"
	bda.collision_layer = 1
	bda.collision_mask = 2  # enemies
	var bda_col = CollisionShape2D.new()
	bda_col.name = "CollisionShape2D"
	var bda_rect = RectangleShape2D.new()
	bda_rect.size = Vector2(50, 28)
	bda_col.shape = bda_rect
	bda.add_child(bda_col)
	root.add_child(bda)

	# Weapon slot
	var ws = Node2D.new()
	ws.name = "WeaponSlot"
	root.add_child(ws)

	# Utility slot
	var us = Node2D.new()
	us.name = "UtilitySlot"
	root.add_child(us)

	# Cargo indicator
	var ci = Node2D.new()
	ci.name = "CargoIndicator"
	root.add_child(ci)

	_set_owners(root, root)
	var packed = PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://scenes/compartment.tscn")
	print("Saved: res://scenes/compartment.tscn")
	quit(0)

func _set_owners(node: Node, owner: Node) -> void:
	for c in node.get_children():
		c.owner = owner
		if c.scene_file_path.is_empty():
			_set_owners(c, owner)
