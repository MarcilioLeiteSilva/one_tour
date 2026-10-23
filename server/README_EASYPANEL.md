# Guia de Infraestrutura e Deploy no Easypanel (Fase 2)

Este guia orienta o deploy da infraestrutura de backend autônoma do **Ecossistema One Tour** usando uma VPS Linux comum (Hetzner, Hostinger, Contabo ou Linode) gerenciada pelo **Easypanel**.

---

## 1. Requisitos da VPS
* **Sistema Operacional:** Ubuntu 22.04 LTS ou Ubuntu 24.04 LTS (64-bit)
* **Hardware Mínimo Recomendado:**
  * 2 vCPUs
  * 4 GB de RAM (mínimo 2 GB)
  * 40 GB SSD / NVMe
* **Portas Abertas no Firewall:** 80 (HTTP), 443 (HTTPS), 3000 (Painel Easypanel).

---

## 2. Instalação do Easypanel na VPS (1 Comando)

Acesse sua VPS via SSH e execute:

```bash
curl -sSL https://get.easypanel.io | sh
```

O script instalará o Docker e o Easypanel automaticamente. Ao final, acesse o painel pelo navegador:
`http://SEU_IP_DA_VPS:3000` e crie a conta de administrador inicial.

---

## 3. Deploy dos Serviços no Easypanel

No Easypanel, crie um novo **Projeto** chamado `one-tour`.

### Método 1: Via Docker Compose (Mais Rápido e Recomendado)
1. Dentro do projeto `one-tour`, clique em **+ Service** → **Compose**.
2. Cole o conteúdo de [server/docker-compose.yml](file:///f:/One_tour/server/docker-compose.yml).
3. Na aba **Environment**, cole as variáveis de [server/.env.example](file:///f:/One_tour/server/.env.example).
4. Clique em **Deploy**.

---

### Método 2: Serviços Individuais no Painel

Caso prefira gerenciar cada serviço isoladamente na interface:

#### Serviço A: PocketBase (CMS & Mídias)
* **Tipo:** App (Docker Image)
* **Imagem:** `ghcr.io/muchobien/pocketbase:latest`
* **Porta:** `8090`
* **Domínio:** `cms.onetour.app` (com SSL automático ativado)
* **Montagem de Volumes Persistentes:**
  * `/pb_data` → Volume `onetour_pb_data`
  * `/pb_migrations` → Montar pasta local contendo as migrações criadas em `server/pocketbase/pb_migrations/`
* **Healthcheck:** `GET /api/health`

#### Serviço B: PostgreSQL 16 + PostGIS (Ad Server & Telemetria)
* **Tipo:** Database / App
* **Imagem:** `postgis/postgis:16-3.4`
* **Porta Interna:** `5432`
* **Variáveis:**
  * `POSTGRES_DB`: `onetour_ads`
  * `POSTGRES_USER`: `onetour_admin`
  * `POSTGRES_PASSWORD`: *(Definir senha forte)*
* **Script de Inicialização:**
  * Montar [server/postgres/init.sql](file:///f:/One_tour/server/postgres/init.sql) em `/docker-entrypoint-initdb.d/init.sql`.

#### Serviço C: MinIO (CDN de Mapas e Bancos SQLite)
* **Tipo:** App
* **Imagem:** `minio/minio:latest`
* **Comando:** `server /data --console-address ":9001"`
* **Portas:** `9000` (API S3) e `9001` (Console Web)
* **Domínio:** `cdn.onetour.app` apontando para a porta `9000`.

---

## 4. Apontamento de DNS (Cloudflare / Registro.br)

Crie os registros do tipo `A` apontando para o IP da sua VPS:

| Tipo | Subdomínio | Destino | Função |
| :---: | :--- | :--- | :--- |
| `A` | `cms.onetour.app` | `IP_DA_VPS` | Painel PocketBase para editores e mídias |
| `A` | `ads.onetour.app` | `IP_DA_VPS` | API de Telemetria e entrega de anúncios |
| `A` | `cdn.onetour.app` | `IP_DA_VPS` | Download de arquivos pesados (`.pmtiles`, `pack.sqlite`) |

---

## 5. Primeiro Acesso ao Backoffice (PocketBase)

1. Abra no navegador: `https://cms.onetour.app/_/`
2. Crie o superusuário de administração (E-mail e Senha).
3. Verifique que as coleções criadas pelas migrações automáticas já estão presentes:
   * `estados` (com o registro de Pernambuco já cadastrado).
   * `cidades` (com Recife, Olinda, Porto de Galinhas, Carneiros e Noronha).
   * `atracoes` (com os pontos turísticos e scores iniciais).
   * `campanhas_ads` (com a primeira campanha da House Ads configurada).
