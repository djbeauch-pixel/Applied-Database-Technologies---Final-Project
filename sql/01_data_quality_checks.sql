# Reviewing Numbers of data inserted into database
SELECT COUNT(*) AS hands FROM hands;
SELECT COUNT(*) AS players FROM players;
SELECT COUNT(*) AS seats FROM hand_players;
SELECT COUNT(*) AS actions FROM actions;
SELECT stake, COUNT(*) AS hands FROM hands GROUP BY stake;
