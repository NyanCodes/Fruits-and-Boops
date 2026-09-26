class_name Player
extends CharacterBody2D

## Stage 1 player controller: walking, jumping, gravity and platform collision.
##
## The numbers below are tuned together — a jump reaches about 63 px (3.5 tiles)
## and carries the player roughly 110 px (6 tiles) across a gap at full speed.
## Change SPEED or JUMP_VELOCITY and the level's gaps need re-checking.

const SPEED := 200.0              # top horizontal speed, px/s
const ACCEL_GROUND := 1600.0      # px/s^2 while standing on something
const ACCEL_AIR := 900.0          # weaker steering mid-air
const FRICTION_GROUND := 1800.0
const FRICTION_AIR := 400.0

const JUMP_VELOCITY := -420.0
const FALL_GRAVITY_SCALE := 1.35  # heavier on the way down so jumps feel snappy
const JUMP_CUT := 0.4             # upward speed kept when jump is released early
const MAX_FALL_SPEED := 600.0

const COYOTE_TIME := 0.10         # jump still works just after leaving a ledge
const JUMP_BUFFER := 0.12         # jump pressed just before landing still counts

# Long enough to read the death counter, short enough that fifty deaths do
# not cost a minute and a half of staring. The death sting outlives it by
# design - it carries over into the respawn.
const RESPAWN_DELAY := 1.2

# A 96 px ladder (one floor in Stage 2) takes a little over a second.
const CLIMB_SPEED := 90.0
const LADDER_JUMP := 0.75         # jumping off a ladder is a smaller hop than a full jump

signal died
signal respawned

@onready var _anim: AnimatedSprite2D = $AnimatedSprite2D

var _spawn_point: Vector2
var _coyote := 0.0
var _buffer := 0.0
var _dead := false
var _was_grounded := true
var _ladder: Ladder               # the ladder being touched, if any
var _climbing := false


func _ready() -> void:
	add_to_group("player")
	_spawn_point = global_position


func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")

	if not _climbing:
		_try_grab_ladder()
	if _climbing:
		_apply_climb(direction)
	else:
		_apply_gravity(delta)
		_apply_jump(delta)
		_apply_walk(direction, delta)

	move_and_slide()
	if _climbing:
		_check_ladder_ends()
	_report_landing()
	_report_hits()
	_update_animation(direction)


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return
	var gravity := get_gravity()
	if velocity.y > 0.0:
		gravity *= FALL_GRAVITY_SCALE
	velocity += gravity * delta
	velocity.y = minf(velocity.y, MAX_FALL_SPEED)


func _apply_jump(delta: float) -> void:
	_coyote = COYOTE_TIME if is_on_floor() else maxf(_coyote - delta, 0.0)
	_buffer = JUMP_BUFFER if Input.is_action_just_pressed("jump") else maxf(_buffer - delta, 0.0)

	if _buffer > 0.0 and _coyote > 0.0:
		velocity.y = JUMP_VELOCITY
		_buffer = 0.0
		_coyote = 0.0
		Audio.sfx(&"jump")

	# Letting go early cuts the jump short, so a tap gives a small hop.
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT


func _apply_walk(direction: float, delta: float) -> void:
	var grounded := is_on_floor()
	if direction != 0.0:
		var accel := ACCEL_GROUND if grounded else ACCEL_AIR
		velocity.x = move_toward(velocity.x, direction * SPEED, accel * delta)
	else:
		var friction := FRICTION_GROUND if grounded else FRICTION_AIR
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)


## Ladders call these as the player touches and leaves them (see ladder.gd).
func enter_ladder(ladder: Ladder) -> void:
	_ladder = ladder


func exit_ladder(ladder: Ladder) -> void:
	if ladder != _ladder:
		return
	_release_ladder()
	_ladder = null


## Up grabs a ladder from below or mid-air. Down grabs it from the plank on top,
## or mid-air to catch it while falling.
##
## Up and W also jump, so this runs before the jump does: on a ladder they
## climb, and anywhere else they still jump exactly as before.
func _try_grab_ladder() -> void:
	if _ladder == null or _dead:
		return
	var below_top := global_position.y > _ladder.top_y() + 1.0
	if Input.is_action_pressed("move_up") and below_top:
		_grab_ladder()
	elif Input.is_action_pressed("move_down") and (not below_top or not is_on_floor()):
		_grab_ladder()


