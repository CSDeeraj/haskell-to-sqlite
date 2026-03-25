# Deterministic Modeling of Flood Susceptibility in Urban Sub-Basins

> Under Varying Precipitation Scenarios

A full-stack application built with **Haskell**, **SQLite**, and **React.js** that deterministically models flood susceptibility in urban sub-basins using **Algebraic Data Types (ADTs)**, **pattern matching**, and a weighted **Susceptibility Index (SI)** formula. Zero probabilistic or ML components.

---

## 🌊 Project Goal

This project models flood susceptibility across **7 international urban sub-basins** under **5 academically meaningful precipitation scenarios** (Normal to Catastrophic). It uses Haskell's type system to enforce exhaustive, deterministic classification of flood risk into four levels: **Low**, **Moderate**, **High**, and **Severe**.

## 📂 Project Structure

```
haskell-to-sqlite/
├── backend/
│   ├── Main.hs           # Server entry point (Scotty, port 3000)
│   ├── Types.hs          # ADTs: RiskLevel, PrecipScenario, SubBasin
│   ├── FloodModel.hs     # SI formula, classifyRisk, sensitivity analysis
│   ├── Database.hs       # SQLite schema, 7-basin + 5-scenario seed data
│   └── Api.hs            # REST API (7 endpoints)
├── frontend-react/
│   ├── src/
│   │   ├── App.jsx        # Main app with 7-tab navigation
│   │   ├── index.css      # Flood-themed dark UI (navy/cyan/teal)
│   │   ├── api.js         # API client
│   │   └── components/
│   │       ├── Dashboard.jsx        # Overview, charts, methodology
│   │       ├── FloodMap.jsx         # Interactive Leaflet world map
│   │       ├── ScenarioSelector.jsx # Live risk reclassification
│   │       ├── BasinComparison.jsx  # Side-by-side basin comparison
│   │       ├── SensitivityPanel.jsx # Parameter contribution analysis
│   │       ├── ScenarioMatrix.jsx   # 7×5 risk matrix table
│   │       └── ResultsPanel.jsx     # Stored risk results
│   ├── vite.config.js
│   └── package.json
├── database/
│   └── schema.sql
├── haskell-to-sqlite.cabal
└── README.md
```

---

## 🧮 Methodology

### Susceptibility Index (SI) Formula

The model computes a weighted **Susceptibility Index** for each basin–scenario combination:

```
SI = w₁×R_norm + w₂×(1/S)_norm + w₃×(1/E)_norm + w₄×ISR_norm + w₅×(1/Dd)_norm
```

Where:
- **R** = Rainfall intensity (mm/hr) — higher → more risk
- **S** = Slope (%) — flatter → more risk (poor drainage)
- **E** = Elevation (m) — lower → more risk (water accumulates)
- **ISR** = Impervious Surface Ratio — higher → more runoff
- **Dd** = Drainage Density (km/km²) — lower → less efficient drainage

### AHP-Derived Weights

| Parameter | Weight | Justification |
|-----------|--------|---------------|
| Rainfall | 0.35 | Strongest driver of flood events |
| Inverse Slope | 0.15 | Flat terrain retains water |
| Inverse Elevation | 0.15 | Low areas accumulate water |
| ISR | 0.20 | Impervious surfaces increase runoff |
| Inverse Drainage Density | 0.15 | Poor drainage increases flood risk |

Weights sum to 1.0 and are derived from AHP (Analytic Hierarchy Process) methodology.

### Normalization

All inputs are min-max normalized to [0, 1]:
- Rainfall: 0–300 mm/hr
- Slope: 0.1–15%
- Elevation: 1–900 m
- ISR: 0–1.0
- Dd: 0.5–5.0 km/km²

### Risk Classification

| SI Range | Risk Level | Description |
|----------|------------|-------------|
| SI < 0.25 | 🟢 Low | Minimal flood danger |
| 0.25 ≤ SI < 0.50 | 🟡 Moderate | Monitor water levels |
| 0.50 ≤ SI < 0.75 | 🟠 High | Prepare flood defenses |
| SI ≥ 0.75 | 🔴 Severe | Immediate action required |

### Theoretical Foundations

- **Rational Method (Q = CiA)**: Peak discharge estimation where C = runoff coefficient, i = rainfall intensity, A = basin area. Used as foundation for understanding runoff response.
- **SCS-CN Method**: Curve Number method for relating land cover and soil type to runoff potential. ISR and drainage parameters relate to CN values.
- **AHP (Analytic Hierarchy Process)**: Multi-criteria decision analysis framework used to derive parameter weights from pairwise comparison of flood drivers.

