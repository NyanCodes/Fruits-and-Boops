class_name HiddenBlock
extends StaticBody2D

## A block that is invisible until bumped from below, then pops into view.
##
## Blocks join the "resettable" group and restore their untouched state when
## the level calls reset() on that group (see player.gd::respawn).

signal bumped(by: Node2D)

## Group every object that has to return to its start state when the player
## respawns. Members must define reset().
const RESET_GROUP := "resettable"

const BUMP_HEIGHT := 4.0
const BUMP_TIME := 0.07

enum Reaction { REVEAL, ESCAPE, SPIKE }

@export var reveal_on_hit: bool = true
@export var kills_player: bool = false
@export var one_shot: bool = true
@export var reaction: Reaction = Reaction.REVEAL
@export var escape_distance := 32.0

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _shape: CollisionShape2D = $CollisionShape2D
@onready var _spike_hitbox: Area2D = get_node_or_null("SpikeHitBox") as Area2D

var _home_y: float
var _home_one_way: bool
var _used: bool = false
var _spike_visible := false
var _bump: Tween


func _ready() -> void:
	add_to_group(RESET_GROUP)
	_home_y = position.y
	_home_one_way = _shape.one_way_collision
	_sprite.visible = false
	if _spike_hitbox != null:
		_spike_hitbox.body_entered.connect(_on_spike_body_entered)
		_spike_hitbox.monitoring = false
	queue_redraw()


func on_hit(body: Node2D, normal: Vector2) -> void:
	# +Y is down in Godot 2D, so this only fires on a hit from underneath.
	if normal.y <= 0.5:
		return
	if _used and one_shot:
		return
	_used = true

	if reveal_on_hit:
		_sprite.visible = true
		# Clearing this directly inside a physics callback would error.
		_shape.set_deferred("one_way_collision", false)

	if reaction == Reaction.ESCAPE:
		_escape()
	elif reaction == Reaction.SPIKE:
		_spike_visible = true
		if _spike_hitbox != null:
			_spike_hitbox.set_deferred("monitoring", true)
		queue_redraw()
	else:
		_play_bump()

	if kills_player and body.has_method("die"):
		body.die()
	Audio.sfx(&"block_bump")
	bumped.emit(body)


## Returns the block to its untouched state: hidden, bumpable again, and back
## at its starting height even if a bump was still animating.
func reset() -> void:
	_stop_bump()
	_used = false
	position.y = _home_y
	_sprite.visible = false
	_spike_visible = false
	if _spike_hitbox != null:
		_spike_hitbox.set_deferred("monitoring", false)
	_shape.set_deferred("one_way_collision", _home_one_way)
	queue_redraw()


func _escape() -> void:
	_stop_bump()
	_bump = create_tween()
	_bump.tween_property(self, "position:y", _home_y - escape_distance, 0.18)


func _on_spike_body_entered(body: Node2D) -> void:
	if _spike_visible and body.has_method("die"):
		body.die()


func _draw() -> void:
	if not _spike_visible:
		return
	var spike_color := Color("f04f5f")
	for x in [-6.0, 0.0, 6.0]:
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - 3.0, -8.0),
			Vector2(x + 3.0, -8.0),
			Vector2(x, -16.0),
		]), spike_color)


func _play_bump() -> void:
	# Kill any bump still running, otherwise repeat hits on a non-one_shot block
	# capture a mid-animation start_y and the block drifts upward.
	_stop_bump()
	_bump = create_tween()
	_bump.tween_property(self, "position:y", _home_y + BUMP_HEIGHT, BUMP_TIME)
	_bump.tween_property(self, "position:y", _home_y, BUMP_TIME)


func _stop_bump() -> void:
	if _bump != null and _bump.is_valid():
		_bump.kill()
	_bump = null
