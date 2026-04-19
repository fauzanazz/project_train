extends CanvasLayer
## res://scripts/hud.gd
## All HUD widget updates, level-up panel, mini-map, and cargo display.

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

# Mini-map draw node
var _mini_map_draw: Node2D = null

func _ready() -> void:
	PlayerManager.xp_changed.connect(_on_xp_changed)
	PlayerManager.level_changed.connect(_on_level_changed)
	PlayerManager.level_up_offer.connect(_on_level_up_offer)
	ResourceManager.resources_changed.connect(_on_resources_changed)
	WaveManager.wave_started.connect(_on_wave_started)
	WaveManager.wave_ended.connect(_on_wave_ended)
	GameManager.game_over.connect(_on_game_over)
	if level_up_panel:
		level_up_panel.hide()

	# Build mini-map draw node inside the SubViewport
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
		_mini_map_draw.set_script(_create_minimap_script())
		sv.add_child(_mini_map_draw)

	# Connect village damage signal (deferred since Village is a scene node)
	_connect_village_signal.call_deferred()

func _connect_village_signal() -> void:
	var village = get_tree().get_first_node_in_group("village") if get_tree() else null
	if village and village.has_signal("village_damaged"):
		village.village_damaged.connect(_on_village_damaged)

func _create_minimap_script():
	return _create_minimap_script_inner()

func _process(delta: float) -> void:
	if _level_up_timer > 0.0:
		_level_up_timer -= delta
		if _level_up_timer <= 0.0:
			_auto_select_level_up()
	# Update wave timer display
	var t: float = WaveManager.get_wave_time_remaining()
	if wave_timer_label:
		wave_timer_label.text = "Next: %.0fs" % t if t > 0.0 else ""
	# Update village HP bar directly from village node
	_update_village_hp_bar()
	# Update cargo display from train compartments
	_update_cargo_display()
	# Draw mini-map
	_draw_minimap()

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
	if level_up_panel:
		level_up_panel.show()

func _on_village_damaged(_amount: float, new_hp: float) -> void:
	if village_hp_bar:
		village_hp_bar.value = new_hp

func _on_wave_started(wave_index: int) -> void:
	if wave_label:
		wave_label.text = "Wave %d" % wave_index

func _on_wave_ended(_wave_index: int) -> void:
	pass

func _on_resources_changed(_lumber: int, _metal: int, _medicine: int) -> void:
	pass

func _on_game_over(_wave_index: int) -> void:
	pass

func _auto_select_level_up() -> void:
	_level_up_timer = 0.0
	if level_up_panel:
		level_up_panel.hide()

func _update_village_hp_bar() -> void:
	var village = get_tree().get_first_node_in_group("village") if get_tree() else null
	if village and village.has_method("get") and "hp" in village and village_hp_bar:
		village_hp_bar.max_value = village.max_hp if "max_hp" in village else 500.0
		village_hp_bar.value = village.hp

func _update_cargo_display() -> void:
	if not cargo_display:
		return
	# Clear existing
	for child in cargo_display.get_children():
		child.queue_free()
	var train = get_tree().get_first_node_in_group("locomotive") if get_tree() else null
	if not train:
		return
	# Find Train parent
	var train_root = train.get_parent() if train else null
	if not train_root or not train_root.has_method("get"):
		return
	if not "compartments" in train_root:
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
	if not _mini_map_draw:
		return
	_mini_map_draw.queue_redraw()

func _create_minimap_script_inner() -> Script:
	# Dynamically create a mini-map drawing script
	var src = "
extends Node2D
func _draw() -> void:
	var map_half := 1600.0
	var map_scale := 180.0 / (map_half * 2.0)
	var village = get_tree().get_first_node_in_group('village') if get_tree() else null
	var loco = get_tree().get_first_node_in_group('locomotive') if get_tree() else null
	# Background
	draw_rect(Rect2(-90, -90, 180, 180), Color('#3A3020'))
	# Village dot
	if village:
		var vp = village.global_position * map_scale
		draw_circle(vp + Vector2(0, 0), 6.0, Color('#8B7355'))
	# Train dot
	if loco:
		var tp = loco.global_position * map_scale
		draw_circle(tp, 4.0, Color('#D2691E'))
	# Resource dots
	var nodes = get_tree().get_nodes_in_group('resource_nodes') if get_tree() else []
	var type_colors := {'lumber': Color('#22C55E'), 'metal': Color('#EAB308'), 'medicine': Color('#3B82F6')}
	for rn in nodes:
		if not rn is Node2D:
			continue
		var rp = rn.global_position * map_scale
		var c = type_colors.get(rn.resource_type, Color.GRAY)
		draw_circle(rp, 2.5 if not rn.depleted else 1.5, c if not rn.depleted else Color.GRAY)
"
	var script = GDScript.new()
	script.source_code = src
	script.reload()
	return script
