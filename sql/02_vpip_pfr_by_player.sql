-- VPIP/PFR and hands played across pre-flop action
SELECT hp.player_id, COUNT(DISTINCT hp.hand_id) AS hands_played, # Count all unique hands
    ROUND(
        100.0 * COUNT(DISTINCT CASE -- This is our VPIP - Cleanliness, percent form average, where we called or CBR
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
             AND a.action_type = 'cbr' -- This is our average PFR preflop since CBR is an aggressive action
            THEN a.hand_id
        END)
        / COUNT(DISTINCT hp.hand_id),
        2 # round 2 decimal points
    ) AS PFR

FROM hand_players AS hp

LEFT JOIN actions AS a -- Left join will keep the hands counted  with no qualifying action (ie: everyone folds pre, BB walks) 
    ON hp.hand_id = a.hand_id
   AND a.actor = CONCAT('p', hp.position_index) 
    -- Each player-seat row gets matched to that player's own actions in that hand via the concat
    -- Non-matching seats will keep their row w/ NULL action columns
GROUP BY hp.player_id -- Grouping by player

HAVING COUNT(DISTINCT hp.hand_id) >= 100 -- Players with total hand count over 100

ORDER BY hands_played DESC;
