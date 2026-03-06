{-# LANGUAGE OverloadedStrings #-}

module Database
    ( initializeDB
    , seedSampleData
    , insertBasin
    , getAllBasins
    , getBasinById
    , insertRainfall
    , getAllRainfall
    , getRainfallById
    , insertFloodResult
    , getAllResults
    ) where

import           Database.SQLite.Simple
import           Data.Text              (Text)
import           Types

-- ============================================================
-- Database initialization and schema setup
-- ============================================================

-- | Initialize the database by creating all required tables.
initializeDB :: Connection -> IO ()
initializeDB conn = do
    execute_ conn
        "CREATE TABLE IF NOT EXISTS basins (\
        \id INTEGER PRIMARY KEY AUTOINCREMENT, \
        \name TEXT NOT NULL, \
        \elevation REAL NOT NULL, \
        \slope REAL NOT NULL, \
        \area REAL NOT NULL)"

    execute_ conn
        "CREATE TABLE IF NOT EXISTS rainfall_data (\
        \id INTEGER PRIMARY KEY AUTOINCREMENT, \
        \basin_id INTEGER NOT NULL, \
        \scenario_name TEXT NOT NULL, \
        \intensity_mm REAL NOT NULL, \
        \duration_hours REAL NOT NULL, \
        \FOREIGN KEY (basin_id) REFERENCES basins(id))"

    execute_ conn
        "CREATE TABLE IF NOT EXISTS flood_results (\
        \id INTEGER PRIMARY KEY AUTOINCREMENT, \
        \basin_id INTEGER NOT NULL, \
        \rainfall_id INTEGER NOT NULL, \
        \risk_level TEXT NOT NULL, \
        \calculated_at TEXT NOT NULL, \
        \FOREIGN KEY (basin_id) REFERENCES basins(id), \
        \FOREIGN KEY (rainfall_id) REFERENCES rainfall_data(id))"

-- ============================================================
-- Seed sample data: 5 urban sub-basins with rainfall scenarios
--
-- Basin data inspired by typical Indian urban sub-basins.
-- Rainfall data inspired by IMD precipitation categories.
-- Elevation data inspired by NASA SRTM elevation profiles.
-- ============================================================

-- | Seed the database with comprehensive basin and rainfall data.
--
-- Data sources:
--   - Basin elevations/slopes: Approximate values from NASA SRTM data
--   - Rainfall intensities: Based on IMD precipitation categories
--   - Cities: Major flood-prone Indian urban areas
seedSampleData :: Connection -> IO ()
seedSampleData conn = do
    -- Check if data already exists
    [Only count] <- query_ conn
        "SELECT COUNT(*) FROM basins" :: IO [Only Int]
    if count > 0
        then putStrLn "[DB] Sample data already exists, skipping seed."
        else do
            putStrLn "[DB] Inserting 12 urban sub-basins..."

            -- ====== CHENNAI SUB-BASINS ======
            execute conn "INSERT INTO basins (name, elevation, slope, area) VALUES (?, ?, ?, ?)"
                ("Adyar Basin – Chennai" :: Text, 12.0 :: Double, 2.5 :: Double, 45.0 :: Double)
            execute conn "INSERT INTO basins (name, elevation, slope, area) VALUES (?, ?, ?, ?)"
                ("Cooum Basin – Chennai" :: Text, 8.0 :: Double, 1.8 :: Double, 38.0 :: Double)
            execute conn "INSERT INTO basins (name, elevation, slope, area) VALUES (?, ?, ?, ?)"
                ("Buckingham Canal – Chennai" :: Text, 3.0 :: Double, 0.5 :: Double, 22.0 :: Double)
            execute conn "INSERT INTO basins (name, elevation, slope, area) VALUES (?, ?, ?, ?)"
                ("Velachery Lake Basin – Chennai" :: Text, 15.0 :: Double, 3.2 :: Double, 18.0 :: Double)
            execute conn "INSERT INTO basins (name, elevation, slope, area) VALUES (?, ?, ?, ?)"
                ("Pallikaranai Marsh – Chennai" :: Text, 5.0 :: Double, 0.8 :: Double, 80.0 :: Double)

            -- ====== MUMBAI SUB-BASINS ======
            execute conn "INSERT INTO basins (name, elevation, slope, area) VALUES (?, ?, ?, ?)"
                ("Mithi River Basin – Mumbai" :: Text, 10.0 :: Double, 1.5 :: Double, 73.0 :: Double)
            execute conn "INSERT INTO basins (name, elevation, slope, area) VALUES (?, ?, ?, ?)"
                ("Dahisar River Basin – Mumbai" :: Text, 25.0 :: Double, 4.0 :: Double, 42.0 :: Double)

            -- ====== KOLKATA SUB-BASINS ======
            execute conn "INSERT INTO basins (name, elevation, slope, area) VALUES (?, ?, ?, ?)"
                ("Tolly's Nullah Basin – Kolkata" :: Text, 6.0 :: Double, 0.3 :: Double, 35.0 :: Double)
            execute conn "INSERT INTO basins (name, elevation, slope, area) VALUES (?, ?, ?, ?)"
                ("Salt Lake Basin – Kolkata" :: Text, 4.0 :: Double, 0.2 :: Double, 28.0 :: Double)

            -- ====== BENGALURU SUB-BASINS ======
            execute conn "INSERT INTO basins (name, elevation, slope, area) VALUES (?, ?, ?, ?)"
                ("Vrishabhavathi Basin – Bengaluru" :: Text, 820.0 :: Double, 8.0 :: Double, 55.0 :: Double)

            -- ====== HYDERABAD SUB-BASIN ======
            execute conn "INSERT INTO basins (name, elevation, slope, area) VALUES (?, ?, ?, ?)"
                ("Musi River Basin – Hyderabad" :: Text, 505.0 :: Double, 5.5 :: Double, 62.0 :: Double)

            -- ====== DELHI SUB-BASIN ======
            execute conn "INSERT INTO basins (name, elevation, slope, area) VALUES (?, ?, ?, ?)"
                ("Yamuna Floodplain – Delhi" :: Text, 210.0 :: Double, 2.0 :: Double, 97.0 :: Double)

            putStrLn "[DB] Inserting 30 rainfall scenarios (IMD categories)..."

            -- ====== LIGHT RAIN (IMD: 2.5–15.5 mm/day) ======
            execute conn "INSERT INTO rainfall_data (basin_id, scenario_name, intensity_mm, duration_hours) VALUES (?, ?, ?, ?)"
                (1 :: Int, "Light Monsoon" :: Text, 15.0 :: Double, 6.0 :: Double)
            execute conn "INSERT INTO rainfall_data (basin_id, scenario_name, intensity_mm, duration_hours) VALUES (?, ?, ?, ?)"
                (2 :: Int, "Light Monsoon" :: Text, 18.0 :: Double, 5.0 :: Double)
            execute conn "INSERT INTO rainfall_data (basin_id, scenario_name, intensity_mm, duration_hours) VALUES (?, ?, ?, ?)"
                (6 :: Int, "Light Post-Monsoon" :: Text, 12.0 :: Double, 4.0 :: Double)
            execute conn "INSERT INTO rainfall_data (basin_id, scenario_name, intensity_mm, duration_hours) VALUES (?, ?, ?, ?)"
                (7 :: Int, "Light Drizzle" :: Text, 8.0 :: Double, 3.0 :: Double)
            execute conn "INSERT INTO rainfall_data (basin_id, scenario_name, intensity_mm, duration_hours) VALUES (?, ?, ?, ?)"
                (10 :: Int, "Light Pre-Monsoon" :: Text, 10.0 :: Double, 2.0 :: Double)
            execute conn "INSERT INTO rainfall_data (basin_id, scenario_name, intensity_mm, duration_hours) VALUES (?, ?, ?, ?)"
                (12 :: Int, "Light Monsoon" :: Text, 14.0 :: Double, 5.0 :: Double)

            -- ====== MODERATE RAIN (IMD: 15.6–64.4 mm/day) ======
            execute conn "INSERT INTO rainfall_data (basin_id, scenario_name, intensity_mm, duration_hours) VALUES (?, ?, ?, ?)"
                (1 :: Int, "Moderate Monsoon" :: Text, 55.0 :: Double, 8.0 :: Double)
            execute conn "INSERT INTO rainfall_data (basin_id, scenario_name, intensity_mm, duration_hours) VALUES (?, ?, ?, ?)"
                (3 :: Int, "Moderate Monsoon" :: Text, 65.0 :: Double, 10.0 :: Double)
            execute conn "INSERT INTO rainfall_data (basin_id, scenario_name, intensity_mm, duration_hours) VALUES (?, ?, ?, ?)"
                (5 :: Int, "Moderate Monsoon" :: Text, 50.0 :: Double, 7.0 :: Double)
            execute conn "INSERT INTO rainfall_data (basin_id, scenario_name, intensity_mm, duration_hours) VALUES (?, ?, ?, ?)"
                (6 :: Int, "Moderate Monsoon" :: Text, 60.0 :: Double, 9.0 :: Double)
            execute conn "INSERT INTO rainfall_data (basin_id, scenario_name, intensity_mm, duration_hours) VALUES (?, ?, ?, ?)"
                (8 :: Int, "Moderate Monsoon" :: Text, 58.0 :: Double, 8.0 :: Double)
            execute conn "INSERT INTO rainfall_data (basin_id, scenario_name, intensity_mm, duration_hours) VALUES (?, ?, ?, ?)"
                (9 :: Int, "Moderate Monsoon" :: Text, 62.0 :: Double, 10.0 :: Double)
            execute conn "INSERT INTO rainfall_data (basin_id, scenario_name, intensity_mm, duration_hours) VALUES (?, ?, ?, ?)"
                (11 :: Int, "Moderate Monsoon" :: Text, 45.0 :: Double, 6.0 :: Double)

            -- ====== HEAVY RAIN (IMD: 64.5–115.5 mm/day) ======
            execute conn "INSERT INTO rainfall_data (basin_id, scenario_name, intensity_mm, duration_hours) VALUES (?, ?, ?, ?)"
                (2 :: Int, "Heavy Monsoon" :: Text, 110.0 :: Double, 12.0 :: Double)
            execute conn "INSERT INTO rainfall_data (basin_id, scenario_name, intensity_mm, duration_hours) VALUES (?, ?, ?, ?)"
                (4 :: Int, "Heavy Monsoon" :: Text, 95.0 :: Double, 9.0 :: Double)
            execute conn "INSERT INTO rainfall_data (basin_id, scenario_name, intensity_mm, duration_hours) VALUES (?, ?, ?, ?)"
                (6 :: Int, "Heavy Monsoon Jul 2005" :: Text, 100.0 :: Double, 10.0 :: Double)
            execute conn "INSERT INTO rainfall_data (basin_id, scenario_name, intensity_mm, duration_hours) VALUES (?, ?, ?, ?)"
                (8 :: Int, "Heavy Monsoon" :: Text, 90.0 :: Double, 11.0 :: Double)
            execute conn "INSERT INTO rainfall_data (basin_id, scenario_name, intensity_mm, duration_hours) VALUES (?, ?, ?, ?)"
                (9 :: Int, "Heavy Monsoon" :: Text, 85.0 :: Double, 8.0 :: Double)
            execute conn "INSERT INTO rainfall_data (basin_id, scenario_name, intensity_mm, duration_hours) VALUES (?, ?, ?, ?)"
                (12 :: Int, "Heavy Monsoon Sep 2023" :: Text, 105.0 :: Double, 14.0 :: Double)

            -- ====== VERY HEAVY RAIN (IMD: 115.6–204.4 mm/day) ======
            execute conn "INSERT INTO rainfall_data (basin_id, scenario_name, intensity_mm, duration_hours) VALUES (?, ?, ?, ?)"
                (1 :: Int, "Very Heavy – Dec 2015 Chennai" :: Text, 150.0 :: Double, 18.0 :: Double)
            execute conn "INSERT INTO rainfall_data (basin_id, scenario_name, intensity_mm, duration_hours) VALUES (?, ?, ?, ?)"
                (3 :: Int, "Very Heavy – Nov 2021 Chennai" :: Text, 170.0 :: Double, 20.0 :: Double)
            execute conn "INSERT INTO rainfall_data (basin_id, scenario_name, intensity_mm, duration_hours) VALUES (?, ?, ?, ?)"
                (5 :: Int, "Very Heavy – Cyclone Vardah" :: Text, 140.0 :: Double, 16.0 :: Double)
            execute conn "INSERT INTO rainfall_data (basin_id, scenario_name, intensity_mm, duration_hours) VALUES (?, ?, ?, ?)"
                (6 :: Int, "Very Heavy – Jul 2005 Mumbai" :: Text, 190.0 :: Double, 24.0 :: Double)
            execute conn "INSERT INTO rainfall_data (basin_id, scenario_name, intensity_mm, duration_hours) VALUES (?, ?, ?, ?)"
                (8 :: Int, "Very Heavy – Kolkata Cyclone" :: Text, 160.0 :: Double, 15.0 :: Double)
            execute conn "INSERT INTO rainfall_data (basin_id, scenario_name, intensity_mm, duration_hours) VALUES (?, ?, ?, ?)"
                (11 :: Int, "Very Heavy – Hyderabad 2020" :: Text, 130.0 :: Double, 12.0 :: Double)

            -- ====== EXTREME RAIN (IMD: ≥204.5 mm/day) ======
            execute conn "INSERT INTO rainfall_data (basin_id, scenario_name, intensity_mm, duration_hours) VALUES (?, ?, ?, ?)"
                (3 :: Int, "Extreme – Dec 2015 Flood" :: Text, 250.0 :: Double, 24.0 :: Double)
            execute conn "INSERT INTO rainfall_data (basin_id, scenario_name, intensity_mm, duration_hours) VALUES (?, ?, ?, ?)"
                (5 :: Int, "Extreme – Cyclone Michaung" :: Text, 220.0 :: Double, 20.0 :: Double)
            execute conn "INSERT INTO rainfall_data (basin_id, scenario_name, intensity_mm, duration_hours) VALUES (?, ?, ?, ?)"
                (6 :: Int, "Extreme – Aug 2017 Mumbai" :: Text, 300.0 :: Double, 24.0 :: Double)
            execute conn "INSERT INTO rainfall_data (basin_id, scenario_name, intensity_mm, duration_hours) VALUES (?, ?, ?, ?)"
                (9 :: Int, "Extreme – Amphan Cyclone" :: Text, 210.0 :: Double, 18.0 :: Double)

            putStrLn "[DB] Inserting 15 pre-calculated flood risk results..."

            -- Pre-calculated results (basin_id, rainfall_id, risk_level, timestamp)
            -- These mirror real risk assessments using classifyFloodRisk logic
            execute conn "INSERT INTO flood_results (basin_id, rainfall_id, risk_level, calculated_at) VALUES (?, ?, ?, ?)"
                (1 :: Int, 1 :: Int, "Moderate" :: Text, "2025-06-15T08:30:00" :: Text)
            execute conn "INSERT INTO flood_results (basin_id, rainfall_id, risk_level, calculated_at) VALUES (?, ?, ?, ?)"
                (2 :: Int, 2 :: Int, "Moderate" :: Text, "2025-06-15T08:31:00" :: Text)
            execute conn "INSERT INTO flood_results (basin_id, rainfall_id, risk_level, calculated_at) VALUES (?, ?, ?, ?)"
                (1 :: Int, 7 :: Int, "Moderate" :: Text, "2025-07-01T10:00:00" :: Text)
            execute conn "INSERT INTO flood_results (basin_id, rainfall_id, risk_level, calculated_at) VALUES (?, ?, ?, ?)"
                (3 :: Int, 8 :: Int, "High" :: Text, "2025-07-10T14:20:00" :: Text)
            execute conn "INSERT INTO flood_results (basin_id, rainfall_id, risk_level, calculated_at) VALUES (?, ?, ?, ?)"
                (2 :: Int, 14 :: Int, "Severe" :: Text, "2025-08-01T06:45:00" :: Text)
            execute conn "INSERT INTO flood_results (basin_id, rainfall_id, risk_level, calculated_at) VALUES (?, ?, ?, ?)"
                (5 :: Int, 9 :: Int, "Moderate" :: Text, "2025-08-15T09:10:00" :: Text)
            execute conn "INSERT INTO flood_results (basin_id, rainfall_id, risk_level, calculated_at) VALUES (?, ?, ?, ?)"
                (6 :: Int, 16 :: Int, "Severe" :: Text, "2025-09-01T11:30:00" :: Text)
            execute conn "INSERT INTO flood_results (basin_id, rainfall_id, risk_level, calculated_at) VALUES (?, ?, ?, ?)"
                (6 :: Int, 10 :: Int, "High" :: Text, "2025-09-05T15:00:00" :: Text)
            execute conn "INSERT INTO flood_results (basin_id, rainfall_id, risk_level, calculated_at) VALUES (?, ?, ?, ?)"
                (8 :: Int, 18 :: Int, "High" :: Text, "2025-09-10T07:20:00" :: Text)
            execute conn "INSERT INTO flood_results (basin_id, rainfall_id, risk_level, calculated_at) VALUES (?, ?, ?, ?)"
                (9 :: Int, 19 :: Int, "Severe" :: Text, "2025-09-20T13:45:00" :: Text)
            execute conn "INSERT INTO flood_results (basin_id, rainfall_id, risk_level, calculated_at) VALUES (?, ?, ?, ?)"
                (3 :: Int, 25 :: Int, "Severe" :: Text, "2025-10-01T04:00:00" :: Text)
            execute conn "INSERT INTO flood_results (basin_id, rainfall_id, risk_level, calculated_at) VALUES (?, ?, ?, ?)"
                (5 :: Int, 26 :: Int, "Severe" :: Text, "2025-10-05T16:30:00" :: Text)
            execute conn "INSERT INTO flood_results (basin_id, rainfall_id, risk_level, calculated_at) VALUES (?, ?, ?, ?)"
                (10 :: Int, 5 :: Int, "Low" :: Text, "2025-06-20T10:15:00" :: Text)
            execute conn "INSERT INTO flood_results (basin_id, rainfall_id, risk_level, calculated_at) VALUES (?, ?, ?, ?)"
                (11 :: Int, 22 :: Int, "Moderate" :: Text, "2025-08-25T12:00:00" :: Text)
            execute conn "INSERT INTO flood_results (basin_id, rainfall_id, risk_level, calculated_at) VALUES (?, ?, ?, ?)"
                (12 :: Int, 6 :: Int, "Low" :: Text, "2025-07-15T08:00:00" :: Text)

            putStrLn "[DB] Done! Seeded 12 basins, 30 rainfall scenarios, 15 flood results."

-- ============================================================
-- Basin operations
-- ============================================================

insertBasin :: Connection -> Text -> Double -> Double -> Double -> IO ()
insertBasin conn name elev slopeVal areaVal =
    execute conn
        "INSERT INTO basins (name, elevation, slope, area) VALUES (?, ?, ?, ?)"
        (name, elev, slopeVal, areaVal)

getAllBasins :: Connection -> IO [Basin]
getAllBasins conn =
    query_ conn "SELECT id, name, elevation, slope, area FROM basins"

getBasinById :: Connection -> Int -> IO [Basin]
getBasinById conn bid =
    query conn "SELECT id, name, elevation, slope, area FROM basins WHERE id = ?" (Only bid)

-- ============================================================
-- Rainfall operations
-- ============================================================

insertRainfall :: Connection -> Int -> Text -> Double -> Double -> IO ()
insertRainfall conn bid sname intensity duration =
    execute conn
        "INSERT INTO rainfall_data (basin_id, scenario_name, intensity_mm, duration_hours) VALUES (?, ?, ?, ?)"
        (bid, sname, intensity, duration)

getAllRainfall :: Connection -> IO [RainfallScenario]
getAllRainfall conn =
    query_ conn "SELECT id, basin_id, scenario_name, intensity_mm, duration_hours FROM rainfall_data"

getRainfallById :: Connection -> Int -> IO [RainfallScenario]
getRainfallById conn rid =
    query conn "SELECT id, basin_id, scenario_name, intensity_mm, duration_hours FROM rainfall_data WHERE id = ?" (Only rid)

-- ============================================================
-- Flood result operations
-- ============================================================

insertFloodResult :: Connection -> Int -> Int -> Text -> Text -> IO ()
insertFloodResult conn bid rid risk timestamp =
    execute conn
        "INSERT INTO flood_results (basin_id, rainfall_id, risk_level, calculated_at) VALUES (?, ?, ?, ?)"
        (bid, rid, risk, timestamp)

getAllResults :: Connection -> IO [FloodResult]
getAllResults conn =
    query_ conn "SELECT id, basin_id, rainfall_id, risk_level, calculated_at FROM flood_results"
