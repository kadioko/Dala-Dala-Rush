ALTER TABLE leaderboard_scores
  DROP CONSTRAINT IF EXISTS leaderboard_scores_route_id_check;
ALTER TABLE leaderboard_scores
  ADD CONSTRAINT leaderboard_scores_route_id_check
  CHECK (route_id IN ('kariakoo', 'mwenge', 'mbezi', 'posta', 'kigamboni', 'ubungo', 'arusha'));

ALTER TABLE meaningful_runs
  DROP CONSTRAINT IF EXISTS meaningful_runs_route_id_check;
ALTER TABLE meaningful_runs
  ADD CONSTRAINT meaningful_runs_route_id_check
  CHECK (route_id IN ('kariakoo', 'mwenge', 'mbezi', 'posta', 'kigamboni', 'ubungo', 'arusha'));

ALTER TABLE leaderboard_reports
  DROP CONSTRAINT IF EXISTS leaderboard_reports_route_id_check;
ALTER TABLE leaderboard_reports
  ADD CONSTRAINT leaderboard_reports_route_id_check
  CHECK (route_id IN ('kariakoo', 'mwenge', 'mbezi', 'posta', 'kigamboni', 'ubungo', 'arusha'));
