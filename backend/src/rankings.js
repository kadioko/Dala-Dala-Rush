import { validRoute } from './validation.js';

export function installRankingRoutes(app, pool, requireInstallation, limit, problem) {
  app.get('/v1/leaderboards/nearby/:routeId', requireInstallation, limit, async (req, res) => {
    if (!validRoute(req.params.routeId)) return problem(res, 400, 'invalid_route');
    try {
      const result = await pool.query(`WITH ranked AS MATERIALIZED (
        SELECT ROW_NUMBER() OVER (ORDER BY score.score DESC, score.created_at ASC, score.installation_id ASC) AS rank,
          score.installation_id, score.score, score.created_at, profile.display_name, profile.report_token
        FROM leaderboard_scores AS score JOIN leaderboard_profiles AS profile ON profile.installation_id = score.installation_id
        WHERE score.route_id = $1 AND profile.moderation_status = 'active'
      ), own AS (SELECT * FROM ranked WHERE installation_id = $2)
      SELECT (SELECT to_jsonb(own) FROM own) AS own,
        COALESCE((SELECT jsonb_agg(to_jsonb(neighbor) ORDER BY neighbor.rank) FROM ranked AS neighbor
          WHERE neighbor.rank BETWEEN (SELECT rank - 3 FROM own) AND (SELECT rank + 3 FROM own)), '[]'::jsonb) AS nearby`,
      [req.params.routeId, req.installationId]);
      const map = row => ({ rank: Number(row.rank), score: Number(row.score), displayName: row.display_name,
        submittedAt: row.created_at, reportRef: row.report_token, isYou: row.installation_id === req.installationId });
      const row = result.rows[0];
      return res.json({ verification: 'unverified', own: row.own ? map(row.own) : null,
        nearby: row.nearby.map(map), updatedAt: new Date().toISOString() });
    } catch { return problem(res, 503, 'database_unavailable'); }
  });
}
