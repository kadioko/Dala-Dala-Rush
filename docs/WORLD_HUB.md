# Mtaa Wetu

Mtaa Wetu is a walkable six-district Dar neighborhood between endless-run
sessions. The map is three districts wide and two districts tall; the camera
follows the player, district edges connect, and the map button offers a quick
dala ride to a district center. Every district links to its matching driving
route and has a dedicated stall, plot office and paid delivery activity.

## 1.0.20 Release Candidate

The current working source extends save schema to 23 and is included in the
version 1.0.20 / code 21 release candidate. Online election and lounge features
require successful deployment of migrations 014-015. No device acceptance is
claimed until the A21s and a second phone complete the QA worksheet.

- Walk with touch D-pad or keyboard arrows/WASD. The first visit points at the
  passenger stop, explains the nearby action button, then names the next errand
  landmark in the HUD. The Mtaa Phone is optional; walking, map travel and
  nearby jobs do not require buying it.
- Daily errand progress requires explicit tap/check-in at the market, garage,
  and plaza; simply walking past does not count. Completion pays 30 existing
  coins once per local day and persists across restarts.
- A compact 3x2 district map marks the current area and active job destination;
  walking signs name district exits. Fast travel is presented as a dala ride.
- Each district greets the player with short localized character lines. Local
  jobs and purchases get district reactions; ambient characters and local
  vehicles give areas recognizable silhouettes without heavy assets.
- Twenty-five district cosmetics/items are sold across the neighborhood. Shops
  show a preview, owned-items view, price and remaining wallet before purchase.
  Six wearable conductor looks can be equipped; ownership stays local. A Posta
  envelope shelf unlocks at Posta Flat level 2.
- The Mtaa Passport permanently records district visits and completed local
  jobs. First visits also add an illustrated district keepsake to the album;
  2/4/6 distinct visits award one-time coin milestones. No streak timer or
  second currency is used.
- Placeable decor has a preview, property selector, three visible plot slots,
  confirmation/cancel, move support and atomic coin/ownership save. The owned
  items view shows each item's property and slot. NPC friendship rewards are
  avatar wearables, not placeable goods.
- Property actions open a home record/outfit panel, workshop vehicle/parts
  panel, Kariakoo market or Posta stock shelf. These are local convenience
  panels; the home interior is not a separate walkable scene.
- A purchasable local phone opens passport, album, route event board, home,
  owned items, a full property portfolio, public lounge, bus display and map
  shortcuts. The global chat entry is
  specifically a Kariakoo-only public lounge with preset phrases, not global
  free-text chat. It requires opted-in public presence and deployed migration
  015. Unmoderated text and voice chat are intentionally absent.
- The personal bus stand can display any locally unlocked vehicle. Showing
  friends' buses is deferred until two-phone friend/block QA passes.
- District event board reuses existing route contracts. Job previews identify
  pickup, delivery, reward and available daily paid-job slots; payout receipts
  show remaining slots or explain when a route reward is queued. Properties can
  be reviewed together, with disclosed perks and capped NPC rent. Results
  summarize Mtaa contract progress and the next local purchase. Fast travel
  remains free and confirmed; walking remains available.
- District arrivals pair localized greetings and landmarks with quiet synthetic
  voice cues controlled by SFX. The brief arrival ring is suppressed by Reduced
  Effects. NPC job completions show relationship progress and cosmetic unlocks;
  no text or voice chat was added.
- Nine buildable plots include the Kariakoo market kiosk, driver home, workshop
  and guest house, plus one plot in each of the other five districts. Buildings
  visibly grow across up to three levels. Ownership is private to the
  installation and is not shown to visitors.
- Modest practical perks are disclosed beside their plots: Kiosk level 2 gives
  10% off Kariakoo shop goods; Mbezi Yard level 2 gives 10% off Mbezi goods;
  Workshop level 2 adds 3 coins to parts jobs; Posta Flat level 2 unlocks one
  extra local cosmetic. These do not affect driving balance.
- Rental properties have game-NPC tenants. Rent is manually collected once per
  local calendar day, capped at 40 coins total across all districts. It is not
  real-player rental, does not accrue while away, and uses the existing wallet.
- Nine walking pickup/delivery jobs across the districts pay 12-20 coins. Each
  district activity also offers a driving contract on its matching route;
  completing that route's existing goal earns a 25-coin bonus on return. The
  shared two-paid-jobs-per-local-day cap is enforced when rewards are paid; a
  completed contract waits for the next available slot. Contracts and walking
  job progress resume after restart. There is no new currency.
- Friends Plaza retains World standings, friend links and optional presence.
  Presence is separately opt-in and still requires a public leaderboard profile.
- The plaza lounge offers five fixed Swahili/English phrases. There is no
  player-authored text or voice. A phrase is shared only through opted-in
  presence and expires from the service after 15 seconds; regular map presence
  expires after 45 seconds. Online presence is limited to Kariakoo and is
  removed when walking or riding to another district. Lounge phrases require
  migration 015.
- Friends Plaza includes a fictional seasonal election for the “Head of Dala
  Dala World”: one vote per installation, no reward, aggregate totals only.
  Individual choices are never returned to other players. It is not a real-world
  political election.

## Online Presence And Election Safety

Presence is a polling feature, not MMO or authoritative multiplayer. The client
sends a fictional map position, selected vehicle and one of three preset emotes.
A single row per installation expires after 45 seconds. Crowd size is capped at
20, blocks apply in both directions, and there is no free-text chat, voice chat,
real-world GPS or movement history. Presence defaults off.

The election requires an installation credential but not a public leaderboard
profile. A database uniqueness constraint enforces one vote per installation
per season; a shared rate limit protects vote writes. Only aggregate totals are
returned. Votes are deleted one year after an election closes, and installation
deletion cascades to its votes.

Migration `013_ephemeral_hub_presence.sql` provides presence. Migration
`014_mtaa_election.sql` creates the election and vote tables. Migration
`015_hub_preset_lounge.sql` expands the database allowlist for preset phrases.
Migrations 014 and 015 are prepared but not deployed to Railway; online election
and lounge requests must be treated as unavailable until deploy.

## Release Readiness

- Migration 013 is deployed. Migrations 014-015 are prepared but not deployed.
- Privacy HTML now includes local election, property-rent and preset-lounge
  disclosures but has not been published. Publish it and update the Play
  Console Data Safety answers before distributing a build with these features.
- Test two real phones for opt-in/out, suspend/resume, expiry, blocking, voting
  once per device, tally refresh and account deletion. No device results are
  claimed yet.
- Validate property prices and job cadence on devices before tuning. The code
  20 / version 1.0.19 bundle predates these changes. A future AAB needs a higher
  version code and a deliberate deploy/release of migrations 014-015.
- The local save schema is now 23. Passport, album, NPC relationships, decor
  placement, phone ownership and bus display are device-local; these source
  additions require no backend schema change. Election and lounge APIs still
  depend on undeployed migrations 014-015.

## Expansion Path

Add a district only after the current movement, interactions, jobs, privacy and
presence flows pass device testing. Future districts can reuse the same systems.
Real-time driving, unrestricted user-generated text, voice and player trading
require separate moderation, abuse, privacy and backend designs.
