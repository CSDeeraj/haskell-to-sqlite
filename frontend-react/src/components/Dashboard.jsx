import { useEffect, useState } from 'react';
import {
    Chart as ChartJS,
    ArcElement,
    BarElement,
    CategoryScale,
    LinearScale,
    Tooltip,
    Legend,
} from 'chart.js';
import { Doughnut, Bar } from 'react-chartjs-2';

ChartJS.register(ArcElement, BarElement, CategoryScale, LinearScale, Tooltip, Legend);

const RISK_COLORS = {
    Low: '#22c55e',
    Moderate: '#f59e0b',
    High: '#f97316',
    Severe: '#ef4444',
};

export default function Dashboard({ basins, rainfall, results }) {
    const [animate, setAnimate] = useState(false);
    useEffect(() => { setAnimate(true); }, []);

    // Risk distribution
    const riskCounts = { Low: 0, Moderate: 0, High: 0, Severe: 0 };
    results.forEach((r) => {
        if (riskCounts[r.riskLevel] !== undefined) riskCounts[r.riskLevel]++;
    });

    const doughnutData = {
        labels: ['Low', 'Moderate', 'High', 'Severe'],
        datasets: [{
            data: [riskCounts.Low, riskCounts.Moderate, riskCounts.High, riskCounts.Severe],
            backgroundColor: ['#22c55e', '#f59e0b', '#f97316', '#ef4444'],
            borderColor: 'transparent',
            borderWidth: 0,
            hoverOffset: 8,
        }],
    };

    const doughnutOptions = {
        responsive: true,
        maintainAspectRatio: false,
        cutout: '65%',
        plugins: {
            legend: {
                position: 'bottom',
                labels: { color: '#94a3b8', font: { family: 'Inter', size: 11, weight: 600 }, padding: 16, usePointStyle: true, pointStyleWidth: 8 },
            },
        },
    };

    // Basins comparison chart
    const basinBarData = {
        labels: basins.map((b) => b.basinName),
        datasets: [
            {
                label: 'Elevation (m)',
                data: basins.map((b) => b.elevation),
                backgroundColor: 'rgba(59, 130, 246, 0.6)',
                borderColor: '#3b82f6',
                borderWidth: 1,
                borderRadius: 4,
            },
            {
                label: 'Slope (%)',
                data: basins.map((b) => b.slope),
                backgroundColor: 'rgba(6, 182, 212, 0.6)',
                borderColor: '#06b6d4',
                borderWidth: 1,
                borderRadius: 4,
            },
        ],
    };

    const barOptions = {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            legend: {
                labels: { color: '#94a3b8', font: { family: 'Inter', size: 11, weight: 600 }, usePointStyle: true, pointStyleWidth: 8 },
            },
        },
        scales: {
            x: { ticks: { color: '#64748b', font: { family: 'Inter', size: 10 } }, grid: { color: 'rgba(255,255,255,0.04)' } },
            y: { ticks: { color: '#64748b', font: { family: 'Inter', size: 10 } }, grid: { color: 'rgba(255,255,255,0.04)' } },
        },
    };

    // Determine dominant risk
    const dominantRisk = Object.entries(riskCounts).reduce((a, b) => (b[1] > a[1] ? b : a), ['None', 0]);

    return (
        <div className="tab-content">
            {/* Stats cards */}
            <div className="stats-bar">
                <div className="stat-card">
                    <span className="stat-icon">🏘️</span>
                    <span className="stat-number">{basins.length}</span>
                    <span className="stat-label">Sub-Basins</span>
                </div>
                <div className="stat-card">
                    <span className="stat-icon">🌧️</span>
                    <span className="stat-number">{rainfall.length}</span>
                    <span className="stat-label">Rainfall Scenarios</span>
                </div>
                <div className="stat-card">
                    <span className="stat-icon">📊</span>
                    <span className="stat-number">{results.length}</span>
                    <span className="stat-label">Risk Assessments</span>
                </div>
                <div className="stat-card">
                    <span className="stat-icon">⚡</span>
                    <span className="stat-number" style={{ color: dominantRisk[0] !== 'None' ? RISK_COLORS[dominantRisk[0]] : undefined, background: 'none', WebkitTextFillColor: dominantRisk[0] !== 'None' ? RISK_COLORS[dominantRisk[0]] : undefined }}>
                        {dominantRisk[0]}
                    </span>
                    <span className="stat-label">Dominant Risk</span>
                </div>
            </div>

            {/* Charts row */}
            <div className="grid-2" style={{ marginBottom: '1.5rem' }}>
                <div className="panel">
                    <div className="panel-header">
                        <h2>🎯 Risk Distribution</h2>
                    </div>
                    <div className="panel-body">
                        {results.length > 0 ? (
                            <div className="chart-container" style={{ height: '280px' }}>
                                <Doughnut data={doughnutData} options={doughnutOptions} />
                            </div>
                        ) : (
                            <div className="empty-state">Calculate risks to see distribution</div>
                        )}
                    </div>
                </div>

                <div className="panel">
                    <div className="panel-header">
                        <h2>🏔️ Basin Terrain Comparison</h2>
                    </div>
                    <div className="panel-body">
                        {basins.length > 0 ? (
                            <div className="chart-container" style={{ height: '280px' }}>
                                <Bar data={basinBarData} options={barOptions} />
                            </div>
                        ) : (
                            <div className="empty-state">No basin data available</div>
                        )}
                    </div>
                </div>
            </div>

            {/* Info section */}
            <div className="panel">
                <div className="panel-header">
                    <h2>🧮 How It Works: ADTs & Pattern Matching</h2>
                </div>
                <div className="panel-body">
                    <div className="info-grid">
                        <div className="info-card">
                            <h3>Algebraic Data Types</h3>
                            <p>Flood risk is modeled as a <strong>sum type</strong> in Haskell:</p>
                            <pre><code>data FloodRisk = Low | Moderate | High | Severe</code></pre>
                            <p>This ensures only valid risk categories exist in the system.</p>
                        </div>
                        <div className="info-card">
                            <h3>Pattern Matching</h3>
                            <p>Risk classification uses <strong>guard-based pattern matching</strong>:</p>
                            <pre><code>{`classifyFloodRisk rainfall elev slope
  | rainfall >= 100 && elev < 50  = Severe
  | rainfall >= 80  && elev < 100 = High
  | rainfall >= 40  && elev < 200 = Moderate
  | otherwise                     = Low`}</code></pre>
                        </div>
                        <div className="info-card">
                            <h3>Datasets Used</h3>
                            <ul>
                                <li><strong>IMD Rainfall</strong> – Indian Meteorological Department precipitation categories</li>
                                <li><strong>NASA SRTM</strong> – Shuttle Radar Topography Mission elevation data</li>
                            </ul>
                        </div>
                        <div className="info-card risk-legend">
                            <h3>Risk Level Legend</h3>
                            <div className="legend-items">
                                <span className="risk-badge risk-low">🟢 Low</span>
                                <span className="risk-badge risk-moderate">🟡 Moderate</span>
                                <span className="risk-badge risk-high">🟠 High</span>
                                <span className="risk-badge risk-severe">🔴 Severe</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}
