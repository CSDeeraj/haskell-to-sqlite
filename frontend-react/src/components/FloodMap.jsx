import { useState, useMemo } from 'react';
import { MapContainer, TileLayer, CircleMarker, Popup, useMap } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';

const RISK_COLORS = {
    Low: '#22c55e', Moderate: '#eab308', High: '#f97316', Severe: '#dc2626', Unknown: '#64748b',
};

const FALLBACK_DATA = [
    { basinId: 1, basinName: 'Adyar Basin', city: 'Chennai', country: 'India', latitude: 13.0067, longitude: 80.2573, elevation: 6, slope: 1.5, isr: 0.65, riskLevel: 'High', siScore: 0 },
    { basinId: 2, basinName: 'Cooum Basin', city: 'Chennai', country: 'India', latitude: 13.0827, longitude: 80.2707, elevation: 4, slope: 1.0, isr: 0.70, riskLevel: 'High', siScore: 0 },
    { basinId: 3, basinName: 'Mithi River Basin', city: 'Mumbai', country: 'India', latitude: 19.1075, longitude: 72.8877, elevation: 10, slope: 1.5, isr: 0.75, riskLevel: 'Severe', siScore: 0 },
    { basinId: 4, basinName: 'Musi River Basin', city: 'Hyderabad', country: 'India', latitude: 17.385, longitude: 78.4867, elevation: 505, slope: 3.5, isr: 0.55, riskLevel: 'Moderate', siScore: 0 },
    { basinId: 5, basinName: 'Ciliwung Basin', city: 'Jakarta', country: 'Indonesia', latitude: -6.1751, longitude: 106.8272, elevation: 5, slope: 2.0, isr: 0.68, riskLevel: 'High', siScore: 0 },
    { basinId: 6, basinName: 'Brays Bayou', city: 'Houston', country: 'USA', latitude: 29.6911, longitude: -95.4091, elevation: 12, slope: 0.5, isr: 0.55, riskLevel: 'High', siScore: 0 },
    { basinId: 7, basinName: 'Anacostia Basin', city: 'Washington DC', country: 'USA', latitude: 38.87, longitude: -76.98, elevation: 30, slope: 3.0, isr: 0.23, riskLevel: 'Low', siScore: 0 },
];

function riskRadius(risk) {
    switch (risk) { case 'Severe': return 14; case 'High': return 12; case 'Moderate': return 10; default: return 8; }
}

