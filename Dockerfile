# Dockerfile for N8N on Render

# Use the official N8N base image
FROM n8nio/n8n:latest

# Configure for Render environment
ENV NODE_ENV=production
ENV N8N_PORT=5678
ENV DB_TYPE=postgresdb

# Expose port 5678 for N8N
EXPOSE 5678

# Health check
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:5678/ || exit 1

# Start N8N
CMD ["n8n"]
