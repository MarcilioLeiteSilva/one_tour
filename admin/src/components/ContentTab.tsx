import React, { useState } from 'react';
import {
  Compass,
  MapPin,
  ExternalLink,
  Search,
  RefreshCw,
  Sparkles,
  Database,
  Star,
  Heart,
} from 'lucide-react';
import { PbCityItem, PbAttractionItem } from '../types';
import { PB_BASE_URL } from '../services/api';

interface ContentTabProps {
  cities: PbCityItem[];
  attractions: PbAttractionItem[];
  isLoading: boolean;
  onRefresh: () => void;
  selectedUf: string;
}

export const ContentTab: React.FC<ContentTabProps> = ({
  cities,
  attractions,
  isLoading,
  onRefresh,
  selectedUf,
}) => {
  const [subView, setSubView] = useState<'cities' | 'attractions'>('cities');
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCityFilter, setSelectedCityFilter] = useState<string>('all');
  const [selectedCategory, setSelectedCategory] = useState<string>('all');

  const filteredCities = cities.filter((c) => {
    const term = searchTerm.toLowerCase();
    return c.nome.toLowerCase().includes(term) || c.slug.toLowerCase().includes(term);
  });

  const categories = Array.from(new Set(attractions.map((a) => a.categoria).filter(Boolean)));

  const filteredAttractions = attractions.filter((a) => {
    const term = searchTerm.toLowerCase();
    const matchSearch =
      a.nome.toLowerCase().includes(term) ||
      a.slug.toLowerCase().includes(term) ||
      (a.cidade_slug && a.cidade_slug.toLowerCase().includes(term));
    const matchCity = selectedCityFilter === 'all' || a.cidade_slug === selectedCityFilter;
    const matchCategory = selectedCategory === 'all' || a.categoria === selectedCategory;
    return matchSearch && matchCity && matchCategory;
  });

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
            <span className="badge badge-info">POCKETBASE CMS</span>
            <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>
              Catálogo Turístico • UF: {selectedUf}
            </span>
          </div>
          <h1 style={{ fontSize: '1.5rem', fontWeight: 700 }}>
            Cidades e Atrações Turísticas
          </h1>
          <p style={{ fontSize: '0.875rem', color: 'var(--text-muted)', marginTop: 4 }}>
            Visualização dos dados editoriais alimentados no PocketBase e consumidos pelo aplicativo móvel offline-first.
          </p>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <a
            href={`${PB_BASE_URL}/_/`}
            target="_blank"
            rel="noopener noreferrer"
            className="btn btn-secondary"
            title="Abrir painel administrativo completo do PocketBase"
          >
            <Database size={15} />
            <span>Abrir PocketBase Studio</span>
            <ExternalLink size={13} style={{ marginLeft: 2, opacity: 0.7 }} />
          </a>
          <button onClick={onRefresh} disabled={isLoading} className="btn btn-primary">
            <RefreshCw size={15} className={isLoading ? 'spin' : ''} />
            <span>Sincronizar</span>
          </button>
        </div>
      </div>

      {/* Sub-navigation Switcher */}
      <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
        <button
          onClick={() => setSubView('cities')}
          className={`btn ${subView === 'cities' ? 'btn-primary' : 'btn-secondary'}`}
          style={{ padding: '8px 20px', borderRadius: 'var(--radius-full)' }}
        >
          <MapPin size={16} />
          <span>Cidades e Destinos ({cities.length})</span>
        </button>
        <button
          onClick={() => setSubView('attractions')}
          className={`btn ${subView === 'attractions' ? 'btn-primary' : 'btn-secondary'}`}
          style={{ padding: '8px 20px', borderRadius: 'var(--radius-full)' }}
        >
          <Compass size={16} />
          <span>Atrações Cadastradas ({attractions.length})</span>
        </button>
      </div>

      {/* Search and Filters */}
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
            placeholder={subView === 'cities' ? 'Buscar cidade ou slug...' : 'Buscar atração, categoria ou cidade...'}
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>

        {subView === 'attractions' && (
          <>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <select
                className="select-field"
                value={selectedCityFilter}
                onChange={(e) => setSelectedCityFilter(e.target.value)}
              >
                <option value="all">Todas as Cidades</option>
                {cities.map((c) => (
                  <option key={c.slug} value={c.slug}>
                    {c.nome}
                  </option>
                ))}
              </select>
            </div>

            {categories.length > 0 && (
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <select
                  className="select-field"
                  value={selectedCategory}
                  onChange={(e) => setSelectedCategory(e.target.value)}
                >
                  <option value="all">Todas as Categorias</option>
                  {categories.map((cat) => (
                    <option key={cat} value={cat}>
                      {cat}
                    </option>
                  ))}
                </select>
              </div>
            )}
          </>
        )}

        <div style={{ marginLeft: 'auto', fontSize: '0.85rem', color: 'var(--text-muted)' }}>
          {subView === 'cities' ? filteredCities.length : filteredAttractions.length} registros
        </div>
      </div>

      {/* Cities View */}
      {subView === 'cities' && (
        <div className="glass-panel" style={{ overflow: 'hidden' }}>
          <div style={{ overflowX: 'auto' }}>
            <table className="table" style={{ width: '100%' }}>
              <thead>
                <tr>
                  <th>Cidade</th>
                  <th>Slug</th>
                  <th>UF</th>
                  <th>Tag / Destaque</th>
                  <th>Coordenadas</th>
                  <th>Pacote Offline</th>
                </tr>
              </thead>
              <tbody>
                {filteredCities.length === 0 ? (
                  <tr>
                    <td colSpan={6} style={{ textAlign: 'center', padding: '40px 20px', color: 'var(--text-muted)' }}>
                      <MapPin size={36} style={{ margin: '0 auto 12px auto', opacity: 0.4 }} />
                      <p style={{ fontWeight: 600 }}>Nenhuma cidade encontrada na coleção `cidades` do PocketBase.</p>
                      <p style={{ fontSize: '0.8rem' }}>Cadastre os polos turísticos de Pernambuco no console do PocketBase.</p>
                    </td>
                  </tr>
                ) : (
                  filteredCities.map((city) => (
                    <tr key={city.id || city.slug}>
                      <td>
                        <div style={{ fontWeight: 700, color: 'var(--text-main)', display: 'flex', alignItems: 'center', gap: 6 }}>
                          <MapPin size={14} style={{ color: 'var(--primary)' }} />
                          {city.nome}
                        </div>
                      </td>
                      <td>
                        <code style={{ fontSize: '0.8rem', color: 'var(--accent-cyan)' }}>{city.slug}</code>
                      </td>
                      <td>
                        <span className="badge badge-primary">{city.estado_sigla || selectedUf}</span>
                      </td>
                      <td>
                        {city.destaque && (
                          <span className="badge badge-warning" style={{ marginRight: 6 }}>
                            <Sparkles size={11} style={{ marginRight: 3 }} />
                            Destaque
                          </span>
                        )}
                        {city.tag && <span className="badge badge-secondary">{city.tag}</span>}
                      </td>
                      <td style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>
                        {city.lat && city.lon ? `${city.lat.toFixed(4)}, ${city.lon.toFixed(4)}` : '—'}
                      </td>
                      <td>
                        <span className="badge badge-info" style={{ fontSize: '0.75rem' }}>
                          {city.package_size || 'Auto SQLite'}
                        </span>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Attractions View */}
      {subView === 'attractions' && (
        <div className="glass-panel" style={{ overflow: 'hidden' }}>
          <div style={{ overflowX: 'auto' }}>
            <table className="table" style={{ width: '100%' }}>
              <thead>
                <tr>
                  <th>Atração</th>
                  <th>Cidade</th>
                  <th>Categoria</th>
                  <th>Atributos</th>
                  <th>Score PB</th>
                  <th>Engajamento</th>
                </tr>
              </thead>
              <tbody>
                {filteredAttractions.length === 0 ? (
                  <tr>
                    <td colSpan={6} style={{ textAlign: 'center', padding: '40px 20px', color: 'var(--text-muted)' }}>
                      <Compass size={36} style={{ margin: '0 auto 12px auto', opacity: 0.4 }} />
                      <p style={{ fontWeight: 600 }}>Nenhuma atração encontrada com os filtros selecionados.</p>
                      <p style={{ fontSize: '0.8rem' }}>Cadastre atrações ou importe dados pelo PocketBase Studio.</p>
                    </td>
                  </tr>
                ) : (
                  filteredAttractions.map((att) => (
                    <tr key={att.id || att.slug}>
                      <td>
                        <div style={{ fontWeight: 700, color: 'var(--text-main)' }}>{att.nome}</div>
                        <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{att.slug}</div>
                      </td>
                      <td>
                        <span className="badge badge-secondary">{att.cidade_slug}</span>
                      </td>
                      <td>
                        <span className="badge badge-info">{att.categoria || 'Geral'}</span>
                      </td>
                      <td>
                        <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                          {att.must_see && (
                            <span className="badge badge-warning" style={{ fontSize: '0.7rem' }}>
                              Imperdível
                            </span>
                          )}
                          {att.gratuito && (
                            <span className="badge badge-success" style={{ fontSize: '0.7rem' }}>
                              Gratuito
                            </span>
                          )}
                          {att.kid_friendly && (
                            <span className="badge badge-secondary" style={{ fontSize: '0.7rem' }}>
                              Família
                            </span>
                          )}
                        </div>
                      </td>
                      <td>
                        <div style={{ fontWeight: 700, color: 'var(--primary)' }}>
                          {att.score ? Number(att.score).toFixed(2) : '—'}
                        </div>
                      </td>
                      <td>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                          <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, fontSize: '0.8rem' }}>
                            <Star size={12} style={{ color: 'var(--accent-amber)', fill: 'var(--accent-amber)' }} />
                            {att.rating_avg ? Number(att.rating_avg).toFixed(1) : '-'}
                          </span>
                          <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, fontSize: '0.8rem' }}>
                            <Heart size={12} style={{ color: 'var(--accent-rose)', fill: 'var(--accent-rose)' }} />
                            {att.likes_count || 0}
                          </span>
                        </div>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
};
