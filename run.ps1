# Script para ejecutar el proyecto Farmacia Service
# Uso: .\run.ps1

$PYTHON_PATH = "C:\Users\LENOVO\AppData\Local\Programs\Python\Python310\python.exe"

Write-Host "=== Farmacia Service ===" -ForegroundColor Cyan
Write-Host ""

# Verificar que existe manage.py
if (!(Test-Path "manage.py")) {
    Write-Host "Error: No se encuentra manage.py" -ForegroundColor Red
    exit 1
}

# Ejecutar el servidor
Write-Host "Iniciando servidor en puerto 8002..." -ForegroundColor Green
& $PYTHON_PATH manage.py runserver 8002
