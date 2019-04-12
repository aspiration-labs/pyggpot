PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS pot (
  id integer NOT NULL PRIMARY KEY AUTOINCREMENT,
  pot_name text NOT NULL UNIQUE,
  max_coins integer NOT NULL,
  create_time DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS coin (
  id integer NOT NULL PRIMARY KEY AUTOINCREMENT,
  denomination integer NOT NULL,
  coin_count integer NOT NULL,
  pot_id integer NOT NULL, FOREIGN KEY (pot_id) REFERENCES pot(id)
);
