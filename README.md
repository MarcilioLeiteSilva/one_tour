# One Tour - Ecossistema de Turismo Estadual (27 Estados)

Ecossistema tecnológico e comercial composto por **27 aplicativos móveis independentes** (um para cada estado brasileiro e DF) construídos sobre um **código único Flutter Multi-Flavor**, com filosofia **offline-first**, assistente de roteirização inteligente e rede proprietária de anúncios (**House Ads**).

---

## 🏗️ Arquitetura do Repositório

```
One_tour/
├── network_status.json         # Configuração remota em tempo real do status dos 27 estados (Play Store)
├── mobile/                     # Aplicativo Flutter Single Codebase (27 Flavors)
│   ├── android/                # Configuração Gradle com 27 Product Flavors
│   ├── lib/
│   │   ├── core/               # Configuração de Flavors, Temas (Material 3) e Rotas (GoRouter)
│   │   ├── features/           # Explorar, Detalhes, Roteiros, Mapa, Favoritos e Rede One Tour
│   │   └── l10n/               # Internacionalização Bilíngue Nativa (PT / EN)
│   └── pubspec.yaml
│
├── server/                     # Infraestrutura Autônoma para VPS Linux (Easypanel)
│   ├── docker-compose.yml      # PocketBase + PostgreSQL (PostGIS) + MinIO
│   ├── .env.example            # Template de variáveis de ambiente
│   ├── README_EASYPANEL.md     # Guia de deploy na VPS com SSL automático
│   ├── pocketbase/             # CMS Editorial, Backoffice e Migrações JS
│   └── postgres/               # Script SQL com PostGIS, Telemetria e Score Social
│
└── relatorios/                 # Documentação de Engenharia e Plano Estratégico
    └── plano_implementacao_ecossistema_one_tour.md
```

---

## 🚀 Como Executar o Mobile (Flutter)

### Pré-requisitos
* Flutter SDK 3.27+ / Dart 3.6+
* Android Studio ou Xcode

### Rodar o estado piloto (Pernambuco - `pe`):
```bash
cd mobile
flutter pub get
flutter run -t lib/main_pe.dart --flavor pe
```

---

## 🐳 Como Subir o Servidor na VPS (Easypanel / Docker)

Acesse a VPS via SSH e execute:
```bash
# 1. Instalar Easypanel (caso novo servidor)
curl -sSL https://get.easypanel.io | sh

# 2. No painel web do Easypanel (porta 3000):
# Crie o projeto 'one-tour' e faça o deploy via Compose usando o arquivo server/docker-compose.yml
```

Mais detalhes no [Guia de Deploy no Easypanel](file:///f:/One_tour/server/README_EASYPANEL.md).

---

## 🌐 Rede One Tour Brasil & Publicação Dinâmica

O aplicativo possui descoberta dinâmica em tempo real dos apps da rede:
* O arquivo `network_status.json` controla o status dos 27 estados (`available` vs `coming_soon`).
* Ao lançar um novo estado na Google Play Store (ex: Alagoas), basta alterar seu status no arquivo.
* Todos os usuários verão o estado mudar para **Disponível** com botão direto de download na loja sem precisar de atualização do app.
* Nos estados em preparação, os usuários podem se inscrever para receber notificação push no lançamento via tópicos FCM (`launch_<uf>`).
