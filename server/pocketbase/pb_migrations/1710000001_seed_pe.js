/// <reference path="../pb_data/types.d.ts" />
migrate((db) => {
  const dao = new Dao(db);

  // 1. Inserir Estado PE
  const colEstados = dao.findCollectionByNameOrId("estados");
  const estadoPe = new Record(colEstados, {
    sigla: "PE",
    nome: "Pernambuco",
    status: "ativo",
    versao_pacote: 1
  });
  dao.saveRecord(estadoPe);

  // 2. Inserir Cidades Polo
  const colCidades = dao.findCollectionByNameOrId("cidades");
  const cidades = [
    { nome: "Recife", slug: "recife", estado_sigla: "PE", tag: "Capital Multicultural", lat: -8.0631, lon: -34.8711, package_size: "14 MB", destaque: true, descricao_pt: "Capital dos rios e pontes, berço do frevo e polo gastronômico.", descricao_en: "Capital of rivers and bridges, birthplace of frevo and culinary hub." },
    { nome: "Porto de Galinhas", slug: "porto_de_galinhas", estado_sigla: "PE", tag: "Piscinas Naturais & Jangadas", lat: -8.5042, lon: -35.0028, package_size: "9 MB", destaque: true, descricao_pt: "Famosa pelas águas mornas cristalinas e recifes de corais.", descricao_en: "Famous for warm crystal-clear waters and coral reefs." },
    { nome: "Olinda", slug: "olinda", estado_sigla: "PE", tag: "Patrimônio Histórico Mundial", lat: -8.0139, lon: -34.8519, package_size: "8 MB", destaque: true, descricao_pt: "Ladeiras históricas e mirante do Alto da Sé.", descricao_en: "Historic slopes and scenic viewpoint at Alto da Sé." },
    { nome: "Praia dos Carneiros", slug: "carneiros", estado_sigla: "PE", tag: "Paraíso dos Coqueirais", lat: -8.7042, lon: -35.0883, package_size: "7 MB", destaque: true, descricao_pt: "Igrejinha secular à beira-mar e mar cor esmeralda.", descricao_en: "Secular chapel by the sea and emerald calm waters." },
    { nome: "Fernando de Noronha", slug: "noronha", estado_sigla: "PE", tag: "Santuário Ecológico", lat: -3.8549, lon: -32.4297, package_size: "12 MB", destaque: true, descricao_pt: "Baía do Sancho e paraíso de vida marinha.", descricao_en: "Sancho Bay and pristine marine life sanctuary." }
  ];

  for (const c of cidades) {
    const rec = new Record(colCidades, c);
    dao.saveRecord(rec);
  }

  // 3. Inserir Atrações Principais
  const colAtracoes = dao.findCollectionByNameOrId("atracoes");
  const atracoes = [
    {
      nome: "Praça do Marco Zero",
      slug: "marco_zero",
      cidade_slug: "recife",
      uf: "PE",
      categoria: "Cultura",
      horario: "Aberto 24h",
      duracao_min: 90,
      gratuito: true,
      kid_friendly: true,
      must_see: true,
      is_lunch: false,
      rating_avg: 4.9,
      rating_count: 2840,
      likes_count: 6120,
      rank_posicao: 1,
      score: 98,
      lat: -8.0631,
      lon: -34.8711,
      descricao_pt: "Ponto inicial de contagem das distâncias de Pernambuco.",
      descricao_en: "Ground zero marker of Pernambuco with scenic river view."
    },
    {
      nome: "Piscinas Naturais de Porto",
      slug: "piscinas_porto",
      cidade_slug: "porto_de_galinhas",
      uf: "PE",
      categoria: "Praias",
      horario: "Tábua de Marés",
      duracao_min: 120,
      gratuito: false,
      kid_friendly: true,
      must_see: true,
      is_lunch: false,
      rating_avg: 4.9,
      rating_count: 3950,
      likes_count: 8400,
      rank_posicao: 2,
      score: 99,
      lat: -8.5042,
      lon: -35.0028,
      descricao_pt: "Passeio de jangada até as piscinas cristalinas com peixes.",
      descricao_en: "Raft tour to clear tidal pools teeming with fish."
    },
    {
      nome: "Alto da Sé e Mirante",
      slug: "alto_da_se",
      cidade_slug: "olinda",
      uf: "PE",
      categoria: "Cultura",
      horario: "08:00 - 19:00",
      duracao_min: 75,
      gratuito: true,
      kid_friendly: true,
      must_see: true,
      is_lunch: false,
      rating_avg: 4.8,
      rating_count: 2190,
      likes_count: 4890,
      rank_posicao: 3,
      score: 95,
      lat: -8.0139,
      lon: -34.8519,
      descricao_pt: "Vista panorâmica de Olinda e Recife com as melhores tapiocas.",
      descricao_en: "Panoramic view of Olinda and Recife with traditional tapioca stalls."
    }
  ];

  for (const a of atracoes) {
    const rec = new Record(colAtracoes, a);
    dao.saveRecord(rec);
  }

  // 4. Inserir Anúncio House Ads Piloto
  const colAds = dao.findCollectionByNameOrId("campanhas_ads");
  const ad1 = new Record(colAds, {
    titulo: "Passeio de Catamarã pelos Rios do Recife",
    link_destino: "https://onetour.app/parceiros/catamara-recife",
    uf_alvo: "PE",
    cidade_alvo: "recife",
    posicao: "home_card",
    ativo: true,
    prioridade: 10
  });
  dao.saveRecord(ad1);
});
