# Creating Database
DROP DATABASE IF EXISTS poker_database;
CREATE DATABASE poker_database;
# Put tables within the poker_database
USE poker_database;

# Creating our first table 'players' with player_id as primary key and player_token as a unique key
CREATE TABLE players (
    player_id INT AUTO_INCREMENT PRIMARY KEY, # DB indexed unique id primary key
    player_token VARCHAR(50) NOT NULL UNIQUE # Setting a higher ceiling for varying sites ID lengths
);

# Creating 2nd table 'hands'
CREATE TABLE hands (
	hand_id INT AUTO_INCREMENT PRIMARY KEY, # Auto generated hand_id column to distinguish IDs across sites
    site_hand_id VARCHAR(50) NOT NULL, # Values exceed 16 billion upon review, Unique for each site
    variant VARCHAR(25) NOT NULL, # All hands should be NT (No Limit Texas Hold'em)
    site VARCHAR(20) NOT NULL, # Maps to 'Venue'
    stake VARCHAR(10) NOT NULL,
    blind_level DECIMAL(8,2) NOT NULL, # Biggest Game we're plaaying is 600NL
    tble_name VARCHAR (150), # Sometimes there can be long, interesting table names
    played_at DATETIME NOT NULL, # Time/Day/Month/Year combined into played_at
    time_zone VARCHAR(8),
    min_bet DECIMAL(8,2) NOT NULL,
    n_players INT NOT NULL, # A count of how many players are in the hand
	UNIQUE (site, site_hand_id) # The combo of site & its site hand ID must be unique
    );

CREATE TABLE hand_players(
	hand_id INT NOT NULL, # FK distinguised below
    player_id INT NOT NULL, # FK distinguished below
    position_index INT NOT NULL, # Player's table position for this hand
    seat_no INT NOT NULL, # Physical seat number at the table
    starting_stack DECIMAL(8,2) NULL, # Unique to each player, boundaries should be fine
    blind_posted DECIMAL(8,2) NULL DEFAULT 0, # Default numbers are 0 unless otherwise noted for this, ante and winnings
    ante DECIMAL(8,2) NULL DEFAULT 0, 
    winnings DECIMAL(8,2) NULL DEFAULT 0, # Ran into errors across sites, maybe due to chops or a different key. changed to null
    PRIMARY KEY(hand_id, position_index), # Unique composite key ensuring each position appears only once per hand
    KEY idx_player(player_id),  # For player lookup efficiency
    CONSTRAINT fk_hp_player FOREIGN KEY(player_id) REFERENCES players(player_id), # Ensures player_id exists in players table
    CONSTRAINT fk_hp_hand FOREIGN KEY (hand_id) REFERENCES hands(hand_id) # Ensures hand_id exists in hands table
    );
    
CREATE TABLE actions(
	hand_id INT NOT NULL, # FK
    action_order INT NOT NULL, 
    actor VARCHAR(10) NOT NULL, # Dealer/Player(1-9)
    street ENUM('preflop','flop','turn','river') NOT NULL,
    action_type VARCHAR(12) NOT NULL, # Fold, check, call, raise
	amount DECIMAL(8,2) NULL, # Null for f/cc
    cards VARCHAR(16) NULL, # Board cards on deal_board
	PRIMARY KEY (hand_id, action_order), # Composite key for hand_id and action order
    KEY idx_street_type(street, action_type), # Index for street/action
    CONSTRAINT fk_actions_hand FOREIGN KEY(hand_id) REFERENCES hands(hand_id)); # FK constraint/reference
