extends Node2D

## Stage bookkeeping: counts fruit and announces the finish.
##
## Fruit and death counts survive respawns and reset when the scene reloads.

const MAIN_MENU := "res://Scenes/MainMenu.tscn"
const STAGE_TRANSITION_DELAY := 2.0
const PAUSE_MENU_SCENE := preload("res://Scenes/PauseMenu.tscn")

## Optional starting checkpoint for test scenes. Empty uses the normal start.
@export_node_path("Area2D") var start_checkpoint: NodePath
## The number shown in the stage-clear UI. This is independent of the scene
## filename, which lets stages be reordered without moving their level data.
@export_range(1, 99, 1) var stage_number := 1
## Scene loaded automatically after the clear banner has been shown briefly.
@export_file("*.tscn") var next_scene := MAIN_MENU

@onready var _count: Label = $HUD/FruitPanel/Row/Count
@onready var _timer_label: Label = $HUD/TimerPanel/Time
@onready var _banner: Control = $HUD/Banner
@onready var _banner_text: Label = $HUD/Banner/Box/Text
@onready var _banner_stats: Label = $HUD/Banner/Box/Stats
@onready var _again_button: Button = $HUD/Banner/Box/Buttons/Again
@onready var _banner_buttons: Control = $HUD/Banner/Box/Buttons
@onready var _death_box: Control = $HUD/DeathBox
@onready var _death_tally: Label = $HUD/DeathBox/Row/Count

var _collected := 0
var _total := 0
var _deaths := 0
var _elapsed_time := 0.0
var _displayed_second := -1
var _timer_running := true
var _pause_menu: CanvasLayer


func _ready() -> void:
	_pause_menu = PAUSE_MENU_SCENE.instantiate() as CanvasLayer
	add_child(_pause_menu)

	var coins := get_tree().get_nodes_in_group(Coin.COIN_GROUP)
	_total = coins.size()
	for coin in coins:
		coin.collected.connect(_on_coin_collected)

	var goal := get_node_or_null("Goal")
	if goal != null:
		goal.reached.connect(_on_goal_reached)

	var player := get_node_or_null("Player")
	if player != null:
		player.died.connect(_on_player_died)
		player.respawned.connect(_on_player_respawned)
		if not start_checkpoint.is_empty():
			var checkpoint := get_node_or_null(start_checkpoint) as Node2D
			if checkpoint != null:
				player.global_position = checkpoint.global_position
				player.set_spawn(checkpoint.global_position)
				var camera := player.get_node_or_null("Camera2D") as Camera2D
				if camera != null:
					camera.reset_smoothing()
			else:
				push_warning("Starting checkpoint not found: %s" % start_checkpoint)

	_again_button.pressed.connect(_on_play_again)
	$HUD/Banner/Box/Buttons/Menu.pressed.connect(_on_main_menu)

	# A run that ended on the pause menu leaves the tree paused behind it.
	get_tree().paused = false
	_banner.visible = false
	_death_box.visible = false
	_refresh()
	_refresh_timer()
	Audio.play_music(&"stage1")


func _process(delta: float) -> void:
	if not _timer_running:
		return
	_elapsed_time += delta
	var whole_seconds := int(_elapsed_time)
	if whole_seconds != _displayed_second:
		_refresh_timer()


func _on_coin_collected(_coin: Coin) -> void:
	_collected += 1
	_refresh()


## Shown during the respawn pause. The tally deliberately survives a death -
## it is a running count for the whole attempt, not per life.
func _on_player_died() -> void:
	_deaths += 1
	_death_tally.text = "x %d" % _deaths
	_death_box.visible = true


func _on_player_respawned() -> void:
	_death_box.visible = false


func _on_goal_reached() -> void:
	_timer_running = false
	_pause_menu.call("lock")
	Audio.sfx(&"stage_clear", 0.0, 0.0)
	_show_banner("STAGE %d CLEAR" % stage_number)
	await get_tree().create_timer(STAGE_TRANSITION_DELAY, true, false, true).timeout
	get_tree().paused = false
	get_tree().change_scene_to_file(next_scene)


## Pausing freezes enemies, cannons and the player while the clear result is
## visible. The process-always transition timer continues while the tree rests.
func _show_banner(heading: String) -> void:
	_banner_text.text = heading
	var destination := "Returning to menu..." if next_scene == MAIN_MENU else "Next stage..."
	_banner_stats.text = "%d / %d fruit    %d deaths    %s\n%s" % [_collected, _total, _deaths, _formatted_time(), destination]
	_banner_buttons.visible = false
	_banner.visible = true
	get_tree().paused = true


func _on_play_again() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU)


func _refresh() -> void:
	_count.text = "%d / %d" % [_collected, _total]


func _refresh_timer() -> void:
	_displayed_second = int(_elapsed_time)
	_timer_label.text = "TIME  %s" % _formatted_time()


func _formatted_time() -> String:
	var total_seconds := int(_elapsed_time)
	var minutes := floori(total_seconds / 60.0)
	return "%02d:%02d" % [minutes, total_seconds % 60]
