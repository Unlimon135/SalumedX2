# Script de prueba para Windows (PowerShell)
# Usage: .\test-notifications.ps1

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  PRUEBA DEL SISTEMA DE NOTIFICACIONES - SALUMEDX" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

$WS_URL = "http://localhost:8080"
$API_ENDPOINT = "$WS_URL/api/notifications"

# 1. Verificar si el servidor está corriendo
Write-Host "1. Verificando si el servidor WebSocket está corriendo..." -ForegroundColor Blue
try {
    $response = Invoke-WebRequest -Uri $WS_URL -Method Get -TimeoutSec 5 -ErrorAction Stop
    Write-Host "✅ Servidor WebSocket respondiendo en $WS_URL" -ForegroundColor Green
} catch {
    Write-Host "❌ No se puede conectar a $WS_URL" -ForegroundColor Red
    Write-Host "Asegúrate de ejecutar: cd app/websocket_service/websocket_web2; npm run dev" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# 2. Enviar notificación de producto
Write-Host "2. Enviando notificación de prueba: PRODUCT_CREATED" -ForegroundColor Blue

$timestamp = [System.DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ss.000Z")
$bodyProducto = @{
    type = "PRODUCT_CREATED"
    data = @{
        id = 1
        nombre_comercial = "Paracetamol 500mg"
        nombre_generico = "Acetaminofén"
        precio = 5.50
        mensaje = "Nuevo producto: Paracetamol 500mg"
    }
    timestamp = $timestamp
    user = "test_admin"
} | ConvertTo-Json

try {
    $response = Invoke-WebRequest -Uri $API_ENDPOINT `
        -Method Post `
        -Headers @{"Content-Type" = "application/json"} `
        -Body $bodyProducto `
        -ErrorAction Stop
    
    Write-Host "✅ Notificación de producto enviada (Status: $($response.StatusCode))" -ForegroundColor Green
    Write-Host "Respuesta: $($response.Content)" -ForegroundColor Gray
} catch {
    Write-Host "❌ Error enviando notificación: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# 3. Enviar notificación de farmacia
Write-Host "3. Enviando notificación de prueba: PHARMACY_CREATED" -ForegroundColor Blue

$timestamp = [System.DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ss.000Z")
$bodyFarmacia = @{
    type = "PHARMACY_CREATED"
    data = @{
        id = 1
        nombre = "Farmacia Central"
        direccion = "Calle Principal 123"
        telefono = "555-1234"
        mensaje = "Nueva farmacia: Farmacia Central"
    }
    timestamp = $timestamp
    user = "test_admin"
} | ConvertTo-Json

try {
    $response = Invoke-WebRequest -Uri $API_ENDPOINT `
        -Method Post `
        -Headers @{"Content-Type" = "application/json"} `
        -Body $bodyFarmacia `
        -ErrorAction Stop
    
    Write-Host "✅ Notificación de farmacia enviada (Status: $($response.StatusCode))" -ForegroundColor Green
    Write-Host "Respuesta: $($response.Content)" -ForegroundColor Gray
} catch {
    Write-Host "❌ Error enviando notificación: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# 4. Enviar notificación de relación
Write-Host "4. Enviando notificación de prueba: PRODUCT_PHARMACY_RELATION_CREATED" -ForegroundColor Blue

$timestamp = [System.DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ss.000Z")
$bodyRelacion = @{
    type = "PRODUCT_PHARMACY_RELATION_CREATED"
    data = @{
        id = 1
        producto_id = 1
        farmacia_id = 1
        precio = 5.99
        stock = 100
        mensaje = "Nueva relación: Producto 1 en Farmacia 1"
    }
    timestamp = $timestamp
    user = "test_admin"
} | ConvertTo-Json

try {
    $response = Invoke-WebRequest -Uri $API_ENDPOINT `
        -Method Post `
        -Headers @{"Content-Type" = "application/json"} `
        -Body $bodyRelacion `
        -ErrorAction Stop
    
    Write-Host "✅ Notificación de relación enviada (Status: $($response.StatusCode))" -ForegroundColor Green
    Write-Host "Respuesta: $($response.Content)" -ForegroundColor Gray
} catch {
    Write-Host "❌ Error enviando notificación: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "✅ PRUEBA COMPLETADA" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""

Write-Host "Próximos pasos:" -ForegroundColor Blue
Write-Host "1. Abre http://localhost:8080/client.html en tu navegador"
Write-Host "2. Deberías ver 3 notificaciones en el dashboard:"
Write-Host "   • 1 Producto creado"
Write-Host "   • 1 Farmacia creada"
Write-Host "   • 1 Relación creada"
Write-Host ""
Write-Host "3. Los contadores en la parte superior deben mostrar:"
Write-Host "   📦 Productos Creados: 1"
Write-Host "   🏥 Farmacias Creadas: 1"
Write-Host "   🔗 Relaciones Creadas: 1"
Write-Host ""
