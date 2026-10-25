import { Router, Request, Response } from 'express';
import path from 'path';
import fs from 'fs';

export const packsRouter = Router();

// Diretório base dos pacotes (pode ser customizado via PACKS_DIR ou busca em pastas padrão)
function getPacksDirectory(): string {
  if (process.env.PACKS_DIR && fs.existsSync(process.env.PACKS_DIR)) {
    return path.resolve(process.env.PACKS_DIR);
  }
  const localPacks = path.resolve(process.cwd(), 'packs');
  if (fs.existsSync(localPacks)) {
    return localPacks;
  }
  const mobilePacks = path.resolve(process.cwd(), '../../mobile/assets/packs');
  if (fs.existsSync(mobilePacks)) {
    return mobilePacks;
  }
  return localPacks;
}

function getMapsDirectory(): string {
  if (process.env.MAPS_DIR && fs.existsSync(process.env.MAPS_DIR)) {
    return path.resolve(process.env.MAPS_DIR);
  }
  const localMaps = path.resolve(process.cwd(), 'maps');
  if (fs.existsSync(localMaps)) {
    return localMaps;
  }
  const localPacks = getPacksDirectory();
  const packsMaps = path.resolve(localPacks, 'maps');
  if (fs.existsSync(packsMaps)) {
    return packsMaps;
  }
  return localMaps;
}

interface CityPackInfo {
  slug: string;
  name: string;
  stateUf: string;
  sqliteFilename: string;
  sqliteSizeKb: number;
  sqliteDownloadUrl: string;
  pmtilesFilename: string;
  pmtilesSizeKb: number;
  pmtilesDownloadUrl: string;
  version: string;
  totalPlaces: number;
}

const CITY_METADATA: Record<string, { name: string; uf: string; places: number }> = {
  recife: { name: 'Recife & Olinda', uf: 'PE', places: 15 },
  porto_de_galinhas: { name: 'Porto de Galinhas', uf: 'PE', places: 10 },
  carneiros: { name: 'Praia dos Carneiros', uf: 'PE', places: 8 },
  noronha: { name: 'Fernando de Noronha', uf: 'PE', places: 10 },
  pe: { name: 'Pernambuco (Estado Completo)', uf: 'PE', places: 43 },
  sp: { name: 'São Paulo', uf: 'SP', places: 6 },
  rj: { name: 'Rio de Janeiro', uf: 'RJ', places: 6 },
  ba: { name: 'Salvador', uf: 'BA', places: 5 },
  mg: { name: 'Belo Horizonte', uf: 'MG', places: 4 },
  ce: { name: 'Fortaleza', uf: 'CE', places: 4 },
  df: { name: 'Brasília', uf: 'DF', places: 4 },
  al: { name: 'Maceió', uf: 'AL', places: 5 },
  pb: { name: 'João Pessoa', uf: 'PB', places: 5 },
  rn: { name: 'Natal', uf: 'RN', places: 5 },
  se: { name: 'Aracaju', uf: 'SE', places: 4 },
  ma: { name: 'São Luís', uf: 'MA', places: 5 },
  pi: { name: 'Teresina', uf: 'PI', places: 4 },
  pr: { name: 'Curitiba', uf: 'PR', places: 5 },
  sc: { name: 'Florianópolis', uf: 'SC', places: 5 },
  rs: { name: 'Porto Alegre', uf: 'RS', places: 5 },
  es: { name: 'Vitória', uf: 'ES', places: 4 },
  go: { name: 'Goiânia', uf: 'GO', places: 4 },
  mt: { name: 'Cuiabá', uf: 'MT', places: 4 },
  ms: { name: 'Campo Grande', uf: 'MS', places: 4 },
  am: { name: 'Manaus', uf: 'AM', places: 5 },
  pa: { name: 'Belém', uf: 'PA', places: 5 },
  to: { name: 'Palmas', uf: 'TO', places: 4 },
  ro: { name: 'Porto Velho', uf: 'RO', places: 4 },
  ac: { name: 'Rio Branco', uf: 'AC', places: 4 },
  ap: { name: 'Macapá', uf: 'AP', places: 4 },
  rr: { name: 'Boa Vista', uf: 'RR', places: 4 },
};

/**
 * GET /api/v1/packs/catalog
 * Retorna o catálogo de todos os pacotes SQLite e Mapas PMTiles disponíveis
 */
