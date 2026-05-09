extends Node
## Mobile feedback hub.
## Keeps vibration calls behind one saved setting so Android builds can stay polite.

var haptics_on: bool = true

func _ready() -> void:
	haptics_on = bool(SaveSystem.get_value("haptics_on", true))

func set_haptics_on(on: bool) -> void:
	haptics_on = on
	SaveSystem.set_value("haptics_on", on)

func tap() -> void:
	_vibrate(18)

func collect() -> void:
	_vibrate(28)

func powerup() -> void:
	_vibrate(45)

func crash() -> void:
	_vibrate(110)

func _vibrate(milliseconds: int) -> void:
	if not haptics_on:
		return
	if not (OS.has_feature("mobile") or OS.has_feature("android")):
		return
	Input.vibrate_handheld(milliseconds)
