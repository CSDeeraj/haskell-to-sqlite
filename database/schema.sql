-- Flood Susceptibility Database Schema
-- Tables for urban sub-basin flood risk modeling

CREATE TABLE IF NOT EXISTS basins (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    name        TEXT    NOT NULL,
    elevation   REAL    NOT NULL,  -- meters above sea level
    slope       REAL    NOT NULL,  -- percentage gradient
    area        REAL    NOT NULL   -- square kilometers
);

CREATE TABLE IF NOT EXISTS rainfall_data (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    basin_id        INTEGER NOT NULL,
    scenario_name   TEXT    NOT NULL,
    intensity_mm    REAL    NOT NULL,   -- mm per hour
    duration_hours  REAL    NOT NULL,
    FOREIGN KEY (basin_id) REFERENCES basins(id)
);

CREATE TABLE IF NOT EXISTS flood_results (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    basin_id        INTEGER NOT NULL,
    rainfall_id     INTEGER NOT NULL,
    risk_level      TEXT    NOT NULL,   -- Low, Moderate, High, Severe
    calculated_at   TEXT    NOT NULL,   -- ISO 8601 timestamp
    FOREIGN KEY (basin_id) REFERENCES basins(id),
    FOREIGN KEY (rainfall_id) REFERENCES rainfall_data(id)
);
