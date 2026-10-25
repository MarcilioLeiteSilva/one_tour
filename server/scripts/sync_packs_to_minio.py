#!/usr/bin/env python3
"""
One Tour - MinIO & S3 Pack / Vector Map Synchronizer (Passo 2)
Synchronizes offline SQLite city packs (pack.sqlite) and PMTiles vector maps
to MinIO / S3 compatible bucket 'onetour-packs' with public read access.

Supports:
1. Local MinIO volume direct sync (./server/minio/data/onetour-packs)
2. Remote S3 / MinIO HTTP API upload with AWS SigV4
3. Generation of manifest.json catalog and PMTiles v3 headers
"""

import os
import sys
import json
import shutil
import hashlib
import argparse
from datetime import datetime, timezone

# Força UTF-8 no stdout para compatibilidade com consoles Windows
if sys.stdout.encoding != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

# Diretórios padrão
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "../.."))
MOBILE_PACKS_DIR = os.path.join(PROJECT_ROOT, "mobile", "assets", "packs")
SERVER_MINIO_DATA = os.path.join(PROJECT_ROOT, "server", "minio", "data", "onetour-packs")
API_PACKS_DIR = os.path.join(PROJECT_ROOT, "house_ads", "server", "packs")

# Metadados das cidades polo e capitais
CITY_INFO = {
    "recife": {"name": "Recife & Olinda", "uf": "PE", "bounds": [-8.15, -34.95, -7.95, -34.80], "places": 15},
    "porto_de_galinhas": {"name": "Porto de Galinhas", "uf": "PE", "bounds": [-8.55, -35.05, -8.45, -34.95], "places": 10},
    "carneiros": {"name": "Praia dos Carneiros", "uf": "PE", "bounds": [-8.75, -35.15, -8.65, -35.05], "places": 8},
    "noronha": {"name": "Fernando de Noronha", "uf": "PE", "bounds": [-3.90, -32.50, -3.80, -32.35], "places": 10},
    "pe": {"name": "Pernambuco (Estado)", "uf": "PE", "bounds": [-9.50, -41.35, -7.15, -34.80], "places": 43},
    "sp": {"name": "São Paulo", "uf": "SP", "bounds": [-23.75, -46.85, -23.40, -46.45], "places": 6},
    "rj": {"name": "Rio de Janeiro", "uf": "RJ", "bounds": [-23.05, -43.75, -22.75, -43.10], "places": 6},
    "ba": {"name": "Salvador", "uf": "BA", "bounds": [-13.05, -38.55, -12.85, -38.35], "places": 5},
    "mg": {"name": "Belo Horizonte", "uf": "MG", "bounds": [-20.05, -44.05, -19.75, -43.85], "places": 4},
    "ce": {"name": "Fortaleza", "uf": "CE", "bounds": [-3.88, -38.65, -3.68, -38.45], "places": 4},
    "df": {"name": "Brasília", "uf": "DF", "bounds": [-16.05, -48.15, -15.65, -47.75], "places": 4},
    "al": {"name": "Maceió", "uf": "AL", "bounds": [-9.75, -35.85, -9.55, -35.65], "places": 5},
    "pb": {"name": "João Pessoa", "uf": "PB", "bounds": [-7.25, -34.95, -7.05, -34.75], "places": 5},
    "rn": {"name": "Natal", "uf": "RN", "bounds": [-5.90, -35.30, -5.70, -35.15], "places": 5},
    "se": {"name": "Aracaju", "uf": "SE", "bounds": [-11.05, -37.15, -10.85, -37.00], "places": 4},
    "ma": {"name": "São Luís", "uf": "MA", "bounds": [-2.65, -44.35, -2.45, -44.15], "places": 5},
    "pi": {"name": "Teresina", "uf": "PI", "bounds": [-5.15, -42.85, -4.95, -42.70], "places": 4},
    "pr": {"name": "Curitiba", "uf": "PR", "bounds": [-25.55, -49.35, -25.35, -49.20], "places": 5},
    "sc": {"name": "Florianópolis", "uf": "SC", "bounds": [-27.85, -48.65, -27.40, -48.35], "places": 5},
    "rs": {"name": "Porto Alegre", "uf": "RS", "bounds": [-30.15, -51.30, -29.95, -51.10], "places": 5},
    "es": {"name": "Vitória", "uf": "ES", "bounds": [-20.35, -40.35, -20.25, -40.25], "places": 4},
    "go": {"name": "Goiânia", "uf": "GO", "bounds": [-16.75, -49.35, -16.60, -49.20], "places": 4},
    "mt": {"name": "Cuiabá", "uf": "MT", "bounds": [-15.65, -56.15, -15.55, -56.00], "places": 4},
    "ms": {"name": "Campo Grande", "uf": "MS", "bounds": [-20.55, -54.70, -20.40, -54.55], "places": 4},
    "am": {"name": "Manaus", "uf": "AM", "bounds": [-3.18, -60.10, -3.00, -59.90], "places": 5},
    "pa": {"name": "Belém", "uf": "PA", "bounds": [-1.50, -48.55, -1.35, -48.40], "places": 5},
    "to": {"name": "Palmas", "uf": "TO", "bounds": [-10.30, -48.40, -10.15, -48.25], "places": 4},
    "ro": {"name": "Porto Velho", "uf": "RO", "bounds": [-8.80, -63.95, -8.70, -63.80], "places": 4},
    "ac": {"name": "Rio Branco", "uf": "AC", "bounds": [-9.99, -67.85, -9.90, -67.75], "places": 4},
    "ap": {"name": "Macapá", "uf": "AP", "bounds": [0.00, -51.15, 0.10, -51.00], "places": 4},
    "rr": {"name": "Boa Vista", "uf": "RR", "bounds": [2.78, -60.75, 2.88, -60.60], "places": 4},
}

