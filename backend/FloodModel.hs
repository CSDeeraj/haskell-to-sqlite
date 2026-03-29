{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric     #-}

module FloodModel
    ( classifyRisk
    , computeSI
    , computeSensitivity
    , riskFromSI
    , riskDescription
    , riskToText
    , textToRisk
    , GeoCoord(..)
    , basinCoordinates
    , lookupCoord
    ) where

import           Data.Text       (Text)
import qualified Data.Text       as T
import qualified Data.Map.Strict as Map
import           Data.Map.Strict (Map)
import           Data.Aeson      (ToJSON)
import           GHC.Generics    (Generic)
import           Types           (RiskLevel(..), SubBasin(..), PrecipScenarioData(..))

-- ============================================================
-- Geographic Coordinate Type (Product ADT)
-- ============================================================

data GeoCoord = GeoCoord
    { latitude  :: Double
    , longitude :: Double
    } deriving (Show, Eq, Generic)

instance ToJSON GeoCoord

-- | Immutable coordinate lookup table for 7 international basins.
basinCoordinates :: Map Text GeoCoord
basinCoordinates = Map.fromList
    [ ("Adyar Basin",           GeoCoord 13.0067  80.2573)
    , ("Cooum Basin",           GeoCoord 13.0827  80.2707)
    , ("Mithi River Basin",     GeoCoord 19.1075  72.8877)
    , ("Musi River Basin",      GeoCoord 17.3850  78.4867)
    , ("Yamuna Floodplain",     GeoCoord 28.6139  77.2090)
    , ("Vrishabhavathi Basin",  GeoCoord 12.9716  77.5946)
    , ("Bisalpur Canal Basin",  GeoCoord 26.9124  75.7873)
    , ("Gomti Basin",           GeoCoord 26.8467  80.9462)
    , ("Ciliwung Basin",        GeoCoord (-6.1751) 106.8272)
    , ("Pasig River Basin",     GeoCoord 14.5995  120.9842)
    , ("Chao Phraya Delta",     GeoCoord 13.7563  100.5018)
    , ("Klang River Basin",     GeoCoord 3.1390   101.6869)
    , ("To Lich River Basin",   GeoCoord 21.0285  105.8542)
    , ("Saigon River Basin",    GeoCoord 10.8231  106.6297)
    , ("Ayeyarwady Delta",      GeoCoord 16.8409  96.1495)
    , ("Shenzhen River Basin",  GeoCoord 22.5431  114.0579)
    , ("Suzhou Creek Basin",    GeoCoord 31.2304  121.4737)
    , ("Pearl River Delta",     GeoCoord 23.1291  113.2644)
    , ("Yangtze Floodplain",    GeoCoord 30.5928  114.3055)
    , ("Kanda River Basin",     GeoCoord 35.6895  139.6917)
    , ("Tsurumi River Basin",   GeoCoord 35.4437  139.6380)
    , ("Buriganga Basin",       GeoCoord 23.8103  90.4125)
    , ("Lai Nullah Basin",      GeoCoord 33.6844  73.0479)
    , ("Kandy Lake Basin",      GeoCoord 7.2906   80.6337)
    , ("Bishnumati Basin",      GeoCoord 27.7172  85.3240)
    , ("Kabul River Basin",     GeoCoord 34.5553  69.2075)
    , ("Jukskei River Basin",   GeoCoord (-26.2041) 28.0473)
    , ("Nairobi River Basin",   GeoCoord (-1.2921)  36.8219)
    , ("Oshiwara River Basin",  GeoCoord 6.5244   3.3792)
    , ("Oued El Harrach",       GeoCoord 36.7538  3.0588)
    , ("Nile Delta Basin",      GeoCoord 30.0444  31.2357)
    , ("Msimbazi Basin",        GeoCoord (-6.7924)  39.2083)
    , ("Seine Floodplain",      GeoCoord 48.8566  2.3522)
    , ("Thames Tideway",        GeoCoord 51.5074  (-0.1278))
    , ("Tiber Floodplain",      GeoCoord 41.9028  12.4964)
    , ("Isar River Basin",      GeoCoord 48.1351  11.5820)
    , ("Danube Floodplain",     GeoCoord 47.4979  19.0402)
    , ("Spree River Basin",     GeoCoord 52.5200  13.4050)
    , ("Brays Bayou",           GeoCoord 29.6911  (-95.4091))
    , ("Anacostia Basin",       GeoCoord 38.8700  (-76.9800))
    , ("Gowanus Canal Basin",   GeoCoord 40.7128  (-74.0060))
    , ("Don River Basin",       GeoCoord 43.6510  (-79.3470))
    , ("Los Angeles River Basin",GeoCoord 34.0522 (-118.2437))
    , ("Chicagoland Basin",     GeoCoord 41.8781  (-87.6298))
    , ("Tiete River Basin",     GeoCoord (-23.5505) (-46.6333))
    , ("Rimac River Basin",     GeoCoord (-12.0464) (-77.0428))
    , ("Bogota River Basin",    GeoCoord 4.7110   (-74.0721))
    , ("Reconquista Basin",     GeoCoord (-34.6037) (-58.3816))
    , ("Wadi Hanifah Basin",    GeoCoord 24.7136  46.6753)
    , ("Jeddah Wadi Basin",     GeoCoord 21.4858  39.1925)
    ]

lookupCoord :: Text -> Maybe GeoCoord
lookupCoord name = Map.lookup name basinCoordinates

-- ============================================================
-- Susceptibility Index (SI) Formula
--
-- SI = w1×R_norm + w2×(1/S)_norm + w3×(1/E)_norm
--    + w4×ISR_norm + w5×(1/Dd)_norm
--
-- Weights derived from AHP (Analytic Hierarchy Process)
-- based on flood susceptibility literature:
--   - Rainfall intensity is the strongest driver (0.35)
--   - Impervious surface ratio strongly affects runoff (0.20)
--   - Slope, elevation, drainage density each 0.15
--
-- Normalization: min-max scaling to [0,1]
--   Rainfall:  0–300 mm/hr
--   Slope:     0.1–15%  (inverted: flat = higher risk)
--   Elevation: 1–900 m  (inverted: low = higher risk)
--   ISR:       0–1.0    (direct: higher = more risk)
--   Dd:        0.5–5.0  (inverted: low = higher risk)
--
-- Classification thresholds:
--   SI < 0.25  → Low
--   SI < 0.50  → Moderate
--   SI < 0.75  → High
--   SI ≥ 0.75  → Severe
-- ============================================================

-- Weights (sum = 1.0)
w1, w2, w3, w4, w5 :: Double
w1 = 0.35  -- Rainfall
w2 = 0.15  -- Inverse Slope
w3 = 0.15  -- Inverse Elevation
w4 = 0.20  -- ISR
w5 = 0.15  -- Inverse Drainage Density

-- | Clamp a value to [0, 1].
clamp01 :: Double -> Double
clamp01 x = max 0.0 (min 1.0 x)

-- | Min-max normalize a value given a range.
normalize :: Double -> Double -> Double -> Double
normalize minV maxV val = clamp01 ((val - minV) / (maxV - minV))

-- | Normalize with inversion (higher input → lower normalized value).
normalizeInv :: Double -> Double -> Double -> Double
normalizeInv minV maxV val = clamp01 (1.0 - normalize minV maxV val)

-- | Compute the Susceptibility Index (SI) for a basin under a scenario.
--
-- This is a pure function using the weighted multi-criteria formula.
-- All inputs are normalized to [0,1] then combined with AHP weights.
computeSI :: SubBasin -> PrecipScenarioData -> Double
computeSI basin scenario =
    let rainfall = intensityMm scenario
        slopeV   = slope basin
        elevV    = elevation basin
        isrV     = imperviousRatio basin
        ddV      = drainageDensity basin

        -- Normalize each factor
        rNorm  = normalize    0.0 300.0 rainfall   -- More rain → higher
        sNorm  = normalizeInv 0.1  15.0 slopeV     -- Flatter → higher
        eNorm  = normalizeInv 1.0 900.0 elevV      -- Lower → higher
        iNorm  = normalize    0.0   1.0 isrV       -- More impervious → higher
        dNorm  = normalizeInv 0.5   5.0 ddV        -- Less drainage → higher

        -- Weighted sum
        si = w1 * rNorm + w2 * sNorm + w3 * eNorm + w4 * iNorm + w5 * dNorm
    in  clamp01 si

-- | Classify risk from SI score using pattern matching with guards.
riskFromSI :: Double -> RiskLevel
riskFromSI si
    | si >= 0.75 = Severe
    | si >= 0.50 = High
    | si >= 0.25 = Moderate
    | otherwise  = Low

-- | Pure function: classify flood risk for a basin under a scenario.
-- Uses exhaustive ADT pattern matching via riskFromSI.
classifyRisk :: SubBasin -> PrecipScenarioData -> RiskLevel
classifyRisk basin scenario = riskFromSI (computeSI basin scenario)

-- | Compute sensitivity: contribution of each parameter to SI.
-- Returns a JSON-encodable string with parameter contributions.
computeSensitivity :: SubBasin -> PrecipScenarioData -> Text
computeSensitivity basin scenario =
    let rainfall = intensityMm scenario
        slopeV   = slope basin
        elevV    = elevation basin
        isrV     = imperviousRatio basin
        ddV      = drainageDensity basin

        rNorm = normalize    0.0 300.0 rainfall
        sNorm = normalizeInv 0.1  15.0 slopeV
        eNorm = normalizeInv 1.0 900.0 elevV
        iNorm = normalize    0.0   1.0 isrV
        dNorm = normalizeInv 0.5   5.0 ddV

        rContrib = w1 * rNorm
        sContrib = w2 * sNorm
        eContrib = w3 * eNorm
        iContrib = w4 * iNorm
        dContrib = w5 * dNorm

        fmt k v = "\"" <> k <> "\":" <> T.pack (show (roundTo3 v))
        roundTo3 x = fromIntegral (round (x * 1000) :: Int) / 1000.0 :: Double
    in  "{" <> T.intercalate ","
            [ fmt "rainfall"  rContrib
            , fmt "slope"     sContrib
            , fmt "elevation" eContrib
            , fmt "isr"       iContrib
            , fmt "drainage"  dContrib
            ] <> "}"


-- | Human-readable risk descriptions via pattern matching.
riskDescription :: RiskLevel -> Text
riskDescription Low      = "Minimal flood risk. Normal conditions expected."
riskDescription Moderate = "Moderate flood potential. Monitor water levels and drainage."
riskDescription High     = "High flood risk. Prepare flood defenses and evacuation routes."
riskDescription Severe   = "Severe flood danger! Immediate protective action required."

-- Re-exports from Types (for backward compat with Api.hs)
riskToText :: RiskLevel -> Text
riskToText Low      = "Low"
riskToText Moderate = "Moderate"
riskToText High     = "High"
riskToText Severe   = "Severe"

textToRisk :: Text -> RiskLevel
textToRisk "Low"      = Low
textToRisk "Moderate" = Moderate
textToRisk "High"     = High
textToRisk "Severe"   = Severe
textToRisk _          = Low
