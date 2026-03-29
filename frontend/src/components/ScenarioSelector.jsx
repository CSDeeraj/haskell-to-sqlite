import { useState } from 'react';
import { classifyRisk, classifyAll } from '../api';

const RISK_COLORS = { Low: '#22c55e', Moderate: '#eab308', High: '#f97316', Severe: '#dc2626' };

function riskClass(level) {
    switch (level) {
        case 'Low': return 'risk-low';
        case 'Moderate': return 'risk-moderate';
        case 'High': return 'risk-high';
        case 'Severe': return 'risk-severe';
        default: return '';
    }
}

export default function ScenarioSelector({ basins, scenarios, onDataChange }) {
    const [selectedScenario, setSelectedScenario] = useState('');
    const [allResults, setAllResults] = useState(null);
    const [isClassifying, setIsClassifying] = useState(false);
    const [singleResult, setSingleResult] = useState(null);
    const [selectedBasin, setSelectedBasin] = useState('');

    async function handleClassifyAll() {
        if (!selectedScenario) return;
        setIsClassifying(true);
        setAllResults(null);
        try {
            const results = await Promise.all(
                basins.map(b =>
                    classifyRisk({ crBasinId: b.basinId, crScenarioId: parseInt(selectedScenario) })
                )
            );
            setAllResults(results.filter(r => r.status === 'success'));
            onDataChange();
        } catch (err) {
            console.error('Classification failed:', err);
        } finally {
            setIsClassifying(false);
        }
    }

    async function handleSingleClassify() {
        if (!selectedBasin || !selectedScenario) return;
        setIsClassifying(true);
        setSingleResult(null);
        try {
            const res = await classifyRisk({ crBasinId: parseInt(selectedBasin), crScenarioId: parseInt(selectedScenario) });
            setSingleResult(res);
            onDataChange();
        } catch (err) {
            console.error(err);
        } finally {
            setIsClassifying(false);
        }
    }

    const scenarioInfo = scenarios.find(s => s.scenarioId === parseInt(selectedScenario));

    return (
        <div className="tab-content">
            <div className="grid-2" style={{ marginBottom: '1.5rem' }}>
                <div className="panel">
                    <div className="panel-header"><h2>🌧️ Select Precipitation Scenario</h2></div>
                    <div className="panel-body">
                        <div className="form-group">
                            <label>Scenario</label>
                            <select value={selectedScenario} onChange={e => { setSelectedScenario(e.target.value); setAllResults(null); setSingleResult(null); }}>
                                <option value="">Choose a scenario...</option>
                                {scenarios.map(s => (
                                    <option key={s.scenarioId} value={s.scenarioId}>
                                        {s.scenarioName} ({s.intensityMm} mm/hr, {s.returnPeriod}-yr)
                                    </option>
                                ))}
                            </select>
                        </div>
                        {scenarioInfo && (
                            <div className="result-card" style={{ marginTop: '.8rem' }}>
                                <h4>Scenario Details</h4>
                                <div className="result-details">
                                    <div className="detail-item"><strong>Type:</strong> {scenarioInfo.scenarioType}</div>
                                    <div className="detail-item"><strong>Intensity:</strong> <span className="data-value font-data">{scenarioInfo.intensityMm} mm/hr</span></div>
                                    <div className="detail-item"><strong>Return Period:</strong> <span className="font-data">{scenarioInfo.returnPeriod} years</span></div>
                                    <div className="detail-item"><strong>Duration:</strong> <span className="font-data">{scenarioInfo.durationHours} hrs</span></div>
                                </div>
                                <p style={{ marginTop: '.6rem', fontSize: '.72rem', color: 'var(--text-muted)', fontStyle: 'italic' }}>
                                    {scenarioInfo.reference}
                                </p>
                            </div>
                        )}
                        <div style={{ display: 'flex', gap: '.6rem', marginTop: '1rem' }}>
                            <button className="btn btn-primary btn-full" onClick={handleClassifyAll} disabled={!selectedScenario || isClassifying}>
                                {isClassifying ? '⏳ Classifying...' : '⚡ Classify All Basins'}
                            </button>
                        </div>
                    </div>
                </div>
                <div className="panel">
                    <div className="panel-header"><h2>🔬 Single Basin Classification</h2></div>
                    <div className="panel-body">
                        <div className="form-group">
                            <label>Basin</label>
                            <select value={selectedBasin} onChange={e => { setSelectedBasin(e.target.value); setSingleResult(null); }}>
                                <option value="">Select a basin...</option>
                                {basins.map(b => (
                                    <option key={b.basinId} value={b.basinId}>{b.basinName} — {b.city}</option>
                                ))}
                            </select>
                        </div>
                        <button className="btn btn-accent btn-full" onClick={handleSingleClassify} disabled={!selectedBasin || !selectedScenario || isClassifying}>
                            {isClassifying ? '⏳...' : '⚡ Classify Risk'}
                        </button>
                        {singleResult && singleResult.status === 'success' && (
                            <div className="result-card">
                                <h4>Risk Assessment</h4>
                                <div className="result-risk-display">
                                    <span className={`risk-badge ${riskClass(singleResult.riskLevel)}`} style={{ fontSize: '1rem', padding: '.45rem 1.2rem' }}>
                                        {singleResult.riskLevel}
                                    </span>
                                    <span className="si-score font-data" style={{ color: RISK_COLORS[singleResult.riskLevel] || '#94a3b8' }}>
                                        SI: {singleResult.siScore?.toFixed(3)}
                                    </span>
                                </div>
                                <div className="result-details">
                                    <div className="detail-item"><strong>Basin:</strong> {singleResult.basinName}</div>
                                    <div className="detail-item"><strong>Rainfall:</strong> <span className="font-data">{singleResult.rainfall_mm} mm/hr</span></div>
                                    <div className="detail-item"><strong>Elevation:</strong> <span className="font-data">{singleResult.elevation_m}m</span></div>
                                    <div className="detail-item"><strong>ISR:</strong> <span className="font-data">{singleResult.isr}</span></div>
                                </div>
                                <p style={{ marginTop: '.6rem', fontSize: '.76rem', color: 'var(--text-secondary)', fontStyle: 'italic' }}>
                                    {singleResult.description}
                                </p>
                            </div>
                        )}
                    </div>
                </div>
            </div>

            {/* All-basin results with water fill cards */}
            {allResults && allResults.length > 0 && (
                <div className="panel">
                    <div className="panel-header"><h2>🌊 Classification Results — {scenarioInfo?.scenarioName}</h2></div>
                    <div className="panel-body">
                        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: '1.5rem' }}>
                            {allResults.map((r, i) => {
                                const fillPct = Math.round((r.siScore || 0) * 100);
                                return (
                                    <div key={i} className="water-fill-card" style={{ '--fill-height': `${fillPct}%` }}>
                                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start', marginBottom: '.8rem' }}>
                                            <div>
                                                <div className="basin-name" style={{ fontSize: '1.15rem', fontWeight: 800 }}>{r.basinName}</div>
                                                <div style={{ fontSize: '.9rem', color: 'var(--text-muted)', marginTop: '.2rem' }}>{r.city}</div>
                                            </div>
                                            <span className={`risk-badge ${riskClass(r.riskLevel)}`} style={{ fontSize: '.85rem', padding: '.4rem .8rem' }}>{r.riskLevel}</span>
                                        </div>
                                        <div className="si-score font-data" style={{ color: RISK_COLORS[r.riskLevel] || '#94a3b8', fontSize: '2.4rem' }}>
                                            {r.siScore?.toFixed(3)}
                                        </div>
                                        <div className="si-label" style={{ fontSize: '.85rem', fontWeight: 700, marginTop: '.4rem' }}>Susceptibility Index</div>
                                    </div>
                                );
                            })}
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