---

## 🧬 ADTs and Pattern Matching

### Algebraic Data Types

```haskell
-- Sum type: exactly four flood risk levels
data RiskLevel = Low | Moderate | High | Severe
    deriving (Show, Eq, Ord, Generic)

-- Sum type: five precipitation scenarios
data PrecipScenario = Normal | ModerateStorm | HeavyStorm
    | ExtremeEvent | Catastrophic
    deriving (Show, Eq, Ord, Generic)

-- Product type: urban sub-basin with full parameters
data SubBasin = SubBasin
    { basinId :: Int, basinName :: Text, city :: Text, country :: Text
    , elevation :: Double, slope :: Double, area :: Double
    , drainageDensity :: Double, imperviousRatio :: Double
    , runoffCoeff :: Double, manningsN :: Double, timeOfConc :: Double
    }
```

### Pure Classification Function

```haskell
-- Total, pure function using guard-based pattern matching
classifyRisk :: SubBasin -> PrecipScenarioData -> RiskLevel
classifyRisk basin scenario = riskFromSI (computeSI basin scenario)

riskFromSI :: Double -> RiskLevel
riskFromSI si
    | si >= 0.75 = Severe
    | si >= 0.50 = High
    | si >= 0.25 = Moderate
    | otherwise  = Low
```

Pattern matching on ADT constructors is used throughout for:
- JSON serialization/deserialization
- Database text conversions
- Human-readable descriptions
- API response generation

---

## 📊 Data Sources

### Urban Sub-Basins

| Basin | City, Country | Elev (m) | Slope (%) | Area (km²) | Dd (km/km²) | ISR | C | Source |
|-------|--------------|----------|-----------|------------|-------------|-----|---|--------|
| Adyar Basin | Chennai, India | 6.0 | 1.5 | 45.0 | 3.1 | 0.65 | 0.72 | SRTM DEM, JETIR morphometric analysis |
| Cooum Basin | Chennai, India | 4.0 | 1.0 | 38.0 | 2.8 | 0.70 | 0.78 | Wikipedia, iamwarm.gov.in |
| Mithi River Basin | Mumbai, India | 10.0 | 1.5 | 73.0 | 2.5 | 0.75 | 0.85 | MCGM report, Texas A&M study |
| Musi River Basin | Hyderabad, India | 505.0 | 3.5 | 62.0 | 2.2 | 0.55 | 0.60 | IJERT, ijhssi.org elevation study |
| Ciliwung Basin | Jakarta, Indonesia | 5.0 | 2.0 | 387.0 | 1.8 | 0.68 | 0.75 | Copernicus/NHESS, UNESA Indonesia |
| Brays Bayou | Houston, USA | 12.0 | 0.5 | 330.0 | 0.96 | 0.55 | 0.65 | Houston Public Works, HCFCD |
| Anacostia Basin | Washington DC, USA | 30.0 | 3.0 | 460.0 | 2.0 | 0.23 | 0.45 | Maryland.gov, UDC watershed studies |

### Precipitation Scenarios

| Scenario | Intensity (mm/hr) | Return Period | Reference |
|----------|--------------------|---------------|-----------|
| Normal Rainfall | 15.0 | 1-year | IMD Light Rain Category |
| Moderate Storm (2-yr) | 40.0 | 2-year | IMD Moderate Rain (15.6–64.4 mm/day) |
| Heavy Storm (10-yr) | 75.0 | 10-year | IMD Heavy Rain (64.5–115.5 mm/day) |
| Extreme Event (50-yr) | 120.0 | 50-year | Chennai 2015 (494mm/24hr) / Mumbai 2005 (944mm/24hr) |
| Catastrophic (100-yr) | 200.0 | 100-year | IPCC AR6 Climate Change Scenario |

---

## ✅ Validation

### Chennai 2015 Flood Event

During December 2015, Chennai received ~494 mm of rainfall in 24 hours. Under the "Extreme Event" scenario (120 mm/hr), the model classifies:
- **Adyar Basin → High** (SI: 0.618) — consistent with severe flooding in low-elevation, high-ISR areas
- **Cooum Basin → High** (SI: 0.644) — lowest elevation (4m), highest ISR (0.70)

