# Content Guide

This project is designed so most new content can be added through small data/script edits.

## Add a Route

1. Add a route entry in `data/routes.gd`.
2. Add a route name key in both locale dictionaries in `autoload/locale_manager.gd`.
3. If the route needs a unique visual identity, update `scripts/entities/road.gd`.

Example:

```gdscript
{
	"id": "temeke",
	"name_key": "ROUTE_TEMEKE",
	"difficulty": 1.35,
	"sky": Color("#f8c291"),
	"road": Color("#30336b"),
	"flavor_key": "ROUTE_TEMEKE_D",
	"goal_key": "GOAL_TEMEKE",
	"goal_type": "score",
	"goal_target": 900,
	"goal_reward": 60,
	"obstacle_weights": {
		"bodaboda": 12, "bajaji": 12, "car": 14, "pothole": 12, "cone": 8,
		"police": 6, "barrier": 8, "truck": 10, "pedestrian": 8, "tire": 10,
	},
	"collectible_weights": {
		"coin": 55, "passenger": 20, "fuel": 10, "shield": 5,
		"magnet": 4, "speed_boost": 3, "slow": 3,
	},
}
```

`obstacle_weights` and `collectible_weights` do not need to add to 100. They are relative weights.
For example, if `truck` is twice as high as `car`, trucks are roughly twice as likely as cars.

Route goals support these `goal_type` values:

- `score`
- `coins`
- `distance`
- `near_misses`
- `passengers`

Add the matching `goal_key` text in both Swahili and English locale dictionaries.

## Add a Daily Challenge

Open `data/daily_challenges.gd` and append to `LIST`:

```gdscript
{
	"id": "daily_fuel_run",
	"key": "DAILY_FUEL_RUN",
	"type": "distance",
	"target": 2500,
	"reward": 90,
}
```

Supported `type` values are the same as route goals: `score`, `coins`, `distance`, `near_misses`, and `passengers`.
Add the `key` text in both locale dictionaries.

## Add a Vehicle

1. Add a vehicle entry in `data/vehicles.gd`.
2. Add the vehicle name key in Swahili and English in `autoload/locale_manager.gd`.
3. Pick a fair coin price. Early unlocks should stay cheap so players feel progress quickly.

Example:

```gdscript
{
	"id": "temeke_green",
	"name_key": "VEH_TEMEKE_GREEN",
	"price": 1200,
	"body": Color("#00b894"),
	"accent": Color("#fdcb6e"),
	"lane_time": 0.13,
	"fuel_drain_mult": 0.95,
	"coin_mult": 1.08,
	"horn_charges": 3,
}
```

Vehicle perk fields:

- `lane_time`: lower means faster lane changes.
- `fuel_drain_mult`: lower means better fuel economy.
- `coin_mult`: higher means more coins per coin pickup.
- `horn_charges`: starting and maximum horn uses.

## Add an Obstacle

1. Add a type to `scripts/entities/obstacle.gd` in `TYPES`.
2. Add a drawing case in `_draw()` if the generic vehicle shape is not enough.
3. Add the id to `OBSTACLE_TYPES` in `scripts/game.gd`.
4. Add How To Play copy if players need to recognize it quickly.

## Add a Collectible or Power-up

1. Add a type to `scripts/entities/collectible.gd`.
2. Add the effect in `scripts/game.gd` inside `_on_collect()`.
3. Add labels/descriptions in `autoload/locale_manager.gd`.
4. Consider haptics: call `FeedbackManager.collect()` or `FeedbackManager.powerup()`.

## Add a Language

1. Add a new locale block in `autoload/locale_manager.gd`.
2. Copy all keys from `en` first, then translate.
3. Update Settings if you want a third button instead of the current Swahili/English selector.
4. Test every menu after switching language.

## Content Tone

- Keep names local and playful.
- Do not use real bus company logos or copyrighted brands.
- Keep police/checkpoint jokes family-friendly.
- Short Swahili UI strings work best on small phones.
