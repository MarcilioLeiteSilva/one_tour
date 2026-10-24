export interface OverviewStats {
  devices_total: number;
  devices_active_7d: number;
  likes_total: number;
  reviews_total: number;
  impressions_30d: number;
  clicks_30d: number;
}

export interface AdPerformanceItem {
  ad_id: string;
  uf: string;
  position: 'home_card' | 'attraction_banner' | 'interstitial';
  impressions: number;
  clicks: number;
  ctr: number;
}

export interface PlaceReviewItem {
  place_id: string;
  device_id: string;
  city_slug: string;
  stars: number;
  hidden: boolean;
  created_at: string;
  updated_at: string;
}

export interface PlaceStatsItem {
  place_id: string;
  city_slug: string;
  likes_count: number;
  rating_avg: number;
  rating_count: number;
  score: number;
  rank_state?: number;
  rank_city?: number;
  updated_at: string;
}

export interface PbCityItem {
  id: string;
  nome: string;
  slug: string;
  estado_sigla: string;
  tag?: string;
  lat?: number;
  lon?: number;
  package_size?: string;
  destaque?: boolean;
  descricao_pt?: string;
}

export interface PbAttractionItem {
  id: string;
  nome: string;
  slug: string;
  cidade_slug: string;
  uf: string;
  categoria: string;
  horario?: string;
  duracao_min?: number;
  gratuito?: boolean;
  kid_friendly?: boolean;
  must_see?: boolean;
  rating_avg?: number;
  rating_count?: number;
  likes_count?: number;
  rank_posicao?: number;
  score?: number;
  lat?: number;
  lon?: number;
  descricao_pt?: string;
}
