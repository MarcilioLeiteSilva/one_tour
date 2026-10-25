// Script de seed para popular Pernambuco (PE) no PocketBase
const PB_URL = process.env.POCKETBASE_URL || 'https://onetour-pocketbase-estados.gtalg3.easypanel.host';

const estadoPe = {
  sigla: 'PE',
  nome: 'Pernambuco',
  status: 'ativo',
  versao_pacote: 1
};

const cidades = [
  { nome: 'Recife', slug: 'recife', estado_sigla: 'PE', tag: 'Capital Multicultural', lat: -8.0631, lon: -34.8711, package_size: '14 MB', destaque: true, descricao_pt: 'Capital dos rios e pontes, berço do frevo e polo gastronômico.', descricao_en: 'Capital of rivers and bridges, birthplace of frevo and culinary hub.' },
  { nome: 'Porto de Galinhas', slug: 'porto_de_galinhas', estado_sigla: 'PE', tag: 'Piscinas Naturais & Jangadas', lat: -8.5042, lon: -35.0028, package_size: '9 MB', destaque: true, descricao_pt: 'Famosa pelas águas mornas cristalinas e recifes de corais.', descricao_en: 'Famous for warm crystal-clear waters and coral reefs.' },
  { nome: 'Olinda', slug: 'olinda', estado_sigla: 'PE', tag: 'Patrimônio Histórico Mundial', lat: -8.0139, lon: -34.8519, package_size: '8 MB', destaque: true, descricao_pt: 'Ladeiras históricas e mirante do Alto da Sé.', descricao_en: 'Historic slopes and scenic viewpoint at Alto da Sé.' },
  { nome: 'Praia dos Carneiros', slug: 'carneiros', estado_sigla: 'PE', tag: 'Paraíso dos Coqueirais', lat: -8.7042, lon: -35.0883, package_size: '7 MB', destaque: true, descricao_pt: 'Igrejinha secular à beira-mar e mar cor esmeralda.', descricao_en: 'Secular chapel by the sea and emerald calm waters.' },
  { nome: 'Fernando de Noronha', slug: 'noronha', estado_sigla: 'PE', tag: 'Santuário Ecológico', lat: -3.8549, lon: -32.4297, package_size: '12 MB', destaque: true, descricao_pt: 'Baía do Sancho e paraíso de vida marinha.', descricao_en: 'Sancho Bay and pristine marine life sanctuary.' }
];

const atracoes = [
  {
    nome: 'Praça do Marco Zero',
    slug: 'marco_zero',
    cidade_slug: 'recife',
    uf: 'PE',
    categoria: 'Cultura',
    horario: 'Aberto 24h',
    duracao_min: 90,
    gratuito: true,
    kid_friendly: true,
    must_see: true,
    score: 98,
    lat: -8.0631,
    lon: -34.8711,
    descricao_pt: 'Ponto inicial de contagem das distâncias de Pernambuco no coração do Recife Antigo.'
  },
  {
    nome: 'Piscinas Naturais de Porto de Galinhas',
    slug: 'piscinas_porto',
    cidade_slug: 'porto_de_galinhas',
    uf: 'PE',
    categoria: 'Praias',
    horario: 'Consulte a tábua de marés',
    duracao_min: 120,
    gratuito: false,
    kid_friendly: true,
    must_see: true,
    score: 99,
    lat: -8.5042,
    lon: -35.0028,
    descricao_pt: 'Aquário natural de águas cristalinas com peixes coloridos acessível por jangada.'
  },
  {
    nome: 'Alto da Sé e Mirante',
    slug: 'alto_da_se',
    cidade_slug: 'olinda',
    uf: 'PE',
    categoria: 'Cultura',
    horario: '08h às 21h',
    duracao_min: 120,
    gratuito: true,
    kid_friendly: true,
    must_see: true,
    score: 96,
    lat: -8.0139,
    lon: -34.8519,
    descricao_pt: 'Vista panorâmica inesquecível de Olinda e Recife com as tradicionais tapiocas de Pernambuco.'
  },
  {
    nome: 'Capela de São Benedito (Igrejinha dos Carneiros)',
    slug: 'igrejinha_carneiros',
    cidade_slug: 'carneiros',
    uf: 'PE',
    categoria: 'Praias',
    horario: 'Acesso pela praia durante o dia',
    duracao_min: 60,
    gratuito: true,
    kid_friendly: true,
    must_see: true,
    score: 95,
    lat: -8.7042,
    lon: -35.0883,
    descricao_pt: 'Cartão-postal icônico do século XVIII à beira-mar cercado por coqueiros centenários.'
  },
  {
    nome: 'Baía do Sancho',
    slug: 'baia_do_sancho',
    cidade_slug: 'noronha',
    uf: 'PE',
    categoria: 'Praias',
    horario: '08h às 18h (PARNAMAR)',
    duracao_min: 240,
    gratuito: false,
    kid_friendly: false,
    must_see: true,
    score: 100,
    lat: -3.8549,
    lon: -32.4297,
    descricao_pt: 'Eleita repetidas vezes a melhor praia do mundo pelo TripAdvisor com vida marinha exuberante.'
  }
];

