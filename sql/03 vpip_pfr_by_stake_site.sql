# Per stake/site aggregate query to look at vpip/pfr across stakes and sites
SELECT
    stake,
    site,
    COUNT(*) AS qualifying_players,
    SUM(hands_played) AS total_hands,
    AVG(VPIP) AS avg_VPIP,
    AVG(PFR) AS avg_PFR
FROM (
    SELECT
        hp.player_id,
        h.stake,
        h.site,
        COUNT(DISTINCT hp.hand_id) AS hands_played,
        100.0 * COUNT(DISTINCT CASE
            WHEN a.street = 'preflop' AND a.action_type IN ('call','cbr')
            THEN hp.hand_id END)
        / COUNT(DISTINCT hp.hand_id) AS VPIP,
        100.0 * COUNT(DISTINCT CASE
            WHEN a.street = 'preflop' AND a.action_type = 'cbr'
            THEN hp.hand_id END)
        / COUNT(DISTINCT hp.hand_id) AS PFR
    FROM hand_players AS hp
    JOIN hands AS h ON hp.hand_id = h.hand_id
    LEFT JOIN actions AS a
        ON hp.hand_id = a.hand_id
       AND a.actor = CONCAT('p', hp.position_index)
    GROUP BY hp.player_id, h.stake, h.site
    HAVING COUNT(DISTINCT hp.hand_id) >= 100
) AS player_stats
GROUP BY stake, site
ORDER BY stake, site;
