extends Node
## Headless data-contract checks. Run with:
## godot --headless --path . res://tests/logic_contracts.tscn

const RoutesData := preload("res://data/routes.gd")
const VehiclesData := preload("res://data/vehicles.gd")
const MissionsData := preload("res://data/missions.gd")
const GhostDataLib := preload("res://data/ghost_data.gd")
const SaveScript := preload("res://autoload/save_system.gd")
const LocaleScript := preload("res://autoload/locale_manager.gd")
const AchievementScript := preload("res://autoload/achievement_manager.gd")
const GameScript := preload("res://scripts/game.gd")
const ReferralsData := preload("res://data/referrals.gd")

const OBSTACLE_IDS := [
	"bodaboda", "bajaji", "car", "pothole", "cone", "police",
	"barrier", "truck", "pedestrian", "tire", "mbuzi",
]
const COLLECTIBLE_IDS := [
	"coin", "passenger", "fuel", "shield", "magnet", "speed_boost", "slow",
]
const GOAL_TYPES := ["score", "coins", "distance", "near_misses", "passengers"]
const MISSION_TYPES := [
	"coins", "dropoffs", "near_misses", "passengers", "distance",
	"horn_uses", "boosts", "fares", "score_best",
]

var _failures: Array[String] = []

func _ready() -> void:
	_check_locales()
	_check_launch_copy()
	_check_routes()
	_check_vehicles()
	_check_missions()
	_check_achievements()
	_check_ghost_validation()
	_check_referrals()
	_check_referral_reward_idempotency()
	_check_distance_scale()
	_check_save_normalization()
	_check_selection_guards()
	_check_reward_idempotency()
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
	locale_node.free()

func _check_routes() -> void:
	var ids: Dictionary = {}
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
		_check_weights(id, route.get("obstacle_weights", {}), OBSTACLE_IDS)
		_check_weights(id, route.get("collectible_weights", {}), COLLECTIBLE_IDS)
	_check(ids.has("kariakoo"), "Starter route kariakoo must exist")

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
	}
	_check(not GhostDataLib.sanitize(valid).is_empty(), "Valid ghost was rejected")
	var encoded := GhostDataLib.encode(valid)
	_check(not encoded.is_empty(), "Valid ghost could not be encoded")
	_check(not GhostDataLib.decode(encoded).is_empty(), "Ghost round-trip failed")
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

func _check_save_normalization() -> void:
	var save_node := SaveScript.new()
	save_node.data = SaveScript.DEFAULTS.duplicate(true)
	save_node.data["schema_version"] = 2
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
	save_node.call("_normalize_core_data")
	_check(int(save_node.data.schema_version) == 3, "Old save schema was not migrated")
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
	save_node.free()

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
