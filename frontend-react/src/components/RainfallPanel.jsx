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

export default function RainfallPanel({ rainfall, onRefresh }) {
    const barData = {
        labels: rainfall.map((r) => r.scenarioName),
        datasets: [
            {
                label: 'Intensity (mm/hr)',
                data: rainfall.map((r) => r.intensityMm),
                backgroundColor: rainfall.map((r) => {
                    if (r.intensityMm >= 100) return 'rgba(239, 68, 68, 0.65)';
                    if (r.intensityMm >= 60) return 'rgba(249, 115, 22, 0.65)';
                    if (r.intensityMm >= 30) return 'rgba(245, 158, 11, 0.65)';
                    return 'rgba(34, 197, 94, 0.65)';
                }),
                borderColor: rainfall.map((r) => {
                    if (r.intensityMm >= 100) return '#ef4444';
                    if (r.intensityMm >= 60) return '#f97316';
                    if (r.intensityMm >= 30) return '#f59e0b';
                    return '#22c55e';
                }),
                borderWidth: 1,
                borderRadius: 6,
            },
        ],
    };

    const barOptions = {
        responsive: true,
        maintainAspectRatio: false,
        indexAxis: 'y',
        plugins: {
            legend: { display: false },
        },
        scales: {
            x: { ticks: { color: '#64748b', font: { family: 'Inter', size: 10 } }, grid: { color: 'rgba(255,255,255,0.04)' }, title: { display: true, text: 'Intensity (mm/hr)', color: '#64748b', font: { family: 'Inter', size: 10 } } },
            y: { ticks: { color: '#94a3b8', font: { family: 'Inter', size: 10 } }, grid: { display: false } },
        },
    };

    return (
        <div className="tab-content">
            <div className="grid-2-1" style={{ marginBottom: '1.5rem' }}>
                {/* Table */}
                <div className="panel">
                    <div className="panel-header">
                        <h2>🌧️ Rainfall Scenarios</h2>
                        <button className="btn btn-secondary btn-sm" onClick={onRefresh}>↻ Refresh</button>
                    </div>
                    <div className="panel-body">
                        <table className="data-table">
                            <thead>
                                <tr>
                                    <th>ID</th>
                                    <th>Basin ID</th>
                                    <th>Scenario</th>
                                    <th>Intensity (mm/hr)</th>
                                    <th>Duration (hrs)</th>
                                </tr>
                            </thead>
                            <tbody>
                                {rainfall.length === 0 ? (
                                    <tr><td colSpan="5" className="empty-state">No rainfall data found.</td></tr>
                                ) : (
                                    rainfall.map((r) => (
                                        <tr key={r.scenarioId}>
                                            <td>{r.scenarioId}</td>
                                            <td>{r.rsBasinId}</td>
                                            <td><strong>{r.scenarioName}</strong></td>
                                            <td>
                                                <span className={`risk-badge ${r.intensityMm >= 100 ? 'risk-severe' : r.intensityMm >= 60 ? 'risk-high' : r.intensityMm >= 30 ? 'risk-moderate' : 'risk-low'}`}>
                                                    {r.intensityMm.toFixed(1)}
                                                </span>
                                            </td>
                                            <td>{r.durationHours.toFixed(1)}</td>
                                        </tr>
                                    ))
                                )}
                            </tbody>
                        </table>
                    </div>
                </div>

                {/* Chart */}
                <div className="panel">
                    <div className="panel-header">
                        <h2>📈 Intensity Comparison</h2>
                    </div>
                    <div className="panel-body">
                        {rainfall.length > 0 ? (
                            <div className="chart-container" style={{ height: Math.max(200, rainfall.length * 35) + 'px' }}>
                                <Bar data={barData} options={barOptions} />
                            </div>
                        ) : (
                            <div className="empty-state">No rainfall data</div>
                        )}
                    </div>
                </div>
            </div>
        </div>
    );
}
