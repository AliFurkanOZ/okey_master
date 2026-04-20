CREATE MATERIALIZED VIEW IF NOT EXISTS mv_leaderboard AS
  SELECT u.id, u.username, us.total_wins, us.avg_score, us.rank
  FROM users u
  JOIN user_stats us ON u.id = us.user_id
  ORDER BY us.avg_score DESC;

CREATE UNIQUE INDEX IF NOT EXISTS mv_leaderboard_id_idx ON mv_leaderboard(id);
