extends CanvasLayer
## res://scripts/hud.gd
## All HUD widget updates, level-up panel, mini-map, and cargo display.

const _MB = preload("res://scripts/modifier_base.gd")

@onready var village_hp_bar: ProgressBar = $Control/TopLeft/VillageHPBar
@onready var xp_bar: ProgressBar = $Control/TopLeft/XPBar
@onready var level_label: Label = $Control/TopLeft/LevelLabel
@onready var wave_label: Label = $Control/TopCenter/WaveLabel
@onready var wave_timer_label: Label = $Control/TopCenter/WaveTimerLabel
@onready var level_up_panel: Control = $Control/LevelUpPanel
@onready var mini_map: SubViewportContainer = $Control/MiniMap
@onready var cargo_display: HBoxContainer = $Control/CargoDisplayParent/CargoDisplay

var _level_up_timer: float = 0.0
var _pending_choices: Array = []
var _game_over_visible: bool = false
var _game_over_wave: int = 0
var _mini_map_draw: Node2D = null
var _cards_container: VBoxContainer = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	PlayerManager.xp_changed.connect(_on_xp_changed)
	PlayerManager.level_changed.connect(_on_level_changed)
	PlayerManager.level_up_offer.connect(_on_level_up_offer)
	ResourceManager.resources_changed.connect(_on_resources_changed)
	WaveManager.wave_started.connect(_on_wave_started)
	WaveManager.wave_ended.connect(_on_wave_ended)
	GameManager.game_over.connect(_on_game_over)
	if level_up_panel:
		level_up_panel.hide()
	# Build mini-map draw node
	if mini_map:
		var sv = mini_map.get_node_or_null("SubViewport")
		if not sv:
			sv = SubViewport.new()
			sv.name = "SubViewport"
			sv.size = Vector2(180, 180)
			sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			mini_map.add_child(sv)
		_mini_map_draw = Node2D.new()
		_mini_map_draw.name = "MiniMapDraw"
		_mini_map_draw.position = Vector2(90, 90)
		_mini_map_draw.set_script(_create_minimap_script())
		sv.add_child(_mini_map_draw)
	_connect_village_signal.call_deferred()

func _connect_village_signal() -> void:
	var village = get_tree().get_first_node_in_group("village") if get_tree() else null
	if village and village.has_signal("village_damaged"):
		village.village_damaged.connect(_on_village_damaged)

func _create_minimap_script():
	return _create_minimap_script_inner()

func _process(delta: float) -> void:
	if _level_up_timer > 0.0 and _pending_choices.size() > 0:
		_level_up_timer -= delta
		if _level_up_timer <= 0.0:
			_auto_select_level_up()
	# Update wave timer
	var t: float = WaveManager.get_wave_time_remaining()
	if wave_timer_label:
		wave_timer_label.text = "Next: %.0fs" % t if t > 0.0 else ""
	_update_village_hp_bar()
	_update_cargo_display()
	_draw_minimap()
	# Update level-up timer display
	if _cards_container and is_instance_valid(_cards_container):
		var timer_lbl = _cards_container.get_node_or_null("TimerLabel")
		if timer_lbl:
			timer_lbl.text = "Auto-select in %.0fs" % _level_up_timer
	_update_targeting_mode()
	_update_game_over()

func _on_xp_changed(new_xp: int, max_xp: int) -> void:
	if xp_bar:
		xp_bar.max_value = max_xp
		xp_bar.value = new_xp

func _on_level_changed(new_level: int) -> void:
	if level_label:
		level_label.text = "Lv %d" % new_level

