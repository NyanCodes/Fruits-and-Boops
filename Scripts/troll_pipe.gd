class_name TrollPipe
extends Area2D

## A harmless-looking pipe that releases an enemy when the player gets close.
## The pipe stays put; the spawned enemy is reset with the stage after a death.

const RESET_GROUP := "resettable"

@export var trigger_distance := 72.0
@export var spawn_offset := Vector2(0.0, -30.0)
@export var spawn_velocity := Vector2(0.0, -180.0)
@export var spawn_delay := 0.12
@export var enemy_scene: PackedScene

@onready var _detector: Area2D = $Detector

var _home := Vector2.ZERO
var _triggered := false
var _spawned_enemy: Node2D
var _token := 0


func _ready() -> void:
	add_to_group(RESET_GROUP)
	_home = position
	_detector.body_entered.connect(_on_detector_body_entered)
	(_detector.get_node("CollisionShape2D").shape as RectangleShape2D).size = Vector2(trigger_distance, 42.0)
	reset()


func _on_detector_body_entered(body: Node2D) -> void:
	if _triggered or enemy_scene == null or not body.has_method("die"):
		return
	_triggered = true
	_detector.set_deferred("monitoring", false)
	var token := _token
	_spawn_enemy(token)


func _spawn_enemy(token: int) -> void:
	await get_tree().create_timer(spawn_delay).timeout
	if token != _token or not is_inside_tree() or enemy_scene == null:
		return
	var enemy := enemy_scene.instantiate() as Node2D
	if enemy == null:
		return
	# Set the local spawn position before adding it so EnemyWalker captures the
	# pipe location as its reset home in _ready().
	enemy.position = position + spawn_offset
	get_parent().add_child(enemy)
	_spawned_enemy = enemy
	if enemy is CharacterBody2D:
		(enemy as CharacterBody2D).velocity = spawn_velocity
	Audio.sfx(&"cannon", -8.0)


func reset() -> void:
	_token += 1
	if is_instance_valid(_spawned_enemy):
		_spawned_enemy.queue_free()
	_spawned_enemy = null
	position = _home
	_triggered = false
	_detector.set_deferred("monitoring", true)
	queue_redraw()


func _draw() -> void:
	var body_color := Color("4bc06f")
	var edge := Color("193b38")
	draw_rect(Rect2(-10.0, -30.0, 20.0, 30.0), edge)
	draw_rect(Rect2(-8.0, -28.0, 16.0, 28.0), body_color)
	draw_rect(Rect2(-13.0, -34.0, 26.0, 7.0), edge)
	draw_rect(Rect2(-11.0, -32.0, 22.0, 4.0), body_color)
