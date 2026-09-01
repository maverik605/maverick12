# ---------------------------------------------------------------------------
# MAVERICK — production image (Railway / any container host)
# ---------------------------------------------------------------------------
FROM node:20-slim AS build
WORKDIR /app

# Build tools in case better-sqlite3 needs to compile from source.
RUN apt-get update -y && apt-get install -y --no-install-recommends python3 make g++ \
    && rm -rf /var/lib/apt/lists/*

COPY package*.json ./
RUN npm ci --omit=dev || npm install --omit=dev

# ---- runtime ----
FROM node:20-slim
WORKDIR /app
ENV NODE_ENV=production

# Persistent data lives here; Railway mounts a volume at /app/.data
ENV DB_PATH=/app/.data/maverick.db
ENV MEDIA_DIR=/app/.data/uploads

# Copy production deps from build stage, then the app source.
COPY --from=build /app/node_modules ./node_modules
COPY . .

# Ensure the data dir exists (a volume may not be mounted locally).
RUN mkdir -p /app/.data/uploads && chown -R node:node /app/.data

USER node
EXPOSE 3001
CMD ["node", "server/index.js"]
