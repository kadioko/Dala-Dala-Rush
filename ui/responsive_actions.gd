extends GridContainer

var minimum_column_width: float = 150.0
var maximum_columns: int = 2

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_READY:
		var gap: float = float(get_theme_constant("h_separation"))
		columns = clampi(floori((size.x + gap) / (minimum_column_width + gap)), 1, maximum_columns)