func _on_level_up_offer(choices: Array) -> void:
	_pending_choices = choices
	_level_up_timer = 15.0
	_clear_level_up_cards()
	if not level_up_panel:
		return
	level_up_panel.show()
	# VBox: timer on top, cards row below
	_cards_container = VBoxContainer.new()
	_cards_container.name = "CardsContainer"
	_cards_container.add_theme_constant_override("separation", 4)
	level_up_panel.add_child(_cards_container)
	# Timer label at top
	var timer_lbl := Label.new()
	timer_lbl.name = "TimerLabel"
	timer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_lbl.add_theme_color_override("font_color", Color("#FFD700"))
	timer_lbl.add_theme_font_size_override("font_size", 14)
	_cards_container.add_child(timer_lbl)
	# HBox for cards
	var hbox := HBoxContainer.new()
	hbox.name = "CardsRow"
	hbox.add_theme_constant_override("separation", 10)
	_cards_container.add_child(hbox)
	var type_colors := {
		"weapon_upgrade": Color("#FF6B35"),
		"weapon_new": Color("#2ECC71"),
		"utility_upgrade": Color("#45B7D1"),
		"utility_new": Color("#96CEB4"),
		"passive": Color("#FFEAA7"),
	}
	for i in _pending_choices.size():
		var choice = _pending_choices[i]
		var card := Button.new()
		card.name = "Card%d" % i
		card.custom_minimum_size = Vector2(210, 100)
		var card_type: String = choice.get("type", "passive")
		var bg_color: Color = type_colors.get(card_type, Color("#444444"))
		var normal_style := StyleBoxFlat.new()
		normal_style.bg_color = Color(bg_color.r * 0.2, bg_color.g * 0.2, bg_color.b * 0.2, 0.9)
		normal_style.border_color = bg_color
		normal_style.set_border_width_all(2)
		normal_style.set_corner_radius_all(6)
		card.add_theme_stylebox_override("normal", normal_style)
		var hover_style := normal_style.duplicate()
		hover_style.bg_color = Color(bg_color.r * 0.4, bg_color.g * 0.4, bg_color.b * 0.4, 0.95)
		card.add_theme_stylebox_override("hover", hover_style)
		var pressed_style := normal_style.duplicate()
		pressed_style.bg_color = bg_color
		card.add_theme_stylebox_override("pressed", pressed_style)
		# Build text — NO duplication
		var name_text: String = "%d: %s" % [i + 1, choice.get("name", "???")]
		if choice.has("current_level"):
			name_text += " Lv%d→%d" % [choice["current_level"], choice["next_level"]]
		var plain_text := name_text
		var upgrade_name: String = choice.get("upgrade_name", "")
		var upgrade_desc: String = choice.get("upgrade_desc", "")
		if upgrade_name != "":
			plain_text += "\n" + upgrade_name
		if upgrade_desc != "":
			plain_text += "\n" + upgrade_desc
		elif choice.has("desc") and not choice.has("upgrade_name"):
			plain_text += "\n" + str(choice["desc"])
		card.text = plain_text
		card.add_theme_color_override("font_color", Color.WHITE)
		card.add_theme_font_size_override("font_size", 13)
		var idx := i
		card.pressed.connect(func(): _on_card_clicked(idx))
		hbox.add_child(card)

func _on_village_damaged(_amount: float, new_hp: float) -> void:
	if village_hp_bar:
		village_hp_bar.value = new_hp

func _on_wave_started(wave_index: int) -> void:
	if wave_label:
		wave_label.text = "Wave %d" % wave_index

func _on_wave_ended(_wave_index: int) -> void:
	pass

func _on_resources_changed(lumber: int, metal: int, medicine: int) -> void:
	pass

func _on_game_over(wave_index: int) -> void:
	_game_over_visible = true
	_game_over_wave = wave_index

func _auto_select_level_up() -> void:
	if _pending_choices.size() > 0:
		PlayerManager.apply_choice(_pending_choices[0])
	_pending_choices = []
	_level_up_timer = 0.0
	_clear_level_up_cards()
	if level_up_panel:
		level_up_panel.hide()
	get_tree().paused = false

func _input(event: InputEvent) -> void:
	if _pending_choices.size() > 0 and _level_up_timer > 0.0:
		var idx := -1
		if event.is_action_pressed("level_up_1"):
			idx = 0
		elif event.is_action_pressed("level_up_2"):
			idx = 1
		elif event.is_action_pressed("level_up_3"):
			idx = 2
		if idx >= 0 and idx < _pending_choices.size():
			PlayerManager.apply_choice(_pending_choices[idx])
			_pending_choices = []
			_level_up_timer = 0.0
			_clear_level_up_cards()
			if level_up_panel:
				level_up_panel.hide()
			get_tree().paused = false

func _update_village_hp_bar() -> void:
	var village = get_tree().get_first_node_in_group("village") if get_tree() else null
	if not village or not village_hp_bar:
		return
	if "walls_destroyed" in village and village.walls_destroyed:
		village_hp_bar.max_value = village.base_max_hp if "base_max_hp" in village else 200.0
		village_hp_bar.value = village.base_hp if "base_hp" in village else 0.0
	else:
		village_hp_bar.max_value = village.max_hp if "max_hp" in village else 500.0
		village_hp_bar.value = village.hp

