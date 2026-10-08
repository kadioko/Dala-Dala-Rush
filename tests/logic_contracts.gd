extends Node
## Headless data-contract checks. Run with:
## godot --headless --path . res://tests/logic_contracts.tscn

const RoutesData := preload("res://data/routes.gd")
const CityPacksData := preload("res://data/city_packs.gd")
const VehiclesData := preload("res://data/vehicles.gd")
const MissionsData := preload("res://data/missions.gd")
const SeasonTracksData := preload("res://data/season_tracks.gd")
const GhostDataLib := preload("res://data/ghost_data.gd")
const SaveScript := preload("res://autoload/save_system.gd")
const LocaleScript := preload("res://autoload/locale_manager.gd")
const AchievementScript := preload("res://autoload/achievement_manager.gd")
const GameScript := preload("res://scripts/game.gd")
const ReferralsData := preload("res://data/referrals.gd")
const RemoteConfigScript := preload("res://autoload/remote_config.gd")
const RouteContractsData := preload("res://data/route_contracts.gd")
const OnlineServiceScript := preload("res://autoload/online_service.gd")
const AnalyticsScript := preload("res://autoload/analytics_service.gd")
const DailyRouteChallengeData := preload("res://data/daily_route_challenge.gd")
const MainMenuScript := preload("res://scripts/main_menu.gd")
const ObstacleScript := preload("res://scripts/entities/obstacle.gd")
const CollectibleScript := preload("res://scripts/entities/collectible.gd")
const LeaderboardScript := preload("res://scripts/leaderboard.gd")

const OBSTACLE_IDS := [
	"bodaboda", "bajaji", "car", "pothole", "cone", "police",
	"barrier", "truck", "pedestrian", "tire", "mbuzi",
]
const COLLECTIBLE_IDS := [
	"coin", "passenger", "fuel", "shield", "magnet", "speed_boost", "slow",
]
const GOAL_TYPES := ["score", "coins", "distance", "near_misses", "passengers"]
const ROUTE_SIGNATURE_IDS := [
	"fare_rush", "boda_watch", "truck_line", "checkpoint_clear", "fuel_scout", "jam_breaker", "highland_pass",
]
const MISSION_TYPES := [
	"coins", "dropoffs", "near_misses", "passengers", "distance",
	"horn_uses", "boosts", "fares", "score_best",
]

var _failures: Array[String] = []

func _ready() -> void:
	_check_locales()
	_check_launch_copy()
	_check_menu_layout_breakpoints()
	_check_near_miss_window()
	_check_routes()
	_check_vehicles()
	_check_missions()
	_check_achievements()
	_check_ghost_validation()
	_check_referrals()
	_check_referral_reward_idempotency()
	_check_distance_scale()
	_check_combo_contract()
	_check_save_normalization()
	_check_cloud_snapshot()
	_check_online_account_reset()
	_check_railway_telemetry()
	_check_route_mastery()
	_check_route_contracts()
	_check_daily_route_challenge()
	_check_daily_traffic_randomness()
	_check_discovery_persistence()
	_check_first_session_flow()
	_check_remote_tuning_guards()
	_check_reputation_contract()
	_check_selection_guards()
	_check_reward_idempotency()
	_check_pooled_entity_reset()
	if _failures.is_empty():
		print("LOGIC CONTRACTS: PASS")
		_release_audio_for_headless_exit()
		await get_tree().create_timer(0.12).timeout
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error("LOGIC CONTRACT: " + failure)
	print("LOGIC CONTRACTS: %d FAILURE(S)" % _failures.size())
	_release_audio_for_headless_exit()
	await get_tree().create_timer(0.12).timeout
	get_tree().quit(1)

func _check_locales() -> void:
	var locale_node: Node = LocaleScript.new()
	var all_strings: Dictionary = locale_node.get("strings")
	var sw: Dictionary = all_strings.get("sw", {})
	var en: Dictionary = all_strings.get("en", {})
	_check(not sw.is_empty(), "Swahili locale must exist")
	_check(not en.is_empty(), "English locale must exist")
	_check(sw.size() == en.size(), "Swahili and English key counts must match")
	for key_value in sw.keys():
		var key := String(key_value)
		_check(en.has(key), "English is missing locale key " + key)
	for key_value in en.keys():
		var key := String(key_value)
		_check(sw.has(key), "Swahili is missing locale key " + key)
	for discovery_key in SaveScript.DISCOVERY_KEYS:
		_check(sw.has(discovery_key) and en.has(discovery_key),
			"Discovery %s must have Swahili and English copy" % discovery_key)
	locale_node.free()

func _check_launch_copy() -> void:
	var locale_node: Node = LocaleScript.new()
	var all_strings: Dictionary = locale_node.get("strings")
	for locale_id in ["sw", "en"]:
		var locale_strings: Dictionary = all_strings.get(locale_id, {})
		var launch_text := String(locale_strings.get("GO_TEXT", "")).strip_edges()
		var prep_text := String(locale_strings.get("PREP", "")).strip_edges()
		_check(not launch_text.is_empty() and launch_text.length() <= 10,
			"%s launch copy must fit the countdown" % locale_id)
		_check(not prep_text.is_empty() and prep_text.length() <= 16,
			"%s preparation copy must fit the countdown" % locale_id)
	_check(String((all_strings.get("sw", {}) as Dictionary).get("GO_TEXT", "")) == "TWENDE!",
		"Swahili launch cue must use the natural Twende wording")
	_check((all_strings.get("sw", {}) as Dictionary).has("LEADERBOARD_WORLD_OPEN")
		and (all_strings.get("en", {}) as Dictionary).has("LEADERBOARD_WORLD_OPEN"),
		"Public World leaderboard instructions must exist in both locales")
	_check((all_strings.get("sw", {}) as Dictionary).has("MORE_OPTIONS")
		and (all_strings.get("en", {}) as Dictionary).has("MORE_OPTIONS")
		and (all_strings.get("sw", {}) as Dictionary).has("LESS_OPTIONS")
		and (all_strings.get("en", {}) as Dictionary).has("LESS_OPTIONS"),
		"Collapsed main-menu options need localized labels")
	_check((all_strings.get("sw", {}) as Dictionary).has("LEADERBOARD_WORLD_TARGET")
		and (all_strings.get("en", {}) as Dictionary).has("LEADERBOARD_WORLD_TARGET"),
		"World next-rival hint must have matching Swahili and English copy")
	locale_node.free()

