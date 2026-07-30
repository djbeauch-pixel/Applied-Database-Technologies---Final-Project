This Repo includes MySQL-backed analytics application for online poker hand history data.
Raw hand-history files are parsed and loaded into a relational database via a Python ETL pipeline, then queried and visualized through a Streamlit app.

Dataset: A Dataset of Poker Hand Histories, Kim J - please see report for reference URL and source material.
My Repo Structure includes the app.py, my streamlit application (see showdown query/under construction), etl folder with my poker parser, my database design under schema and my sql queries in the sql folder.

Database Schema:
Four tables: players -> hand_players <- hands -> actions, linked by player_id and hand_id.

Running locally: Set up MySQL Run schema/poker_database_design.sql to create the database and tables.
Load data by opening etl file, point root_folder at the local .phhs files and run the notebook.

Set up app:
python -m venv venv
venv\Scripts\activate          # Windows
streamlit run app.py

The app connects to poker_database on localhost by default, update if your connection details differ.

Tech Stack:
Python · Jupyter · MySQL · Streamlit · pandas · tomllib

Author: David Beauchamp - Applied Database Technologies, Final Project
