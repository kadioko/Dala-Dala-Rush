# Railway Backend Runbook

The repository now contains a small Node 20 / Express / PostgreSQL service in
`backend/`. It is intentionally separate from the Godot game: the game remains
fully playable offline. The Railway service is deployed and the current client
release switch is on. As confirmed October 8, 2026, production has migrations
through `009_moderation_console.sql`. Public World standings can be viewed without an account; posting a
name/score and using Friends require explicit in-game consent. Scores remain
unverified and have no rewards. Complete the device and Play declaration checks
before expanding promotion or adding reward-bearing competition.

## What It Provides

- Optional cloud-save storage with monotonic revisions.
- Server-issued installation credentials, stored only on that device.
- An opt-in, deliberately labelled **unverified** leaderboard with a short
  public driver name, one best score per route, expiring friend codes, cached
  standings, and device-side retryable submissions. Do not use it for prizes.
- A separate, disabled-by-default, consented telemetry endpoint for a small
  allowlist of gameplay-friction events. It rejects names, codes, tokens,
  advertising IDs, and nested/free-form data.
- Server-side referral activation gates after an invited device records a
  meaningful run. This is not fraud-proof verification yet.
- No email addresses, contacts, precise location, advertising ID, Firebase
  data, or database credentials are accepted by the API. A player may choose a
  2-16 character driver name for the opt-in leaderboard only.
- Deployed hardening: score writes retain only an improved per-route best,
  migration `005_leaderboard_one_best.sql` removes existing duplicates and adds
  a unique guard, reserved staff-like names are rejected, and migration
  `006_shared_rate_limits.sql` provides shared counters for 20 registrations
  per IP per hour, 90 World reads per IP per minute, 8 score submissions per
  installation per five minutes, and 8 profile changes per installation per
  hour.

The backend does not automatically award coins. Keep the existing offline
referral flow as the live system until device QA, privacy review, and a stronger
attestation strategy are complete. The endpoint validates a score's route,
integer bounds, public name, consented installation, rate limit, and best-score
upsert, but does not replay or independently verify the run. A modified client
can still forge a plausible score; Play Integrity alone would not prove the
gameplay result. Public scores must remain labelled unverified and reward-free.

## Moderation Console

The service includes a private operator page at `/admin` and token-protected
moderation endpoints. It lists fixed-reason reports, supports dismissal, hides
a reported profile from World/Friends without deleting score records, and allows
restoration after review. The public app cannot call these admin endpoints.

Operator access:

1. A unique random `MODERATION_ADMIN_TOKEN` is configured on the production
   Railway service. Its operator copy is stored outside the repository. Rotate
   it in Railway and update the operator copy if it is lost or exposed.
2. Open `https://dala-dala-api-production.up.railway.app/admin`, enter the
   token, and review over HTTPS.
   The page keeps the secret only in the current browser tab's `sessionStorage`
   and sends it in `X-Admin-Token`, never in a URL.
3. Use **Hide profile** only when warranted: all open reports for that profile
   are actioned and its display name disappears from World/Friends. **Restore
   profile** reverses the visibility decision. Dismiss closes a report without
   hiding the profile.
4. Rotate the token in Railway and clear browser tabs if it is exposed. This is
   a single shared operator secret, not multi-user identity or a substitute for
   a staffed moderation policy.

The console does not prove score legitimacy or provide an appeal/chat system.
Report records continue to follow the existing 90-day deletion policy.

The limiter uses a keyed HMAC of the endpoint subject. A stable random
`RATE_LIMIT_HASH_KEY` is configured in Railway and shared by replicas. The
database URL is a compatibility fallback, but a separate key prevents database
credential rotation from resetting active rate-limit buckets. Raw IP addresses
are never written to the limiter table.

## Deploy To Railway

Do this only when you are ready to create the Railway resources. Do not put
`DATABASE_URL`, Railway tokens, or a production sync token in Godot.

1. In a terminal, enter `backend/` and sign in: `railway login`.
2. Create/select a Railway project: `railway init`.
3. Add PostgreSQL: `railway add --database postgres`.
4. Create a service from this same folder. In its Variables, set:

   ```text
   DATABASE_URL=${{Postgres.DATABASE_URL}}
   ```

   Railway supplies `PORT`; do not set it unless you have a specific reason.
5. Deploy the service: `railway up`.
6. Apply all database migrations before deploying code that requires them.
   The API service's Railway `preDeployCommand` is configured as
   `npm run migrate`; verify the migration log before considering the deploy
   healthy. The one-time `RUN_MIGRATIONS_ON_START=true` bootstrap is a fallback
   only and must be removed immediately after use.

   ```powershell
   railway run npm run migrate
   ```

   `railway run` executes on your computer, so it cannot resolve Railway's
   private Postgres hostname. For a private-only database, use the configured
   Railway pre-deploy command, which runs inside the private network. If a
   migration must be applied manually, use a secure Railway-side execution
   path and verify the API before removing any temporary bootstrap setting.

7. In Railway Networking, generate a public domain. Open
   `https://YOUR-DOMAIN/health`; it must return `{ "ok": true }`.
