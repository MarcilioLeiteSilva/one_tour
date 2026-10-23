FROM alpine:latest

ARG PB_VERSION=0.22.20

RUN apk add --no-cache \
    unzip \
    ca-certificates \
    wget

# Download e instalação do binário oficial do PocketBase
RUN wget https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_amd64.zip \
    && unzip pocketbase_${PB_VERSION}_linux_amd64.zip -d /pb \
    && rm pocketbase_${PB_VERSION}_linux_amd64.zip \
    && chmod +x /pb/pocketbase

WORKDIR /pb

# Copia migrações pré-configuradas para dentro da imagem
COPY pb_migrations /pb/pb_migrations

EXPOSE 8090

VOLUME ["/pb/pb_data"]

CMD ["/pb/pocketbase", "serve", "--http=0.0.0.0:8090", "--dir=/pb/pb_data", "--migrationsDir=/pb/pb_migrations"]
