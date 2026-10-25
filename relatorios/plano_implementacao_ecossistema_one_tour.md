# Plano de Implementação: Ecossistema One Tour (27 Estados)

> **Documento:** Plano de Engenharia, Diretrizes Estratégicas e Implementação em Fases  
> **Versão:** 1.4 (Status de Produção & Validação em Hardware Físico)  
> **Data:** 24 de Outubro de 2026 (Atualizado após Deploy no Easypanel, Seed de PE & FCM Real)  
> **Nicho:** City Tour, Turismo Estadual, Roteirização Inteligente, Rede House Ads e Push Notificações  
> **Plataformas:** Android e iOS (27 Aplicativos - 26 Estados + Distrito Federal)  
> **Status Geral do Projeto:** 🚀 **MVP, Backend, CMS, Painel Web e Push 100% Operacionais em Produção**

> [!NOTE]
> **MARCO DE IMPLEMENTAÇÃO ALCANÇADO (24/10/2026):**  
> Todos os serviços de nuvem estão deployed e ativos no Easypanel com SSL automático. O PocketBase foi migrado com sucesso para instância dedicada com volume persistente (`onetour-pocketbase-estados`), schema v0.23 com coleções `estados`, `cidades`, `atracoes` e `campanhas_push` populadas com dados reais de Pernambuco. O Admin Web Command Center está no ar com autenticação superuser. O Firebase Admin SDK oficial foi integrado à API com projeto `app-onetour` e entrega real de push notifications com BigPictureStyle validada no smartphone físico Samsung Galaxy SM-A075M.

---

## 1. Apresentação do Projeto, Contexto Estratégico e Guia para Agentes de IA

> [!IMPORTANT]
> **LEITURA OBRIGATÓRIA PARA QUALQUER AGENTE DE IA OU ENGENHEIRO:**  
> Este capítulo define a visão de negócio, os aprendizados da engenharia reversa do app de referência e as regras arquiteturais inegociáveis. Qualquer agente que assumir este projeto deve seguir rigorosamente as decisões aqui documentadas para manter a coerência técnica, funcional e comercial.

### 1.1. O Que É o Projeto One Tour?
O **One Tour** é um ecossistema comercial e tecnológico composto por **27 aplicativos móveis independentes** (um para cada estado brasileiro e o Distrito Federal — ex: *Tour Pernambuco*, *Tour São Paulo*, *Tour Bahia*, etc.), focados em:
1. **Guia e City Tour Municipal:** Apresentação rica de pontos turísticos, rotas culturais, praias, patrimônio histórico, gastronomia e informações úteis de cada cidade do estado.
2. **Roteirização Inteligente (AI Trip Planner):** Um assistente que monta itinerários completos dia a dia, personalizados pelo perfil do turista (orçamento, ritmo, dias de estadia, viagens com crianças ou solo).
3. **Expansão da Rede Própria de Anúncios (House Ads):** Monetização e tráfego cruzado entre os aplicativos da rede, além da venda direta de espaços de publicidade qualificada para a cadeia de turismo local (hotéis, pousadas, restaurantes, passeios de barco e receptivos).
4. **Push Notificações Segmentadas:** Canal contínuo de retenção e vendas com disparos direcionados por estado, cidade ou interesse (ofertas sazonais, pacotes turísticos, notícias e novidades).

---

### 1.2. DNA de Negócio: O Modelo "ZapScore" Aplicado ao Turismo
O cliente já opera com sucesso a rede **ZapScore**, onde construiu dezenas de aplicativos de futebol segmentados por campeonato e estado (ex: `com.zapscore.estadualpernambucano`, `com.zapscore.estadualpaulista`, `com.zapscore.estadualbaiano`).
* **Vantagem de ASO (App Store Optimization):** O turista ou morador que busca "O que fazer em Pernambuco" ou "Turismo em Bonito MS" encontra um app dedicado com identidade visual e conteúdo hiper-local, gerando muito mais downloads e conversão do que um app genérico nacional.
* **Rede de Distribuição Proprietária:** Ao deter 27 aplicativos nas lojas, o ecossistema cria uma audiência cativa massiva e qualificada. O app de Pernambuco promove os apps dos estados vizinhos (Alagoas, Paraíba, Ceará), gerando instalações cruzadas a custo zero de aquisição (CAC).

---

### 1.3. Lições Críticas da Engenharia Reversa do "Trip AI Plan"
O aplicativo de referência instalado no celular (`com.aitrippack.app`, v1.0.5) foi completamente inspecionado em nível de código nativo (`libapp.so`), banco de dados e tráfego de CDN. As descobertas fundamentais que **devem ser preservadas** neste projeto são:

