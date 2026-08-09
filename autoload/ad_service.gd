extends Node
## Central ad service and policy layer.
##
## All SDK-specific code should stay in this file. Debug builds simulate ads
## when no plugin is installed, so the game flow can be tested in the editor.

signal rewarded_result(placement: String, success: bool)
signal interstitial_closed(placement: String)

const PLACEMENT_CONTINUE := "continue_after_crash"
const PLACEMENT_DOUBLE_COINS := "double_coins"
const PLACEMENT_INTERSTITIAL_RUN_END := "run_end_interstitial"
const PLACEMENT_BANNER_MENU := "menu_banner"
const PLACEMENT_BANNER_RESULTS := "results_banner"

const ADMOB_REWARDED_ID := "ca-app-pub-1484098434630929/1092598111"
const ADMOB_INTERSTITIAL_ID := "ca-app-pub-1484098434630929/3323134078"
const ADMOB_BANNER_ID := "ca-app-pub-1484098434630929/2952474694"

const SIMULATE_IN_DEBUG := true
const INTERSTITIAL_MIN_RUNS := 2
const INTERSTITIAL_MAX_RUNS := 3
const MobileAdsApi := preload("res://addons/admob/gdscript/src/api/MobileAds.gd")
const RewardedAdLoaderApi := preload("res://addons/admob/gdscript/src/api/RewardedAdLoader.gd")
const InterstitialAdLoaderApi := preload("res://addons/admob/gdscript/src/api/InterstitialAdLoader.gd")
const AdViewApi := preload("res://addons/admob/gdscript/src/api/AdView.gd")
const AdRequestApi := preload("res://addons/admob/gdscript/src/api/core/AdRequest.gd")
const AdSizeApi := preload("res://addons/admob/gdscript/src/api/core/AdSize.gd")
const AdPositionApi := preload("res://addons/admob/gdscript/src/api/core/AdPosition.gd")
const RewardedAdLoadCallbackApi := preload("res://addons/admob/gdscript/src/api/listeners/RewardedAdLoadCallback.gd")
const FullScreenContentCallbackApi := preload("res://addons/admob/gdscript/src/api/listeners/FullScreenContentCallback.gd")
const OnUserEarnedRewardListenerApi := preload("res://addons/admob/gdscript/src/api/listeners/OnUserEarnedRewardListener.gd")
const InterstitialAdLoadCallbackApi := preload("res://addons/admob/gdscript/src/api/listeners/InterstitialAdLoadCallback.gd")
const AdListenerApi := preload("res://addons/admob/gdscript/src/api/listeners/AdListener.gd")
const OnInitializationCompleteListenerApi := preload("res://addons/admob/gdscript/src/api/listeners/OnInitializationCompleteListener.gd")

var _plugin: Object = null
var _rewarded_loaded: bool = false
var _interstitial_loaded: bool = false
var _pending_placement: String = ""
var _banner: Control = null
var _rewarded_ad: Variant = null
var _interstitial_ad: Variant = null
var _ad_view: Variant = null
var _rewarded_load_callback: Variant = null
var _rewarded_content_callback: Variant = null
var _reward_listener: Variant = null
var _interstitial_load_callback: Variant = null
var _interstitial_content_callback: Variant = null
var _banner_listener: Variant = null
var _rewarded_result_sent: bool = false
var _rewarded_earned: bool = false

func _ready() -> void:
	randomize()
	if Engine.has_singleton("PoingGodotAdMob"):
		_plugin = Engine.get_singleton("PoingGodotAdMob")
		_plugin_init()

func is_rewarded_available(_placement: String = "") -> bool:
	if _plugin != null:
		return _rewarded_loaded
	return SIMULATE_IN_DEBUG and OS.is_debug_build()

func show_rewarded(placement: String) -> void:
	if _plugin != null and _rewarded_loaded:
		_pending_placement = placement
		_plugin_show_rewarded()
		return
	if SIMULATE_IN_DEBUG and OS.is_debug_build():
		var t := get_tree().create_timer(0.4)
		t.timeout.connect(func(): rewarded_result.emit(placement, true))
		return
	rewarded_result.emit(placement, false)

func is_interstitial_available(_placement: String = "") -> bool:
	if _plugin != null:
		return _interstitial_loaded
	return SIMULATE_IN_DEBUG and OS.is_debug_build()