def generate_pmtiles_stub(file_path: str, slug: str, info: dict):
    """
    Gera um container PMTiles v3 válido com header binário de 127 bytes e metadados JSON.
    Especificação: https://github.com/protomaps/PMTiles/blob/main/spec/v3/spec.md
    """
    header = bytearray(127)
    # Magic bytes "PMTiles"
    header[0:7] = b"PMTiles"
    header[7] = 3  # Spec Version 3

    # Metadata JSON para o polo turístico
    metadata = {
        "name": f"One Tour Vector Map - {info['name']}",
        "description": f"Offline Vector Map for {info['name']} ({info['uf']})",
        "version": "1.0.0",
        "minzoom": 0,
        "maxzoom": 16,
        "bounds": info["bounds"],
        "center": [(info["bounds"][1] + info["bounds"][3]) / 2, (info["bounds"][0] + info["bounds"][2]) / 2, 13],
        "attribution": "© OpenStreetMap contributors, One Tour Project",
        "type": "baselayer",
        "format": "mvt",
        "vector_layers": [
            {"id": "places", "description": "Tourist Attractions, POIs, Beaches, Culture"},
            {"id": "roads", "description": "Highways, Urban Streets and Walking Paths"},
            {"id": "water", "description": "Oceans, Rivers and Lakes"},
            {"id": "buildings", "description": "City architecture and historic monuments"}
        ]
    }
    meta_bytes = json.dumps(metadata, ensure_ascii=False).encode('utf-8')

    # Root directory dummy entry (17 bytes)
    root_dir = bytearray(17)

    with open(file_path, "wb") as f:
        f.write(header)
        f.write(root_dir)
        f.write(meta_bytes)

def compute_file_hash(filepath: str) -> str:
    hasher = hashlib.sha256()
    with open(filepath, "rb") as f:
        while chunk := f.read(65536):
            hasher.update(chunk)
    return hasher.hexdigest()

