#!/bin/bash
# Script de prueba rápida del sistema de notificaciones
# Usage: bash test-notifications.sh

echo "═══════════════════════════════════════════════════════════════"
echo "  PRUEBA DEL SISTEMA DE NOTIFICACIONES - SALUMEDX"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
WS_URL="http://localhost:8080"
API_ENDPOINT="$WS_URL/api/notifications"

echo -e "${BLUE}1. Verificando si el servidor WebSocket está corriendo...${NC}"
if curl -s "$WS_URL" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Servidor WebSocket respondiendo en $WS_URL${NC}"
else
    echo -e "${RED}❌ No se puede conectar a $WS_URL${NC}"
    echo -e "${YELLOW}Asegúrate de ejecutar: cd app/websocket_service/websocket_web2 && npm run dev${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}2. Enviando notificación de prueba: PRODUCT_CREATED${NC}"

curl -X POST "$API_ENDPOINT" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "PRODUCT_CREATED",
    "data": {
      "id": 1,
      "nombre_comercial": "Paracetamol 500mg",
      "nombre_generico": "Acetaminofén",
      "precio": 5.50,
      "mensaje": "Nuevo producto: Paracetamol 500mg"
    },
    "timestamp": "'$(date -u +'%Y-%m-%dT%H:%M:%S.000Z')'",
    "user": "test_admin"
  }' \
  -w "\nStatus: %{http_code}\n" \
  -s

echo ""
echo -e "${GREEN}✅ Notificación de producto enviada${NC}"

echo ""
echo -e "${BLUE}3. Enviando notificación de prueba: PHARMACY_CREATED${NC}"

curl -X POST "$API_ENDPOINT" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "PHARMACY_CREATED",
    "data": {
      "id": 1,
      "nombre": "Farmacia Central",
      "direccion": "Calle Principal 123",
      "telefono": "555-1234",
      "mensaje": "Nueva farmacia: Farmacia Central"
    },
    "timestamp": "'$(date -u +'%Y-%m-%dT%H:%M:%S.000Z')'",
    "user": "test_admin"
  }' \
  -w "\nStatus: %{http_code}\n" \
  -s

echo ""
echo -e "${GREEN}✅ Notificación de farmacia enviada${NC}"

echo ""
echo -e "${BLUE}4. Enviando notificación de prueba: PRODUCT_PHARMACY_RELATION_CREATED${NC}"

curl -X POST "$API_ENDPOINT" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "PRODUCT_PHARMACY_RELATION_CREATED",
    "data": {
      "id": 1,
      "producto_id": 1,
      "farmacia_id": 1,
      "precio": 5.99,
      "stock": 100,
      "mensaje": "Nueva relación: Producto 1 en Farmacia 1"
    },
    "timestamp": "'$(date -u +'%Y-%m-%dT%H:%M:%S.000Z')'",
    "user": "test_admin"
  }' \
  -w "\nStatus: %{http_code}\n" \
  -s

echo ""
echo -e "${GREEN}✅ Notificación de relación enviada${NC}"

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo -e "${GREEN}✅ PRUEBA COMPLETADA${NC}"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo -e "${BLUE}Próximos pasos:${NC}"
echo "1. Abre http://localhost:8080/client.html en tu navegador"
echo "2. Deberías ver 3 notificaciones en el dashboard:"
echo "   • 1 Producto creado"
echo "   • 1 Farmacia creada"
echo "   • 1 Relación creada"
echo ""
echo "3. Los contadores en la parte superior deben mostrar:"
echo "   📦 Productos Creados: 1"
echo "   🏥 Farmacias Creadas: 1"
echo "   🔗 Relaciones Creadas: 1"
echo ""
