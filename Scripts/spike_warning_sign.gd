extends Node2D

## A visible, nonlethal warning for nearby floor spikes.

const OUTLINE := Color("26303d")
const YELLOW := Color("f5c542")
const WOOD := Color("9f6b3e")


func _draw() -> void:
	# The scene origin is the bottom of this small sign, so it sits on a floor.
	draw_rect(Rect2(-2.0, -12.0, 4.0, 12.0), OUTLINE)
	draw_rect(Rect2(-1.0, -11.0, 2.0, 11.0), WOOD)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-8.0, -11.0), Vector2(0.0, -25.0), Vector2(8.0, -11.0)
	]), OUTLINE)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-6.0, -13.0), Vector2(0.0, -21.0), Vector2(6.0, -13.0)
	]), YELLOW)
	for x in [-3.0, 0.0, 3.0]:
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - 1.0, -14.0), Vector2(x, -17.0), Vector2(x + 1.0, -14.0)
		]), OUTLINE)
	draw_rect(Rect2(-5.0, -14.0, 10.0, 1.0), OUTLINE)
