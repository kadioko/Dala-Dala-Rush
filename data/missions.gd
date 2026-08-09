class_name Missions
## Three always-active rotating missions + season XP track.
## Progress accumulates across runs; completing a mission grants coins
## and season XP, then the next template from the pool rotates in.
## All state persists via SaveSystem ("missions_active", "missions_next",
## "missions_completed", "season_xp").

const TEMPLATES: Array = [
	{"id": "m_coins_40",     "key": "MIS_COINS",      "type": "coins",       "target": 40,   "reward": 30, "xp": 20},
	{"id": "m_drop_8",       "key": "MIS_DROPOFFS",   "type": "dropoffs",    "target": 8,    "reward": 40, "xp": 25},
	{"id": "m_near_12",      "key": "MIS_NEAR",       "type": "near_misses", "target": 12,   "reward": 35, "xp": 20},
	{"id": "m_pass_15",      "key": "MIS_PASS",       "type": "passengers",  "target": 15,   "reward": 35, "xp": 20},
	{"id": "m_dist_5000",    "key": "MIS_DIST",       "type": "distance",    "target": 5000, "reward": 45, "xp": 30},
	{"id": "m_horn_6",       "key": "MIS_HORN",       "type": "horn_uses",   "target": 6,    "reward": 25, "xp": 15},
	{"id": "m_boost_3",      "key": "MIS_BOOST",      "type": "boosts",      "target": 3,    "reward": 30, "xp": 20},
	{"id": "m_fares_60",     "key": "MIS_FARES",      "type": "fares",       "target": 60,   "reward": 50, "xp": 30},
	{"id": "m_score_1200",   "key": "MIS_SCORE",      "type": "score_best",  "target": 1200, "reward": 50, "xp": 35},
	{"id": "m_coins_100",    "key": "MIS_COINS",      "type": "coins",       "target": 100,  "reward": 60, "xp": 40},
	{"id": "m_drop_20",      "key": "MIS_DROPOFFS",   "type": "dropoffs",    "target": 20,   "reward": 70, "xp": 45},
	{"id": "m_dist_12000",   "key": "MIS_DIST",       "type": "distance",    "target": 12000,"reward": 80, "xp": 50},
]

const ACTIVE_COUNT := 3
const XP_PER_LEVEL := 120

# ─── Active mission state ─────────────────────────────────────────

static func get_active() -> Array:
	var active: Array = SaveSystem.get_value("missions_active", [])
	if active.size() < ACTIVE_COUNT:
		SaveSystem.begin_batch()
		var next_idx := int(SaveSystem.get_value("missions_next", 0))
		while active.size() < ACTIVE_COUNT:
			active.append({"tid": TEMPLATES[next_idx % TEMPLATES.size()].id, "progress": 0})
			next_idx += 1
		SaveSystem.set_value("missions_next", next_idx)
		SaveSystem.set_value("missions_active", active)
		SaveSystem.end_batch()
	return active

static func template(tid: String) -> Dictionary:
	for t in TEMPLATES:
		if t.id == tid:
			return t
	return TEMPLATES[0]

## Apply one run's stats. Returns array of completed template dicts.
static func update_from_run(stats: Dictionary) -> Array:
	SaveSystem.begin_batch()
	var active := get_active()
	var completed: Array = []
	var next_idx := int(SaveSystem.get_value("missions_next", 0))

	for m in active:
		var t := template(String(m.tid))
		var mtype := String(t.type)
		if mtype == "score_best":
			m.progress = max(int(m.progress), int(stats.get("score", 0)))
		else:
			m.progress = int(m.progress) + int(stats.get(mtype, 0))
		if int(m.progress) >= int(t.target):
			completed.append(t)
			SaveSystem.add_coins(int(t.reward))
			add_season_xp(int(t.xp))
			SaveSystem.set_value("missions_completed",
				int(SaveSystem.get_value("missions_completed", 0)) + 1)
			# Rotate in the next template
			m.tid = TEMPLATES[next_idx % TEMPLATES.size()].id
			m.progress = 0
			next_idx += 1

	SaveSystem.set_value("missions_next", next_idx)
	SaveSystem.set_value("missions_active", active)
	SaveSystem.end_batch()
	return completed

# ─── Season track ─────────────────────────────────────────────────

static func season_xp() -> int:
	return int(SaveSystem.get_value("season_xp", 0))

static func season_level() -> int:
	return season_xp() / XP_PER_LEVEL + 1

static func season_progress() -> float:
	return float(season_xp() % XP_PER_LEVEL) / float(XP_PER_LEVEL)

## Adds XP; pays out level-up coin rewards automatically.
static func add_season_xp(amount: int) -> void:
	SaveSystem.begin_batch()
	var before := season_level()
	SaveSystem.set_value("season_xp", season_xp() + amount)
	var after := season_level()
	if after > before:
		SaveSystem.add_coins(30 * after)
	SaveSystem.end_batch()

static func describe(t: Dictionary) -> String:
	return LocaleManager.t(String(t.key)).replace("{n}", str(int(t.target)))
