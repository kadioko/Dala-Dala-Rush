extends Node
## Rewarded-ad service with a clean integration seam for AdMob.
##
## INTEGRATION (see docs/ADMOB_SETUP.md):
##   1. Install the poing-studios Godot AdMob plugin (or similar).
##   2. Set ADMOB_REWARDED_ID below to your real ad unit id.
##   3. Fill in the three _plugin_* methods where marked TODO.
##
## Until a plugin is present, SIMULATE_IN_DEBUG lets you test the
## full continue / double-coins flow inside the editor.

signal rewarded_result(placement: String, success: bool)

const PLACEMENT_CONTINUE := "continue_after_crash"
const PLACEMENT_DOUBLE_COINS := "double_coins"

## Google test rewarded id — replace with your real unit id before release.
const ADMOB_REWARDED_ID := "ca-app-pub-3940256099942544/5224354917"

## When true and running a debug build without an ad plugin,
## ads "succeed" after a short delay so flows can be tested.
const SIMULATE_IN_DEBUG := true

var _plugin: Object = null
var _ad_loaded: bool = false
var _pending_placement: String = ""

func _ready() -> void:
	if Engine.has_singleton("AdMob"):
		_plugin = Engine.get_singleton("AdMob")
		_plugin_init()

# ─── Public API ───────────────────────────────────────────────────

func is_rewarded_available(_placement: String = "") -> bool:
	if _plugin != null:
		return _ad_loaded
	return SIMULATE_IN_DEBUG and OS.is_debug_build()

## Async: result arrives via the rewarded_result signal.
func show_rewarded(placement: String) -> void:
	if _plugin != null and _ad_loaded:
		_pending_placement = placement
		_plugin_show()
		return
	if SIMULATE_IN_DEBUG and OS.is_debug_build():
		# Simulate a short ad so UI flows are testable in the editor.
		var t := get_tree().create_timer(0.4)
		t.timeout.connect(func(): rewarded_result.emit(placement, true))
		return
	rewarded_result.emit(placement, false)

# ─── Plugin seam (fill these in once the AdMob plugin is installed) ──

func _plugin_init() -> void:
	# TODO with poing-studios plugin:
	#   MobileAds.initialize()
	#   connect rewarded-loaded / earned-reward / dismissed signals,
	#   then call _plugin_load().
	pass

func _plugin_load() -> void:
	# TODO: RewardedAdLoader.load(ADMOB_REWARDED_ID, ...)
	# In the loaded callback set: _ad_loaded = true
	pass

func _plugin_show() -> void:
	# TODO: rewarded_ad.show()
	# On "earned reward":   rewarded_result.emit(_pending_placement, true)
	# On dismiss w/o reward: rewarded_result.emit(_pending_placement, false)
	# Then: _ad_loaded = false; _plugin_load()   # preload the next one
	pass
