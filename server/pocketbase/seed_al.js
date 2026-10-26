// Script de seed para cadastrar Alagoas (AL) e cidades polo no PocketBase
const PB_URL = process.env.POCKETBASE_URL || 'https://onetour-pocketbase-estados.gtalg3.easypanel.host';

const estadoAl = {
  sigla: 'AL',
  nome: 'Alagoas',
  status: 'ativo',
  versao_pacote: 1
};

const cidades = [
  {
    nome: 'Maceió',
    slug: 'maceio',
    estado_sigla: 'AL',
    tag: 'Caribe Brasileiro & Orla das Águas Claras',
    lat: -9.6658,
    lon: -35.7353,
    package_size: '11 MB',
    destaque: true,
    descricao_pt: 'Capital de praias urbanas cinematográficas (Pajuçara, Ponta Verde), piscinas naturais e gastronomia de frutos do mar.',
    descricao_en: 'Capital of postcard urban beaches (Pajuçara, Ponta Verde), natural pools and fresh seafood culinary scene.'
  },
  {
    nome: 'Maragogi',
    slug: 'maragogi',
    estado_sigla: 'AL',
    tag: 'Galés & Piscinas Naturais',
    lat: -9.0122,
    lon: -35.2225,
    package_size: '8 MB',
    destaque: true,
    descricao_pt: 'O coração da Costa dos Corais, célebre pelas Galés de águas mornas e translúcidas em alto mar.',
    descricao_en: 'Heart of Coral Coast, famous worldwide for the Galés crystal-clear natural barrier pools offshore.'
  },
  {
    nome: 'São Miguel dos Milagres',
    slug: 'milagres',
    estado_sigla: 'AL',
    tag: 'Rota Ecológica & Mar de Esmeralda',
    lat: -9.2667,
    lon: -35.3725,
    package_size: '6 MB',
    destaque: true,
    descricao_pt: 'Charme rústico, praias desertas paradisíacas (Praia do Toque), coqueirais infinitos e santuário do peixe-boi.',
    descricao_en: 'Rustic charm, deserted paradise beaches (Praia do Toque), endless palm groves, and manatee sanctuary.'
  }
];

const atracoes = [
  {
    nome: 'Piscinas Naturais de Pajuçara',
    slug: 'piscinas_pajucara',
    cidade_slug: 'maceio',
    uf: 'AL',
    categoria: 'Praias',
    horario: 'Consulte a tábua de marés',
    duracao_min: 120,
    gratuito: false,
    kid_friendly: true,
    must_see: true,
    score: 98,
    lat: -9.6658,
    lon: -35.7153,
    descricao_pt: 'Passeio tradicional de jangada até os bancos de corais repletos de peixes coloridos a 2 km da costa.'
  },
  {
    nome: 'Galés de Maragogi',
    slug: 'gales_maragogi',
    cidade_slug: 'maragogi',
    uf: 'AL',
    categoria: 'Praias',
    horario: 'Catamarãs na maré baixa',
    duracao_min: 150,
    gratuito: false,
    kid_friendly: true,
    must_see: true,
    score: 100,
    lat: -9.0122,
    lon: -35.1725,
    descricao_pt: 'Aquário natural gigante formado pela segunda maior barreira de corais do planeta.'
  },
  {
    nome: 'Praia do Toque',
    slug: 'praia_do_toque',
    cidade_slug: 'milagres',
    uf: 'AL',
    categoria: 'Praias',
    horario: 'Acesso livre durante o dia',
    duracao_min: 180,
    gratuito: true,
    kid_friendly: true,
    must_see: true,
    score: 97,
    lat: -9.2667,
    lon: -35.3625,
    descricao_pt: 'Eleita uma das praias mais bonitas do Brasil, com água tépida e barreira de arrecifes próxima.'
  },
  {
    nome: 'Farol da Ponta Verde',
    slug: 'farol_ponta_verde',
    cidade_slug: 'maceio',
    uf: 'AL',
    categoria: 'Cultura',
    horario: 'Visita externa na maré baixa',
    duracao_min: 60,
    gratuito: true,
    kid_friendly: true,
    must_see: true,
    score: 95,
    lat: -9.6585,
    lon: -35.6980,
    descricao_pt: 'Marco fotográfico de Maceió, onde é possível caminhar até a base do farol sobre os recifes.'
  }
];

