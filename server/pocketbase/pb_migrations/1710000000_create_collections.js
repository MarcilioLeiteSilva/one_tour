/// <reference path="../pb_data/types.d.ts" />
migrate((db) => {
  const Dao = new Dao(db);

  // 1. Coleção: estados
  const estados = new Collection({
    name: "estados",
    type: "base",
    listRule: "@request.auth.id != '' || true",
    viewRule: "@request.auth.id != '' || true",
    createRule: "@request.auth.id != ''",
    updateRule: "@request.auth.id != ''",
    deleteRule: "@request.auth.id != ''",
    schema: [
      { name: "sigla", type: "text", required: true, unique: true },
      { name: "nome", type: "text", required: true },
      { name: "status", type: "select", options: { values: ["ativo", "em_breve"] }, required: true },
      { name: "versao_pacote", type: "number" }
    ]
  });
  Dao.saveCollection(estados);

  // 2. Coleção: cidades
  const cidades = new Collection({
    name: "cidades",
    type: "base",
    listRule: "@request.auth.id != '' || true",
    viewRule: "@request.auth.id != '' || true",
    createRule: "@request.auth.id != ''",
    updateRule: "@request.auth.id != ''",
    deleteRule: "@request.auth.id != ''",
    schema: [
      { name: "nome", type: "text", required: true },
      { name: "slug", type: "text", required: true, unique: true },
      { name: "estado_sigla", type: "text", required: true },
      { name: "tag", type: "text" },
      { name: "lat", type: "number" },
      { name: "lon", type: "number" },
      { name: "package_size", type: "text" },
      { name: "destaque", type: "bool" },
      { name: "descricao_pt", type: "text" },
      { name: "descricao_en", type: "text" }
    ]
  });
  Dao.saveCollection(cidades);

  // 3. Coleção: atracoes
  const atracoes = new Collection({
    name: "atracoes",
    type: "base",
    listRule: "@request.auth.id != '' || true",
    viewRule: "@request.auth.id != '' || true",
    createRule: "@request.auth.id != ''",
    updateRule: "@request.auth.id != ''",
    deleteRule: "@request.auth.id != ''",
    schema: [
      { name: "nome", type: "text", required: true },
      { name: "slug", type: "text", required: true },
      { name: "cidade_slug", type: "text", required: true },
      { name: "uf", type: "text", required: true },
      { name: "categoria", type: "select", options: { values: ["Praias", "Cultura", "Gastronomia", "Ecoturismo", "Noite"] }, required: true },
      { name: "horario", type: "text" },
      { name: "duracao_min", type: "number" },
      { name: "gratuito", type: "bool" },
      { name: "kid_friendly", type: "bool" },
      { name: "must_see", type: "bool" },
      { name: "is_lunch", type: "bool" },
      { name: "rating_avg", type: "number" },
      { name: "rating_count", type: "number" },
      { name: "likes_count", type: "number" },
      { name: "rank_posicao", type: "number" },
      { name: "score", type: "number" },
      { name: "lat", type: "number" },
      { name: "lon", type: "number" },
      { name: "descricao_pt", type: "text" },
      { name: "descricao_en", type: "text" }
    ]
  });
  Dao.saveCollection(atracoes);

  // 4. Coleção: campanhas_ads (House Ads Network)
  const campanhasAds = new Collection({
    name: "campanhas_ads",
    type: "base",
    listRule: "@request.auth.id != '' || true",
    viewRule: "@request.auth.id != '' || true",
    createRule: "@request.auth.id != ''",
    updateRule: "@request.auth.id != ''",
    deleteRule: "@request.auth.id != ''",
    schema: [
      { name: "titulo", type: "text", required: true },
      { name: "link_destino", type: "url", required: true },
      { name: "uf_alvo", type: "text", required: true },
      { name: "cidade_alvo", type: "text" },
      { name: "posicao", type: "select", options: { values: ["home_card", "attraction_banner", "interstitial"] }, required: true },
      { name: "ativo", type: "bool" },
      { name: "prioridade", type: "number" },
      { name: "data_inicio", type: "date" },
      { name: "data_fim", type: "date" }
    ]
  });
  Dao.saveCollection(campanhasAds);
}, (db) => {
  const Dao = new Dao(db);
  const collections = ["campanhas_ads", "atracoes", "cidades", "estados"];
  for (const name of collections) {
    try {
      const col = Dao.findCollectionByNameOrId(name);
      if (col) Dao.deleteCollection(col);
    } catch (_) {}
  }
});
