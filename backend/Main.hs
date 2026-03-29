{-# LANGUAGE OverloadedStrings #-}

module Main where

import           Web.Scotty                      (scottyOpts, middleware, Options(..))
import           Network.Wai.Middleware.Static    (staticPolicy, addBase)
import           Database.SQLite.Simple           (open)
import           Network.Wai.Handler.Warp        (setPort, setHost, defaultSettings)
import           Data.String                     (fromString)
import           System.Environment              (lookupEnv)
import           Network.Wai.Middleware.Cors     (cors, corsOrigins, corsMethods, corsRequestHeaders, corsMaxAge, simpleCorsResourcePolicy, CorsResourcePolicy)
import           Data.Maybe                      (fromMaybe)

import           Database                        (initializeDB, seedSampleData)
import           Api                             (app)

-- ============================================================
-- Main entry point
--
-- 1. Opens (or creates) the SQLite database
-- 2. Initializes tables (basins, precipitation_scenarios, risk_results)
-- 3. Seeds sample data (7 basins + 5 scenarios)
-- 4. Starts the Scotty web server on port 3000
-- 5. Serves the frontend as static files
-- 6. Binds to 0.0.0.0 for Codespaces compatibility
-- ============================================================

main :: IO ()
main = do
    putStrLn "==========================================================="
    putStrLn "  Deterministic Flood Susceptibility Modeling System"
    putStrLn "  Urban Sub-Basins Under Varying Precipitation Scenarios"
    putStrLn "==========================================================="
    putStrLn ""

    -- Initialize database
    putStrLn "[DB] Opening database: flood_susceptibility.db"
    conn <- open "flood_susceptibility.db"

    putStrLn "[DB] Initializing tables..."
    initializeDB conn

    putStrLn "[DB] Seeding sample data..."
    seedSampleData conn

    portStr <- lookupEnv "PORT"
    let port = read (fromMaybe "3000" portStr) :: Int

    putStrLn ""
    putStrLn $ "[SERVER] Starting on http://0.0.0.0:" ++ show port
    putStrLn "[SERVER] Frontend available at http://localhost:3000/index.html"
    putStrLn "[SERVER] API endpoints:"
    putStrLn "  GET  /api/basins             - All sub-basins with parameters"
    putStrLn "  GET  /api/scenarios          - All precipitation scenarios"
    putStrLn "  POST /api/classify           - Classify risk (basin + scenario)"
    putStrLn "  POST /api/classify-all       - Classify basin across all scenarios"
    putStrLn "  GET  /api/results            - All stored risk results"
    putStrLn "  GET  /api/basin-coordinates  - Basins with coordinates + risk"
    putStrLn "  GET  /api/scenario-matrix    - Full basin x scenario matrix"
    putStrLn ""

    let warpSettings = setPort port $ setHost (fromString "0.0.0.0") defaultSettings
        opts = Options 1 warpSettings True

    let corsPolicy = simpleCorsResourcePolicy
            { corsOrigins = Just (["https://flood-susceptibility.vercel.app", "http://localhost:5173", "http://localhost:3000"], True)
            , corsMethods = ["GET", "POST", "OPTIONS"]
            , corsRequestHeaders = ["Content-Type"]
            , corsMaxAge = Just 86400
            }

    scottyOpts opts $ do
        middleware $ cors (const $ Just corsPolicy)
        middleware $ staticPolicy (addBase "frontend/dist")
        app conn