func _grab_ladder() -> void:
	_climbing = true
	velocity = Vector2.ZERO
	_coyote = 0.0
	_buffer = 0.0
	global_position.x = _ladder.global_position.x
	# Lets the player climb down through the plank they were standing on.
	add_collision_exception_with(_ladder.plank)


## Straight up and down, centred on the ladder - Stage 2's ladders pass through
## holes only a tile wide, so drifting sideways would snag on the edges.
func _apply_climb(direction: float) -> void:
	# Space lets go with a hop. W and Up are jump keys too, but pressing them
	# here means "climb", so a jump only counts if up was not pressed with it.
	if Input.is_action_just_pressed("jump") and not Input.is_action_just_pressed("move_up"):
		_release_ladder()
		velocity = Vector2(direction * SPEED, JUMP_VELOCITY * LADDER_JUMP)
		Audio.sfx(&"jump")
		return

	global_position.x = _ladder.global_position.x
	velocity = Vector2(0.0, Input.get_axis("move_up", "move_down") * CLIMB_SPEED)


## Climbing past the top leaves the player standing on the plank; climbing down
## onto a floor lets go.
func _check_ladder_ends() -> void:
	if _ladder == null:
		return
	var top := _ladder.top_y()
	if global_position.y <= top:
		global_position.y = top
		velocity = Vector2.ZERO
		_release_ladder()
	# Not `velocity.y > 0`: move_and_slide zeroes the fall speed on the frame
	# the feet touch down, which is exactly the frame this needs to catch.
	elif velocity.y >= 0.0 and is_on_floor():
		_release_ladder()


func _release_ladder() -> void:
	if not _climbing:
		return
	_climbing = false
	_anim.speed_scale = 1.0
	if _ladder != null:
		remove_collision_exception_with(_ladder.plank)


## One thud on the frame the player touches down, not every frame after.
func _report_landing() -> void:
	var grounded := is_on_floor()
	if grounded and not _was_grounded and not _dead:
		Audio.sfx(&"land", -7.0)
	_was_grounded = grounded


## Lets blocks react to being bumped (see hidden_block.gd).
func _report_hits() -> void:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider != null and collider.has_method("on_hit"):
			collider.on_hit(self, collision.get_normal())

	# Bonking a ceiling kills upward momentum instead of scraping along it.
	if is_on_ceiling():
		velocity.y = 60.0


func _update_animation(direction: float) -> void:
	if _dead:
		return

	if direction != 0.0 and not _climbing:
		_anim.flip_h = direction < 0.0

	var next := "idle"
	if _climbing:
		next = "climb"
	elif not is_on_floor():
		next = "jump" if velocity.y < 0.0 else "fall"
	elif direction != 0.0:
		next = "run"

	# Not every player scene defines every state — walk down to one that exists.
	for candidate in [next, "jump", "idle"]:
		if _anim.sprite_frames.has_animation(candidate):
			next = candidate
			break

	_anim.play(next)
	# Hanging still on a ladder holds the pose instead of looping it.
	_anim.speed_scale = 0.0 if _climbing and velocity.y == 0.0 else 1.0


func die() -> void:
	if _dead:
		return
	_dead = true
	_release_ladder()
	Audio.sfx(&"death", 0.0, 0.03)
	Audio.stop_music()
	died.emit()
	velocity = Vector2.ZERO
	set_physics_process(false)
	if _anim.sprite_frames.has_animation("hit"):
		_anim.play("hit")

	await get_tree().create_timer(RESPAWN_DELAY).timeout
	respawn()


## Death does not reload the scene, so anything the player changed on the way
## through has to be put back by hand. Blocks and other one-shot props join the
## "resettable" group and define reset() (see hidden_block.gd).
func respawn() -> void:
	global_position = _spawn_point
	velocity = Vector2.ZERO
	_coyote = 0.0
	_buffer = 0.0
	_dead = false
	get_tree().call_group(HiddenBlock.RESET_GROUP, "reset")
	set_physics_process(true)
	Audio.play_music(&"stage1")
	respawned.emit()


## Checkpoints call this to move where death sends the player back to.
func set_spawn(point: Vector2) -> void:
	_spawn_point = point


func _on_kill_zone_body_entered(body: Node2D) -> void:
	if body.has_method("die"):
		body.die()
