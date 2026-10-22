extends Node
## Explicit debug-only capture. No player IDs, uploads, or per-frame allocations.

signal capture_finished(path: String, error: Error)
const FramePacing := preload("res://data/frame_pacing.gd")
const REPORT_PATH := "user://performance_last.json"
var active: bool = false
var _remaining: float = 0.0
var _focused: bool = true
var _skip_frame: bool = true
var _histogram: RefCounted
var _peak_static_bytes: int = 0
var _peak_nodes: int = 0
var _sample_clock: float = 0.0
var _initial_fps: int = 60
var _mixed_cap: bool = false
var _started_unix: int = 0

func _ready() -> void:
	set_process(false)

func start_capture(seconds: float = 300.0) -> void:
	if not OS.is_debug_build() or active: return
	_initial_fps = 30 if bool(SaveSystem.get_value("battery_saver", false)) else 60
	_started_unix = int(Time.get_unix_time_from_system())
	_histogram = FramePacing.new(_initial_fps)
	_remaining = clampf(seconds, 10.0, 1800.0)
	_peak_static_bytes = 0
	_peak_nodes = 0
	_sample_clock = 0.0
	_mixed_cap = false
	_skip_frame = true
	active = true
	set_process(true)

func _process(delta: float) -> void:
	if not _focused: return
	if _skip_frame:
		_skip_frame = false
		return
	_histogram.add_frame(delta)
	_remaining -= delta
	_sample_clock += delta
	_mixed_cap = _mixed_cap or Engine.max_fps != _initial_fps
	if _sample_clock >= 1.0:
		_sample_clock = 0.0
		_peak_static_bytes = maxi(_peak_static_bytes, OS.get_static_memory_usage())
		_peak_nodes = maxi(_peak_nodes, get_tree().get_node_count())
	if _remaining <= 0.0: stop_capture()

func stop_capture() -> void:
	if not active: return
	active = false
	set_process(false)
	var report: Dictionary = _histogram.report()
	report.merge({"format": 1, "engine": Engine.get_version_info().string,
		"started_at_unix": _started_unix, "finished_at_unix": int(Time.get_unix_time_from_system()),
		"platform": OS.get_name(), "render_driver": RenderingServer.get_current_rendering_method(),
		"target_fps": _initial_fps, "mixed_frame_caps": _mixed_cap,
		"peak_static_bytes": _peak_static_bytes, "peak_nodes": _peak_nodes,
		"scope": "debug engine process frames; not GPU presentation or battery measurement"})
	var error: Error = AtomicJson.write(REPORT_PATH, report)
	capture_finished.emit(REPORT_PATH, error)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_focused = false
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_focused = true
		_skip_frame = true
