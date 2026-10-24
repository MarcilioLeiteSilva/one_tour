import React, { useState } from 'react';
import {
  Trophy,
  Award,
  Search,
  Filter,
  RefreshCw,
  Star,
  Heart,
  Sliders,
  Check,
  HelpCircle,
} from 'lucide-react';
import { PlaceStatsItem, PbCityItem } from '../types';

interface RankingsTabProps {
  places: PlaceStatsItem[];
  cities: PbCityItem[];
  isLoading: boolean;
  onRefresh: () => void;
  onRecalculateRankings: () => Promise<void>;
  onUpdateEditorialWeight: (
    placeId: string,
    uf: string,
    citySlug: string,
    weight: number
  ) => Promise<void>;
  isRecalculating: boolean;
  selectedUf: string;
}

export const RankingsTab: React.FC<RankingsTabProps> = ({
  places,
  cities,
  isLoading,
  onRefresh,
  onRecalculateRankings,
  onUpdateEditorialWeight,
  isRecalculating,
  selectedUf,
}) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCity, setSelectedCity] = useState<string>('all');
  const [sortBy, setSortBy] = useState<'rank' | 'score' | 'likes' | 'rating'>('rank');
  const [editingPlaceId, setEditingPlaceId] = useState<string | null>(null);
  const [editWeightValue, setEditWeightValue] = useState<number>(3.0);
  const [isSavingWeight, setIsSavingWeight] = useState(false);
  const [showFormulaInfo, setShowFormulaInfo] = useState(false);

  // Filter
  const filtered = places.filter((p) => {
    const matchSearch =
      p.place_id.toLowerCase().includes(searchTerm.toLowerCase()) ||
      p.city_slug.toLowerCase().includes(searchTerm.toLowerCase());
    const matchCity = selectedCity === 'all' || p.city_slug.toLowerCase() === selectedCity.toLowerCase();
    return matchSearch && matchCity;
  });

  // Sort
  const sorted = [...filtered].sort((a, b) => {
    if (sortBy === 'rank') {
      const rankA = a.rank_state || 99999;
      const rankB = b.rank_state || 99999;
      return rankA - rankB;
    }
    if (sortBy === 'score') {
      return (b.score || 0) - (a.score || 0);
    }
    if (sortBy === 'likes') {
      return (b.likes_count || 0) - (a.likes_count || 0);
    }
    if (sortBy === 'rating') {
      return (b.rating_avg || 0) - (a.rating_avg || 0);
    }
    return 0;
  });

  const handleStartEdit = (place: PlaceStatsItem) => {
    setEditingPlaceId(place.place_id);
    setEditWeightValue(3.0); // default fallback
  };

  const handleSaveWeight = async (place: PlaceStatsItem) => {
    setIsSavingWeight(true);
    try {
      await onUpdateEditorialWeight(place.place_id, selectedUf, place.city_slug, editWeightValue);
      setEditingPlaceId(null);
    } finally {
      setIsSavingWeight(false);
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
            <span className="badge badge-success">SISTEMA DE RANQUEAMENTO V2</span>
            <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>
              UF: {selectedUf}
            </span>
          </div>
          <h1 style={{ fontSize: '1.5rem', fontWeight: 700 }}>
            Rankings e Pesos Editoriais de Atrações
          </h1>
          <p style={{ fontSize: '0.875rem', color: 'var(--text-muted)', marginTop: 4 }}>
            Classificação algorítmica inteligente que pondera avaliações bayesianas, curtidas da comunidade e curadoria editorial.
          </p>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <button
            onClick={onRefresh}
            disabled={isLoading}
            className="btn btn-secondary"
            title="Atualizar lista de rankings"
          >
            <RefreshCw size={15} className={isLoading ? 'spin' : ''} />
            <span>Atualizar</span>
          </button>

          <button
            onClick={() => setShowFormulaInfo(!showFormulaInfo)}
            className="btn btn-secondary"
            title="Ver fórmula matemática do Score"
          >
            <HelpCircle size={15} />
            <span>Fórmula</span>
          </button>

          <button
            onClick={onRecalculateRankings}
            disabled={isRecalculating}
            className="btn btn-primary"
            title="Recalcula posições estaduais e municipais agora no PostgreSQL"
          >
            <RefreshCw size={15} className={isRecalculating ? 'spin' : ''} />
            <span>{isRecalculating ? 'Recalculando...' : 'Recalcular Agora'}</span>
          </button>
        </div>
      </div>

      {/* Formula Explanation Callout */}
      {showFormulaInfo && (
        <div
          className="glass-panel"
          style={{
            padding: '20px 24px',
            backgroundColor: 'rgba(99, 102, 241, 0.08)',
            borderColor: 'rgba(99, 102, 241, 0.25)',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12 }}>
            <Award size={20} style={{ color: 'var(--primary)', flexShrink: 0, marginTop: 2 }} />
            <div>
              <h4 style={{ fontSize: '0.95rem', fontWeight: 700, color: 'var(--text-main)', marginBottom: 6 }}>
                Fórmula de Pontuação Bayesiana (Score 0 a 5.0)
              </h4>
              <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)', lineHeight: 1.6 }}>
                <strong>Score</strong> = (Média Bayesiana × <strong>0.40</strong>) + (Curtidas Normalizadas × <strong>0.30</strong>) + (Peso Editorial × <strong>0.30</strong>)
              </p>
              <ul style={{ fontSize: '0.8rem', color: 'var(--text-muted)', marginTop: 8, paddingLeft: 18, lineHeight: 1.5 }}>
                <li><strong>Média Bayesiana:</strong> Pondera notas com um prior de 4.0 e peso mínimo de 5 votos para evitar que uma atração com 1 voto 5 estrelas ultrapasse atrações consagradas com centenas de avaliações.</li>
                <li><strong>Curtidas:</strong> Normalizadas logaritmicamente na escala 0-5.</li>
                <li><strong>Peso Editorial:</strong> Controle de curadoria (0.0 a 5.0) para impulsionar patrimônios históricos ou atrações em destaque.</li>
              </ul>
            </div>
          </div>
        </div>
      )}

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
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, flex: '1 1 240px', position: 'relative' }}>
          <Search size={16} style={{ color: 'var(--text-muted)', position: 'absolute', left: 12 }} />
          <input
            type="text"
            className="input-field"
            style={{ paddingLeft: 38 }}
            placeholder="Buscar atração ou cidade..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>

        {/* City Filter */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <select
            className="select-field"
            value={selectedCity}
            onChange={(e) => setSelectedCity(e.target.value)}
          >
            <option value="all">Todas as Cidades</option>
            {cities.map((c) => (
              <option key={c.slug} value={c.slug}>
                {c.nome}
              </option>
            ))}
          </select>
        </div>

        {/* Sort */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <Filter size={16} style={{ color: 'var(--text-muted)' }} />
          <select
            className="select-field"
            value={sortBy}
            onChange={(e) => setSortBy(e.target.value as any)}
          >
            <option value="rank">Ordenar por: Rank Estado (#1)</option>
            <option value="score">Ordenar por: Maior Score (0-5)</option>
            <option value="likes">Ordenar por: Mais Curtidas</option>
            <option value="rating">Ordenar por: Melhor Nota Média</option>
          </select>
        </div>

        <div style={{ marginLeft: 'auto', fontSize: '0.85rem', color: 'var(--text-muted)' }}>
          {sorted.length} atrações no ranking
        </div>
      </div>

      {/* Rankings Table */}
      <div className="glass-panel" style={{ overflow: 'hidden' }}>
        <div style={{ overflowX: 'auto' }}>
          <table className="table" style={{ width: '100%' }}>
            <thead>
              <tr>
                <th>Rank UF</th>
                <th>Rank Cidade</th>
                <th>Atração</th>
                <th>Cidade</th>
                <th>Score Final</th>
                <th>Avaliações</th>
                <th>Curtidas</th>
                <th style={{ textAlign: 'right' }}>Curadoria / Peso</th>
              </tr>
            </thead>
            <tbody>
              {sorted.length === 0 ? (
                <tr>
                  <td colSpan={8} style={{ textAlign: 'center', padding: '40px 20px', color: 'var(--text-muted)' }}>
                    <Trophy size={36} style={{ margin: '0 auto 12px auto', opacity: 0.4 }} />
                    <p style={{ fontWeight: 600 }}>Nenhuma atração com métricas de ranking disponível ainda.</p>
                    <p style={{ fontSize: '0.8rem' }}>
                      Clique em "Recalcular Agora" ou gere interações no aplicativo One Tour PE.
                    </p>
                  </td>
                </tr>
              ) : (
                sorted.map((item) => {
                  const isEditing = editingPlaceId === item.place_id;

                  return (
                    <tr key={item.place_id}>
                      <td>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                          {item.rank_state === 1 && (
                            <Trophy size={16} style={{ color: 'var(--accent-amber)' }} />
                          )}
                          <span
                            style={{
                              fontWeight: 800,
                              fontSize: '0.95rem',
                              color:
                                item.rank_state === 1
                                  ? 'var(--accent-amber)'
                                  : item.rank_state && item.rank_state <= 3
                                  ? 'var(--accent-cyan)'
                                  : 'var(--text-main)',
                            }}
                          >
                            #{item.rank_state || '-'}
                          </span>
                        </div>
                      </td>
                      <td>
                        <span className="badge badge-secondary">
                          #{item.rank_city || '-'}
                        </span>
                      </td>
                      <td>
                        <div style={{ fontWeight: 600, color: 'var(--text-main)' }}>
                          {item.place_id}
                        </div>
                      </td>
                      <td>
                        <span style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>
                          {item.city_slug}
                        </span>
                      </td>
                      <td>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                          <span
                            style={{
                              fontSize: '1rem',
                              fontWeight: 800,
                              color: 'var(--primary)',
                            }}
                          >
                            {Number(item.score || 0).toFixed(2)}
                          </span>
                          <div
                            style={{
                              width: 50,
                              height: 6,
                              backgroundColor: 'rgba(255, 255, 255, 0.1)',
                              borderRadius: 3,
                              overflow: 'hidden',
                            }}
                          >
                            <div
                              style={{
                                width: `${Math.min(100, (Number(item.score || 0) / 5) * 100)}%`,
                                height: '100%',
                                background: 'var(--primary-gradient)',
                              }}
                            />
                          </div>
                        </div>
                      </td>
                      <td>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                          <Star size={13} style={{ color: 'var(--accent-amber)', fill: 'var(--accent-amber)' }} />
                          <span style={{ fontWeight: 600 }}>
                            {Number(item.rating_avg || 0).toFixed(1)}
                          </span>
                          <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                            ({item.rating_count || 0})
                          </span>
                        </div>
                      </td>
                      <td>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                          <Heart size={13} style={{ color: 'var(--accent-rose)', fill: 'var(--accent-rose)' }} />
                          <span style={{ fontWeight: 600 }}>{item.likes_count || 0}</span>
                        </div>
                      </td>
                      <td style={{ textAlign: 'right' }}>
                        {isEditing ? (
                          <div style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
                            <input
                              type="number"
                              min="0"
                              max="5"
                              step="0.5"
                              className="input-field"
                              style={{ width: 70, padding: '4px 8px', textAlign: 'center' }}
                              value={editWeightValue}
                              onChange={(e) => setEditWeightValue(Number(e.target.value))}
                            />
                            <button
                              onClick={() => handleSaveWeight(item)}
                              disabled={isSavingWeight}
                              className="btn btn-primary"
                              style={{ padding: '6px 10px', fontSize: '0.75rem' }}
                              title="Salvar peso editorial"
                            >
                              <Check size={14} />
                            </button>
                            <button
                              onClick={() => setEditingPlaceId(null)}
                              className="btn btn-secondary"
                              style={{ padding: '6px 8px', fontSize: '0.75rem' }}
                            >
                              ✕
                            </button>
                          </div>
                        ) : (
                          <button
                            onClick={() => handleStartEdit(item)}
                            className="btn btn-secondary"
                            style={{ padding: '6px 12px', fontSize: '0.8rem' }}
                            title="Ajustar peso editorial de 0.0 a 5.0"
                          >
                            <Sliders size={13} />
                            <span>Ajustar</span>
                          </button>
                        )}
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
