class_name ShareHelper
## Small cross-platform sharing bridge used by social screens.

static func share_text(text: String) -> bool:
	if text.strip_edges().is_empty():
		return false
	if OS.get_name() == "Android":
		var intent := "intent:#Intent;action=android.intent.action.SEND;type=text/plain;S.android.intent.extra.TEXT=%s;end" % text.uri_encode()
		if OS.shell_open(intent) == OK:
			return true
		DisplayServer.clipboard_set(text)
		return false
	DisplayServer.clipboard_set(text)
	return true

static func copy_text(text: String) -> bool:
	if text.strip_edges().is_empty():
		return false
	DisplayServer.clipboard_set(text)
	return true