1. **Roteirizador "AI" é Híbrido, Local e sem Custo por Chamada:**
   * O app **não** faz requisições síncronas a APIs caras de LLM (como OpenAI ou Claude) a cada roteiro gerado pelo usuário.
   * Ele baixa pacotes por cidade contendo um banco `pack.sqlite`. Esse banco contém:
     * A tabela `place` com atributos pré-classificados (`score`, `fame`, `interest`, `duration_min`, `setting`, `kid_friendly`, `must_see`).
     * A tabela `matrix` com uma matriz pré-calculada de tempos e distâncias a pé e de carro (`from_id`, `to_id`, `walk_min`, `drive_min`) entre todos os pontos turísticos relevantes.
   * O aplicativo executa em Dart um **algoritmo de otimização combinatória local (Problema do Caixeiro Viajante com janelas de tempo)**. O roteiro é gerado em menos de 1 segundo, com pausa inteligente para almoço (`is_lunch`), funciona sem conexão à internet e tem **custo R$ 0,00 de servidor**.
2. **Mapas 100% Offline com MapLibre GL e PMTiles:**
   * Em vez de pagar centenas de dólares por mês para Google Maps ou Mapbox, o app faz download de arquivos compactados `.pmtiles` (tiles vetoriais do OpenStreetMap).
   * O mapa vetorial da cidade é renderizado localmente pelo MapLibre, sem consumo de 4G/5G do turista.
3. **Configuração Remota Leve para Anúncios:**
   * Um simples JSON remoto (`app_config.json`) liga/desliga anúncios e define os blocos por tela dinamicamente sem necessidade de novas compilações na Play Store.

---

### 1.4. Diretrizes Inegociáveis para Agentes de IA em Fases Posteriores

Para que qualquer outro agente de IA ou desenvolvedor dê sequência ao projeto com total fidelidade e sem retrabalho, **obedeça rigorosamente a estas 5 regras:**

* **REGRA 1: Base de Código Única (Single Codebase Multi-Flavor):**
  * NUNCA crie 27 repositórios diferentes de código mobile.
  * O projeto possui apenas um repositório Flutter (`/mobile`), onde cada estado é configurado como um *Product Flavor* (`pe`, `sp`, `rj`, `ba`, etc.), compartilhando 100% dos widgets, modelos, lógica de mapas e roteirização.
* **REGRA 2: Filosofia Offline-First:**
  * O turista viaja para áreas com sinal precário (serras, praias remotas, estradas). O app DEVE funcionar sem internet após o download inicial do pacote da cidade.
  * NUNCA torne o app refém de conexão constante para abrir roteiros, ver mapas ou ler dados turísticos já baixados.
* **REGRA 3: Separação Rígida entre PocketBase e PostgreSQL:**
  * **PocketBase:** É exclusivamente a interface visual de CMS/Backoffice e autenticação. É onde editores humanos cadastram cidades, pontos turísticos, fazem upload de fotos e banners da House Ads.
  * **PostgreSQL + PostGIS:** É o motor de dados espaciais analíticos e telemetria de alta performance do Ad Server (gravação de milhões de visualizações e cliques de anúncios sem travar o CMS).
  * Não crie acoplamentos desnecessários ou dependências circulares entre os dois bancos.
* **REGRA 4: Infraestrutura Econômica Autônoma (VPS + Easypanel):**
  * Toda a infraestrutura backend roda em contêineres Docker orquestrados pelo Easypanel em uma VPS simples (Hetzner, Hostinger ou similar).
  * Evite introduzir serviços gerenciados caros de nuvens públicas (AWS, Firebase pago por leitura, etc.) que inviabilizem o modelo de custo fixo baixo.
* **REGRA 5: Respeito à Sequência do Plano:**
  * Não pule etapas. Primeiro valida-se a infraestrutura e o app piloto do estado polo (Pernambuco). Somente após o piloto estar redondo é que se realiza a industrialização e o rollout dos demais 26 estados com Fastlane.

---

## 2. Visão Geral e Arquitetura do Sistema

```mermaid
graph TD
    subgraph Mobile [Ecossistema Mobile - Flutter Single Codebase]
        FlavorPE[App Tour Pernambuco]
        FlavorSP[App Tour São Paulo]
        FlavorRJ[App Tour Rio de Janeiro]
        FlavorOthers[... Demais 24 Estados]
    end

    subgraph Infra [VPS Linux com Easypanel]
        PocketBase[PocketBase CMS & Auth & Mídias]
        PostgreSQL[(PostgreSQL 16 + PostGIS)]
        AdEngine[API House Ads Server & Métricas]
        PushService[Serviço de Push Notificações]
    end

    subgraph External [Serviços Externos / CDN]
        FCM[Firebase Cloud Messaging]
        MapCDN[CDN de Mapas PMTiles & Pacotes SQLite]
    end

    Mobile -->|Download Pacote Cidade| MapCDN
    Mobile -->|Anúncios e Métricas| AdEngine
    Mobile -->|Cadastro/Favoritos/Sync| PocketBase
    Mobile -->|Registro de Tokens| PushService
    AdEngine --> PostgreSQL
    PushService --> FCM
    FCM --> Mobile
```

### 2.1. Ambiente de Produção Ativo (Easypanel & Nuvem)