8. Put only that public `https://...` domain in `API_BASE_URL` inside
   `autoload/online_service.gd`, then test a new Android build on a non-primary
   save before enabling any cloud-sync UI.

Railway's Postgres service exposes `DATABASE_URL` to the service through a
variable reference; the Node service uses that at runtime, never in source.

## Local Verification

```powershell
cd backend
npm install
npm test
$env:DATABASE_URL = "postgresql://..."
npm run migrate
npm start
```

`GET /health` confirms the process can query PostgreSQL. Do not commit `.env`,
database dumps, service tokens, or a copied Railway variable file.

## API Contract

All endpoints return JSON. Authenticated routes require:

```text
X-Installation-Id: server-issued UUID
X-Sync-Token: server-issued device token
```

| Endpoint | Purpose |
|---|---|
| `POST /v1/installations` | Create one anonymous device identity and sync token. |
| `GET/POST /v1/cloud-save` | Read/write the filtered cloud snapshot. Newer revision wins. |
| `POST /v1/leaderboards/unverified` | Submit a non-reward-bearing score. |
| `GET /v1/leaderboards/unverified/:routeId` | Read the top 25 named best scores for a route. |
| `GET /admin` | Private moderation operator page. |
| `GET /v1/admin/reports?status=open` | Token-protected report queue (`open`, `reviewed`, or `all`). |
| `POST /v1/admin/reports/:reportId/resolve` | Token-protected `dismiss` or `hide_profile` decision. |
| `GET /v1/admin/profiles/hidden` | Token-protected list of hidden public profiles. |
| `POST /v1/admin/profiles/:targetId/restore` | Restore a hidden profile. |
| `PUT /v1/leaderboard-profile` | Save an opted-in driver's public display name. |
| `DELETE /v1/leaderboard-profile` | Leave public competition and remove that profile, scores, friend links, and friend codes. |
| `POST /v1/leaderboards/friends/invite` | Create a one-use friend code valid for 24 hours. |
| `POST /v1/leaderboards/friends/claim` | Create a two-way friend link from a code. |
| `GET /v1/leaderboards/friends/:routeId` | Read a driver's and friends' best route scores. |
| `GET /v1/leaderboards/friends` | Read the current driver's friend list. |
| `DELETE /v1/leaderboards/friends/:friendId` | Remove one two-way friend link. |
| `POST /v1/telemetry` | Store a batch of consented, allowlisted, anonymous gameplay events. |
| `POST /v1/runs/meaningful` | Record a qualifying run for referral eligibility. |
| `POST /v1/referrals/invites` | Create a server-issued invite code. |
| `POST /v1/referrals/activate` | Link an eligible invitee to an invite, with duplicate/self guards. |
| `POST /v1/account/transfer-code` | Create a one-time, 15-minute phone-move code. |
| `POST /v1/account/claim-transfer` | Rotate cloud access to a new phone using that code. |

Cloud sync intentionally excludes local leaderboard names, all referral codes,
analytics history, pending leaderboard uploads, cached standings, and the sync
credential itself. Online leaderboard and gameplay-insights consent are each
separate from cloud-backup consent; no name or score leaves the device until
the player explicitly joins competition, and no telemetry leaves it until they
enable Gameplay Insights. A phone move rotates the anonymous sync token,
invalidating the old phone's server access.

## Remaining Production Checks

- Migrations through `009` were deployed on October 8, 2026. Railway logs
  confirmed the migration runner completed; `/health` and Arusha's public World
  endpoint returned HTTP 200 with a valid unverified response. The Dar and
  Arusha boards may be empty until players opt in and submit scores.
- Railway's production pre-deploy command is now `npm run migrate`. Keep it
  enabled for future schema changes.
- Shared request limits are abuse friction, not anti-cheat. Scores remain
  forgeable and must stay labelled unverified and reward-free.
- Migration `008_arusha_route_pack.sql` expands the accepted route IDs;
  migration `009_moderation_console.sql` adds report-review and visibility
  state. Both were applied by the production pre-deploy migration runner.
- The protected console is deployed and `MODERATION_ADMIN_TOKEN` is configured.
  Smoke-test authenticated list, dismiss, hide, and restore with a disposable
  report/profile before relying on moderation operations.
- The public World route endpoint does not require a player account; posting
  a name/score does require opt-in. A successful empty `scores` array means
  there are no opted-in scores for that route, not that World is disabled.
- Recheck the Privacy Policy and Play Data Safety form against the exact
  deployed behavior, including public visibility after a player opts in.
- Test World refresh/cache, opt-in submission, friend linking/removal,
  registration, cloud upload/download, deletion, offline retry, and server
  outages on at least two phones.
- Keep database backups, error monitoring, and a retention policy in Railway
  before broad public promotion.
- Require server-verifiable integrity evidence before paying server-side
  referral rewards or presenting a leaderboard as verified or reward-bearing.
- The API now has authenticated `DELETE /v1/account`, which cascades deletion
  of that anonymous installation's cloud save, online scores, invite records,
  and referral activations. Test it on two phones before promotion.
