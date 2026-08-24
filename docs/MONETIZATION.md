# Monetization Plan

Last verified: August 19, 2026.

Ads are the only enabled monetization in the current game. Play Billing and a
premium season track are optional future work and must not be declared as live
products until implemented and tested.

## 1. Ads

`autoload/ad_service.gd` owns all ad policy and SDK integration points.

Current placement mix:

- Rewarded revive after crash.
- Rewarded double coins on the results screen.
- One revive per run; the result screen accepts only one rewarded request, so
  revive and double coins cannot stack.
- Interstitial after every 2-3 completed runs.
- Banner only on the main menu and results screen.
- No gameplay banner.
- No interstitial before revive/double-coins decisions.

The interstitial cadence is saved locally with:

- `ads_runs_since_interstitial`
- `ads_next_interstitial_at`
- `ads_pending_interstitial`

The Poing Studios AdMob plugin, production IDs, and SDK bridge are wired. See
`docs/ADMOB_SETUP.md` for manifest status and release QA. Use registered test
devices while developing and never click live ads.

## 2. In-App Purchases

`autoload/iap_service.gd` holds the catalog for coin packs and VIP bundle.
Billing is currently unavailable, the shop does not expose real-money offers,
and no Play products should be activated for this release.

To go live:

1. Install the official Godot Play Billing Android plugin.
2. Create products in Play Console > Monetize > Products with matching ids.
3. Implement product query, purchase, acknowledgement/consumption, restore,
   pending-purchase handling, and server-side verification as appropriate.
4. Build a store section calling `IapService.purchase(id)`.
5. Update the privacy policy, Data safety form, content rating, store listing,
   and test purchases before enabling products.

## 3. Season Pass

The season XP track is built in `data/missions.gd`. A future premium track can
use one IAP, such as `season_pass`, to unlock a second reward column.

Current status: no paid season pass exists.

## Tanzania Pricing Notes

- Use Play Console country pricing and set friendly TZS prices manually.
- Rewarded ads should out-earn IAP early; do not paywall progression.
- Keep paid advantages cosmetic or convenient so ghost/ranking fairness stays
  intact.
- Fake coins have no cash value and cannot be withdrawn, traded, wagered, or
  exchanged for prizes.

## Referral Coin Economy

Invite & Earn is a retention feature, not a paid product. The current offline
handshake pays 75 welcome coins to one invited player and 125 coins to the
inviter after a returned confirmation, with a maximum of 10 inviter rewards per
local save. Milestones add 100 coins at 3 friends, 200 at 5, and 500 at 10.
Sharing alone never pays coins. A player who completes all 10 referrals earns
2,050 inviter coins in total, enough for meaningful progression without an
uncapped source.

The local checksum and duplicate guards deter casual repeat claims but are not
server-grade fraud prevention. Do not raise the cap, attach cash value, or add
large or paid rewards until installs and payouts are verified by a backend. A
future implementation should use Play install attribution plus server-side
idempotency while preserving the current saved invite code where possible.
