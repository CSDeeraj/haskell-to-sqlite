import { useState } from 'react';

const RISK_COLORS = { Low: '#22c55e', Moderate: '#eab308', High: '#f97316', Severe: '#dc2626' };

export default function BasinComparison({ basins, scenarios, matrix }) {
    const [basinA, setBasinA] = useState('');
    const [basinB, setBasinB] = useState('');

    const a = basins.find(b => b.basinId === parseInt(basinA));
    const b = basins.find(b2 => b2.basinId === parseInt(basinB));

    const matrixA = matrix?.find(m => m.basinId === parseInt(basinA));
    const matrixB = matrix?.find(m => m.basinId === parseInt(basinB));

    const params = [
        { key: 'elevation', label: 'Elevation (m)', max: 600, unit: 'm' },
        { key: 'slope', label: 'Slope (%)', max: 10, unit: '%' },
        { key: 'imperviousRatio', label: 'ISR', max: 1, unit: '', pct: true },
        { key: 'drainageDensity', label: 'Dd (km/km²)', max: 5, unit: '' },
        { key: 'runoffCoeff', label: 'Runoff C', max: 1, unit: '', pct: true },
        { key: 'area', label: 'Area (km²)', max: 500, unit: 'km²' },
    ];

    function renderBasinCard(basin, matrixData, label) {
        if (!basin) return (
            <div className="panel">
                <div className="panel-header"><h2>{label}</h2></div>
                <div className="panel-body"><div className="empty-state">Select a basin</div></div>
            </div>
        );
        return (
            <div className="panel">
                <div className="panel-header"><h2>{basin.basinName}</h2></div>
                <div className="panel-body">
                    <div style={{ marginBottom: '.8rem' }}>
                        <div style={{ fontSize: '.72rem', color: 'var(--text-muted)' }}>{basin.city}, {basin.country}</div>
                    </div>
                    {params.map(p => {
                        const val = basin[p.key];
                        const pct = Math.min(100, (val / p.max) * 100);
                        return (
                            <div key={p.key} className="param-comparison">
                                <div className="param-bar-label">
                                    <span>{p.label}</span>
                                    <span className="font-data" style={{ color: 'var(--text-data)' }}>
                                        {p.pct ? (val * 100).toFixed(0) + '%' : val.toFixed(1)}{p.unit && (' ' + p.unit)}
                                    </span>
                                </div>
                                <div style={{ height: '12px', background: 'rgba(6,182,212,0.06)', borderRadius: '6px', overflow: 'hidden' }}>
                                    <div style={{ height: '100%', width: `${pct}%`, background: 'linear-gradient(90deg, var(--accent-cyan), var(--accent-teal))', borderRadius: '6px', transition: 'width .6s ease' }}></div>
                                </div>
                            </div>
                        );
                    })}
                    {matrixData?.scenarios && (
                        <div style={{ marginTop: '1rem' }}>
                            <div style={{ fontSize: '.72rem', fontWeight: 700, color: 'var(--text-secondary)', marginBottom: '.4rem', textTransform: 'uppercase', letterSpacing: '.06em' }}>Risk across scenarios</div>
                            <div style={{ display: 'flex', flexWrap: 'wrap', gap: '.3rem' }}>
                                {matrixData.scenarios.map(s => (
                                    <span key={s.scenarioId} className={`risk-badge ${s.riskLevel === 'Low' ? 'risk-low' : s.riskLevel === 'Moderate' ? 'risk-moderate' : s.riskLevel === 'High' ? 'risk-high' : 'risk-severe'}`} style={{ fontSize: '.6rem' }}>
                                        {s.scenarioType}: {s.riskLevel}
                                    </span>
                                ))}
                            </div>
                        </div>
                    )}
                </div>
            </div>
        );
    }

    return (
        <div className="tab-content">
            <div className="grid-2" style={{ marginBottom: '1rem' }}>
                <div className="form-group">
                    <label>Basin A</label>
                    <select value={basinA} onChange={e => setBasinA(e.target.value)}>
                        <option value="">Select first basin...</option>
                        {basins.map(b => <option key={b.basinId} value={b.basinId}>{b.basinName} — {b.city}</option>)}
                    </select>
                </div>
                <div className="form-group">
                    <label>Basin B</label>
                    <select value={basinB} onChange={e => setBasinB(e.target.value)}>
                        <option value="">Select second basin...</option>
                        {basins.map(b => <option key={b.basinId} value={b.basinId}>{b.basinName} — {b.city}</option>)}
                    </select>
                </div>
            </div>
            <div className="comparison-grid">
                {renderBasinCard(a, matrixA, 'Basin A')}
                <div className="comparison-vs">VS</div>
                {renderBasinCard(b, matrixB, 'Basin B')}
            </div>
        </div>
    );
}
