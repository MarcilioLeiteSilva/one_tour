-- ==============================================================================
-- Migração 002: tabela espacial de POIs (somente se o PostGIS estiver disponível)
-- ==============================================================================
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'postgis') THEN
    EXECUTE $sql$
      CREATE TABLE IF NOT EXISTS spatial_pois (
          id          VARCHAR(64) PRIMARY KEY,
          name        VARCHAR(255) NOT NULL,
          uf          VARCHAR(2)   NOT NULL,
          city_slug   VARCHAR(64)  NOT NULL,
          category    VARCHAR(64),
          geom        GEOMETRY(Point, 4326) NOT NULL,
          created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
      )
    $sql$;
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_spatial_pois_geom ON spatial_pois USING GIST (geom)';
  ELSE
    RAISE NOTICE 'PostGIS ausente: spatial_pois não criada.';
  END IF;
END $$;
