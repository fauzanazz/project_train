extends Node
## res://scripts/player_manager.gd
## Owns XP ledger, player level, and level-up card dispatch. Singleton autoloaded as PlayerManager.

signal xp_changed(new_xp: int, max_xp: int)
signal level_changed(new_level: int)
signal level_up_offer(choices: Array)

var current_xp: int = 0
var current_level: int = 1
var _xp_for_next: int = 100

func _ready() -> void:
	GameManager.game_started.connect(_on_game_started)

func _on_game_started() -> void:
	current_xp = 0
	current_level = 1
	_xp_for_next = _xp_threshold(1)

func _xp_threshold(level: int) -> int:
	return int(100.0 * pow(level, 1.4))

func add_xp(amount: int) -> void:
	current_xp += amount
	xp_changed.emit(current_xp, _xp_for_next)
	while current_xp >= _xp_for_next:
		current_xp -= _xp_for_next
		current_level += 1
		_xp_for_next = _xp_threshold(current_level)
		level_changed.emit(current_level)
		_offer_level_up()

func _offer_level_up() -> void:
	# Choices assembled by HUD / modifier system in Task 2
	level_up_offer.emit([])

func _on_zombie_killed(xp: int, _position: Vector2, _resource_drop: Dictionary) -> void:
	add_xp(xp)

func _on_train_destroyed(_cargo: Array) -> void:
	# XP is kept on train destruction — no XP loss
	pass
