class_name LoginStreak
## Offline daily login streak. No network or account required.
## Call claim_today() once when the main menu opens:
## returns {"streak": int, "reward": int, "claimed_now": bool}.
## Reward scales with streak length, capped at MAX_REWARD.

const BASE_REWARD := 10
const PER_DAY_BONUS := 10
const MAX_REWARD := 60

static func today_key() -> String:
	return Time.get_date_string_from_system(false)

static func _day_number(date_str: String) -> int:
	if date_str == "":
		return -10
	var unix := Time.get_unix_time_from_datetime_string(date_str + "T00:00:00")
	return int(unix / 86400)

static func reward_for(streak: int) -> int:
	return min(MAX_REWARD, BASE_REWARD + (streak - 1) * PER_DAY_BONUS)

static func claim_today() -> Dictionary:
	var today := today_key()
	var last := String(SaveSystem.get_value("streak_last_date", ""))
	var streak := int(SaveSystem.get_value("streak_count", 0))

	if last == today:
		return {"streak": streak, "reward": 0, "claimed_now": false}

	var gap := _day_number(today) - _day_number(last)
	streak = streak + 1 if gap == 1 else 1

	SaveSystem.begin_batch()
	SaveSystem.set_value("streak_last_date", today)
	SaveSystem.set_value("streak_count", streak)

	var reward := reward_for(streak)
	SaveSystem.add_coins(reward)

	if streak >= 3:
		AchievementManager.try_unlock("streak_3")
	SaveSystem.end_batch()

	return {"streak": streak, "reward": reward, "claimed_now": true}
