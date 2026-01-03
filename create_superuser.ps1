# Script para crear un superusuario
# Uso: .\create_superuser.ps1

$PYTHON_PATH = "C:\Users\LENOVO\AppData\Local\Programs\Python\Python310\python.exe"

Write-Host "=== Crear Superusuario ===" -ForegroundColor Cyan
Write-Host ""

& $PYTHON_PATH manage.py createsuperuser
