# SACCO Crews - Product And Technical Design

Status: design only. No crew UI, endpoint, database table, or crew score is
shipped. This proposal intentionally waits for reliable two-phone leaderboard
QA and an authenticated moderation workflow.

## Player Loop

- A player can create or join one crew using a short, expiring invite code.
- A crew has a display name, optional short motto, owner, and up to 20 members.
- Members compete on one weekly route contract with identical route, vehicle,
  traffic seed, duration rules, and no revive/consumable bonuses.
- Results show the crew total and each member's best eligible run. Crew rewards
  are cosmetic/recognition only at first; no coins, progression advantage, or
  paid access is tied to crew rank.
- Players can leave at any time. The owner can transfer ownership or disband;
  an inactive crew must not trap its members.

## Privacy And Safety Requirements

- Joining is a separate, explicit opt-in from public World leaderboard consent.
- Use an opaque account identifier server-side. Display only the player's
  chosen leaderboard name; never expose email, device identifiers, or invite
  history in crew views.
- Require a confirmation step before sharing the selected name with crew
  members. Settings must support leaving and deleting the crew profile.
- Provide report and block controls on member names. A block must hide the
  blocked player's crew content and prevent new invitations between them.
- Keep the initial feature invite-only: no public crew directory, open chat,
  user-submitted images, or free-form public bios. Use a fixed list of motto
  phrases or omit mottos entirely to reduce moderation risk.
- Rate-limit invite creation/join attempts and prevent repeated reward farming.
  Invite codes expire, are one-use, and are not the account credential.
- Define retention and deletion behavior in the privacy policy and Play Data
  Safety declaration before launch. Crew membership and reports need an
  explicit deletion path and an operational moderation owner.

## Suggested Backend Shape

PostgreSQL tables should store crew identity, membership, weekly challenge
definition, eligible run submissions, and moderation references separately.
Use foreign keys and unique constraints to enforce one membership per player,
one active challenge per crew/week, and one best eligible score per player and
challenge. Store only opaque IDs and required timestamps. Do not put personal
data in invite tokens.

Proposed endpoints, after authentication is available:

- `POST /v1/crews` create a crew and return a one-use invite code.
- `POST /v1/crews/join` redeem an expiring invite code.
- `GET /v1/crews/me` return the caller's crew and current challenge.
- `POST /v1/crews/runs` submit a run proof for server validation.
- `POST /v1/crews/leave` leave; owner transfer or disband is explicit.
- `POST /v1/crews/members/report` report a member using fixed reason codes.
- `DELETE /v1/crews/me` remove membership/profile and associated crew data as
  allowed by the crew's remaining members and retention obligations.

Do not accept client-provided score totals as authoritative. Before calling a
crew board verified, the server must validate a signed/replayable run protocol,
challenge seed, allowed vehicle/upgrades, duration, and score bounds. Existing
local replay clips are for friendly comparison only; they are not tamper-proof.

## Release Gates

1. Finish name report/block/unblock UX and operational moderation ownership.
2. Add authenticated identity and server-side run validation before crew ranks
   can be described as verified.
3. Implement schema migrations, abuse/rate limits, deletion, and privacy copy.
4. Test create/join/leave/report/block/delete on two physical phones, both
   languages, airplane mode, expired invite, full crew, and owner departure.
5. Keep the feature behind a server kill switch until the above pass.

## Current Foundation

The game already has opt-in leaderboard names, friend codes, fixed-reason
leaderboard reporting, blocking, and local replay clips. These are useful
building blocks, but they do not provide crew membership, authentication,
verified scores, or crew moderation. Do not advertise SACCO crews until those
missing systems ship and are validated.
