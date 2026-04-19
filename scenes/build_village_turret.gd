extends SceneTree
## Scene builder for village_turret.tscn — Node2D with turret script.

func _initialize() -> void:
	var root = Node2D.new()
	root.name = "VillageTurret"
	root.set_script(load("res://scripts/village_turret.gd"))
	root.set("turret_type", 0)  # Default: ARROW

	_set_owners(root, root)
	var packed = PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://scenes/village_turret.tscn")
	print("Saved: res://scenes/village_turret.tscn")
	quit(0)

func _set_owners(node: Node, owner: Node) -> void:
	for c in node.get_children():
		c.owner = owner
		if c.scene_file_path.is_empty():
			_set_owners(c, owner)