func _check_menu_layout_breakpoints() -> void:
	_check(MainMenuScript.STREAK_PULSE_SCALE > 1.0 and MainMenuScript.STREAK_PULSE_SCALE <= 1.05,
		"Daily streak reward pulse must remain subtle enough for compact screens")
	_check(MainMenuScript.info_menu_columns_for_width(540.0) == 2,
		"Secondary menu should keep its two options aligned on wider phones")
	_check(MainMenuScript.info_menu_columns_for_width(499.0) == 1,
		"Narrow portrait widths must stack navigation instead of overflowing")
	_check(MainMenuScript.utility_menu_columns_for_width(412.0) == 2,
		"Common narrow phones should retain a two-column utility grid")
	_check(MainMenuScript.utility_menu_columns_for_width(360.0) == 1,
		"Small portrait widths must stack utility actions instead of overflowing")
	_check(MainMenuScript.title_font_size_for_width(320.0) == 26,
		"Main-menu title must scale down on the narrowest phones")
	_check(MainMenuScript.title_font_size_for_width(412.0) == 34,
		"Main-menu title must retain its normal size on wider phones")
	_check(LeaderboardScript.dialog_width_for_viewport(360.0, 440) == 328,
		"Leaderboard dialogs must fit a compact 360px phone")
	_check(LeaderboardScript.dialog_width_for_viewport(540.0, 440) == 440,
		"Leaderboard dialogs should retain a comfortable width on larger phones")
	_check(LeaderboardScript.points_to_overtake(500, 620) == 121
		and LeaderboardScript.points_to_overtake(700, 620) == 0,
		"World rival hint must show the exact points needed to pass the next score")
	_check(GameScript.reachable_lane_choices([0, 1, 2], 1, 1, 3) == [0, 1, 2],
		"All reachable lanes should remain available when traffic is open")
	_check(GameScript.reachable_lane_choices([0, 2], 1, 0, 3) == [0],
		"Forced traffic should prefer a lane compatible with the last safe lane")
	_check(GameScript.reachable_lane_choices([0, 2], 1, 99, 3) == [0, 2],
		"Fallback traffic choices must remain one swipe from the current lane")
	_check(GameScript.reachable_lane_choices([2], 0, 0, 3).is_empty(),
		"Traffic must defer a wave when its only escape needs two lane switches")
	var planner_rng := RandomNumberGenerator.new()
	for clear_set in [[0, 1, 2], [0, 1], [1, 2]]:
		for current_lane in range(3):
			for last_lane in range(3):
				for blocked_count in [1, 2]:
					for seed in range(1, 21):
						planner_rng.seed = seed
						var planned: Dictionary = GameScript.plan_wave_lanes(
							clear_set, current_lane, last_lane, 3, blocked_count, planner_rng)
						_check(not planned.is_empty(),
							"Planner should find a safe lane for every reachable generated-wave case")
						if planned.is_empty():
							continue
						var chosen_lane: int = int(planned.free_lane)
						_check(chosen_lane in clear_set and abs(chosen_lane - current_lane) <= 1,
							"Generated waves must leave a current, one-swipe reachable escape lane")
						_check((planned.blocked_lanes as Array).size() < clear_set.size(),
							"Generated waves must not fill every currently clear lane")
	_check(not GameScript.obstacle_blocks_lane("car", 100.0, 30.0, 185.0, 28.0),
		"A stationary car must not reserve a physically clear neighboring lane")
	_check(GameScript.obstacle_blocks_lane("bodaboda", 100.0, 17.0, 170.0, 28.0),
		"A weaving bodaboda must reserve a lane inside its drift and collision envelope")
	_check(not GameScript.obstacle_blocks_lane("bodaboda", 100.0, 17.0, 202.0, 28.0),
		"Bodaboda reservation must stop outside its full swept collision envelope")
	_check(GameScript.obstacle_blocks_lane("mbuzi", 100.0, 22.0, 900.0, 28.0),
		"A road-crossing goat must not be treated as a stable single-lane obstacle")
	var warning_y: float = GameScript.traffic_warning_y(900.0, 250.0, 42.0, 55.0)
	_check(is_equal_approx((900.0 - 42.0 - 55.0 - warning_y) / 250.0, 1.0),
		"Traffic warning must allow a full second after collision boxes stop touching")
	_check(GameScript.traffic_warning_y(1310.0, 500.0)
		< GameScript.traffic_warning_y(1310.0, 250.0),
		"Fast obstacles must trigger their lane cue earlier to preserve reaction time")
	var stationary_lanes: Array = GameScript.predicted_hazard_lanes(
		"car", 100.0, 100.0, 0.0, 0.0, 1, 1.0, 300.0,
		[0.0, 100.0, 200.0], 30.0, 28.0, 0.0, 200.0)
	_check(stationary_lanes == [1], "A stationary vehicle should only warn for its collision lane")
	var crossing_lanes: Array = GameScript.predicted_hazard_lanes(
		"mbuzi", 20.0, 20.0, 0.0, 0.0, 1, 4.0, 300.0,
		[0.0, 100.0, 200.0], 18.0, 28.0, 0.0, 200.0)
	_check(crossing_lanes.size() == 3,
		"A crossing goat should warn every lane it can enter before contact")
	var compact_player_y: float = GameScript.player_y_for_view(640.0)
	var compact_spawn: float = GameScript.obstacle_spawn_y_for(compact_player_y, 46.2, 57.2, 700.0)
	_check(compact_spawn < -130.0,
		"A fast late-run obstacle on a compact viewport must spawn early enough to react")
	for obstacle_id in ObstacleScript.TYPES.keys():
		var obstacle_type: String = String(obstacle_id)
		var definition: Dictionary = ObstacleScript.TYPES[obstacle_type]
		var visual: Vector2 = definition.get("size", Vector2.ZERO)
		var hit: Vector2 = ObstacleScript.collision_size(obstacle_type, visual)
		_check(hit.x > 0.0 and hit.y > 0.0 and hit.x <= visual.x and hit.y <= visual.y,
			"%s collision bounds must remain inside its visible art" % obstacle_type)
	for viewport_width in [320.0, 360.0, 393.0, 412.0, 540.0]:
		var dock: Dictionary = GameScript.drive_dock_metrics(viewport_width)
		_check(float(dock.width) <= viewport_width and float(dock.content_width) <= float(dock.width) + 0.1,
			"Driving controls must stay inside the %dpx viewport" % int(viewport_width))
	_check(float(GameScript.drive_dock_metrics(360.0).scale) >= 0.85,
		"Small-phone steering and horn targets must remain comfortably tappable")
	for viewport_width in [320.0, 360.0, 393.0, 412.0, 540.0]:
		_check(GameScript.pause_panel_width(viewport_width) <= viewport_width,
			"Pause actions must stay on-screen at %dpx width" % int(viewport_width))
	for safe_bottom in [0.0, 18.0, 32.0]:
		var player_bottom: float = GameScript.player_y_for_view(640.0, safe_bottom) + 55.0
		var powerup_top: float = 640.0 - 183.0 - safe_bottom
		_check(powerup_top - player_bottom >= 40.0,
			"Player vehicle must not crowd power-up indicators above the control dock")

func _check_near_miss_window() -> void:
	var player_rect := Rect2(0.0, 0.0, 80.0, 100.0)
	var close_pass := Rect2(95.0, 60.0, 70.0, 80.0)
	var late_pass := Rect2(95.0, 140.0, 70.0, 80.0)
	var collision := Rect2(20.0, 60.0, 70.0, 80.0)
	_check(GameScript.near_miss_is_eligible(player_rect, close_pass, 90.0),
		"A close, non-colliding pass should earn near-miss credit")
	_check(not GameScript.near_miss_is_eligible(player_rect, late_pass, 90.0)
		and GameScript.near_miss_window_expired(player_rect, late_pass),
		"Changing lanes after a hazard passes must not earn delayed near-miss credit")
	_check(not GameScript.near_miss_is_eligible(player_rect, collision, 15.0),
		"A real collision must not be reported as a near miss")

