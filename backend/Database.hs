{-# LANGUAGE OverloadedStrings #-}

module Database
    ( initializeDB
    , seedSampleData
    , getAllBasins
    , getBasinById
    , getAllScenarios
    , getScenarioById
    , insertRiskResult
    , getAllResults
    , clearResults
    ) where

import           Database.SQLite.Simple
import           Database.SQLite.Simple.ToField (toField)
import           Data.Text              (Text)
import           Types

initializeDB :: Connection -> IO ()
initializeDB conn = do
    -- Enable WAL mode for better concurrent read/write
    execute_ conn "PRAGMA journal_mode=WAL"

    execute_ conn
        "CREATE TABLE IF NOT EXISTS basins (\
        \id INTEGER PRIMARY KEY AUTOINCREMENT, \
        \name TEXT NOT NULL, city TEXT NOT NULL, country TEXT NOT NULL, \
        \elevation REAL NOT NULL, slope REAL NOT NULL, area REAL NOT NULL, \
        \drainage_density REAL NOT NULL, impervious_ratio REAL NOT NULL, \
        \runoff_coeff REAL NOT NULL, mannings_n REAL NOT NULL, \
        \time_of_conc REAL NOT NULL)"

    execute_ conn
        "CREATE TABLE IF NOT EXISTS precipitation_scenarios (\
        \id INTEGER PRIMARY KEY AUTOINCREMENT, \
        \scenario_type TEXT NOT NULL, name TEXT NOT NULL, \
        \intensity_mm REAL NOT NULL, return_period INTEGER NOT NULL, \
        \duration_hours REAL NOT NULL, reference TEXT NOT NULL)"

    execute_ conn
        "CREATE TABLE IF NOT EXISTS risk_results (\
        \id INTEGER PRIMARY KEY AUTOINCREMENT, \
        \basin_id INTEGER NOT NULL, scenario_id INTEGER NOT NULL, \
        \si_score REAL NOT NULL, risk_level TEXT NOT NULL, \
        \sensitivity TEXT NOT NULL, calculated_at TEXT NOT NULL, \
        \FOREIGN KEY (basin_id) REFERENCES basins(id), \
        \FOREIGN KEY (scenario_id) REFERENCES precipitation_scenarios(id))"

insertBasin :: Connection -> Text -> Text -> Text -> Double -> Double -> Double -> Double -> Double -> Double -> Double -> Double -> IO ()
insertBasin conn name_ city_ country_ elev slopeV areaV dd isr c_ mann toc =
    execute conn
        "INSERT INTO basins (name, city, country, elevation, slope, area, \
        \drainage_density, impervious_ratio, runoff_coeff, mannings_n, time_of_conc) \
        \VALUES (?,?,?,?,?,?,?,?,?,?,?)"
        [ toField name_, toField city_, toField country_
        , toField elev, toField slopeV, toField areaV
        , toField dd, toField isr, toField c_
        , toField mann, toField toc ]

seedSampleData :: Connection -> IO ()
seedSampleData conn = do
    [Only bCount] <- query_ conn
        "SELECT COUNT(*) FROM basins" :: IO [Only Int]
    [Only sCount] <- query_ conn
        "SELECT COUNT(*) FROM precipitation_scenarios" :: IO [Only Int]
    if bCount >= 50 && sCount >= 5
        then putStrLn "[DB] Sample data already exists, skipping seed."
        else do
            putStrLn "[DB] Clearing partial data..."
            execute_ conn "DELETE FROM risk_results"
            execute_ conn "DELETE FROM basins"
            execute_ conn "DELETE FROM precipitation_scenarios"
            putStrLn "[DB] Inserting 50 urban sub-basins..."

            -- ============= INDIA (8 basins) =============
            insertBasin conn "Adyar Basin" "Chennai" "India"
                6.0 1.5 45.0 3.1 0.65 0.72 0.025 120.0
            insertBasin conn "Cooum Basin" "Chennai" "India"
                4.0 1.0 38.0 2.8 0.70 0.78 0.025 100.0
            insertBasin conn "Mithi River Basin" "Mumbai" "India"
                10.0 1.5 73.0 2.5 0.75 0.85 0.020 90.0
            insertBasin conn "Musi River Basin" "Hyderabad" "India"
                505.0 3.5 62.0 2.2 0.55 0.60 0.030 180.0
            insertBasin conn "Yamuna Floodplain" "Delhi" "India"
                213.0 0.8 48.0 1.9 0.72 0.80 0.022 130.0
            insertBasin conn "Vrishabhavathi Basin" "Bengaluru" "India"
                890.0 2.0 38.0 2.4 0.60 0.65 0.028 140.0
            insertBasin conn "Bisalpur Canal Basin" "Jaipur" "India"
                431.0 2.5 29.0 1.7 0.45 0.52 0.032 160.0
            insertBasin conn "Gomti Basin" "Lucknow" "India"
                120.0 0.4 55.0 1.5 0.50 0.58 0.030 200.0

            -- ============= SOUTHEAST ASIA (7 basins) =============
            insertBasin conn "Ciliwung Basin" "Jakarta" "Indonesia"
                5.0 2.0 387.0 1.8 0.68 0.75 0.022 150.0
            insertBasin conn "Pasig River Basin" "Manila" "Philippines"
                8.0 0.6 620.0 2.1 0.62 0.70 0.024 170.0
            insertBasin conn "Chao Phraya Delta" "Bangkok" "Thailand"
                2.0 0.3 160.0 1.4 0.58 0.68 0.020 210.0
            insertBasin conn "Klang River Basin" "Kuala Lumpur" "Malaysia"
                35.0 3.0 468.0 2.6 0.55 0.62 0.026 140.0
            insertBasin conn "To Lich River Basin" "Hanoi" "Vietnam"
                6.0 0.5 78.0 1.8 0.64 0.72 0.022 120.0
            insertBasin conn "Saigon River Basin" "Ho Chi Minh City" "Vietnam"
                4.0 0.3 4717.0 1.6 0.52 0.60 0.024 180.0
            insertBasin conn "Ayeyarwady Delta" "Yangon" "Myanmar"
                5.0 0.2 38.0 1.3 0.48 0.55 0.028 220.0

            -- ============= EAST ASIA (6 basins) =============
            insertBasin conn "Shenzhen River Basin" "Shenzhen" "China"
                45.0 4.5 312.0 3.2 0.72 0.82 0.018 80.0
            insertBasin conn "Suzhou Creek Basin" "Shanghai" "China"
                4.0 0.2 125.0 2.0 0.78 0.88 0.016 100.0
            insertBasin conn "Pearl River Delta" "Guangzhou" "China"
                11.0 0.5 52.0 2.3 0.65 0.74 0.020 130.0
            insertBasin conn "Yangtze Floodplain" "Wuhan" "China"
                23.0 0.3 55.0 1.7 0.58 0.66 0.022 160.0
            insertBasin conn "Kanda River Basin" "Tokyo" "Japan"
                30.0 3.8 105.0 4.2 0.82 0.90 0.015 60.0
            insertBasin conn "Tsurumi River Basin" "Yokohama" "Japan"
                25.0 3.2 235.0 3.8 0.70 0.78 0.018 90.0

            -- ============= SOUTH ASIA (5 basins) =============
            insertBasin conn "Buriganga Basin" "Dhaka" "Bangladesh"
                4.0 0.2 30.0 1.2 0.68 0.76 0.025 140.0
            insertBasin conn "Lai Nullah Basin" "Islamabad" "Pakistan"
                507.0 5.0 234.0 2.8 0.40 0.50 0.035 110.0
            insertBasin conn "Kandy Lake Basin" "Kandy" "Sri Lanka"
                500.0 8.0 18.0 3.5 0.35 0.42 0.035 70.0
            insertBasin conn "Bishnumati Basin" "Kathmandu" "Nepal"
                1300.0 6.0 102.0 3.0 0.45 0.52 0.030 90.0
            insertBasin conn "Kabul River Basin" "Kabul" "Afghanistan"
                1790.0 7.0 565.0 2.2 0.25 0.35 0.040 200.0

            -- ============= AFRICA (6 basins) =============
            insertBasin conn "Jukskei River Basin" "Johannesburg" "South Africa"
                1650.0 3.5 540.0 2.8 0.48 0.55 0.030 150.0
            insertBasin conn "Nairobi River Basin" "Nairobi" "Kenya"
                1660.0 4.0 98.0 2.5 0.42 0.50 0.032 130.0
            insertBasin conn "Oshiwara River Basin" "Lagos" "Nigeria"
                5.0 0.3 42.0 1.1 0.62 0.70 0.025 180.0
            insertBasin conn "Oued El Harrach" "Algiers" "Algeria"
                60.0 6.5 1250.0 3.0 0.38 0.45 0.035 120.0
            insertBasin conn "Nile Delta Basin" "Cairo" "Egypt"
                20.0 0.2 180.0 0.8 0.55 0.62 0.028 250.0
            insertBasin conn "Msimbazi Basin" "Dar es Salaam" "Tanzania"
                15.0 1.8 270.0 1.9 0.40 0.48 0.030 170.0

            -- ============= EUROPE (6 basins) =============
            insertBasin conn "Seine Floodplain" "Paris" "France"
                33.0 0.5 35.0 2.5 0.72 0.80 0.018 120.0
            insertBasin conn "Thames Tideway" "London" "UK"
                5.0 0.3 28.0 3.0 0.78 0.85 0.016 100.0
            insertBasin conn "Tiber Floodplain" "Rome" "Italy"
                20.0 1.5 45.0 2.2 0.65 0.72 0.022 130.0
            insertBasin conn "Isar River Basin" "Munich" "Germany"
                519.0 3.0 148.0 2.8 0.52 0.58 0.025 140.0
            insertBasin conn "Danube Floodplain" "Budapest" "Hungary"
                96.0 0.5 525.0 1.8 0.55 0.62 0.024 180.0
            insertBasin conn "Spree River Basin" "Berlin" "Germany"
                34.0 0.3 55.0 1.6 0.58 0.65 0.022 160.0

            -- ============= NORTH AMERICA (6 basins) =============
            insertBasin conn "Brays Bayou" "Houston" "USA"
                12.0 0.5 330.0 0.96 0.55 0.65 0.018 240.0
            insertBasin conn "Anacostia Basin" "Washington DC" "USA"
                30.0 3.0 460.0 2.0 0.23 0.45 0.035 300.0
            insertBasin conn "Gowanus Canal Basin" "New York" "USA"
                3.0 0.2 4.5 3.5 0.92 0.95 0.012 30.0
            insertBasin conn "Don River Basin" "Toronto" "Canada"
                76.0 2.5 360.0 2.6 0.42 0.50 0.028 180.0
            insertBasin conn "Los Angeles River Basin" "Los Angeles" "USA"
                85.0 2.0 2160.0 1.2 0.60 0.68 0.020 200.0
            insertBasin conn "Chicagoland Basin" "Chicago" "USA"
                180.0 0.3 45.0 2.0 0.70 0.78 0.018 150.0

            -- ============= LATIN AMERICA (4 basins) =============
            insertBasin conn "Tiete River Basin" "Sao Paulo" "Brazil"
                760.0 1.5 5985.0 1.8 0.58 0.65 0.024 200.0
            insertBasin conn "Rimac River Basin" "Lima" "Peru"
                150.0 12.0 3312.0 2.5 0.50 0.58 0.030 110.0
            insertBasin conn "Bogota River Basin" "Bogota" "Colombia"
                2640.0 2.0 590.0 1.6 0.48 0.55 0.028 180.0
            insertBasin conn "Reconquista Basin" "Buenos Aires" "Argentina"
                5.0 0.2 1738.0 1.3 0.55 0.62 0.025 240.0

            -- ============= MIDDLE EAST (2 basins) =============
            insertBasin conn "Wadi Hanifah Basin" "Riyadh" "Saudi Arabia"
                612.0 1.5 4130.0 0.9 0.35 0.42 0.038 280.0
            insertBasin conn "Jeddah Wadi Basin" "Jeddah" "Saudi Arabia"
                15.0 3.0 350.0 1.4 0.45 0.55 0.032 120.0

            putStrLn "[DB] Inserting 5 precipitation scenarios..."

            execute conn "INSERT INTO precipitation_scenarios (scenario_type, name, intensity_mm, return_period, duration_hours, reference) VALUES (?,?,?,?,?,?)"
                ("Normal" :: Text, "Normal Rainfall" :: Text, 15.0::Double, 1::Int, 6.0::Double, "IMD Light Rain Category (2.5-15.5 mm/day)" :: Text)
            execute conn "INSERT INTO precipitation_scenarios (scenario_type, name, intensity_mm, return_period, duration_hours, reference) VALUES (?,?,?,?,?,?)"
                ("ModerateStorm" :: Text, "Moderate Storm (2-yr)" :: Text, 40.0::Double, 2::Int, 4.0::Double, "IMD Moderate Rain (15.6-64.4 mm/day), 2-year ARI" :: Text)
            execute conn "INSERT INTO precipitation_scenarios (scenario_type, name, intensity_mm, return_period, duration_hours, reference) VALUES (?,?,?,?,?,?)"
                ("HeavyStorm" :: Text, "Heavy Storm (10-yr)" :: Text, 75.0::Double, 10::Int, 6.0::Double, "IMD Heavy Rain (64.5-115.5 mm/day), 10-year ARI" :: Text)
            execute conn "INSERT INTO precipitation_scenarios (scenario_type, name, intensity_mm, return_period, duration_hours, reference) VALUES (?,?,?,?,?,?)"
                ("ExtremeEvent" :: Text, "Extreme Event (50-yr)" :: Text, 120.0::Double, 50::Int, 12.0::Double, "Chennai 2015 / Mumbai 2005 flood reference, 50-year ARI" :: Text)
            execute conn "INSERT INTO precipitation_scenarios (scenario_type, name, intensity_mm, return_period, duration_hours, reference) VALUES (?,?,?,?,?,?)"
                ("Catastrophic" :: Text, "Catastrophic (100-yr)" :: Text, 200.0::Double, 100::Int, 24.0::Double, "IPCC AR6 Climate Scenario, 100-year ARI projection" :: Text)

            putStrLn "[DB] Done! Seeded 50 basins, 5 precipitation scenarios."

getAllBasins :: Connection -> IO [SubBasin]
getAllBasins conn =
    query_ conn "SELECT id, name, city, country, elevation, slope, area, \
                \drainage_density, impervious_ratio, runoff_coeff, mannings_n, \
                \time_of_conc FROM basins"

getBasinById :: Connection -> Int -> IO [SubBasin]
getBasinById conn bid =
    query conn "SELECT id, name, city, country, elevation, slope, area, \
               \drainage_density, impervious_ratio, runoff_coeff, mannings_n, \
               \time_of_conc FROM basins WHERE id = ?" (Only bid)

getAllScenarios :: Connection -> IO [PrecipScenarioData]
getAllScenarios conn =
    query_ conn "SELECT id, scenario_type, name, intensity_mm, return_period, \
                \duration_hours, reference FROM precipitation_scenarios"

getScenarioById :: Connection -> Int -> IO [PrecipScenarioData]
getScenarioById conn sid =
    query conn "SELECT id, scenario_type, name, intensity_mm, return_period, \
               \duration_hours, reference FROM precipitation_scenarios WHERE id = ?" (Only sid)

insertRiskResult :: Connection -> Int -> Int -> Double -> Text -> Text -> Text -> IO ()
insertRiskResult conn bid sid si risk sens timestamp =
    execute conn
        "INSERT INTO risk_results (basin_id, scenario_id, si_score, risk_level, \
        \sensitivity, calculated_at) VALUES (?, ?, ?, ?, ?, ?)"
        (bid, sid, si, risk, sens, timestamp)

getAllResults :: Connection -> IO [RiskResult]
getAllResults conn =
    query_ conn "SELECT id, basin_id, scenario_id, si_score, risk_level, \
                \sensitivity, calculated_at FROM risk_results"

clearResults :: Connection -> IO ()
clearResults conn =
    execute_ conn "DELETE FROM risk_results"
