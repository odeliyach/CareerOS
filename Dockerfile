FROM n8nio/n8n:latest

ENV NODE_ENV=production
ENV N8N_PORT=5678
ENV DB_TYPE=postgresdb
ENV N8N_PROTOCOL=https
ENV WEBHOOK_URL=https://${RENDER_EXTERNAL_HOSTNAME}

EXPOSE 5678

HEALTHCHECK --interval=30s --timeout=10s --retries=5 \
  CMD node -e "require('http').get('http://localhost:5678/healthz', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})"
