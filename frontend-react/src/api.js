// ============================================================
// Centralized API client for Flood Susceptibility Modeling
// ============================================================

const API_BASE = '';

export async function fetchBasins() {
    const res = await fetch(`${API_BASE}/api/basins`);
    return res.json();
}

export async function fetchRainfall() {
    const res = await fetch(`${API_BASE}/api/rainfall`);
    return res.json();
}

export async function fetchResults() {
    const res = await fetch(`${API_BASE}/api/results`);
    return res.json();
}

export async function uploadRainfall(data) {
    const res = await fetch(`${API_BASE}/api/upload-rainfall`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
    });
    return res.json();
}

export async function calculateRisk(data) {
    const res = await fetch(`${API_BASE}/api/calculate-risk`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
    });
    return res.json();
}
