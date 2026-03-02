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

-- | Seed the database with sample basins and rainfall scenarios.
seedSampleData :: Connection -> IO ()
seedSampleData conn = do
    -- Check if data already exists
    [Only count] <- query_ conn
        "SELECT COUNT(*) FROM basins" :: IO [Only Int]
    if count > 0
        then putStrLn "Sample data already exists, skipping seed."
        else do
            -- Insert 5 urban sub-basins
            -- (name, elevation_m, slope_%, area_km2)
            execute conn "INSERT INTO basins (name, elevation, slope, area) VALUES (?, ?, ?, ?)"
                ("Adyar Basin" :: Text, 12.0 :: Double, 2.5 :: Double, 45.0 :: Double)
            execute conn "INSERT INTO basins (name, elevation, slope, area) VALUES (?, ?, ?, ?)"
                ("Cooum Basin" :: Text, 8.0 :: Double, 1.8 :: Double, 38.0 :: Double)
            execute conn "INSERT INTO basins (name, elevation, slope, area) VALUES (?, ?, ?, ?)"
                ("Buckingham Canal" :: Text, 3.0 :: Double, 0.5 :: Double, 22.0 :: Double)
            execute conn "INSERT INTO basins (name, elevation, slope, area) VALUES (?, ?, ?, ?)"
                ("Velachery Lake Basin" :: Text, 15.0 :: Double, 3.2 :: Double, 18.0 :: Double)
            execute conn "INSERT INTO basins (name, elevation, slope, area) VALUES (?, ?, ?, ?)"
                ("Pallikaranai Marsh" :: Text, 5.0 :: Double, 0.8 :: Double, 80.0 :: Double)

            -- Insert rainfall scenarios (per IMD categories)
            -- Light Rain
            execute conn "INSERT INTO rainfall_data (basin_id, scenario_name, intensity_mm, duration_hours) VALUES (?, ?, ?, ?)"
                (1 :: Int, "Light Monsoon" :: Text, 15.0 :: Double, 6.0 :: Double)
            execute conn "INSERT INTO rainfall_data (basin_id, scenario_name, intensity_mm, duration_hours) VALUES (?, ?, ?, ?)"
                (2 :: Int, "Light Monsoon" :: Text, 18.0 :: Double, 5.0 :: Double)
            -- Moderate Rain
            execute conn "INSERT INTO rainfall_data (basin_id, scenario_name, intensity_mm, duration_hours) VALUES (?, ?, ?, ?)"
                (1 :: Int, "Moderate Monsoon" :: Text, 55.0 :: Double, 8.0 :: Double)
            execute conn "INSERT INTO rainfall_data (basin_id, scenario_name, intensity_mm, duration_hours) VALUES (?, ?, ?, ?)"
                (3 :: Int, "Moderate Monsoon" :: Text, 65.0 :: Double, 10.0 :: Double)
            -- Heavy Rain
            execute conn "INSERT INTO rainfall_data (basin_id, scenario_name, intensity_mm, duration_hours) VALUES (?, ?, ?, ?)"
                (2 :: Int, "Heavy Monsoon" :: Text, 110.0 :: Double, 12.0 :: Double)
            execute conn "INSERT INTO rainfall_data (basin_id, scenario_name, intensity_mm, duration_hours) VALUES (?, ?, ?, ?)"
                (4 :: Int, "Heavy Monsoon" :: Text, 95.0 :: Double, 9.0 :: Double)
            -- Very Heavy / Extreme
            execute conn "INSERT INTO rainfall_data (basin_id, scenario_name, intensity_mm, duration_hours) VALUES (?, ?, ?, ?)"
                (3 :: Int, "Extreme Event" :: Text, 180.0 :: Double, 24.0 :: Double)
            execute conn "INSERT INTO rainfall_data (basin_id, scenario_name, intensity_mm, duration_hours) VALUES (?, ?, ?, ?)"
                (5 :: Int, "Extreme Event" :: Text, 200.0 :: Double, 18.0 :: Double)
            -- Additional scenarios
            execute conn "INSERT INTO rainfall_data (basin_id, scenario_name, intensity_mm, duration_hours) VALUES (?, ?, ?, ?)"
                (4 :: Int, "Light Monsoon" :: Text, 20.0 :: Double, 4.0 :: Double)
            execute conn "INSERT INTO rainfall_data (basin_id, scenario_name, intensity_mm, duration_hours) VALUES (?, ?, ?, ?)"
                (5 :: Int, "Moderate Monsoon" :: Text, 50.0 :: Double, 7.0 :: Double)

            putStrLn "Sample data seeded successfully."

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
