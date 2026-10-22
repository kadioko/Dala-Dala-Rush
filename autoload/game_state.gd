extends Node
## Tracks selections that survive between scenes and the most recent run.

const Routes := preload("res://data/routes.gd")
const Vehicles := preload("res://data/vehicles.gd")
const DailyChallengesData := preload("res://data/daily_challenges.gd")
const DailyRouteChallengeData := preload("res://data/daily_route_challenge.gd")
const RouteContractsData := preload("res://data/route_contracts.gd")
const MissionsData := preload("res://data/missions.gd")

var selected_vehicle_id: String = "classic_blue"
var selected_route_id: String = "kariakoo"
var daily_route_challenge: Dictionary = {}

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
var last_route_contract: Dictionary = {}
var last_route_contract_met: bool = false
var last_route_contract_rewarded: bool = false
var last_route_contract_progress: String = ""
var last_route_contract_bonus_coins: int = 0
var last_missions_completed: Array = []
var last_end_reason: String = "unknown"
var last_reputation: int = 0
var last_reputation_grade: String = "C"
var last_reputation_breakdown: Dictionary = {}
var last_is_reputation_record: bool = false
var last_best_score_delta: int = 0
var last_discovery_key: String = ""
var last_mastery_stars: int = 0
var last_mastery_gained: int = 0
var last_mastery_bonus_coins: int = 0
var last_combo_peak: int = 0

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

## The first three fresh runs each introduce one core habit. A save created
## before this feature already has completed runs, so it is deliberately left
## alone instead of being pushed back into onboarding.
func tutorial_stage_for_run(is_continuing: bool = false) -> int:
	if is_continuing:
		return 0
	var completed_lessons: int = clampi(int(SaveSystem.get_value("first_session_stage", 0)), 0, 3)
	if completed_lessons == 0 and int(SaveSystem.get_value("regular_runs", 0)) > 0 \
	and not bool(SaveSystem.get_value("tutorial_started", false)):
		return 0
	return completed_lessons + 1 if completed_lessons < 3 else 0

func complete_tutorial_stage(stage: int, completed_steps: int = 2) -> void:
	if stage < 1 or stage > 3 or completed_steps < 2:
		return
	var completed_lessons: int = clampi(int(SaveSystem.get_value("first_session_stage", 0)), 0, 3)
	if stage > completed_lessons:
		SaveSystem.set_value("first_session_stage", stage)

func skip_tutorials() -> void:
	SaveSystem.begin_batch()
	SaveSystem.set_value("tutorial_started", true)
	SaveSystem.set_value("first_session_stage", 3)
	SaveSystem.end_batch()

func _ready() -> void:
	reload_profile()

func reload_profile() -> void:
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
	daily_route_challenge = {}
	SaveSystem.set_value("selected_vehicle", id)
	return true

func set_route(id: String) -> bool:
	var route := Routes.get_by_id(id)
	if String(route.id) != id or not Routes.is_unlocked(route):
		return false
	selected_route_id = id
	daily_route_challenge = {}
	SaveSystem.set_value("selected_route", id)
	AnalyticsService.log_event("route_selected", {"route": id})
	return true

func start_daily_route_challenge() -> Dictionary:
	daily_route_challenge = DailyRouteChallengeData.current()
	selected_route_id = String(daily_route_challenge.get("route_id", "kariakoo"))
	selected_vehicle_id = String(daily_route_challenge.get("vehicle_id", "classic_blue"))
	return daily_route_challenge.duplicate(true)

func is_daily_route_challenge_active() -> bool:
	return not daily_route_challenge.is_empty()

func finish_daily_route_challenge() -> void:
	daily_route_challenge = {}
	selected_vehicle_id = String(SaveSystem.get_value("selected_vehicle", "classic_blue"))
	selected_route_id = String(SaveSystem.get_value("selected_route", "kariakoo"))

