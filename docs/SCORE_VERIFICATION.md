# Leaderboard Score Verification

## Current State

The production World endpoint is reachable and public-read. On October 8,
2026, `/health` returned `{"ok":true}` and Kariakoo, Mwenge, Mbezi, Posta,
Kigamboni, and Ubungo World endpoints returned HTTP 200 with valid
`verification: "unverified"` responses and empty score arrays. This means the
board works but had no opted-in public scores at the time of the check.
Arusha returned HTTP 400 because its route migration has not reached Railway.

The server currently checks installation credentials, opt-in client behavior,
route validity, display-name rules, integer score bounds, rate limits, and
strictly improved best-score writes. It does **not** receive or replay the game
inputs and cannot establish that the submitted total came from a genuine run.
The current client supplies only route, score, and name. Keep every World and
Friends score labelled unverified and do not attach rewards or prizes.

## Why A Client Proof Is Not Enough

A client-generated checksum, run summary, replay clip, or signed value stored
inside the APK can be reproduced by a modified client. Play Integrity can add
useful app/device risk signals, but it does not independently calculate the
player's score. A plausibility envelope can reject impossible-looking values,
but should be described as screening, not verification.

## Recommended Verifiable Run Protocol

1. Version the game rules and export the scoring/simulation logic into one
   deterministic, server-runnable module shared by the client and backend.
   It must define seeded random generation, route/vehicle rules, pickups,
   obstacles, collisions, power-ups, allowed inputs, and exact score math.
2. For an online ranked attempt, request a short-lived run ticket containing a
   server-issued run ID, installation, route, vehicle/upgrades allowed,
   challenge seed, simulation version, and expiry. Sign the ticket server-side.
   Offline runs remain playable but are not submitted as verified.
3. Record a compact, bounded input/event transcript during play. Submit it
   once with the run ID and final client display data. Make run IDs idempotent;
   reject expired, reused, oversized, or mismatched attempts.
4. Re-simulate the transcript on the server and recompute the score. Reject
   illegal transitions, impossible timing, post-collision input, fabricated
   pickups, mismatched configuration, or score disagreement. Store the server
   result and simulation version, not just the claimed client total.
5. Keep legacy scores in a clearly separate unverified pool. Add a new verified
   board only after two-device tests, tamper tests, privacy review, and a staged
   rollout. Never silently relabel historical entries.

## Release Gates

- Specify protocol and threat model before implementation; review replay size,
  CPU cost, offline behavior, save migration, and route balance implications.
- Add tests for valid traces, duplicate tickets, altered score, impossible
  event ordering, expired tickets, modified seed/rules, and route mismatches.
- Run the authoritative simulator against recorded legitimate runs from every
  route and supported build version before enabling public verified rankings.
- Keep the current World endpoint intact and explicitly unverified until the
  verified board can be proven independently. Do not describe the existing
  client summary as proof.
