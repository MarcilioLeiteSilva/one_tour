# 📢 One Tour - House Ads Network & Ad Server

Rede proprietária de publicidade e cross-promotion (divulgação cruzada) para os 27 aplicativos estaduais do ecossistema One Tour.

---

## 🎯 Objetivos de Negócio

1. **Tráfego Cruzado (Cross-Promotion):**
   - O aplicativo de Pernambuco divulga os aplicativos vizinhos (*Tour Paraíba*, *Tour Alagoas*, *Tour Ceará*) para turistas que viajam pelo Nordeste.
2. **Monetização Direta Local:**
   - Venda de cotas publicitárias municipais para hotéis, pousadas, empresas de passeios náuticos e restaurantes locais (ex: Passeio de Catamarã em Olinda, Pousada em Porto de Galinhas).
3. **Telemetria de Alta Performance no PostgreSQL:**
   - Registro de impressões, cliques e cálculo de CTR em tempo real através da view analítica `view_ad_performance`.

---

## 📁 Estrutura do Diretório `house_ads/`

```
house_ads/
├── README.md                 # Especificação e arquitetura da rede de anúncios
└── server/                   # Microserviço Ad Server (Node.js/Express + TypeScript)
    ├── Dockerfile            # Imagem de produção para Easypanel / VPS
    ├── package.json
    ├── tsconfig.json
    ├── .env.example
    └── src/
        ├── index.ts          # Entry point & rotas Express
        ├── config.ts         # Variáveis de ambiente
        ├── db.ts             # Conexão Pool PostgreSQL (com fallback gracioso)
        ├── campaigns.ts      # Campanhas de cross-promotion e patrocinadores diretos
        └── routes/
            ├── ads.ts        # GET /api/v1/ads (segmentado por UF, cidade e posição)
            ├── track.ts      # POST /api/v1/ads/track/impression e /click
            └── stats.ts      # GET /api/v1/ads/stats/performance (CTR em tempo real)
```

---

## 📡 Endpoints da API do Ad Server

### 1. Obter Anúncios Segmentados
- **Método:** `GET /api/v1/ads`
- **Parâmetros de Consulta:**
  - `uf`: Sigla do estado (ex: `PE`, `SP`, `RJ`).
  - `cidade`: Slug ou nome da cidade (ex: `recife`, `porto_de_galinhas`).
  - `posicao`: Local de renderização (`home_card`, `attraction_banner`, `interstitial`).
  - `limit`: Quantidade máxima de anúncios retornados (padrão: 5).

### 2. Registrar Impressão (Telemetria)
- **Método:** `POST /api/v1/ads/track/impression`
- **Body JSON:**
```json
{
  "ad_id": "cross_pb_litoral",
  "uf": "PE",
  "city_slug": "recife",
  "position": "attraction_banner",
  "device_id": "dev_anon_12345"
}
```

### 3. Registrar Clique (Telemetria)
- **Método:** `POST /api/v1/ads/track/click`
- **Body JSON:**
```json
{
  "ad_id": "sponsor_catamara_recife",
  "uf": "PE",
  "city_slug": "recife",
  "position": "home_card",
  "device_id": "dev_anon_12345"
}
```

### 4. Consultar Desempenho & CTR
- **Método:** `GET /api/v1/ads/stats/performance`
- **Resposta:**
```json
{
  "success": true,
  "rows": [
    {
      "ad_id": "sponsor_catamara_recife",
      "uf": "PE",
      "position": "home_card",
      "impressions_count": 1420,
      "clicks_count": 98,
      "ctr_percentage": "6.90"
    }
  ]
}
```

---

## 📱 Formatos Visuais no App Flutter

1. **Card em Destaque na Home (`home_card`):**
   - Integrado logo após as tags de filtro da tela principal.
   - Ideal para atrações e experiências imperdíveis com selo patrocinado discreto.
2. **Banner Nativo no Feed de Atrações (`attraction_banner`):**
   - Inserido a cada 5 ou 6 itens no feed de exploração.
   - Estilizado de forma idêntica ao design system do app para não parecer publicidade invasiva.
3. **Intersticial Suave de Roteiro (`interstitial`):**
   - Modal com animação suave exibido exclusivamente ao salvar ou exportar um itinerário gerado.
   - Sem contadores forçados de bloqueio de tela (respeito à experiência do usuário).
