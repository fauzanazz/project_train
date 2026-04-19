extends SceneTree
## Scene builder — run: timeout 60 godot --headless --script scenes/build_world.gd

func _initialize() -> void:
	var root = Node2D.new()
	root.name = "World"
	root.set_script(load("res://scripts/world.gd"))

	# Ground visual node
	var ground = Node2D.new()
	ground.name = "Ground"
	root.add_child(ground)

	# Village
	var village = Node2D.new()
	village.name = "Village"
	village.set_script(load("res://scripts/village.gd"))
	root.add_child(village)

	# Resource nodes container
	var rn_container = Node2D.new()
	rn_container.name = "ResourceNodes"
	root.add_child(rn_container)

	# Hazards container
	var hz_container = Node2D.new()
	hz_container.name = "HazardNodes"
	root.add_child(hz_container)

	# Spawn corridors marker container
	var sc_container = Node2D.new()
	sc_container.name = "SpawnCorridors"
	root.add_child(sc_container)

	# Navigation region
	var nav_region = NavigationRegion2D.new()
	nav_region.name = "NavigationRegion2D"
	var nav_poly = NavigationPolygon.new()
	# Simple open map polygon — enemies can navigate anywhere on the 3200x3200 map
	var outline = PackedVector2Array([
		Vector2(-1600, -1600), Vector2(1600, -1600),
		Vector2(1600, 1600), Vector2(-1600, 1600)
	])
	nav_poly.add_outline(outline)
	# Village obstacle cutout (enemies cannot path through walls)
	var village_cutout = PackedVector2Array([
		Vector2(-150, -150), Vector2(150, -150),
		Vector2(150, 150), Vector2(-150, 150)
	])
	nav_poly.add_outline(village_cutout)
	NavigationServer2D.bake_from_source_geometry_data(nav_poly, NavigationMeshSourceGeometryData2D.new())
	nav_region.navigation_polygon = nav_poly
	root.add_child(nav_region)

	_set_owners(root, root)
	var packed = PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://scenes/world.tscn")
	print("Saved: res://scenes/world.tscn")
	quit(0)

func _set_owners(node: Node, owner: Node) -> void:
	for c in node.get_children():
		c.owner = owner
		if c.scene_file_path.is_empty():
			_set_owners(c, owner)
