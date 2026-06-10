extends Node3D

@onready var sim_manager: Node = $SimulationManager
@onready var tsunami: Node3D = $Tsunami
@onready var ui: Control = $UI
@onready var orbit_camera: Camera3D = $OrbitCamera
@onready var player: CharacterBody3D = $Player

# UI
var _btn_start: Button
var _btn_reset: Button
var _btn_toggle_cam: Button
var _lbl_status: Label
var _lbl_time: Label
var _progress_bar: ProgressBar

var _using_player_cam: bool = false

func _ready() -> void:
	sim_manager.setup(tsunami, ui)
	sim_manager.state_changed.connect(_on_state_changed)

	_btn_start     = ui.get_node("Panel/VBox/BtnStart")
	_btn_reset     = ui.get_node("Panel/VBox/BtnReset")
	_btn_toggle_cam = ui.get_node("Panel/VBox/BtnCam")
	_lbl_status    = ui.get_node("Panel/VBox/LblStatus")
	_lbl_time      = ui.get_node("Panel/VBox/LblTime")
	_progress_bar  = ui.get_node("Panel/VBox/WaveProgress")

	_btn_start.pressed.connect(_on_start_pressed)
	_btn_reset.pressed.connect(_on_reset_pressed)
	_btn_toggle_cam.pressed.connect(_toggle_camera)

	_set_orbit_mode()
	_update_ui()

func _process(_delta: float) -> void:
	if _lbl_time:
		_lbl_time.text = "Time: %.1fs" % sim_manager.get_elapsed_time()
	if _progress_bar:
		_progress_bar.value = sim_manager.get_wave_progress() * 100.0
	if _lbl_status:
		_lbl_status.text = sim_manager.get_state_label()

	if Input.is_action_just_pressed("ui_accept") and not _using_player_cam:
		_on_start_pressed()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R and not _using_player_cam:
			_on_reset_pressed()
		elif event.keycode == KEY_TAB:
			_toggle_camera()

func _on_start_pressed() -> void:
	sim_manager.start_simulation()
	_update_ui()

func _on_reset_pressed() -> void:
	sim_manager.reset_simulation()
	_update_ui()

func _toggle_camera() -> void:
	_using_player_cam = not _using_player_cam
	if _using_player_cam:
		_set_player_mode()
	else:
		_set_orbit_mode()

func _set_orbit_mode() -> void:
	_using_player_cam = false
	orbit_camera.current = true
	player.get_node("CameraArm/Camera3D").current = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if _btn_toggle_cam:
		_btn_toggle_cam.text = "👤 Walk Mode (Tab)"

func _set_player_mode() -> void:
	_using_player_cam = true
	orbit_camera.current = false
	player.get_node("CameraArm/Camera3D").current = true
	# Capture mouse so moving the mouse looks around without clicking buttons
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if _btn_toggle_cam:
		_btn_toggle_cam.text = "🎥 Orbit Mode (Tab)"

func _update_ui() -> void:
	if not _btn_start: return
	var is_idle: bool = (sim_manager.current_state == sim_manager.SimState.IDLE)
	_btn_start.disabled = not is_idle
	_btn_reset.disabled = is_idle

func _on_state_changed(_state: String) -> void:
	_update_ui()
