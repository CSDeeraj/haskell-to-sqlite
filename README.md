# Deterministic Modeling of Flood Susceptibility in Urban Sub-Basins

> Under Varying Precipitation Scenarios

A full-stack application built with **Haskell**, **SQLite**, and **vanilla JavaScript** that estimates flood susceptibility for urban sub-basins using **Algebraic Data Types (ADTs)** and **pattern matching**.

---

## 🌊 Project Goal

This project models flood susceptibility in urban sub-basins by processing rainfall intensity, elevation, and slope data. It uses a deterministic approach — no probabilistic or ML components — to classify flood risk into four levels: **Low**, **Moderate**, **High**, and **Severe**.

## 📂 Project Structure

```
haskell-to-sqlite/
├── backend/
│   ├── Main.hs           # Server entry point
│   ├── Types.hs          # ADTs: FloodRisk, Basin, RainfallScenario
│   ├── FloodModel.hs     # Deterministic flood risk classifier
│   ├── Database.hs       # SQLite operations & sample data
│   └── Api.hs            # REST API endpoints (Scotty)
├── frontend/
│   ├── index.html         # User interface
│   ├── style.css          # Dark theme with risk color-coding
│   └── app.js             # Fetch API client
├── database/
│   └── schema.sql         # Database schema reference
├── datasets/              # Directory for IMD/SRTM data files
├── haskell-to-sqlite.cabal
├── README.md
└── LICENSE
```

## 📊 Datasets Used

| Dataset | Source | Purpose |
|---------|--------|---------|
| **IMD Rainfall** | Indian Meteorological Department | Precipitation intensity categories (Light → Extreme) |
| **NASA SRTM** | Shuttle Radar Topography Mission | Elevation and terrain slope data |

Sample data is seeded automatically with 5 urban sub-basins (inspired by Chennai's drainage basins) and 10 rainfall scenarios based on IMD categories.

## 🧮 ADTs and Pattern Matching

### Algebraic Data Type: `FloodRisk`

```haskell
data FloodRisk
    = Low       -- Minimal flood danger
    | Moderate  -- Some flood potential
    | High      -- Significant flood risk
    | Severe    -- Critical flood danger
    deriving (Show, Eq, Ord, Generic)
```

This **sum type** ensures only four valid risk categories exist in the system. The compiler enforces exhaustive handling.

### Pattern Matching: Risk Classification

```haskell
classifyFloodRisk :: Double -> Double -> Double -> FloodRisk
classifyFloodRisk rainfall elev slopeVal
    | rainfall >= 100 && elev < 50  && slopeVal < 5  = Severe
    | rainfall >= 150 && elev < 100                   = Severe
    | rainfall >= 200                                 = Severe
    | rainfall >= 80  && elev < 100 && slopeVal < 10  = High
    | rainfall >= 100 && elev < 150                   = High
    | rainfall >= 60  && elev < 30  && slopeVal < 3   = High
    | rainfall >= 40  && elev < 200 && slopeVal < 15  = Moderate
    | rainfall >= 60  && elev < 300                   = Moderate
    | rainfall >= 30  && elev < 50                    = Moderate
    | otherwise                                       = Low
```

Guard-based pattern matching deterministically classifies risk based on:
- **Rainfall intensity** (mm/hr) — higher → more risk
- **Elevation** (meters) — lower → more risk (water accumulates)
- **Slope** (%) — flatter → more risk (poor drainage)

### Additional Pattern Matching Usage

```haskell
riskDescription :: FloodRisk -> Text
riskDescription Low      = "Minimal flood risk."
riskDescription Moderate = "Moderate flood potential."
riskDescription High     = "High flood risk."
riskDescription Severe   = "Severe flood danger!"
```

Pattern matching on ADT constructors is used for:
- JSON serialization/deserialization
- Database text conversion (`riskToText`, `textToRisk`)
- Human-readable descriptions
- API response generation

## 🚀 Running in GitHub Codespaces

### Prerequisites

These are available by default in GitHub Codespaces with Haskell:
- GHC (Haskell compiler)
- Cabal (build tool)
- SQLite3

### Setup & Run

```bash
# 1. Clone the repository
git clone https://github.com/CSDeeraj/haskell-to-sqlite.git
cd haskell-to-sqlite

# 2. Update cabal package list
cabal update

# 3. Build the project
cabal build

# 4. Run the server
cabal run flood-susceptibility
```

The server starts on **http://localhost:3000**.

### In Codespaces

When running in GitHub Codespaces, port 3000 will be automatically forwarded. Click the forwarded port URL to open the frontend in your browser.

## 🔌 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/basins` | List all urban sub-basins |
| `GET` | `/api/rainfall` | List all rainfall scenarios |
| `POST` | `/api/upload-rainfall` | Upload a new rainfall scenario |
| `POST` | `/api/calculate-risk` | Calculate flood risk for a basin + rainfall pair |
| `GET` | `/api/results` | List all calculated flood risk results |

### Example: Calculate Risk

```bash
curl -X POST http://localhost:3000/api/calculate-risk \
  -H "Content-Type: application/json" \
  -d '{"crBasinId": 1, "crRainfallId": 1}'
```

Response:
```json
{
  "status": "success",
  "basinName": "Adyar Basin",
  "scenario": "Light Monsoon",
  "rainfall_mm": 15.0,
  "elevation_m": 12.0,
  "slope_pct": 2.5,
  "riskLevel": "Moderate",
  "description": "Moderate flood potential. Monitor water levels.",
  "calculatedAt": "2025-01-15T10:30:00"
}
```

### Example: Upload Rainfall

```bash
curl -X POST http://localhost:3000/api/upload-rainfall \
  -H "Content-Type: application/json" \
  -d '{"urBasinId": 1, "urScenarioName": "Cyclone Event", "urIntensityMm": 160.0, "urDurationHours": 12.0}'
```

## 🖥️ Frontend

The frontend provides a simple UI to:

1. **View sub-basins** — Table showing all urban sub-basins with elevation, slope, area
2. **View rainfall scenarios** — All available precipitation data
3. **Upload rainfall data** — Add new scenarios via form
4. **Calculate flood risk** — Select basin + rainfall, get risk assessment
5. **View results** — Table with color-coded risk levels

### Risk Level Color Coding

| Risk Level | Color | Meaning |
|------------|-------|---------|
| 🟢 Low | Green | Minimal flood danger |
| 🟡 Moderate | Amber | Monitor water levels |
| 🟠 High | Orange | Prepare flood defenses |
| 🔴 Severe | Red | Immediate action required |

## 🧰 Tech Stack

| Component | Technology |
|-----------|------------|
| Backend Language | Haskell (GHC) |
| Build Tool | Cabal |
| Web Framework | Scotty |
| Database | SQLite (via sqlite-simple) |
| JSON Handling | Aeson |
| Frontend | HTML + CSS + Vanilla JavaScript |

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.
