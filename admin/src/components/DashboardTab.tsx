import {
  Smartphone,
  Users,
  Heart,
  Star,
  Eye,
  MousePointerClick,
  TrendingUp,
  RefreshCw,
  MapPin,
  ExternalLink,
  Award,
  Layers,
} from 'lucide-react';
import { OverviewStats, AdPerformanceItem, PlaceStatsItem, PbCityItem } from '../types';
import { StatCard } from './StatCard';

interface DashboardTabProps {
  stats: OverviewStats | null;
  adItems: AdPerformanceItem[];
  placeStats: PlaceStatsItem[];
  cities: PbCityItem[];
  selectedUf: string;
  onRefresh: () => void;
  onRecalculateRankings: () => void;
  isRecalculating: boolean;
  onGoToTab: (tab: string) => void;
}

export const DashboardTab: React.FC<DashboardTabProps> = ({
  stats,
  adItems,
  placeStats,
  cities,
  selectedUf,
  onRefresh,
  onRecalculateRankings,
  isRecalculating,
  onGoToTab,
}) => {
  const totalImpressions = stats?.impressions_30d || 0;
  const totalClicks = stats?.clicks_30d || 0;
  const overallCtr = totalImpressions > 0 ? ((totalClicks / totalImpressions) * 100).toFixed(2) : '0.00';
  const topPlace = placeStats.find((p) => p.rank_state === 1) || placeStats[0];

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
      {/* Hero Welcome Banner */}
      <div
        className="glass-panel"
        style={{
          padding: '24px 28px',
          background: 'linear-gradient(135deg, rgba(99, 102, 241, 0.15) 0%, rgba(139, 92, 246, 0.08) 50%, rgba(15, 23, 42, 0.6) 100%)',
          border: '1px solid rgba(99, 102, 241, 0.25)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          flexWrap: 'wrap',
          gap: 16,
        }}
      >
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 6 }}>
            <span className="badge badge-primary">CENTRAL DE OPERAÇÕES • {selectedUf}</span>
            <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>
              Ecossistema Multi-Flavor One Tour
            </span>
          </div>
          <h1 style={{ fontSize: '1.65rem', fontWeight: 800, letterSpacing: '-0.02em' }}>
            Visão Geral e Telemetria em Tempo Real
          </h1>
          <p style={{ fontSize: '0.875rem', color: 'var(--text-muted)', marginTop: 4 }}>
            Monitoramento de engajamento comunitário, rede de publicidade nativa e sincronização offline-first.
          </p>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <button
            onClick={onRecalculateRankings}
            disabled={isRecalculating}
            className="btn btn-secondary"
            title="Recalcula scores bayesianos e posições de ranking no Postgres"
          >
            <RefreshCw size={15} className={isRecalculating ? 'spin' : ''} />
            <span>{isRecalculating ? 'Recalculando...' : 'Recalcular Rankings'}</span>
          </button>
          <button onClick={onRefresh} className="btn btn-primary">
            <RefreshCw size={15} />
            <span>Atualizar Métricas</span>
          </button>
        </div>
      </div>

      {/* Grid of Key Metrics */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
          gap: 16,
        }}
      >
        <StatCard
          title="Dispositivos Únicos"
          value={stats?.devices_total ?? '—'}
          subtitle="Identidades anônimas criadas"
          icon={<Smartphone size={18} color="var(--accent-cyan)" />}
          accentColor="var(--accent-cyan)"
          badge="Instalações"
          badgeColor="primary"
        />
        <StatCard
          title="Ativos (Últimos 7d)"
          value={stats?.devices_active_7d ?? '—'}
          subtitle="Acessos na última semana"
          icon={<Users size={18} color="#34d399" />}
          accentColor="#10b981"
          badge="Engajamento"
          badgeColor="green"
        />
        <StatCard
          title="Curtidas Comunitárias"
          value={stats?.likes_total ?? '—'}
          subtitle="Votos positivos em POIs"
          icon={<Heart size={18} color="#fb7185" />}
          accentColor="#f43f5e"
          badge="Social"
          badgeColor="rose"
        />
        <StatCard
          title="Avaliações (1-5★)"
          value={stats?.reviews_total ?? '—'}
          subtitle="Reviews de satisfação"
          icon={<Star size={18} color="#fbbf24" />}
          accentColor="#f59e0b"
          badge="Qualidade"
          badgeColor="amber"
        />
        <StatCard
          title="Impressões Ads (30d)"
          value={totalImpressions.toLocaleString('pt-BR')}
          subtitle="Exibições de banners e cards"
          icon={<Eye size={18} color="#818cf8" />}
          accentColor="var(--primary)"
        />
        <StatCard
          title="Cliques Ads (30d)"
          value={totalClicks.toLocaleString('pt-BR')}
          subtitle="Cliques direcionados"
          icon={<MousePointerClick size={18} color="#06b6d4" />}
          accentColor="var(--accent-cyan)"
        />
        <StatCard
          title="CTR Médio da Rede"
          value={`${overallCtr}%`}
          subtitle="Taxa média de conversão"
          icon={<TrendingUp size={18} color="#34d399" />}
          accentColor="#10b981"
          badge="Performance"
          badgeColor="green"
        />
        <StatCard
          title="Top Atração (#1)"
          value={topPlace ? topPlace.place_id : `${placeStats.length} POIs`}
          subtitle={topPlace ? `Score: ${Number(topPlace.score || 0).toFixed(2)} (${topPlace.city_slug})` : 'Aguardando cálculo'}
          icon={<Award size={18} color="var(--accent-amber)" />}
          accentColor="var(--accent-amber)"
          badge="Ranking"
          badgeColor="amber"
        />
      </div>

      {/* Two Column Section: Top Ads & Polos */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(400px, 1fr))', gap: 20 }}>
        {/* Top Ads Performance */}
        <div className="glass-panel" style={{ padding: 22 }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 16 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <Layers size={18} color="var(--primary)" />
              <h2 style={{ fontSize: '1rem', fontWeight: 700 }}>Campanhas House Ads em Destaque</h2>
            </div>
            <button
              onClick={() => onGoToTab('ads')}
              className="btn btn-secondary"
              style={{ fontSize: '0.75rem', padding: '4px 10px' }}
            >
              <span>Ver todas</span>
              <ExternalLink size={12} />
            </button>
          </div>

          {adItems.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '32px 16px', color: 'var(--text-muted)' }}>
              Nenhum evento de anúncio registrado ainda no PostgreSQL.
            </div>
          ) : (
            <div className="table-container">
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Anúncio ID</th>
                    <th>Posição</th>
                    <th>Impressões</th>
                    <th>Cliques</th>
                    <th>CTR</th>
                  </tr>
                </thead>
                <tbody>
                  {adItems.slice(0, 5).map((ad) => (
                    <tr key={`${ad.ad_id}_${ad.position}`}>
                      <td style={{ fontWeight: 600 }}>{ad.ad_id}</td>
                      <td>
                        <span className="badge badge-primary">{ad.position}</span>
                      </td>
                      <td>{ad.impressions.toLocaleString()}</td>
                      <td>{ad.clicks.toLocaleString()}</td>
                      <td style={{ fontWeight: 700, color: ad.ctr > 2.0 ? '#34d399' : '#f8fafc' }}>
                        {ad.ctr.toFixed(2)}%
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>

        {/* Polos / Cidades Cadastradas */}
        <div className="glass-panel" style={{ padding: 22 }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 16 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <MapPin size={18} color="var(--accent-cyan)" />
              <h2 style={{ fontSize: '1rem', fontWeight: 700 }}>
                Polos Turísticos Ativos ({cities.length})
              </h2>
            </div>
            <button
              onClick={() => onGoToTab('content')}
              className="btn btn-secondary"
              style={{ fontSize: '0.75rem', padding: '4px 10px' }}
            >
              <span>Gerenciar Cidades</span>
              <ExternalLink size={12} />
            </button>
          </div>

          {cities.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '32px 16px', color: 'var(--text-muted)' }}>
              Carregando cidades do PocketBase...
            </div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              {cities.map((city) => (
                <div
                  key={city.id}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    padding: '10px 14px',
                    borderRadius: 'var(--radius-sm)',
                    background: 'rgba(255, 255, 255, 0.03)',
                    border: '1px solid var(--border-subtle)',
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                    <div
                      style={{
                        width: 10,
                        height: 10,
                        borderRadius: '50%',
                        background: city.destaque ? 'var(--accent-amber)' : 'var(--accent-green)',
                      }}
                    />
                    <div>
                      <div style={{ fontWeight: 700, fontSize: '0.9rem' }}>{city.nome}</div>
                      <div style={{ fontSize: '0.75rem', color: 'var(--text-dim)' }}>
                        {city.tag || 'Destino Turístico'} • Pacote: {city.package_size || '10 MB'}
                      </div>
                    </div>
                  </div>
                  <span className="badge badge-primary">{city.estado_sigla}</span>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
