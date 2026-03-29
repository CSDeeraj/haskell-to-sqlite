const RISK_COLORS = { Low: '#22c55e', Moderate: '#eab308', High: '#f97316', Severe: '#dc2626' };
function riskClass(level) {
    switch (level) { case 'Low': return 'risk-low'; case 'Moderate': return 'risk-moderate'; case 'High': return 'risk-high'; case 'Severe': return 'risk-severe'; default: return ''; }
}

export default function ScenarioMatrix({ basins, scenarios, matrix }) {
    if (!matrix || matrix.length === 0) return <div className="tab-content"><div className="empty-state">Loading scenario matrix...</div></div>;

    return (
        <div className="tab-content">
            <div className="panel">
                <div className="panel-header">
                    <h2>📋 Scenario Comparison Matrix — All Basins × All Scenarios</h2>
                </div>
                <div className="panel-body" style={{ overflowX: 'auto' }}>
                    <table className="matrix-table">
                        <thead>
                            <tr>
                                <th style={{ minWidth: '160px' }}>Basin</th>
                                {scenarios.map(s => (
                                    <th key={s.scenarioId} style={{ minWidth: '130px' }}>
                                        <div>{s.scenarioName}</div>
                                        <div style={{ fontSize: '.85rem', fontWeight: 600, color: 'var(--text-muted)', textTransform: 'none', marginTop: '.3rem' }}>
                                            {s.intensityMm} mm/hr · {s.returnPeriod}-yr
                                        </div>
                                    </th>
                                ))}
                            </tr>
                        </thead>
                        <tbody>
                            {matrix.map(basin => {
                                const scenarioData = basin.scenarios || [];
                                return (
                                    <tr key={basin.basinId}>
                                        <td>
                                            <div className="basin-name" style={{ fontSize: '1.05rem', fontWeight: 700 }}>{basin.basinName}</div>
                                            <div style={{ fontSize: '.9rem', color: 'var(--text-muted)', marginTop: '.2rem' }}>
                                                {basin.city}, {basin.country}
                                            </div>
                                        </td>
                                        {scenarios.map(s => {
                                            const match = scenarioData.find(sd => sd.scenarioId === s.scenarioId);
                                            if (!match) return <td key={s.scenarioId}>—</td>;
                                            return (
                                                <td key={s.scenarioId}>
                                                    <div className="matrix-cell">
                                                        <span className={`risk-badge ${riskClass(match.riskLevel)}`}>
                                                            {match.riskLevel}
                                                        </span>
                                                        <span className="matrix-si font-data" style={{ fontSize: '.9rem', fontWeight: 700 }}>
                                                            SI: {match.siScore?.toFixed(3)}
                                                        </span>
                                                    </div>
                                                </td>
                                            );
                                        })}
                                    </tr>
                                );
                            })}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    );
}
