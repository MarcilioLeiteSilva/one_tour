import React, { useState, useEffect, useCallback } from 'react';
import { Sidebar } from './components/Sidebar';
import { LoginModal } from './components/LoginModal';
import { DashboardTab } from './components/DashboardTab';
import { ImagesTab } from './components/ImagesTab';
import { AdsTab } from './components/AdsTab';
import { RankingsTab } from './components/RankingsTab';
import { ReviewsTab } from './components/ReviewsTab';
import { ContentTab } from './components/ContentTab';
import { NotificationsTab } from './components/NotificationsTab';
import {
  OverviewStats,
  AdPerformanceItem,
  PlaceStatsItem,
  PlaceReviewItem,
  PbCityItem,
  PbAttractionItem,
} from './types';
import {
  getStoredToken,
  clearStoredAuth,
  fetchOverviewStats,
  fetchAdPerformance,
  fetchPlaceStats,
  fetchReviews,
  fetchPbCities,
  fetchPbAttractions,
  triggerRecalculateRankings,
  updateEditorialWeight,
  toggleHideReview,
} from './services/api';
import { CheckCircle2, AlertCircle, Menu, RefreshCw, Radio } from 'lucide-react';

export const App: React.FC = () => {
  const [currentTab, setCurrentTab] = useState<string>('dashboard');
  const [selectedUf, setSelectedUf] = useState<string>('PE');
  const [isAuthenticated, setIsAuthenticated] = useState<boolean>(!!getStoredToken());
  const [isLoginModalOpen, setIsLoginModalOpen] = useState<boolean>(false);
  const [isSidebarCollapsed, setIsSidebarCollapsed] = useState<boolean>(false);

  // Data states
  const [stats, setStats] = useState<OverviewStats | null>(null);
  const [adItems, setAdItems] = useState<AdPerformanceItem[]>([]);
  const [placeStats, setPlaceStats] = useState<PlaceStatsItem[]>([]);
  const [reviews, setReviews] = useState<PlaceReviewItem[]>([]);
  const [cities, setCities] = useState<PbCityItem[]>([]);
  const [attractions, setAttractions] = useState<PbAttractionItem[]>([]);

  // Loading & Action states
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [isRecalculating, setIsRecalculating] = useState<boolean>(false);
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' } | null>(null);

  const showToast = (message: string, type: 'success' | 'error' = 'success') => {
    setToast({ message, type });
    setTimeout(() => {
      setToast(null);
    }, 4500);
  };

  const loadData = useCallback(async () => {
    setIsLoading(true);
    try {
      // 1. Fetch Overview Stats
      try {
        const ov = await fetchOverviewStats();
        setStats(ov);
      } catch (err: any) {
        console.warn('Overview stats fetch notice:', err.message);
      }

      // 2. Fetch Ads Performance
      try {
        const ads = await fetchAdPerformance(30);
        setAdItems(ads);
      } catch (err: any) {
        console.warn('Ads performance fetch notice:', err.message);
      }

      // 3. Fetch Place Stats (Rankings)
      try {
        const ps = await fetchPlaceStats(selectedUf);
        setPlaceStats(ps);
      } catch (err: any) {
        console.warn('Place stats fetch notice:', err.message);
      }

      // 4. Fetch Reviews
      try {
        const revs = await fetchReviews(selectedUf);
        setReviews(revs);
      } catch (err: any) {
        console.warn('Reviews fetch notice:', err.message);
      }

      // 5. Fetch PocketBase Cities & Attractions
      try {
        const [pbCities, pbAttrs] = await Promise.all([
          fetchPbCities(selectedUf),
          fetchPbAttractions(selectedUf),
        ]);
        setCities(pbCities);
        setAttractions(pbAttrs);
      } catch (err: any) {
        console.warn('PocketBase fetch notice:', err.message);
      }
    } finally {
      setIsLoading(false);
    }
  }, [selectedUf]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  const handleRecalculateRankings = async () => {
    if (!isAuthenticated) {
      setIsLoginModalOpen(true);
      showToast('Autentique-se com credenciais de administrador para recalcular rankings.', 'error');
      return;
    }

    setIsRecalculating(true);
    try {
      const res = await triggerRecalculateRankings();
      showToast(`Rankings recalculados com sucesso para ${res.places} atrações no PostgreSQL!`);
      const ps = await fetchPlaceStats(selectedUf);
      setPlaceStats(ps);
    } catch (err: any) {
      showToast(`Erro ao recalcular rankings: ${err.message}`, 'error');
    } finally {
      setIsRecalculating(false);
    }
  };

  const handleUpdateEditorialWeight = async (
    placeId: string,
    uf: string,
    citySlug: string,
    weight: number
  ) => {
    if (!isAuthenticated) {
      setIsLoginModalOpen(true);
      showToast('Autentique-se como administrador para alterar pesos editoriais.', 'error');
      return;
    }

    try {
      await updateEditorialWeight(placeId, uf, citySlug, weight);
      showToast(`Peso editorial da atração "${placeId}" ajustado para ${weight}!`);
      const ps = await fetchPlaceStats(selectedUf);
      setPlaceStats(ps);
    } catch (err: any) {
      showToast(`Erro ao salvar peso editorial: ${err.message}`, 'error');
    }
  };

  const handleToggleHideReview = async (
    placeId: string,
    deviceId: string,
    hidden: boolean
  ) => {
    if (!isAuthenticated) {
      setIsLoginModalOpen(true);
      showToast('Autentique-se como administrador para moderar avaliações.', 'error');
      return;
    }

    try {
      await toggleHideReview(placeId, deviceId, hidden);
      setReviews((prev) =>
        prev.map((r) =>
          r.place_id === placeId && r.device_id === deviceId ? { ...r, hidden } : r
        )
      );
      showToast(hidden ? 'Avaliação ocultada da média pública.' : 'Avaliação restaurada com sucesso!');
    } catch (err: any) {
      showToast(`Erro ao alterar visibilidade: ${err.message}`, 'error');
    }
  };

  const handleLoginSuccess = () => {
    setIsAuthenticated(true);
    showToast('Administrador conectado com sucesso via PocketBase!');
    loadData();
  };

  const handleLogout = () => {
    clearStoredAuth();
    setIsAuthenticated(false);
    showToast('Sessão administrativa encerrada.');
  };

  const tabLabels: Record<string, string> = {
    dashboard: 'Visão Geral & Telemetria',
    images: 'Galeria & Gestão de Imagens dos Apps',
    ads: 'Campanhas House Ads & CTR',
    rankings: 'Rankings Sociais & Pesos Editoriais',
    reviews: 'Moderação de Avaliações',
    content: 'Catálogo PocketBase CMS',
    notifications: 'Broadcast Push Notifications (FCM)',
  };

  return (
    <div style={{ minHeight: '100vh', display: 'flex', background: 'var(--bg-main)' }}>
      {/* Toast Notification */}
      {toast && (
        <div
          style={{
            position: 'fixed',
            bottom: 24,
            right: 24,
            zIndex: 1500,
            display: 'flex',
            alignItems: 'center',
            gap: 10,
            padding: '12px 20px',
            borderRadius: 'var(--radius-sm)',
            background: toast.type === 'success' ? 'rgba(16, 185, 129, 0.95)' : 'rgba(244, 63, 94, 0.95)',
            color: 'white',
            boxShadow: '0 10px 25px -5px rgba(0, 0, 0, 0.5)',
            backdropFilter: 'blur(8px)',
            fontWeight: 600,
            fontSize: '0.875rem',
            animation: 'fadeIn 0.25s ease-out',
          }}
        >
          {toast.type === 'success' ? <CheckCircle2 size={18} /> : <AlertCircle size={18} />}
          <span>{toast.message}</span>
        </div>
      )}

      {/* Lateral Menu / Sidebar */}
      <Sidebar
        currentTab={currentTab}
        onTabChange={setCurrentTab}
        onOpenLogin={() => setIsLoginModalOpen(true)}
        onLogout={handleLogout}
        isAuthenticated={isAuthenticated}
        selectedUf={selectedUf}
        onUfChange={setSelectedUf}
        isCollapsed={isSidebarCollapsed}
        onToggleCollapse={() => setIsSidebarCollapsed((prev) => !prev)}
      />

      {/* Main Layout Area */}
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0, overflowX: 'hidden' }}>
        {/* Top Header Bar */}
        <header
          style={{
            height: 64,
            borderBottom: '1px solid var(--border-subtle)',
            background: 'rgba(9, 13, 22, 0.8)',
            backdropFilter: 'blur(16px)',
            position: 'sticky',
            top: 0,
            zIndex: 100,
            padding: '0 28px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            gap: 16,
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
            <button
              onClick={() => setIsSidebarCollapsed((prev) => !prev)}
              title="Alternar menu lateral"
              style={{
                background: 'rgba(255, 255, 255, 0.04)',
                border: '1px solid var(--border-subtle)',
                color: 'var(--text-muted)',
                borderRadius: 'var(--radius-sm)',
                width: 34,
                height: 34,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                cursor: 'pointer',
              }}
            >
              <Menu size={17} />
            </button>

            <div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <span style={{ fontWeight: 800, fontSize: '1.05rem', color: 'var(--text-main)' }}>
                  {tabLabels[currentTab] || 'One Tour Command Center'}
                </span>
                <span className="badge badge-primary" style={{ fontSize: '0.7rem' }}>
                  UF: {selectedUf}
                </span>
              </div>
            </div>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: 6,
                background: 'rgba(255, 255, 255, 0.04)',
                padding: '4px 10px',
                borderRadius: 'var(--radius-full)',
                border: '1px solid var(--border-subtle)',
                fontSize: '0.75rem',
                color: 'var(--text-muted)',
              }}
            >
              <Radio size={12} color="var(--accent-cyan)" />
              <span>Multi-Flavor Ativo</span>
            </div>

            <button
              onClick={loadData}
              disabled={isLoading}
              className="btn btn-secondary"
              title="Atualizar dados da plataforma"
              style={{ padding: '6px 12px', fontSize: '0.8rem' }}
            >
              <RefreshCw size={13} className={isLoading ? 'spin' : ''} />
              <span>Atualizar</span>
            </button>
          </div>
        </header>

        {/* Content Area */}
        <main style={{ flex: 1, maxWidth: 1440, width: '100%', margin: '0 auto', padding: '28px 24px' }}>
          {currentTab === 'dashboard' && (
            <DashboardTab
              stats={stats}
              adItems={adItems}
              placeStats={placeStats}
              cities={cities}
              selectedUf={selectedUf}
              onRefresh={loadData}
              onRecalculateRankings={handleRecalculateRankings}
              isRecalculating={isRecalculating}
              onGoToTab={setCurrentTab}
            />
          )}

          {currentTab === 'images' && (
            <ImagesTab
              cities={cities}
              attractions={attractions}
              selectedUf={selectedUf}
              onRefresh={loadData}
              isLoading={isLoading}
              onNotify={showToast}
              isAuthenticated={isAuthenticated}
              onOpenLogin={() => setIsLoginModalOpen(true)}
            />
          )}

          {currentTab === 'ads' && (
            <AdsTab
              items={adItems}
              isLoading={isLoading}
              onRefresh={loadData}
              selectedUf={selectedUf}
              onNotify={showToast}
            />
          )}

          {currentTab === 'rankings' && (
            <RankingsTab
              places={placeStats}
              cities={cities}
              isLoading={isLoading}
              onRefresh={loadData}
              onRecalculateRankings={handleRecalculateRankings}
              onUpdateEditorialWeight={handleUpdateEditorialWeight}
              isRecalculating={isRecalculating}
              selectedUf={selectedUf}
            />
          )}

          {currentTab === 'reviews' && (
            <ReviewsTab
              reviews={reviews}
              isLoading={isLoading}
              onRefresh={loadData}
              onToggleHide={handleToggleHideReview}
              selectedUf={selectedUf}
            />
          )}

          {currentTab === 'content' && (
            <ContentTab
              cities={cities}
              attractions={attractions}
              isLoading={isLoading}
              onRefresh={loadData}
              selectedUf={selectedUf}
            />
          )}

          {currentTab === 'notifications' && (
            <NotificationsTab
              cities={cities}
              selectedUf={selectedUf}
              onShowToast={showToast}
              isAuthenticated={isAuthenticated}
              onOpenLogin={() => setIsLoginModalOpen(true)}
            />
          )}
        </main>

        {/* Footer */}
        <footer
          style={{
            borderTop: '1px solid var(--border-subtle)',
            padding: '18px 24px',
            textAlign: 'center',
            color: 'var(--text-dim)',
            fontSize: '0.8rem',
            background: 'rgba(9, 13, 22, 0.6)',
            backdropFilter: 'blur(8px)',
          }}
        >
          <div
            style={{
              maxWidth: 1440,
              margin: '0 auto',
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              flexWrap: 'wrap',
              gap: 12,
            }}
          >
            <div>
              <span>One Tour Ecosystem v2.0 • Painel Central com Gestão Visual & Menu Lateral</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
              <span>API: <code>https://onetour-api-onetour.gtalg3.easypanel.host</code></span>
              <span>PB: <code>https://onetour-pocketbase-estados.gtalg3.easypanel.host</code></span>
            </div>
          </div>
        </footer>
      </div>

      {/* Login Modal */}
      <LoginModal
        isOpen={isLoginModalOpen}
        onClose={() => setIsLoginModalOpen(false)}
        onSuccess={handleLoginSuccess}
      />
    </div>
  );
};
