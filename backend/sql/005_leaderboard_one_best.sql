WITH ranked_scores AS (
  SELECT id,
         ROW_NUMBER() OVER (
           PARTITION BY installation_id, route_id
           ORDER BY score DESC, created_at ASC, id ASC
         ) AS row_number
  FROM leaderboard_scores
)
DELETE FROM leaderboard_scores AS score
USING ranked_scores
WHERE score.id = ranked_scores.id
  AND ranked_scores.row_number > 1;

CREATE UNIQUE INDEX IF NOT EXISTS leaderboard_scores_one_best_per_route_idx
  ON leaderboard_scores (installation_id, route_id);