func _update_cargo_display() -> void:
	if not cargo_display:
		return
	for child in cargo_display.get_children():
		child.queue_free()
	var loco = get_tree().get_first_node_in_group("locomotive") if get_tree() else null
	if not loco:
		return
	var train_root = loco.get_parent() if loco else null
	if not train_root or not "compartments" in train_root:
		return
	for comp in train_root.compartments:
		var label = Label.new()
		if comp.cargo.is_empty():
			label.text = "[  ]"
		else:
			label.text = "[%s]" % comp.cargo.left(1).to_upper()
		label.add_theme_color_override("font_color", Color.WHITE)
		cargo_display.add_child(label)

func _draw_minimap() -> void:
	if _mini_map_draw:
		_mini_map_draw.queue_redraw()

func _clear_level_up_cards() -> void:
	if _cards_container and is_instance_valid(_cards_container):
		_cards_container.queue_free()
		_cards_container = null

func _on_card_clicked(idx: int) -> void:
	if idx >= 0 and idx < _pending_choices.size():
		PlayerManager.apply_choice(_pending_choices[idx])
	_pending_choices = []
	_level_up_timer = 0.0
	_clear_level_up_cards()
	if level_up_panel:
		level_up_panel.hide()
	get_tree().paused = false

func _update_targeting_mode() -> void:
	var ctrl = $Control as Control
	if not ctrl:
		return
	var label = ctrl.get_node_or_null("TargetingModeLabel")
	if not label:
		label = Label.new()
		label.name = "TargetingModeLabel"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.add_theme_color_override("font_color", Color("#FFD700"))
		label.add_theme_font_size_override("font_size", 16)
		label.position = Vector2(10, 100)
		ctrl.add_child(label)
	var mode_text := "Target: Player" if _MB.targeting_mode == _MB.TargetingMode.PLAYER_CENTER else "Target: Mouse"
	label.text = mode_text

func _update_game_over() -> void:
	if not _game_over_visible:
		return
	# Find or create game over label
	var ctrl = $Control as Control
	if not ctrl:
		return
	var go_label = ctrl.get_node_or_null("GameOverLabel")
	if not go_label:
		go_label = Label.new()
		go_label.name = "GameOverLabel"
		go_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		go_label.add_theme_color_override("font_color", Color.RED)
		go_label.add_theme_font_size_override("font_size", 32)
		ctrl.add_child(go_label)
	go_label.text = "GAME OVER — Wave %d" % _game_over_wave
	go_label.set_anchors_preset(Control.PRESET_CENTER)
	go_label.position = Vector2(-100, -20)
	go_label.custom_minimum_size = Vector2(200, 44)

func _create_minimap_script_inner() -> Script:
	var src = "
extends Node2D
func _draw() -> void:
	var map_half := 1600.0
	var map_scale := 180.0 / (map_half * 2.0)
	var village = get_tree().get_first_node_in_group('village') if get_tree() else null
	var loco = get_tree().get_first_node_in_group('locomotive') if get_tree() else null
	draw_rect(Rect2(-90, -90, 180, 180), Color('#3A3020'))
	if village:
		var vp = village.global_position * map_scale
		draw_rect(Rect2(vp.x - 10, vp.y - 10, 20, 20), Color('#8B7355'))
	if loco:
		var tp = loco.global_position * map_scale
		draw_circle(tp, 4.0, Color('#D2691E'))
	var nodes = get_tree().get_nodes_in_group('resource_nodes') if get_tree() else []
	var type_colors := {'lumber': Color('#22C55E'), 'metal': Color('#EAB308'), 'medicine': Color('#3B82F6')}
	for rn in nodes:
		if not rn is Node2D: continue
		var rp = rn.global_position * map_scale
		var c = type_colors.get(rn.resource_type, Color.GRAY)
		draw_circle(rp, 2.5 if not rn.depleted else 1.5, c if not rn.depleted else Color.GRAY)
	var enemies = get_tree().get_nodes_in_group('enemies') if get_tree() else []
	for e in enemies:
		if not e is Node2D: continue
		var ep = e.global_position * map_scale
		draw_circle(ep, 1.5, Color('#FF4444'))
"
	var script = GDScript.new()
	script.source_code = src
	script.reload()
	return script