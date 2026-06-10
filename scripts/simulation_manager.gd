extends Node

signal state_changed(new_state: String)

enum SimState { IDLE, RUNNING, HIT, FINISHED }

var current_state: SimState = SimState.IDLE
var _tsunami_node: Node3D = null
var _ui_node: Control = null
var _start_time: float = 0.0
var _elapsed_time: float = 0.0

func _ready() -> void:
	pass

func setup(tsunami: Node3D, ui: Control) -> void:
	_tsunami_node = tsunami
	_ui_node = ui

	if _tsunami_node:
		_tsunami_node.wave_started.connect(_on_wave_started)
		_tsunami_node.wave_hit_city.connect(_on_wave_hit_city)
		_tsunami_node.simulation_reset.connect(_on_simulation_reset)

func _process(delta: float) -> void:
	if current_state == SimState.RUNNING or current_state == SimState.HIT:
		_elapsed_time += delta

func start_simulation() -> void:
	if current_state != SimState.IDLE:
		return
	_start_time = Time.get_ticks_msec() / 1000.0
	_elapsed_time = 0.0
	current_state = SimState.RUNNING
	if _tsunami_node:
		_tsunami_node.start()
	emit_signal("state_changed", "running")

func reset_simulation() -> void:
	current_state = SimState.IDLE
	_elapsed_time = 0.0
	if _tsunami_node:
		_tsunami_node.reset()
	emit_signal("state_changed", "idle")

func _on_wave_started() -> void:
	current_state = SimState.RUNNING

func _on_wave_hit_city() -> void:
	current_state = SimState.HIT
	emit_signal("state_changed", "hit")

func _on_simulation_reset() -> void:
	current_state = SimState.IDLE
	_elapsed_time = 0.0

func get_elapsed_time() -> float:
	return _elapsed_time

func get_state_label() -> String:
	match current_state:
		SimState.IDLE: return "Ready"
		SimState.RUNNING: return "Wave approaching..."
		SimState.HIT: return "IMPACT!"
		SimState.FINISHED: return "Finished"
	return "Unknown"

func get_wave_progress() -> float:
	if _tsunami_node:
		return _tsunami_node.get_wave_progress()
	return 0.0
