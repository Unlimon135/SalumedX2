# Script para iniciar el servidor WebSocket de SaluMedX
# Este script arranca el servidor Node.js con todas las dependencias configuradas

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  INICIANDO SERVIDOR WEBSOCKET - SALUMEDX" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Detener cualquier proceso Node anterior
Write-Host "Limpiando procesos anteriores..." -ForegroundColor Yellow
Get-Process -Name node -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

Start-Sleep -Seconds 2

# Navegar a la carpeta correcta
cd websocket_web2

Write-Host "Iniciando servidor en puerto 8080..." -ForegroundColor Blue
Write-Host ""

# Iniciar el servidor
npm run dev

Write-Host ""
Write-Host "Para probar:" -ForegroundColor Green
Write-Host "1. Abre http://localhost:8080/client.html en tu navegador"
Write-Host "2. Ejecuta .\test-notifications.ps1 desde otra terminal"
Write-Host ""
