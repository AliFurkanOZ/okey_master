DROP MATERIALIZED VIEW IF EXISTS mv_leaderboard;

CREATE MATERIALIZED VIEW mv_leaderboard AS
  SELECT 
    u.id AS user_id, 
    u.username, 
    u.avatar_url,
    us.total_wins, 
    us.avg_score, 
    us.rank,
    CASE WHEN us.total_games > 0 THEN (us.total_wins::numeric / us.total_games) * 100 ELSE 0 END AS win_rate,
    ROW_NUMBER() OVER(ORDER BY us.avg_score DESC) AS position
  FROM users u
  JOIN user_stats us ON u.id = us.user_id;

CREATE UNIQUE INDEX IF NOT EXISTS mv_leaderboard_user_id_idx ON mv_leaderboard(user_id);
