import {
    Chart as ChartJS,
    BarElement,
    CategoryScale,
    LinearScale,
    Tooltip,
    Legend,
} from 'chart.js';
import { Bar } from 'react-chartjs-2';

ChartJS.register(BarElement, CategoryScale, LinearScale, Tooltip, Legend);

const RISK_COLORS = {
    Low: '#22c55e',
    Moderate: '#f59e0b',
    High: '#f97316',
    Severe: '#ef4444',
};

function riskClass(level) {
    switch (level) {
        case 'Low': return 'risk-low';
        case 'Moderate': return 'risk-moderate';
        case 'High': return 'risk-high';
        case 'Severe': return 'risk-severe';
        default: return '';
    }
}

export default function ResultsPanel({ results, basins, onRefresh }) {
    // Build a risk level summary bar chart
    const riskCounts = { Low: 0, Moderate: 0, High: 0, Severe: 0 };
    results.forEach((r) => {
        if (riskCounts[r.riskLevel] !== undefined) riskCounts[r.riskLevel]++;
    });

    const summaryData = {
        labels: ['Low', 'Moderate', 'High', 'Severe'],
        datasets: [{
            label: 'Count',
            data: [riskCounts.Low, riskCounts.Moderate, riskCounts.High, riskCounts.Severe],
            backgroundColor: ['rgba(34, 197, 94, 0.65)', 'rgba(245, 158, 11, 0.65)', 'rgba(249, 115, 22, 0.65)', 'rgba(239, 68, 68, 0.65)'],
            borderColor: ['#22c55e', '#f59e0b', '#f97316', '#ef4444'],
            borderWidth: 1,
            borderRadius: 8,
        }],
    };

    const summaryOptions = {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
            x: { ticks: { color: '#94a3b8', font: { family: 'Inter', size: 11, weight: 600 } }, grid: { display: false } },
            y: { ticks: { color: '#64748b', font: { family: 'Inter', size: 10 }, stepSize: 1 }, grid: { color: 'rgba(255,255,255,0.04)' } },
        },
    };

    // Map basinId to name
    const basinNameMap = {};
    basins.forEach((b) => { basinNameMap[b.basinId] = b.basinName; });

    return (
        <div className="tab-content">
            <div className="grid-2-1" style={{ marginBottom: '1.5rem' }}>
                {/* Table */}
                <div className="panel">
                    <div className="panel-header">
                        <h2>📋 Flood Risk Results</h2>
                        <button className="btn btn-secondary btn-sm" onClick={onRefresh}>↻ Refresh</button>
                    </div>
                    <div className="panel-body">
                        <table className="data-table">
                            <thead>
                                <tr>
                                    <th>#</th>
                                    <th>Basin</th>
                                    <th>Rainfall ID</th>
                                    <th>Risk Level</th>
                                    <th>Calculated At</th>
                                </tr>
                            </thead>
                            <tbody>
                                {results.length === 0 ? (
                                    <tr><td colSpan="5" className="empty-state">No results yet. Use the Risk Calculator to generate assessments.</td></tr>
                                ) : (
                                    results.map((r) => (
                                        <tr key={r.resultId}>
                                            <td>{r.resultId}</td>
                                            <td><span className="basin-name">{basinNameMap[r.frBasinId] || `Basin ${r.frBasinId}`}</span></td>
                                            <td>{r.frRainfallId}</td>
                                            <td><span className={`risk-badge ${riskClass(r.riskLevel)}`}>{r.riskLevel}</span></td>
                                            <td style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>{r.calculatedAt}</td>
                                        </tr>
                                    ))
                                )}
                            </tbody>
                        </table>
                    </div>
                </div>

                {/* Summary chart */}
                <div className="panel">
                    <div className="panel-header">
                        <h2>📊 Risk Summary</h2>
                    </div>
                    <div className="panel-body">
                        {results.length > 0 ? (
                            <div className="chart-container" style={{ height: '280px' }}>
                                <Bar data={summaryData} options={summaryOptions} />
                            </div>
                        ) : (
                            <div className="empty-state">No results to summarize</div>
                        )}
                    </div>
                </div>
            </div>
        </div>
    );
}
