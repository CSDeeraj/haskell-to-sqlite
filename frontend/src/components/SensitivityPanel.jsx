import { useState, useEffect } from 'react';
import { classifyRisk } from '../api';

const PARAM_COLORS = {
    rainfall: '#0ea5e9', slope: '#06b6d4', elevation: '#14b8a6', isr: '#eab308', drainage: '#f97316',
};
const PARAM_LABELS = {
    rainfall: 'Rainfall', slope: 'Inv. Slope', elevation: 'Inv. Elevation', isr: 'Impervious Ratio', drainage: 'Inv. Drainage Dd',
};

export default function SensitivityPanel({ basins, scenarios }) {
    const [selectedBasin, setSelectedBasin] = useState('');
    const [selectedScenario, setSelectedScenario] = useState('');
    const [sensData, setSensData] = useState(null);
    const [siScore, setSiScore] = useState(null);
    const [riskLevel, setRiskLevel] = useState(null);
    const [loading, setLoading] = useState(false);

    async function handleAnalyze() {
        if (!selectedBasin || !selectedScenario) return;
        setLoading(true);
        try {
            const res = await classifyRisk({ crBasinId: parseInt(selectedBasin), crScenarioId: parseInt(selectedScenario) });
            if (res.status === 'success' && res.sensitivity) {
                try {
                    const parsed = typeof res.sensitivity === 'string' ? JSON.parse(res.sensitivity) : res.sensitivity;
                    setSensData(parsed);
                } catch { setSensData(null); }
                setSiScore(res.siScore);
                setRiskLevel(res.riskLevel);
            }
        } catch (err) {
            console.error(err);
        } finally {
            setLoading(false);
        }
    }

    const maxContrib = sensData ? Math.max(...Object.values(sensData), 0.01) : 1;

    return (
        <div className="tab-content">
            <div className="grid-2" style={{ marginBottom: '1.5rem' }}>
                <div className="panel">
                    <div className="panel-header"><h2>📊 Sensitivity Analysis</h2></div>
                    <div className="panel-body">
                        <div className="form-group">
                            <label>Basin</label>
                            <select value={selectedBasin} onChange={e => { setSelectedBasin(e.target.value); setSensData(null); }}>
                                <option value="">Select a basin...</option>
                                {basins.map(b => <option key={b.basinId} value={b.basinId}>{b.basinName} — {b.city}</option>)}
                            </select>
                        </div>
                        <div className="form-group">
                            <label>Scenario</label>
                            <select value={selectedScenario} onChange={e => { setSelectedScenario(e.target.value); setSensData(null); }}>
                                <option value="">Select a scenario...</option>
                                {scenarios.map(s => <option key={s.scenarioId} value={s.scenarioId}>{s.scenarioName} ({s.intensityMm} mm/hr)</option>)}
                            </select>
                        </div>
                        <button className="btn btn-primary btn-full" onClick={handleAnalyze} disabled={!selectedBasin || !selectedScenario || loading}>
                            {loading ? '⏳ Analyzing...' : '📊 Analyze Sensitivity'}
                        </button>
                    </div>
                </div>

                <div className="panel">
                    <div className="panel-header"><h2>🔬 Parameter Contributions to SI</h2></div>
                    <div className="panel-body">
                        {sensData ? (
                            <>
                                <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '1.2rem' }}>
                                    <div>
                                        <div className="si-score font-data" style={{ color: riskLevel === 'Severe' ? '#dc2626' : riskLevel === 'High' ? '#f97316' : riskLevel === 'Moderate' ? '#eab308' : '#22c55e' }}>
                                            {siScore?.toFixed(3)}
                                        </div>
                                        <div className="si-label">SI Score</div>
                                    </div>
                                    <span className={`risk-badge ${riskLevel === 'Low' ? 'risk-low' : riskLevel === 'Moderate' ? 'risk-moderate' : riskLevel === 'High' ? 'risk-high' : 'risk-severe'}`} style={{ fontSize: '.85rem', padding: '.4rem 1rem' }}>
                                        {riskLevel}
                                    </span>
                                </div>
                                {Object.entries(sensData).sort((a, b) => b[1] - a[1]).map(([key, value]) => {
                                    const pct = Math.max(5, (value / maxContrib) * 100);
                                    return (
                                        <div key={key} className="sensitivity-bar">
                                            <span className="sensitivity-bar-label">{PARAM_LABELS[key] || key}</span>
                                            <div className="sensitivity-bar-track">
                                                <div className="sensitivity-bar-fill" style={{ width: `${pct}%`, background: PARAM_COLORS[key] || '#06b6d4' }}>
                                                </div>
                                            </div>
                                            <span className="sensitivity-bar-value">{value.toFixed(3)}</span>
                                        </div>
                                    );
                                })}
                                <p style={{ marginTop: '1rem', fontSize: '.72rem', color: 'var(--text-muted)', fontStyle: 'italic' }}>
                                    Bars show each parameter's weighted contribution to the SI score. The parameter with the highest bar is the primary driver of flood risk for this basin-scenario combination.
                                </p>
                            </>
                        ) : (
                            <div className="empty-state">Select a basin and scenario, then click Analyze</div>
                        )}
                    </div>
                </div>
            </div>
        </div>
    );
}
