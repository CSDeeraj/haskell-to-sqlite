function riskClass(level) {
    switch (level) { case 'Low': return 'risk-low'; case 'Moderate': return 'risk-moderate'; case 'High': return 'risk-high'; case 'Severe': return 'risk-severe'; default: return ''; }
}

export default function ResultsPanel({ results, basins, onRefresh }) {
    if (!results || results.length === 0) {
        return (
            <div className="tab-content">
                <div className="panel">
                    <div className="panel-header">
                        <h2>🔬 Risk Assessment Results</h2>
                        <button className="btn btn-secondary btn-sm" onClick={onRefresh}>🔄 Refresh</button>
                    </div>
                    <div className="panel-body">
                        <div className="empty-state">
                            No results yet. Use the <strong>Scenario Selector</strong> tab to classify basins.
                        </div>
                    </div>
                </div>
            </div>
        );
    }

    const basinMap = {};
    basins.forEach(b => { basinMap[b.basinId] = b; });

    return (
        <div className="tab-content">
            <div className="panel">
                <div className="panel-header">
                    <h2>🔬 Risk Assessment Results ({results.length} records)</h2>
                    <button className="btn btn-secondary btn-sm" onClick={onRefresh}>🔄 Refresh</button>
                </div>
                <div className="panel-body" style={{ overflowX: 'auto' }}>
                    <table className="data-table">
                        <thead>
                            <tr>
                                <th>#</th>
                                <th>Basin</th>
                                <th>Scenario</th>
                                <th>SI Score</th>
                                <th>Risk Level</th>
                                <th>Timestamp</th>
                            </tr>
                        </thead>
                        <tbody>
                            {results.map((r, i) => {
                                const basin = basinMap[r.rrBasinId];
                                return (
                                    <tr key={r.resultId || i}>
                                        <td className="data-value font-data">{r.resultId}</td>
                                        <td className="basin-name">{basin?.basinName || `Basin #${r.rrBasinId}`}</td>
                                        <td className="data-value font-data">Scenario #{r.rrScenarioId}</td>
                                        <td><span className="data-value font-data">{r.siScore?.toFixed(4)}</span></td>
                                        <td>
                                            <span className={`risk-badge ${riskClass(r.riskLevel)}`}>
                                                {r.riskLevel}
                                            </span>
                                        </td>
                                        <td style={{ fontSize: '.72rem', color: 'var(--text-muted)' }}>{r.calculatedAt}</td>
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
