# Variables
PYTHON=python3
FLASK_APP=main.py
TEST_DIR=test

# Démarrer le serveur Flask
run:
	FLASK_ENV=development $(PYTHON) $(FLASK_APP)

# Installer les dépendances
install:
	pip install -r requirements.txt

# Lancer les tests unitaires
test:
	pytest -v $(TEST_DIR)

# Lancer les tests avec coverage (console + HTML)
coverage:
	pytest --cov=main --cov-report=term-missing --cov-report=html $(TEST_DIR)
	@echo "📊 Rapport HTML généré dans htmlcov/index.html"

# Ouvrir le rapport coverage (Mac)
open-report:
	open htmlcov/index.html

# Nettoyer
clean:
	rm -rf __pycache__ */__pycache__ .pytest_cache htmlcov .coverage
