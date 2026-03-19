FROM n8nio/n8n:latest

ENV NODE_ENV=production
ENV N8N_PORT=5678
ENV DB_TYPE=sqlite

# WHY this line: n8n blocks env var access in Code nodes by default for security.
# NODE_FUNCTION_ALLOW_ENV tells n8n which specific vars to expose via $env.
# Without this, $env.GITHUB_TOKEN throws "access to env vars denied".
ENV NODE_FUNCTION_ALLOW_ENV=GITHUB_TOKEN,GROQ_API_KEY

EXPOSE 5678