func _check_routes() -> void:
	var ids: Dictionary = {}
	var locale_node: Node = LocaleScript.new()
	var all_strings: Dictionary = locale_node.get("strings")
	for route_value in RoutesData.LIST:
		var route: Dictionary = route_value
		var id := String(route.get("id", ""))
		_check(not id.is_empty(), "Route id cannot be empty")
		_check(not ids.has(id), "Duplicate route id " + id)
		ids[id] = true
		_check(String(route.get("goal_type", "")) in GOAL_TYPES,
			"Route %s has unsupported goal type" % id)
		_check(float(route.get("goal_target", 0.0)) > 0.0,
			"Route %s needs a positive goal target" % id)
		_check(int(route.get("goal_reward", 0)) > 0,
			"Route %s needs a positive goal reward" % id)
		_check(float(route.get("difficulty", 0.0)) > 0.0,
			"Route %s needs positive difficulty" % id)
		_check(float(route.get("spawn_interval_mult", 0.0)) > 0.0,
			"Route %s needs a positive spawn multiplier" % id)
		_check(float(route.get("passenger_interval_mult", 0.0)) > 0.0,
			"Route %s needs a positive passenger cadence multiplier" % id)
		_check(float(route.get("kituo_gap_mult", 0.0)) > 0.0,
			"Route %s needs a positive kituo cadence multiplier" % id)
		_check(float(route.get("fuel_drain_route_mult", 0.0)) > 0.0,
			"Route %s needs a positive route fuel multiplier" % id)
		var rush_chance: float = float(route.get("rush_hour_chance", -1.0))
		_check(rush_chance >= 0.0 and rush_chance <= 1.0,
			"Route %s needs a valid rush-hour chance" % id)
		_check_weights(id + " conditions", route.get("condition_weights", {}), RoutesData.CONDITION_IDS)
		_check(String(route.get("signature_id", "")) in ROUTE_SIGNATURE_IDS,
			"Route %s needs a supported signature moment" % id)
		_check(not String(route.get("signature_key", "")).is_empty(),
			"Route %s needs signature copy" % id)
		_check(not String(route.get("signature_title_key", "")).is_empty(),
			"Route %s needs a compact signature title" % id)
		_check(not String(route.get("signature_action_key", "")).is_empty(),
			"Route %s needs a clear signature action" % id)
		for locale_id in ["sw", "en"]:
			var locale_strings: Dictionary = all_strings.get(locale_id, {})
			for copy_key in ["signature_key", "signature_title_key", "signature_action_key"]:
				var locale_key: String = String(route.get(copy_key, ""))
				_check(locale_strings.has(locale_key) and not String(locale_strings.get(locale_key, "")).is_empty(),
					"Route %s has missing %s copy in %s" % [id, copy_key, locale_id])
		var mastery_scores: Array = route.get("mastery_scores", [])
		var mastery_rewards: Array = route.get("mastery_rewards", [])
		_check(mastery_scores.size() == 3 and mastery_rewards.size() == 3,
			"Route %s needs three mastery thresholds and rewards" % id)
		if mastery_scores.size() == 3:
			_check(int(mastery_scores[0]) > 0 and int(mastery_scores[0]) < int(mastery_scores[1]) \
			and int(mastery_scores[1]) < int(mastery_scores[2]),
				"Route %s mastery thresholds must rise" % id)
		if mastery_rewards.size() == 3:
			for reward_value in mastery_rewards:
				_check(int(reward_value) > 0, "Route %s mastery reward must be positive" % id)
		_check_weights(id, route.get("obstacle_weights", {}), OBSTACLE_IDS)
		_check_weights(id, route.get("collectible_weights", {}), COLLECTIBLE_IDS)
	_check(ids.has("kariakoo"), "Starter route kariakoo must exist")
	_check(ids.has("arusha"), "Arusha city pack must add its route to the route catalog")
	_check(CityPacksData.route_ids().size() == ids.size()
		and CityPacksData.get_by_id("arusha").get("status", "") == "live",
		"City pack catalog must account for every playable route")
	var arusha: Dictionary = RoutesData.get_by_id("arusha")
	_check(String(arusha.get("city_pack", "")) == "arusha"
		and String(arusha.get("signature_id", "")) == "highland_pass"
		and float(arusha.get("fuel_drain_route_mult", 1.0)) < 1.0,
		"Arusha needs a distinct highland route identity and long-run fuel profile")
	var kigamboni: Dictionary = RoutesData.get_by_id("kigamboni")
	_check(RoutesData.pick_condition(kigamboni, 0.99) == "rain",
		"Kigamboni's high weather roll must select its rain profile")
	var mbezi: Dictionary = RoutesData.get_by_id("mbezi")
	_check(RoutesData.pick_condition(mbezi, 0.10) == "day",
		"Mbezi's low weather roll must select its day profile")
	var kariakoo: Dictionary = RoutesData.get_by_id("kariakoo")
	_check(float(kariakoo.passenger_interval_mult) < float(mbezi.passenger_interval_mult),
		"Kariakoo should create more frequent fare/passenger opportunities than Mbezi")
	_check(float(kigamboni.fuel_drain_route_mult) > float(mbezi.fuel_drain_route_mult),
		"Kigamboni should exert more fuel pressure than the Mbezi efficiency route")
	var ubungo: Dictionary = RoutesData.get_by_id("ubungo")
	_check(float(kariakoo.spawn_interval_mult) / float(kariakoo.difficulty)
		> float(ubungo.spawn_interval_mult) / float(ubungo.difficulty),
		"Ubungo should have a denser traffic rhythm than starter Kariakoo")
	locale_node.free()

func _check_weights(owner_id: String, value: Variant, allowed: Array) -> void:
	_check(typeof(value) == TYPE_DICTIONARY, "%s weights must be a dictionary" % owner_id)
	if typeof(value) != TYPE_DICTIONARY:
		return
	var weights := value as Dictionary
	var total := 0.0
	for key_value in weights.keys():
		var key := String(key_value)
		_check(key in allowed, "%s has unknown weighted id %s" % [owner_id, key])
		var weight := float(weights.get(key, 0.0))
		_check(weight >= 0.0, "%s has negative weight for %s" % [owner_id, key])
		total += maxf(0.0, weight)
	_check(total > 0.0, "%s needs at least one positive weight" % owner_id)

func _check_vehicles() -> void:
	var ids: Dictionary = {}
	for vehicle_value in VehiclesData.LIST:
		var vehicle: Dictionary = vehicle_value
		var id := String(vehicle.get("id", ""))
		_check(not id.is_empty(), "Vehicle id cannot be empty")
		_check(not ids.has(id), "Duplicate vehicle id " + id)
		ids[id] = true
		_check(int(vehicle.get("price", -1)) >= 0, "Vehicle %s has invalid price" % id)
		_check(float(vehicle.get("lane_time", 0.0)) > 0.0,
			"Vehicle %s needs positive lane time" % id)
		_check(float(vehicle.get("fuel_drain_mult", 0.0)) > 0.0,
			"Vehicle %s needs positive fuel drain" % id)
		_check(float(vehicle.get("coin_mult", 0.0)) > 0.0,
			"Vehicle %s needs positive coin multiplier" % id)
		_check(int(vehicle.get("horn_charges", 0)) > 0,
			"Vehicle %s needs at least one horn charge" % id)
	_check(ids.has("classic_blue"), "Starter vehicle classic_blue must exist")

func _check_missions() -> void:
	var ids: Dictionary = {}
	for template_value in MissionsData.TEMPLATES:
		var mission: Dictionary = template_value
		var id := String(mission.get("id", ""))
		_check(not ids.has(id), "Duplicate mission id " + id)
		ids[id] = true
		_check(String(mission.get("type", "")) in MISSION_TYPES,
			"Mission %s has unsupported type" % id)
		_check(int(mission.get("target", 0)) > 0, "Mission %s needs a target" % id)
		_check(int(mission.get("reward", 0)) > 0, "Mission %s needs a reward" % id)
		_check(int(mission.get("xp", 0)) > 0, "Mission %s needs XP" % id)
	_check(MissionsData.ACTIVE_COUNT > 0 \
		and MissionsData.ACTIVE_COUNT <= MissionsData.TEMPLATES.size(),
		"Mission active count must fit the template pool")
	_check(String(SeasonTracksData.chapter_for_level(1).get("name_key", "")) == "SEASON_CHAPTER_DAR"
		and String(SeasonTracksData.chapter_for_level(5).get("name_key", "")) == "SEASON_CHAPTER_ARUSHA",
		"Season chapters should progress from Dar routes to the Arusha pack")
	_check(SeasonTracksData.milestone_reward(4) == 75
		and SeasonTracksData.milestone_reward(8) == 100
		and SeasonTracksData.next_milestone(8) == 12
		and SeasonTracksData.next_milestone(16) == 20,
		"Season bonus milestones must be finite, visible, and continue safely")

func _check_achievements() -> void:
	var ids: Dictionary = {}
	for achievement_value in AchievementScript.ACHIEVEMENTS:
		var achievement: Dictionary = achievement_value
		var id := String(achievement.get("id", ""))
		_check(not id.is_empty(), "Achievement id cannot be empty")
		_check(not ids.has(id), "Duplicate achievement id " + id)
		ids[id] = true