const notificacoes = [
  {
    titulo: '☀️ Maré Baixa em Porto de Galinhas!',
    mensagem: 'O pico da maré baixa hoje será às 10h15. Momento perfeito para o passeio de jangada até as piscinas naturais.',
    uf_alvo: 'PE',
    topico: 'pe_porto_de_galinhas',
    action_type: 'open_city',
    action_value: 'porto_de_galinhas',
    status: 'enviado',
    sent_count: 12500
  },
  {
    titulo: '🎭 Noite dos Tambores Silenciosos em Olinda',
    mensagem: 'Ensaio aberto de maracatu nas ladeiras históricas a partir das 19h no Alto da Sé.',
    uf_alvo: 'PE',
    topico: 'pe_eventos',
    action_type: 'open_attraction',
    action_value: 'alto_da_se',
    status: 'enviado',
    sent_count: 9800
  },
  {
    titulo: '⛵ Passeio de Catamarã com 15% OFF',
    mensagem: 'Reserve seu tour fluvial pelas pontes históricas do Recife Antigo com desconto exclusivo pelo app.',
    uf_alvo: 'PE',
    topico: 'pe_promocoes',
    action_type: 'open_url',
    action_value: 'https://catamarantours.com.br?ref=onetour_pe',
    status: 'enviado',
    sent_count: 14200
  }
];

async function seed(token) {
  const headers = {
    'Content-Type': 'application/json',
    ...(token ? { 'Authorization': token } : {})
  };

  console.log('--- 1. Inserindo Estado PE ---');
  await fetch(`${PB_URL}/api/collections/estados/records`, {
    method: 'POST',
    headers,
    body: JSON.stringify(estadoPe)
  }).then(r => r.json()).then(d => console.log('Estado:', d.id || d.message));

  console.log('--- 2. Inserindo Cidades Polo ---');
  for (const c of cidades) {
    await fetch(`${PB_URL}/api/collections/cidades/records`, {
      method: 'POST',
      headers,
      body: JSON.stringify(c)
    }).then(r => r.json()).then(d => console.log('Cidade ' + c.nome + ':', d.id || d.message));
  }

  console.log('--- 3. Inserindo Atrações Principais ---');
  for (const a of atracoes) {
    await fetch(`${PB_URL}/api/collections/atracoes/records`, {
      method: 'POST',
      headers,
      body: JSON.stringify(a)
    }).then(r => r.json()).then(d => console.log('Atração ' + a.nome + ':', d.id || d.message));
  }

  console.log('--- 4. Inserindo Notificações Push ---');
  for (const n of notificacoes) {
    await fetch(`${PB_URL}/api/collections/campanhas_push/records`, {
      method: 'POST',
      headers,
      body: JSON.stringify(n)
    }).then(r => r.json()).then(d => console.log('Notificação ' + n.titulo + ':', d.id || d.message));
  }

  console.log('--- SEED CONCLUÍDO COM SUCESSO! ---');
}

module.exports = { seed };

if (require.main === module) {
  const token = process.argv[2] || '';
  seed(token).catch(console.error);
}