## Called by game.gd when a brand-new run starts (not an ad-continue).
func begin_run() -> void:
	finalize_run()
	SaveSystem.set_value("active_run_id", preload("res://data/operation_ids.gd").create())
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
	if is_daily_route_challenge_active() or continue_used or not rewarded_choice_used.is_empty():
		return false
	continue_used = true
	rewarded_choice_used = "continue"
	var receipt: Dictionary = reward_receipt()
	receipt["choice"] = "continue"
	SaveSystem.set_value("last_reward_receipt", receipt)
	continue_pending = true
	continue_state = {
		"distance": last_distance,
		"bonus_score": last_bonus_score,
		"coins": last_coins,
		"passengers": last_passengers,
		"near_misses": last_near_misses,
		"dropoffs": last_dropoffs,
		"fares": last_fares,
		"combo_peak": last_combo_peak,
	}
	continue_state.merge(_last_resume_state, true)
	return true

## Grants the second copy of coins collected during this run. Keeping the
## claim here makes it atomic and prevents duplicate SDK callbacks or a later
## results scene from combining Double Coins with a rewarded revive.
func claim_double_coins() -> int:
	if not rewarded_choice_used.is_empty() or last_coins <= 0:
		return 0
	var receipt: Dictionary = reward_receipt()
	if not String(receipt.get("choice", "")).is_empty():
		return 0
	rewarded_choice_used = "double_coins"
	SaveSystem.begin_batch()
	SaveSystem.add_coins(last_coins)
	var components: Dictionary = receipt.get("components", {})
	components["ads"] = last_coins
	receipt["components"] = components
	receipt["choice"] = "double_coins"
	receipt["run_ref"] = active_run_id()
	receipt["total"] = int(receipt.get("total", 0)) + last_coins
	SaveSystem.set_value("last_reward_receipt", receipt)
	SaveSystem.end_batch()
	return last_coins

func active_run_id() -> String:
	var value: String = String(SaveSystem.get_value("active_run_id", ""))
	if value.is_empty():
		value = preload("res://data/operation_ids.gd").create()
		SaveSystem.set_value("active_run_id", value)
	return value

func reward_receipt() -> Dictionary:
	var receipt: Dictionary = SaveSystem.get_value("last_reward_receipt", {})
	return SaveSystem.clean_reward_receipt(receipt) if receipt.get("run_ref") == SaveSystem.get_value("active_run_id", "") else {}

func finalize_run() -> void:
	var receipt: Dictionary = reward_receipt()
	if receipt.is_empty() or bool(receipt.get("finalized", false)):
		return
	var summary: Dictionary = receipt.get("summary", {}).duplicate(true)
	if summary.is_empty(): return
	summary["run_ref"] = String(receipt.run_ref)
	summary["coins"] = int(receipt.get("total", 0))
	AnalyticsService.log_event("run_settled", summary, String(receipt.run_ref))
	AnalyticsService._save_log()
	if not AnalyticsService._log_dirty:
		receipt["finalized"] = true
		SaveSystem.set_value("last_reward_receipt", receipt)
	OnlineService.flush_telemetry()

func can_claim_rewarded_choice() -> bool:
	return not is_daily_route_challenge_active() and rewarded_choice_used.is_empty()

