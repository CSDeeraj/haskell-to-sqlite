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

export default function BasinsPanel({ basins, onRefresh }) {
    const barData = {
        labels: basins.map((b) => b.basinName),
        datasets: [
            {
                label: 'Elevation (m)',
                data: basins.map((b) => b.elevation),
                backgroundColor: 'rgba(59, 130, 246, 0.65)',
                borderColor: '#3b82f6',
                borderWidth: 1,
                borderRadius: 6,
            },
            {
                label: 'Slope (%)',
                data: basins.map((b) => b.slope),
                backgroundColor: 'rgba(139, 92, 246, 0.65)',
                borderColor: '#8b5cf6',
                borderWidth: 1,
                borderRadius: 6,
            },
            {
                label: 'Area (km²)',
                data: basins.map((b) => b.area),
                backgroundColor: 'rgba(6, 182, 212, 0.65)',
                borderColor: '#06b6d4',
                borderWidth: 1,
                borderRadius: 6,
            },
        ],
    };

    const barOptions = {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            legend: {
                labels: { color: '#94a3b8', font: { family: 'Inter', size: 11, weight: 600 }, usePointStyle: true, pointStyleWidth: 8, padding: 16 },
            },
        },
        scales: {
            x: { ticks: { color: '#64748b', font: { family: 'Inter', size: 10 } }, grid: { color: 'rgba(255,255,255,0.04)' } },
            y: { ticks: { color: '#64748b', font: { family: 'Inter', size: 10 } }, grid: { color: 'rgba(255,255,255,0.04)' } },
        },
    };

    return (
        <div className="tab-content">
            <div className="grid-2-1" style={{ marginBottom: '1.5rem' }}>
                {/* Table */}
                <div className="panel">
                    <div className="panel-header">
                        <h2>🏘️ Urban Sub-Basins</h2>
                        <button className="btn btn-secondary btn-sm" onClick={onRefresh}>↻ Refresh</button>
                    </div>
                    <div className="panel-body">
                        <table className="data-table">
                            <thead>
                                <tr>
                                    <th>ID</th>
                                    <th>Basin Name</th>
                                    <th>Elevation (m)</th>
                                    <th>Slope (%)</th>
                                    <th>Area (km²)</th>
                                </tr>
                            </thead>
                            <tbody>
                                {basins.length === 0 ? (
                                    <tr><td colSpan="5" className="empty-state">No basins found.</td></tr>
                                ) : (
                                    basins.map((b) => (
                                        <tr key={b.basinId}>
                                            <td>{b.basinId}</td>
                                            <td><span className="basin-name">{b.basinName}</span></td>
                                            <td>{b.elevation.toFixed(1)}</td>
                                            <td>{b.slope.toFixed(1)}</td>
                                            <td>{b.area.toFixed(1)}</td>
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
                        <h2>📊 Terrain Data</h2>
                    </div>
                    <div className="panel-body">
                        {basins.length > 0 ? (
                            <div className="chart-container" style={{ height: '320px' }}>
                                <Bar data={barData} options={barOptions} />
                            </div>
                        ) : (
                            <div className="empty-state">No basin data</div>
                        )}
                    </div>
                </div>
            </div>
        </div>
    );
}
