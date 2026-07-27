# VPIP/PFR and hands played across pre-flop action
SELECT hp.player_id, COUNT(DISTINCT hp.hand_id) AS hands_played, # Count all unique hands
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