func _check_ghost_validation() -> void:
	var valid := {
		"events": [[0.0, 1], [2.0, 0], [4.0, 2]],
		"end": 8.0,
		"score": 500,
		"name": "ABC",
		"route": "arusha",
		"vehicle_id": "classic_blue",
		"challenge_id": "route_daily_2026-10-08",
		"traffic_seed": 12345,
	}
	_check(not GhostDataLib.sanitize(valid).is_empty(), "Valid ghost was rejected")
	var encoded := GhostDataLib.encode(valid)
	_check(not encoded.is_empty(), "Valid ghost could not be encoded")
	var decoded := GhostDataLib.decode(encoded)
	_check(not decoded.is_empty() and String(decoded.get("route", "")) == "arusha"
		and int(decoded.get("traffic_seed", 0)) == 12345,
		"Replay clip metadata did not survive code round-trip")
	var challenge := {
		"id": "route_daily_2026-10-08", "route_id": "arusha",
		"vehicle_id": "classic_blue", "traffic_seed": 12345,
	}
	_check(GhostDataLib.matches_daily_challenge(decoded, challenge),
		"A replay from the same daily rules should qualify as a rival")
	challenge["traffic_seed"] = 12346
	_check(not GhostDataLib.matches_daily_challenge(decoded, challenge),
		"A replay from different traffic seed must not qualify for a Daily Run")
	_check(GhostDataLib.sanitize({"events": [[0.0, 1]], "end": 8.0, "route": "not_a_route"}).is_empty(),
		"Replay clip with an unknown route was accepted")
	_check(GhostDataLib.sanitize({"events": [[0.0, 4]], "end": 8.0}).is_empty(),
		"Out-of-range ghost lane was accepted")
	_check(GhostDataLib.sanitize({"events": [[3.0, 1], [2.0, 1]], "end": 8.0}).is_empty(),
		"Backward ghost timeline was accepted")
	_check(GhostDataLib.sanitize({"events": [], "end": 0.1}).is_empty(),
		"Trivial ghost duration was accepted")
	_check(GhostDataLib.decode("not-a-ghost").is_empty(), "Invalid ghost prefix was accepted")

func _check_referrals() -> void:
	var inviter := "DDR-ABC234"
	var invitee := "DDR-DEF567"
	_check(ReferralsData.normalize_invite_code(" ddr abc-234 ") == inviter,
		"Referral invite normalization failed")
	_check(ReferralsData.normalize_invite_code("DDR-000000").is_empty(),
		"Referral code accepted confusing or unsupported characters")
	_check(not bool(ReferralsData.validate_invite_claim(inviter, inviter, false).get("ok", true)),
		"Self-referral was accepted")
	_check(not bool(ReferralsData.validate_invite_claim(inviter, invitee, true).get("ok", true)),
		"A second welcome referral was accepted")
	var confirmation := ReferralsData.build_confirmation_code(inviter, invitee)
	var parsed := ReferralsData.inspect_confirmation_code(confirmation)
	_check(bool(parsed.get("ok", false)), "Valid referral confirmation was rejected")
	_check(String(parsed.get("inviter", "")) == inviter,
		"Referral confirmation lost the inviter code")
	_check(String(parsed.get("invitee", "")) == invitee,
		"Referral confirmation lost the invitee code")
	var tampered := confirmation.substr(0, confirmation.length() - 1) + "0"
	_check(not bool(ReferralsData.inspect_confirmation_code(tampered).get("ok", true)),
		"Tampered referral confirmation was accepted")
	_check(ReferralsData.WELCOME_REWARD > 0 and ReferralsData.REFERRER_REWARD > 0,
		"Referral rewards must be positive")
	_check(ReferralsData.MAX_REFERRAL_REWARDS > 0 \
		and ReferralsData.MAX_REFERRAL_REWARDS <= 20,
		"Offline referral reward limit is outside the safe economy range")
	_check(ReferralsData.milestone_reward_for(3) == 100,
		"Three-friend referral milestone has the wrong reward")
	_check(ReferralsData.milestone_reward_for(4) == 0,
		"Non-milestone referral count paid a bonus")
	var next_milestone := ReferralsData.next_milestone_after(3)
	_check(int(next_milestone.get("count", 0)) == 5,
		"Referral milestone progression did not advance to five friends")

func _check_referral_reward_idempotency() -> void:
	var save_data_before := SaveSystem.data.duplicate(true)
	var batch_depth_before := SaveSystem._batch_depth
	var batch_dirty_before := SaveSystem._batch_dirty
	var inviter := "DDR-ABC234"
	var invitee := "DDR-DEF567"

	# Keep referral reward tests in memory so developer saves are never rewritten.
	SaveSystem.data = SaveScript.DEFAULTS.duplicate(true)
	SaveSystem.data["referral_invite_code"] = invitee
	SaveSystem._batch_depth = 1
	SaveSystem._batch_dirty = false
	var welcome_claim := ReferralsData.claim_invite_code(inviter)
	var repeated_welcome := ReferralsData.claim_invite_code(inviter)
	_check(bool(welcome_claim.get("ok", false)), "Valid welcome referral did not pay")
	_check(not bool(repeated_welcome.get("ok", true)), "Welcome referral paid twice")
	_check(int(SaveSystem.data.total_coins) == ReferralsData.WELCOME_REWARD,
		"Welcome referral paid an incorrect amount")

	var confirmation := String(welcome_claim.get("confirmation", ""))
	SaveSystem.data = SaveScript.DEFAULTS.duplicate(true)
	SaveSystem.data["referral_invite_code"] = inviter
	SaveSystem._batch_depth = 1
	SaveSystem._batch_dirty = false
	var referrer_claim := ReferralsData.claim_confirmation_code(confirmation)
	var repeated_referrer_claim := ReferralsData.claim_confirmation_code(confirmation)
	_check(bool(referrer_claim.get("ok", false)), "Valid referrer confirmation did not pay")
	_check(not bool(repeated_referrer_claim.get("ok", true)),
		"Referrer confirmation paid twice")
	_check(int(SaveSystem.data.total_coins) == ReferralsData.REFERRER_REWARD,
		"Referrer confirmation paid an incorrect amount")
	_check((SaveSystem.data.referral_claimed_invitees as Array).size() == 1,
		"Referrer claim did not record exactly one invitee")

	var second_confirmation := ReferralsData.build_confirmation_code(inviter, "DDR-GHJ678")
	var third_confirmation := ReferralsData.build_confirmation_code(inviter, "DDR-KLM789")
	var second_claim := ReferralsData.claim_confirmation_code(second_confirmation)
	var third_claim := ReferralsData.claim_confirmation_code(third_confirmation)
	var repeated_milestone_claim := ReferralsData.claim_confirmation_code(third_confirmation)
	_check(bool(second_claim.get("ok", false)) and bool(third_claim.get("ok", false)),
		"Valid milestone referrals were rejected")
	_check(int(third_claim.get("milestone_bonus", 0)) == 100,
		"Third referral did not pay its milestone bonus")
	_check(not bool(repeated_milestone_claim.get("ok", true)),
		"Third-referral milestone paid twice")
	_check(int(SaveSystem.data.total_coins) == ReferralsData.REFERRER_REWARD * 3 + 100,
		"Three-referral total did not include the exact milestone payout")

	SaveSystem.data = save_data_before
	SaveSystem._batch_depth = batch_depth_before
	SaveSystem._batch_dirty = batch_dirty_before

func _check_distance_scale() -> void:
	var base_meters_per_second := 340.0 * float(GameScript.METERS_PER_WORLD_UNIT)
	_check(base_meters_per_second >= 40.0 and base_meters_per_second <= 70.0,
		"Base distance rate should keep goals meaningful")
	var seconds_to_one_km := 1000.0 / base_meters_per_second
	_check(seconds_to_one_km >= 14.0,
		"The 1 km achievement must not complete during the opening seconds")

