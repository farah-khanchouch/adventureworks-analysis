@echo off
echo Creation de la structure du projet AdventureWorks...

REM Créer les dossiers principaux
mkdir docs
mkdir docs\exploration
mkdir docs\data-quality
mkdir docs\visualizations

mkdir sql-scripts
mkdir sql-scripts\exploration
mkdir sql-scripts\cleaning
mkdir sql-scripts\analysis

mkdir etl
mkdir etl\knime-workflows
mkdir etl\pentaho-jobs

mkdir dashboards
mkdir dashboards\powerbi
mkdir dashboards\tableau

mkdir reports

echo Structure creee avec succes!
pause
