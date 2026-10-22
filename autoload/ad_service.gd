extends Node
## Central ad service and policy layer.
##
## All SDK-specific code should stay in this file. Debug builds simulate ads
## when no plugin is installed, so the game flow can be tested in the editor.

signal rewarded_result(placement: String, success: bool)
signal interstitial_closed(placement: String)
signal rewarded_availability_changed(available: bool)
signal privacy_options_changed(required: bool)

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
var _rewarded_loading: bool = false
var _interstitial_loading: bool = false
var _sdk_initialized: bool = false
var _full_screen_active: bool = false
var _retry_timers: Dictionary = {}
var _retry_attempts: Dictionary = {}
var _banner_requested: bool = false
var _banner_placement: String = ""
var _consent_bridge: Object
var _consent_allowed: bool = false
var _privacy_required: bool = false
var _sdk_initializing: bool = false
var _consent_epoch: int = 0
var _banner_epoch: int = 0
var _fullscreen_serial: int = 0
var _fullscreen_kind: String = ""

func _ready() -> void:
	randomize()
	if Engine.has_singleton("PoingGodotAdMob"):
		_plugin = Engine.get_singleton("PoingGodotAdMob")
		if Engine.has_singleton("DalaConsent"):
			_consent_bridge = Engine.get_singleton("DalaConsent")
			_consent_bridge.connect("consent_updated", _on_consent_updated)
			_consent_bridge.call("requestConsent")
		else:
			push_warning("Consent bridge missing: native ads remain disabled.")

func _simulate() -> bool:
	return _plugin == null and OS.get_name() != "Android" and SIMULATE_IN_DEBUG and OS.is_debug_build()

func privacy_options_required() -> bool:
	return _privacy_required and _consent_bridge != null

func show_privacy_options() -> void:
	if not privacy_options_required() or _full_screen_active:
		return
	_clear_consent_ads()
	_consent_bridge.call("showPrivacyOptions")

func _clear_consent_ads() -> void:
	_consent_epoch += 1
	_consent_allowed = false
	_rewarded_loading = false
	_interstitial_loading = false
	_set_rewarded_available(false)
	_interstitial_loaded = false
	for kind in ["rewarded", "interstitial", "banner"]:
		_cancel_retry(kind)
	_plugin_hide_banner()
	for ad in [_rewarded_ad, _interstitial_ad]:
		if ad: ad.destroy()
	_rewarded_ad = null
	_interstitial_ad = null

func _on_consent_updated(allowed: bool, options_required: bool, _error_code: String) -> void:
	_privacy_required = options_required
	privacy_options_changed.emit(options_required)
	if not allowed:
		_clear_consent_ads()
		return
	_consent_allowed = true
	if not _sdk_initialized and not _sdk_initializing:
		_sdk_initializing = true
		_plugin_init()
	else:
		ensure_ads_loaded()
		if _banner_requested and _sdk_initialized:
			_plugin_show_banner(_banner_placement)

func is_rewarded_available(_placement: String = "") -> bool:
	if _plugin != null:
		return _consent_allowed and _rewarded_loaded and not _full_screen_active
	return _simulate()

func show_rewarded(placement: String) -> void:
	if _full_screen_active:
		rewarded_result.emit(placement, false)
		return
	AnalyticsService.log_event("ad_rewarded_requested", {
		"placement": placement,
		"sdk_ready": _plugin != null,
	})
	if _plugin != null and is_rewarded_available():
		_pending_placement = placement
		_plugin_show_rewarded()
		return
	if _simulate():
		var t := get_tree().create_timer(0.4)
		t.timeout.connect(func(): rewarded_result.emit(placement, true))
		return
	rewarded_result.emit(placement, false)

func is_interstitial_available(_placement: String = "") -> bool:
	if _plugin != null:
		return _consent_allowed and _interstitial_loaded and not _full_screen_active
	return _simulate()

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
	AnalyticsService.log_event("ad_interstitial_paced", {"runs_since": since, "target": target})

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
	if _full_screen_active:
		interstitial_closed.emit(placement)
		return
	AnalyticsService.log_event("ad_interstitial_requested", {
		"placement": placement,
		"sdk_ready": _plugin != null,
	})
	if _plugin != null and is_interstitial_available():
		_pending_placement = placement
		_plugin_show_interstitial()
		return
	if _simulate():
		var t := get_tree().create_timer(0.35)
		t.timeout.connect(func(): interstitial_closed.emit(placement))
		return
	interstitial_closed.emit(placement)