func _check_combo_contract() -> void:
	_check(GameScript.next_combo(0) == 1,
		"Driving flow must start at one action")
	_check(GameScript.next_combo(4, 2) == 6,
		"A fare service action must advance driving flow by its full value")
	_check(GameScript.next_combo(GameScript.COMBO_MAX, 3) == GameScript.COMBO_MAX,
		"Driving flow must cap coin scaling at its documented maximum")

func _check_save_normalization() -> void:
	var save_node := SaveScript.new()
	save_node.data = SaveScript.DEFAULTS.duplicate(true)
	save_node.data["schema_version"] = 2
	save_node.data["total_runs"] = 5
	save_node.data.erase("regular_runs")
	save_node.data["total_coins"] = -100
	save_node.data["total_distance_ever"] = -25.0
	save_node.data["locale"] = "invalid"
	save_node.data["unlocked_vehicles"] = ["vip", "vip", 42]
	save_node.data["unlocked_routes"] = []
	save_node.data["consumables"] = {"shield": 2, "bad": {"count": 99}}
	save_node.data["leaderboard"] = [
		{"name": "longname", "score": 15, "route": "kariakoo"},
		{"name": "bad", "score": -1, "route": "mwenge"},
		{"name": [], "score": {}, "route": []},
		"invalid",
	]
	save_node.data["referral_claimed_invitees"] = ["DDR-ABC234", "DDR-ABC234", 42]
	save_node.data["referral_success_count"] = 99
	save_node.data["route_mastery"] = {"kariakoo": 9, "mwenge": -2, "bad": "stars"}
	save_node.data["route_contract_claimed_on"] = {"kariakoo": "2026-09-02", "bad": 42, "": "2026-01-01"}
	save_node.data["seen_discoveries"] = ["DISCOVERY_WEATHER", "DISCOVERY_WEATHER", 42, "bad"]
	save_node.data["online_installation_id"] = 42
	save_node.data["online_sync_token"] = []
	save_node.call("_normalize_core_data")
	_check(int(save_node.data.schema_version) == 16, "Old save schema was not migrated")
	_check(int(save_node.data.regular_runs) == 5,
		"Legacy runs must migrate as regular runs to preserve experienced-player status")
	_check(int(save_node.data.total_coins) == 0, "Negative saved coins were not clamped")
	_check(float(save_node.data.total_distance_ever) == 0.0,
		"Negative lifetime distance was not clamped")
	_check(String(save_node.data.locale) == "sw", "Invalid locale did not fall back")
	_check("classic_blue" in save_node.data.unlocked_vehicles,
		"Save repair must preserve the starter vehicle")
	_check("kariakoo" in save_node.data.unlocked_routes,
		"Save repair must preserve the starter route")
	_check((save_node.data.consumables as Dictionary) == {"shield": 2},
		"Malformed consumable counts were not removed")
	_check((save_node.data.leaderboard as Array).size() == 1,
		"Malformed leaderboard rows were not removed")
	_check((save_node.data.referral_claimed_invitees as Array).size() == 1,
		"Malformed or duplicate referral invitees were not removed")
	_check(int(save_node.data.referral_success_count) == 1,
		"Referral success count did not reconcile with claimed invitees")
	_check((save_node.data.route_mastery as Dictionary) == {"kariakoo": 3},
		"Malformed route mastery was not repaired")
	_check((save_node.data.seen_discoveries as Array) == ["DISCOVERY_WEATHER"],
		"Malformed discovery history was not repaired")
	_check((save_node.data.route_contract_claimed_on as Dictionary) == {"kariakoo": "2026-09-02"},
		"Malformed route contract claims were not repaired")
	_check(String(save_node.data.online_installation_id).is_empty()
		and String(save_node.data.online_sync_token).is_empty(),
		"Malformed cloud-sync identity was not removed")
	_check(SaveScript.normalize_leaderboard_name("  Konda   Juma  ") == "Konda Juma",
		"Leaderboard name normalization should trim repeated whitespace")
	# Keep these persistence contracts in memory; test runs must not touch a
	# developer's actual user:// save.
	save_node._batch_depth = 1
	save_node.queue_leaderboard_submission("kariakoo", 400)
	save_node.queue_leaderboard_submission("kariakoo", 650)
	save_node.queue_leaderboard_submission("bad", 999)
	var pending_scores: Array = save_node.get_pending_leaderboard_submissions()
	_check(pending_scores.size() == 1 and int((pending_scores[0] as Dictionary).get("score", 0)) == 650,
		"Pending leaderboard submissions should keep only the best route score")
	save_node.cache_online_leaderboard("world", "kariakoo", [{"displayName": "Juma", "score": 50}])
	_check(not save_node.get_cached_online_leaderboard("world", "kariakoo").is_empty(),
		"Online leaderboard cache was not retained")
	_check(SaveScript.normalize_leaderboard_name("A") == "Dereva",
		"Too-short leaderboard names should receive a safe fallback")
	_check(SaveScript.normalize_leaderboard_name("$$Konda@@") == "Konda",
		"Leaderboard names should keep only the server-approved character set")
	_check(SaveScript.is_reserved_leaderboard_name("Official_Dereva")
		and not SaveScript.is_reserved_leaderboard_name("Konda Juma"),
		"Reserved official-looking leaderboard names must be rejected without blocking ordinary names")
	save_node.set_leaderboard_upload_status("retry", "kariakoo", 650)
	var upload_state: Dictionary = save_node.get_leaderboard_upload_state()
	_check(String(upload_state.get("status", "")) == "retry"
		and String(upload_state.get("route", "")) == "kariakoo"
		and int(upload_state.get("score", 0)) == 650,
		"Leaderboard upload status should persist a local retry state")
	save_node._batch_depth = 0
	save_node._batch_dirty = false
	save_node.free()
	for old_schema in [2, 8, 13]:
		var legacy := SaveScript.new()
		legacy.data = SaveScript.DEFAULTS.duplicate(true)
		legacy.data["schema_version"] = old_schema
		legacy.data["total_runs"] = old_schema + 10
		legacy.data.erase("regular_runs")
		legacy.data["total_coins"] = 23
		legacy.call("_normalize_core_data")
		_check(int(legacy.data.schema_version) == 16
			and int(legacy.data.regular_runs) == old_schema + 10
			and int(legacy.data.total_coins) == 23,
			"Legacy schema %d migration must preserve runs and currency" % old_schema)
		legacy.free()
	AudioManager.set_game_paused(true)
	_check(AudioManager.game_paused,
		"Pausing gameplay must persistently silence audio managed by the audio service")
	AudioManager.set_game_paused(false)
	_check(not AudioManager.game_paused,
		"Resuming gameplay must restore the shared audio service")

func _check_cloud_snapshot() -> void:
	var service := OnlineServiceScript.new()
	var snapshot: Dictionary = service.cloud_snapshot({
		"total_coins": 250,
		"selected_route": "kariakoo",
		"referral_invite_code": "DDR-ABC234",
		"leaderboard": [{"name": "DDD", "score": 999}],
		"analytics_session_count": 4,
		"online_sync_token": "secret",
		"leaderboard_display_name": "Konda Juma",
		"online_leaderboard_opt_in": true,
		"leaderboard_upload_status": "retry",
		"leaderboard_upload_route": "kariakoo",
		"leaderboard_upload_score": 880,
		"leaderboard_upload_updated_at": 1000,
	})
	_check(int(snapshot.get("total_coins", 0)) == 250
		and String(snapshot.get("selected_route", "")) == "kariakoo",
		"Cloud snapshot lost allowed game progress")
	_check(not snapshot.has("referral_invite_code") and not snapshot.has("leaderboard")
		and not snapshot.has("analytics_session_count") and not snapshot.has("online_sync_token")
		and not snapshot.has("leaderboard_display_name") and not snapshot.has("online_leaderboard_opt_in")
		and not snapshot.has("leaderboard_upload_status") and not snapshot.has("leaderboard_upload_route")
		and not snapshot.has("leaderboard_upload_score") and not snapshot.has("leaderboard_upload_updated_at"),
		"Cloud snapshot included private local data")
	_check(service.is_release_rollout_enabled(),
		"Cloud service must be enabled for consent-gated phone QA")
	service._registration_in_flight = true
	service.register_installation()
	_check(service.get_child_count() == 0,
		"Concurrent online opt-ins must share one registration request")
	service.free()

