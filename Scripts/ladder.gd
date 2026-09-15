@tool
class_name Ladder
extends Area2D

## A climbable ladder. The node sits at the ladder's foot and it rises `height`
## pixels. Its top is a one-way plank, so a ladder can pass up through a hole in
## a floor without leaving a gap to fall into: walk across the plank, or stand on
## it and press down to climb back down.
##
## Put the foot on the floor you climb from and set `height` to the rise to the
## floor you climb to. Stage tiles are 16 px, so heights come in steps of 16.
##
## The climbing itself lives in player.gd - this node only reports who is
## touching it and where its ends are.

## Stops short of the plank's edges, so the player has to be lined up with the
## ladder to grab it rather than catching it from a tile away.
const GRAB_WIDTH := 12.0
## How far the grab zone reaches above the plank. A player standing on the top
## still has to be touching the ladder, or they could never climb down.
const TOP_REACH := 8.0

const PLANK_THICKNESS := 4.0
const RUNG_SPACING := 8

# Pixel Adventure's brown platform palette, so the ladder sits with the tiles.
const OUTLINE := Color8(33, 31, 48)
const WOOD_DARK := Color8(132, 51, 70)
const WOOD := Color8(161, 71, 68)
const WOOD_LIGHT := Color8(185, 110, 84)

@export_range(16.0, 480.0, 16.0, "suffix:px") var height := 96.0:
	set(value):
		height = value
		if is_node_ready():
			_fit()

@onready var _grab: CollisionShape2D = $Grab
@onready var plank: StaticBody2D = $Plank
@onready var _plank_shape: CollisionShape2D = $Plank/CollisionShape2D


func _ready() -> void:
	_fit()
	if Engine.is_editor_hint():
		return
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


## Global y of the plank's walking surface.
func top_y() -> float:
	return global_position.y - height


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("enter_ladder"):
		body.enter_ladder(self)


func _on_body_exited(body: Node2D) -> void:
	if body.has_method("exit_ladder"):
		body.exit_ladder(self)


## Sizes the grab zone and moves the plank to match `height`. The grab shape is
## local to each instance (see Ladder.tscn), so ladders of different heights do
## not resize each other.
func _fit() -> void:
	var reach := height + TOP_REACH
	(_grab.shape as RectangleShape2D).size = Vector2(GRAB_WIDTH, reach)
	_grab.position = Vector2(0.0, -reach * 0.5)
	_plank_shape.position = Vector2(0.0, -height + PLANK_THICKNESS * 0.5)
	queue_redraw()


func _draw() -> void:
	var top := -height

	# Two rails, each a 2 px wooden strip in a 1 px outline.
	for x in [-8.0, 4.0]:
		draw_rect(Rect2(x, top, 4.0, height), OUTLINE)
		draw_rect(Rect2(x + 1.0, top, 2.0, height), WOOD)
		draw_rect(Rect2(x + 1.0, top, 1.0, height), WOOD_LIGHT)

	# Rungs from the foot upward, stopping clear of the plank.
	var y := -4.0
	while y - 4.0 > top + PLANK_THICKNESS:
		draw_rect(Rect2(-4.0, y - 3.0, 8.0, 3.0), OUTLINE)
		draw_rect(Rect2(-4.0, y - 2.0, 8.0, 1.0), WOOD_LIGHT)
		y -= RUNG_SPACING

	# The plank the player stands on at the top.
	draw_rect(Rect2(-8.0, top, 16.0, PLANK_THICKNESS), OUTLINE)
	draw_rect(Rect2(-7.0, top + 1.0, 14.0, 1.0), WOOD_LIGHT)
	draw_rect(Rect2(-7.0, top + 2.0, 14.0, 1.0), WOOD_DARK)