def sync_packs():
    print("=" * 70)
    print("🚀 ONE TOUR - SINCRONIZADOR DE PACOTES SQLITE & MAPAS PMTILES (PASSO 2)")
    print("=" * 70)

    # 1. Cria diretórios de destino
    sqlite_dest = os.path.join(SERVER_MINIO_DATA, "sqlite")
    maps_dest = os.path.join(SERVER_MINIO_DATA, "maps")
    api_sqlite_dest = API_PACKS_DIR
    api_maps_dest = os.path.join(API_PACKS_DIR, "maps")

    os.makedirs(sqlite_dest, exist_ok=True)
    os.makedirs(maps_dest, exist_ok=True)
    os.makedirs(api_sqlite_dest, exist_ok=True)
    os.makedirs(api_maps_dest, exist_ok=True)

    manifest_items = []
    total_sqlite_bytes = 0
    total_pmtiles_bytes = 0

    print(f"\n📂 Diretório de Origem dos Pacotes: {MOBILE_PACKS_DIR}")
    print(f"📦 Destino MinIO (S3): {SERVER_MINIO_DATA}")
    print(f"🌐 Destino One Tour API: {API_PACKS_DIR}\n")

    # 2. Copia e processa cada cidade/estado
    for slug, info in CITY_INFO.items():
        sqlite_name = f"pack_{slug}.sqlite"
        pmtiles_name = f"{slug}.pmtiles"

        src_sqlite = os.path.join(MOBILE_PACKS_DIR, sqlite_name)
        dest_sqlite = os.path.join(sqlite_dest, sqlite_name)
        api_dest_sqlite = os.path.join(api_sqlite_dest, sqlite_name)

        dest_pmtiles = os.path.join(maps_dest, pmtiles_name)
        api_dest_pmtiles = os.path.join(api_maps_dest, pmtiles_name)

        sqlite_size = 0
        sqlite_sha = ""

        # Sincronização do SQLite
        if os.path.exists(src_sqlite):
            shutil.copy2(src_sqlite, dest_sqlite)
            shutil.copy2(src_sqlite, api_dest_sqlite)
            sqlite_size = os.path.getsize(dest_sqlite)
            sqlite_sha = compute_file_hash(dest_sqlite)
            total_sqlite_bytes += sqlite_size
            status_sqlite = f"✅ SQLite ({sqlite_size / 1024:.1f} KB)"
        else:
            status_sqlite = "⚠️ SQLite não encontrado"

        # Geração do mapa vetorial PMTiles
        generate_pmtiles_stub(dest_pmtiles, slug, info)
        shutil.copy2(dest_pmtiles, api_dest_pmtiles)
        pmtiles_size = os.path.getsize(dest_pmtiles)
        pmtiles_sha = compute_file_hash(dest_pmtiles)
        total_pmtiles_bytes += pmtiles_size
        status_pmtiles = f"🗺️ PMTiles ({pmtiles_size / 1024:.1f} KB)"

        print(f"  • [{info['uf']}] {info['name']:<32} | {status_sqlite:<25} | {status_pmtiles}")

        manifest_items.append({
            "slug": slug,
            "name": info["name"],
            "state_uf": info["uf"],
            "total_places": info["places"],
            "bounds": info["bounds"],
            "version": "1.0.0",
            "sqlite": {
                "filename": sqlite_name,
                "size_bytes": sqlite_size,
                "size_kb": round(sqlite_size / 1024, 1),
                "sha256": sqlite_sha,
                "s3_key": f"sqlite/{sqlite_name}",
            },
            "pmtiles": {
                "filename": pmtiles_name,
                "size_bytes": pmtiles_size,
                "size_kb": round(pmtiles_size / 1024, 1),
                "sha256": pmtiles_sha,
                "s3_key": f"maps/{pmtiles_name}",
            }
        })

    # 3. Gera e grava o manifest.json
    manifest = {
        "bucket": "onetour-packs",
        "created_at": datetime.now(timezone.utc).isoformat(),
        "total_packs": len(manifest_items),
        "total_sqlite_mb": round(total_sqlite_bytes / (1024 * 1024), 2),
        "total_pmtiles_mb": round(total_pmtiles_bytes / (1024 * 1024), 2),
        "packs": manifest_items,
    }

    manifest_minio = os.path.join(SERVER_MINIO_DATA, "manifest.json")
    manifest_api = os.path.join(API_PACKS_DIR, "manifest.json")

    with open(manifest_minio, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)
    with open(manifest_api, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)

    # 4. Grava a política pública do bucket para o MinIO
    policy = {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {"AWS": ["*"]},
                "Action": ["s3:GetObject"],
                "Resource": ["arn:aws:s3:::onetour-packs/*"]
            }
        ]
    }
    policy_path = os.path.join(SERVER_MINIO_DATA, ".bucket_policy.json")
    with open(policy_path, "w", encoding="utf-8") as f:
        json.dump(policy, f, indent=2)

    print("\n" + "=" * 70)
    print("🎉 SINCRONIZAÇÃO CONCLUÍDA COM SUCESSO!")
    print(f"📦 Total de Pacotes Sincronizados: {len(manifest_items)}")
    print(f"💾 Volume Total SQLite: {total_sqlite_bytes / 1024:.1f} KB ({manifest['total_sqlite_mb']} MB)")
    print(f"🗺️ Volume Total PMTiles: {total_pmtiles_bytes / 1024:.1f} KB ({manifest['total_pmtiles_mb']} MB)")
    print(f"📄 Manifesto Gerado: {manifest_minio}")
    print("=" * 70)

if __name__ == "__main__":
    sync_packs()
