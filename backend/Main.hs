{-# LANGUAGE OverloadedStrings #-}

module Main where

import           Web.Scotty                      (scottyOpts, middleware, Options(..))
import           Network.Wai.Middleware.Static    (staticPolicy, addBase)
import           Database.SQLite.Simple           (open)
import           Network.Wai.Handler.Warp        (setPort, setHost, defaultSettings)
import           Data.String                     (fromString)

import           Database                        (initializeDB, seedSampleData)
import           Api                             (app)

-- ============================================================
-- Main entry point
--
-- 1. Opens (or creates) the SQLite database
-- 2. Initializes tables
-- 3. Seeds sample data (basins + rainfall scenarios)
-- 4. Starts the Scotty web server on port 3000
-- 5. Serves the frontend as static files
-- 6. Binds to 0.0.0.0 for GitHub Codespaces compatibility
-- ============================================================

main :: IO ()
main = do
    putStrLn "==========================================================="
    putStrLn "  Flood Susceptibility Modeling System"
    putStrLn "  Deterministic modeling for urban sub-basins"
    putStrLn "==========================================================="
    putStrLn ""

    -- Initialize database
    putStrLn "[DB] Opening database: flood_susceptibility.db"
    conn <- open "flood_susceptibility.db"

    putStrLn "[DB] Initializing tables..."
    initializeDB conn

    putStrLn "[DB] Seeding sample data..."
    seedSampleData conn

    putStrLn ""
    putStrLn "[SERVER] Starting on http://0.0.0.0:3000"
    putStrLn "[SERVER] Frontend available at http://localhost:3000/index.html"
    putStrLn "[SERVER] API endpoints:"
    putStrLn "  GET  /api/basins"
    putStrLn "  GET  /api/rainfall"
    putStrLn "  POST /api/upload-rainfall"
    putStrLn "  POST /api/calculate-risk"
    putStrLn "  GET  /api/results"
    putStrLn ""

    -- Configure server options: bind to 0.0.0.0 for Codespaces
    let warpSettings = setPort 3000 $ setHost (fromString "0.0.0.0") defaultSettings
        opts = Options 1 warpSettings True

    -- Start Scotty server with static file middleware
    scottyOpts opts $ do
        -- Serve frontend files from the 'frontend' directory
        middleware $ staticPolicy (addBase "frontend-react/dist")
        -- Mount API routes
        app conn
