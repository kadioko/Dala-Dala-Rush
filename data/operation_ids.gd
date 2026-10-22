class_name OperationIds

static func create() -> String:
	var bytes: PackedByteArray = Crypto.new().generate_random_bytes(16)
	bytes[6] = (bytes[6] & 15) | 64
	bytes[8] = (bytes[8] & 63) | 128
	var hex := bytes.hex_encode()
	return "%s-%s-%s-%s-%s" % [hex.substr(0, 8), hex.substr(8, 4),
		hex.substr(12, 4), hex.substr(16, 4), hex.substr(20, 12)]

static func is_valid(value: Variant) -> bool:
	if value is not String:
		return false
	var expression := RegEx.new()
	expression.compile("^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$")
	return expression.search(String(value).to_lower()) != null
