# ---------- Backend ----------
run-backend:
	cd backend && python main.py

test-backend:
	cd backend && pytest -q

coverage-backend:
	cd backend && pytest --cov=main --cov-report=term-missing

# ---------- Frontend ----------
run-frontend:
	cd frontend && flutter run

test-frontend:
	cd frontend && flutter test

# ---------- CI/CD helpers ----------
format:
	black backend

lint:
	flake8 backend
	cd frontend && flutter analyze
