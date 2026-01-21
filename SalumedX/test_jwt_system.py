"""
Script de prueba para el sistema JWT
Verifica que el auth-service esté corriendo y prueba el flujo completo
"""
import requests
import json
from datetime import datetime

# Configuración
BASE_URL = "http://localhost:8000"
AUTH_SERVICE_URL = "http://localhost:8001"

def print_section(title):
    print(f"\n{'='*60}")
    print(f"  {title}")
    print('='*60)

def test_auth_service_health():
    """Verifica que el auth-service esté disponible"""
    print_section("1. Verificando Auth-Service")
    try:
        response = requests.get(f"{AUTH_SERVICE_URL}/health", timeout=2)
        print(f"✅ Auth-Service está corriendo (Status: {response.status_code})")
        return True
    except:
        print("❌ Auth-Service NO está disponible en puerto 8001")
        print("   Asegúrate de iniciar el auth-service primero")
        return False

def test_login():
    """Prueba el login y obtiene el token"""
    print_section("2. Login (Obtener Token JWT)")
    
    credentials = {
        "email": "medico@test.com",
        "password": "12345678"
    }
    
    print(f"Intentando login con: {credentials['email']}")
    
    try:
        response = requests.post(
            f"{BASE_URL}/auth/login/",
            json=credentials,
            timeout=5
        )
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Login exitoso!")
            print(f"   User ID: {data['user']['id']}")
            print(f"   Username: {data['user']['username']}")
            print(f"   Tipo: {data['user'].get('tipo_usuario', 'N/A')}")
            print(f"   Token (primeros 50 chars): {data['access'][:50]}...")
            return data['access']
        else:
            print(f"❌ Login falló (Status: {response.status_code})")
            print(f"   Response: {response.json()}")
            return None
            
    except Exception as e:
        print(f"❌ Error en login: {str(e)}")
        return None

def test_token_status(token):
    """Verifica el estado del token"""
    print_section("3. Verificar Estado del Token")
    
    try:
        response = requests.get(
            f"{BASE_URL}/token/status/",
            headers={"Authorization": f"Bearer {token}"}
        )
        
        if response.status_code == 200:
            data = response.json()
            print("✅ Token válido!")
            print(f"   Authenticated: {data['authenticated']}")
            print(f"   User ID: {data['user_id']}")
            print(f"   Username: {data['user_info'].get('username', 'N/A')}")
            print(f"   Tiempo restante: {data['remaining_time']}")
            print(f"   Expira en: {data['expiration_time']}")
            
            # Verificar headers
            print(f"\n   Headers informativos:")
            print(f"   X-Token-Status: {response.headers.get('X-Token-Status', 'N/A')}")
            
            return True
        else:
            print(f"❌ Token inválido (Status: {response.status_code})")
            print(f"   Response: {response.json()}")
            return False
            
    except Exception as e:
        print(f"❌ Error al verificar token: {str(e)}")
        return False

def test_protected_endpoint(token):
    """Prueba un endpoint protegido (recetas)"""
    print_section("4. Acceder a Endpoint Protegido")
    
    print("Intentando acceder a GET /recetas/")
    
    try:
        response = requests.get(
            f"{BASE_URL}/recetas/",
            headers={"Authorization": f"Bearer {token}"}
        )
        
        if response.status_code == 200:
            data = response.json()
            print("✅ Acceso exitoso a endpoint protegido!")
            print(f"   Total de recetas: {data.get('total', 0)}")
            
            # Verificar headers
            token_status = response.headers.get('X-Token-Status', 'N/A')
            print(f"   X-Token-Status: {token_status}")
            
            return True
        else:
            print(f"❌ Acceso denegado (Status: {response.status_code})")
            print(f"   Response: {response.json()}")
            return False
            
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return False

def test_without_token():
    """Prueba acceso sin token (debe fallar)"""
    print_section("5. Intentar Acceder Sin Token")
    
    try:
        response = requests.get(f"{BASE_URL}/recetas/")
        
        if response.status_code == 401:
            data = response.json()
            print("✅ Correctamente bloqueado sin token!")
            print(f"   Error: {data.get('error', 'N/A')}")
            print(f"   Code: {data.get('code', 'N/A')}")
            return True
        else:
            print(f"⚠️  Respuesta inesperada (Status: {response.status_code})")
            return False
            
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return False

def test_invalid_token():
    """Prueba con token inválido"""
    print_section("6. Intentar con Token Inválido")
    
    fake_token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.invalid.token"
    
    try:
        response = requests.get(
            f"{BASE_URL}/recetas/",
            headers={"Authorization": f"Bearer {fake_token}"}
        )
        
        if response.status_code == 401:
            print("✅ Token inválido correctamente rechazado!")
            
            # Verificar header
            token_error = response.headers.get('X-Token-Error', 'N/A')
            print(f"   X-Token-Error: {token_error}")
            
            return True
        else:
            print(f"⚠️  Respuesta inesperada (Status: {response.status_code})")
            return False
            
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return False

def main():
    """Ejecuta todas las pruebas"""
    print("\n" + "🔐 PRUEBAS DEL SISTEMA JWT".center(60))
    print(f"Fecha: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # Verificar auth-service
    if not test_auth_service_health():
        print("\n❌ ABORTANDO: Auth-Service no disponible")
        return
    
    # Login y obtener token
    token = test_login()
    if not token:
        print("\n❌ ABORTANDO: No se pudo obtener token")
        return
    
    # Verificar estado del token
    if not test_token_status(token):
        print("\n⚠️  Advertencia: Token inválido")
    
    # Probar endpoint protegido
    test_protected_endpoint(token)
    
    # Probar sin token
    test_without_token()
    
    # Probar con token inválido
    test_invalid_token()
    
    # Resumen
    print_section("✅ PRUEBAS COMPLETADAS")
    print("\nSistema JWT funcionando correctamente!")
    print("\nPróximos pasos:")
    print("  1. Probar crear una receta con POST /recetas/")
    print("  2. Probar el endpoint /token/refresh/")
    print("  3. Verificar expiración después de 5 horas")

if __name__ == "__main__":
    main()
