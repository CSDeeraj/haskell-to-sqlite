{-# LANGUAGE OverloadedStrings #-}

module FloodModel
    ( classifyFloodRisk
    , riskDescription
    , riskToText
    , textToRisk
    ) where

import           Data.Text (Text)
import           Types     (FloodRisk (..))

-- ============================================================
-- Deterministic Flood Susceptibility Classification
--
-- This module implements the core flood risk model using
-- Haskell's pattern matching and algebraic data types.
--
-- The model considers three inputs:
--   1. Rainfall intensity (mm/hr)
--   2. Elevation (meters above sea level)
--   3. Slope (percentage gradient)
--
-- Risk classification uses guard-based pattern matching
-- to deterministically categorize flood susceptibility.
-- ============================================================

-- | Classify flood risk based on rainfall, elevation, and slope.
--
-- The classification uses a deterministic scoring approach:
--   - High rainfall intensity increases risk
--   - Low elevation increases risk (water accumulates in low areas)
--   - Low slope increases risk (poor drainage)
--
-- Pattern matching with guards determines the final risk level.
classifyFloodRisk :: Double    -- ^ Rainfall intensity in mm/hr
                  -> Double    -- ^ Elevation in meters
                  -> Double    -- ^ Slope in percentage
                  -> FloodRisk
classifyFloodRisk rainfall elev slopeVal
    -- Severe: Very heavy rain in low-lying flat areas
    | rainfall >= 100 && elev < 50  && slopeVal < 5   = Severe
    | rainfall >= 150 && elev < 100                    = Severe
    | rainfall >= 200                                  = Severe

    -- High: Heavy rain or unfavorable terrain combination
    | rainfall >= 80  && elev < 100 && slopeVal < 10   = High
    | rainfall >= 100 && elev < 150                    = High
    | rainfall >= 60  && elev < 30  && slopeVal < 3    = High

    -- Moderate: Medium rain with mixed terrain
    | rainfall >= 40  && elev < 200 && slopeVal < 15   = Moderate
    | rainfall >= 60  && elev < 300                    = Moderate
    | rainfall >= 30  && elev < 50                     = Moderate

    -- Low: Light rain or high elevation with good drainage
    | otherwise                                        = Low


-- | Provide a human-readable description for each risk level.
--
-- Uses direct pattern matching on the FloodRisk ADT constructors.
riskDescription :: FloodRisk -> Text
riskDescription Low      = "Minimal flood risk. Normal conditions expected."
riskDescription Moderate = "Moderate flood potential. Monitor water levels and drainage systems."
riskDescription High     = "High flood risk. Prepare flood defenses and consider evacuation routes."
riskDescription Severe   = "Severe flood danger! Immediate protective action required."


-- | Convert FloodRisk ADT to database-storable Text.
--
-- Pattern matching ensures exhaustive coverage of all constructors.
riskToText :: FloodRisk -> Text
riskToText Low      = "Low"
riskToText Moderate = "Moderate"
riskToText High     = "High"
riskToText Severe   = "Severe"


-- | Convert Text back to FloodRisk ADT.
--
-- Pattern matching with a default fallback for unknown values.
textToRisk :: Text -> FloodRisk
textToRisk "Low"      = Low
textToRisk "Moderate" = Moderate
textToRisk "High"     = High
textToRisk "Severe"   = Severe
textToRisk _          = Low  -- safe default for unknown values
