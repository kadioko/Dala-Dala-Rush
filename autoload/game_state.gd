extends Node
## Tracks selections that survive between scenes and the most recent run.

const Routes := preload("res://data/routes.gd")
const Vehicles := preload("res://data/vehicles.gd")
const DailyChallengesData := preload("res://data/daily_challenges.gd")
const MissionsData := preload("res://data/missions.gd")

var selected_vehicle_id: String = "classic_blue"
var selected_route_id: String = "kariakoo"

# Last completed run — read by GameOver and Leaderboard.
var last_score: int = 0
var last_bonus_score: int = 0
var last_coins: int = 0
var last_bonus_coins: int = 0
var last_passengers: int = 0
var last_distance: float = 0.0
var last_near_misses: int = 0
var last_dropoffs: int = 0
var last_fares: int = 0
var last_is_new_record: bool = false
var last_is_route_record: bool = false
var last_route_goal_met: bool = false
var last_route_goal_key: String = ""
var last_route_goal_progress: String = ""
var last_daily_challenge_met: bool = false
var last_daily_challenge_rewarded: bool = false
var last_daily_challenge_key: String = ""
var last_daily_challenge_progress: String = ""
var last_daily_bonus_coins: int = 0
var last_missions_completed: Array = []
var last_end_reason: String = "unknown"

# ── Continue-after-crash (rewarded ad) ───────────────────────────
# When continue_pending is true, game.gd restores this state instead
# of starting a fresh run.
var continue_pending: bool = false
var continue_state: Dictionary = {}
var continue_used: bool = false
var rewarded_choice_used: String = ""
var _last_resume_state: Dictionary = {}

# Banked totals already credited to the save during this run
# (prevents double-counting when a run is continued after a crash).
var _banked_coins: int = 0
var _banked_distance: float = 0.0
var _banked_passengers: int = 0
var _banked_misc: Dictionary = {}    # near_misses/dropoffs/fares/horn_uses/boosts
var _run_counted: bool = false
var _goal_rewarded: bool = false

func _ready() -> void:
	selected_vehicle_id = String(SaveSystem.get_value("selected_vehicle", "classic_blue"))
	selected_route_id   = String(SaveSystem.get_value("selected_route", "kariakoo"))
	_migrate_route_unlocks()
	_validate_selections()

## Grandfather existing players: any route already played stays unlocked.
func _migrate_route_unlocks() -> void:
	SaveSystem.begin_batch()
	for r in Routes.LIST:
		var rid := String(r.id)
		if SaveSystem.get_route_best(rid) > 0 and not SaveSystem.is_route_unlocked(rid):
			SaveSystem.unlock_route(rid)
	SaveSystem.end_batch()

func _validate_selections() -> void:
	var vehicle := Vehicles.get_by_id(selected_vehicle_id)
	if String(vehicle.id) != selected_vehicle_id \
		or not SaveSystem.is_vehicle_unlocked(selected_vehicle_id):
		set_vehicle("classic_blue")
	var route := Routes.get_by_id(selected_route_id)
	if String(route.id) != selected_route_id or not Routes.is_unlocked(route):
		set_route("kariakoo")

func set_vehicle(id: String) -> bool:
	var vehicle := Vehicles.get_by_id(id)
	if String(vehicle.id) != id or not SaveSystem.is_vehicle_unlocked(id):
		return false
	selected_vehicle_id = id
	SaveSystem.set_value("selected_vehicle", id)
	return true

func set_route(id: String) -> bool:
	var route := Routes.get_by_id(id)
	if String(route.id) != id or not Routes.is_unlocked(route):
		return false
	selected_route_id = id
	SaveSystem.set_value("selected_route", id)
	return true

## Called by game.gd when a brand-new run starts (not an ad-continue).
func begin_run() -> void:
	continue_pending = false
	continue_state = {}
	continue_used = false
	rewarded_choice_used = ""
	_last_resume_state = {}
	_banked_coins = 0
	_banked_distance = 0.0
	_banked_passengers = 0
	_banked_misc = {}
	_run_counted = false
	_goal_rewarded = false

## Called by GameOver when the player watches a rewarded ad to continue.
func request_continue() -> bool:
	if continue_used or not rewarded_choice_used.is_empty():
		return false
	continue_used = true
	rewarded_choice_used = "continue"
	continue_pending = true
	continue_state = {
		"distance": last_distance,
		"bonus_score": last_bonus_score,
		"coins": last_coins,
		"passengers": last_passengers,
		"near_misses": last_near_misses,
		"dropoffs": last_dropoffs,
		"fares": last_fares,
	}
	continue_state.merge(_last_resume_state, true)
	return true

## Grants the second copy of coins collected during this run. Keeping the
## claim here makes it atomic and prevents duplicate SDK callbacks or a later
## results scene from combining Double Coins with a rewarded revive.
func claim_double_coins() -> int:
	if not rewarded_choice_used.is_empty() or last_coins <= 0:
		return 0
	rewarded_choice_used = "double_coins"
	SaveSystem.add_coins(last_coins)
	return last_coins

