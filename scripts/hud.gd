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

func _process(delta: float) -> void:
	if _level_up_timer > 0.0:
		_level_up_timer -= delta
		if _level_up_timer <= 0.0:
			_auto_select_level_up()
	# Update wave timer display
	var t: float = WaveManager.get_wave_time_remaining()
	if wave_timer_label:
		wave_timer_label.text = "Next: %.0fs" % t if t > 0.0 else ""

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
		# Card population implemented in Task 2

func _on_village_damaged(_amount: float, new_hp: float) -> void:
	if village_hp_bar:
		village_hp_bar.value = new_hp

func _on_wave_started(wave_index: int) -> void:
	if wave_label:
		wave_label.text = "Wave %d" % wave_index

func _on_wave_ended(_wave_index: int) -> void:
	pass

func _on_resources_changed(_lumber: int, _metal: int, _medicine: int) -> void:
	# Cargo slot visuals updated in Task 2
	pass

func _on_game_over(_wave_index: int) -> void:
	# Game over overlay shown in Task 2
	pass

func _auto_select_level_up() -> void:
	_level_up_timer = 0.0
	if level_up_panel:
		level_up_panel.hide()
	# Auto-pick logic implemented in Task 2
