extends SceneTree
## Scene builder — run: timeout 60 godot --headless --script scenes/build_hud.gd

func _initialize() -> void:
	var root = CanvasLayer.new()
	root.name = "HUD"
	root.layer = 10
	root.set_script(load("res://scripts/hud.gd"))

	var ctrl = Control.new()
	ctrl.name = "Control"
	ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(ctrl)

	# Top left — village HP, XP bar, level
	var top_left = VBoxContainer.new()
	top_left.name = "TopLeft"
	top_left.position = Vector2(12, 12)
	top_left.custom_minimum_size = Vector2(220, 0)
	ctrl.add_child(top_left)

	var vil_hp = ProgressBar.new()
	vil_hp.name = "VillageHPBar"
	vil_hp.max_value = 500.0
	vil_hp.value = 500.0
	vil_hp.custom_minimum_size = Vector2(220, 18)
	top_left.add_child(vil_hp)

	var xp_bar = ProgressBar.new()
	xp_bar.name = "XPBar"
	xp_bar.max_value = 100.0
	xp_bar.value = 0.0
	xp_bar.custom_minimum_size = Vector2(220, 14)
	top_left.add_child(xp_bar)

	var lvl_lbl = Label.new()
	lvl_lbl.name = "LevelLabel"
	lvl_lbl.text = "Lv 1"
	top_left.add_child(lvl_lbl)

	# Top center — wave info
	var top_center = VBoxContainer.new()
	top_center.name = "TopCenter"
	top_center.set_anchors_preset(Control.PRESET_CENTER_TOP)
	top_center.position = Vector2(-60, 12)
	ctrl.add_child(top_center)

	var wave_lbl = Label.new()
	wave_lbl.name = "WaveLabel"
	wave_lbl.text = "Wave 0"
	wave_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_center.add_child(wave_lbl)

	var timer_lbl = Label.new()
	timer_lbl.name = "WaveTimerLabel"
	timer_lbl.text = ""
	timer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_center.add_child(timer_lbl)

	# Bottom center — cargo display
	var bot_center = HBoxContainer.new()
	bot_center.name = "BottomCenter"
	var bc_parent = HBoxContainer.new()
	bc_parent.name = "CargoDisplayParent"
	bc_parent.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	bc_parent.position = Vector2(12, -50)
	ctrl.add_child(bc_parent)

	var cargo_disp = HBoxContainer.new()
	cargo_disp.name = "CargoDisplay"
	bc_parent.add_child(cargo_disp)

	# Bottom right — mini-map placeholder
	var br_container = SubViewportContainer.new()
	br_container.name = "MiniMap"
	br_container.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	br_container.position = Vector2(-192, -192)
	br_container.custom_minimum_size = Vector2(180, 180)
	ctrl.add_child(br_container)

	# Level-up panel (hidden by default)
	var lu_panel = Panel.new()
	lu_panel.name = "LevelUpPanel"
	lu_panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	lu_panel.position = Vector2(-340, -150)
	lu_panel.custom_minimum_size = Vector2(320, 300)
	lu_panel.visible = false
	ctrl.add_child(lu_panel)

	_set_owners(root, root)
	var packed = PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://scenes/hud.tscn")
	print("Saved: res://scenes/hud.tscn")
	quit(0)

func _set_owners(node: Node, owner: Node) -> void:
	for c in node.get_children():
		c.owner = owner
		if c.scene_file_path.is_empty():
			_set_owners(c, owner)
