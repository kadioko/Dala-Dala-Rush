# Monetization Plan

Three layers, all wired or scaffolded in code:

## 1. Rewarded ads (live-ready)
`autoload/ad_service.gd` — continue-after-crash and double-coins.
Setup: docs/ADMOB_SETUP.md. These convert best because the player asks for them.

## 2. In-app purchases (scaffolded)
`autoload/iap_service.gd` holds the catalog (coin packs + VIP bundle) and the
Play Billing seam. To go live:

1. Install the official **Godot Play Billing** Android plugin.
2. Create the products in Play Console > Monetize > Products with matching ids
   (`coins_small`, `coins_big`, `vip_bundle`).
3. Fill in the TODOs in iap_service.gd (detect singleton, query, purchase,
   consume/acknowledge, then `_grant()`).
4. Build a simple store section in the shop calling `IapService.purchase(id)`.

### Tanzania-specific: carrier billing
Google Play supports **direct carrier billing** in Tanzania via major
operators (availability varies — check Play Console > Settings > Payment
profile coverage). Users without cards pay through their airtime/mobile
balance. Nothing extra to code — it appears automatically as a payment
method in the Play purchase sheet when available. This dramatically widens
who can actually buy. Price low (the $0.99 pack matters most).

## 3. Season pass (future)
The season XP track (data/missions.gd) is built. A premium track =
one IAP (`season_pass`) gating a second reward column. Add when retention
data justifies it.

## Pricing guidance for TZ
- Use Play Console's per-country pricing; set TZS prices manually rather
  than auto-converted USD (round to friendly numbers, e.g. TSh 2,500).
- Rewarded ads will likely out-earn IAP early; don't paywall progression.
- Never sell power that breaks ghost-racing fairness (cosmetics + convenience only).
