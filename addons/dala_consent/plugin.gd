@tool
extends EditorPlugin

class ConsentExporter extends EditorExportPlugin:
	func _get_name() -> String:
		return "DalaConsent"
	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid
	func _get_android_libraries(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray(["res://addons/dala_consent/libs/dala-consent-release.aar"])
	func _get_android_dependencies(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray(["com.google.android.ump:user-messaging-platform:4.0.0"])

var _exporter := ConsentExporter.new()
func _enter_tree() -> void:
	add_export_plugin(_exporter)
func _exit_tree() -> void:
	remove_export_plugin(_exporter)
