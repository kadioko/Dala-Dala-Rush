class_name SeasonTracks
## Persistent season chapters layered onto the existing XP track.
## Chapters do not expire or reset, so offline players never lose progress.

const CHAPTERS: Array[Dictionary] = [
	{"first_level": 1, "last_level": 4, "name_key": "SEASON_CHAPTER_DAR", "milestone": 4, "bonus_coins": 75},
	{"first_level": 5, "last_level": 8, "name_key": "SEASON_CHAPTER_ARUSHA", "milestone": 8, "bonus_coins": 100},
	{"first_level": 9, "last_level": 12, "name_key": "SEASON_CHAPTER_NEXT", "milestone": 12, "bonus_coins": 125},
]

static func chapter_for_level(level: int) -> Dictionary:
	for chapter in CHAPTERS:
		if level >= int(chapter.first_level) and level <= int(chapter.last_level):
			return chapter
	return {"first_level": 13, "last_level": 0, "name_key": "SEASON_CHAPTER_NEXT", "milestone": 16, "bonus_coins": 150}

static func milestone_reward(level: int) -> int:
	for chapter in CHAPTERS:
		if level == int(chapter.milestone):
			return int(chapter.bonus_coins)
	return 150 if level >= 16 and level % 4 == 0 else 0

static func next_milestone(level: int) -> int:
	for chapter in CHAPTERS:
		if level < int(chapter.milestone):
			return int(chapter.milestone)
	if level < 16:
		return 16
	return 20 + maxi(0, floori(float(level - 16) / 4.0)) * 4
