# CareerOS — Makefile
# Usage: make start | make stop | make logs | make restart

.PHONY: start stop logs restart status

start:
	@echo "Starting CareerOS (n8n)..."
	docker compose up -d
	@echo "n8n running at http://localhost:5679"

stop:
	@echo "Stopping CareerOS..."
	docker compose down

restart:
	@echo "Restarting CareerOS..."
	docker compose down && docker compose up -d

logs:
	docker compose logs -f n8n

status:
	docker compose ps
