class_name AtomicJson
## The last good primary remains intact until the complete replacement exists.

static func write(path: String, value: Variant, backup_path: String = "") -> Error:
	var temporary := path + ".tmp"
	var encoded := JSON.stringify(value)
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(encoded)
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	if write_error != OK:
		return write_error
	var verified := FileAccess.open(temporary, FileAccess.READ)
	if verified == null:
		return FileAccess.get_open_error()
	var complete: bool = verified.get_as_text() == encoded
	verified.close()
	if not complete:
		return ERR_FILE_CORRUPT
	if not backup_path.is_empty() and FileAccess.file_exists(path):
		if not DirAccess.dir_exists_absolute(backup_path.get_base_dir()):
			return ERR_CANT_CREATE
		var old := FileAccess.open(path, FileAccess.READ)
		if old == null:
			return FileAccess.get_open_error()
		var previous: Variant = JSON.parse_string(old.get_as_text())
		old.close()
		if typeof(previous) == typeof(value):
			var copied: Error = DirAccess.copy_absolute(path, backup_path + ".tmp")
			if copied != OK:
				return copied
			var rotated: Error = DirAccess.rename_absolute(backup_path + ".tmp", backup_path)
			if rotated != OK:
				return rotated
	return DirAccess.rename_absolute(temporary, path)
