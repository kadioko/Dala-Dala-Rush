extends Node
## Tracks selections that survive between scenes and the most recent run.

const Routes := preload("res://data/routes.gd")
const DailyChallengesData := preload("res://data/daily_challenges.gd")

var selected_vehicle_id: String = "classic_blue"
var selected_route_id: String = "kariakoo"

# Last completed run — read by GameOver and Leaderboard.
var last_score: int = 0
var last_coins: int = 0
var last_bonus_coins: int = 0
var last_passengers: int = 0
var last_distance: float = 0.0
var last_near_misses: int = 0
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

func _ready() -> void:
	selected_vehicle_id = SaveSystem.get_value("selected_vehicle", "classic_blue")
	selected_route_id   = SaveSystem.get_value("selected_route", "kariakoo")

func set_vehicle(id: String) -> void:
	selected_vehicle_id = id
	SaveSystem.set_value("selected_vehicle", id)

func set_route(id: String) -> void:
	selected_route_id = id
	SaveSystem.set_value("selected_route", id)

func record_run(score: int, coins: int, passengers: int, distance: float, near_misses: int = 0) -> void:
	last_score      = score
	last_coins      = coins
	last_bonus_coins = 0
	last_daily_bonus_coins = 0
	last_daily_challenge_met = false
	last_daily_challenge_rewarded = false
	last_passengers = passengers
	last_distance   = distance
	last_near_misses = near_misses
	last_is_new_record   = SaveSystem.update_best_score(score)
	last_is_route_record = SaveSystem.update_route_best(selected_route_id, score)

	var route := Routes.get_by_id(selected_route_id)
	var stats := {
		"score": score,
		"coins": coins,
		"passengers": passengers,
		"distance": distance,
		"near_misses": near_misses,
	}
	last_route_goal_key = String(route.get("goal_key", ""))
	last_route_goal_progress = Routes.goal_progress(route, stats)
	last_route_goal_met = Routes.is_goal_met(route, stats)
	if last_route_goal_met:
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

	var earned_coins := coins + last_bonus_coins + last_daily_bonus_coins
	SaveSystem.add_coins(earned_coins)
	SaveSystem.add_run_stats(distance, earned_coins, passengers)
