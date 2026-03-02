{-# LANGUAGE OverloadedStrings #-}

module Api (app) where

import           Web.Scotty
import           Data.Aeson              (object, (.=))
import qualified Data.Text.Lazy          as TL
import           Database.SQLite.Simple  (Connection)
import           Data.Time.Clock         (getCurrentTime)
import           Data.Time.Format        (formatTime, defaultTimeLocale)

import           Types
import           FloodModel              (classifyFloodRisk, riskToText, riskDescription)
import           Database

-- ============================================================
-- REST API using Scotty
--
-- Endpoints:
--   GET  /api/basins           - List all basins
--   GET  /api/rainfall         - List all rainfall scenarios
--   POST /api/upload-rainfall  - Upload new rainfall scenario
--   POST /api/calculate-risk   - Calculate flood risk for basin+rainfall
--   GET  /api/results          - List all calculated results
-- ============================================================

app :: Connection -> ScottyM ()
app conn = do

    -- --------------------------------------------------------
    -- GET /api/basins
    -- Returns all urban sub-basins as JSON array
    -- --------------------------------------------------------
    get "/api/basins" $ do
        basins <- liftIO $ getAllBasins conn
        json basins

    -- --------------------------------------------------------
    -- GET /api/rainfall
    -- Returns all rainfall scenarios as JSON array
    -- --------------------------------------------------------
    get "/api/rainfall" $ do
        rainfall <- liftIO $ getAllRainfall conn
        json rainfall

    -- --------------------------------------------------------
    -- POST /api/upload-rainfall
    -- Accepts JSON body with rainfall scenario data
    -- Inserts into database and returns success response
    -- --------------------------------------------------------
    post "/api/upload-rainfall" $ do
        req <- jsonData :: ActionM UploadRainfallRequest
        liftIO $ insertRainfall conn
            (urBasinId req)
            (urScenarioName req)
            (urIntensityMm req)
            (urDurationHours req)
        -- Fetch updated rainfall list
        rainfall <- liftIO $ getAllRainfall conn
        json $ object
            [ "status"  .= ("success" :: TL.Text)
            , "message" .= ("Rainfall scenario uploaded successfully" :: TL.Text)
            , "data"    .= rainfall
            ]

    -- --------------------------------------------------------
    -- POST /api/calculate-risk
    -- Accepts JSON body with basinId and rainfallId
    -- Uses the FloodModel (ADT + pattern matching) to classify risk
    -- Stores result in database and returns it
    -- --------------------------------------------------------
    post "/api/calculate-risk" $ do
        req <- jsonData :: ActionM CalculateRiskRequest
        let bid = crBasinId req
            rid = crRainfallId req

        -- Fetch basin and rainfall data
        basins   <- liftIO $ getBasinById conn bid
        rainfall <- liftIO $ getRainfallById conn rid

        case (basins, rainfall) of
            (b:_, r:_) -> do
                -- Apply the deterministic flood model
                -- Uses pattern matching via classifyFloodRisk
                let risk = classifyFloodRisk
                        (intensityMm r)
                        (elevation b)
                        (slope b)
                    riskText = riskToText risk
                    desc     = riskDescription risk

                -- Get current timestamp
                now <- liftIO getCurrentTime
                let timestamp = TL.pack $ formatTime defaultTimeLocale "%Y-%m-%dT%H:%M:%S" now

                -- Store result in database
                liftIO $ insertFloodResult conn bid rid riskText (TL.toStrict timestamp)

                json $ object
                    [ "status"      .= ("success" :: TL.Text)
                    , "basinName"   .= basinName b
                    , "scenario"    .= scenarioName r
                    , "rainfall_mm" .= intensityMm r
                    , "elevation_m" .= elevation b
                    , "slope_pct"   .= slope b
                    , "riskLevel"   .= riskText
                    , "description" .= desc
                    , "calculatedAt".= timestamp
                    ]

            _ -> do
                status $ toEnum 404
                json $ object
                    [ "status"  .= ("error" :: TL.Text)
                    , "message" .= ("Basin or rainfall scenario not found" :: TL.Text)
                    ]

    -- --------------------------------------------------------
    -- GET /api/results
    -- Returns all previously calculated flood risk results
    -- --------------------------------------------------------
    get "/api/results" $ do
        results <- liftIO $ getAllResults conn
        json results
