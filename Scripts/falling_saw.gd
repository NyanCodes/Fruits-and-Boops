class_name FallingSaw
extends Area2D

## A spinning saw that drops when the player gets close to its trigger zone.
## The default keeps ordinary saws unchanged; Stage 2 enables the drop per
## instance for its elevated troll wheels.

const RESET_GROUP := "resettable"

@export var drop_when_close := false
@export var trigger_distance := 50.0
@export var trigger_vertical_distance := 0.0
@export var drop_distance := 10
@export var drop_speed := 110.0
@export var roll_after_drop := false
@export var roll_distance := 112.0
@export var roll_speed := 90.0

var _home := Vector2.ZERO
var _dropping := false
var _rolling := false
var _roll_direction := -1.0
var _dropped := false


func _ready() -> void:
	add_to_group(RESET_GROUP)
	_home = position
	body_entered.connect(_on_body_entered)
	reset()


func _physics_process(delta: float) -> void:
	if not drop_when_close:
		return
	if _dropping:
		position.y = move_toward(position.y, _home.y + drop_distance, drop_speed * delta)
		if is_equal_approx(position.y, _home.y + drop_distance):
			_dropping = false
			_rolling = roll_after_drop and roll_distance > 0.0
		return
	if _rolling:
		var roll_target := _home.x + _roll_direction * roll_distance
		position.x = move_toward(position.x, roll_target, roll_speed * delta)
		if is_equal_approx(position.x, roll_target):
			_rolling = false
		return
	if _dropped:
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null or not player.has_method("die"):
		return
	if absf(player.global_position.x - global_position.x) > trigger_distance:
		return
	# A value of zero keeps the original horizontal-only trigger. Elevated saws
	# can opt into this guard so walking underneath them on another floor does
	# not consume the trap before the player reaches their platform.
	if trigger_vertical_distance > 0.0 \
			and absf(player.global_position.y - global_position.y) > trigger_vertical_distance:
		return
	_roll_direction = -1.0 if player.global_position.x < global_position.x else 1.0
	_dropped = true
	_dropping = true
	Audio.sfx(&"crumble", -5.0)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("die"):
		body.die()


func reset() -> void:
	position = _home
	_dropping = false
	_rolling = false
	_roll_direction = -1.0
	_dropped = false
