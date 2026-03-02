// ============================================================
// Flood Susceptibility Modeling – Frontend Application
// Vanilla JavaScript with Fetch API
// ============================================================

const API_BASE = '';  // Same origin

// ============================================================
// Data storage
// ============================================================
let basinsData = [];
let rainfallData = [];

// ============================================================
// On page load
// ============================================================
document.addEventListener('DOMContentLoaded', () => {
    loadBasins();
    loadRainfall();
    loadResults();
});

// ============================================================
// Load Basins
// ============================================================
async function loadBasins() {
    try {
        const res = await fetch(`${API_BASE}/api/basins`);
        basinsData = await res.json();

        const tbody = document.getElementById('basins-tbody');
        document.getElementById('stat-basins').textContent = basinsData.length;

        if (basinsData.length === 0) {
            tbody.innerHTML = '<tr><td colspan="4" class="empty-state">No basins found.</td></tr>';
            return;
        }

        tbody.innerHTML = basinsData.map(b => `
            <tr>
                <td><strong>${escapeHtml(b.basinName)}</strong></td>
                <td>${b.elevation.toFixed(1)}</td>
                <td>${b.slope.toFixed(1)}</td>
                <td>${b.area.toFixed(1)}</td>
            </tr>
        `).join('');

        // Populate basin select dropdowns
        populateBasinSelects(basinsData);
    } catch (err) {
        console.error('Error loading basins:', err);
    }
}

// ============================================================
// Load Rainfall Scenarios
// ============================================================
async function loadRainfall() {
    try {
        const res = await fetch(`${API_BASE}/api/rainfall`);
        rainfallData = await res.json();

        const tbody = document.getElementById('rainfall-tbody');
        document.getElementById('stat-scenarios').textContent = rainfallData.length;

        if (rainfallData.length === 0) {
            tbody.innerHTML = '<tr><td colspan="5" class="empty-state">No rainfall data found.</td></tr>';
            return;
        }

        tbody.innerHTML = rainfallData.map(r => `
            <tr>
                <td>${r.scenarioId}</td>
                <td>${r.rsBasinId}</td>
                <td>${escapeHtml(r.scenarioName)}</td>
                <td>${r.intensityMm.toFixed(1)}</td>
                <td>${r.durationHours.toFixed(1)}</td>
            </tr>
        `).join('');

        // Populate rainfall select dropdown
        populateRainfallSelect(rainfallData);
    } catch (err) {
        console.error('Error loading rainfall:', err);
    }
}

// ============================================================
// Load Results
// ============================================================
async function loadResults() {
    try {
        const res = await fetch(`${API_BASE}/api/results`);
        const results = await res.json();

        const tbody = document.getElementById('results-tbody');
        document.getElementById('stat-results').textContent = results.length;

        if (results.length === 0) {
            tbody.innerHTML = '<tr><td colspan="5" class="empty-state">No results yet. Calculate flood risk to see results here.</td></tr>';
            return;
        }

        tbody.innerHTML = results.map(r => `
            <tr>
                <td>${r.resultId}</td>
                <td>${r.frBasinId}</td>
                <td>${r.frRainfallId}</td>
                <td><span class="risk-badge ${riskClass(r.riskLevel)}">${escapeHtml(r.riskLevel)}</span></td>
                <td>${escapeHtml(r.calculatedAt)}</td>
            </tr>
        `).join('');
    } catch (err) {
        console.error('Error loading results:', err);
    }
}

