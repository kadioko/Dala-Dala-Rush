extends RefCounted
## Constant-memory histogram. Percentiles are upper bounds at 1 ms resolution.

var buckets: PackedInt32Array = PackedInt32Array()
var frames: int = 0
var slow_frames: int = 0
var elapsed: float = 0.0
var worst_ms: float = 0.0
var budget_ms: float = 16.667

func _init(target_fps: int = 60) -> void:
	buckets.resize(501)
	buckets.fill(0)
	budget_ms = 1000.0 / maxi(1, target_fps)

func add_frame(seconds: float) -> void:
	if not is_finite(seconds) or seconds <= 0.0:
		return
	var ms: float = seconds * 1000.0
	buckets[clampi(ceili(ms), 0, 500)] += 1
	frames += 1
	elapsed += seconds
	worst_ms = maxf(worst_ms, ms)
	if ms > budget_ms * 1.5: slow_frames += 1

func percentile_ms(fraction: float) -> int:
	var target: int = maxi(1, ceili(frames * clampf(fraction, 0.0, 1.0)))
	var count: int = 0
	for i in range(buckets.size()):
		count += buckets[i]
		if count >= target: return i
	return 0

func report() -> Dictionary:
	return {"frames": frames, "active_seconds": elapsed,
		"average_fps": frames / elapsed if elapsed > 0.0 else 0.0,
		"p50_ms_upper": percentile_ms(0.5), "p95_ms_upper": percentile_ms(0.95),
		"p99_ms_upper": percentile_ms(0.99), "worst_ms": worst_ms,
		"over_1_5_budget_frames": slow_frames, "percentile_cap_ms": 500}
