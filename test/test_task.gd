extends SceneTree
## res://test/test_task.gd
## Visual QA: capture upgrade card UI and weapon upgrade visual progression.

var _elapsed: float = 0.0
var _phase: int = 0
var _screenshot_dir := "user://upgrade_qa"

func _initialize() -> void:
	var main_scene = load("res://scenes/main.tscn")
	if main_scene:
		var main = main_scene.instantiate()
		root.add_child(main)
	print("[QA] Test initialized")

func _process(delta: float) -> bool:
	_elapsed += delta

	# Phase 0: t=3s — baseline
	if _elapsed >= 3.0 and _phase == 0:
		_phase = 1
		_take_screenshot("01_baseline")
		_log("Phase 1: Baseline captured")

	# Phase 1: t=5s — force level-up
	if _elapsed >= 5.0 and _phase == 1:
		_phase = 2
		PlayerManager.add_xp(100)
		_log("Phase 2: Forced level-up via 100 XP")

	# Phase 2: t=7s — capture card UI (should be paused with cards visible)
	if _elapsed >= 7.0 and _phase == 2:
		_phase = 3
		_take_screenshot("02_level_up_cards")
		_log_hud_choices()
		_select_first_card()
		_log("Phase 3: Cards captured, selecting first")

	# Phase 3: t=9s — second level-up
	if _elapsed >= 9.0 and _phase == 3:
		_phase = 4
		PlayerManager.add_xp(300)
		_log("Phase 4: Second level-up forced (300 XP)")

	# Phase 4: t=11s — capture upgrade card
	if _elapsed >= 11.0 and _phase == 4:
		_phase = 5
		_take_screenshot("03_upgrade_cards")
		_log_hud_choices()
		_select_first_card()
		_log("Phase 5: Upgrade cards captured")

	# Phase 5: t=13s — bulk XP for higher tiers
	if _elapsed >= 13.0 and _phase == 5:
		_phase = 6
		PlayerManager.add_xp(1500)
		_log("Phase 6: Bulk 1500 XP")

	# Phase 6: t=16s — capture after multiple upgrades
	if _elapsed >= 16.0 and _phase == 6:
		_phase = 7
		_take_screenshot("04_multi_upgrades")
		_log_equipment()

	# Phase 7: t=18s — force more level-ups
	if _elapsed >= 18.0 and _phase == 7:
		_phase = 8
		PlayerManager.add_xp(3000)
		_log("Phase 7: 3000 more XP")

	# Phase 8: t=20s — capture high-tier cards
	if _elapsed >= 20.0 and _phase == 8:
		_phase = 9
		_take_screenshot("05_high_tier_cards")
		_log_hud_choices()
		_select_first_card()

	# Final: t=22s
	if _elapsed >= 22.0:
		_take_screenshot("06_final")
		_log_equipment()
		_log("DONE - All screenshots captured")
		quit(0)

	return false

func _select_first_card() -> void:
	var hud = _find_hud()
	if not hud:
		_log("FAIL: HUD not found for card selection")
		if get_tree().paused:
			get_tree().paused = false
		return
	var choices: Array = hud._pending_choices
	if choices.size() > 0:
		PlayerManager.apply_choice(choices[0])
		hud._pending_choices = []
		hud._level_up_timer = 0.0
		var panel = hud.get_node_or_null("Control/LevelUpPanel")
		if panel:
			panel.hide()
	else:
		_log("WARN: No pending choices to select")
	if get_tree().paused:
		get_tree().paused = false

func _log_hud_choices() -> void:
	var hud = _find_hud()
	if not hud:
		_log("HUD not found")
		return
	var choices: Array = hud._pending_choices
	_log("Paused: %s, Choices: %d" % [get_tree().paused, choices.size()])
	for i in choices.size():
		var c = choices[i]
		var info := "Card %d: type=%s name=%s" % [i + 1, c.get("type", "?"), c.get("name", "?")]
		if c.has("upgrade_name"):
			info += " upgrade=%s(Lv%d→%d)" % [c["upgrade_name"], c["current_level"], c["next_level"]]
		if c.has("desc"):
			info += " desc=%s" % c["desc"]
		_log(info)

func _log_equipment() -> void:
	_log("Level: %d, XP: %d/%d" % [PlayerManager.current_level, PlayerManager.current_xp, PlayerManager._xp_for_next])
	var train = _find_train()
	if not train:
		_log("Train not found")
		return
	if train.locomotive:
		var ws = train.locomotive.get_node_or_null("WeaponSlot")
		if ws:
			for child in ws.get_children():
				_log("Loco Weapon: %s id=%s lv=%d" % [child.name, child.get("id", "?"), child.get("upgrade_level", 0)])
				if child.has_method("get_next_upgrade_name"):
					_log("  next: %s" % child.get_next_upgrade_name())
	if "compartments" in train:
		for comp in train.compartments:
			if not comp:
				continue
			for slot_name in ["WeaponSlot", "UtilitySlot"]:
				var slot = comp.get_node_or_null(slot_name)
				if slot:
					for child in slot.get_children():
						_log("Comp %s: %s id=%s lv=%d" % [slot_name, child.name, child.get("id", "?"), child.get("upgrade_level", 0)])

func _find_hud() -> Node:
	var all: Array = root.find_children("*", "CanvasLayer", true, false)
	if all.size() > 0:
		return all[0]
	return null

func _find_train() -> Node:
	var main := root.get_child(0)
	if main:
		var train = main.get_node_or_null("Train")
		if train:
			return train
	var all_nodes: Array = root.find_children("*", "", true, false)
	for node in all_nodes:
		if node.is_in_group("train"):
			return node
	return null

func _take_screenshot(label: String) -> void:
	var dir := "screenshots/upgrade_qa"
	DirAccess.make_dir_recursive_absolute(dir)
	var path := "%s/%s.png" % [dir, label]
	var vp := root.get_viewport()
	var img := vp.get_texture().get_image()
	img.save_png(path)
	_log("Screenshot: %s (%dx%d)" % [path, img.get_width(), img.get_height()])

func _log(msg: String) -> void:
	print("[QA] %s" % msg)
	push_warning("[QA] %s" % msg)
