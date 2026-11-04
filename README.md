# One Tour: Guia de Viagem (Turismo Brasil)

Aplicativo nacional de turismo construído sobre arquitetura **offline-first**, com download modular das principais cidades e destinos do Brasil, assistente de roteirização inteligente (AI Trip Planner local), rede proprietária de anúncios (**House Ads**), monetização com **Google AdMob**, painel administrativo web integrado e acervo de **fotos reais geolocalizadas**.

* **Nome Comercial:** `One Tour: Guia de Viagem`
* **Package Name / Application ID:** `com.onetour.pe`
* **Keystore Oficial:** `APKS/pernambuco/keys/onetour-pe-upload.jks` (alias `onetour-pe`)
* **Modelo Operacional:** App único nacional com pacotes modulares de cidades (`pack_<cidade>.sqlite` e mapas vetoriais `.pmtiles`) para baixar e usar sem conexão.

---

## 🏗️ Arquitetura do Repositório

```
One_tour/
├── network_status.json         # Configuração remota do status e destaques nacionais
├── mobile/                     # Aplicativo Flutter Single Codebase (One Tour: Guia de Viagem)
│   ├── android/                # Configuração Gradle com Application ID com.onetour.pe e AdMob oficial
│   ├── lib/
│   │   ├── core/               # Temas (Material 3), Rotas (GoRouter) e AdMobConfig
│   │   ├── features/           # Explorar (Cidades do Brasil), Roteiros (VRP Offline), Mapa (PMTiles) e House Ads
│   │   └── l10n/               # Internacionalização Bilíngue Nativa (PT / EN)
│   ├── test/                   # Testes unitários e de integração (AdMob, Roteirizador)
│   └── pubspec.yaml
│
├── admin/                      # Painel Web Administrativo & Gestão de Conteúdo (React + TypeScript + Vite)
│   ├── src/
│   │   ├── components/         # Sidebar retrátil, ImagesTab (Gestão de Imagens dos Apps), HouseAdsTab, PushTab
│   │   ├── services/           # Comunicação com Ad Server API e PocketBase (updatePbRecord)
│   │   └── App.tsx             # Layout moderno com menu lateral e seletor rápido de UF/Destinos
│   ├── Dockerfile              # Deploy em produção via Easypanel / Nginx
│   └── package.json
│
├── house_ads/                  # Ad Server API & Distribuição de Campanhas (Node.js / Express)
│   ├── server/                 # Endpoints REST para anúncios, métricas e upload de imagens
│   └── Dockerfile              # Container de produção na VPS
│
├── server/                     # Infraestrutura Autônoma para VPS Linux (Easypanel)
│   ├── docker-compose.yml      # PocketBase + PostgreSQL 16 (PostGIS) + MinIO
│   ├── README_EASYPANEL.md     # Guia de deploy na VPS com SSL automático
│   ├── pocketbase/             # CMS Editorial, Coleções de Cidades/Atrações e Migrações
│   └── postgres/               # Script SQL com PostGIS, Telemetria e Score Social
│
├── APKS/                       # Bundles de Produção Assinados e Chaves de Upload
│   └── pernambuco/             # onetour-guia-de-viagem-release.aab (com.onetour.pe)
│
└── relatorios/                 # Documentação de Engenharia e Plano Estratégico
    └── plano_implementacao_ecossistema_one_tour.md
```

---

## 📌 Status Atual de Implementação

### 1. 🎯 Transição para App Único Nacional
* **App Unificado:** Em vez de manter 27 aplicativos regionais, o projeto foi unificado no aplicativo **One Tour: Guia de Viagem** (`com.onetour.pe`), eliminando riscos de políticas de conteúdo repetitivo da Play Store e reduzindo custos de manutenção.
* **Download Modular de Cidades:** O usuário baixa apenas os pacotes das cidades que deseja explorar offline (ex: Recife, Maceió, Salvador, Rio de Janeiro, São Paulo, Florianópolis, Foz do Iguaçu, Gramado).
* **AI Trip Planner Local:** Algoritmo combinatório preservado, gerando roteiros dia a dia sem custos de servidor e 100% offline.

### 2. 🖼️ Acervo de Fotos Reais e Autênticas (Wikimedia Commons)
* **Eliminação de Fotos Fictícias:** Fotografias geolocalizadas reais de domínio público e Creative Commons em resolução otimizada de 1280px via CDN `upload.wikimedia.org`.
* **Catálogo de Destinos:** Cidades e atrações de PE, AL, BA, RJ, SP, SC, PR, RS e DF integradas à base e aos fallbacks offline do app.

### 3. 💰 Monetização Google AdMob
* **App ID Oficial:** `ca-app-pub-5133242303791049~4445477549`
* **Banner Adaptativo:** `ca-app-pub-5133242303791049/1923255989`
* **Intersticial:** `ca-app-pub-5133242303791049/4252151837`
* **Nativo Avançado:** `ca-app-pub-5133242303791049/6065468944`
* **Vídeo Recompensado:** `ca-app-pub-5133242303791049/6792439283`
* **Fallback Híbrido:** Alternância automática para a rede proprietária de House Ads caso não haja inventário (*no-fill*) ou sem conexão à internet.

### 4. 🎛️ Painel Administrativo (`admin`)
* **Menu Lateral (Sidebar):** Navegação por categorias (Geral, Publicidade, Conteúdo, Sistema) e filtro de destinos por UF.
* **Módulo "Imagens dos Apps":** Catálogo com busca, modal de edição com upload local, inserção de URLs e sincronização remota via PocketBase (`updatePbRecord`).

---

## 🚀 Como Executar os Projetos

### 📱 Mobile (Flutter)
```bash
cd mobile
flutter pub get

# Rodar One Tour: Guia de Viagem no dispositivo conectado
flutter run -t lib/main_pe.dart --flavor pe

# Rodar a suíte de testes automatizados
flutter test test/admob_integration_test.dart

# Gerar Android App Bundle de Produção Oficial (AAB)
flutter build appbundle -t lib/main_pe.dart --flavor pe --release
```

### 💻 Painel Administrativo (`admin`)
```bash
cd admin
npm install
npm run dev      # Executar localmente em http://localhost:5173
npm run build    # Compilação de produção (Vite / TypeScript)
```

---

## 🐳 Servidores na Nuvem (Easypanel / VPS)

* **Ad Server & API House Ads:** `https://onetour-api-onetour.gtalg3.easypanel.host`
* **PocketBase (CMS & Conteúdo):** `https://onetour-pocketbase-estados.gtalg3.easypanel.host`
* **Admin Web:** Integrado ao Easypanel via Dockerfile multi-stage Nginx.
