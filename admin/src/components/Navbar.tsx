import React from 'react';
import { Compass, ShieldCheck, LogIn, LogOut, Radio } from 'lucide-react';
import { getStoredEmail } from '../services/api';

interface NavbarProps {
  currentTab: string;
  onTabChange: (tab: string) => void;
  onOpenLogin: () => void;
  onLogout: () => void;
  isAuthenticated: boolean;
  selectedUf: string;
  onUfChange: (uf: string) => void;
}

export const Navbar: React.FC<NavbarProps> = ({
  currentTab,
  onTabChange,
  onOpenLogin,
  onLogout,
  isAuthenticated,
  selectedUf,
  onUfChange,
}) => {
  const adminEmail = getStoredEmail();

  const tabs = [
    { id: 'dashboard', label: 'Dashboard' },
    { id: 'ads', label: 'House Ads & CTR' },
    { id: 'rankings', label: 'Rankings & Score' },
    { id: 'reviews', label: 'Moderação' },
    { id: 'content', label: 'Conteúdo (PB)' },
    { id: 'notifications', label: 'Push (FCM)' },
  ];

  return (
    <header
      style={{
        borderBottom: '1px solid var(--border-subtle)',
        background: 'rgba(9, 13, 22, 0.85)',
        backdropFilter: 'blur(16px)',
        position: 'sticky',
        top: 0,
        zIndex: 100,
        padding: '0 24px',
      }}
    >
      <div
        style={{
          maxWidth: 1400,
          margin: '0 auto',
          height: 68,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          gap: 16,
        }}
      >
        {/* Brand */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <div
            style={{
              width: 40,
              height: 40,
              borderRadius: 10,
              background: 'var(--primary-gradient)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              boxShadow: '0 0 15px rgba(99, 102, 241, 0.4)',
            }}
          >
            <Compass size={22} color="white" />
          </div>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <span style={{ fontWeight: 800, fontSize: '1.1rem', letterSpacing: '-0.02em' }}>
                ONE TOUR
              </span>
              <span className="badge badge-primary">COMMAND CENTER</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: '0.72rem', color: 'var(--text-dim)' }}>
              <span className="pulse-indicator" />
              <span>API & PostGIS Conectados</span>
            </div>
          </div>
        </div>

        {/* Navigation Tabs */}
        <nav style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
          {tabs.map((tab) => {
            const active = currentTab === tab.id;
            return (
              <button
                key={tab.id}
                onClick={() => onTabChange(tab.id)}
                style={{
                  background: active ? 'rgba(99, 102, 241, 0.15)' : 'transparent',
                  color: active ? '#818cf8' : 'var(--text-muted)',
                  border: active ? '1px solid rgba(99, 102, 241, 0.3)' : '1px solid transparent',
                  padding: '8px 14px',
                  borderRadius: 'var(--radius-sm)',
                  fontWeight: 600,
                  fontSize: '0.875rem',
                  cursor: 'pointer',
                  transition: 'all 0.15s ease',
                }}
              >
                {tab.label}
              </button>
            );
          })}
        </nav>

        {/* Right Section: UF Selector & Auth */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          {/* UF Selector */}
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: 6,
              background: 'rgba(255, 255, 255, 0.05)',
              padding: '4px 10px',
              borderRadius: 'var(--radius-sm)',
              border: '1px solid var(--border-subtle)',
            }}
          >
            <Radio size={14} color="var(--accent-cyan)" />
            <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)', fontWeight: 600 }}>UF:</span>
            <select
              value={selectedUf}
              onChange={(e) => onUfChange(e.target.value)}
              style={{
                background: 'transparent',
                border: 'none',
                color: 'var(--text-main)',
                fontWeight: 700,
                fontSize: '0.85rem',
                cursor: 'pointer',
                outline: 'none',
              }}
            >
              <option value="PE" style={{ background: '#0f172a' }}>PE (Pernambuco • Piloto)</option>
              <option value="PB" style={{ background: '#0f172a' }}>PB (Paraíba)</option>
              <option value="AL" style={{ background: '#0f172a' }}>AL (Alagoas)</option>
              <option value="RN" style={{ background: '#0f172a' }}>RN (Rio Grande do Norte)</option>
              <option value="CE" style={{ background: '#0f172a' }}>CE (Ceará)</option>
              <option value="BA" style={{ background: '#0f172a' }}>BA (Bahia)</option>
              <option value="SP" style={{ background: '#0f172a' }}>SP (São Paulo)</option>
              <option value="RJ" style={{ background: '#0f172a' }}>RJ (Rio de Janeiro)</option>
            </select>
          </div>

          {/* Auth State */}
          {isAuthenticated ? (
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <div
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 6,
                  padding: '6px 12px',
                  borderRadius: 'var(--radius-sm)',
                  background: 'rgba(16, 185, 129, 0.1)',
                  border: '1px solid rgba(16, 185, 129, 0.25)',
                }}
              >
                <ShieldCheck size={16} color="#34d399" />
                <span style={{ fontSize: '0.8rem', color: '#6ee7b7', fontWeight: 600 }}>
                  {adminEmail || 'Admin Autenticado'}
                </span>
              </div>
              <button
                onClick={onLogout}
                className="btn btn-secondary"
                title="Sair da sessão"
                style={{ padding: '8px' }}
              >
                <LogOut size={16} />
              </button>
            </div>
          ) : (
            <button onClick={onOpenLogin} className="btn btn-primary">
              <LogIn size={16} />
              <span>Entrar no PocketBase</span>
            </button>
          )}
        </div>
      </div>
    </header>
  );
};
