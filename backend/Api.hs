{-# LANGUAGE OverloadedStrings #-}

module Api (app) where

import           Web.Scotty
import           Data.Aeson              (Value, object, (.=), toJSON)
import qualified Data.Text.Lazy          as TL
import qualified Data.Text               as T
import           Database.SQLite.Simple  (Connection)
import           Data.Time.Clock         (getCurrentTime)
import           Data.Time.Format        (formatTime, defaultTimeLocale)

import           Types
import           FloodModel              (computeSI, classifyRisk,
                                          riskDescription, computeSensitivity,
                                          lookupCoord, GeoCoord(..))
import           Database

-- ============================================================
-- REST API using Scotty
--
-- Endpoints:
--   GET  /api/basins             – List all basins (full params)
--   GET  /api/scenarios          – List all precipitation scenarios
--   POST /api/classify           – Classify risk for one basin+scenario
--   POST /api/classify-all       – Classify one basin across all scenarios
--   GET  /api/results            – List all calculated results
--   GET  /api/basin-coordinates  – Basins with lat/lon + latest risk
--   GET  /api/scenario-matrix    – Full NxM matrix: all basins × all scenarios
-- ============================================================

app :: Connection -> ScottyM ()
app conn = do

    -- GET /api/basins
    get "/api/basins" $ do
        basins <- liftIO $ getAllBasins conn
        json basins

    -- GET /api/scenarios
    get "/api/scenarios" $ do
        scenarios <- liftIO $ getAllScenarios conn
        json scenarios

    -- POST /api/classify
    post "/api/classify" $ do
        req <- jsonData :: ActionM ClassifyRequest
        let bid = crBasinId req
            sid = crScenarioId req

        basins    <- liftIO $ getBasinById conn bid
        scenarios <- liftIO $ getScenarioById conn sid

        case (basins, scenarios) of
            (b:_, s:_) -> do
                let si   = computeSI b s
                    risk = classifyRisk b s
                    rText = riskToText risk
                    desc  = riskDescription risk
                    sens  = computeSensitivity b s

                now <- liftIO getCurrentTime
                let timestamp = TL.pack $ formatTime defaultTimeLocale "%Y-%m-%dT%H:%M:%S" now

                liftIO $ insertRiskResult conn bid sid si rText sens (TL.toStrict timestamp)

                json $ object
                    [ "status"      .= ("success" :: TL.Text)
                    , "basinName"   .= basinName b
                    , "city"        .= city b
                    , "scenario"    .= scenarioName s
                    , "rainfall_mm" .= intensityMm s
                    , "elevation_m" .= elevation b
                    , "slope_pct"   .= slope b
                    , "isr"         .= imperviousRatio b
                    , "drainage_density" .= drainageDensity b
                    , "siScore"     .= si
                    , "riskLevel"   .= rText
                    , "description" .= desc
                    , "sensitivity" .= sens
                    , "calculatedAt".= timestamp
                    ]

            _ -> do
                status $ toEnum 404
                json $ object
                    [ "status"  .= ("error" :: TL.Text)
                    , "message" .= ("Basin or scenario not found" :: TL.Text)
                    ]

    -- POST /api/classify-all
    post "/api/classify-all" $ do
        req <- jsonData :: ActionM ClassifyAllRequest
        let bid = carBasinId req

        basins    <- liftIO $ getBasinById conn bid
        scenarios <- liftIO $ getAllScenarios conn

        case basins of
            (b:_) -> do
                now <- liftIO getCurrentTime
                let timestamp = TL.pack $ formatTime defaultTimeLocale "%Y-%m-%dT%H:%M:%S" now

                let results = map (\s ->
                        let si   = computeSI b s
                            risk = classifyRisk b s
                            rText = riskToText risk
                            sens  = computeSensitivity b s
                        in object
                            [ "scenarioId"   .= scenarioId s
                            , "scenarioName" .= scenarioName s
                            , "scenarioType" .= scenarioType s
                            , "intensity_mm" .= intensityMm s
                            , "siScore"      .= si
                            , "riskLevel"    .= rText
                            , "sensitivity"  .= sens
                            ]
                        ) scenarios

                json $ object
                    [ "status"    .= ("success" :: TL.Text)
                    , "basinName" .= basinName b
                    , "city"      .= city b
                    , "results"   .= results
                    ]

            _ -> do
                status $ toEnum 404
                json $ object
                    [ "status"  .= ("error" :: TL.Text)
                    , "message" .= ("Basin not found" :: TL.Text)
                    ]

    -- GET /api/results
    get "/api/results" $ do
        results <- liftIO $ getAllResults conn
        json results

    -- GET /api/basin-coordinates
    get "/api/basin-coordinates" $ do
        basins  <- liftIO $ getAllBasins conn
        results <- liftIO $ getAllResults conn
        let coordList = map (enrichBasin results) basins
        json coordList

    -- GET /api/scenario-matrix
    get "/api/scenario-matrix" $ do
        basins    <- liftIO $ getAllBasins conn
        scenarios <- liftIO $ getAllScenarios conn
        let matrix = map (\b ->
                let scenarioResults = map (\s ->
                        let si   = computeSI b s
                            risk = classifyRisk b s
                            rText = riskToText risk
                            sens  = computeSensitivity b s
                        in object
                            [ "scenarioId"   .= scenarioId s
                            , "scenarioType" .= scenarioType s
                            , "scenarioName" .= scenarioName s
                            , "siScore"      .= si
                            , "riskLevel"    .= rText
                            , "sensitivity"  .= sens
                            ]
                        ) scenarios
                    coord = lookupCoord (basinName b)
                in object
                    [ "basinId"    .= basinId b
                    , "basinName"  .= basinName b
                    , "city"       .= city b
                    , "country"    .= country b
                    , "elevation"  .= elevation b
                    , "slope"      .= slope b
                    , "area"       .= area b
                    , "isr"        .= imperviousRatio b
                    , "drainageDensity" .= drainageDensity b
                    , "runoffCoeff"     .= runoffCoeff b
                    , "latitude"   .= fmap latitude coord
                    , "longitude"  .= fmap longitude coord
                    , "scenarios"  .= scenarioResults
                    ]
                ) basins
        json matrix

  where
    enrichBasin :: [RiskResult] -> SubBasin -> Value
    enrichBasin results b =
        let name = basinName b
            coord = lookupCoord name
            basinResults = filter (\r -> rrBasinId r == basinId b) results
            latestRisk = case basinResults of
                []    -> "Unknown" :: T.Text
                _     -> riskLevel (last basinResults)
            latestSI = case basinResults of
                []    -> 0.0 :: Double
                _     -> siScore (last basinResults)
        in object
            [ "basinId"    .= basinId b
            , "basinName"  .= name
            , "city"       .= city b
            , "country"    .= country b
            , "elevation"  .= elevation b
            , "slope"      .= slope b
            , "area"       .= area b
            , "isr"        .= imperviousRatio b
            , "drainageDensity" .= drainageDensity b
            , "latitude"   .= fmap latitude coord
            , "longitude"  .= fmap longitude coord
            , "riskLevel"  .= latestRisk
            , "siScore"    .= latestSI
            ]
