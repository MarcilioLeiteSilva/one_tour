import React from 'react';

interface StatCardProps {
  title: string;
  value: string | number;
  subtitle?: string;
  icon: React.ReactNode;
  badge?: string;
  badgeColor?: 'primary' | 'green' | 'amber' | 'rose';
  accentColor?: string;
}

export const StatCard: React.FC<StatCardProps> = ({
  title,
  value,
  subtitle,
  icon,
  badge,
  badgeColor = 'primary',
  accentColor = 'var(--primary)',
}) => {
  return (
    <div
      className="glass-panel"
      style={{
        padding: 20,
        position: 'relative',
        overflow: 'hidden',
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'space-between',
        gap: 12,
      }}
    >
      <div
        style={{
          position: 'absolute',
          top: 0,
          left: 0,
          width: 4,
          height: '100%',
          backgroundColor: accentColor,
        }}
      />
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <span style={{ fontSize: '0.825rem', color: 'var(--text-muted)', fontWeight: 600 }}>
          {title}
        </span>
        <div
          style={{
            width: 36,
            height: 36,
            borderRadius: 'var(--radius-sm)',
            background: 'rgba(255, 255, 255, 0.05)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            border: '1px solid var(--border-subtle)',
          }}
        >
          {icon}
        </div>
      </div>

      <div>
        <div style={{ fontSize: '1.85rem', fontWeight: 800, letterSpacing: '-0.03em', lineHeight: 1.1 }}>
          {value}
        </div>
        {subtitle && (
          <div style={{ fontSize: '0.75rem', color: 'var(--text-dim)', marginTop: 4 }}>
            {subtitle}
          </div>
        )}
      </div>

      {badge && (
        <div style={{ display: 'flex', alignItems: 'center', marginTop: 4 }}>
          <span className={`badge badge-${badgeColor}`}>{badge}</span>
        </div>
      )}
    </div>
  );
};
