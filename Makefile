.PHONY: setup start stop restart validate test lint security logs

setup:
	bash scripts/setup.sh

start:
	docker compose up --build -d

stop:
	docker compose down

restart:
	bash scripts/restart.sh

validate:
	bash scripts/validate.sh

test:
	npm test

lint:
	npm run lint

security:
	npm audit --audit-level=high

logs:
	docker compose logs -f app
