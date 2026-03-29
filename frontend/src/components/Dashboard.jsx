import { useEffect, useState } from 'react';
import {
    Chart as ChartJS, ArcElement, BarElement, CategoryScale, LinearScale, Tooltip, Legend,
} from 'chart.js';
import { Doughnut, Bar } from 'react-chartjs-2';

ChartJS.register(ArcElement, BarElement, CategoryScale, LinearScale, Tooltip, Legend);

const RISK_COLORS = { Low: '#22c55e', Moderate: '#eab308', High: '#f97316', Severe: '#dc2626' };

export default function Dashboard({ basins, scenarios, results, matrix }) {
    const [animate, setAnimate] = useState(false);
    useEffect(() => { setAnimate(true); }, []);

    // Compute risk from matrix if available
    const riskCounts = { Low: 0, Moderate: 0, High: 0, Severe: 0 };
    if (matrix && matrix.length > 0) {
        matrix.forEach(basin => {
            if (basin.scenarios) {
                basin.scenarios.forEach(s => {
                    if (riskCounts[s.riskLevel] !== undefined) riskCounts[s.riskLevel]++;
                });
            }
        });
    } else {
        results.forEach(r => {
            if (riskCounts[r.riskLevel] !== undefined) riskCounts[r.riskLevel]++;
        });
    }

    const totalAssessments = Object.values(riskCounts).reduce((a, b) => a + b, 0);
    const dominantRisk = Object.entries(riskCounts).reduce((a, b) => b[1] > a[1] ? b : a, ['None', 0]);

    const doughnutData = {
        labels: ['Low', 'Moderate', 'High', 'Severe'],
        datasets: [{
            data: [riskCounts.Low, riskCounts.Moderate, riskCounts.High, riskCounts.Severe],
            backgroundColor: ['#22c55e', '#eab308', '#f97316', '#dc2626'],
            borderColor: 'transparent', borderWidth: 0, hoverOffset: 8,
        }],
    };
    const doughnutOptions = {
        responsive: true, maintainAspectRatio: false, cutout: '68%',
        plugins: { legend: { position: 'bottom', labels: { color: '#94a3b8', font: { family: 'Inter', size: 11, weight: 600 }, padding: 16, usePointStyle: true, pointStyleWidth: 8 } } },
    };

    const basinBarData = {
        labels: basins.map(b => b.basinName),
        datasets: [
            { label: 'ISR', data: basins.map(b => b.imperviousRatio * 100), backgroundColor: 'rgba(6,182,212,0.6)', borderColor: '#06b6d4', borderWidth: 1, borderRadius: 4 },
            { label: 'Slope (%)', data: basins.map(b => b.slope), backgroundColor: 'rgba(14,165,233,0.6)', borderColor: '#0ea5e9', borderWidth: 1, borderRadius: 4 },
            { label: 'Runoff C', data: basins.map(b => b.runoffCoeff * 100), backgroundColor: 'rgba(20,184,166,0.6)', borderColor: '#14b8a6', borderWidth: 1, borderRadius: 4 },
        ],
    };
    const barOptions = {
        responsive: true, maintainAspectRatio: false,
        plugins: { legend: { labels: { color: '#94a3b8', font: { family: 'Inter', size: 11, weight: 600 }, usePointStyle: true, pointStyleWidth: 8 } } },
        scales: {
            x: { ticks: { color: '#64748b', font: { family: 'Inter', size: 9 }, maxRotation: 45 }, grid: { color: 'rgba(6,182,212,0.04)' } },
            y: { ticks: { color: '#64748b', font: { family: 'Inter', size: 10 } }, grid: { color: 'rgba(6,182,212,0.04)' } },
        },
    };

    return (
        <div className="tab-content">
            <div className="stats-bar">
                <div className="stat-card">
                    <span className="stat-icon">🏘️</span>
                    <span className="stat-number">{basins.length}</span>
                    <span className="stat-label">Sub-Basins</span>
                </div>
                <div className="stat-card">
                    <span className="stat-icon">🌧️</span>
                    <span className="stat-number">{scenarios.length}</span>
                    <span className="stat-label">Scenarios</span>
                </div>
                <div className="stat-card">
                    <span className="stat-icon">📊</span>
                    <span className="stat-number">{totalAssessments}</span>
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

            <div className="grid-2" style={{ marginBottom: '1.5rem' }}>
                <div className="panel">
                    <div className="panel-header"><h2>🎯 Risk Distribution (All Basins × Scenarios)</h2></div>
                    <div className="panel-body">
                        {totalAssessments > 0 ? (
                            <div className="chart-container" style={{ height: '280px' }}>
                                <Doughnut data={doughnutData} options={doughnutOptions} />
                            </div>
                        ) : (
                            <div className="empty-state">No risk data yet</div>
                        )}
                    </div>
                </div>
                <div className="panel">
                    <div className="panel-header"><h2>🏔️ Basin Parameters Comparison</h2></div>
                    <div className="panel-body">
                        {basins.length > 0 ? (
                            <div className="chart-container" style={{ height: '280px' }}>
                                <Bar data={basinBarData} options={barOptions} />
                            </div>
                        ) : (
                            <div className="empty-state">No basin data</div>
                        )}
                    </div>
                </div>
            </div>

            <div className="panel">
                <div className="panel-header"><h2>🧮 Methodology: SI Formula & ADTs</h2></div>
                <div className="panel-body">
                    <div className="info-grid">
                        <div className="info-card">
                            <h3>Susceptibility Index (SI)</h3>
                            <p>Weighted multi-criteria formula with AHP-derived weights:</p>
                            <pre><code>{`SI = 0.35×R + 0.15×(1/S) + 0.15×(1/E)
   + 0.20×ISR + 0.15×(1/Dd)

All inputs min-max normalized to [0,1]`}</code></pre>
                        </div>
                        <div className="info-card">
                            <h3>Algebraic Data Types</h3>
                            <pre><code>{`data RiskLevel = Low | Moderate | High | Severe
data PrecipScenario = Normal | ModerateStorm
    | HeavyStorm | ExtremeEvent | Catastrophic

classifyRisk :: SubBasin -> PrecipScenario -> RiskLevel`}</code></pre>
                        </div>
                        <div className="info-card">
                            <h3>Theoretical Foundations</h3>
                            <ul>
                                <li><strong>Rational Method</strong> — Q = CiA (peak discharge)</li>
                                <li><strong>SCS-CN Method</strong> — curve number runoff model</li>
                                <li><strong>AHP</strong> — weight derivation for multi-criteria</li>
                            </ul>
                        </div>
                        <div className="info-card">
                            <h3>Risk Level Classification</h3>
                            <div style={{ display: 'flex', flexWrap: 'wrap', gap: '.5rem', marginTop: '.4rem' }}>
                                <span className="risk-badge risk-low">SI &lt; 0.25 Low</span>
                                <span className="risk-badge risk-moderate">0.25–0.50 Moderate</span>
                                <span className="risk-badge risk-high">0.50–0.75 High</span>
                                <span className="risk-badge risk-severe">≥ 0.75 Severe</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}
