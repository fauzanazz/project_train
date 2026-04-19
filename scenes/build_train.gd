extends SceneTree
## Scene builder — run: timeout 60 godot --headless --script scenes/build_train.gd
## Depends on: locomotive.tscn, compartment.tscn

func _initialize() -> void:
	var root = Node2D.new()
	root.name = "Train"
	root.set_script(load("res://scripts/train.gd"))

	var loco = load("res://scenes/locomotive.tscn").instantiate()
	loco.name = "Locomotive"
	root.add_child(loco)

	var cc = Node2D.new()
	cc.name = "CompartmentContainer"
	root.add_child(cc)

	_set_owners(root, root)
	var packed = PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://scenes/train.tscn")
	print("Saved: res://scenes/train.tscn")
	quit(0)

func _set_owners(node: Node, owner: Node) -> void:
	for c in node.get_children():
		c.owner = owner
		if c.scene_file_path.is_empty():
			_set_owners(c, owner)
