import React, { useState, useEffect } from 'react';
import {
  Layers,
  Calendar,
  RefreshCw,
  ArrowUpRight,
  Plus,
  Edit2,
  Trash2,
  Power,
  ExternalLink,
  Sliders,
  MapPin,
} from 'lucide-react';
import { AdPerformanceItem, HouseAdCampaign } from '../types';
import {
  fetchCampaigns,
  createCampaign,
  updateCampaign,
  toggleCampaignActive,
  deleteCampaign,
} from '../services/api';
import { CampaignModal } from './CampaignModal';

interface AdsTabProps {
  items: AdPerformanceItem[];
  days?: number;
  onDaysChange?: (days: number) => void;
  onRefresh: () => void;
  isLoading: boolean;
  selectedUf?: string;
  onNotify?: (message: string, type: 'success' | 'error') => void;
}

export const AdsTab: React.FC<AdsTabProps> = ({
  items,
  days = 30,
  onDaysChange = () => {},
  onRefresh,
  isLoading,
  selectedUf = 'PE',
  onNotify = () => {},
}) => {
  const [activeSubTab, setActiveSubTab] = useState<'manager' | 'analytics'>('manager');
  const [campaigns, setCampaigns] = useState<HouseAdCampaign[]>([]);
  const [loadingCampaigns, setLoadingCampaigns] = useState<boolean>(false);
  const [isModalOpen, setIsModalOpen] = useState<boolean>(false);
  const [campaignToEdit, setCampaignToEdit] = useState<HouseAdCampaign | null>(null);

  // Filters for Manager
  const [filterUf, setFilterUf] = useState<string>(selectedUf);
  const [filterPos, setFilterPos] = useState<string>('all');
  const [filterStatus, setFilterStatus] = useState<'all' | 'active' | 'paused'>('all');
  const [searchTerm, setSearchTerm] = useState<string>('');

  // Filters for Analytics
  const [analyticsSearchTerm, setAnalyticsSearchTerm] = useState<string>('');
  const [analyticsPos, setAnalyticsPos] = useState<string>('all');

  const loadCampaignsList = async () => {
    setLoadingCampaigns(true);
    try {
      const data = await fetchCampaigns(filterUf === 'ALL' ? undefined : filterUf, filterPos);
      setCampaigns(data);
    } catch (err: any) {
      console.warn('Erro ao carregar campanhas dinâmicas:', err.message);
    } finally {
      setLoadingCampaigns(false);
    }
  };

  useEffect(() => {
    loadCampaignsList();
  }, [filterUf, filterPos]);

  const handleSaveCampaign = async (campaignData: Partial<HouseAdCampaign>) => {
    if (campaignToEdit) {
      await updateCampaign(campaignToEdit.id, campaignData);
      onNotify('Campanha atualizada com sucesso!', 'success');
    } else {
      await createCampaign(campaignData);
      onNotify('Nova campanha criada e ativada na rede!', 'success');
    }
    await loadCampaignsList();
    onRefresh();
  };

  const handleToggleActive = async (campaign: HouseAdCampaign) => {
    try {
      await toggleCampaignActive(campaign.id, !campaign.active);
      onNotify(
        `Campanha ${campaign.active ? 'pausada' : 'ativada'} com sucesso!`,
        'success'
      );
      await loadCampaignsList();
    } catch (err: any) {
      onNotify(`Erro ao alterar status: ${err.message}`, 'error');
    }
  };

  const handleDelete = async (campaignId: string) => {
    if (!window.confirm('Tem certeza que deseja excluir esta campanha?')) return;
    try {
      await deleteCampaign(campaignId);
      onNotify('Campanha removida com sucesso.', 'success');
      await loadCampaignsList();
      onRefresh();
    } catch (err: any) {
      onNotify(`Erro ao excluir: ${err.message}`, 'error');
    }
  };

  // Filtered Campaigns
  const filteredCampaigns = campaigns.filter((c) => {
    if (filterStatus === 'active' && !c.active) return false;
    if (filterStatus === 'paused' && c.active) return false;
    if (
      searchTerm &&
      !c.title.toLowerCase().includes(searchTerm.toLowerCase()) &&
      !c.id.toLowerCase().includes(searchTerm.toLowerCase())
    ) {
      return false;
    }
    return true;
  });

  // Filtered Analytics
  const filteredAnalytics = items.filter((ad) => {
    if (analyticsPos !== 'all' && ad.position !== analyticsPos) return false;
    if (
      analyticsSearchTerm &&
      !ad.ad_id.toLowerCase().includes(analyticsSearchTerm.toLowerCase())
    ) {
      return false;
    }
    return true;
  });

  const totalImpressions = items.reduce((acc, curr) => acc + curr.impressions, 0);
  const totalClicks = items.reduce((acc, curr) => acc + curr.clicks, 0);
  const averageCtr =
    totalImpressions > 0 ? ((totalClicks / totalImpressions) * 100).toFixed(2) : '0.00';

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
      {/* Header controls & Sub-tab Switcher */}
      <div
        className="glass-panel"
        style={{
          padding: '16px 20px',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          flexWrap: 'wrap',
          gap: 16,
        }}
      >
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <Layers size={22} color="var(--primary)" />
            <h1 style={{ fontSize: '1.35rem', fontWeight: 800 }}>Rede House Ads • Command Center</h1>
          </div>
          <p style={{ fontSize: '0.8rem', color: 'var(--text-muted)', marginTop: 2 }}>
            Gestão de campanhas de patrocinadores locais, promoção cruzada e métricas de conversão.
          </p>
        </div>

        {/* View Switcher Tabs */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <div
            style={{
              display: 'flex',
              background: 'rgba(255, 255, 255, 0.05)',
              padding: 4,
              borderRadius: 'var(--radius-sm)',
              border: '1px solid var(--border-subtle)',
            }}
          >
            <button
              onClick={() => setActiveSubTab('manager')}
              style={{
                background: activeSubTab === 'manager' ? 'var(--primary)' : 'transparent',
                color: activeSubTab === 'manager' ? '#fff' : 'var(--text-muted)',
                border: 'none',
                padding: '6px 14px',
                borderRadius: 6,
                fontWeight: 700,
                fontSize: '0.8rem',
                cursor: 'pointer',
                transition: 'all 0.2s',
              }}
            >
              Gestão de Campanhas ({campaigns.length})
            </button>
            <button
              onClick={() => setActiveSubTab('analytics')}
              style={{
                background: activeSubTab === 'analytics' ? 'var(--primary)' : 'transparent',
                color: activeSubTab === 'analytics' ? '#fff' : 'var(--text-muted)',
                border: 'none',
                padding: '6px 14px',
                borderRadius: 6,
                fontWeight: 700,
                fontSize: '0.8rem',
                cursor: 'pointer',
                transition: 'all 0.2s',
              }}
            >
              Métricas & CTR ({days}d)
            </button>
          </div>

          <button
            onClick={() => {
              loadCampaignsList();
              onRefresh();
            }}
            className="btn btn-secondary"
            disabled={isLoading || loadingCampaigns}
          >
            <RefreshCw size={14} className={isLoading || loadingCampaigns ? 'spin' : ''} />
            <span>Atualizar</span>
          </button>
        </div>
      </div>

      {/* ==================================================================== */}
      {/* SUB-ABA 1: GESTÃO DE CAMPANHAS (CRUD)                                */}
      {/* ==================================================================== */}
      {activeSubTab === 'manager' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
          {/* Controls Bar */}
          <div
            className="glass-panel"
            style={{
              padding: 16,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              flexWrap: 'wrap',
              gap: 12,
            }}
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, flexWrap: 'wrap', flex: 1 }}>
              <input
                type="text"
                placeholder="Buscar por título ou ID..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="input-control"
                style={{ width: 220 }}
              />

              <select
                value={filterUf}
                onChange={(e) => setFilterUf(e.target.value)}
                className="input-control"
                style={{ width: 140 }}
              >
                <option value="PE">Pernambuco (PE)</option>
                <option value="AL">Alagoas (AL)</option>
                <option value="PB">Paraíba (PB)</option>
                <option value="RN">Rio G. Norte (RN)</option>
                <option value="CE">Ceará (CE)</option>
                <option value="BA">Bahia (BA)</option>
                <option value="SE">Sergipe (SE)</option>
                <option value="ALL">Todas as UFs</option>
              </select>

              <select
                value={filterPos}
                onChange={(e) => setFilterPos(e.target.value)}
                className="input-control"
                style={{ width: 160 }}
              >
                <option value="all">Todas as posições</option>
                <option value="home_card">Top Card da Cidade</option>
                <option value="attraction_banner">Banner In-Feed</option>
                <option value="itinerary_footer">Rodapé do Roteiro</option>
                <option value="interstitial">Intersticial Suave</option>
              </select>

              <select
                value={filterStatus}
                onChange={(e) => setFilterStatus(e.target.value as any)}
                className="input-control"
                style={{ width: 130 }}
              >
                <option value="all">Todos Status</option>
                <option value="active">🟢 Apenas Ativos</option>
                <option value="paused">⏸️ Apenas Pausados</option>
              </select>
            </div>

            <button
              onClick={() => {
                setCampaignToEdit(null);
                setIsModalOpen(true);
              }}
              className="btn btn-primary"
            >
              <Plus size={16} />
              <span>Nova Campanha</span>
            </button>
          </div>

          {/* Cards Grid */}
          {loadingCampaigns ? (
            <div className="glass-panel" style={{ padding: 40, textAlign: 'center', color: 'var(--text-muted)' }}>
              <RefreshCw size={24} className="spin" style={{ margin: '0 auto 12px' }} />
              <div>Carregando catálogo de campanhas...</div>
            </div>
          ) : filteredCampaigns.length === 0 ? (
            <div className="glass-panel" style={{ padding: 48, textAlign: 'center', color: 'var(--text-muted)' }}>
              <Layers size={36} color="var(--text-dim)" style={{ margin: '0 auto 12px' }} />
              <div style={{ fontSize: '1rem', fontWeight: 700, color: 'var(--text-main)' }}>
                Nenhuma campanha encontrada
              </div>
              <p style={{ fontSize: '0.825rem', marginTop: 4 }}>
                Crie um novo anúncio para começar a monetizar no app {filterUf !== 'ALL' ? filterUf : ''}.
              </p>
              <button
                onClick={() => {
                  setCampaignToEdit(null);
                  setIsModalOpen(true);
                }}
                className="btn btn-primary"
                style={{ marginTop: 16 }}
              >
                <Plus size={16} />
                <span>Criar Primeira Campanha</span>
              </button>
            </div>
          ) : (
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(340px, 1fr))', gap: 16 }}>
              {filteredCampaigns.map((ad) => {
                const isCrossPromo = ad.type === 'cross_promotion';
                return (
                  <div
                    key={ad.id}
                    className="glass-panel"
                    style={{
                      display: 'flex',
                      flexDirection: 'column',
                      borderRadius: 'var(--radius-md)',
                      overflow: 'hidden',
                      border: ad.active
                        ? isCrossPromo
                          ? '1px solid rgba(99, 102, 241, 0.4)'
                          : '1px solid rgba(245, 158, 11, 0.4)'
                        : '1px solid rgba(255, 255, 255, 0.08)',
                      opacity: ad.active ? 1 : 0.65,
                    }}
                  >
                    {/* Thumbnail & Badges */}
                    <div style={{ position: 'relative', height: 140, background: '#1e293b' }}>
                      <img
                        src={ad.image_url}
                        alt={ad.title}
                        style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                        onError={(e) => {
                          (e.target as any).src =
                            'https://placehold.co/600x300/1e293b/white?text=Foto+do+Anuncio';
                        }}
                      />
                      <div
                        style={{
                          position: 'absolute',
                          top: 10,
                          left: 10,
                          display: 'flex',
                          gap: 6,
                          flexWrap: 'wrap',
                        }}
                      >
                        <span className={isCrossPromo ? 'badge badge-primary' : 'badge badge-amber'}>
                          {ad.tag || (isCrossPromo ? 'REDE ONE TOUR' : 'PATROCINADOR')}
                        </span>
                        <span className="badge badge-green">UF: {ad.target_uf}</span>
                      </div>

                      <div style={{ position: 'absolute', top: 10, right: 10 }}>
                        <span
                          style={{
                            background: ad.active ? 'rgba(16, 185, 129, 0.9)' : 'rgba(239, 68, 68, 0.9)',
                            color: '#fff',
                            fontSize: '0.7rem',
                            fontWeight: 800,
                            padding: '3px 8px',
                            borderRadius: 'var(--radius-full)',
                          }}
                        >
                          {ad.active ? '● ATIVO' : 'PAUSADO'}
                        </span>
                      </div>

                      <div
                        style={{
                          position: 'absolute',
                          bottom: 8,
                          right: 10,
                          background: 'rgba(0, 0, 0, 0.75)',
                          backdropFilter: 'blur(4px)',
                          padding: '2px 8px',
                          borderRadius: 4,
                          fontSize: '0.7rem',
                          color: '#fff',
                          fontWeight: 700,
                        }}
                      >
                        Posição: {ad.position}
                      </div>
                    </div>

                    {/* Content */}
                    <div style={{ padding: 16, display: 'flex', flexDirection: 'column', flex: 1, gap: 10 }}>
                      <div>
                        <div style={{ fontSize: '0.7rem', color: 'var(--text-dim)', fontWeight: 600 }}>
                          ID: {ad.id}
                        </div>
                        <h3 style={{ fontSize: '1rem', fontWeight: 800, marginTop: 2, lineHeight: 1.3 }}>
                          {ad.title}
                        </h3>
                        {ad.subtitle && (
                          <p
                            style={{
                              fontSize: '0.8rem',
                              color: 'var(--text-muted)',
                              marginTop: 4,
                              display: '-webkit-box',
                              WebkitLineClamp: 2,
                              WebkitBoxOrient: 'vertical',
                              overflow: 'hidden',
                            }}
                          >
                            {ad.subtitle}
                          </p>
                        )}
                      </div>

                      {/* Cities & Alternation Weight */}
                      <div
                        style={{
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'space-between',
                          fontSize: '0.75rem',
                          color: 'var(--text-muted)',
                          padding: '8px 10px',
                          background: 'rgba(255, 255, 255, 0.03)',
                          borderRadius: 'var(--radius-sm)',
                        }}
                      >
                        <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                          <MapPin size={13} color="var(--primary)" />
                          <span>
                            {ad.target_cities && ad.target_cities.length > 0
                              ? ad.target_cities.join(', ')
                              : 'Todo o Estado'}
                          </span>
                        </div>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                          <Sliders size={13} color="#f59e0b" />
                          <span style={{ fontWeight: 700, color: 'var(--text-main)' }}>
                            Peso: {ad.priority}
                          </span>
                        </div>
                      </div>

                      {/* CTA & Target Link */}
                      <div
                        style={{
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'space-between',
                          gap: 8,
                          fontSize: '0.75rem',
                        }}
                      >
                        <span style={{ color: 'var(--text-muted)', fontWeight: 600 }}>
                          Botão: <strong style={{ color: 'var(--text-main)' }}>{ad.action_label}</strong>
                        </span>
                        <a
                          href={ad.target_url}
                          target="_blank"
                          rel="noopener noreferrer"
                          style={{
                            color: 'var(--accent-cyan)',
                            textDecoration: 'none',
                            display: 'flex',
                            alignItems: 'center',
                            gap: 4,
                            fontWeight: 700,
                          }}
                        >
                          <span>Ver Destino</span>
                          <ExternalLink size={12} />
                        </a>
                      </div>

                      <div style={{ flex: 1 }} />

                      {/* Action buttons footer */}
                      <div
                        style={{
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'space-between',
                          paddingTop: 12,
                          borderTop: '1px solid var(--border-subtle)',
                        }}
                      >
                        <button
                          onClick={() => handleToggleActive(ad)}
                          className={`btn ${ad.active ? 'btn-secondary' : 'btn-success'}`}
                          style={{ padding: '6px 12px', fontSize: '0.75rem' }}
                        >
                          <Power size={13} />
                          <span>{ad.active ? 'Pausar' : 'Ativar'}</span>
                        </button>

                        <div style={{ display: 'flex', gap: 6 }}>
                          <button
                            onClick={() => {
                              setCampaignToEdit(ad);
                              setIsModalOpen(true);
                            }}
                            className="btn btn-secondary"
                            style={{ padding: '6px 10px', fontSize: '0.75rem' }}
                            title="Editar Campanha"
                          >
                            <Edit2 size={13} />
                          </button>
                          <button
                            onClick={() => handleDelete(ad.id)}
                            className="btn btn-danger"
                            style={{ padding: '6px 10px', fontSize: '0.75rem' }}
                            title="Excluir Campanha"
                          >
                            <Trash2 size={13} />
                          </button>
                        </div>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      )}

      {/* ==================================================================== */}
      {/* SUB-ABA 2: MÉTRICAS & RELATÓRIO DE CTR                               */}
      {/* ==================================================================== */}
      {activeSubTab === 'analytics' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
          {/* Days selector bar */}
          <div
            className="glass-panel"
            style={{
              padding: 16,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              flexWrap: 'wrap',
              gap: 12,
            }}
          >
            <div style={{ fontSize: '0.85rem', fontWeight: 700 }}>
              Relatório de Telemetria de Anúncios Gravado no PostgreSQL
            </div>

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
          </div>

          {/* KPI Cards */}
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: 16 }}>
            <div className="glass-panel" style={{ padding: 18 }}>
              <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', fontWeight: 600 }}>
                Total de Campanhas Ativas
              </div>
              <div style={{ fontSize: '1.75rem', fontWeight: 800, marginTop: 4 }}>
                {campaigns.filter((c) => c.active).length}
              </div>
            </div>
            <div className="glass-panel" style={{ padding: 18 }}>
              <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', fontWeight: 600 }}>
                Total de Impressões ({days}d)
              </div>
              <div style={{ fontSize: '1.75rem', fontWeight: 800, marginTop: 4, color: '#818cf8' }}>
                {totalImpressions.toLocaleString('pt-BR')}
              </div>
            </div>
            <div className="glass-panel" style={{ padding: 18 }}>
              <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', fontWeight: 600 }}>
                Total de Cliques ({days}d)
              </div>
              <div style={{ fontSize: '1.75rem', fontWeight: 800, marginTop: 4, color: 'var(--accent-cyan)' }}>
                {totalClicks.toLocaleString('pt-BR')}
              </div>
            </div>
            <div className="glass-panel" style={{ padding: 18 }}>
              <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', fontWeight: 600 }}>
                Taxa Média de Clique (CTR)
              </div>
              <div style={{ fontSize: '1.75rem', fontWeight: 800, marginTop: 4, color: '#34d399' }}>
                {averageCtr}%
              </div>
            </div>
          </div>

          {/* Table & Filters */}
          <div className="glass-panel" style={{ padding: 20 }}>
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                marginBottom: 16,
                flexWrap: 'wrap',
                gap: 12,
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                <input
                  type="text"
                  placeholder="Buscar por ID de anúncio..."
                  value={analyticsSearchTerm}
                  onChange={(e) => setAnalyticsSearchTerm(e.target.value)}
                  className="input-control"
                  style={{ width: 260 }}
                />
                <select
                  value={analyticsPos}
                  onChange={(e) => setAnalyticsPos(e.target.value)}
                  className="input-control"
                  style={{ width: 180 }}
                >
                  <option value="all">Todas as posições</option>
                  <option value="home_card">Card da Home</option>
                  <option value="attraction_banner">Banner de Atração</option>
                  <option value="itinerary_footer">Rodapé do Roteiro</option>
                  <option value="interstitial">Intersticial Suave</option>
                </select>
              </div>

              <div style={{ fontSize: '0.8rem', color: 'var(--text-dim)' }}>
                Exibindo {filteredAnalytics.length} de {items.length} anúncios
              </div>
            </div>

            {filteredAnalytics.length === 0 ? (
              <div style={{ textAlign: 'center', padding: '40px 16px', color: 'var(--text-muted)' }}>
                Nenhum dado analítico encontrado para o período selecionado.
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
                    {filteredAnalytics.map((ad) => {
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
                              <span
                                style={{
                                  fontWeight: 800,
                                  color: isHighCtr ? '#34d399' : 'inherit',
                                }}
                              >
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
      )}

      {/* Modal de Criação / Edição */}
      <CampaignModal
        isOpen={isModalOpen}
        onClose={() => {
          setIsModalOpen(false);
          setCampaignToEdit(null);
        }}
        onSave={handleSaveCampaign}
        campaignToEdit={campaignToEdit}
        defaultUf={selectedUf}
      />
    </div>
  );
};
