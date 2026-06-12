class_name SpriteLib
## Optional sprite loading with vector-draw fallback.
##
## Drop PNGs into res://sprites/ named after entity ids and they are used
## automatically; anything missing keeps the built-in vector art.
## See docs/SPRITES.md for the full list and recommended sizes.
##
##   sprites/vehicle_<vehicle_id>.png   e.g. vehicle_classic_blue.png
##   sprites/obstacle_<type_id>.png     e.g. obstacle_mbuzi.png
##   sprites/collectible_<type_id>.png  e.g. collectible_coin.png

static var _cache: Dictionary = {}

static func get_tex(kind: String, id: String) -> Texture2D:
	var key := "%s_%s" % [kind, id]
	if _cache.has(key):
		return _cache[key]
	var tex: Texture2D = null
	var path := "res://sprites/%s.png" % key
	if ResourceLoader.exists(path):
		var res := load(path)
		if res is Texture2D:
			tex = res
	_cache[key] = tex
	return tex
