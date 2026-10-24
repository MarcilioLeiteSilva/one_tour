import React, { useState } from 'react';
import { Layers, Calendar, RefreshCw, ArrowUpRight } from 'lucide-react';
import { AdPerformanceItem } from '../types';

interface AdsTabProps {
  items: AdPerformanceItem[];
  days?: number;
  onDaysChange?: (days: number) => void;
  onRefresh: () => void;
  isLoading: boolean;
  selectedUf?: string;
}

export const AdsTab: React.FC<AdsTabProps> = ({
  items,
  days = 30,
  onDaysChange = () => {},
  onRefresh,
  isLoading,
}) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedPos, setSelectedPos] = useState<string>('all');

  const filtered = items.filter((ad) => {
    if (selectedPos !== 'all' && ad.position !== selectedPos) return false;
    if (searchTerm && !ad.ad_id.toLowerCase().includes(searchTerm.toLowerCase())) return false;
    return true;
  });

  const totalImpressions = items.reduce((acc, curr) => acc + curr.impressions, 0);
  const totalClicks = items.reduce((acc, curr) => acc + curr.clicks, 0);
  const averageCtr = totalImpressions > 0 ? ((totalClicks / totalImpressions) * 100).toFixed(2) : '0.00';

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
      {/* Header controls */}
      <div
        className="glass-panel"
        style={{
          padding: 20,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          flexWrap: 'wrap',
          gap: 16,
        }}
      >
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <Layers size={20} color="var(--primary)" />
            <h1 style={{ fontSize: '1.35rem', fontWeight: 800 }}>Rede House Ads • Desempenho & CTR</h1>
          </div>
          <p style={{ fontSize: '0.8rem', color: 'var(--text-muted)', marginTop: 2 }}>
            Métricas de engajamento dos patrocinadores locais e campanhas de cross-promotion entre estados.
          </p>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          {/* Days selector */}
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: 6,
              background: 'rgba(255, 255, 255, 0.05)',
              padding: '6px 12px',
              borderRadius: 'var(--radius-sm)',
              border: '1px solid var(--border-subtle)',
            }}
          >
            <Calendar size={14} color="var(--text-muted)" />
            <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Período:</span>
            <select
              value={days}
              onChange={(e) => onDaysChange(Number(e.target.value))}
              style={{
                background: 'transparent',
                border: 'none',
                color: 'var(--text-main)',
                fontWeight: 600,
                fontSize: '0.825rem',
                cursor: 'pointer',
                outline: 'none',
              }}
            >
              <option value={7} style={{ background: '#0f172a' }}>Últimos 7 dias</option>
              <option value={15} style={{ background: '#0f172a' }}>Últimos 15 dias</option>
              <option value={30} style={{ background: '#0f172a' }}>Últimos 30 dias</option>
              <option value={90} style={{ background: '#0f172a' }}>Últimos 90 dias</option>
            </select>
          </div>

          <button onClick={onRefresh} className="btn btn-primary" disabled={isLoading}>
            <RefreshCw size={14} className={isLoading ? 'spin' : ''} />
            <span>Atualizar</span>
          </button>
        </div>
      </div>

      {/* KPI Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: 16 }}>
        <div className="glass-panel" style={{ padding: 18 }}>
          <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', fontWeight: 600 }}>Total de Campanhas Ativas</div>
          <div style={{ fontSize: '1.75rem', fontWeight: 800, marginTop: 4 }}>{items.length}</div>
        </div>
        <div className="glass-panel" style={{ padding: 18 }}>
          <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', fontWeight: 600 }}>Total de Impressões ({days}d)</div>
          <div style={{ fontSize: '1.75rem', fontWeight: 800, marginTop: 4, color: '#818cf8' }}>
            {totalImpressions.toLocaleString('pt-BR')}
          </div>
        </div>
        <div className="glass-panel" style={{ padding: 18 }}>
          <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', fontWeight: 600 }}>Total de Cliques ({days}d)</div>
          <div style={{ fontSize: '1.75rem', fontWeight: 800, marginTop: 4, color: 'var(--accent-cyan)' }}>
            {totalClicks.toLocaleString('pt-BR')}
          </div>
        </div>
        <div className="glass-panel" style={{ padding: 18 }}>
          <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', fontWeight: 600 }}>Taxa Média de Clique (CTR)</div>
          <div style={{ fontSize: '1.75rem', fontWeight: 800, marginTop: 4, color: '#34d399' }}>
            {averageCtr}%
          </div>
        </div>
      </div>

      {/* Table & Filters */}
      <div className="glass-panel" style={{ padding: 20 }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 16, flexWrap: 'wrap', gap: 12 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <input
              type="text"
              placeholder="Buscar por ID de anúncio..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="input-control"
              style={{ width: 260 }}
            />
            <select
              value={selectedPos}
              onChange={(e) => setSelectedPos(e.target.value)}
              className="input-control"
              style={{ width: 180 }}
            >
              <option value="all">Todas as posições</option>
              <option value="home_card">Card da Home</option>
              <option value="attraction_banner">Banner de Atração</option>
              <option value="interstitial">Intersticial Suave</option>
            </select>
          </div>

          <div style={{ fontSize: '0.8rem', color: 'var(--text-dim)' }}>
            Exibindo {filtered.length} de {items.length} anúncios
          </div>
        </div>

        {filtered.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '40px 16px', color: 'var(--text-muted)' }}>
            Nenhum anúncio encontrado com os filtros selecionados.
          </div>
        ) : (
          <div className="table-container">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Campanha / Ad ID</th>
                  <th>UF</th>
                  <th>Posição no App</th>
                  <th>Impressões</th>
                  <th>Cliques</th>
                  <th>CTR (%)</th>
                  <th>Conversão Visual</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map((ad) => {
                  const ctrBarWidth = Math.min(Math.max(ad.ctr * 15, 4), 100);
                  const isHighCtr = ad.ctr >= 3.0;
                  return (
                    <tr key={`${ad.ad_id}_${ad.position}`}>
                      <td>
                        <div style={{ fontWeight: 700, fontSize: '0.9rem' }}>{ad.ad_id}</div>
                      </td>
                      <td>
                        <span className="badge badge-primary">{ad.uf}</span>
                      </td>
                      <td>
                        <span className="badge badge-amber">{ad.position}</span>
                      </td>
                      <td style={{ fontWeight: 600 }}>{ad.impressions.toLocaleString()}</td>
                      <td style={{ fontWeight: 600 }}>{ad.clicks.toLocaleString()}</td>
                      <td>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                          <span style={{ fontWeight: 800, color: isHighCtr ? '#34d399' : 'inherit' }}>
                            {ad.ctr.toFixed(2)}%
                          </span>
                          {isHighCtr && <ArrowUpRight size={14} color="#34d399" />}
                        </div>
                      </td>
                      <td style={{ minWidth: 140 }}>
                        <div
                          style={{
                            width: '100%',
                            height: 6,
                            borderRadius: 3,
                            background: 'rgba(255, 255, 255, 0.08)',
                            overflow: 'hidden',
                          }}
                        >
                          <div
                            style={{
                              width: `${ctrBarWidth}%`,
                              height: '100%',
                              borderRadius: 3,
                              background: isHighCtr
                                ? 'linear-gradient(90deg, #10b981, #06b6d4)'
                                : 'linear-gradient(90deg, #6366f1, #8b5cf6)',
                            }}
                          />
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
};
