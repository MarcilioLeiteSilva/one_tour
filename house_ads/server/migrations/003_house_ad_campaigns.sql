-- ------------------------------------------------------------------------------
-- Migração 003: Tabela de Campanhas Dinâmicas da Rede House Ads
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS house_ad_campaigns (
    id             VARCHAR(64)  PRIMARY KEY,
    type           VARCHAR(32)  NOT NULL DEFAULT 'direct_sponsor', -- direct_sponsor | cross_promotion
    title          VARCHAR(255) NOT NULL,
    subtitle       TEXT         NOT NULL DEFAULT '',
    tag            VARCHAR(64)  NOT NULL DEFAULT 'PATROCINADO',
    image_url      TEXT         NOT NULL,
    action_label   VARCHAR(64)  NOT NULL DEFAULT 'Saiba Mais',
    target_url     TEXT         NOT NULL,
    target_uf      VARCHAR(2)   NOT NULL,                          -- PE, AL, PB, etc. ou 'ALL'
    target_cities  TEXT[]       DEFAULT '{}',                      -- ex: {'recife', 'porto_de_galinhas'}
    position       VARCHAR(32)  NOT NULL,                          -- home_card | attraction_banner | itinerary_footer | interstitial
    priority       INTEGER      NOT NULL DEFAULT 10,               -- 1 a 100 (peso na alternância)
    active         BOOLEAN      NOT NULL DEFAULT TRUE,
    start_date     TIMESTAMPTZ  DEFAULT NOW(),
    end_date       TIMESTAMPTZ  DEFAULT NULL,
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_house_ads_target ON house_ad_campaigns (target_uf, position, active, priority DESC);

-- Seed das campanhas iniciais (Pernambuco e Alagoas)
INSERT INTO house_ad_campaigns (id, type, title, subtitle, tag, image_url, action_label, target_url, target_uf, target_cities, position, priority, active)
VALUES
(
    'cross_pb_litoral',
    'cross_promotion',
    'Conheça o App Tour Paraíba',
    'Explore as praias de Tambaú, Cabo Branco e o Centro Histórico de João Pessoa.',
    'REDE ONE TOUR • VIZINHO',
    'https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=800&q=80',
    'Baixar App Grátis',
    'https://onetour.app/pb',
    'PE',
    '{}',
    'attraction_banner',
    10,
    true
),
(
    'cross_al_maragogi',
    'cross_promotion',
    'Viaje para Alagoas • Tour Alagoas',
    'Galés de Maragogi e as águas mornas de São Miguel dos Milagres 100% offline.',
    'REDE ONE TOUR • ALAGOAS',
    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80',
    'Abrir Guia de Alagoas',
    'https://onetour.app/al',
    'PE',
    '{}',
    'attraction_banner',
    12,
    true
),
(
    'sponsor_catamara_recife',
    'direct_sponsor',
    'Passeio de Catamarã pelos Rios do Recife',
    'Navegue sob as pontes históricas do Capibaribe com guia ao vivo e pôr do sol.',
    'EXPERIÊNCIA RECOMENDADA',
    'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?auto=format&fit=crop&w=800&q=80',
    'Reservar com 15% OFF',
    'https://catamarantours.com.br?ref=onetour_pe',
    'PE',
    '{"recife", "olinda"}',
    'home_card',
    20,
    true
),
(
    'sponsor_pousada_porto',
    'direct_sponsor',
    'Pousada Pé na Areia • Porto de Galinhas',
    'Piscinas naturais na porta do quarto, café da manhã regional e transfer.',
    'ONDE SE HOSPEDAR',
    'https://images.unsplash.com/photo-1582650625119-3a31f8418b7d?auto=format&fit=crop&w=800&q=80',
    'Ver Tarifas Especiais',
    'https://tabapitanga.com.br?ref=onetour_pe',
    'PE',
    '{"porto_de_galinhas"}',
    'home_card',
    25,
    true
),
(
    'interstitial_seguro_viagem',
    'direct_sponsor',
    'Seu Roteiro está Pronto!',
    'Viaje tranquilo pelo Nordeste com assistência médica 24h e cobertura de bagagem.',
    'PARCEIRO OFICIAL ONE TOUR',
    'https://images.unsplash.com/photo-1488646953014-85cb44e25828?auto=format&fit=crop&w=800&q=80',
    'Cotar Seguro Viagem',
    'https://seguro.onetour.app?ref=export_trip',
    'PE',
    '{}',
    'interstitial',
    15,
    true
),
(
    'sponsor_jangada_maragogi',
    'direct_sponsor',
    'Passeio às Piscinas Naturais de Maragogi',
    'Reserve seu catamarã e jangada com hora marcada nas marés baixas.',
    'PASSEIO OBRIGATÓRIO',
    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80',
    'Reservar Passeio',
    'https://maragogitours.com.br?ref=onetour_al',
    'AL',
    '{"maragogi"}',
    'home_card',
    30,
    true
)
ON CONFLICT (id) DO NOTHING;
