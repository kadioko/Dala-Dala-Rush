class_name Career
## Career ladder: from konda (conductor) to king of the road.
## XP derives from lifetime stats, so it back-fills for existing players.
## Bus upgrades (engine / brakes / sound system) are permanent coin sinks.

const RANKS: Array = [
	{"key": "RANK_0", "xp": 0},      # Konda
	{"key": "RANK_1", "xp": 300},    # Dereva Mwanafunzi
	{"key": "RANK_2", "xp": 900},    # Dereva
	{"key": "RANK_3", "xp": 2000},   # Dereva Mzoefu
	{"key": "RANK_4", "xp": 4000},   # Bosi wa Njia
	{"key": "RANK_5", "xp": 7500},   # Mfalme wa Barabara
]

const UPGRADES: Array = [
	{"id": "upg_engine", "key": "UPG_ENGINE", "desc_key": "UPG_ENGINE_D",
		"icon": "🔧", "costs": [200, 500, 1100]},
	{"id": "upg_brakes", "key": "UPG_BRAKES", "desc_key": "UPG_BRAKES_D",
		"icon": "🛞", "costs": [150, 400, 900]},
	{"id": "upg_sound", "key": "UPG_SOUND", "desc_key": "UPG_SOUND_D",
		"icon": "🔊", "costs": [180, 450, 1000]},
]

static func career_xp() -> int:
	var ach_count: int = (SaveSystem.get_value("achievements", []) as Array).size()
	return int(SaveSystem.get_value("total_coins_ever", 0)) \
		+ int(SaveSystem.get_value("total_passengers_ever", 0)) * 3 \
		+ int(SaveSystem.get_value("route_goals_completed", 0)) * 50 \
		+ int(SaveSystem.get_value("missions_completed", 0)) * 40 \
		+ int(SaveSystem.get_value("daily_challenges_completed", 0)) * 30 \
		+ ach_count * 60

static func rank_index(xp: int = -1) -> int:
	if xp < 0:
		xp = career_xp()
	var idx := 0
	for i in range(RANKS.size()):
		if xp >= int(RANKS[i].xp):
			idx = i
	return idx

static func rank_key(idx: int = -1) -> String:
	if idx < 0:
		idx = rank_index()
	return String(RANKS[clampi(idx, 0, RANKS.size() - 1)].key)

## Progress toward the next rank, 1.0 when at max rank.
static func rank_progress() -> float:
	var xp := career_xp()
	var idx := rank_index(xp)
	if idx >= RANKS.size() - 1:
		return 1.0
	var lo := int(RANKS[idx].xp)
	var hi := int(RANKS[idx + 1].xp)
	return float(xp - lo) / float(hi - lo)

## Detects a rank-up since last check; pays the reward. Call from the menu.
## Returns {} when no rank-up happened.
static func check_rank_up() -> Dictionary:
	var current := rank_index()
	var stored := int(SaveSystem.get_value("career_rank", 0))
	if current <= stored:
		return {}
	SaveSystem.begin_batch()
	SaveSystem.set_value("career_rank", current)
	var reward := 50 * current
	SaveSystem.add_coins(reward)
	SaveSystem.end_batch()
	return {"rank": current, "key": rank_key(current), "reward": reward}

# ─── Upgrades ─────────────────────────────────────────────────────

static func upgrade_level(id: String) -> int:
	return int(SaveSystem.get_value(id, 0))

static func upgrade_cost(id: String) -> int:
	for u in UPGRADES:
		if u.id == id:
			var lvl := upgrade_level(id)
			var costs: Array = u.costs
			if lvl >= costs.size():
				return -1  # maxed
			return int(costs[lvl])
	return -1

static func buy_upgrade(id: String) -> bool:
	var cost := upgrade_cost(id)
	if cost < 0:
		return false
	SaveSystem.begin_batch()
	if not SaveSystem.spend_coins(cost):
		SaveSystem.end_batch()
		return false
	SaveSystem.set_value(id, upgrade_level(id) + 1)
	SaveSystem.end_batch()
	return true
