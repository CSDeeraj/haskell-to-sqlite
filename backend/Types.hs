{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}

module Types
    ( RiskLevel(..)
    , PrecipScenario(..)
    , SubBasin(..)
    , PrecipScenarioData(..)
    , RiskResult(..)
    , ClassifyRequest(..)
    , ClassifyAllRequest(..)
    , riskToText
    , textToRisk
    , precipToText
    , textToPrecip
    ) where

import           Data.Aeson            (FromJSON (..), ToJSON (..), object,
                                        withText, (.=))
import           Data.Text             (Text)
import           Database.SQLite.Simple (FromRow (..), ToRow (..), field, SQLData)
import           Database.SQLite.Simple.ToField (toField)
import           GHC.Generics          (Generic)

-- ============================================================
-- Algebraic Data Type: RiskLevel (Sum Type)
--
-- Four exhaustive constructors for flood susceptibility.
-- Compiler enforces total pattern matching.
-- ============================================================

data RiskLevel
    = Low       -- ^ SI < 0.25: Minimal flood danger
    | Moderate  -- ^ 0.25 ≤ SI < 0.50: Monitor water levels
    | High      -- ^ 0.50 ≤ SI < 0.75: Prepare flood defenses
    | Severe    -- ^ SI ≥ 0.75: Immediate action required
    deriving (Show, Eq, Ord, Generic)

instance ToJSON RiskLevel where
    toJSON Low      = "Low"
    toJSON Moderate = "Moderate"
    toJSON High     = "High"
    toJSON Severe   = "Severe"

instance FromJSON RiskLevel where
    parseJSON = withText "RiskLevel" $ \t ->
        case t of
            "Low"      -> pure Low
            "Moderate" -> pure Moderate
            "High"     -> pure High
            "Severe"   -> pure Severe
            _          -> fail "Invalid RiskLevel value"

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

-- ============================================================
-- Algebraic Data Type: PrecipScenario (Sum Type)
--
-- Five exhaustive precipitation scenario levels based on
-- IMD categories and return period analysis.
-- ============================================================

data PrecipScenario
    = Normal          -- ^ 10–20 mm/hr, 1-year return period
    | ModerateStorm   -- ^ 30–50 mm/hr, 2-year return period
    | HeavyStorm      -- ^ 60–90 mm/hr, 10-year return period
    | ExtremeEvent    -- ^ 100–150 mm/hr, 50-year (Chennai 2015 / Mumbai 2005)
    | Catastrophic    -- ^ 150+ mm/hr, 100-year climate change scenario
    deriving (Show, Eq, Ord, Generic)

instance ToJSON PrecipScenario
instance FromJSON PrecipScenario

precipToText :: PrecipScenario -> Text
precipToText Normal        = "Normal"
precipToText ModerateStorm = "ModerateStorm"
precipToText HeavyStorm    = "HeavyStorm"
precipToText ExtremeEvent  = "ExtremeEvent"
precipToText Catastrophic  = "Catastrophic"

textToPrecip :: Text -> PrecipScenario
textToPrecip "Normal"        = Normal
textToPrecip "ModerateStorm" = ModerateStorm
textToPrecip "HeavyStorm"    = HeavyStorm
textToPrecip "ExtremeEvent"  = ExtremeEvent
textToPrecip "Catastrophic"  = Catastrophic
textToPrecip _               = Normal

-- ============================================================
-- SubBasin: Urban sub-basin with full hydrology parameters
-- ============================================================

data SubBasin = SubBasin
    { basinId         :: Int
    , basinName       :: Text
    , city            :: Text
    , country         :: Text
    , elevation       :: Double   -- ^ Meters above sea level (mean)
    , slope           :: Double   -- ^ Percentage gradient
    , area            :: Double   -- ^ Square kilometers
    , drainageDensity :: Double   -- ^ km/km² (stream length per unit area)
    , imperviousRatio :: Double   -- ^ 0.0–1.0 (impervious surface ratio)
    , runoffCoeff     :: Double   -- ^ 0.0–1.0 (Rational Method C)
    , manningsN       :: Double   -- ^ Manning's roughness coefficient
    , timeOfConc      :: Double   -- ^ Time of concentration (minutes)
    } deriving (Show, Eq, Generic)

instance ToJSON SubBasin
instance FromJSON SubBasin

instance FromRow SubBasin where
    fromRow = SubBasin <$> field <*> field <*> field <*> field
                       <*> field <*> field <*> field <*> field
                       <*> field <*> field <*> field <*> field

instance ToRow SubBasin where
    toRow b = [ toField (basinName b), toField (city b), toField (country b)
              , toField (elevation b), toField (slope b), toField (area b)
              , toField (drainageDensity b), toField (imperviousRatio b)
              , toField (runoffCoeff b), toField (manningsN b), toField (timeOfConc b) ]

-- ============================================================
-- PrecipScenarioData: Named precipitation scenario record
-- ============================================================

data PrecipScenarioData = PrecipScenarioData
    { scenarioId     :: Int
    , scenarioType   :: Text      -- ^ "Normal", "ModerateStorm", etc.
    , scenarioName   :: Text      -- ^ Human-readable name
    , intensityMm    :: Double    -- ^ mm/hr
    , returnPeriod   :: Int       -- ^ Return period in years
    , durationHours  :: Double    -- ^ Duration in hours
    , reference      :: Text      -- ^ Academic reference
    } deriving (Show, Eq, Generic)

instance ToJSON PrecipScenarioData
instance FromJSON PrecipScenarioData

instance FromRow PrecipScenarioData where
    fromRow = PrecipScenarioData <$> field <*> field <*> field
                                 <*> field <*> field <*> field <*> field

instance ToRow PrecipScenarioData where
    toRow s = toRow ( scenarioType s, scenarioName s, intensityMm s
                    , returnPeriod s, durationHours s, reference s )

-- ============================================================
-- RiskResult: Computed flood risk with SI score
-- ============================================================

data RiskResult = RiskResult
    { resultId       :: Int
    , rrBasinId      :: Int
    , rrScenarioId   :: Int
    , siScore        :: Double    -- ^ Susceptibility Index 0.0–1.0
    , riskLevel      :: Text     -- ^ "Low", "Moderate", "High", "Severe"
    , sensitivity    :: Text     -- ^ JSON: parameter sensitivities
    , calculatedAt   :: Text     -- ^ ISO 8601 timestamp
    } deriving (Show, Eq, Generic)

instance ToJSON RiskResult
instance FromJSON RiskResult

instance FromRow RiskResult where
    fromRow = RiskResult <$> field <*> field <*> field
                         <*> field <*> field <*> field <*> field

instance ToRow RiskResult where
    toRow r = toRow ( rrBasinId r, rrScenarioId r, siScore r
                    , riskLevel r, sensitivity r, calculatedAt r )

-- ============================================================
-- API Request types
-- ============================================================

data ClassifyRequest = ClassifyRequest
    { crBasinId    :: Int
    , crScenarioId :: Int
    } deriving (Show, Eq, Generic)

instance FromJSON ClassifyRequest
instance ToJSON ClassifyRequest

data ClassifyAllRequest = ClassifyAllRequest
    { carBasinId :: Int
    } deriving (Show, Eq, Generic)

instance FromJSON ClassifyAllRequest
instance ToJSON ClassifyAllRequest