func note_completed_run() -> void:
	if bool(SaveSystem.get_value("ads_pending_interstitial", false)):
		return
	var since: int = int(SaveSystem.get_value("ads_runs_since_interstitial", 0)) + 1
	var target: int = int(SaveSystem.get_value("ads_next_interstitial_at", INTERSTITIAL_MIN_RUNS))
	SaveSystem.begin_batch()
	SaveSystem.set_value("ads_runs_since_interstitial", since)
	if since >= target:
		SaveSystem.set_value("ads_pending_interstitial", true)
	SaveSystem.end_batch()

func consume_pending_interstitial() -> bool:
	if not bool(SaveSystem.get_value("ads_pending_interstitial", false)):
		return false
	SaveSystem.begin_batch()
	SaveSystem.set_value("ads_pending_interstitial", false)
	SaveSystem.set_value("ads_runs_since_interstitial", 0)
	SaveSystem.set_value("ads_next_interstitial_at", randi_range(INTERSTITIAL_MIN_RUNS, INTERSTITIAL_MAX_RUNS))
	SaveSystem.end_batch()
	return true

func show_interstitial(placement: String) -> void:
	if _plugin != null and _interstitial_loaded:
		_pending_placement = placement
		_plugin_show_interstitial()
		return
	if SIMULATE_IN_DEBUG and OS.is_debug_build():
		var t := get_tree().create_timer(0.35)
		t.timeout.connect(func(): interstitial_closed.emit(placement))
		return
	interstitial_closed.emit(placement)

func show_banner(parent: Control, placement: String) -> void:
	if placement not in [PLACEMENT_BANNER_MENU, PLACEMENT_BANNER_RESULTS]:
		return
	hide_banner()
	if _plugin != null:
		_plugin_show_banner(placement)
		return
	if not SIMULATE_IN_DEBUG or not OS.is_debug_build():
		return
	_banner = _build_debug_banner(placement)
	parent.add_child(_banner)

func hide_banner() -> void:
	if _plugin != null:
		_plugin_hide_banner()
	if is_instance_valid(_banner):
		_banner.queue_free()
	_banner = null

func _plugin_init() -> void:
	_rewarded_load_callback = RewardedAdLoadCallbackApi.new()
	_rewarded_content_callback = FullScreenContentCallbackApi.new()
	_reward_listener = OnUserEarnedRewardListenerApi.new()
	_interstitial_load_callback = InterstitialAdLoadCallbackApi.new()
	_interstitial_content_callback = FullScreenContentCallbackApi.new()
	_banner_listener = AdListenerApi.new()

	_rewarded_load_callback.on_ad_loaded = _on_rewarded_loaded
	_rewarded_load_callback.on_ad_failed_to_load = _on_rewarded_failed_to_load
	_reward_listener.on_user_earned_reward = _on_user_earned_reward
	_rewarded_content_callback.on_ad_dismissed_full_screen_content = _on_rewarded_dismissed
	_rewarded_content_callback.on_ad_failed_to_show_full_screen_content = _on_rewarded_failed_to_show

	_interstitial_load_callback.on_ad_loaded = _on_interstitial_loaded
	_interstitial_load_callback.on_ad_failed_to_load = _on_interstitial_failed_to_load
	_interstitial_content_callback.on_ad_dismissed_full_screen_content = _on_interstitial_dismissed
	_interstitial_content_callback.on_ad_failed_to_show_full_screen_content = _on_interstitial_failed_to_show

	_banner_listener.on_ad_failed_to_load = _on_banner_failed_to_load
	_banner_listener.on_ad_loaded = _on_banner_loaded

	var init_listener: Variant = OnInitializationCompleteListenerApi.new()
	init_listener.on_initialization_complete = func(_status: Variant) -> void:
		_plugin_load_rewarded()
		_plugin_load_interstitial()
	MobileAdsApi.initialize(init_listener)

func _plugin_load_rewarded() -> void:
	if _rewarded_ad:
		_rewarded_ad.destroy()
		_rewarded_ad = null
	_rewarded_loaded = false
	RewardedAdLoaderApi.new().load(ADMOB_REWARDED_ID, AdRequestApi.new(), _rewarded_load_callback)

func _plugin_show_rewarded() -> void:
	if not _rewarded_ad:
		rewarded_result.emit(_pending_placement, false)
		_plugin_load_rewarded()
		return
	_rewarded_result_sent = false
	_rewarded_earned = false
	_rewarded_loaded = false
	_rewarded_ad.show(_reward_listener)

