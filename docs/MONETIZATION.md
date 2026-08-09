# Monetization Plan

Last verified: August 9, 2026.

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
