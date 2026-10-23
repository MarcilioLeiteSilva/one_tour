export interface HouseAd {
  id: string;
  type: 'direct_sponsor' | 'cross_promotion';
  title: string;
  subtitle: string;
  tag: string;
  imageUrl: string;
  actionLabel: string;
  targetUrl: string;
  targetUf: string;       // App UF being displayed on
  targetCities?: string[]; // Specific cities or null for statewide
  position: 'home_card' | 'attraction_banner' | 'interstitial';
  priority: number;
  active: boolean;
}

export const CAMPAIGNS: HouseAd[] = [
  // 1. Cross-Promotion: PE -> Tour Paraíba (Vizinho imediato)
  {
    id: 'cross_pb_litoral',
    type: 'cross_promotion',
    title: 'Conheça o App Tour Paraíba',
    subtitle: 'Explore as praias de Tambaú, Cabo Branco e o Centro Histórico de João Pessoa.',
    tag: 'REDE ONE TOUR • VIZINHO',
    imageUrl: 'https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=800&q=80',
    actionLabel: 'Baixar App Grátis',
    targetUrl: 'https://onetour.app/pb',
    targetUf: 'PE',
    position: 'attraction_banner',
    priority: 10,
    active: true,
  },
  // 2. Cross-Promotion: PE -> Tour Alagoas (Caribe Brasileiro)
  {
    id: 'cross_al_maragogi',
    type: 'cross_promotion',
    title: 'Viaje para Alagoas • Tour Alagoas',
    subtitle: 'Galés de Maragogi e as águas mornas de São Miguel dos Milagres 100% offline.',
    tag: 'REDE ONE TOUR • ALAGOAS',
    imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80',
    actionLabel: 'Abrir Guia de Alagoas',
    targetUrl: 'https://onetour.app/al',
    targetUf: 'PE',
    position: 'attraction_banner',
    priority: 8,
    active: true,
  },
  // 3. Patrocinador Local Direto: Catamarã Recife & Olinda
  {
    id: 'sponsor_catamara_recife',
    type: 'direct_sponsor',
    title: 'Passeio de Catamarã pelos Rios do Recife',
    subtitle: 'Navegue sob as pontes históricas do Capibaribe com guia ao vivo e pôr do sol.',
    tag: 'EXPERIÊNCIA RECOMENDADA',
    imageUrl: 'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?auto=format&fit=crop&w=800&q=80',
    actionLabel: 'Reservar com 15% OFF',
    targetUrl: 'https://catamarantours.com.br?ref=onetour_pe',
    targetUf: 'PE',
    targetCities: ['recife', 'olinda'],
    position: 'home_card',
    priority: 20,
    active: true,
  },
  // 4. Patrocinador Local Direto: Pousada Tabapitanga em Porto de Galinhas
  {
    id: 'sponsor_pousada_porto',
    type: 'direct_sponsor',
    title: 'Pousada Pé na Areia • Porto de Galinhas',
    subtitle: 'Piscinas naturais na porta do quarto, café da manhã regional e transfer.',
    tag: 'ONDE SE HOSPEDAR',
    imageUrl: 'https://images.unsplash.com/photo-1582650625119-3a31f8418b7d?auto=format&fit=crop&w=800&q=80',
    actionLabel: 'Ver Tarifas Especiais',
    targetUrl: 'https://tabapitanga.com.br?ref=onetour_pe',
    targetUf: 'PE',
    targetCities: ['porto_de_galinhas'],
    position: 'home_card',
    priority: 25,
    active: true,
  },
  // 5. Intersticial Suave: Exibido ao Salvar/Exportar Roteiro
  {
    id: 'interstitial_seguro_viagem',
    type: 'direct_sponsor',
    title: 'Seu Roteiro está Pronto!',
    subtitle: 'Viaje tranquilo pelo Nordeste com assistência médica 24h e cobertura de bagagem.',
    tag: 'PARCEIRO OFICIAL ONE TOUR',
    imageUrl: 'https://images.unsplash.com/photo-1488646953014-85cb44e25828?auto=format&fit=crop&w=800&q=80',
    actionLabel: 'Cotar Seguro Viagem',
    targetUrl: 'https://seguro.onetour.app?ref=export_trip',
    targetUf: 'PE',
    position: 'interstitial',
    priority: 15,
    active: true,
  }
];

export function getMatchingAds(params: {
  uf: string;
  city?: string;
  position?: string;
  limit?: number;
}): HouseAd[] {
  const { uf, city, position, limit = 5 } = params;
  const normalizedUf = uf.toUpperCase();

  const filtered = CAMPAIGNS.filter((ad) => {
    if (!ad.active) return false;
    if (ad.targetUf !== normalizedUf) return false;
    if (position && ad.position !== position) return false;
    if (city && ad.targetCities && ad.targetCities.length > 0) {
      const normalizedCity = city.toLowerCase().trim();
      const match = ad.targetCities.some((c) => normalizedCity.includes(c) || c.includes(normalizedCity));
      if (!match) return false;
    }
    return true;
  });

  filtered.sort((a, b) => b.priority - a.priority);
  return filtered.slice(0, limit);
}