func _plugin_load_interstitial() -> void:
	if _interstitial_ad:
		_interstitial_ad.destroy()
		_interstitial_ad = null
	_interstitial_loaded = false
	InterstitialAdLoaderApi.new().load(ADMOB_INTERSTITIAL_ID, AdRequestApi.new(), _interstitial_load_callback)

func _plugin_show_interstitial() -> void:
	if not _interstitial_ad:
		interstitial_closed.emit(_pending_placement)
		_plugin_load_interstitial()
		return
	_interstitial_loaded = false
	_interstitial_ad.show()

func _plugin_show_banner(_placement: String) -> void:
	if _ad_view:
		_ad_view.destroy()
		_ad_view = null
	var ad_size: Variant = AdSizeApi.get_current_orientation_anchored_adaptive_banner_ad_size(AdSizeApi.FULL_WIDTH)
	_ad_view = AdViewApi.new(ADMOB_BANNER_ID, ad_size, AdPositionApi.Values.BOTTOM)
	_ad_view.ad_listener = _banner_listener
	_ad_view.load_ad(AdRequestApi.new())

func _plugin_hide_banner() -> void:
	if _ad_view:
		_ad_view.destroy()
		_ad_view = null

func _on_rewarded_loaded(ad: Variant) -> void:
	_rewarded_ad = ad
	_rewarded_ad.full_screen_content_callback = _rewarded_content_callback
	_rewarded_loaded = true

func _on_rewarded_failed_to_load(error: Variant) -> void:
	push_warning("Rewarded ad failed to load: " + _ad_error_message(error))
	_rewarded_loaded = false

func _on_user_earned_reward(_item: Variant) -> void:
	_rewarded_earned = true
	if not _rewarded_result_sent:
		_rewarded_result_sent = true
		rewarded_result.emit(_pending_placement, true)

func _on_rewarded_dismissed() -> void:
	if not _rewarded_result_sent:
		_rewarded_result_sent = true
		rewarded_result.emit(_pending_placement, _rewarded_earned)
	_plugin_load_rewarded()

func _on_rewarded_failed_to_show(error: Variant) -> void:
	push_warning("Rewarded ad failed to show: " + _ad_error_message(error))
	if not _rewarded_result_sent:
		_rewarded_result_sent = true
		rewarded_result.emit(_pending_placement, false)
	_plugin_load_rewarded()

func _on_interstitial_loaded(ad: Variant) -> void:
	_interstitial_ad = ad
	_interstitial_ad.full_screen_content_callback = _interstitial_content_callback
	_interstitial_loaded = true

func _on_interstitial_failed_to_load(error: Variant) -> void:
	push_warning("Interstitial ad failed to load: " + _ad_error_message(error))
	_interstitial_loaded = false

func _on_interstitial_dismissed() -> void:
	interstitial_closed.emit(_pending_placement)
	_plugin_load_interstitial()

func _on_interstitial_failed_to_show(error: Variant) -> void:
	push_warning("Interstitial ad failed to show: " + _ad_error_message(error))
	interstitial_closed.emit(_pending_placement)
	_plugin_load_interstitial()

func _on_banner_loaded() -> void:
	if _ad_view:
		_ad_view.show()

func _on_banner_failed_to_load(error: Variant) -> void:
	push_warning("Banner ad failed to load: " + _ad_error_message(error))

func _ad_error_message(error: Variant) -> String:
	if error is Object:
		var message: Variant = error.get("message")
		if message != null:
			return str(message)
	return str(error)

func _build_debug_banner(placement: String) -> Control:
	var box := PanelContainer.new()
	box.name = "DebugAdBanner"
	box.anchor_left = 0.0
	box.anchor_right = 1.0
	box.anchor_top = 1.0
	box.anchor_bottom = 1.0
	box.offset_left = 16
	box.offset_right = -16
	box.offset_top = -58
	box.offset_bottom = -12
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.05, 0.07, 0.86)
	sb.border_color = Color("#ffd23f")
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	box.add_theme_stylebox_override("panel", sb)

	var lbl := Label.new()
	lbl.text = "%s - %s" % [LocaleManager.t("AD_BANNER_LABEL"), placement]
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", Color("#f5f5f5"))
	lbl.add_theme_font_size_override("font_size", 14)
	box.add_child(lbl)
	return box