// ============================================================
// Upload Rainfall
// ============================================================
async function uploadRainfall(event) {
    event.preventDefault();

    const statusEl = document.getElementById('upload-status');
    statusEl.classList.remove('hidden', 'status-success', 'status-error');

    const body = {
        urBasinId: parseInt(document.getElementById('upload-basin-id').value),
        urScenarioName: document.getElementById('upload-scenario').value,
        urIntensityMm: parseFloat(document.getElementById('upload-intensity').value),
        urDurationHours: parseFloat(document.getElementById('upload-duration').value)
    };

    try {
        const res = await fetch(`${API_BASE}/api/upload-rainfall`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(body)
        });

        const data = await res.json();

        if (data.status === 'success') {
            statusEl.classList.add('status-success');
            statusEl.textContent = '✅ ' + data.message;
            document.getElementById('upload-form').reset();
            loadRainfall();
        } else {
            statusEl.classList.add('status-error');
            statusEl.textContent = '❌ ' + (data.message || 'Upload failed');
        }
    } catch (err) {
        statusEl.classList.add('status-error');
        statusEl.textContent = '❌ Network error: ' + err.message;
    }
}

// ============================================================
// Calculate Flood Risk
// ============================================================
async function calculateRisk(event) {
    event.preventDefault();

    const resultEl = document.getElementById('calc-result');
    resultEl.classList.remove('hidden');
    resultEl.innerHTML = '<p style="color: var(--text-muted);">Calculating...</p>';

    const body = {
        crBasinId: parseInt(document.getElementById('calc-basin-id').value),
        crRainfallId: parseInt(document.getElementById('calc-rainfall-id').value)
    };

    try {
        const res = await fetch(`${API_BASE}/api/calculate-risk`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(body)
        });

        const data = await res.json();

        if (data.status === 'success') {
            resultEl.innerHTML = `
                <h4>Risk Assessment Result</h4>
                <div class="result-risk">
                    <span class="risk-badge ${riskClass(data.riskLevel)}" style="font-size: 1rem; padding: 0.4rem 1rem;">
                        ${escapeHtml(data.riskLevel)}
                    </span>
                </div>
                <div class="result-details">
                    <strong>Basin:</strong> ${escapeHtml(data.basinName)}<br>
                    <strong>Scenario:</strong> ${escapeHtml(data.scenario)}<br>
                    <strong>Rainfall:</strong> ${data.rainfall_mm} mm/hr<br>
                    <strong>Elevation:</strong> ${data.elevation_m} m<br>
                    <strong>Slope:</strong> ${data.slope_pct}%<br>
                    <strong>Description:</strong> ${escapeHtml(data.description)}<br>
                    <strong>Calculated:</strong> ${escapeHtml(data.calculatedAt)}
                </div>
            `;
            loadResults();
        } else {
            resultEl.innerHTML = `<p style="color: var(--risk-severe);">❌ ${escapeHtml(data.message)}</p>`;
        }
    } catch (err) {
        resultEl.innerHTML = `<p style="color: var(--risk-severe);">❌ Network error: ${escapeHtml(err.message)}</p>`;
    }
}

// ============================================================
// Helpers
// ============================================================

function riskClass(level) {
    switch (level) {
        case 'Low':      return 'risk-low';
        case 'Moderate': return 'risk-moderate';
        case 'High':     return 'risk-high';
        case 'Severe':   return 'risk-severe';
        default:         return '';
    }
}

function escapeHtml(text) {
    if (!text) return '';
    const str = String(text);
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
}

function populateBasinSelects(basins) {
    const selects = [
        document.getElementById('upload-basin-id'),
        document.getElementById('calc-basin-id')
    ];

    selects.forEach(select => {
        // Keep the first placeholder option
        const placeholder = select.querySelector('option:first-child');
        select.innerHTML = '';
        select.appendChild(placeholder);

        basins.forEach(b => {
            const opt = document.createElement('option');
            opt.value = b.basinId;
            opt.textContent = `${b.basinId} – ${b.basinName}`;
            select.appendChild(opt);
        });
    });
}

function populateRainfallSelect(rainfall) {
    const select = document.getElementById('calc-rainfall-id');
    const placeholder = select.querySelector('option:first-child');
    select.innerHTML = '';
    select.appendChild(placeholder);

    rainfall.forEach(r => {
        const opt = document.createElement('option');
        opt.value = r.scenarioId;
        opt.textContent = `${r.scenarioId} – ${r.scenarioName} (${r.intensityMm} mm/hr)`;
        select.appendChild(opt);
    });
}