func show_banner(parent: Control, placement: String) -> void:
	if placement not in [PLACEMENT_BANNER_MENU, PLACEMENT_BANNER_RESULTS]:
		return
	hide_banner()
	_banner_requested = true
	_banner_placement = placement
	if _plugin != null:
		if _consent_allowed and _sdk_initialized:
			_plugin_show_banner(placement)
		return
	if not _simulate():
		return
	_banner = _build_debug_banner(placement)
	parent.add_child(_banner)

func hide_banner() -> void:
	_banner_requested = false
	_cancel_retry("banner")
	if _plugin != null:
		_plugin_hide_banner()
	if is_instance_valid(_banner):
		_banner.queue_free()
	_banner = null

func _plugin_init() -> void:
	_rewarded_content_callback = FullScreenContentCallbackApi.new()
	_reward_listener = OnUserEarnedRewardListenerApi.new()
	_interstitial_content_callback = FullScreenContentCallbackApi.new()

	_reward_listener.on_user_earned_reward = _on_user_earned_reward
	_rewarded_content_callback.on_ad_dismissed_full_screen_content = _on_rewarded_dismissed
	_rewarded_content_callback.on_ad_failed_to_show_full_screen_content = _on_rewarded_failed_to_show

	_interstitial_content_callback.on_ad_dismissed_full_screen_content = _on_interstitial_dismissed
	_interstitial_content_callback.on_ad_failed_to_show_full_screen_content = _on_interstitial_failed_to_show


	var init_listener: Variant = OnInitializationCompleteListenerApi.new()
	init_listener.on_initialization_complete = func(_status: Variant) -> void:
		_sdk_initialized = true
		_sdk_initializing = false
		_plugin_load_rewarded()
		_plugin_load_interstitial()
		if _banner_requested and _consent_allowed:
			_plugin_show_banner(_banner_placement)
	MobileAdsApi.initialize(init_listener)

func _plugin_load_rewarded() -> void:
	if not _consent_allowed or _rewarded_loading or _full_screen_active:
		return
	_cancel_retry("rewarded")
	_rewarded_loading = true
	if _rewarded_ad:
		_rewarded_ad.destroy()
		_rewarded_ad = null
	_set_rewarded_available(false)
	_rewarded_load_callback = _rewarded_callbacks(_consent_epoch)
	RewardedAdLoaderApi.new().load(ADMOB_REWARDED_ID, AdRequestApi.new(), _rewarded_load_callback)

func _rewarded_callbacks(epoch: int) -> Variant:
	var callback: Variant = RewardedAdLoadCallbackApi.new()
	callback.on_ad_loaded = func(ad: Variant) -> void:
		if epoch != _consent_epoch or not _consent_allowed:
			ad.destroy()
			return
		_on_rewarded_loaded(ad)
	callback.on_ad_failed_to_load = func(error: Variant) -> void:
		if epoch == _consent_epoch and _consent_allowed:
			_on_rewarded_failed_to_load(error)
	return callback

func _plugin_show_rewarded() -> void:
	if not _rewarded_ad:
		rewarded_result.emit(_pending_placement, false)
		_plugin_load_rewarded()
		return
	_rewarded_result_sent = false
	_rewarded_earned = false
	_set_rewarded_available(false)
	_full_screen_active = true
	_fullscreen_serial += 1
	_fullscreen_kind = "rewarded"
	var serial: int = _fullscreen_serial
	_reward_listener = OnUserEarnedRewardListenerApi.new()
	_reward_listener.on_user_earned_reward = func(item: Variant) -> void:
		if _owns_fullscreen(serial, "rewarded"): _on_user_earned_reward(item)
	var content: Variant = FullScreenContentCallbackApi.new()
	content.on_ad_dismissed_full_screen_content = func() -> void:
		if _owns_fullscreen(serial, "rewarded"): _on_rewarded_dismissed()
	content.on_ad_failed_to_show_full_screen_content = func(error: Variant) -> void:
		if _owns_fullscreen(serial, "rewarded"): _on_rewarded_failed_to_show(error)
	_rewarded_ad.full_screen_content_callback = content
	_rewarded_ad.show(_reward_listener)

