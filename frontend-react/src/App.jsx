import { useState, useEffect, useCallback } from 'react';
import { fetchBasins, fetchRainfall, fetchResults } from './api';
import Dashboard from './components/Dashboard';
import BasinsPanel from './components/BasinsPanel';
import RainfallPanel from './components/RainfallPanel';
import RiskCalculator from './components/RiskCalculator';
import ResultsPanel from './components/ResultsPanel';
import './index.css';

const TABS = [
    { key: 'dashboard', label: 'Dashboard', icon: '🏠' },
    { key: 'basins', label: 'Basins', icon: '🏘️' },
    { key: 'rainfall', label: 'Rainfall', icon: '🌧️' },
    { key: 'calculator', label: 'Risk Calculator', icon: '⚡' },
    { key: 'results', label: 'Results', icon: '📊' },
];

export default function App() {
    const [activeTab, setActiveTab] = useState('dashboard');
    const [basins, setBasins] = useState([]);
    const [rainfall, setRainfall] = useState([]);
    const [results, setResults] = useState([]);
    const [loading, setLoading] = useState(true);

    const loadAll = useCallback(async () => {
        try {
            const [b, r, res] = await Promise.all([
                fetchBasins(),
                fetchRainfall(),
                fetchResults(),
            ]);
            setBasins(b);
            setRainfall(r);
            setResults(res);
        } catch (err) {
            console.error('Failed to load data:', err);
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => { loadAll(); }, [loadAll]);

    const handleDataChange = useCallback(() => {
        loadAll();
    }, [loadAll]);

    return (
        <>
            {/* Header */}
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
                        <div className="header-badge" style={{ borderColor: 'rgba(139, 92, 246, 0.2)', color: '#8b5cf6', background: 'rgba(139, 92, 246, 0.08)' }}>
                            React.js
                        </div>
                    </div>
                </div>
            </header>

            <main className="container">
                {/* Tab Navigation */}
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

                {/* Loading state */}
                {loading ? (
                    <div className="loading-spinner">
                        <div className="spinner"></div>
                    </div>
                ) : (
                    <>
                        {activeTab === 'dashboard' && (
                            <Dashboard basins={basins} rainfall={rainfall} results={results} />
                        )}
                        {activeTab === 'basins' && (
                            <BasinsPanel basins={basins} onRefresh={() => fetchBasins().then(setBasins)} />
                        )}
                        {activeTab === 'rainfall' && (
                            <RainfallPanel rainfall={rainfall} onRefresh={() => fetchRainfall().then(setRainfall)} />
                        )}
                        {activeTab === 'calculator' && (
                            <RiskCalculator basins={basins} rainfall={rainfall} onDataChange={handleDataChange} />
                        )}
                        {activeTab === 'results' && (
                            <ResultsPanel results={results} basins={basins} onRefresh={() => fetchResults().then(setResults)} />
                        )}
                    </>
                )}
            </main>

            {/* Footer */}
            <footer className="footer">
                <p>Flood Susceptibility Modeling System &bull; <span>Haskell + SQLite + Scotty</span> &bull; React.js Frontend &bull; MIT License</p>
            </footer>
        </>
    );
}
