-- ==============================================================================
-- One Tour API - Migração 001: esquema central
-- Telemetria de anúncios, interações sociais, estatísticas de lugares e push.
-- Idempotente: pode ser reexecutada com segurança.
-- ==============================================================================

-- PostGIS é opcional nesta etapa. Se o usuário não tiver permissão, segue sem ele.
DO $$
BEGIN
  CREATE EXTENSION IF NOT EXISTS postgis;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'PostGIS não habilitado (%). Consultas espaciais ficarão indisponíveis.', SQLERRM;
END $$;

-- ------------------------------------------------------------------------------
-- Dispositivos (identidade anônima gerada pelo app)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS devices (
    device_id    VARCHAR(128) PRIMARY KEY,
    platform     VARCHAR(16),
    app_uf       VARCHAR(2),
    app_version  VARCHAR(32),
    first_seen   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_seen    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- Telemetria de anúncios (House Ads)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ad_impressions (
    id          BIGSERIAL PRIMARY KEY,
    ad_id       VARCHAR(64) NOT NULL,
    uf          VARCHAR(2)  NOT NULL,
    city_slug   VARCHAR(64),
    position    VARCHAR(32) NOT NULL,
    device_id   VARCHAR(128),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ad_clicks (
    id          BIGSERIAL PRIMARY KEY,
    ad_id       VARCHAR(64) NOT NULL,
    uf          VARCHAR(2)  NOT NULL,
    city_slug   VARCHAR(64),
    position    VARCHAR(32) NOT NULL,
    device_id   VARCHAR(128),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_impressions_ad_time ON ad_impressions (ad_id, created_at);
CREATE INDEX IF NOT EXISTS idx_impressions_uf_city ON ad_impressions (uf, city_slug);
CREATE INDEX IF NOT EXISTS idx_clicks_ad_time      ON ad_clicks (ad_id, created_at);
CREATE INDEX IF NOT EXISTS idx_clicks_uf_city      ON ad_clicks (uf, city_slug);

-- CTR por anúncio: contagens agregadas separadamente (evita JOIN caro entre eventos).
DROP VIEW IF EXISTS view_ad_performance;
CREATE VIEW view_ad_performance AS
SELECT
    i.ad_id,
    i.uf,
    i.position,
    i.impressions_count,
    COALESCE(c.clicks_count, 0) AS clicks_count,
    ROUND(COALESCE(c.clicks_count, 0)::numeric / NULLIF(i.impressions_count, 0) * 100, 2) AS ctr_percentage
FROM (
    SELECT ad_id, uf, position, COUNT(*) AS impressions_count
    FROM ad_impressions
    GROUP BY ad_id, uf, position
) i
LEFT JOIN (
    SELECT ad_id, uf, position, COUNT(*) AS clicks_count
    FROM ad_clicks
    GROUP BY ad_id, uf, position
) c ON c.ad_id = i.ad_id AND c.uf = i.uf AND c.position = i.position;

-- ------------------------------------------------------------------------------
-- Interações sociais (um registro por dispositivo e lugar => idempotente offline)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS place_likes (
    place_id    VARCHAR(64)  NOT NULL,
    device_id   VARCHAR(128) NOT NULL,
    uf          VARCHAR(2)   NOT NULL,
    city_slug   VARCHAR(64)  NOT NULL DEFAULT '',
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    PRIMARY KEY (place_id, device_id)
);

CREATE TABLE IF NOT EXISTS place_reviews (
    place_id    VARCHAR(64)  NOT NULL,
    device_id   VARCHAR(128) NOT NULL,
    uf          VARCHAR(2)   NOT NULL,
    city_slug   VARCHAR(64)  NOT NULL DEFAULT '',
    stars       SMALLINT     NOT NULL CHECK (stars BETWEEN 1 AND 5),
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    hidden      BOOLEAN      NOT NULL DEFAULT FALSE,
    PRIMARY KEY (place_id, device_id)
);

CREATE INDEX IF NOT EXISTS idx_place_likes_uf   ON place_likes (uf, city_slug);
CREATE INDEX IF NOT EXISTS idx_place_reviews_uf ON place_reviews (uf, city_slug);

-- ------------------------------------------------------------------------------
-- Estatísticas consolidadas por lugar (lidas pelo app e pelo admin)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS place_stats (
    place_id         VARCHAR(64) PRIMARY KEY,
    uf               VARCHAR(2)  NOT NULL,
    city_slug        VARCHAR(64) NOT NULL DEFAULT '',
    likes_count      INTEGER     NOT NULL DEFAULT 0,
    rating_avg       NUMERIC(3,2) NOT NULL DEFAULT 0,
    rating_count     INTEGER     NOT NULL DEFAULT 0,
    editorial_weight NUMERIC(3,2) NOT NULL DEFAULT 3.00 CHECK (editorial_weight BETWEEN 0 AND 5),
    score            NUMERIC(6,3) NOT NULL DEFAULT 0,
    rank_state       INTEGER,
    rank_city        INTEGER,
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_place_stats_rank ON place_stats (uf, city_slug, score DESC);

-- ------------------------------------------------------------------------------
-- Histórico de notificações push enviadas pelo admin
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS push_log (
    id          BIGSERIAL PRIMARY KEY,
    topic       VARCHAR(128) NOT NULL,
    title       VARCHAR(200) NOT NULL,
    body        TEXT         NOT NULL,
    data        JSONB,
    status      VARCHAR(16)  NOT NULL DEFAULT 'pending', -- pending | sent | failed
    error       TEXT,
    sent_by     VARCHAR(128),
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
