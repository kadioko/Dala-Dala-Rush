# Sprite Assets

Last verified: August 19, 2026.

No optional gameplay PNG overrides are currently present. The current build
uses the improved procedural/vector artwork in the entity and road scripts.
Files under `assets/store_listing/` are Play Store graphics, not gameplay
sprite overrides.

Current build note: the same sprite lookup is used by the How to Play entity
previews, so a new sprite improves both gameplay and the teaching screen
automatically.

The game draws all entities as detailed vector shapes in code, so it runs with
zero gameplay image files. The built-in set includes distinct top-down cars,
trucks, police vehicles, bodabodas, bajajis, dala dalas, road hazards, people,
power-ups, animated coins, bus stops, and route scenery. To replace any item,
drop a PNG into `res://sprites/` — it is used automatically (loaded by
`scripts/sprite_lib.gd`); anything missing keeps the polished vector fallback.
Mix and match freely.

All sprites should face **up** (driving away from the camera) and include
transparency. They are stretched to the entity's logical size, so match the
aspect ratios below. Use 2x the logical size for crispness.

## Vehicles — `sprites/vehicle_<id>.png` (logical 72x110)

- vehicle_classic_blue.png
- vehicle_kariakoo_yellow.png
- vehicle_mwendokasi_red.png
- vehicle_night_bus.png
- vehicle_vip.png
- vehicle_old_school.png
- vehicle_simba_express.png
- vehicle_bongo_flava.png

## Obstacles — `sprites/obstacle_<id>.png`

| File | Logical size |
|---|---|
| obstacle_bodaboda.png | 46x70 |
| obstacle_bajaji.png | 60x80 |
| obstacle_car.png | 70x100 |
| obstacle_pothole.png | 72x28 |
| obstacle_cone.png | 28x38 |
| obstacle_police.png | 80x110 |
| obstacle_barrier.png | 80x22 |
| obstacle_truck.png | 76x130 |
| obstacle_pedestrian.png | 80x22 (zebra crossing) |
| obstacle_tire.png | 36x36 |
| obstacle_mbuzi.png | 44x52 (goat) |
| obstacle_kituo.png | 74x96 (roadside bus stop / shelter) |

## Collectibles — `sprites/collectible_<id>.png`

| File | Logical size |
|---|---|
| collectible_coin.png | 36x36 |
| collectible_passenger.png | 40x56 |
| collectible_fuel.png | 36x46 |
| collectible_shield.png | 40x46 |
| collectible_magnet.png | 40x40 |
| collectible_speed_boost.png | 40x40 |
| collectible_slow.png | 40x40 |

## Style suggestions

- Bold flat colours with dark outlines read best at small sizes on cheap screens.
- Keep the vehicle accent colours close to the in-game palette (data/vehicles.gd) so the garage previews still match.
- Pixel art at 2x–3x scale also works well with the project's nearest-neighbour filtering (`default_texture_filter=0`).

## Import QA

- Use transparent PNGs with tight bounds and no baked background.
- Verify the same asset in gameplay, Garage/How to Play where applicable, and
  both day and night conditions.
- Keep collision sizes in code unchanged unless the new visual genuinely needs
  a gameplay change.
- Test memory and frame pacing on a low-end phone after adding a full set.