func _check_online_account_reset() -> void:
	var save_node := SaveScript.new()
	save_node.data = SaveScript.DEFAULTS.duplicate(true)
	save_node._batch_depth = 1
	save_node.data["best_mwenge"] = 540
	save_node.data["leaderboard"] = [
		{"name": "Juma", "score": 900, "route": "kariakoo"},
		{"name": "Juma", "score": 800, "route": "kariakoo"},
		{"name": "Juma", "score": 700, "route": "kariakoo"},
		{"name": "Juma", "score": 600, "route": "kariakoo"},
		{"name": "Juma", "score": 550, "route": "kariakoo"},
	]
	var personal: Array = save_node.get_personal_route_scores("mwenge")
	_check(personal.size() == 1 and int((personal[0] as Dictionary).get("score", 0)) == 540,
		"A route record outside the global Top-5 must appear on its Personal board")
	save_node.data["online_installation_id"] = "installation"
	save_node.data["online_sync_token"] = "token"
	save_node.data["online_cloud_revision"] = 3
	save_node.data["cloud_sync_opt_in"] = true
	save_node.data["online_leaderboard_opt_in"] = true
	save_node.data["online_telemetry_opt_in"] = true
	save_node.data["leaderboard_upload_status"] = "retry"
	save_node.data["pending_leaderboard_submissions"] = [{"route": "mwenge", "score": 540}]
	save_node.data["leaderboard_cache"] = {"world:mwenge": {"scores": []}}
	save_node.clear_online_account()
	_check(String(save_node.data.online_installation_id).is_empty()
		and String(save_node.data.online_sync_token).is_empty()
		and int(save_node.data.online_cloud_revision) == 0,
		"Deleting an online account must remove its saved identity")
	_check(not bool(save_node.data.cloud_sync_opt_in)
		and not bool(save_node.data.online_leaderboard_opt_in)
		and not bool(save_node.data.online_telemetry_opt_in),
		"Deleting an online account must reset every online consent")
	_check((save_node.data.pending_leaderboard_submissions as Array).is_empty()
		and (save_node.data.leaderboard_cache as Dictionary).is_empty()
		and String(save_node.data.leaderboard_upload_status).is_empty()
		and int(save_node.data.best_mwenge) == 540,
		"Deleting online data must clear stale submissions while preserving local progress")
	save_node.free()

func _check_railway_telemetry() -> void:
	var tracker := AnalyticsScript.new()
	var now: int = int(Time.get_unix_time_from_system())
	tracker._queue = [
		{"e": "run_end", "p": {"score": 100}, "t": float(now) - 0.25},
		{"e": "run_end", "p": {}, "t": now - AnalyticsScript.RAILWAY_MAX_EVENT_AGE_SECONDS - 10},
	]
	var batch: Array = tracker.get_railway_batch()
	_check(batch.size() == 1, "Railway telemetry must skip events too old for the server")
	if not batch.is_empty():
		_check(typeof((batch[0] as Dictionary).get("t", null)) == TYPE_INT,
			"Railway telemetry must send whole-second timestamps, including old queued events")
	tracker.free()

func _check_daily_route_challenge() -> void:
	var first: Dictionary = DailyRouteChallengeData.current()
	var second: Dictionary = DailyRouteChallengeData.current()
	_check(String(first.get("route_id", "")) in ["kariakoo", "mwenge", "mbezi", "posta", "kigamboni", "ubungo"],
		"Daily route must use a shipped route")
	_check(String(first.get("vehicle_id", "")) == "classic_blue" and not bool(first.get("revives_allowed", true)),
		"Daily route must use the shared starter vehicle and no-revive rule")
	_check(int(first.get("traffic_seed", 0)) == int(second.get("traffic_seed", -1)),
		"Daily route seed must be stable for the same date")
	_check(GameScript.run_tuning_multiplier(true, 1.4) == 1.0
		and GameScript.run_tuning_multiplier(false, 1.4) == 1.4,
		"Daily Run must ignore live tuning while regular runs retain it")
	_check(GameScript.effective_upgrade_level(true, 3) == 0
		and GameScript.effective_upgrade_level(false, 3) == 3,
		"Career upgrades must not alter shared Daily Run rules")
	_check(GameScript.effective_tutorial_stage(true, 2) == 0
		and GameScript.effective_tutorial_stage(false, 2) == 2,
		"Daily Run traffic must not depend on onboarding progress")
	_check(not GameScript.daily_run_ghost_allowed(true, 20, true)
		and GameScript.daily_run_ghost_allowed(false, 20, true),
		"Account-specific ghosts must not alter Daily Run scores")
	_check(GameScript.replay_pass_bonus(true) == 0
		and GameScript.replay_pass_bonus(false) == 150,
		"Rival replays must not change comparable Daily Run scores")
	_check(not GameScript.daily_run_chases_allowed(true, 0)
		and not GameScript.daily_run_chases_allowed(true, 20)
		and GameScript.daily_run_chases_allowed(false, 6)
		and not GameScript.daily_run_chases_allowed(false, 5),
		"Daily Runs must consistently omit account-gated police chases")
	var original_save: Dictionary = SaveSystem.data.duplicate(true)
	var original_batch_depth: int = SaveSystem._batch_depth
	var original_batch_dirty: bool = SaveSystem._batch_dirty
	SaveSystem.data = SaveScript.DEFAULTS.duplicate(true)
	SaveSystem._batch_depth = 1
	SaveSystem._batch_dirty = false
	SaveSystem.add_run_stats(0.0, 0, 0, true, true)
	_check(int(SaveSystem.data.total_runs) == 1 and int(SaveSystem.data.regular_runs) == 0,
		"Daily runs must count toward lifetime totals without marking onboarding as completed")
	_check(GameState.tutorial_stage_for_run(false) == 1,
		"A new player who first plays Daily Run must still receive the first regular tutorial")
	SaveSystem.add_run_stats(0.0, 0, 0, true, false)
	_check(int(SaveSystem.data.total_runs) == 2 and int(SaveSystem.data.regular_runs) == 1,
		"Regular runs must increment both lifetime and regular-run totals")
	SaveSystem.data = original_save
	SaveSystem._batch_depth = original_batch_depth
	SaveSystem._batch_dirty = original_batch_dirty

func _check_daily_traffic_randomness() -> void:
	var first_rng := RandomNumberGenerator.new()
	var second_rng := RandomNumberGenerator.new()
	first_rng.seed = 24513
	second_rng.seed = 24513
	var weights := {"coin": 6.0, "fuel": 2.0, "shield": 1.0}
	for _attempt in range(5):
		_check(GameScript.shuffle_with_rng(range(10), first_rng) \
			== GameScript.shuffle_with_rng(range(10), second_rng),
			"Equal Daily Run seeds must choose the same lane order")
		_check(RoutesData.weighted_pick(weights, ["coin", "fuel", "shield"], "coin", first_rng) \
			== RoutesData.weighted_pick(weights, ["coin", "fuel", "shield"], "coin", second_rng),
			"Equal Daily Run seeds must choose the same collectible type")
	var first_visual_rng := RandomNumberGenerator.new()
	var second_visual_rng := RandomNumberGenerator.new()
	first_visual_rng.seed = 100
	second_visual_rng.seed = 200
	var first_obstacle := ObstacleScript.new()
	var second_obstacle := ObstacleScript.new()
	first_obstacle.setup("bodaboda", 100.0, -130.0, first_rng, first_visual_rng)
	second_obstacle.setup("bodaboda", 100.0, -130.0, second_rng, second_visual_rng)
	_check(first_obstacle.drift_phase == second_obstacle.drift_phase
		and first_obstacle.walk_dir == second_obstacle.walk_dir,
		"Cosmetic randomness must not change seeded obstacle movement")
	first_obstacle.free()
	second_obstacle.free()

