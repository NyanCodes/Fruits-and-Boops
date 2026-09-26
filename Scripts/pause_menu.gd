extends CanvasLayer

## In-game pause and audio settings. This node keeps processing while the
## SceneTree is paused so Esc, sliders and navigation remain responsive.

const MAIN_MENU := "res://Scenes/MainMenu.tscn"

@onready var _panel: PanelContainer = $Overlay/Panel
@onready var _resume_button: Button = $Overlay/Panel/Box/Resume

var _locked := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_resume_button.pressed.connect(_resume)
	$Overlay/Panel/Box/Restart.pressed.connect(_restart_stage)
	$Overlay/Panel/Box/MainMenu.pressed.connect(_return_to_menu)
	$Overlay/Panel/Box/Quit.pressed.connect(_quit_game)

	for bus in Audio.VOLUME_BUSES:
		var row := _panel.get_node("Box/" + str(bus))
		var slider := row.get_node("Slider") as HSlider
		var value_label := row.get_node("Value") as Label
		slider.value = roundf(Audio.get_bus_volume(bus) * 100.0)
		value_label.text = "%d%%" % slider.value
		slider.value_changed.connect(func(value: float) -> void:
			Audio.set_bus_volume(bus, value / 100.0)
			value_label.text = "%d%%" % value
		)

	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if _locked or not event.is_action_pressed(&"ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	if visible:
		_resume()
	else:
		_open()


## Prevent the pause overlay from opening over the stage-clear screen.
func lock() -> void:
	_locked = true
	visible = false


func _open() -> void:
	visible = true
	get_tree().paused = true
	_resume_button.grab_focus()


func _resume() -> void:
	Audio.save_volume_settings()
	visible = false
	get_tree().paused = false


func _restart_stage() -> void:
	Audio.save_volume_settings()
	get_tree().paused = false
	get_tree().reload_current_scene()


func _return_to_menu() -> void:
	Audio.save_volume_settings()
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU)


func _quit_game() -> void:
	Audio.save_volume_settings()
	get_tree().quit()
