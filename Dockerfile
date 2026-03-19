FROM n8nio/n8n:latest

ENV NODE_ENV=production
ENV N8N_PORT=5678
ENV DB_TYPE=postgresdb  # ← Changed from "postgres" to "postgresdb"

EXPOSE 5678

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:5678/ || exit 1

CMD ["n8n"]