func _check_route_mastery() -> void:
	var route: Dictionary = RoutesData.get_by_id("kariakoo")
	var first_star: int = RoutesData.mastery_stars(route, {"score": 400})
	var second_star: int = RoutesData.mastery_stars(route, {
		"score": 800, "passengers": 8, "reputation": 75,
	})
	var third_star: int = RoutesData.mastery_stars(route, {
		"score": 1300, "passengers": 8, "reputation": 85,
	})
	_check(first_star == 1, "First route mastery star should require its score threshold")
	_check(second_star == 2, "Second route mastery star must require score and route goal")
	_check(third_star == 3, "Third route mastery star must require excellent reputation")
	_check(RoutesData.mastery_reward(route, 0, 3) == 85,
		"Route mastery must award each newly earned star exactly once")
	_check(RoutesData.mastery_reward(route, 3, 3) == 0,
		"Completed route mastery must not repay repeat runs")
	var next_first: Dictionary = RoutesData.next_mastery_target(route, 0)
	var next_second: Dictionary = RoutesData.next_mastery_target(route, 1)
	var next_third: Dictionary = RoutesData.next_mastery_target(route, 2)
	var mastered: Dictionary = RoutesData.next_mastery_target(route, 3)
	_check(int(next_first.get("score", 0)) == 400 and not bool(next_first.get("needs_goal", true)),
		"First mastery target must be score-only")
	_check(bool(next_second.get("needs_goal", false)) and not bool(next_second.get("needs_reputation", true)),
		"Second mastery target must add the route goal")
	_check(bool(next_third.get("needs_goal", false)) and bool(next_third.get("needs_reputation", false)),
		"Third mastery target must require an A reputation")
	_check(bool(mastered.get("complete", false)), "Completed route must report a mastered target")

	var save_data_before := SaveSystem.data.duplicate(true)
	var batch_depth_before := SaveSystem._batch_depth
	var batch_dirty_before := SaveSystem._batch_dirty
	SaveSystem.data = SaveScript.DEFAULTS.duplicate(true)
	SaveSystem._batch_depth = 1
	SaveSystem._batch_dirty = false
	_check(SaveSystem.update_route_mastery("kariakoo", 2) == 2,
		"First mastery save must record both newly earned stars")
	_check(SaveSystem.update_route_mastery("kariakoo", 2) == 0,
		"Repeated mastery tier must not pay a second time")
	_check(SaveSystem.update_route_mastery("kariakoo", 3) == 1,
		"Only the newly earned final star should be awarded later")
	_check(SaveSystem.get_route_mastery("kariakoo") == 3,
		"Saved mastery must retain the highest achieved tier")
	SaveSystem.data = save_data_before
	SaveSystem._batch_depth = batch_depth_before
	SaveSystem._batch_dirty = batch_dirty_before

func _check_route_contracts() -> void:
	for route_value in RoutesData.LIST:
		var route: Dictionary = route_value
		var route_id: String = String(route.id)
		var contract: Dictionary = RouteContractsData.current(route_id, "2026-09-02")
		_check(not contract.is_empty(), "Route %s needs a daily contract" % route_id)
		_check(int(contract.get("target", 0)) > 0 and int(contract.get("reward", 0)) > 0,
			"Route %s contract needs a positive target and reward" % route_id)
		_check(not String(contract.get("key", "")).is_empty(),
			"Route %s contract needs localized copy" % route_id)

	var save_data_before := SaveSystem.data.duplicate(true)
	var batch_depth_before := SaveSystem._batch_depth
	var batch_dirty_before := SaveSystem._batch_dirty
	SaveSystem.data = SaveScript.DEFAULTS.duplicate(true)
	SaveSystem.data["total_runs"] = 3
	SaveSystem._batch_depth = 1
	SaveSystem._batch_dirty = false
	var current: Dictionary = RouteContractsData.current("kariakoo")
	var stats: Dictionary = {}
	stats[String(current.get("type", "score"))] = int(current.get("target", 0))
	_check(RouteContractsData.is_available("kariakoo"),
		"Route contracts must begin after the first-session lessons")
	_check(RouteContractsData.is_met(current, stats),
		"A contract target must satisfy its own progress rule")
	_check(RouteContractsData.mark_completed("kariakoo"),
		"A completed route contract must claim once")
	_check(not RouteContractsData.mark_completed("kariakoo"),
		"A route contract must not claim twice in one day")
	SaveSystem.data = save_data_before
	SaveSystem._batch_depth = batch_depth_before
	SaveSystem._batch_dirty = batch_dirty_before

func _check_discovery_persistence() -> void:
	var save_data_before := SaveSystem.data.duplicate(true)
	var batch_depth_before := SaveSystem._batch_depth
	var batch_dirty_before := SaveSystem._batch_dirty
	SaveSystem.data = SaveScript.DEFAULTS.duplicate(true)
	SaveSystem._batch_depth = 1
	SaveSystem._batch_dirty = false
	_check(SaveSystem.mark_discovery_seen("DISCOVERY_WEATHER"),
		"First discovery display must persist")
	_check(not SaveSystem.mark_discovery_seen("DISCOVERY_WEATHER"),
		"A discovery must not be shown twice")
	_check(SaveSystem.has_seen_discovery("DISCOVERY_WEATHER"),
		"Persisted discovery was not readable")
	_check(not SaveSystem.mark_discovery_seen("NOT_A_DISCOVERY"),
		"Unknown discovery key was accepted")
	SaveSystem.data = save_data_before
	SaveSystem._batch_depth = batch_depth_before
	SaveSystem._batch_dirty = batch_dirty_before

func _check_reputation_contract() -> void:
	var strong: Dictionary = GameState.calculate_reputation({
		"passengers": 12, "dropoffs": 8, "near_misses": 4, "goal_met": true,
		"clean_checkpoints": 2, "route_moments": 1, "missed_stops": 0,
		"fines": 0, "end_reason": "car",
	})
	var weak: Dictionary = GameState.calculate_reputation({
		"passengers": 0, "dropoffs": 0, "near_misses": 0, "goal_met": false,
		"clean_checkpoints": 0, "route_moments": 0, "missed_stops": 5,
		"fines": 5, "end_reason": "fuel",
	})
	_check(int(strong.get("score", -1)) >= 85 and String(strong.get("grade", "")) == "A",
		"Strong service run must earn an A reputation")
	_check(int(weak.get("score", 101)) >= 0 and int(weak.get("score", -1)) < int(strong.get("score", 0)),
		"Poor service run must be bounded and rank below a strong run")
	var strong_ledger_score: int = clampi(int(strong.get("base", 0)) \
		+ int(strong.get("positive_total", 0)) - int(strong.get("negative_total", 0)), 0, 100)
	_check(int(strong.get("score", -1)) == strong_ledger_score,
		"Reputation ledger must explain the displayed score exactly")
	_check(int(weak.get("fuel", 0)) == 8 and int(weak.get("negative_total", 0)) \
		== int(weak.get("missed", 0)) + int(weak.get("fines", 0)) + int(weak.get("fuel", 0)) \
		+ int(weak.get("crash", 0)),
		"Fuel and service penalties must be included in the reputation ledger")
	_check(int(strong.get("crash", 0)) == 10,
		"A collision finish must reduce Driver Reputation")