packsRouter.get('/catalog', (req: Request, res: Response) => {
  const ufFilter = (req.query.uf as string)?.toUpperCase();
  const cdnBase = process.env.CDN_BASE_URL || `${req.protocol}://${req.get('host')}`;
  const packsDir = getPacksDirectory();
  const mapsDir = getMapsDirectory();

  const items: CityPackInfo[] = [];

  for (const [slug, meta] of Object.entries(CITY_METADATA)) {
    if (ufFilter && meta.uf !== ufFilter) continue;

    const sqliteFilename = `pack_${slug}.sqlite`;
    const sqlitePath = path.join(packsDir, sqliteFilename);
    const sqliteSize = fs.existsSync(sqlitePath) ? Math.round(fs.statSync(sqlitePath).size / 1024) : 48;

    const pmtilesFilename = `${slug}.pmtiles`;
    const pmtilesPath = path.join(mapsDir, pmtilesFilename);
    const pmtilesSize = fs.existsSync(pmtilesPath) ? Math.round(fs.statSync(pmtilesPath).size / 1024) : 256;

    items.push({
      slug,
      name: meta.name,
      stateUf: meta.uf,
      sqliteFilename,
      sqliteSizeKb: sqliteSize,
      sqliteDownloadUrl: `${cdnBase}/api/v1/packs/download/${slug}`,
      pmtilesFilename,
      pmtilesSizeKb: pmtilesSize,
      pmtilesDownloadUrl: `${cdnBase}/api/v1/packs/maps/download/${slug}`,
      version: '1.0.0',
      totalPlaces: meta.places,
    });
  }

  res.json({
    success: true,
    count: items.length,
    cdnBase,
    data: items,
  });
});

/**
 * GET /api/v1/packs/download/:slug
 * Faz download do arquivo pack_<slug>.sqlite
 */
packsRouter.get('/download/:slug', (req: Request, res: Response): void => {
  const rawSlug = Array.isArray(req.params.slug) ? req.params.slug[0] : req.params.slug;
  const slug = (rawSlug || '').toLowerCase().trim();
  const filename = `pack_${slug}.sqlite`;
  const packsDir = getPacksDirectory();
  const filePath = path.join(packsDir, filename);

  // Se houver CDN externa configurada (ex: MinIO público ou Cloudflare R2), redireciona
  if (process.env.MINIO_PUBLIC_URL || process.env.S3_PACKS_URL) {
    const s3Url = `${process.env.MINIO_PUBLIC_URL || process.env.S3_PACKS_URL}/sqlite/${filename}`;
    res.redirect(302, s3Url);
    return;
  }

  if (!fs.existsSync(filePath)) {
    res.status(404).json({
      error: 'Pacote SQLite não encontrado',
      slug,
      expectedFilename: filename,
    });
    return;
  }

  res.setHeader('Content-Type', 'application/vnd.sqlite3');
  res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
  res.setHeader('Cache-Control', 'public, max-age=86400'); // Cache 24h
  res.sendFile(filePath);
});

/**
 * GET /api/v1/packs/maps/download/:slug
 * Faz download ou streaming do arquivo vetorial <slug>.pmtiles (com suporte a Range Requests)
 */
packsRouter.get('/maps/download/:slug', (req: Request, res: Response): void => {
  const rawSlug = Array.isArray(req.params.slug) ? req.params.slug[0] : req.params.slug;
  const slug = (rawSlug || '').toLowerCase().trim();
  const filename = `${slug}.pmtiles`;
  const mapsDir = getMapsDirectory();
  const filePath = path.join(mapsDir, filename);

  // Se houver CDN externa configurada (ex: MinIO público ou Cloudflare R2), redireciona
  if (process.env.MINIO_PUBLIC_URL || process.env.S3_PACKS_URL) {
    const s3Url = `${process.env.MINIO_PUBLIC_URL || process.env.S3_PACKS_URL}/maps/${filename}`;
    res.redirect(302, s3Url);
    return;
  }

  if (!fs.existsSync(filePath)) {
    // Se não existir arquivo específico de mapa, cria resposta simulada válida ou 404 informativo
    res.status(404).json({
      error: 'Mapa vetorial PMTiles não encontrado para o polo selecionado',
      slug,
      expectedFilename: filename,
    });
    return;
  }

  res.setHeader('Content-Type', 'application/octet-stream');
  res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
  res.setHeader('Cache-Control', 'public, max-age=604800'); // Cache 7 dias
  // sendFile nativo do Express com acceptRanges: true suporta Range Requests (essencial para PMTiles)
  res.sendFile(filePath, { acceptRanges: true });
});
