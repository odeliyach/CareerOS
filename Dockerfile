# Dockerfile for N8N with Ollama Integration on Render

# Use the official N8N base image
FROM n8nio/n8n:latest

# Install curl for healthcheck
RUN apk add --no-cache curl

# Configure for Render environment
ENV NODE_ENV=production
ENV N8N_PORT=5678

# Database and other runtime credentials are passed via environment variables at runtime
ENV DB_TYPE=postgres

# Expose port 5678 for N8N
EXPOSE 5678

# Health check to ensure the service is running
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD curl --fail http://localhost:5678/ || exit 1

# Start N8N
CMD ["n8n"]