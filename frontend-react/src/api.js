// ============================================================
// Centralized API client for Flood Susceptibility Modeling
// ============================================================

const API_BASE = import.meta.env.VITE_API_BASE_URL || '';

export async function fetchBasins() {
    const res = await fetch(`${API_BASE}/api/basins`);
    return res.json();
}

export async function fetchScenarios() {
    const res = await fetch(`${API_BASE}/api/scenarios`);
    return res.json();
}

export async function fetchResults() {
    const res = await fetch(`${API_BASE}/api/results`);
    return res.json();
}

export async function classifyRisk(data) {
    const res = await fetch(`${API_BASE}/api/classify`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
    });
    return res.json();
}

export async function classifyAll(data) {
    const res = await fetch(`${API_BASE}/api/classify-all`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
    });
    return res.json();
}

export async function fetchScenarioMatrix() {
    const res = await fetch(`${API_BASE}/api/scenario-matrix`);
    return res.json();
}

export async function fetchBasinCoordinates() {
    const res = await fetch(`${API_BASE}/api/basin-coordinates`);
    return res.json();
}
