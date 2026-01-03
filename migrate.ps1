# Script para hacer migraciones
# Uso: .\migrate.ps1

$PYTHON_PATH = "C:\Users\LENOVO\AppData\Local\Programs\Python\Python310\python.exe"

Write-Host "=== Migraciones de Base de Datos ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "Creando migraciones..." -ForegroundColor Yellow
& $PYTHON_PATH manage.py makemigrations

Write-Host ""
Write-Host "Aplicando migraciones..." -ForegroundColor Yellow
& $PYTHON_PATH manage.py migrate

Write-Host ""
Write-Host "¡Migraciones completadas!" -ForegroundColor Green
