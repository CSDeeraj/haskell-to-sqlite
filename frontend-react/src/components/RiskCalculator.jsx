import { useState } from 'react';
import { uploadRainfall, calculateRisk } from '../api';

function riskClass(level) {
    switch (level) {
        case 'Low': return 'risk-low';
        case 'Moderate': return 'risk-moderate';
        case 'High': return 'risk-high';
        case 'Severe': return 'risk-severe';
        default: return '';
    }
}

export default function RiskCalculator({ basins, rainfall, onDataChange }) {
    // Upload state
    const [uploadBasinId, setUploadBasinId] = useState('');
    const [scenarioName, setScenarioName] = useState('');
    const [intensity, setIntensity] = useState('');
    const [duration, setDuration] = useState('');
    const [uploadStatus, setUploadStatus] = useState(null);

    // Calculate state
    const [calcBasinId, setCalcBasinId] = useState('');
    const [calcRainfallId, setCalcRainfallId] = useState('');
    const [calcResult, setCalcResult] = useState(null);
    const [isCalculating, setIsCalculating] = useState(false);

    async function handleUpload(e) {
        e.preventDefault();
        setUploadStatus(null);
        try {
            const data = await uploadRainfall({
                urBasinId: parseInt(uploadBasinId),
                urScenarioName: scenarioName,
                urIntensityMm: parseFloat(intensity),
                urDurationHours: parseFloat(duration),
            });
            if (data.status === 'success') {
                setUploadStatus({ type: 'success', msg: '✅ ' + data.message });
                setScenarioName('');
                setIntensity('');
                setDuration('');
                setUploadBasinId('');
                onDataChange();
            } else {
                setUploadStatus({ type: 'error', msg: '❌ ' + (data.message || 'Upload failed') });
            }
        } catch (err) {
            setUploadStatus({ type: 'error', msg: '❌ Network error: ' + err.message });
        }
    }

    async function handleCalculate(e) {
        e.preventDefault();
        setCalcResult(null);
        setIsCalculating(true);
        try {
            const data = await calculateRisk({
                crBasinId: parseInt(calcBasinId),
                crRainfallId: parseInt(calcRainfallId),
            });
            setIsCalculating(false);
            if (data.status === 'success') {
                setCalcResult({ type: 'success', data });
                onDataChange();
            } else {
                setCalcResult({ type: 'error', msg: data.message || 'Calculation failed' });
            }
        } catch (err) {
            setIsCalculating(false);
            setCalcResult({ type: 'error', msg: 'Network error: ' + err.message });
        }
    }

    return (
        <div className="tab-content">
            <div className="grid-2">
                {/* Upload Rainfall */}
                <div className="panel">
                    <div className="panel-header">
                        <h2>📤 Upload Rainfall Data</h2>
                    </div>
                    <div className="panel-body">
                        <form onSubmit={handleUpload}>
                            <div className="form-group">
                                <label htmlFor="upload-basin-id">Basin</label>
                                <select id="upload-basin-id" value={uploadBasinId} onChange={(e) => setUploadBasinId(e.target.value)} required>
                                    <option value="">Select a basin...</option>
                                    {basins.map((b) => (
                                        <option key={b.basinId} value={b.basinId}>{b.basinId} – {b.basinName}</option>
                                    ))}
                                </select>
                            </div>
                            <div className="form-group">
                                <label htmlFor="upload-scenario">Scenario Name</label>
                                <input id="upload-scenario" type="text" placeholder="e.g., Heavy Monsoon" value={scenarioName} onChange={(e) => setScenarioName(e.target.value)} required />
                            </div>
                            <div className="form-row">
                                <div className="form-group">
                                    <label htmlFor="upload-intensity">Intensity (mm/hr)</label>
                                    <input id="upload-intensity" type="number" step="0.1" min="0" placeholder="0.0" value={intensity} onChange={(e) => setIntensity(e.target.value)} required />
                                </div>
                                <div className="form-group">
                                    <label htmlFor="upload-duration">Duration (hrs)</label>
                                    <input id="upload-duration" type="number" step="0.1" min="0" placeholder="0.0" value={duration} onChange={(e) => setDuration(e.target.value)} required />
                                </div>
                            </div>
                            <button type="submit" className="btn btn-primary btn-full">Upload Scenario</button>
                        </form>
                        {uploadStatus && (
                            <div className={`status-message ${uploadStatus.type === 'success' ? 'status-success' : 'status-error'}`}>
                                {uploadStatus.msg}
                            </div>
                        )}
                    </div>
                </div>

                {/* Calculate Risk */}
                <div className="panel">
                    <div className="panel-header">
                        <h2>⚡ Calculate Flood Risk</h2>
                    </div>
                    <div className="panel-body">
                        <form onSubmit={handleCalculate}>
                            <div className="form-group">
                                <label htmlFor="calc-basin-id">Basin</label>
                                <select id="calc-basin-id" value={calcBasinId} onChange={(e) => setCalcBasinId(e.target.value)} required>
                                    <option value="">Select a basin...</option>
                                    {basins.map((b) => (
                                        <option key={b.basinId} value={b.basinId}>{b.basinId} – {b.basinName}</option>
                                    ))}
                                </select>
                            </div>
                            <div className="form-group">
                                <label htmlFor="calc-rainfall-id">Rainfall Scenario</label>
                                <select id="calc-rainfall-id" value={calcRainfallId} onChange={(e) => setCalcRainfallId(e.target.value)} required>
                                    <option value="">Select a scenario...</option>
                                    {rainfall.map((r) => (
                                        <option key={r.scenarioId} value={r.scenarioId}>{r.scenarioId} – {r.scenarioName} ({r.intensityMm} mm/hr)</option>
                                    ))}
                                </select>
                            </div>
                            <button type="submit" className="btn btn-accent btn-full" disabled={isCalculating}>
                                {isCalculating ? '⏳ Calculating...' : '⚡ Calculate Risk'}
                            </button>
                        </form>

                        {calcResult && calcResult.type === 'success' && (
                            <div className="result-card">
                                <h4>Risk Assessment Result</h4>
                                <div className="result-risk-display">
                                    <span className={`risk-badge ${riskClass(calcResult.data.riskLevel)}`} style={{ fontSize: '1.1rem', padding: '0.5rem 1.3rem' }}>
                                        {calcResult.data.riskLevel}
                                    </span>
                                </div>
                                <div className="result-details">
                                    <div className="detail-item"><strong>Basin:</strong> {calcResult.data.basinName}</div>
                                    <div className="detail-item"><strong>Scenario:</strong> {calcResult.data.scenario}</div>
                                    <div className="detail-item"><strong>Rainfall:</strong> {calcResult.data.rainfall_mm} mm/hr</div>
                                    <div className="detail-item"><strong>Elevation:</strong> {calcResult.data.elevation_m} m</div>
                                    <div className="detail-item"><strong>Slope:</strong> {calcResult.data.slope_pct}%</div>
                                    <div className="detail-item"><strong>Calculated:</strong> {calcResult.data.calculatedAt}</div>
                                </div>
                                <p style={{ marginTop: '0.8rem', fontSize: '0.82rem', color: 'var(--text-secondary)', fontStyle: 'italic' }}>
                                    {calcResult.data.description}
                                </p>
                            </div>
                        )}

                        {calcResult && calcResult.type === 'error' && (
                            <div className="status-message status-error" style={{ marginTop: '1rem' }}>
                                ❌ {calcResult.msg}
                            </div>
                        )}
                    </div>
                </div>
            </div>
        </div>
    );
}
