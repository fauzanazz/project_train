extends SceneTree
## Scene builder for hazard scenes — toxic puddle, rubble pile, electrified rail.

func _initialize() -> void:
	_build_toxic_puddle()
	_build_rubble_pile()
	_build_electrified_rail()
	quit(0)

func _build_toxic_puddle() -> void:
	var root = Area2D.new()
	root.name = "ToxicPuddle"
	root.set_script(load("res://scripts/hazard_toxic_puddle.gd"))
	root.collision_layer = 32  # hazards (layer 6)
	root.collision_mask = 1    # player

	var col = CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var circle = CircleShape2D.new()
	circle.radius = 25.0
	col.shape = circle
	root.add_child(col)

	_set_owners(root, root)
	var packed = PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://scenes/hazard_toxic_puddle.tscn")
	print("Saved: res://scenes/hazard_toxic_puddle.tscn")

func _build_rubble_pile() -> void:
	var root = StaticBody2D.new()
	root.name = "RubblePile"
	root.set_script(load("res://scripts/hazard_rubble_pile.gd"))
	root.collision_layer = 32  # hazards
	root.collision_mask = 1    # player

	var col = CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var rect = RectangleShape2D.new()
	rect.size = Vector2(44, 28)
	col.shape = rect
	root.add_child(col)

	_set_owners(root, root)
	var packed = PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://scenes/hazard_rubble_pile.tscn")
	print("Saved: res://scenes/hazard_rubble_pile.tscn")

func _build_electrified_rail() -> void:
	var root = Area2D.new()
	root.name = "ElectrifiedRail"
	root.set_script(load("res://scripts/hazard_electrified_rail.gd"))
	root.collision_layer = 32  # hazards
	root.collision_mask = 1    # player

	var col = CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var rect = RectangleShape2D.new()
	rect.size = Vector2(80, 12)
	col.shape = rect
	root.add_child(col)

	_set_owners(root, root)
	var packed = PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://scenes/hazard_electrified_rail.tscn")
	print("Saved: res://scenes/hazard_electrified_rail.tscn")

func _set_owners(node: Node, owner: Node) -> void:
	for c in node.get_children():
		c.owner = owner
		if c.scene_file_path.is_empty():
			_set_owners(c, owner)