const notificacoes = [
  {
    titulo: '🌊 Tour Alagoas Chegou ao One Tour!',
    mensagem: 'Explore as piscinas de Maragogi, a orla de Maceió e Milagres 100% offline.',
    uf_alvo: 'AL',
    topico: 'launch_al',
    action_type: 'open_city',
    action_value: 'maceio',
    status: 'enviado',
    sent_count: 5200
  }
];

async function seed(token) {
  const headers = {
    'Content-Type': 'application/json',
    ...(token ? { 'Authorization': token } : {})
  };

  console.log('--- 1. Inserindo Estado AL no PocketBase ---');
  // Verifica se AL já existe
  const estadosRes = await fetch(`${PB_URL}/api/collections/estados/records?filter=(sigla='AL')`).then(r => r.json());
  if (estadosRes.items && estadosRes.items.length > 0) {
    console.log('Estado AL já cadastrado:', estadosRes.items[0].id);
  } else {
    const res = await fetch(`${PB_URL}/api/collections/estados/records`, {
      method: 'POST',
      headers,
      body: JSON.stringify(estadoAl)
    }).then(r => r.json());
    console.log('Estado AL criado:', res.id || res.message);
  }

  console.log('--- 2. Inserindo Cidades Polo de Alagoas ---');
  for (const c of cidades) {
    const cidRes = await fetch(`${PB_URL}/api/collections/cidades/records?filter=(slug='${c.slug}')`).then(r => r.json());
    if (cidRes.items && cidRes.items.length > 0) {
      console.log(`Cidade ${c.nome} já existe:`, cidRes.items[0].id);
    } else {
      const res = await fetch(`${PB_URL}/api/collections/cidades/records`, {
        method: 'POST',
        headers,
        body: JSON.stringify(c)
      }).then(r => r.json());
      console.log(`Cidade ${c.nome} inserida:`, res.id || res.message);
    }
  }

  console.log('--- 3. Inserindo Atrações Âncora de Alagoas ---');
  for (const a of atracoes) {
    const attRes = await fetch(`${PB_URL}/api/collections/atracoes/records?filter=(slug='${a.slug}')`).then(r => r.json());
    if (attRes.items && attRes.items.length > 0) {
      console.log(`Atração ${a.nome} já existe:`, attRes.items[0].id);
    } else {
      const res = await fetch(`${PB_URL}/api/collections/atracoes/records`, {
        method: 'POST',
        headers,
        body: JSON.stringify(a)
      }).then(r => r.json());
      console.log(`Atração ${a.nome} inserida:`, res.id || res.message);
    }
  }

  console.log('--- 4. Inserindo Campanha de Lançamento no PocketBase ---');
  for (const n of notificacoes) {
    const notRes = await fetch(`${PB_URL}/api/collections/campanhas_push/records?filter=(topico='${n.topico}')`).then(r => r.json());
    if (notRes.items && notRes.items.length > 0) {
      console.log(`Campanha ${n.topico} já existe:`, notRes.items[0].id);
    } else {
      const res = await fetch(`${PB_URL}/api/collections/campanhas_push/records`, {
        method: 'POST',
        headers,
        body: JSON.stringify(n)
      }).then(r => r.json());
      console.log(`Campanha ${n.titulo} inserida:`, res.id || res.message);
    }
  }

  console.log('--- SEED ALAGOAS CONCLUÍDO COM SUCESSO! ---');
}

module.exports = { seed };

if (require.main === module) {
  const token = process.argv[2] || '';
  seed(token).catch(console.error);
}
