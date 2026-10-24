FROM node:22-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN if [ -f package-lock.json ]; then npm ci; else npm install; fi

ARG VITE_API_BASE_URL=https://onetour-api-onetour.gtalg3.easypanel.host
ARG VITE_POCKETBASE_URL=https://onetour-pocketbase-estados.gtalg3.easypanel.host
ENV VITE_API_BASE_URL=$VITE_API_BASE_URL
ENV VITE_POCKETBASE_URL=$VITE_POCKETBASE_URL

COPY tsconfig*.json vite.config.ts index.html ./
COPY src/ ./src/

RUN npm run build

FROM nginx:alpine AS runner

COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