func _owns_fullscreen(serial: int, kind: String) -> bool:
	return _full_screen_active and _fullscreen_serial == serial and _fullscreen_kind == kind

func _plugin_load_interstitial() -> void:
	if not _consent_allowed or _interstitial_loading or _full_screen_active:
		return
	_cancel_retry("interstitial")
	_interstitial_loading = true
	if _interstitial_ad:
		_interstitial_ad.destroy()
		_interstitial_ad = null
	_interstitial_loaded = false
	_interstitial_load_callback = _interstitial_callbacks(_consent_epoch)
	InterstitialAdLoaderApi.new().load(ADMOB_INTERSTITIAL_ID, AdRequestApi.new(), _interstitial_load_callback)

func _interstitial_callbacks(epoch: int) -> Variant:
	var callback: Variant = InterstitialAdLoadCallbackApi.new()
	callback.on_ad_loaded = func(ad: Variant) -> void:
		if epoch != _consent_epoch or not _consent_allowed:
			ad.destroy()
			return
		_on_interstitial_loaded(ad)
	callback.on_ad_failed_to_load = func(error: Variant) -> void:
		if epoch == _consent_epoch and _consent_allowed:
			_on_interstitial_failed_to_load(error)
	return callback

func _plugin_show_interstitial() -> void:
	if not _interstitial_ad:
		interstitial_closed.emit(_pending_placement)
		_plugin_load_interstitial()
		return
	_interstitial_loaded = false
	_full_screen_active = true
	_fullscreen_serial += 1
	_fullscreen_kind = "interstitial"
	var serial: int = _fullscreen_serial
	var content: Variant = FullScreenContentCallbackApi.new()
	content.on_ad_dismissed_full_screen_content = func() -> void:
		if _owns_fullscreen(serial, "interstitial"): _on_interstitial_dismissed()
	content.on_ad_failed_to_show_full_screen_content = func(error: Variant) -> void:
		if _owns_fullscreen(serial, "interstitial"): _on_interstitial_failed_to_show(error)
	_interstitial_ad.full_screen_content_callback = content
	_interstitial_ad.show()

func _plugin_show_banner(_placement: String) -> void:
	if not _consent_allowed:
		return
	_plugin_hide_banner()
	var epoch: int = _banner_epoch
	_banner_listener = AdListenerApi.new()
	_banner_listener.on_ad_loaded = func() -> void:
		if epoch == _banner_epoch:
			_on_banner_loaded()
	_banner_listener.on_ad_failed_to_load = func(error: Variant) -> void:
		if epoch == _banner_epoch:
			_on_banner_failed_to_load(error)
	var ad_size: Variant = AdSizeApi.get_current_orientation_anchored_adaptive_banner_ad_size(AdSizeApi.FULL_WIDTH)
	_ad_view = AdViewApi.new(ADMOB_BANNER_ID, ad_size, AdPositionApi.Values.BOTTOM)
	_ad_view.ad_listener = _banner_listener
	_ad_view.load_ad(AdRequestApi.new())

func _plugin_hide_banner() -> void:
	_banner_epoch += 1
	if _ad_view:
		_ad_view.destroy()
		_ad_view = null

func _on_rewarded_loaded(ad: Variant) -> void:
	_rewarded_loading = false
	if not _consent_allowed:
		ad.destroy()
		return
	_retry_attempts["rewarded"] = 0
	_cancel_retry("rewarded")
	_rewarded_ad = ad
	_rewarded_ad.full_screen_content_callback = _rewarded_content_callback
	_set_rewarded_available(true)
	AnalyticsService.log_event("ad_rewarded_loaded")

func _on_rewarded_failed_to_load(error: Variant) -> void:
	push_warning("Rewarded ad failed to load: " + _ad_error_message(error))
	_rewarded_loading = false
	_set_rewarded_available(false)
	_schedule_retry("rewarded")
	AnalyticsService.log_event("ad_rewarded_load_failed")

func _on_user_earned_reward(_item: Variant) -> void:
	if _rewarded_earned:
		return
	_rewarded_earned = true
	AnalyticsService.log_event("ad_rewarded_earned", {"placement": _pending_placement})

