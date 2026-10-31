import React from 'react';
import {
  Compass,
  LayoutDashboard,
  Image as ImageIcon,
  Megaphone,
  Trophy,
  ShieldCheck,
  Database,
  Bell,
  LogIn,
  LogOut,
  Radio,
  ChevronLeft,
  ChevronRight,
} from 'lucide-react';
import { getStoredEmail } from '../services/api';

interface SidebarProps {
  currentTab: string;
  onTabChange: (tab: string) => void;
  onOpenLogin: () => void;
  onLogout: () => void;
  isAuthenticated: boolean;
  selectedUf: string;
  onUfChange: (uf: string) => void;
  isCollapsed: boolean;
  onToggleCollapse: () => void;
}

export const Sidebar: React.FC<SidebarProps> = ({
  currentTab,
  onTabChange,
  onOpenLogin,
  onLogout,
  isAuthenticated,
  selectedUf,
  onUfChange,
  isCollapsed,
  onToggleCollapse,
}) => {
  const adminEmail = getStoredEmail();

  const navItems = [
    {
      id: 'dashboard',
      label: 'Visão Geral',
      icon: LayoutDashboard,
      badge: null,
      section: 'main',
    },
    {
      id: 'images',
      label: 'Imagens dos Apps',
      icon: ImageIcon,
      badge: 'EDITOR',
      badgeColor: 'rgba(6, 182, 212, 0.15)',
      badgeTextColor: '#38bdf8',
      section: 'media',
    },
    {
      id: 'ads',
      label: 'House Ads & CTR',
      icon: Megaphone,
      badge: null,
      section: 'ads',
    },
    {
      id: 'rankings',
      label: 'Rankings & Score',
      icon: Trophy,
      badge: null,
      section: 'content',
    },
    {
      id: 'reviews',
      label: 'Moderação Reviews',
      icon: ShieldCheck,
      badge: null,
      section: 'content',
    },
    {
      id: 'content',
      label: 'Catálogo PocketBase',
      icon: Database,
      badge: null,
      section: 'content',
    },
    {
      id: 'notifications',
      label: 'Push Broadcast (FCM)',
      icon: Bell,
      badge: null,
      section: 'ops',
    },
  ];

  const states = [
    { uf: 'PE', name: 'PE (Pernambuco • Piloto)' },
    { uf: 'AL', name: 'AL (Alagoas • Novo)' },
    { uf: 'PB', name: 'PB (Paraíba)' },
    { uf: 'RN', name: 'RN (Rio Grande do Norte)' },
    { uf: 'CE', name: 'CE (Ceará)' },
    { uf: 'BA', name: 'BA (Bahia)' },
    { uf: 'SP', name: 'SP (São Paulo)' },
    { uf: 'RJ', name: 'RJ (Rio de Janeiro)' },
    { uf: 'ALL', name: 'TODOS (Estatísticas Globais)' },
  ];

  return (
    <aside
      style={{
        width: isCollapsed ? 80 : 270,
        minWidth: isCollapsed ? 80 : 270,
        height: '100vh',
        position: 'sticky',
        top: 0,
        zIndex: 200,
        background: 'rgba(10, 14, 26, 0.95)',
        backdropFilter: 'blur(20px)',
        borderRight: '1px solid var(--border-subtle)',
        display: 'flex',
        flexDirection: 'column',
        transition: 'width 0.25s cubic-bezier(0.4, 0, 0.2, 1), min-width 0.25s cubic-bezier(0.4, 0, 0.2, 1)',
        overflow: 'hidden',
      }}
    >
      {/* Brand Header */}
      <div
        style={{
          padding: isCollapsed ? '20px 14px' : '22px 20px',
          borderBottom: '1px solid var(--border-subtle)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: isCollapsed ? 'center' : 'space-between',
          gap: 12,
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, minWidth: 0 }}>
          <div
            style={{
              width: 40,
              height: 40,
              minWidth: 40,
              borderRadius: 11,
              background: 'var(--primary-gradient)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              boxShadow: '0 0 16px rgba(99, 102, 241, 0.45)',
            }}
          >
            <Compass size={22} color="white" />
          </div>

          {!isCollapsed && (
            <div style={{ minWidth: 0, overflow: 'hidden' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                <span
                  style={{
                    fontWeight: 800,
                    fontSize: '1.05rem',
                    letterSpacing: '-0.02em',
                    color: 'var(--text-main)',
                    whiteSpace: 'nowrap',
                  }}
                >
                  ONE TOUR
                </span>
                <span
                  className="badge badge-primary"
                  style={{ fontSize: '0.65rem', padding: '1px 6px', letterSpacing: '0.04em' }}
                >
                  ADMIN
                </span>
              </div>
              <div
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 6,
                  fontSize: '0.7rem',
                  color: 'var(--text-dim)',
                  marginTop: 2,
                  whiteSpace: 'nowrap',
                }}
              >
                <span className="pulse-indicator" style={{ width: 6, height: 6 }} />
                <span>API & VPS Online</span>
              </div>
            </div>
          )}
        </div>

        {!isCollapsed && (
          <button
            onClick={onToggleCollapse}
            title="Recolher menu lateral"
            style={{
              background: 'rgba(255, 255, 255, 0.04)',
              border: '1px solid var(--border-subtle)',
              color: 'var(--text-muted)',
              borderRadius: 8,
              width: 28,
              height: 28,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              cursor: 'pointer',
              transition: 'all 0.15s ease',
            }}
          >
            <ChevronLeft size={16} />
          </button>
        )}
      </div>

      {/* State / UF Selector */}
      <div
        style={{
          padding: isCollapsed ? '14px 10px' : '14px 16px',
          borderBottom: '1px solid var(--border-subtle)',
          background: 'rgba(255, 255, 255, 0.02)',
        }}
      >
        {isCollapsed ? (
          <div
            title={`Estado Atual: ${selectedUf}`}
            style={{
              background: 'rgba(99, 102, 241, 0.15)',
              border: '1px solid rgba(99, 102, 241, 0.3)',
              borderRadius: 8,
              padding: '6px 0',
              textAlign: 'center',
              fontWeight: 800,
              fontSize: '0.85rem',
              color: '#818cf8',
            }}
          >
            {selectedUf}
          </div>
        ) : (
          <div>
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                marginBottom: 6,
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                <Radio size={13} color="var(--accent-cyan)" />
                <span style={{ fontSize: '0.72rem', color: 'var(--text-muted)', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                  Filtro Territorial
                </span>
              </div>
              <span className="badge badge-info" style={{ fontSize: '0.68rem', padding: '1px 6px' }}>
                {selectedUf}
              </span>
            </div>
            <select
              value={selectedUf}
              onChange={(e) => onUfChange(e.target.value)}
              className="select-field"
              style={{
                width: '100%',
                padding: '6px 10px',
                fontSize: '0.8rem',
                fontWeight: 600,
                background: 'rgba(15, 23, 42, 0.8)',
              }}
            >
              {states.map((s) => (
                <option key={s.uf} value={s.uf} style={{ background: '#0f172a' }}>
                  {s.name}
                </option>
              ))}
            </select>
          </div>
        )}
      </div>

      {/* Navigation Links */}
      <nav
        style={{
          flex: 1,
          padding: isCollapsed ? '16px 8px' : '16px 12px',
          overflowY: 'auto',
          display: 'flex',
          flexDirection: 'column',
          gap: 4,
        }}
      >
        {!isCollapsed && (
          <span
            style={{
              fontSize: '0.68rem',
              fontWeight: 700,
              color: 'var(--text-dim)',
              textTransform: 'uppercase',
              letterSpacing: '0.06em',
              padding: '4px 10px 8px 10px',
            }}
          >
            Menu Principal
          </span>
        )}

        {navItems.map((item) => {
          const active = currentTab === item.id;
          const Icon = item.icon;

          return (
            <button
              key={item.id}
              onClick={() => onTabChange(item.id)}
              title={isCollapsed ? item.label : undefined}
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: isCollapsed ? 'center' : 'space-between',
                gap: 12,
                padding: isCollapsed ? '12px 0' : '10px 14px',
                borderRadius: 'var(--radius-sm)',
                background: active
                  ? 'linear-gradient(90deg, rgba(99, 102, 241, 0.22) 0%, rgba(99, 102, 241, 0.08) 100%)'
                  : 'transparent',
                borderLeft: active ? '3px solid #818cf8' : '3px solid transparent',
                borderTop: 'none',
                borderRight: 'none',
                borderBottom: 'none',
                color: active ? '#ffffff' : 'var(--text-muted)',
                fontWeight: active ? 700 : 500,
                fontSize: '0.86rem',
                cursor: 'pointer',
                textAlign: 'left',
                width: '100%',
                transition: 'all 0.15s ease',
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: 11, minWidth: 0 }}>
                <Icon
                  size={19}
                  color={active ? '#818cf8' : 'currentColor'}
                  style={{ flexShrink: 0 }}
                />
                {!isCollapsed && (
                  <span style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                    {item.label}
                  </span>
                )}
              </div>

              {!isCollapsed && item.badge && (
                <span
                  style={{
                    fontSize: '0.62rem',
                    fontWeight: 800,
                    letterSpacing: '0.04em',
                    padding: '2px 6px',
                    borderRadius: 'var(--radius-full)',
                    background: item.badgeColor || 'rgba(99, 102, 241, 0.2)',
                    color: item.badgeTextColor || '#818cf8',
                    border: '1px solid rgba(56, 189, 248, 0.3)',
                    flexShrink: 0,
                  }}
                >
                  {item.badge}
                </span>
              )}
            </button>
          );
        })}
      </nav>

      {/* Collapse Toggle for collapsed state */}
      {isCollapsed && (
        <div style={{ padding: '8px', display: 'flex', justifyContent: 'center' }}>
          <button
            onClick={onToggleCollapse}
            title="Expandir menu lateral"
            style={{
              background: 'rgba(255, 255, 255, 0.04)',
              border: '1px solid var(--border-subtle)',
              color: 'var(--text-muted)',
              borderRadius: 8,
              width: 34,
              height: 34,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              cursor: 'pointer',
            }}
          >
            <ChevronRight size={16} />
          </button>
        </div>
      )}

      {/* Admin Auth Footer */}
      <div
        style={{
          borderTop: '1px solid var(--border-subtle)',
          padding: isCollapsed ? '14px 8px' : '16px 14px',
          background: 'rgba(9, 13, 22, 0.75)',
        }}
      >
        {isAuthenticated ? (
          <div>
            {!isCollapsed ? (
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 8 }}>
                <div style={{ minWidth: 0 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                    <ShieldCheck size={14} color="var(--accent-green)" />
                    <span style={{ fontSize: '0.78rem', fontWeight: 700, color: 'var(--accent-green)' }}>
                      Admin Conectado
                    </span>
                  </div>
                  <div
                    style={{
                      fontSize: '0.72rem',
                      color: 'var(--text-muted)',
                      overflow: 'hidden',
                      textOverflow: 'ellipsis',
                      whiteSpace: 'nowrap',
                      marginTop: 2,
                    }}
                    title={adminEmail || 'admin@onetour.com'}
                  >
                    {adminEmail || 'admin@onetour.com'}
                  </div>
                </div>

                <button
                  onClick={onLogout}
                  className="btn btn-secondary"
                  title="Encerrar sessão de administrador"
                  style={{ padding: '6px 8px', borderRadius: 8, flexShrink: 0 }}
                >
                  <LogOut size={14} />
                </button>
              </div>
            ) : (
              <button
                onClick={onLogout}
                title={`Desconectar (${adminEmail})`}
                style={{
                  width: '100%',
                  background: 'transparent',
                  border: 'none',
                  color: 'var(--accent-rose)',
                  cursor: 'pointer',
                  display: 'flex',
                  justifyContent: 'center',
                  padding: '6px 0',
                }}
              >
                <LogOut size={18} />
              </button>
            )}
          </div>
        ) : (
          <div>
            {!isCollapsed ? (
              <button
                onClick={onOpenLogin}
                className="btn btn-primary"
                style={{ width: '100%', fontSize: '0.8rem', padding: '8px 12px' }}
              >
                <LogIn size={15} />
                <span>Conectar Admin</span>
              </button>
            ) : (
              <button
                onClick={onOpenLogin}
                title="Conectar como Administrador"
                style={{
                  width: '100%',
                  background: 'transparent',
                  border: 'none',
                  color: 'var(--primary)',
                  cursor: 'pointer',
                  display: 'flex',
                  justifyContent: 'center',
                  padding: '6px 0',
                }}
              >
                <LogIn size={18} />
              </button>
            )}
          </div>
        )}
      </div>
    </aside>
  );
};
