/// <reference path="../pb_data/types.d.ts" />
migrate((db) => {
  const dao = new Dao(db);

  // 1. Coleção: campanhas_push (Disparo e Histórico de Notificações)
  const campanhasPush = new Collection({
    name: "campanhas_push",
    type: "base",
    listRule: "",
    viewRule: "",
    createRule: null,
    updateRule: null,
    deleteRule: null,
    schema: [
      { name: "titulo", type: "text", required: true },
      { name: "mensagem", type: "text", required: true },
      { name: "imagem_url", type: "text" },
      { name: "uf_alvo", type: "text", required: true },
      { name: "topico", type: "text", required: true },
      { 
        name: "action_type", 
        type: "select", 
        options: { values: ["open_attraction", "open_city", "open_url", "open_trip"] }, 
        required: true 
      },
      { name: "action_value", type: "text" },
      { 
        name: "status", 
        type: "select", 
        options: { values: ["rascunho", "agendado", "enviado"] }, 
        required: true 
      },
      { name: "sent_count", type: "number" },
      { name: "data_envio", type: "date" }
    ]
  });
  dao.saveCollection(campanhasPush);

  // 2. Inserir notificações de exemplo para Pernambuco
  const colPush = dao.findCollectionByNameOrId("campanhas_push");
  const notifications = [
    {
      titulo: "☀️ Maré Baixa em Porto de Galinhas!",
      mensagem: "O pico da maré baixa hoje será às 10h15. Momento perfeito para o passeio de jangada até as piscinas naturais.",
      imagem_url: "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80",
      uf_alvo: "PE",
      topico: "pe_porto_de_galinhas",
      action_type: "open_city",
      action_value: "porto_de_galinhas",
      status: "enviado",
      sent_count: 12500,
      data_envio: new Date().toISOString()
    },
    {
      titulo: "🎭 Noite dos Tambores Silenciosos em Olinda",
      mensagem: "Ensaio aberto de maracatu nas ladeiras históricas a partir das 19h no Alto da Sé.",
      imagem_url: "https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?auto=format&fit=crop&w=800&q=80",
      uf_alvo: "PE",
      topico: "pe_eventos",
      action_type: "open_attraction",
      action_value: "alto_da_se",
      status: "enviado",
      sent_count: 9800,
      data_envio: new Date().toISOString()
    },
    {
      titulo: "⛵ Passeio de Catamarã com 15% OFF",
      mensagem: "Reserve seu tour fluvial pelas pontes históricas do Recife Antigo com desconto exclusivo pelo app.",
      imagem_url: "https://images.unsplash.com/photo-1599839575945-a9e5af0c3fa5?auto=format&fit=crop&w=800&q=80",
      uf_alvo: "PE",
      topico: "pe_promocoes",
      action_type: "open_url",
      action_value: "https://catamarantours.com.br?ref=onetour_pe",
      status: "enviado",
      sent_count: 14200,
      data_envio: new Date().toISOString()
    }
  ];

  for (const n of notifications) {
    const rec = new Record(colPush, n);
    dao.saveRecord(rec);
  }
}, (db) => {
  const dao = new Dao(db);
  try {
    const col = dao.findCollectionByNameOrId("campanhas_push");
    if (col) dao.deleteCollection(col);
  } catch (_) {}
});
