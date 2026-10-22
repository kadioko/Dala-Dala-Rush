class_name CollisionMath

static func swept_intersects(previous_a: Rect2, current_a: Rect2,
		previous_b: Rect2, current_b: Rect2) -> bool:
	if current_a.intersects(current_b) or previous_a.intersects(previous_b):
		return true
	var start := previous_a.get_center()
	var relative_move := (current_a.get_center() - start) \
		- (current_b.get_center() - previous_b.get_center())
	var expanded := Rect2(previous_b.position - previous_a.size * 0.5,
		previous_b.size + previous_a.size)
	var entry := 0.0
	var exit_time := 1.0
	for axis in [0, 1]:
		if absf(relative_move[axis]) < 0.000001:
			if start[axis] <= expanded.position[axis] or start[axis] >= expanded.end[axis]:
				return false
			continue
		var first: float = (expanded.position[axis] - start[axis]) / relative_move[axis]
		var last: float = (expanded.end[axis] - start[axis]) / relative_move[axis]
		entry = maxf(entry, minf(first, last))
		exit_time = minf(exit_time, maxf(first, last))
		if entry >= exit_time:
			return false
	return entry < 1.0 and exit_time > 0.0