func record_run(score: int, coins: int, passengers: int, distance: float,
		near_misses: int = 0, extra: Dictionary = {}) -> void:
	var run_ref: String = active_run_id()
	var receipt: Dictionary = reward_receipt()
	var segment: String = "continued" if continue_used else "initial"
	var segments: Array = receipt.get("segments", [])
	if segment in segments:
		return
	SaveSystem.begin_batch()
	var wallet_before: int = int(SaveSystem.get_value("total_coins", 0))
	var previous_best_score: int = int(SaveSystem.get_value("best_score", 0))
	var previous_run_count: int = int(SaveSystem.get_value("total_runs", 0))
	last_score      = score
	last_bonus_score = maxi(0, score - int(distance * 0.1))
	last_coins      = coins
	last_dropoffs   = int(extra.get("dropoffs", 0))
	last_fares      = int(extra.get("fares", 0))
	last_bonus_coins = 0
	last_daily_bonus_coins = 0
	last_route_contract = {}
	last_route_contract_met = false
	last_route_contract_rewarded = false
	last_route_contract_progress = ""
	last_route_contract_bonus_coins = 0
	last_daily_challenge_met = false
	last_daily_challenge_rewarded = false
	last_mastery_gained = 0
	last_mastery_bonus_coins = 0
	last_combo_peak = clampi(int(extra.get("combo_peak", 0)), 0, 8)
	last_passengers = passengers
	last_distance   = distance
	last_near_misses = near_misses
	last_end_reason = String(extra.get("end_reason", "unknown"))
	last_discovery_key = ""
	_last_resume_state = {
		"onboard": int(extra.get("onboard", 0)),
		"fuel": float(extra.get("fuel", 0.6)),
		"elapsed": float(extra.get("elapsed", 0.0)),
		"horn_uses": int(extra.get("horn_uses", 0)),
		"boosts": int(extra.get("boosts", 0)),
		"clean_checkpoints": int(extra.get("clean_checkpoints", 0)),
		"route_moments": int(extra.get("route_moments", 0)),
		"horn_charges": int(extra.get("horn_charges", 0)),
		"max_horn_charges": int(extra.get("max_horn_charges", 3)),
		"horn_regen_timer": float(extra.get("horn_regen_timer", 0.0)),
		"fuel_drain_mult": float(extra.get("fuel_drain_mult", 1.0)),
		"missed_stops": int(extra.get("missed_stops", 0)),
		"fines": int(extra.get("fines", 0)),
		"fines_paid": int(extra.get("fines_paid", 0)),
		"chase_coins": int(extra.get("chase_coins", 0)),
		"combo_peak": last_combo_peak,
		"condition": String(extra.get("condition", "day")),
		"rush_hour": bool(extra.get("rush_hour", false)),
	}
	last_is_new_record   = SaveSystem.update_best_score(score)
	last_is_route_record = SaveSystem.update_route_best(selected_route_id, score)
	last_best_score_delta = maxi(0, score - previous_best_score) if last_is_new_record else 0

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
		"clean_checkpoints": int(extra.get("clean_checkpoints", 0)),
		"route_moments": int(extra.get("route_moments", 0)),
	}
	last_route_goal_key = String(route.get("goal_key", ""))
	last_route_goal_progress = Routes.goal_progress(route, stats)
	last_route_goal_met = Routes.is_goal_met(route, stats)
	if last_route_goal_met and not _goal_rewarded:
		_goal_rewarded = true
		last_bonus_coins = int(route.get("goal_reward", 0))
		SaveSystem.add_route_goal_completion(selected_route_id)

	last_reputation_breakdown = calculate_reputation({
		"passengers": passengers,
		"dropoffs": last_dropoffs,
		"near_misses": near_misses,
		"goal_met": last_route_goal_met,
		"clean_checkpoints": int(extra.get("clean_checkpoints", 0)),
		"route_moments": int(extra.get("route_moments", 0)),
		"missed_stops": int(extra.get("missed_stops", 0)),
		"fines": int(extra.get("fines", 0)),
		"end_reason": last_end_reason,
	})
	last_reputation = int(last_reputation_breakdown.get("score", 0))
	last_reputation_grade = String(last_reputation_breakdown.get("grade", "C"))
	last_is_reputation_record = SaveSystem.update_best_reputation(last_reputation)
	stats["reputation"] = last_reputation
	var mastery_before: int = SaveSystem.get_route_mastery(selected_route_id)
	var mastery_attained: int = Routes.mastery_stars(route, stats)
	last_mastery_stars = maxi(mastery_before, mastery_attained)
	last_mastery_gained = SaveSystem.update_route_mastery(selected_route_id, mastery_attained)
	if last_mastery_gained > 0:
		last_mastery_bonus_coins = Routes.mastery_reward(route, mastery_before, last_mastery_stars)
		AnalyticsService.log_event("route_mastery_earned", {
			"route": selected_route_id,
			"stars": last_mastery_stars,
			"gained": last_mastery_gained,
			"reward": last_mastery_bonus_coins,
		})
	_queue_progress_discovery(int(extra.get("tutorial_stage", 0)), previous_run_count)

	var daily := DailyChallengesData.current()
	last_daily_challenge_key = String(daily.get("key", ""))
	last_daily_challenge_progress = DailyChallengesData.progress(daily, stats)
	last_daily_challenge_met = DailyChallengesData.is_met(daily, stats)
	if last_daily_challenge_met and not DailyChallengesData.is_completed_today():
		last_daily_bonus_coins = int(daily.get("reward", 0))
		last_daily_challenge_rewarded = true
		DailyChallengesData.mark_completed_today()

	if RouteContractsData.is_available(selected_route_id):
		last_route_contract = RouteContractsData.current(selected_route_id)
		last_route_contract_progress = RouteContractsData.progress(last_route_contract, stats)
		last_route_contract_met = RouteContractsData.is_met(last_route_contract, stats)
		if last_route_contract_met and RouteContractsData.mark_completed(selected_route_id):
			last_route_contract_rewarded = true
			last_route_contract_bonus_coins = int(last_route_contract.get("reward", 0))
			AnalyticsService.log_event("route_contract_completed", {
				"route": selected_route_id,
				"reward": last_route_contract_bonus_coins,
			})

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
	var mission_coins: int = 0
	for mission in last_missions_completed:
		mission_coins += int(mission.reward)
	var season_coins: int = int(SaveSystem.get_value("total_coins", 0)) - wallet_before - mission_coins
	_banked_misc = {
		"near_misses": near_misses,
		"dropoffs": last_dropoffs,
		"fares": last_fares,
		"horn_uses": int(extra.get("horn_uses", 0)),
		"boosts": int(extra.get("boosts", 0)),
	}

	# Only credit the delta beyond what was already banked at an earlier
	# crash in this same run (ad-continue case).
	var new_coins: int = coins - _banked_coins
	var new_distance: float = max(0.0, distance - _banked_distance)
	var new_passengers: int = max(0, passengers - _banked_passengers)
	var earned_coins := new_coins + last_bonus_coins + last_daily_bonus_coins \
		+ last_mastery_bonus_coins + last_route_contract_bonus_coins
	if earned_coins >= 0:
		SaveSystem.add_coins(earned_coins)
	else:
		SaveSystem.spend_coins(-earned_coins)
	SaveSystem.add_run_stats(new_distance, maxi(0, earned_coins), new_passengers, not _run_counted,
		bool(extra.get("daily_route", false)))
	var components: Dictionary = receipt.get("components", {})
	var fines_paid: int = int(extra.get("fines_paid", 0))
	var other_coins: int = int(extra.get("chase_coins", 0))
	components["pickups"] = maxi(0, coins + fines_paid - last_fares - other_coins)
	components["fares"] = last_fares
	components["other"] = other_coins
	components["fines"] = -fines_paid
	var bonuses: Dictionary = {"route_goal": last_bonus_coins, "missions": mission_coins,
		"season": season_coins, "mastery": last_mastery_bonus_coins,
		"daily": last_daily_bonus_coins, "contract": last_route_contract_bonus_coins}
	for key in bonuses:
		components[key] = int(components.get(key, 0)) + int(bonuses[key])
	var receipt_total: int = 0
	for amount in components.values(): receipt_total += int(amount)
	segments.append(segment)
	receipt.merge({"run_ref": run_ref, "components": components, "total": receipt_total,
		"segments": segments, "finalized": false, "summary": {"route": selected_route_id,
		"score": score, "distance": distance, "elapsed": float(extra.get("elapsed", 0.0)),
		"end_reason": last_end_reason, "goal_met": last_route_goal_met, "continued": continue_used}}, true)
	SaveSystem.set_value("last_reward_receipt", receipt)

	_banked_coins = coins
	_banked_distance = distance
	_banked_passengers = passengers
	_run_counted = true
	SaveSystem.end_batch()
	AnalyticsService.log_event("run_reputation", {
		"score": last_reputation,
		"grade": last_reputation_grade,
		"goal_met": last_route_goal_met,
		"route": selected_route_id,
	})