func _check_first_session_flow() -> void:
	var save_data_before := SaveSystem.data.duplicate(true)
	var batch_depth_before := SaveSystem._batch_depth
	var batch_dirty_before := SaveSystem._batch_dirty
	SaveSystem.data = SaveScript.DEFAULTS.duplicate(true)
	SaveSystem._batch_depth = 1
	SaveSystem._batch_dirty = false
	_check(GameState.tutorial_stage_for_run(false) == 1,
		"A brand-new player must begin the first guided run")
	GameState.complete_tutorial_stage(1)
	_check(int(SaveSystem.data.first_session_stage) == 1,
		"Finishing the first lesson did not persist progress")
	_check(GameState.tutorial_stage_for_run(false) == 2,
		"The second guided run did not follow the first")
	SaveSystem.data["total_runs"] = 5
	SaveSystem.data["regular_runs"] = 5
	SaveSystem.data["first_session_stage"] = 0
	_check(GameState.tutorial_stage_for_run(false) == 0,
		"Existing players should not be forced into new onboarding")
	_check(GameState.tutorial_stage_for_run(true) == 0,
		"Rewarded continues must not restart a tutorial stage")
	SaveSystem.data = save_data_before
	SaveSystem._batch_depth = batch_depth_before
	SaveSystem._batch_dirty = batch_dirty_before

func _check_remote_tuning_guards() -> void:
	_check(RemoteConfigScript.REMOTE_URL.ends_with("/docs/remote-config.json"),
		"Hosted remote config URL must match its GitHub Pages docs path")
	var config := RemoteConfigScript.new()
	_check(RemoteConfigScript.REQUEST_TIMEOUT_SECONDS > 0.0
		and RemoteConfigScript.MAX_RESPONSE_BYTES >= 1024,
		"Remote config needs bounded network time and payload size")
	config._values = RemoteConfigScript.DEFAULTS.duplicate(true)
	config._values["fuel_drain_global"] = "invalid"
	_check(config.get_float("fuel_drain_global", 1.0, 0.6, 1.4) == 1.0,
		"Invalid global tuning should fall back safely")
	config._values["route_tuning"] = {"kariakoo": {"spawn": 4.0, "fuel": 0.8}}
	_check(config.get_route_float("kariakoo", "spawn", 1.0, 0.75, 1.5) == 1.5,
		"Route tuning must clamp unsafe spawn values")
	_check(config.get_route_float("kariakoo", "fuel", 1.0, 0.6, 1.4) == 0.8,
		"Valid route tuning should be readable")
	config._values = RemoteConfigScript.DEFAULTS.duplicate(true)
	_check(config._merge_config({
		"revision": 4,
		"event_banner": "QA route event",
		"unknown": 99,
		"route_tuning": {"kariakoo": {"passengers": 0.93, "not_a_tuning": 3}},
	}), "Valid hosted config should merge")
	_check(not config._values.has("unknown"),
		"Unknown hosted config keys must be discarded")
	_check(config.get_route_float("kariakoo", "passengers", 1.0, 0.8, 1.2) == 0.93,
		"New passenger cadence tuning should be readable")
	_check(not config._merge_config({"revision": 3, "event_banner": "stale"}),
		"Older remote config revisions must not replace current tuning")
	_check(String(config.get_value("event_banner", "")) == "QA route event",
		"Rejected stale config must leave the active config unchanged")
	_check(config.get_route_float("kariakoo", "not_a_tuning", 1.0, 0.8, 1.2) == 1.0,
		"Unknown route tuning keys must be discarded")
	var refresh_count: Array[int] = [0]
	config.config_updated.connect(func(): refresh_count[0] += 1)
	_check(config._apply_remote_payload({
		"revision": 5, "event_banner_en": "New route event",
	}), "New valid remote payload should apply")
	_check(refresh_count[0] == 1,
		"Applying remote config must notify open UI to refresh its live event banner")
	_check(not config._apply_remote_payload({
		"revision": 5.5, "event_banner_en": "Invalid revision",
	}), "Remote payload must reject a non-integer revision")
	_check(not config._apply_remote_payload({
		"revision": 4, "event_banner_en": "Stale event",
	}), "Remote payload must reject stale revisions")
	_check(not config._apply_remote_payload({
		"revision": "6", "event_banner_en": "Wrong type",
	}), "Remote config must reject a string revision")
	_check(not config._merge_config({
		"revision": 6, "route_tuning": [],
	}), "Malformed route tuning must not replace the current config")
	_check(not config._merge_config({
		"revision": 6, "unknown": {"unbounded": true},
	}), "Unknown-only payloads must be rejected")
	_check(String(config.get_value("event_banner_en", "")) == "New route event",
		"Rejected malformed payloads must leave the previous config intact")
	config.free()

func _check_pooled_entity_reset() -> void:
	var obstacle := ObstacleScript.new()
	add_child(obstacle)
	obstacle.setup("bodaboda", 100.0, 200.0)
	obstacle.warning_announced = true
	obstacle.scale = Vector2(2.0, 0.5)
	obstacle.rotation = 0.4
	obstacle.modulate = Color.RED
	obstacle.deactivate()
	obstacle.setup("car", 220.0, -300.0)
	_check(obstacle.active and obstacle.visible and not obstacle.warning_announced
		and obstacle.scale == Vector2.ONE and is_zero_approx(obstacle.rotation)
		and obstacle.modulate == Color.WHITE and obstacle.position == Vector2(220.0, -300.0),
		"Reused obstacles must reset visibility, warning state, transform, and color")
	var collectible := CollectibleScript.new()
	add_child(collectible)
	collectible.setup("coin", 100.0, 200.0)
	collectible.spin = 30.0
	collectible.scale = Vector2(0.5, 2.0)
	collectible.rotation = -0.3
	collectible.modulate = Color.RED
	collectible.deactivate()
	collectible.setup("fuel", 220.0, -300.0)
	_check(collectible.active and collectible.visible and is_zero_approx(collectible.spin)
		and collectible.scale == Vector2.ONE and is_zero_approx(collectible.rotation)
		and collectible.modulate == Color.WHITE and collectible.position == Vector2(220.0, -300.0),
		"Reused collectibles must reset animation state, transform, and color")
	obstacle.free()
	collectible.free()

func _check_selection_guards() -> void:
	var vehicle_before := GameState.selected_vehicle_id
	var route_before := GameState.selected_route_id
	_check(not GameState.set_vehicle("missing_vehicle"),
		"Unknown vehicle selection was accepted")
	_check(not GameState.set_route("missing_route"),
		"Unknown route selection was accepted")
	_check(GameState.selected_vehicle_id == vehicle_before,
		"Rejected vehicle changed the current selection")
	_check(GameState.selected_route_id == route_before,
		"Rejected route changed the current selection")

func _check_reward_idempotency() -> void:
	var save_data_before := SaveSystem.data.duplicate(true)
	var batch_depth_before := SaveSystem._batch_depth
	var batch_dirty_before := SaveSystem._batch_dirty
	var coins_before := GameState.last_coins
	var choice_before := GameState.rewarded_choice_used

	# Keep this contract entirely in memory; never rewrite a developer save.
	SaveSystem._batch_depth = 1
	SaveSystem._batch_dirty = false
	GameState.last_coins = 37
	GameState.rewarded_choice_used = ""
	var first_claim := GameState.claim_double_coins()
	var second_claim := GameState.claim_double_coins()
	_check(first_claim == 37 and second_claim == 0,
		"Double Coins must pay exactly once per run")
	_check(int(SaveSystem.data.total_coins) == int(save_data_before.total_coins) + 37,
		"Double Coins paid an incorrect amount")

	SaveSystem.data = save_data_before
	SaveSystem._batch_depth = batch_depth_before
	SaveSystem._batch_dirty = batch_dirty_before
	GameState.last_coins = coins_before
	GameState.rewarded_choice_used = choice_before

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _release_audio_for_headless_exit() -> void:
	# The real autoload is present in this project-mode test. Release generated
	# streams explicitly so Godot's immediate headless shutdown stays leak-free.
	if AudioManager._music_player == null:
		return
	AudioManager.stop_music()
	for player_value in AudioManager._sfx_players:
		var player := player_value as AudioStreamPlayer
		player.stop()
		player.stream = null
	AudioManager._music_player.stream = null
	AudioManager._music_stream = null
	AudioManager._sfx_streams.clear()
