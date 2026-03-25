import { useState, useEffect, useCallback } from 'react';
import { fetchBasins, fetchScenarios, fetchResults, fetchScenarioMatrix } from './api';
import Dashboard from './components/Dashboard';
import FloodMap from './components/FloodMap';
import ScenarioSelector from './components/ScenarioSelector';
import BasinComparison from './components/BasinComparison';
import SensitivityPanel from './components/SensitivityPanel';
import ScenarioMatrix from './components/ScenarioMatrix';
import ResultsPanel from './components/ResultsPanel';
import './index.css';

const TABS = [
    { key: 'dashboard', label: 'Dashboard', icon: '🌊' },
    { key: 'map', label: 'Flood Map', icon: '🗺️' },
    { key: 'scenario', label: 'Scenario Selector', icon: '⚡' },
    { key: 'comparison', label: 'Basin Comparison', icon: '⚖️' },
    { key: 'sensitivity', label: 'Sensitivity', icon: '📊' },
    { key: 'matrix', label: 'Scenario Matrix', icon: '📋' },
    { key: 'results', label: 'Results', icon: '🔬' },
];

export default function App() {
    const [activeTab, setActiveTab] = useState('dashboard');
    const [basins, setBasins] = useState([]);
    const [scenarios, setScenarios] = useState([]);
    const [results, setResults] = useState([]);
    const [matrix, setMatrix] = useState([]);
    const [loading, setLoading] = useState(true);

    const loadAll = useCallback(async () => {
        try {
            const [b, s, res, m] = await Promise.all([
                fetchBasins(),
                fetchScenarios(),
                fetchResults(),
                fetchScenarioMatrix(),
            ]);
            setBasins(b);
            setScenarios(s);
            setResults(res);
            setMatrix(m);
        } catch (err) {
            console.error('Failed to load data:', err);
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => { loadAll(); }, [loadAll]);

    const handleDataChange = useCallback(() => { loadAll(); }, [loadAll]);

    return (
        <>
            <header className="header">
                <div className="header-content">
                    <div className="logo">
                        <span className="logo-icon">🌊</span>
                        <div>
                            <h1>Flood Susceptibility Modeling</h1>
                            <p className="subtitle">Deterministic modeling of urban sub-basins under varying precipitation scenarios</p>
                        </div>
                    </div>
                    <div className="header-badges">
                        <div className="header-badge">
                            <span className="badge-dot"></span>
                            Haskell + SQLite
                        </div>
                        <div className="header-badge" style={{ borderColor: 'rgba(20,184,166,0.2)', color: '#14b8a6', background: 'rgba(20,184,166,0.08)' }}>
                            React.js
                        </div>
                    </div>
                </div>
            </header>

            <main className="container">
                <nav className="tab-nav">
                    {TABS.map((tab) => (
                        <button
                            key={tab.key}
                            className={`tab-btn ${activeTab === tab.key ? 'active' : ''}`}
                            onClick={() => setActiveTab(tab.key)}
                        >
                            <span className="tab-icon">{tab.icon}</span>
                            {tab.label}
                        </button>
                    ))}
                </nav>

                {loading ? (
                    <div className="loading-spinner">
                        <div className="spinner"></div>
                    </div>
                ) : (
                    <>
                        {activeTab === 'dashboard' && (
                            <Dashboard basins={basins} scenarios={scenarios} results={results} matrix={matrix} />
                        )}
                        {activeTab === 'map' && (
                            <FloodMap matrix={matrix} />
                        )}
                        {activeTab === 'scenario' && (
                            <ScenarioSelector basins={basins} scenarios={scenarios} onDataChange={handleDataChange} />
                        )}
                        {activeTab === 'comparison' && (
                            <BasinComparison basins={basins} scenarios={scenarios} matrix={matrix} />
                        )}
                        {activeTab === 'sensitivity' && (
                            <SensitivityPanel basins={basins} scenarios={scenarios} />
                        )}
                        {activeTab === 'matrix' && (
                            <ScenarioMatrix basins={basins} scenarios={scenarios} matrix={matrix} />
                        )}
                        {activeTab === 'results' && (
                            <ResultsPanel results={results} basins={basins} onRefresh={() => fetchResults().then(setResults)} />
                        )}
                    </>
                )}
            </main>

            <footer className="footer">
                <p>Flood Susceptibility Modeling System &bull; <span>Haskell + SQLite + Scotty</span> &bull; React.js Frontend &bull; Rational Method (Q=CiA) &bull; MIT License</p>
            </footer>
        </>
    );
}