func _on_rewarded_dismissed() -> void:
	_full_screen_active = false
	_fullscreen_kind = ""
	if not _rewarded_result_sent:
		_rewarded_result_sent = true
		rewarded_result.emit(_pending_placement, _rewarded_earned)
	_plugin_load_rewarded()

func _on_rewarded_failed_to_show(error: Variant) -> void:
	_full_screen_active = false
	_fullscreen_kind = ""
	push_warning("Rewarded ad failed to show: " + _ad_error_message(error))
	if not _rewarded_result_sent:
		_rewarded_result_sent = true
		rewarded_result.emit(_pending_placement, false)
	_plugin_load_rewarded()

func _on_interstitial_loaded(ad: Variant) -> void:
	_interstitial_loading = false
	if not _consent_allowed:
		ad.destroy()
		return
	_retry_attempts["interstitial"] = 0
	_cancel_retry("interstitial")
	_interstitial_ad = ad
	_interstitial_ad.full_screen_content_callback = _interstitial_content_callback
	_interstitial_loaded = true
	AnalyticsService.log_event("ad_interstitial_loaded")

func _on_interstitial_failed_to_load(error: Variant) -> void:
	push_warning("Interstitial ad failed to load: " + _ad_error_message(error))
	_interstitial_loaded = false
	_interstitial_loading = false
	_schedule_retry("interstitial")
	AnalyticsService.log_event("ad_interstitial_load_failed")

func _on_interstitial_dismissed() -> void:
	_full_screen_active = false
	_fullscreen_kind = ""
	interstitial_closed.emit(_pending_placement)
	_plugin_load_interstitial()

func _on_interstitial_failed_to_show(error: Variant) -> void:
	_full_screen_active = false
	_fullscreen_kind = ""
	push_warning("Interstitial ad failed to show: " + _ad_error_message(error))
	interstitial_closed.emit(_pending_placement)
	_plugin_load_interstitial()

func _on_banner_loaded() -> void:
	if not _consent_allowed or not _banner_requested:
		_plugin_hide_banner()
		return
	_retry_attempts["banner"] = 0
	_cancel_retry("banner")
	if _ad_view:
		_ad_view.show()
	AnalyticsService.log_event("ad_banner_loaded")

func _on_banner_failed_to_load(error: Variant) -> void:
	_schedule_retry("banner")
	push_warning("Banner ad failed to load: " + _ad_error_message(error))
	AnalyticsService.log_event("ad_banner_load_failed")

func _set_rewarded_available(available: bool) -> void:
	if _rewarded_loaded == available:
		return
	_rewarded_loaded = available
	rewarded_availability_changed.emit(available)

static func retry_delay(attempt: int) -> float:
	return minf(60.0, 2.0 * pow(2.0, clampi(attempt, 0, 5)))

func _schedule_retry(kind: String) -> void:
	if _plugin == null or not _consent_allowed or not _sdk_initialized or _retry_timers.has(kind):
		return
	if kind == "banner" and not _banner_requested:
		return
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = retry_delay(int(_retry_attempts.get(kind, 0)))
	_retry_attempts[kind] = int(_retry_attempts.get(kind, 0)) + 1
	_retry_timers[kind] = timer
	add_child(timer)
	timer.timeout.connect(func():
		_retry_timers.erase(kind)
		timer.queue_free()
		if _full_screen_active:
			_schedule_retry(kind)
			return
		match kind:
			"rewarded": _plugin_load_rewarded()
			"interstitial": _plugin_load_interstitial()
			"banner":
				if _banner_requested:
					_plugin_show_banner(_banner_placement)
	)
	timer.start()

func _cancel_retry(kind: String) -> void:
	var timer: Timer = _retry_timers.get(kind) as Timer
	if is_instance_valid(timer):
		timer.stop()
		timer.queue_free()
	_retry_timers.erase(kind)

func ensure_ads_loaded() -> void:
	if _plugin == null or not _consent_allowed or not _sdk_initialized or _full_screen_active:
		return
	if not _rewarded_loaded and not _rewarded_loading:
		_plugin_load_rewarded()
	if not _interstitial_loaded and not _interstitial_loading:
		_plugin_load_interstitial()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED:
		ensure_ads_loaded()

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
