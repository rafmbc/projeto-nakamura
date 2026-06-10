extends CharacterBody3D

@export var walk_speed: float = 8.0
@export var run_speed: float = 18.0
@export var jump_velocity: float = 6.0
@export var mouse_sensitivity: float = 0.002
@export var gravity: float = 20.0

# Wave push parameters
@export var wave_push_force: float = 48.0
@export var wave_push_up: float = 10.0
@export var wave_influence_radius: float = 60.0

# Safety floor — if player falls below this Y they're teleported back
@export var void_floor_y: float = -30.0
@export var respawn_y: float = 2.0

# Maximum horizontal speed so wave can't launch player off the map
@export var max_horizontal_speed: float = 80.0

var _camera_pitch: float = 0.0
var _wave_node: Node3D = null
var _being_pushed: bool = false
var _wave_push_strength: float = 0.0

# Saved spawn position for respawn after void fall
var _spawn_pos: Vector3 = Vector3.ZERO

@onready var camera: Camera3D = $CameraArm/Camera3D
@onready var camera_arm: Node3D = $CameraArm

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_spawn_pos = global_position
	_wave_node = get_parent().get_node_or_null("Tsunami")

func _input(event: InputEvent) -> void:
	# Mouse look is only active when mouse is captured (walk mode)
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		_camera_pitch = clamp(_camera_pitch - event.relative.y * mouse_sensitivity, -1.2, 0.8)
		camera_arm.rotation.x = _camera_pitch

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	# ── Void safety — teleport back if player falls off the world ────────────
	if global_position.y < void_floor_y:
		global_position = _spawn_pos + Vector3(0, respawn_y, 0)
		velocity = Vector3.ZERO
		return

	# ── Gravity ───────────────────────────────────────────────────────────────
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		# Reset spawn anchor to current safe ground position
		_spawn_pos = Vector3(global_position.x, 0, global_position.z)
		if Input.is_action_just_pressed("ui_accept"):
			velocity.y = jump_velocity

	# ── Wave collision push ───────────────────────────────────────────────────
	_apply_wave_push(delta)

	# ── Clamp horizontal speed so the wave can't send the player off the map ──
	var horiz := Vector2(velocity.x, velocity.z)
	if horiz.length() > max_horizontal_speed:
		horiz = horiz.normalized() * max_horizontal_speed
		velocity.x = horiz.x
		velocity.z = horiz.y

	# ── Player movement
	# Movement and camera look are fully independent:
	# mouse controls camera pitch/yaw,  WASD moves relative to camera facing.
	# control_factor only slightly reduces movement while pushed (feels more
	# realistic — you can still try to run but the wave overpowers you)
	var control_factor: float = max(0.60, 1.0 - clamp(_wave_push_strength, 0.0, 1.0) * 0.40)
	var input_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):    input_dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):  input_dir.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):  input_dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): input_dir.x += 1

	var speed: float = (run_speed if Input.is_key_pressed(KEY_SHIFT) else walk_speed) * control_factor

	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()
		var dir3d := (transform.basis * Vector3(input_dir.x, 0, input_dir.y))
		velocity.x = lerp(velocity.x, dir3d.x * speed, 10.0 * delta)
		velocity.z = lerp(velocity.z, dir3d.z * speed, 10.0 * delta)
	else:
		if not _being_pushed:
			velocity.x = move_toward(velocity.x, 0, speed * 10.0 * delta)
			velocity.z = move_toward(velocity.z, 0, speed * 10.0 * delta)

	move_and_slide()

func _apply_wave_push(delta: float) -> void:
	if _wave_node == null or not _wave_node.is_active():
		_being_pushed = false
		_wave_push_strength = 0.0
		return

	var wave_z: float = _wave_node.get_wave_z()
	var wave_front_z: float = wave_z + _wave_node.wave_depth * 0.92
	var dist: float = global_position.z - wave_front_z

	var hit_start: float = -wave_influence_radius * 0.2
	var hit_end: float   =  wave_influence_radius * 0.7

	if dist > hit_start and dist < hit_end:
		var strength: float = clamp(1.0 - (dist / (wave_influence_radius * 0.8)), 0.0, 1.0)
		strength = pow(strength, 0.8)
		_wave_push_strength = strength
		_being_pushed = strength > 0.05

		# Push forward and slightly up — scaled down so it's dramatic but
		# doesn't send the player supersonic
		var push := Vector3(0.0, wave_push_up * strength * 0.65, wave_push_force * strength * 0.50)
		velocity += push * delta

		# Gentle turbulent sideways drift (no overpowering wobble)
		var wobble: float = sin(global_position.x * 0.35 + _wave_node.get_wave_z() * 0.06) * 3.5 * strength
		velocity.x += wobble * delta
	else:
		_being_pushed = false
		_wave_push_strength = 0.0
		if dist < hit_start:
			# Wave has passed — damp residual horizontal velocity
			velocity.x = move_toward(velocity.x, 0, 22.0 * delta)
			velocity.z = move_toward(velocity.z, 0, 22.0 * delta)