export default function FloodMap({ matrix }) {
    const [selectedBasin, setSelectedBasin] = useState(null);
    const [filterCity, setFilterCity] = useState('All');

    const basinsData = useMemo(() => {
        if (matrix && matrix.length > 0) {
            return matrix.map(b => {
                const extremeScenario = b.scenarios?.find(s => s.scenarioType === 'ExtremeEvent');
                return {
                    basinId: b.basinId, basinName: b.basinName, city: b.city, country: b.country,
                    latitude: b.latitude, longitude: b.longitude,
                    elevation: b.elevation, slope: b.slope, isr: b.isr,
                    drainageDensity: b.drainageDensity, area: b.area,
                    riskLevel: extremeScenario?.riskLevel || 'Unknown',
                    siScore: extremeScenario?.siScore || 0,
                    scenarios: b.scenarios,
                };
            }).filter(b => b.latitude && b.longitude);
        }
        return FALLBACK_DATA;
    }, [matrix]);

    const cities = useMemo(() => ['All', ...new Set(basinsData.map(b => b.city))], [basinsData]);
    const filtered = filterCity === 'All' ? basinsData : basinsData.filter(b => b.city === filterCity);

    const riskCounts = { Low: 0, Moderate: 0, High: 0, Severe: 0 };
    filtered.forEach(b => { if (riskCounts[b.riskLevel] !== undefined) riskCounts[b.riskLevel]++; });
    const total = filtered.length || 1;

    return (
        <div className="tab-content">
            <div className="map-layout">
                <div className="map-sidebar">
                    <div className="map-panel">
                        <h3>🗺️ Basin Risk Map</h3>
                        <p style={{ fontSize: '.72rem', color: 'var(--text-muted)', marginBottom: '.6rem' }}>
                            Showing risk levels under <strong>Extreme Event (50-yr)</strong> scenario
                        </p>
                        <div className="city-filter-pills">
                            {cities.map(c => (
                                <button key={c} className={`city-pill ${filterCity === c ? 'active' : ''}`} onClick={() => setFilterCity(c)}>{c}</button>
                            ))}
                        </div>
                    </div>

                    <div className="map-panel">
                        <h3>📊 Risk Distribution</h3>
                        <div className="risk-summary-bars">
                            {['Severe', 'High', 'Moderate', 'Low'].map(level => (
                                <div key={level} className="risk-summary-row">
                                    <span className="risk-summary-label" style={{ color: RISK_COLORS[level] }}>{level}</span>
                                    <div className="risk-summary-bar-track">
                                        <div className="risk-summary-bar-fill" style={{ width: `${(riskCounts[level] / total) * 100}%`, background: RISK_COLORS[level] }}></div>
                                    </div>
                                    <span className="risk-summary-count">{riskCounts[level]}</span>
                                </div>
                            ))}
                        </div>
                    </div>

                    {selectedBasin && (
                        <div className="map-panel">
                            <div className="detail-card-header">
                                <h3>{selectedBasin.basinName}</h3>
                                <button className="detail-close" onClick={() => setSelectedBasin(null)}>✕</button>
                            </div>
                            <div className="detail-card-risk" style={{ borderColor: RISK_COLORS[selectedBasin.riskLevel] + '40', background: RISK_COLORS[selectedBasin.riskLevel] + '10' }}>
                                <span className="detail-risk-level" style={{ color: RISK_COLORS[selectedBasin.riskLevel] }}>{selectedBasin.riskLevel}</span>
                                <span className="font-data" style={{ color: 'var(--text-data)', fontSize: '.78rem' }}>SI: {selectedBasin.siScore?.toFixed(3)}</span>
                            </div>
                            <div className="detail-card-stats">
                                <div className="detail-stat"><span className="detail-stat-icon">📍</span><div><span className="detail-stat-value">{selectedBasin.city}, {selectedBasin.country}</span><span className="detail-stat-label">Location</span></div></div>
                                <div className="detail-stat"><span className="detail-stat-icon">⛰️</span><div><span className="detail-stat-value">{selectedBasin.elevation}m</span><span className="detail-stat-label">Elevation</span></div></div>
                                <div className="detail-stat"><span className="detail-stat-icon">📐</span><div><span className="detail-stat-value">{selectedBasin.slope}%</span><span className="detail-stat-label">Slope</span></div></div>
                                <div className="detail-stat"><span className="detail-stat-icon">🏗️</span><div><span className="detail-stat-value">{(selectedBasin.isr * 100).toFixed(0)}%</span><span className="detail-stat-label">ISR</span></div></div>
                            </div>
                        </div>
                    )}

                    <div className="map-panel">
                        <h3>📌 Legend</h3>
                        <div className="legend-items-vertical">
                            {Object.entries(RISK_COLORS).filter(([k]) => k !== 'Unknown').map(([level, color]) => (
                                <div key={level} className="legend-row">
                                    <div className="legend-dot" style={{ background: color, boxShadow: `0 0 8px ${color}60` }}></div>
                                    <span className="legend-label">{level} Risk</span>
                                </div>
                            ))}
                        </div>
                    </div>
                </div>

                <div className="map-container-wrapper">
                    <MapContainer center={[20, 40]} zoom={2} className="flood-map" style={{ height: '100%', minHeight: '600px' }}>
                        <TileLayer
                            attribution='&copy; <a href="https://carto.com">CARTO</a>'
                            url="https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
                        />
                        {filtered.map(basin => (
                            <CircleMarker
                                key={basin.basinId}
                                center={[basin.latitude, basin.longitude]}
                                radius={riskRadius(basin.riskLevel)}
                                pathOptions={{
                                    fillColor: RISK_COLORS[basin.riskLevel] || '#64748b',
                                    color: RISK_COLORS[basin.riskLevel] || '#64748b',
                                    weight: 2, opacity: 0.9, fillOpacity: 0.6,
                                }}
                                eventHandlers={{ click: () => setSelectedBasin(basin) }}
                            >
                                <Popup>
                                    <div className="map-popup-content">
                                        <div className="map-popup-title">{basin.basinName}</div>
                                        <div className="map-popup-risk">
                                            <div className="map-popup-risk-dot" style={{ background: RISK_COLORS[basin.riskLevel] }}></div>
                                            <span style={{ fontFamily: 'JetBrains Mono, monospace', fontWeight: 700, color: RISK_COLORS[basin.riskLevel] }}>{basin.riskLevel}</span>
                                            <span style={{ fontFamily: 'JetBrains Mono, monospace', fontSize: '.7rem', color: '#94a3b8' }}>SI: {basin.siScore?.toFixed(3)}</span>
                                        </div>
                                        <div className="map-popup-details">
                                            <div>📍 {basin.city}, {basin.country}</div>
                                            <div>⛰️ {basin.elevation}m · 📐 {basin.slope}%</div>
                                            <div>🏗️ ISR: {(basin.isr * 100).toFixed(0)}%</div>
                                        </div>
                                    </div>
                                </Popup>
                            </CircleMarker>
                        ))}
                    </MapContainer>
                </div>
            </div>
        </div>
    );
}
