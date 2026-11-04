# Mtaa Wetu

Mtaa Wetu is the first small neighborhood between endless-run sessions. The
goal is to make the local setting feel like somewhere players return to, while
keeping the core driver loop and coin economy intact.

## Current Playable Slice

- Walk around a Kariakoo block with touch D-pad or keyboard arrows/WASD.
- Visit the passenger stop and finish today's three-stop errand by reaching the
  market, garage and Friends Plaza. It pays 30 existing coins once per local day
  and resumes saved progress after reopening the game.
- Spend existing coins on a Kanga flag, market lanterns or a bus-stop bench.
  Purchases are saved with the wallet in one write; owned items are drawn into
  the plaza. The normal Garage remains available from the mechanic stall.
- Enter Friends Plaza for World standings, friend links and optional online
  presence. Presence must be separately enabled in the plaza or Settings and
  requires an online leaderboard profile.

## Online Presence And Safety

Presence is a small polling feature, not MMO or authoritative multiplayer. The
client sends the current fictional map position, selected vehicle and one of
three preset emotes. A single row per installation is overwritten; it expires
after 45 seconds and a Railway cleanup task removes stale rows. The crowd is
capped at 20 and does not include the local player. Existing blocks are applied
in both directions. Players can block a visible driver. There is no text chat,
voice chat, real-world GPS or historical movement trail. Presence defaults off.

The API requires the installation credential and an active public leaderboard
profile. Position values and vehicle/emote identifiers are bounded and
whitelisted; shared database-backed limits protect writes. Leaving the plaza
removes the current row, and inactivity expires it. Migration
`backend/sql/013_ephemeral_hub_presence.sql` creates only the current presence
table and index.

## Before A Public Release

- Deploy migration 013 and confirm its schema in Railway before using presence.
- Publish the matching privacy policy and review Play Console Data Safety.
- Test two real phones, including opt-in/out, app suspend/resume, expiry, emotes,
  blocking and the leaderboard profile requirement.
- Record how quickly the first decoration is affordable and whether the daily
  route feels worthwhile; adjust costs/reward only from observed runs.
- Build a higher-version signed AAB. The October code-19 candidate predates this
  feature and must not be used to claim the hub is on devices.

## Expansion Path

Add new districts only when the hub has a stable movement/interact contract and
the existing one is used. Candidate additions are a minibus stage, mechanic
tasks, route-specific public events and friend challenges using reproducible run
rules. Real-time driving, unrestricted user-generated text, voice and player
trading need separate safety, abuse, privacy and backend designs; they are not
part of this prototype.
