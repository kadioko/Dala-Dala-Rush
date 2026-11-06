extends Node

const Hub := preload("res://scripts/world_hub.gd")

var _failures: Array[String] = []
var _saved_profile: Dictionary
var _saved_depth: int
var _saved_dirty: bool
var _saved_events: Array

func _ready() -> void:
	_saved_profile = SaveSystem.data.duplicate(true)
	_saved_depth = SaveSystem._batch_depth
	_saved_dirty = SaveSystem._batch_dirty
	_saved_events = AnalyticsService._queue.duplicate(true)
	SaveSystem.data = SaveSystem.DEFAULTS.duplicate(true)
	SaveSystem._batch_depth += 1
	call_deferred("_run")

func _run() -> void:
	var hub := Hub.new()
	add_child(hub)
	await get_tree().process_frame
	_check(Hub.DISTRICTS.size() == 6 and Hub.DECOR.size() == 25 and Hub.PROPERTIES.size() == 9,
		"The open-world map should include six districts, local goods, wearables and buildable plots")
	_check(hub.call("_district_at", Vector2(810, 480)) == "mwenge"
		and hub.call("_district_at", Vector2(270, 1440)) == "posta"
		and hub.call("_district_at", Vector2(1350, 1440)) == "ubungo"
		and hub.call("_district_at", Vector2(1350, 480)) == "mbezi"
		and hub.call("_district_at", Vector2(810, 1440)) == "kigamboni"
		and hub.call("_district_at", Vector2(270, 480)) == "kariakoo",
		"District lookup should follow the six-tile world layout")
	for district_id in ["mwenge", "mbezi", "posta", "kigamboni", "ubungo"]:
		_check(not (hub.call("_spot", district_id + "_market") as Dictionary).is_empty()
			and not (hub.call("_spot", district_id + "_properties") as Dictionary).is_empty(),
			"District %s should have its own market and plot office" % district_id)
	for job_id in ["mwenge_boda_delivery", "mbezi_fuel_run", "posta_courier", "kigamboni_parcel", "ubungo_manifest"]:
		var job: Dictionary = hub.call("_job", job_id)
		_check(not job.is_empty() and not (hub.call("_spot", String(job.start)) as Dictionary).is_empty()
			and not (hub.call("_spot", String(job.finish)) as Dictionary).is_empty(),
			"District activity %s must have reachable pickup and delivery landmarks" % job_id)
	_check(String(hub.call("_district_for_job_spot", "stop")) == "kariakoo",
		"Kariakoo's passenger stop should offer its own route activity")
	hub.call("_update_nearby")
	_check(hub.get("_nearby_id") == "stop", "New visitor should arrive beside the passenger stop")
	hub.call("_start_errand")
	_check(String(hub.call("_next_errand_stop")) == "market",
		"The first guided errand should reveal the market as its next stop")
	_check(String(LocaleManager.strings.en.HUB_GUIDE_FIRST).contains("action button")
		and String(LocaleManager.strings.sw.HUB_GUIDE_FIRST).contains("kitufe cha kitendo"),
		"First-visit directions should explain the nearby action control in both languages")
	_check(String(LocaleManager.strings.en.HUB_PHONE_LOCKED).contains("optional")
		and String(LocaleManager.strings.sw.HUB_PHONE_LOCKED).contains("hiari"),
		"Phone copy must state that it is optional, not required for navigation")
	for stop in ["market", "garage", "plaza"]:
		var spot: Dictionary = hub.call("_spot", stop)
		var point: Vector2 = spot.get("position", Vector2.ZERO)
		hub.set("_player_position", point)
		hub.call("_update_nearby")
		if stop == "market":
			_check((hub.get("_errand_progress") as Array).is_empty(), "Walking near a stop must not complete it without a tap")
		hub.call("_check_in_errand", stop)
	var after_errand := int(SaveSystem.get_value("total_coins", 0))
	_check(after_errand == Hub.ERRAND_REWARD, "Completing the three neighborhood stops must pay once")
	_check(String(SaveSystem.get_value("hub_daily_completed_date", "")) == Time.get_date_string_from_system(),
		"Completed neighborhood errand should persist today's date")
	hub.set("_player_position", Vector2(270, 738))
	hub.call("_start_errand")
	_check(int(SaveSystem.get_value("total_coins", 0)) == after_errand,
		"A second same-day errand must not pay twice")
	SaveSystem.set_value("total_coins", 400)
	hub.call("_buy_decor", "kanga_flag", 90)
	_check(int(SaveSystem.get_value("total_coins", 0)) == 310,
		"Buying one plaza decoration should atomically debit its price")
	_check("kanga_flag" in SaveSystem.get_value("hub_owned_decor", []),
		"Purchased decoration should be owned")
	hub.call("_buy_decor", "kanga_flag", 90)
	_check(int(SaveSystem.get_value("total_coins", 0)) == 310,
		"Purchasing an owned decoration again must not debit coins")
	SaveSystem.set_value("total_coins", 2000)
	hub.call("_buy_property", "kiosk", 350)
	_check(int(SaveSystem.get_value("hub_properties", {}).get("kiosk", 0)) == 1,
		"Buying a plot should persist its first build level")
	_check(int(SaveSystem.get_value("total_coins", 0)) == 1650,
		"Buying a plot should debit the listed price once")
	hub.call("_buy_property", "kiosk", 250)
	_check(int(SaveSystem.get_value("hub_properties", {}).get("kiosk", 0)) == 2,
		"Owned property should support a saved upgrade")
	_check(int(hub.call("_shop_discount", "kariakoo")) == 10,
		"Kiosk level two should provide its disclosed local shop discount")
	hub.call("_record_district_visit", "mwenge")
	_check("mwenge" in SaveSystem.get_value("hub_passport_visited", [])
		and "mwenge" in SaveSystem.get_value("hub_album_found", [])
		and "2" in SaveSystem.get_value("hub_passport_claimed", []),
		"Second district visit should save passport and album progress with a one-time milestone")
	SaveSystem.set_value("total_coins", 5000)
	hub.call("_buy_property", "home", 600)
	hub.call("_commit_placement", "kanga_flag", "home", 0, 0, false)
	_check("kanga_flag" in SaveSystem.get_value("hub_owned_decor", [])
		and String(SaveSystem.get_value("hub_decor_placements", {}).get("home", [""])[0]) == "kanga_flag",
		"Buying and placing decor should save ownership and its plot slot together")
	_check(String(hub.call("_placement_location_text", "kanga_flag")).contains("1"),
		"Owned-items detail should identify a placed item by plot and slot")
	hub.call("_commit_placement", "kanga_flag", "home", 0, 90, true)
	_check(int(SaveSystem.get_value("total_coins", 0)) == 5000 - 600,
		"A duplicate placement purchase must not charge or duplicate ownership")
	hub.call("_buy_property", "guest_house", 1100)
	_check(int(hub.call("_daily_rent")) == 20,
		"Owned homes should produce bounded NPC rent")
	var before_rent := int(SaveSystem.get_value("total_coins", 0))
	hub.call("_collect_rent")
	_check(int(SaveSystem.get_value("total_coins", 0)) == before_rent + 20,
		"Rent collection should pay the displayed amount once")
	hub.call("_collect_rent")
	_check(int(SaveSystem.get_value("total_coins", 0)) == before_rent + 20,
		"Rent must not be claimed twice on the same day")
	hub.call("_buy_property", "mwenge_home", 1000)
	_check(int(SaveSystem.get_value("hub_properties", {}).get("mwenge_home", 0)) == 1,
		"District plot purchases should persist independently")
	hub.call("_buy_decor", "mwenge_reflectors", 190, "mwenge")
	_check("mwenge_reflectors" in SaveSystem.get_value("hub_owned_decor", []),
		"District-market cosmetics should use the shared owned-decor save")
	var perk_properties: Dictionary = hub.get("_properties").duplicate(true)
	perk_properties["mbezi_yard"] = 2
	hub.set("_properties", perk_properties)
	_check(int(hub.call("_shop_discount", "mbezi")) == 10,
		"Mbezi Yard level two should grant the disclosed local discount")
	SaveSystem.set_value("total_coins", 5000)
	hub.call("_buy_decor", "konda_cap", 160, "kariakoo")
	_check(String(SaveSystem.get_value("hub_avatar_item", "")) == "konda_cap"
		and "konda_cap" in SaveSystem.get_value("hub_owned_decor", []),
		"Buying a wearable should save ownership and equip it together")
	perk_properties = hub.get("_properties").duplicate(true)
	perk_properties["posta_flat"] = 2
	hub.set("_properties", perk_properties)
	hub.call("_buy_decor", "posta_relay_stand", 360, "posta")
	_check("posta_relay_stand" in SaveSystem.get_value("hub_owned_decor", []),
		"Posta Flat level two should unlock its additional shop item")
	perk_properties.erase("posta_flat")
	hub.set("_properties", perk_properties)
	_check(int(hub.call("_daily_rent")) == 28,
		"New district rentals should join the existing capped rent wallet")
	hub.call("_travel_to_district", "mwenge")
	_check(String(hub.get("_current_district_id")) == "mwenge"
		and hub.call("_district_at", hub.get("_player_position")) == "mwenge",
		"District map travel should move the player and camera target into Mwenge")
	hub.call("_travel_to_district", "kariakoo")
	hub.call("_start_job", "passenger_escort")
	hub.call("_interact_with_job", "stop")
	_check(int(hub.get("_active_job_step")) == 1, "Job pickup should require explicit check-in")
	hub.call("_interact_with_job", "plaza")
	_check(int(SaveSystem.get_value("hub_jobs_claimed_count", 0)) == 1,
		"Completing a job should consume one of today's paid-job claims")
	var after_job := int(SaveSystem.get_value("total_coins", 0))
	hub.call("_interact_with_job", "plaza")
	_check(int(SaveSystem.get_value("total_coins", 0)) == after_job,
		"A completed job cannot pay twice")
	hub.call("_start_job", "market_delivery")
	hub.call("_interact_with_job", "market")
	hub.call("_interact_with_job", "stop")
	_check(int(SaveSystem.get_value("hub_jobs_claimed_count", 0)) == 2,
		"Second paid job should reach the daily cap")
	hub.call("_start_job", "passenger_escort")
	_check(String(hub.get("_active_job_id")).is_empty(), "Paid neighborhood jobs should stop after the daily cap")
	hub.set("_properties", {"workshop": 2})
	SaveSystem.set_value("hub_jobs_claimed_count", 0)
	hub.set("_jobs_claimed_today", 0)
	var parts_wallet := int(SaveSystem.get_value("total_coins", 0))
	hub.call("_start_job", "parts_run")
	hub.call("_interact_with_job", "garage")
	hub.call("_interact_with_job", "route_board")
	_check(int(SaveSystem.get_value("total_coins", 0)) == parts_wallet + 18,
		"Workshop level two should add its modest bonus to the parts-run payout")
	SaveSystem.set_value("hub_jobs_claimed_count", 2)
	hub.set("_jobs_claimed_today", 2)
	var coins_before_route := int(SaveSystem.get_value("total_coins", 0))
	SaveSystem.set_value("hub_route_activity", {"district": "mwenge", "route": "mwenge", "status": "success_pending", "reward": 999})
	hub.call("_settle_route_activity")
	_check(int(SaveSystem.get_value("total_coins", 0)) == coins_before_route,
		"A full daily job cap should defer, not lose or pay, the route reward")
	hub.set("_jobs_claimed_today", 1)
	SaveSystem.set_value("hub_jobs_claimed_count", 1)
	hub.call("_settle_route_activity")
	_check(int(SaveSystem.get_value("total_coins", 0)) == coins_before_route + 25
		and int(SaveSystem.get_value("hub_jobs_claimed_count", 0)) == 2,
		"Successful district route jobs should pay once and consume the available daily slot")
	_check((SaveSystem.get_value("hub_route_activity", {}) as Dictionary).is_empty(),
		"A paid route activity should clear its pending state")
	hub.call("_settle_route_activity")
	_check(int(SaveSystem.get_value("total_coins", 0)) == coins_before_route + 25,
		"Returning to the hub again must not duplicate a route-contract reward")
	SaveSystem.data = _saved_profile
	SaveSystem._batch_depth = _saved_depth
	SaveSystem._batch_dirty = _saved_dirty
	AnalyticsService._queue = _saved_events
	AnalyticsService._save_log()
	hub.free()
	await get_tree().process_frame
	await get_tree().process_frame
	for failure in _failures:
		push_error("WORLD HUB: " + failure)
	print("WORLD HUB CONTRACTS: " + ("PASS" if _failures.is_empty() else "FAIL"))
	get_tree().quit(0 if _failures.is_empty() else 1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
