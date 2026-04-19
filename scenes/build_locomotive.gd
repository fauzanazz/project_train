extends SceneTree
## Scene builder — run: timeout 60 godot --headless --script scenes/build_locomotive.gd

func _initialize() -> void:
	var root = CharacterBody2D.new()
	root.name = "Locomotive"
	root.set_script(load("res://scripts/locomotive.gd"))
	root.collision_layer = 1   # player
	root.collision_mask = 18   # enemies (2) + village (16) = bit 2 + bit 5... using direct values: layer 2 = 2, layer 4 = 8, layer 6 = 32

	# Collision shape
	var col = CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var rect = RectangleShape2D.new()
	rect.size = Vector2(60, 28)
	col.shape = rect
	root.add_child(col)

	# Body damage area (detects enemy overlap)
	var bda = Area2D.new()
	bda.name = "BodyDamageArea"
	bda.collision_layer = 1
	bda.collision_mask = 2  # enemies
	var bda_col = CollisionShape2D.new()
	bda_col.name = "CollisionShape2D"
	var bda_rect = RectangleShape2D.new()
	bda_rect.size = Vector2(64, 32)
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

	# Camera
	var cam = Camera2D.new()
	cam.name = "Camera2D"
	cam.zoom = Vector2(1.0, 1.0)
	root.add_child(cam)

	_set_owners(root, root)
	var packed = PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://scenes/locomotive.tscn")
	print("Saved: res://scenes/locomotive.tscn")
	quit(0)

func _set_owners(node: Node, owner: Node) -> void:
	for c in node.get_children():
		c.owner = owner
		if c.scene_file_path.is_empty():
			_set_owners(c, owner)