func can_claim_rewarded_choice() -> bool:
	return rewarded_choice_used.is_empty()

func record_run(score: int, coins: int, passengers: int, distance: float,
		near_misses: int = 0, extra: Dictionary = {}) -> void:
	SaveSystem.begin_batch()
	last_score      = score
	last_bonus_score = maxi(0, score - int(distance * 0.1))
	last_coins      = coins
	last_dropoffs   = int(extra.get("dropoffs", 0))
	last_fares      = int(extra.get("fares", 0))
	last_bonus_coins = 0
	last_daily_bonus_coins = 0
	last_daily_challenge_met = false
	last_daily_challenge_rewarded = false
	last_passengers = passengers
	last_distance   = distance
	last_near_misses = near_misses
	last_end_reason = String(extra.get("end_reason", "unknown"))
	_last_resume_state = {
		"onboard": int(extra.get("onboard", 0)),
		"fuel": float(extra.get("fuel", 0.6)),
		"elapsed": float(extra.get("elapsed", 0.0)),
		"horn_uses": int(extra.get("horn_uses", 0)),
		"boosts": int(extra.get("boosts", 0)),
		"horn_charges": int(extra.get("horn_charges", 0)),
		"max_horn_charges": int(extra.get("max_horn_charges", 3)),
		"horn_regen_timer": float(extra.get("horn_regen_timer", 0.0)),
		"fuel_drain_mult": float(extra.get("fuel_drain_mult", 1.0)),
		"condition": String(extra.get("condition", "day")),
		"rush_hour": bool(extra.get("rush_hour", false)),
	}
	last_is_new_record   = SaveSystem.update_best_score(score)
	last_is_route_record = SaveSystem.update_route_best(selected_route_id, score)

	var route := Routes.get_by_id(selected_route_id)
	var stats := {
		"score": score,
		"coins": coins,
		"passengers": passengers,
		"distance": distance,
		"near_misses": near_misses,
		"dropoffs": last_dropoffs,
		"fares": last_fares,
		"horn_uses": int(extra.get("horn_uses", 0)),
		"boosts": int(extra.get("boosts", 0)),
	}
	last_route_goal_key = String(route.get("goal_key", ""))
	last_route_goal_progress = Routes.goal_progress(route, stats)
	last_route_goal_met = Routes.is_goal_met(route, stats)
	if last_route_goal_met and not _goal_rewarded:
		_goal_rewarded = true
		last_bonus_coins = int(route.get("goal_reward", 0))
		SaveSystem.add_route_goal_completion(selected_route_id)

	var daily := DailyChallengesData.current()
	last_daily_challenge_key = String(daily.get("key", ""))
	last_daily_challenge_progress = DailyChallengesData.progress(daily, stats)
	last_daily_challenge_met = DailyChallengesData.is_met(daily, stats)
	if last_daily_challenge_met and not DailyChallengesData.is_completed_today():
		last_daily_bonus_coins = int(daily.get("reward", 0))
		last_daily_challenge_rewarded = true
		DailyChallengesData.mark_completed_today()

	# Missions consume only the delta of this run segment (continue-safe).
	var mission_stats := {
		"score": score,
		"coins": max(0, coins - _banked_coins),
		"passengers": max(0, passengers - _banked_passengers),
		"distance": max(0.0, distance - _banked_distance),
		"near_misses": max(0, near_misses - int(_banked_misc.get("near_misses", 0))),
		"dropoffs": max(0, last_dropoffs - int(_banked_misc.get("dropoffs", 0))),
		"fares": max(0, last_fares - int(_banked_misc.get("fares", 0))),
		"horn_uses": max(0, int(extra.get("horn_uses", 0)) - int(_banked_misc.get("horn_uses", 0))),
		"boosts": max(0, int(extra.get("boosts", 0)) - int(_banked_misc.get("boosts", 0))),
	}
	last_missions_completed = MissionsData.update_from_run(mission_stats)
	_banked_misc = {
		"near_misses": near_misses,
		"dropoffs": last_dropoffs,
		"fares": last_fares,
		"horn_uses": int(extra.get("horn_uses", 0)),
		"boosts": int(extra.get("boosts", 0)),
	}

	# Only credit the delta beyond what was already banked at an earlier
	# crash in this same run (ad-continue case).
	var new_coins: int = max(0, coins - _banked_coins)
	var new_distance: float = max(0.0, distance - _banked_distance)
	var new_passengers: int = max(0, passengers - _banked_passengers)
	var earned_coins := new_coins + last_bonus_coins + last_daily_bonus_coins
	SaveSystem.add_coins(earned_coins)
	SaveSystem.add_run_stats(new_distance, earned_coins, new_passengers, not _run_counted)

	_banked_coins = coins
	_banked_distance = distance
	_banked_passengers = passengers
	_run_counted = true
	SaveSystem.end_batch()
