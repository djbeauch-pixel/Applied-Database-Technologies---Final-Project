import streamlit as st
import mysql.connector

st.title("Online Poker Analytics Circa 2009 - Samples Across 50NL, 200NL and 1000NL x Sites")

conn = mysql.connector.connect(host="localhost", user="root", password="root", database="poker_database")
cursor = conn.cursor()
cursor.execute("SELECT COUNT(*) FROM hands")
total_hands = cursor.fetchone()[0]

st.metric(label="Total Hands in Database", value=f"{total_hands:,}")

cursor.execute("SELECT COUNT(*) FROM players")
total_players = cursor.fetchone()[0]

cursor.execute("SELECT COUNT(*) FROM hand_players")
total_seats = cursor.fetchone()[0]

cursor.execute("SELECT COUNT(*) FROM actions")
total_actions = cursor.fetchone()[0]

col1, col2, col3 = st.columns(3)
col1.metric("Total Players", f"{total_players:,}")
col2.metric("Total Seats", f"{total_seats:,}")
col3.metric("Total Actions", f"{total_actions:,}")

import pandas as pd

# Table 2: VPIP / PFR by player
st.subheader("VPIP / PFR by Player")

vpip_pfr_query = """
    SELECT
        hp.player_id,
        COUNT(DISTINCT hp.hand_id) AS hands_played,
        ROUND(
            100.0 * COUNT(DISTINCT CASE
                WHEN a.street = 'preflop' AND a.action_type IN ('call', 'cbr')
                THEN a.hand_id
            END)
            / COUNT(DISTINCT hp.hand_id),
            2
        ) AS VPIP,
        ROUND(
            100.0 * COUNT(DISTINCT CASE
                WHEN a.street = 'preflop' AND a.action_type = 'cbr'
                THEN a.hand_id
            END)
            / COUNT(DISTINCT hp.hand_id),
            2
        ) AS PFR
    FROM hand_players AS hp
    LEFT JOIN actions AS a
        ON hp.hand_id = a.hand_id
       AND a.actor = CONCAT('p', hp.position_index)
    GROUP BY hp.player_id
    HAVING COUNT(DISTINCT hp.hand_id) >= 100
    ORDER BY hands_played DESC
"""

vpip_pfr_df = pd.read_sql(vpip_pfr_query, conn)
st.dataframe(vpip_pfr_df, use_container_width=True)

# Table 3: VPIP / PFR by stake (all sites combined)
st.subheader("VPIP / PFR by Stake")

stake_query = """
    SELECT
        stake,
        COUNT(*) AS qualifying_players,
        SUM(hands_played) AS total_hands,
        ROUND(AVG(VPIP), 2) AS avg_VPIP,
        ROUND(AVG(PFR), 2) AS avg_PFR
    FROM (
        SELECT
            hp.player_id,
            h.stake,
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
        GROUP BY hp.player_id, h.stake
        HAVING COUNT(DISTINCT hp.hand_id) >= 100
    ) AS player_stats
    GROUP BY stake
    ORDER BY stake
"""

stake_df = pd.read_sql(stake_query, conn)
st.dataframe(stake_df, use_container_width=True)

# Chart: VPIP / PFR across stakes
st.subheader("VPIP / PFR Across Stakes")

chart_df = stake_df.set_index("stake")[["avg_VPIP", "avg_PFR"]]
st.line_chart(chart_df)

# Table 4: VPIP / PFR by stake and site - More Granular
st.subheader("VPIP / PFR by Stake and Site - Players Qualify w/ 100 Hands or More")

stake_site_query = """
    SELECT
        stake,
        site,
        COUNT(*) AS qualifying_players,
        SUM(hands_played) AS total_hands,
        ROUND(AVG(VPIP), 2) AS avg_VPIP,
        ROUND(AVG(PFR), 2) AS avg_PFR
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
    ORDER BY stake, site
"""

stake_site_df = pd.read_sql(stake_site_query, conn)
st.dataframe(stake_site_df, use_container_width=True)

# Still under construction
showdown_query = """
    SELECT
        hf.stake,
        SUM(CASE WHEN hf.is_showdown = 1 THEN COALESCE(hp.winnings, 0) ELSE 0 END) AS showdown_winnings,
        SUM(CASE WHEN hf.is_showdown = 0 THEN COALESCE(hp.winnings, 0) ELSE 0 END) AS non_showdown_winnings
    FROM (
        SELECT
            h.hand_id,
            h.stake,
            CASE
                WHEN hs.reached_river = 1
                 AND (h.n_players - hs.folded_count) >= 2
                THEN 1 ELSE 0
            END AS is_showdown
        FROM hands h
        JOIN (
            SELECT
                a.hand_id,
                MAX(CASE WHEN a.street = 'river' THEN 1 ELSE 0 END) AS reached_river,
                COUNT(DISTINCT CASE WHEN a.action_type = 'f' THEN a.actor END) AS folded_count
            FROM actions a
            GROUP BY a.hand_id
        ) AS hs ON hs.hand_id = h.hand_id
    ) AS hf
    JOIN hand_players hp ON hp.hand_id = hf.hand_id
    GROUP BY hf.stake
    ORDER BY hf.stake
"""

showdown_df = pd.read_sql(showdown_query, conn)
st.dataframe(showdown_df, use_container_width=True)

chart_df2 = showdown_df.set_index("stake")[["showdown_winnings", "non_showdown_winnings"]]
st.bar_chart(chart_df2)