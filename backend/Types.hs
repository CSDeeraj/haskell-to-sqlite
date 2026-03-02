{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}

module Types
    ( FloodRisk(..)
    , Basin(..)
    , RainfallScenario(..)
    , FloodResult(..)
    , CalculateRiskRequest(..)
    , UploadRainfallRequest(..)
    ) where

import           Data.Aeson            (FromJSON (..), ToJSON (..), object,
                                        withText, (.=))
import           Data.Text             (Text)
import           Database.SQLite.Simple (FromRow (..), ToRow (..), field)
import           GHC.Generics          (Generic)

-- ============================================================
-- Algebraic Data Type: FloodRisk
-- This is the core ADT representing flood susceptibility levels.
-- Uses sum type (four distinct constructors) for risk categories.
-- ============================================================

data FloodRisk
    = Low       -- ^ Minimal flood danger
    | Moderate  -- ^ Some flood potential, monitoring advised
    | High      -- ^ Significant flood risk, action recommended
    | Severe    -- ^ Critical flood danger, immediate action required
    deriving (Show, Eq, Ord, Generic)

-- Custom JSON instances for FloodRisk ADT
instance ToJSON FloodRisk where
    toJSON Low      = "Low"
    toJSON Moderate = "Moderate"
    toJSON High     = "High"
    toJSON Severe   = "Severe"

instance FromJSON FloodRisk where
    parseJSON = withText "FloodRisk" $ \t ->
        case t of
            "Low"      -> pure Low
            "Moderate" -> pure Moderate
            "High"     -> pure High
            "Severe"   -> pure Severe
            _          -> fail "Invalid FloodRisk value"

-- Convert FloodRisk to Text for database storage
riskToText :: FloodRisk -> Text
riskToText Low      = "Low"
riskToText Moderate = "Moderate"
riskToText High     = "High"
riskToText Severe   = "Severe"

-- Convert Text from database to FloodRisk using pattern matching
textToRisk :: Text -> FloodRisk
textToRisk "Low"      = Low
textToRisk "Moderate" = Moderate
textToRisk "High"     = High
textToRisk "Severe"   = Severe
textToRisk _          = Low  -- default fallback

-- ============================================================
-- Basin: Represents an urban sub-basin with geographic properties
-- ============================================================

data Basin = Basin
    { basinId    :: Int
    , basinName  :: Text
    , elevation  :: Double   -- ^ Meters above sea level
    , slope      :: Double   -- ^ Percentage gradient
    , area       :: Double   -- ^ Square kilometers
    } deriving (Show, Eq, Generic)

instance ToJSON Basin
instance FromJSON Basin

instance FromRow Basin where
    fromRow = Basin <$> field <*> field <*> field <*> field <*> field

instance ToRow Basin where
    toRow b = toRow (basinName b, elevation b, slope b, area b)

-- ============================================================
-- RainfallScenario: Precipitation data for a given basin
-- ============================================================

data RainfallScenario = RainfallScenario
    { scenarioId    :: Int
    , rsBasinId     :: Int
    , scenarioName  :: Text
    , intensityMm   :: Double   -- ^ Millimeters per hour
    , durationHours :: Double
    } deriving (Show, Eq, Generic)

instance ToJSON RainfallScenario
instance FromJSON RainfallScenario

instance FromRow RainfallScenario where
    fromRow = RainfallScenario <$> field <*> field <*> field <*> field <*> field

instance ToRow RainfallScenario where
    toRow r = toRow (rsBasinId r, scenarioName r, intensityMm r, durationHours r)

-- ============================================================
-- FloodResult: Computed flood risk result stored in database
-- ============================================================

data FloodResult = FloodResult
    { resultId     :: Int
    , frBasinId    :: Int
    , frRainfallId :: Int
    , riskLevel    :: Text     -- ^ Stored as text, converted to FloodRisk when needed
    , calculatedAt :: Text     -- ^ ISO 8601 timestamp
    } deriving (Show, Eq, Generic)

instance ToJSON FloodResult
instance FromJSON FloodResult

instance FromRow FloodResult where
    fromRow = FloodResult <$> field <*> field <*> field <*> field <*> field

instance ToRow FloodResult where
    toRow r = toRow (frBasinId r, frRainfallId r, riskLevel r, calculatedAt r)

-- ============================================================
-- API Request types
-- ============================================================

data CalculateRiskRequest = CalculateRiskRequest
    { crBasinId    :: Int
    , crRainfallId :: Int
    } deriving (Show, Eq, Generic)

instance FromJSON CalculateRiskRequest
instance ToJSON CalculateRiskRequest

data UploadRainfallRequest = UploadRainfallRequest
    { urBasinId       :: Int
    , urScenarioName  :: Text
    , urIntensityMm   :: Double
    , urDurationHours :: Double
    } deriving (Show, Eq, Generic)

instance FromJSON UploadRainfallRequest
instance ToJSON UploadRainfallRequest
