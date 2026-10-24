import React, { useState } from 'react';
import {
  Star,
  Eye,
  EyeOff,
  Search,
  Filter,
  RefreshCw,
  ShieldAlert,
  Smartphone,
  MapPin,
} from 'lucide-react';
import { PlaceReviewItem } from '../types';

interface ReviewsTabProps {
  reviews: PlaceReviewItem[];
  isLoading: boolean;
  onRefresh: () => void;
  onToggleHide: (placeId: string, deviceId: string, hidden: boolean) => Promise<void>;
  selectedUf: string;
}

export const ReviewsTab: React.FC<ReviewsTabProps> = ({
  reviews,
  isLoading,
  onRefresh,
  onToggleHide,
  selectedUf,
}) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [filterRating, setFilterRating] = useState<number | 'all'>('all');
  const [filterVisibility, setFilterVisibility] = useState<'all' | 'visible' | 'hidden'>('all');
  const [updatingKey, setUpdatingKey] = useState<string | null>(null);

  const filteredReviews = reviews.filter((rev) => {
    // Search
    const term = searchTerm.toLowerCase();
    const matchSearch =
      rev.place_id.toLowerCase().includes(term) ||
      rev.city_slug.toLowerCase().includes(term) ||
      rev.device_id.toLowerCase().includes(term);

    // Rating
    const matchRating = filterRating === 'all' || rev.stars === filterRating;

    // Visibility
    const matchVisibility =
      filterVisibility === 'all' ||
      (filterVisibility === 'visible' && !rev.hidden) ||
      (filterVisibility === 'hidden' && rev.hidden);

    return matchSearch && matchRating && matchVisibility;
  });

  const handleToggle = async (placeId: string, deviceId: string, currentHidden: boolean) => {
    const key = `${placeId}_${deviceId}`;
    setUpdatingKey(key);
    try {
      await onToggleHide(placeId, deviceId, !currentHidden);
    } finally {
      setUpdatingKey(null);
    }
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
      {/* Header Panel */}
      <div
        className="glass-panel"
        style={{
          padding: '24px 28px',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: 16,
        }}
      >
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 6 }}>
            <span className="badge badge-warning">MODERAÇÃO COMUNITÁRIA</span>
            <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>
              UF: {selectedUf}
            </span>
          </div>
          <h1 style={{ fontSize: '1.5rem', fontWeight: 700 }}>
            Avaliações e Moderação de Conteúdo
          </h1>
          <p style={{ fontSize: '0.875rem', color: 'var(--text-muted)', marginTop: 4 }}>
            Monitore avaliações coletadas via telemetria, oculte comentários/avaliações fraudulentas ou inadequadas.
          </p>
        </div>

        <button
          onClick={onRefresh}
          disabled={isLoading}
          className="btn btn-secondary"
        >
          <RefreshCw size={15} className={isLoading ? 'spin' : ''} />
          <span>Atualizar</span>
        </button>
      </div>

      {/* Filter and Search Bar */}
      <div
        className="glass-panel"
        style={{
          padding: '16px 20px',
          display: 'flex',
          gap: 16,
          flexWrap: 'wrap',
          alignItems: 'center',
        }}
      >
        {/* Search */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, flex: '1 1 240px', position: 'relative' }}>
          <Search size={16} style={{ color: 'var(--text-muted)', position: 'absolute', left: 12 }} />
          <input
            type="text"
            className="input-field"
            style={{ paddingLeft: 38 }}
            placeholder="Buscar por atração, cidade ou dispositivo..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>

        {/* Rating Filter */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <Filter size={16} style={{ color: 'var(--text-muted)' }} />
          <select
            className="select-field"
            value={filterRating}
            onChange={(e) => setFilterRating(e.target.value === 'all' ? 'all' : Number(e.target.value))}
          >
            <option value="all">Todas as Estrelas</option>
            <option value="5">⭐⭐⭐⭐⭐ (5)</option>
            <option value="4">⭐⭐⭐⭐ (4)</option>
            <option value="3">⭐⭐⭐ (3)</option>
            <option value="2">⭐⭐ (2)</option>
            <option value="1">⭐ (1)</option>
          </select>
        </div>

        {/* Visibility Filter */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <select
            className="select-field"
            value={filterVisibility}
            onChange={(e) => setFilterVisibility(e.target.value as any)}
          >
            <option value="all">Status: Todos</option>
            <option value="visible">Apenas Ativas</option>
            <option value="hidden">Apenas Ocultas</option>
          </select>
        </div>

        <div style={{ marginLeft: 'auto', fontSize: '0.85rem', color: 'var(--text-muted)' }}>
          {filteredReviews.length} avaliações encontradas
        </div>
      </div>

      {/* Reviews Table */}
      <div className="glass-panel" style={{ overflow: 'hidden' }}>
        <div style={{ overflowX: 'auto' }}>
          <table className="table" style={{ width: '100%' }}>
            <thead>
              <tr>
                <th>Atração (ID)</th>
                <th>Cidade</th>
                <th>Dispositivo</th>
                <th>Nota</th>
                <th>Data</th>
                <th>Status</th>
                <th style={{ textAlign: 'right' }}>Ações</th>
              </tr>
            </thead>
            <tbody>
              {filteredReviews.length === 0 ? (
                <tr>
                  <td colSpan={7} style={{ textAlign: 'center', padding: '40px 20px', color: 'var(--text-muted)' }}>
                    <ShieldAlert size={36} style={{ margin: '0 auto 12px auto', opacity: 0.4 }} />
                    <p style={{ fontWeight: 600 }}>Nenhuma avaliação encontrada com os filtros selecionados.</p>
                    <p style={{ fontSize: '0.8rem' }}>As notas e comentários enviados pelo app móvel aparecerão aqui.</p>
                  </td>
                </tr>
              ) : (
                filteredReviews.map((rev) => {
                  const key = `${rev.place_id}_${rev.device_id}`;
                  const isUpdating = updatingKey === key;

                  return (
                    <tr
                      key={key}
                      style={{
                        backgroundColor: rev.hidden ? 'rgba(244, 63, 94, 0.05)' : undefined,
                      }}
                    >
                      <td>
                        <div style={{ fontWeight: 600, color: 'var(--text-main)' }}>
                          {rev.place_id}
                        </div>
                      </td>
                      <td>
                        <span className="badge badge-secondary" style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}>
                          <MapPin size={11} />
                          {rev.city_slug}
                        </span>
                      </td>
                      <td>
                        <div
                          style={{
                            display: 'flex',
                            alignItems: 'center',
                            gap: 6,
                            fontFamily: 'monospace',
                            fontSize: '0.75rem',
                            color: 'var(--text-muted)',
                          }}
                          title={rev.device_id}
                        >
                          <Smartphone size={13} />
                          {rev.device_id.substring(0, 12)}...
                        </div>
                      </td>
                      <td>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                          {[1, 2, 3, 4, 5].map((s) => (
                            <Star
                              key={s}
                              size={14}
                              style={{
                                color: s <= rev.stars ? 'var(--accent-amber)' : 'rgba(255, 255, 255, 0.15)',
                                fill: s <= rev.stars ? 'var(--accent-amber)' : 'none',
                              }}
                            />
                          ))}
                          <span style={{ fontSize: '0.85rem', fontWeight: 700, marginLeft: 4 }}>
                            {rev.stars}.0
                          </span>
                        </div>
                      </td>
                      <td style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>
                        {new Date(rev.created_at).toLocaleDateString('pt-BR', {
                          day: '2-digit',
                          month: 'short',
                          year: 'numeric',
                        })}
                      </td>
                      <td>
                        {rev.hidden ? (
                          <span className="badge badge-danger">Oculta (Spam)</span>
                        ) : (
                          <span className="badge badge-success">Visível</span>
                        )}
                      </td>
                      <td style={{ textAlign: 'right' }}>
                        <button
                          onClick={() => handleToggle(rev.place_id, rev.device_id, rev.hidden)}
                          disabled={isUpdating}
                          className="btn btn-secondary"
                          style={{
                            padding: '6px 12px',
                            fontSize: '0.8rem',
                            borderColor: rev.hidden ? 'rgba(16, 185, 129, 0.4)' : 'rgba(244, 63, 94, 0.4)',
                          }}
                          title={rev.hidden ? 'Tornar visível e computar nas médias' : 'Ocultar da média pública e app'}
                        >
                          {rev.hidden ? (
                            <>
                              <Eye size={13} style={{ color: 'var(--accent-green)' }} />
                              <span style={{ color: 'var(--accent-green)' }}>Restaurar</span>
                            </>
                          ) : (
                            <>
                              <EyeOff size={13} style={{ color: 'var(--accent-rose)' }} />
                              <span style={{ color: 'var(--accent-rose)' }}>Ocultar</span>
                            </>
                          )}
                        </button>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
