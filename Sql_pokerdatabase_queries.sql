# Reviewing Numbers of sample data inserted into database
SELECT COUNT(*) AS hands FROM hands;
SELECT COUNT(*) AS players FROM players;
SELECT COUNT(*) AS seats FROM hand_players;
SELECT COUNT(*) AS actions FROM actions;
SELECT stake, COUNT(*) AS hands FROM hands GROUP BY stake;

# VPIP/PFR and hands played across 1000NL players
SELECT
    hp.player_id,
    COUNT(DISTINCT hp.hand_id) AS hands_played, # count all hands
    ROUND(
        100.0 * COUNT(DISTINCT CASE # Cleanliness, % - ensuring we're looking at preflop action in calls/cbr
            WHEN a.street = 'preflop'
             AND a.action_type IN ('call', 'cbr')
            THEN a.hand_id
        END)
        / COUNT(DISTINCT hp.hand_id),
        2
    ) AS VPIP,

    ROUND(
        100.0 * COUNT(DISTINCT CASE
            WHEN a.street = 'preflop'
             AND a.action_type = 'cbr'
            THEN a.hand_id
        END)
        / COUNT(DISTINCT hp.hand_id),
        2 # round 2 decimal points
    ) AS PFR

FROM hand_players AS hp

LEFT JOIN actions AS a # Left join will keep the hands counted  with no qualifying action 
    ON hp.hand_id = a.hand_id
   AND a.actor = CONCAT('p', hp.position_index)

GROUP BY hp.player_id 

HAVING COUNT(DISTINCT hp.hand_id) >= 100 

ORDER BY hands_played DESC;

# MEAN VPIP/PFR grouped by Stake across all hands
SELECT
    h.stake,

    COUNT(DISTINCT hp.hand_id) AS total_hands,

    COUNT(DISTINCT hp.player_id) AS players,

    ROUND(AVG(player_stats.VPIP), 2) AS mean_VPIP,

    ROUND(AVG(player_stats.PFR), 2) AS mean_PFR

FROM (

    SELECT
        hp.player_id,
        h.stake,

        COUNT(DISTINCT hp.hand_id) AS hands_played,

        100.0 * COUNT(DISTINCT CASE
            WHEN a.street = 'preflop'
             AND a.action_type IN ('call','cbr')
            THEN hp.hand_id
        END)
        / COUNT(DISTINCT hp.hand_id) AS VPIP,

        100.0 * COUNT(DISTINCT CASE
            WHEN a.street = 'preflop'
             AND a.action_type = 'cbr'
            THEN hp.hand_id
        END)
        / COUNT(DISTINCT hp.hand_id) AS PFR

    FROM hand_players hp

    JOIN hands h
        ON hp.hand_id = h.hand_id

    LEFT JOIN actions a
        ON hp.hand_id = a.hand_id
       AND a.actor = CONCAT('p', hp.position_index)

    GROUP BY hp.player_id, h.stake

    HAVING COUNT(DISTINCT hp.hand_id) >= 100

) AS player_stats

JOIN hands as h
    ON player_stats.stake = h.stake

JOIN hand_players as hp
    ON hp.hand_id = h.hand_id

GROUP BY h.stake

ORDER BY h.stake;