## Show one durable discovery per result screen. Conditions are intentionally
## re-evaluated on later runs so a higher-priority discovery never erases a
## lower-priority milestone that happened in the same run.
func _queue_progress_discovery(completed_tutorial_stage: int, previous_runs: int) -> void:
	var candidates: Array[String] = []
	if completed_tutorial_stage == 3:
		candidates.append("DISCOVERY_FULL_CITY")
	if Routes.is_unlocked(Routes.get_by_id("mwenge")):
		candidates.append("DISCOVERY_MWENGE")
	if last_mastery_gained > 0:
		candidates.append("DISCOVERY_MASTERY")
	# These messages arrive immediately before their systems can appear next run.
	if previous_runs >= 3:
		candidates.append("DISCOVERY_WEATHER")
	if previous_runs >= 4:
		candidates.append("DISCOVERY_GHOST")
	if previous_runs >= 5:
		candidates.append("DISCOVERY_POLICE")
	for key in candidates:
		if SaveSystem.mark_discovery_seen(key):
			last_discovery_key = key
			AnalyticsService.log_event("feature_discovery", {"key": key})
			return

## A simple service-quality score that rewards route craft without becoming a
## second currency. Its pure data shape keeps it easy to rebalance remotely
## later and straightforward to contract-test now.
func calculate_reputation(stats: Dictionary) -> Dictionary:
	const BASE_SCORE := 50
	var dropoff_points: int = mini(24, maxi(0, int(stats.get("dropoffs", 0))) * 3)
	var passenger_points: int = mini(10, maxi(0, int(stats.get("passengers", 0))))
	var near_miss_points: int = mini(12, maxi(0, int(stats.get("near_misses", 0))) * 2)
	var goal_points: int = 12 if bool(stats.get("goal_met", false)) else 0
	var checkpoint_points: int = mini(12, maxi(0, int(stats.get("clean_checkpoints", 0))) * 4)
	var moment_points: int = mini(8, maxi(0, int(stats.get("route_moments", 0))) * 4)
	var missed_penalty: int = mini(21, maxi(0, int(stats.get("missed_stops", 0))) * 7)
	var fine_penalty: int = mini(20, maxi(0, int(stats.get("fines", 0))) * 5)
	var finish_penalty: int = 8 if String(stats.get("end_reason", "unknown")) == "fuel" else 0
	var crash_penalty: int = 10 if String(stats.get("end_reason", "unknown")) in ["car", "bodaboda", "bajaji", "truck", "pothole", "barrier", "cone", "tire", "pedestrian", "mbuzi", "police"] else 0
	var positive_total: int = dropoff_points + passenger_points + near_miss_points \
		+ goal_points + checkpoint_points + moment_points
	var negative_total: int = missed_penalty + fine_penalty + finish_penalty + crash_penalty
	var score: int = clampi(BASE_SCORE + positive_total - negative_total, 0, 100)
	var grade: String = "A" if score >= 85 else ("B" if score >= 70 else ("C" if score >= 50 else "D"))
	return {
		"score": score,
		"grade": grade,
		"base": BASE_SCORE,
		"positive_total": positive_total,
		"negative_total": negative_total,
		"dropoffs": dropoff_points,
		"passengers": passenger_points,
		"near_misses": near_miss_points,
		"goal": goal_points,
		"checkpoints": checkpoint_points,
		"moments": moment_points,
		"missed": missed_penalty,
		"fines": fine_penalty,
		"fuel": finish_penalty,
		"crash": crash_penalty,
	}
