# One Tour - Ecossistema de Turismo Estadual (27 Estados)

Ecossistema tecnológico e comercial composto por **27 aplicativos móveis independentes** (um para cada estado brasileiro e DF) construídos sobre um **código único Flutter Multi-Flavor**, com filosofia **offline-first**, assistente de roteirização inteligente, rede proprietária de anúncios (**House Ads**), monetização com **Google AdMob**, painel administrativo web integrado e acervo de **fotos reais e geolocalizadas**.

---

## 🏗️ Arquitetura do Repositório

```
One_tour/
├── network_status.json         # Configuração remota em tempo real do status dos 27 estados (Play Store)
├── mobile/                     # Aplicativo Flutter Single Codebase (27 Flavors)
│   ├── android/                # Configuração Gradle com 27 Product Flavors e AdMob Application IDs
│   ├── lib/
│   │   ├── core/               # Flavors, Temas (Material 3), Rotas (GoRouter) e AdMobConfig (PE, AL...)
│   │   ├── features/           # Explorar, Detalhes, Roteiros (VRP Offline), Mapa (PMTiles), House Ads e Rede One Tour
│   │   └── l10n/               # Internacionalização Bilíngue Nativa (PT / EN)
│   ├── test/                   # Testes unitários e de integração (AdMob, Roteirizador)
│   └── pubspec.yaml
│
├── admin/                      # Painel Web Administrativo & Gestão de Conteúdo (React + TypeScript + Vite)
│   ├── src/
│   │   ├── components/         # Sidebar retrátil, ImagesTab (Gestão de Imagens dos Apps), HouseAdsTab, PushTab
│   │   ├── services/           # Comunicação com Ad Server API e PocketBase (updatePbRecord)
│   │   └── App.tsx             # Layout moderno com menu lateral e seletor rápido de UF
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
└── relatorios/                 # Documentação de Engenharia e Plano Estratégico
    └── plano_implementacao_ecossistema_one_tour.md
```

---

## 📌 Status Atual de Implementação (30/10/2026)

### 1. 🖼️ Acervo de Fotos Reais e Autênticas (Wikimedia Commons)
* **Eliminação de Fotos Fictícias e Genéricas:** Todas as imagens genéricas de bancos de stock foram substituídas por fotografias geolocalizadas autênticas de Pernambuco e Alagoas com licenças livres (Creative Commons / Domínio Público).
* **CDN e Otimização:** URLs configuradas com largura otimizada de 1280px via `upload.wikimedia.org`, garantindo carregamento rápido e baixo consumo de dados móveis.
* **Consistência Online & Offline:** Mapeamento sincronizado em `ExploreRepository` (online dinâmico), `mock_pe_data.dart` (memória) e `LocalDbService` (banco SQLite offline para itinerários).

### 2. 🎛️ Painel Administrativo (`admin`) - Menu Lateral & Gestão de Imagens
* **Menu Lateral (Sidebar):**
  * Navegação retrátil por seções (Geral, Publicidade, Conteúdo, Sistema).
  * Seletor rápido de UF (PE, AL, PB, RN, CE, BA, SP, RJ, TODOS) para filtragem global de dados.
  * Status de conexão em tempo real com Ad Server e PocketBase.
* **Módulo "Imagens dos Apps" (`ImagesTab`):**
  * Catálogo visual com busca textual, filtro de UF e filtro por categoria (Cidades, Praias, Cultura, Natureza, Gastronomia).
  * **Modal de Edição Completo:**
    1. Upload direto de imagem do computador para o servidor (`/api/v1/admin/ads/upload`).
    2. Inserção direta de URL externa (ex: CDN oficial, Wikimedia).
    3. Sugestões de fotos reais verificadas com aplicação em 1 clique.
    4. Sincronização direta com a base de dados do PocketBase (`updatePbRecord`).

### 3. 💰 Monetização Google AdMob Multi-UF
Configuração híbrida (Google AdMob oficial + fallback automático para House Ads proprietário):
* **Pernambuco (`pe`):**
  * App ID: `ca-app-pub-5133242303791049~4445477549`
  * Banner: `ca-app-pub-5133242303791049/1923255989`
  * Intersticial: `ca-app-pub-5133242303791049/4252151837`
  * Nativo: `ca-app-pub-5133242303791049/6065468944`
  * Recompensado: `ca-app-pub-5133242303791049/6792439283`
* **Alagoas (`al`):**
  * App ID: `ca-app-pub-5133242303791049~3525828291`
  * Banner: `ca-app-pub-5133242303791049/5845316981`
  * Intersticial: `ca-app-pub-5133242303791049/7951112282`
  * Nativo: `ca-app-pub-5133242303791049/2535134076`
  * Recompensado: `ca-app-pub-5133242303791049/5161297412`
* **Testes Automatizados:** Suíte `test/admob_integration_test.dart` com 5/5 testes passando.

### 4. 📦 Artefatos de Produção AAB (Pernambuco)
* Gerado pacote de release oficial para a Google Play Store: `APKS/pernambuco/app-pe-release.aab`.
* Assinatura configurada via `key.properties` e keystore `pe_release_key.jks` (protegidos no `.gitignore`).

---

## 🚀 Como Executar os Projetos

### 📱 Mobile (Flutter)
```bash
cd mobile
flutter pub get

# Rodar Pernambuco no dispositivo conectado
flutter run -t lib/main_pe.dart --flavor pe

# Rodar Alagoas no dispositivo conectado
flutter run -t lib/main_al.dart --flavor al

# Rodar a suíte de testes do AdMob
flutter test test/admob_integration_test.dart

# Gerar Android App Bundle de Produção (PE)
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

---

## 🌐 Rede One Tour Brasil & Publicação Dinâmica

O aplicativo possui descoberta dinâmica em tempo real dos apps da rede:
* O arquivo `network_status.json` controla o status dos 27 estados (`available` vs `coming_soon`).
* Ao lançar um novo estado na Google Play Store (ex: Alagoas), basta alterar seu status no arquivo.
* Todos os usuários verão o estado mudar para **Disponível** com botão direto de download na loja sem precisar de atualização do app.
* Nos estados em preparação, os usuários podem se inscrever para receber notificação push no lançamento via tópicos FCM (`launch_<uf>`).
