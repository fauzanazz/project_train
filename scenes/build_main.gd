extends SceneTree
## Scene builder — run: timeout 60 godot --headless --script scenes/build_main.gd
## Depends on: world.tscn, train.tscn, hud.tscn

func _initialize() -> void:
	var root = Node2D.new()
	root.name = "Main"

	var world = load("res://scenes/world.tscn").instantiate()
	world.name = "World"
	root.add_child(world)

	var train = load("res://scenes/train.tscn").instantiate()
	train.name = "Train"
	root.add_child(train)

	var hud = load("res://scenes/hud.tscn").instantiate()
	hud.name = "HUD"
	root.add_child(hud)

	_set_owners(root, root)
	var packed = PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://scenes/main.tscn")
	print("Saved: res://scenes/main.tscn")
	quit(0)

func _set_owners(node: Node, owner: Node) -> void:
	for c in node.get_children():
		c.owner = owner
		if c.scene_file_path.is_empty():
			_set_owners(c, owner)
