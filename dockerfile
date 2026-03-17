FROM mcr.microsoft.com/playwright:v1.49.0-noble AS builder

ARG PNPM_VERSION=9.1.4

WORKDIR /build

RUN corepack enable && \
    corepack prepare pnpm@${PNPM_VERSION} --activate && \
    mkdir -p /root/.cache && \
    ln -s /ms-playwright /root/.cache/ms-playwright

COPY package.json pnpm-lock.yaml tsconfig.json gulpfile.js index.js ./
COPY nodes ./nodes

RUN pnpm install --frozen-lockfile --ignore-scripts && \
    pnpm build && \
    pnpm run setup && \
    npm pack

FROM mcr.microsoft.com/playwright:v1.49.0-noble

ARG N8N_VERSION=1.79.3

ENV NODE_ENV=production \
    N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true \
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1

USER root

RUN npm install -g n8n@${N8N_VERSION} && \
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

CMD ["n8n", "start"]
