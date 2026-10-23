-- ==============================================================================
-- One Tour Ecosystem - PostgreSQL 16 + PostGIS Initialization Script
-- ==============================================================================

-- 1. Habilitar Extensões
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==============================================================================
-- 2. Telemetria do Ad Server (House Ads Network)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS ad_impressions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ad_id VARCHAR(64) NOT NULL,
    uf VARCHAR(2) NOT NULL,
    city_slug VARCHAR(64),
    position VARCHAR(32) NOT NULL, -- 'home_card', 'attraction_banner', 'interstitial'
    device_id VARCHAR(128),
    ip_hash VARCHAR(64),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ad_clicks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ad_id VARCHAR(64) NOT NULL,
    uf VARCHAR(2) NOT NULL,
    city_slug VARCHAR(64),
    position VARCHAR(32) NOT NULL,
    device_id VARCHAR(128),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices de Alta Performance para Telemetria
CREATE INDEX IF NOT EXISTS idx_impressions_ad_time ON ad_impressions (ad_id, created_at);
CREATE INDEX IF NOT EXISTS idx_impressions_uf_city ON ad_impressions (uf, city_slug);
CREATE INDEX IF NOT EXISTS idx_clicks_ad_time ON ad_clicks (ad_id, created_at);
CREATE INDEX IF NOT EXISTS idx_clicks_uf_city ON ad_clicks (uf, city_slug);

-- ==============================================================================
-- 3. Telemetria Social Comunitária (Estrelas, Curtidas & Sincronização)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS social_ratings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    attraction_id VARCHAR(64) NOT NULL,
    uf VARCHAR(2) NOT NULL,
    city_slug VARCHAR(64) NOT NULL,
    stars SMALLINT NOT NULL CHECK (stars >= 1 AND stars <= 5),
    device_id VARCHAR(128),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS social_likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    attraction_id VARCHAR(64) NOT NULL,
    uf VARCHAR(2) NOT NULL,
    city_slug VARCHAR(64),
    device_id VARCHAR(128),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_social_ratings_attraction ON social_ratings (attraction_id);
CREATE INDEX IF NOT EXISTS idx_social_likes_attraction ON social_likes (attraction_id);

-- ==============================================================================
-- 4. Dados Espaciais para Consultas de Proximidade (PostGIS)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS spatial_pois (
    id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    uf VARCHAR(2) NOT NULL,
    city_slug VARCHAR(64) NOT NULL,
    category VARCHAR(64),
    geom GEOMETRY(Point, 4326) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_spatial_pois_geom ON spatial_pois USING GIST (geom);

-- ==============================================================================
-- 5. Views Analíticas em Tempo Real
-- ==============================================================================

-- Desempenho e CTR dos Anúncios
CREATE OR REPLACE VIEW view_ad_performance AS
SELECT 
    imp.ad_id,
    imp.uf,
    imp.position,
    COUNT(DISTINCT imp.id) AS impressions_count,
    COUNT(DISTINCT clk.id) AS clicks_count,
    ROUND(
        (COUNT(DISTINCT clk.id)::DECIMAL / NULLIF(COUNT(DISTINCT imp.id), 0)) * 100, 
        2
    ) AS ctr_percentage
FROM ad_impressions imp
LEFT JOIN ad_clicks clk 
    ON imp.ad_id = clk.ad_id 
    AND imp.device_id = clk.device_id 
    AND clk.created_at >= imp.created_at
GROUP BY imp.ad_id, imp.uf, imp.position;

-- Consolidação de Score Social por Atração
CREATE OR REPLACE VIEW view_attraction_social_score AS
SELECT 
    r.attraction_id,
    r.uf,
    r.city_slug,
    ROUND(AVG(r.stars), 1) AS rating_avg,
    COUNT(r.id) AS rating_count,
    COALESCE(l.likes_count, 0) AS likes_count,
    ROUND(
        (COALESCE(AVG(r.stars), 0) * 0.40) + 
        (LEAST(COALESCE(l.likes_count, 0), 1000) / 1000.0 * 5.0 * 0.30) + 
        (1.5), -- Peso editorial base
        2
    ) AS calculated_score
FROM social_ratings r
LEFT JOIN (
    SELECT attraction_id, COUNT(id) AS likes_count
    FROM social_likes
    GROUP BY attraction_id
) l ON r.attraction_id = l.attraction_id
GROUP BY r.attraction_id, r.uf, r.city_slug, l.likes_count;