| Componente / Serviço | Endereço / URL de Produção | Tecnologia & Configuração | Status Operacional |
| :--- | :--- | :--- | :---: |
| **PocketBase CMS & Auth** | [`onetour-pocketbase-estados.gtalg3.easypanel.host`](https://onetour-pocketbase-estados.gtalg3.easypanel.host/) | PocketBase v0.23 + Volume persistente montado em `/pb_data` | **100% Online** ✅ |
| **Admin Web Command Center** | [`onetour-frontend-onetour.gtalg3.easypanel.host`](https://onetour-frontend-onetour.gtalg3.easypanel.host/) | React + Vite + Tailwind + Lucide (Auth v0.23 Superuser) | **100% Online** ✅ |
| **One Tour API Backend & Ads** | [`onetour-api-onetour.gtalg3.easypanel.host`](https://onetour-api-onetour.gtalg3.easypanel.host/) | Node.js, Express, TypeScript, Firebase Admin SDK v14 | **100% Online** ✅ |
| **Banco Relacional & Spatial** | `postgres-onetour:5432` (Database: `onetour`) | PostgreSQL 16 + Extensão PostGIS habilitada | **100% Online** ✅ |
| **Firebase Cloud Messaging** | Google Cloud / Firebase Console (Projeto `app-onetour`) | Service Account oficial com suporte a tópicos e BigPicture | **100% Online** ✅ |
| **App Mobile Piloto (Pernambuco)** | Pacote: `com.onetour.pe` (Samsung SM-A075M) | Flutter 3.x, SQLite, MapLibre, FCM integrado | **Validado em Hardware** ✅ |

---

## 3. Stack Tecnológica Definida

| Camada | Tecnologia | Função no Ecossistema |
| :--- | :--- | :--- |
| **Mobile** | Flutter (Dart AOT) | Código único para 27 apps via *Product Flavors*. |
| **Gerenciamento de Estado** | Riverpod | Injeção de dependência reativa e desacoplada. |
| **Navegação** | GoRouter | Roteamento declarativo com suporte a Deep Linking. |
| **Mapas & Vetores** | MapLibre GL + PMTiles | Mapas vetoriais 100% offline sem custo de Google Maps. |
| **Banco Local App** | SQLite (`sqlite3`) | Armazenamento de pontos turísticos (`pack.sqlite`) e viagens (`user.sqlite`). |
| **Hospedagem & Deploy** | VPS Linux + Easypanel | Orquestração Docker com SSL automático e deploy contínuo. |
| **CMS & Backoffice** | PocketBase (Go + SQLite) | Cadastro de cidades, atrações, banners de anúncios e upload de mídias. |
| **Banco Central & Ads** | PostgreSQL 16 + PostGIS | Motor espacial de proximidade, métricas e telemetria da rede House Ads. |
| **Push Notificações** | Firebase Cloud Messaging (FCM) | Notificações push segmentadas por tópicos (UF, cidade, categoria). |
| **Esteira de Build** | Fastlane + GitHub Actions | Compilação e envio automatizado dos 27 apps para a Google Play / App Store. |

---

## 4. Arquitetura de Telas, Layout e Experiência do Usuário (UI/UX)

### 4.1. Filosofia de Interface e Usabilidade Mobile
* **Navegação Ergonométrica:** Elementos de ação primária acessíveis na metade inferior da tela para uso confortável com apenas uma mão durante caminhadas ou deslocamentos.
* **Design Imersivo e Fotográfico:** Ênfase em imagens de alta qualidade dos destinos, com cantos arredondados modernos (BorderRadius 16px), micro-interações suaves e transições fluidas.
* **Transparência de Conectividade:** Indicadores claros de status offline ("Disponível Offline", "Baixando Pacote 45%", "Sincronizado").
* **Tipografia e Cores:**
  * Tipografia moderna e altamente legível (Google Fonts *Inter* ou *Outfit*).
  * Design tokens dinâmicos por estado (definidos no Flavor), garantindo que cada app tenha identidade regional sem duplicar telas.
  * Suporte nativo a **Modo Escuro (Dark Mode)** e **Modo Claro (Light Mode)**.

---

### 4.2. Estrutura Global de Navegação (Bottom Navigation Bar)
O aplicativo adota barra de navegação inferior persistente com 4 destinos:
1. **Explorar (`/cidades`):** Vitrine do estado, busca de municípios e categorias.
2. **Roteiros (`/roteiros`):** Central de viagens, assistente de criação e itinerários gerados.
3. **Mapa (`/mapa`):** Visualização cartográfica offline em tela cheia com pins e rotas.
4. **Salvos (`/favoritos`):** Lugares favoritados e gerenciamento de pacotes offline baixados.

---

### 4.3. Detalhamento Tela a Tela

```
┌────────────────────────────────────────────────────────────────────────┐
│                        MAPA DE TELAS DO APP                            │
├─────────────────┬──────────────────┬─────────────────┬─────────────────┤
│    EXPLORAR     │   TELA CIDADE    │   WIZARD ROTEIRO│ ROTEIRO GERADO  │
│ ┌─────────────┐ │ ┌──────────────┐ │ ┌─────────────┐ │ ┌─────────────┐ │
│ │Busca & UF   │ │ │Hero Header   │ │ │Quantos dias?│ │ │[D1] [D2] [D3│ │
│ │Carrossel Cid│ │ │Status Offline│ │ │Qual ritmo?  │ │ │09:00 Parada1│ │
│ │Filtro Tags  │ │ │Guia Cultural │ │ │Interesses?  │ │ │🚶 8 min     │ │
│ │House Ads Card │ │Lista Atrações│ │ └─────────────┘ │ │12:30 Almoço 🍽│ │
│ │Feed Atrações│ │ │[FAB: Roteiro]│ │ [Gerar Agora] │ │ │14:00 Parada2│ │
│ └─────────────┘ │ └──────────────┘ │                 │ └─────────────┘ │
└─────────────────┴──────────────────┴─────────────────┴─────────────────┘
```

#### A. Tela Principal do Estado (Home / Explorar - `/cidades`)
* **Header Temático:**
  * Saudação personalizada com brasão/logo do estado (ex: *Tour Pernambuco*).
  * Widget de previsão do tempo da capital.
  * Barra de busca rápida com preenchimento preditivo de cidades e atrações.
* **Carrossel de Cidades Polo:**
  * Cards horizontais em destaque com foto de capa imersiva, nome do município e selo (ex: *"Recife • Capital Multicultural"*, *"Porto de Galinhas • Piscinas Naturais"*).
* **Filtros por Tags em Pílulas (Chips Horizontais):**
  * `🏖️ Praias & Litoral`, `🏛️ Cultura & História`, `🍲 Gastronomia`, `🌿 Ecoturismo & Trilhas`, `🎉 Eventos & Noite`.
* **Bloco Nativo House Ads:**
  * Card patrocinado orgânico (ex: *"Passeio de Catamarã em Olinda"* ou promoção cruzada *"Conheça o App Tour Paraíba"*).
* **Feed Vertical de Atrações em Alta:**
  * Lista de atrações com nota de avaliação (*score*), tempo médio de visitação e badge *"Imperdível"*.

#### B. Tela de Detalhes da Cidade (`/cidade/:id`)
* **Hero Header Panorâmico:**
  * Foto da cidade em alta definição com gradiente de proteção de leitura.
  * Botão de Ação Rápida de Download:
    * Se não baixado: `[ ⬇ Baixar Guia e Mapa Offline (12 MB) ]`
    * Se baixado: `[ ✓ Pronto Offline • 12 MB ]`
* **Guia Rápido Municipal:**
  * Resumo histórico e dicas práticas (*Melhor época para ir*, *Como circular*, *Dicas locais*).
* **Lista de Atrações da Cidade:**
  * Agrupamento por bairros/regiões turísticas com fotos, horários e distâncias relativas.
* **Floating Action Button (FAB) de Destaque:**
  * Botão flutuante estilizado: **"Montar Roteiro Inteligente"**.

#### C. Assistente de Roteirização (Wizard AI Planner - `/roteiro/novo`)
Fluxo em modal/bottom-sheet ágil em 3 perguntas antes da otimização:
1. **Duração:** Seletor de 1 a 7 dias de viagem.
2. **Ritmo de Passeio:**
   * *Tranquilo:* 2 a 3 pontos por dia (ideal para descanso).
   * *Moderado:* 3 a 4 pontos por dia.
   * *Intenso:* 5 a 6 pontos por dia (aproveitamento máximo).
3. **Perfil e Interesses:**
   * *Com quem viaja:* Solo, Casal, Amigos ou Família com Crianças (*filtro kid-friendly ativado*).
   * *Prioridades:* Marcar checkboxes de História, Praias, Gastronomia ou Compras.
* **Gatilho:** Botão **"Gerar Itinerário Otimizado"** (execução do algoritmo combinatório local em < 1 segundo).

#### D. Tela do Roteiro Pronto e Itinerário (`/roteiro/:id`)
* **Seletor de Abas de Dias:** Navegação superior por pílulas `[ Dia 1 ]` `[ Dia 2 ]` `[ Dia 3 ]`.
* **Timeline Vertical Cronológica:**
  * `09:00` • **Marco Zero do Recife** (Tempo de visitação: 1h30).
  * `🚶‍♂️ 8 min a pé (600m)` até a próxima parada.
  * `10:45` • **Rua do Bom Jesus e Sinagoga**.
  * `12:30` • 🍽️ **Pausa Almoço:** Sugestão do polo gastronômico local.
  * `14:00` • **Museu Cais do Sertão** (Tempo de visitação: 2h).
* **Ações do Roteiro:**
  * Botão *"Ver no Mapa"* (plota todos os pontos do dia com linha de rota traçada).
  * Botão *"Compartilhar/Exportar"* (abre o intersticial suave da House Ads e gera card visual para redes sociais/PDF).

#### E. Tela do Mapa Offline Interativo (`/mapa`)
* **Visualização Cartográfica em Tela Cheia:** Renderização via MapLibre GL usando os tiles vetoriais PMTiles.
* **Pins Inteligentes:** Marcadores customizados com ícone da categoria (praia, museu, restaurante).
* **Linha de Trajeto (Route Path):** Desenho vetorial da sequência de pontos do dia selecionado.
* **Card Deslizante de Atração:** Ao tocar em um pin, exibe card inferior com foto, nota em estrelas, posição no ranking, horário e botão *"Traçar Rota a Pé / De Carro"*.

---

### 4.4. Mecânica Social: Avaliações, Estrelas, Curtidas, Score e Rankings Comunitários

A inclusão de prova social transforma os 27 aplicativos de guias estáticos em uma **rede dinâmica e colaborativa**, aumentando o tempo de permanência, o engajamento e a precisão do algoritmo de roteiros.

```
┌────────────────────────────────────────────────────────────────────────┐
│               FLUXO DA MECÂNICA SOCIAL & OFFLINE-FIRST                 │
├────────────────────────────┬─────────────────────────────┬─────────────┤
│      APP (CLIENTE)         │      OFFLINE LOCAL          │   BACKEND   │
│ ┌────────────────────────┐ │ ┌─────────────────────────┐ │ ┌─────────┐ │
│ │ ❤️ Curtida (1 Toque)   │─┼─►│ Grava no user.sqlite   │ │ │Pocket-  │ │
│ │ ⭐ Estrelas (1 a 5)    │ │ │ (fila pendente de sync) │ │ │Base     │ │
│ │ 🏆 Badge #1 no Ranking │ │ └───────────┬─────────────┘ │ │ & Post- │ │
│ └────────────────────────┘ │             │ (ao ter net)  │ │ greSQL  │ │
│                            │             └───────────────┼►│Recalcula│ │
│ ┌────────────────────────┐ │ ┌─────────────────────────┐ │ │Scores & │ │
│ │ Exibe médias & ranks   │◄┼─┤ Lê do pack.sqlite       │◄┼─┤Rankings │ │
│ │ sem gastar internet    │ │ │ (dados consolidados)    │ │ └─────────┘ │
│ └────────────────────────┘ │ └─────────────────────────┘ │             │
└────────────────────────────┴─────────────────────────────┴─────────────┘
```

#### 1. Componentes de Prova Social e Interface:
* **Curtida Rápida (❤️ com 1 Toque):**
  * Ícone flutuante em cada card de atração e foto de capa.
  * Tocar salva instantaneamente o ponto na aba *"Salvos/Favoritos"* e incrementa o contador local com animação háptica suave.
* **Sistema de Avaliação por Estrelas (⭐ 1.0 a 5.0):**
  * Modal interativo com toque nas 5 estrelas exibido ao final da visita ou na tela de detalhes.
  * Exibição visual de média ponderada e volume de votos (ex: `⭐ 4.9 (1.420 avaliações)`).
* **Badges de Ranking Estadual e Municipal:**
  * Selos visuais com destaque dourado/prateado nos cards:
    * `🥇 #1 Mais Curtida de Pernambuco`
    * `🥈 #2 em Gastronomia de Olinda`
    * `🥉 Top 5 Escolha dos Viajantes`
* **Carrossel Temático na Home:**
  * Seção *"Os Mais Votados do Estado"* destacando os campeões de preferência dos turistas.

#### 2. Alimentação do Algoritmo de Roteirização (Score Comunitário Dinâmico):
* O algoritmo VRP local consome a pontuação para decidir a ordem e prioridade dos locais no itinerário.
* **Fórmula do Score Comunitário:**
  $$\text{Score} = (\text{Média Estrelas} \times 0.40) + (\text{Curtidas Normalizadas} \times 0.30) + (\text{Peso Editorial Curadoria} \times 0.30)$$
* Atrações com maiores notas e curtidas sobem organicamente no ranking e tornam-se paradas prioritárias nos roteiros automáticos.

#### 3. Arquitetura Técnica Offline-First e Sincronização Assíncrona:
* **Consumo 100% Offline:** Os valores consolidados (`rating_avg`, `rating_count`, `likes_count`, `rank_posicao`) são pré-compilados pelo backend dentro do `pack.sqlite`. O turista visualiza estrelas e rankings sem gastar 1 byte de dados móveis.
* **Gravação Desconectada:** Quando o usuário curte ou avalia sem internet, o voto é salvo na tabela `pending_votes` do banco local `user.sqlite`.
* **Sync em Background Silencioso:** Um worker do app escuta o status da rede. Ao detectar Wi-Fi ou sinal de dados, despacha os votos acumulados via endpoint leve (`POST /api/v1/telemetry/vote`) e atualiza o estado local.

#### 4. Estratégia de Segurança e Aprovação Rápida nas Lojas (Apple e Google):
* **Foco em Métricas Numéricas (Fase 1 e Piloto):**
  * A interação é restrita a **estrelas, curtidas e seleções de tags**.
  * **Não implementar comentários de texto aberto nesta etapa inicial:** Isso evita que a Apple classifique o app como *User Generated Content (UGC)* irrestrito, dispensando a exigência burocrática de moderação humana em tempo real, termos de bloqueio de usuários e filtros de linguagem que costumam atrasar a aprovação da versão 1.0.

---

## 5. Fases de Implementação e Status Operacional

---

### FASE 1: Fundação do App Mobile (Flutter Multi-Flavor) `[CONCLUÍDO] ✅`
*Objetivo: Criar a base de código único capaz de compilar os 27 aplicativos com marcas e configurações dinâmicas.*

* [x] **Configuração de Product Flavors:**
  * 27 variantes estruturadas no Gradle/Xcode (`pe`, `sp`, `rj`, `ba`, `mg`, etc.).
  * Definição de `applicationId` por estado (ex: `com.onetour.pe`, `com.onetour.sp`).
  * Estrutura de assets dinâmicos por flavor (`assets/flavors/pe/` com ícones, logos, splash e brasão).
  * Paleta de cores dinâmica e tokens de estilo configurados via `FlavorConfig`.
* [x] **Design System Base:**
  * Componentes reutilizáveis: Cards de atrações, carrossel de cidades, barra de busca preditiva, chips de categorias e filtros rápidos.
  * Suporte nativo completo a **Modo Escuro (Dark Mode)** e **Modo Claro (Light Mode)**.
* [x] **Navegação Modular (GoRouter):**
  * Rotas declarativas estruturadas: `/` (Splash), `/cidades`, `/cidade/:id`, `/roteiros`, `/roteiro/novo`, `/mapa`, `/favoritos`.

---

### FASE 2: Infraestrutura de Servidor (VPS + Easypanel) `[CONCLUÍDO] ✅`
*Objetivo: Subir a infraestrutura autônoma, de baixo custo fixo e alta capacidade de entrega.*

* [x] **Setup da VPS com Easypanel:**
  * Orquestração Docker completa com proxy reverso e certificados SSL automáticos (Let's Encrypt).
* [x] **Deploy do PocketBase Permanente (Backoffice & CMS):**
  * Instância permanente criada no Easypanel: `https://onetour-pocketbase-estados.gtalg3.easypanel.host/`
  * Volume de armazenamento persistente montado no host (`/pb_data`), garantindo que dados, uploads e superusers nunca sejam resetados em redeploys.
  * Compatibilidade com **PocketBase v0.23**: Autenticação via `_superusers` e schema JSON migrado (`server/pocketbase/pb_schema_v23_ready.json`).
  * Coleções estruturadas e ativas:
    * `estados` (sigla, nome, status, versao_pacote).
    * `cidades` (nome, estado_id, lat, lon, capa, destaque, tags).
    * `atracoes` (nome, categoria, horário, duração, fotos, gratuito, kid_friendly, rating_avg, rating_count, likes_count, rank_posicao).
    * `campanhas_push` (titulo, mensagem, imagem, topico, segmento, data_agendamento, status).
* [x] **Deploy do PostgreSQL com Extensão PostGIS:**
  * Contêiner PostgreSQL 16 + PostGIS ativo na rede interna do Easypanel (`postgres-onetour:5432`, database `onetour`).
  * Tabelas de telemetria analítica, eventos de publicidade (impressões, cliques, CTR) e persistência de votos comunitários.
* [x] **Carga Inicial de Dados (Seed Automático):**
  * Script de seed executado com sucesso (`server/pocketbase/seed_pe.js`), cadastrando 5 cidades polo de Pernambuco e 5 atrações âncora com regras de leitura pública (HTTP 200 OK).

---

### FASE 3: Motor de Turismo Offline e Roteirizador Inteligente `[CONCLUÍDO] ✅`
*Objetivo: Replicar o modelo do Trip AI Plan, com geração instantânea de itinerários sem custo de IA por chamada.*

* [x] **Pipeline de Geração de Pacotes de Cidades:**
  * Geração do banco SQLite compactado `pack.sqlite` para cada cidade:
    * Tabela `place`: Pontos turísticos, restaurantes, praias, museus com atributos pré-classificados (`score`, `fame`, `rating_avg`, `likes_count`, `rank_posicao`).
    * Tabela `matrix`: Matriz pré-computada de distância e tempo a pé e de carro entre os principais pontos da cidade.
* [x] **Algoritmo de Roteirização Local no App:**
  * Implementação em Dart do algoritmo combinatório (VRP com janelas de tempo):
    * Entrada: Quantidade de dias (1 a 7), interesses (história, praias, gastronomia), perfil (família/solo) e ritmo (tranquilo ou intenso).
    * Saída: Cronograma hora a hora em menos de 1 segundo, agrupando atrações por proximidade geográfica para evitar deslocamentos desnecessários.
    * Inserção automática de pausas de almoço (`is_lunch`) e cálculo de tempo de trajeto sem gastar dados móveis.
* [x] **Integração do Mapa com MapLibre GL:**
  * Renderização de camadas vetoriais via PMTiles sem consumo de internet.
  * Plotagem dos pins das atrações do roteiro e traçado da rota conectando as paradas do dia.

---

### FASE 4: Rede Própria de Anúncios (House Ads) & Admin Command Center `[CONCLUÍDO] ✅`
*Objetivo: Monetizar, gerar tráfego cruzado e gerenciar métricas e moderação em tempo real.*

* [x] **Componente House Ads no Flutter:**
  * Bloco de Banner Nativo (integrado de forma orgânica no feed de atrações).
  * Card em Destaque no Topo da Cidade (ex: "Pousada Recomendada", "Passeio de Barco").
  * Intersticial Suave (exibido apenas ao salvar ou exportar um roteiro).
* [x] **Serviço de Entrega de Anúncios (API v2 / Ad Server):**
  * Endpoints parametrizados por `uf`, `cidade` e `posicao` (`GET /api/v1/ads/serve`).
  * Endpoints de ingestão de telemetria (`POST /api/v1/telemetry/event` e `POST /api/v1/telemetry/vote`).
  * Recálculo automático e manual de scores e rankings comunitários no PostgreSQL.
* [x] **One Tour Admin Web Command Center:**
  * Aplicação web moderna em React + Vite + Tailwind + Lucide Icons deployed em:  
    `https://onetour-frontend-onetour.gtalg3.easypanel.host/`
  * Autenticação integrada com o PocketBase v0.23 (`_superusers`).
  * Dashboard com métricas consolidadas de impressões, cliques e CTR.
  * Moderação e curadoria de avaliações, controle de pesos editoriais e recálculo instantâneo de rankings.
  * Disparador visual de notificações push conectado diretamente à API.

---

### FASE 5: Sistema de Push Notificações Segmentadas `[CONCLUÍDO] ✅`
*Objetivo: Engajamento contínuo, envio de promoções, alertas de eventos, novidades e ofertas locais.*

```mermaid
graph LR
    Admin[Admin Web Command Center] -->|Disparar Push| API[One Tour API v2]
    API -->|Valida Superuser JWT| PocketBase[PocketBase v0.23]
    API -->|Firebase Admin SDK| FCM[Google Cloud FCM]
    FCM -->|Tópico: pe_geral| Phone1[Samsung Galaxy - PE Geral]
    FCM -->|Tópico: pe_porto_de_galinhas| Phone2[Samsung Galaxy - Porto]
    FCM -->|Tópico: global_ofertas| AllUsers[Todos os Usuários]
```

* [x] **Integração com Firebase Admin SDK Oficial:**
  * SDK oficial `firebase-admin` (v14.5.0) integrado na API (`house_ads/server/src/services/fcm.ts`).
  * Conectado à conta de serviço oficial do Google Cloud (Projeto: `app-onetour`).
  * Chave de serviço configurada com segurança em Base64 no Easypanel via variável de ambiente `FIREBASE_SERVICE_ACCOUNT`.
* [x] **Suporte a Rich Notifications com Imagem Expandida (BigPictureStyle):**
  * Mapeamento de `notification.imageUrl` e `android.notification.imageUrl` no payload FCM.
  * Renderização de banners grandes de promoções e fotos de capa na bandeja de notificações do Android.
* [x] **Arquitetura de Tópicos e Segmentação Geográfica:**
  * Inscrição automática no Flutter para tópicos estaduais (`pe_geral`, `pe_promocoes`, `pe_eventos`) e municipais (`pe_recife`, `pe_porto_de_galinhas`, `pe_olinda`, `pe_carneiros`, `pe_noronha`, `global_ofertas`).
  * Suporte a envio por tópicos e envio direto por Token individual de dispositivo.
* [x] **Validação Prática em Hardware Físico Real:**
  * App instalado no smartphone **Samsung Galaxy A075M** (`com.onetour.pe`).
  * Notificações disparadas com sucesso via Admin Web e curl com entrega confirmada em tempo real e visualização expandida (Big Picture).

---

### FASE 6: Piloto e Validação (App Modelo: Pernambuco) `[CONCLUÍDO] ✅`
*Objetivo: Lançar e validar 100% das funcionalidades em um estado polo antes da replicação em massa.*

* [x] **Cadastramento de Dados Reais de Pernambuco:**
  * 5 Cidades Polo inseridas no PocketBase: Recife, Porto de Galinhas, Olinda, Praia dos Carneiros, Fernando de Noronha.
  * 5 Atrações Âncora cadastradas com fotos, horários e geolocalização: Marco Zero, Piscinas Naturais, Alto da Sé, Igrejinha dos Carneiros, Baía do Sancho.
  * 3 Campanhas promocionais push cadastradas no banco de dados.
* [x] **Validação do Ciclo Completo em Dispositivo Físico:**
  * APK Release compilado com sucesso (`mobile/build/app/outputs/flutter-apk/app-pe-release.apk`, 52.7 MB).
  * Instalação via ADB no Samsung Galaxy SM-A075M (`R9QL1043H7H`).
  * Validação de funcionamento offline, algoritmo de itinerários, exibição de cards patrocinados e recebimento de push em segundo plano.
* [ ] **Publicação nas Lojas:**
  * Geração do bundle `.aab` assinado com Keystore de produção e submissão na Google Play Console (Próxima etapa).

---

### FASE 7: Industrialização e Rollout para os 27 Estados `[ESTRUTURA CONCLUÍDA / ROLLOUT AGENDADO] 🟡`
*Objetivo: Automatizar a esteira para compilar, assinar e subir os 26 estados restantes em lote.*

* [x] **Configuração da Esteira de CI/CD (Fastlane + GitHub Actions):**
  * Script `mobile/android/fastlane/Fastfile` implementado com suporte à iteração de todos os 27 estados:
    ```ruby
    estados = ['pe', 'sp', 'rj', 'ba', 'mg', 'ce', 'pr', 'sc', 'rs', ...]
    estados.each do |uf|
      lane "deploy_#{uf}".to_sym do
        build_android_app(flavor: uf)
        upload_to_play_store(track: 'production', package_name: "com.onetour.#{uf}")
      end
    end
    ```
  * Workflow automatizado `.github/workflows/rollout_27_estados.yml` para compilação em matriz paralela.
* [x] **Matriz de Cidades por Estado:**
  * Schemas do PocketBase e scripts de ingestão em lote preparados para importação de dados de outros estados.
* [ ] **Lançamento Escalonado por Regiões:**
  * **Onda 1 (Prioridade Imediata):** Nordeste (9 estados: PE, AL, PB, CE, RN, SE, BA, PI, MA).
  * **Onda 2:** Sudeste (4 estados: SP, RJ, MG, ES).
  * **Onda 3:** Sul (3 estados: PR, SC, RS).
  * **Onda 4:** Centro-Oeste e Norte (11 estados + DF).

---

## 6. Matriz de Entregáveis e Cronograma Consolidado

| Fase | Foco Principal | Status Atual | Marco / Conclusão |
| :---: | :--- | :---: | :---: |
| **Fase 1** | Base Flutter Multi-Flavor & Design System | **CONCLUÍDO** ✅ | 27 Flavors, Riverpod, GoRouter e Dark Mode |
| **Fase 2** | VPS, Easypanel, PocketBase & PostgreSQL | **CONCLUÍDO** ✅ | Volume persistente, PB v0.23, Postgres 16 (24/10/2026) |
| **Fase 3** | Motor Offline (PMTiles + SQLite + Algoritmo de Roteiro) | **CONCLUÍDO** ✅ | Algoritmo VRP em Dart, pack.sqlite e MapLibre |
| **Fase 4** | Servidor House Ads & Admin Web Command Center | **CONCLUÍDO** ✅ | Admin Web React + Ad Server API no ar (24/10/2026) |
| **Fase 5** | Módulo de Push Notificações Segmentadas (FCM) | **CONCLUÍDO** ✅ | Firebase Admin oficial, BigPicture e Hardware testado (24/10/2026) |
| **Fase 6** | App Piloto (Pernambuco) & Validação em Produção | **CONCLUÍDO** ✅ | Seed PE, APK Release instalado no Samsung A075M (24/10/2026) |
| **Fase 7** | Automação CI/CD Fastlane e Rollout dos 27 Estados | **ESTRUTURA PRONTA** 🟡 | Fastlane e GitHub Actions prontos para submissão |
| **Total** | **Ecossistema Completo Operacional** | **90% GLOBAL** 🚀 | **Fases 1 a 6 100% Funcionais em Produção** |

---

## 7. Próximos Passos Imediatos

1. **Submissão na Google Play Store (App Piloto PE):**
   * Gerar o Android App Bundle (`.aab`) assinado via `flutter build appbundle --flavor pe --target lib/main_pe.dart`.
   * Realizar upload na Google Play Console sob a faixa de testes internos para o identificador `com.onetour.pe`.
2. **Hospedagem dos Arquivos de Mapas Vetoriais (.pmtiles):**
   * Fazer upload dos arquivos PMTiles gerados das cidades polo para o bucket S3 / MinIO ou CDN para downloads offline pelo app.
3. **Execução do Rollout da Onda 1 (Nordeste):**
   * Disparar a esteira Fastlane para compilar e empacotar os estados limítrofes (Alagoas `com.onetour.al`, Paraíba `com.onetour.pb` e Ceará `com.onetour.ce`), ativando a rede de anúncios cruzados (Cross-Promotion).
