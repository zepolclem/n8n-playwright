FROM mcr.microsoft.com/playwright:v1.58.2-noble AS builder

ARG PNPM_VERSION=9.1.4

WORKDIR /build

RUN corepack enable && \
    corepack prepare pnpm@${PNPM_VERSION} --activate

COPY package.json pnpm-lock.yaml tsconfig.json gulpfile.js index.js ./
COPY nodes ./nodes

RUN pnpm install --frozen-lockfile --ignore-scripts && \
    pnpm build && \
    pnpm run setup && \
    npm pack

FROM n8nio/n8n:2.12.2 AS n8n

FROM mcr.microsoft.com/playwright:v1.58.2-noble

ENV NODE_ENV=production \
    N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true \
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 \
    N8N_RELEASE_TYPE=stable \
    NODE_PATH=/usr/local/lib/node_modules/n8n/node_modules

USER root

COPY --from=n8n /usr/local/lib/node_modules/n8n /usr/local/lib/node_modules/n8n

RUN apt-get update && \
    apt-get install -y --no-install-recommends python3-venv build-essential && \
    rm -rf /var/lib/apt/lists/* && \
    ln -s /usr/local/lib/node_modules/n8n/bin/n8n /usr/local/bin/n8n && \
    npm rebuild --prefix /usr/local/lib/node_modules/n8n sqlite3 && \
    npm rebuild --prefix /usr/local/lib/node_modules/n8n isolated-vm && \
    useradd --create-home --shell /bin/bash node && \
    mkdir -p /home/node/.n8n/nodes

WORKDIR /home/node/.n8n/nodes

COPY --from=builder /build/*.tgz /tmp/n8n-nodes-playwright.tgz

RUN npm install --omit=dev --ignore-scripts /tmp/n8n-nodes-playwright.tgz && \
    rm /tmp/n8n-nodes-playwright.tgz && \
    chown -R node:node /home/node

USER node

WORKDIR /home/node/.n8n

EXPOSE 5678

CMD ["n8n"]