Under "Catastrophic" (200 mm/hr):
- **Cooum Basin → High** (SI: 0.737) — approaching Severe threshold

### Mumbai 2005 Flood Event

Mumbai received 944 mm on July 26, 2005. Under the "Catastrophic" scenario:
- **Mithi River Basin → Severe** (SI: 0.751) — correctly classified, consistent with the extreme flooding of the Mithi River during the event. High ISR (0.75) and low drainage density (2.5) drive the high SI.

### Low-Risk Validation

- **Anacostia Basin + Normal → Moderate** (SI: 0.429) — lowest ISR basin (0.23) at moderate elevation (30m), appropriately lower risk
- **Musi River Basin + Normal → Moderate** (SI: 0.403) — highest elevation (505m) significantly reduces susceptibility

---

## 🚀 Running the Application

### Prerequisites

- GHC 9.6+ (Haskell compiler)
- Cabal 3.8+ (build tool)
- SQLite3
- Node.js 18+ & npm

### Setup & Run

```bash
# Clone the repository
git clone https://github.com/CSDeeraj/haskell-to-sqlite.git
cd haskell-to-sqlite

# Build the React frontend
cd frontend-react
npm install
npm run build
cd ..

# Build and run the Haskell backend
cabal update
cabal build
cabal run flood-susceptibility
```

The server starts on **http://localhost:3000** and serves the React frontend.

### Development Mode

```bash
# Terminal 1: Backend
cabal run flood-susceptibility

# Terminal 2: Frontend (hot reload)
cd frontend-react
npm run dev
```

Frontend dev server runs at **http://localhost:5173**, proxying API calls to port 3000.

---

## 🔌 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/basins` | All 7 basins with full parameters |
| `GET` | `/api/scenarios` | All 5 precipitation scenarios |
| `POST` | `/api/classify` | Classify risk for one basin + scenario |
| `POST` | `/api/classify-all` | Classify one basin across all scenarios |
| `GET` | `/api/results` | All stored risk results |
| `GET` | `/api/basin-coordinates` | Basins with lat/lon + latest risk |
| `GET` | `/api/scenario-matrix` | Full 7×5 basin × scenario matrix |

### Example: Classify Risk

```bash
curl -X POST http://localhost:3000/api/classify \
  -H "Content-Type: application/json" \
  -d '{"crBasinId": 3, "crScenarioId": 5}'
```

### Example Response

```json
{
  "status": "success",
  "basinName": "Mithi River Basin",
  "city": "Mumbai",
  "scenario": "Catastrophic (100-yr)",
  "rainfall_mm": 200.0,
  "siScore": 0.751,
  "riskLevel": "Severe",
  "description": "Severe flood danger! Immediate protective action required.",
  "sensitivity": "{\"rainfall\":0.233,\"slope\":0.135,\"elevation\":0.148,\"isr\":0.150,\"drainage\":0.084}"
}
```

---

## 🖥️ Frontend

The React frontend features a **deep navy/cyan/teal flood-themed** dark interface with:

1. **Dashboard** — Overview with risk distribution chart, basin parameters comparison, methodology cards
2. **Flood Map** — Interactive Leaflet world map with risk-colored markers (7 international basins)
3. **Scenario Selector** — Live risk reclassification with water-fill animated cards
4. **Basin Comparison** — Side-by-side parameter bars for two selected basins
5. **Sensitivity Analysis** — Parameter contribution bars showing which factor drives risk most
6. **Scenario Matrix** — Full 7×5 table with color-coded risk badges and SI scores
7. **Results** — Stored risk assessment records with SI scores

### Design System

- **Typography**: JetBrains Mono for data values, Inter for labels
- **Colors**: Deep navy (#020617), cyan (#06b6d4), teal (#14b8a6)
- **Risk Badges**: Low=green, Moderate=yellow, High=orange, Severe=crimson with neon glow
- **Effects**: Water-fill animations, topographic SVG contour background, glassmorphism cards

---

## 🧰 Tech Stack

| Component | Technology |
|-----------|------------|
| Backend Language | Haskell (GHC 9.6+) |
| Build Tool | Cabal |
| Web Framework | Scotty |
| Database | SQLite (via sqlite-simple) |
| JSON Handling | Aeson |
| Frontend | React.js + Vite |
| Charts | Chart.js + react-chartjs-2 |
| Maps | React-Leaflet + CARTO Dark Basemap |
| Styling | Custom CSS (flood-themed dark palette) |

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.
