extends Camera3D

# Orbit camera controller - click drag to rotate, scroll to zoom
@export var orbit_speed: float = 0.3
@export var zoom_speed: float = 5.0
@export var min_zoom: float = 10.0
@export var max_zoom: float = 200.0
@export var pan_speed: float = 0.15

var _dragging: bool = false
var _right_dragging: bool = false
var _last_mouse: Vector2 = Vector2.ZERO
var _pivot: Vector3 = Vector3.ZERO
var _yaw: float = -30.0
var _pitch: float = 45.0
var _distance: float = 80.0

func _ready() -> void:
	_apply_orbit()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_dragging = event.pressed
			_last_mouse = event.position
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_right_dragging = event.pressed
			_last_mouse = event.position
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_distance = clamp(_distance - zoom_speed * 2.0, min_zoom, max_zoom)
			_apply_orbit()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_distance = clamp(_distance + zoom_speed * 2.0, min_zoom, max_zoom)
			_apply_orbit()

	elif event is InputEventMouseMotion:
		if _dragging:
			_yaw -= event.relative.x * orbit_speed
			_pitch = clamp(_pitch - event.relative.y * orbit_speed, 5.0, 85.0)
			_apply_orbit()
		elif _right_dragging:
			var right = global_transform.basis.x
			var up_flat = Vector3(0, 1, 0)
			_pivot -= right * event.relative.x * pan_speed
			_pivot -= up_flat * event.relative.y * pan_speed * -1
			_apply_orbit()

func _apply_orbit() -> void:
	var yaw_rad = deg_to_rad(_yaw)
	var pitch_rad = deg_to_rad(_pitch)
	var offset = Vector3(
		cos(pitch_rad) * sin(yaw_rad),
		sin(pitch_rad),
		cos(pitch_rad) * cos(yaw_rad)
	) * _distance
	global_position = _pivot + offset
	look_at(_pivot, Vector3.UP)
