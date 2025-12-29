# 🔐 Microservicio de Autenticación

Microservicio independiente para autenticación JWT con Django REST Framework.

## 📋 Características

- ✅ Autenticación basada en JWT (Access + Refresh Tokens)
- ✅ Registro y login de usuarios
- ✅ Validación de tokens para otros microservicios
- ✅ Blacklist de tokens revocados
- ✅ Rate limiting para prevenir ataques
- ✅ Base de datos propia (SQLite/PostgreSQL)
- ✅ Metadata de seguridad (IP, User Agent)

## 🚀 Inicio Rápido

### Instalación Local

```bash
# Crear entorno virtual
python -m venv venv
source venv/bin/activate  # En Windows: venv\Scripts\activate

# Instalar dependencias
pip install -r requirements.txt

# Configurar variables de entorno
cp .env.example .env

# Aplicar migraciones
python manage.py makemigrations
python manage.py migrate

# Crear superusuario
python manage.py createsuperuser

# Ejecutar servidor
python manage.py runserver 8001
```

### Docker

```bash
# Construir y levantar servicios
docker-compose up --build

# Aplicar migraciones (primera vez)
docker-compose exec auth-service python manage.py migrate

# Crear superusuario
docker-compose exec auth-service python manage.py createsuperuser
```

## 📡 Endpoints

### POST /auth/register
Registrar un nuevo usuario

**Request:**
```json
{
  "email": "user@example.com",
  "username": "usuario123",
  "password": "Password123!",
  "password2": "Password123!",
  "first_name": "Juan",
  "last_name": "Pérez"
}
```

**Response:**
```json
{
  "message": "Usuario registrado exitosamente",
  "user": {
    "id": "uuid-here",
    "email": "user@example.com",
    "username": "usuario123",
    "first_name": "Juan",
    "last_name": "Pérez",
    "is_active": true,
    "created_at": "2025-12-28T02:00:00Z"
  },
  "tokens": {
    "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
  }
}
```

### POST /auth/login
Iniciar sesión

**Request:**
```json
{
  "email": "user@example.com",
  "password": "Password123!"
}
```

**Response:**
```json
{
  "message": "Login exitoso",
  "user": { ... },
  "tokens": {
    "access": "...",
    "refresh": "..."
  }
}
```

### POST /auth/logout
Cerrar sesión y revocar tokens

**Headers:**
```
Authorization: Bearer {access_token}
```

**Request:**
```json
{
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

**Response:**
```json
{
  "message": "Logout exitoso"
}
```

### POST /auth/refresh
Refrescar access token

**Request:**
```json
{
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

**Response:**
```json
{
  "access": "nuevo_access_token..."
}
```

### GET /auth/me
Obtener información del usuario autenticado

**Headers:**
```
Authorization: Bearer {access_token}
```

**Response:**
```json
{
  "id": "uuid-here",
  "email": "user@example.com",
  "username": "usuario123",
  "first_name": "Juan",
  "last_name": "Pérez",
  "is_active": true,
  "created_at": "2025-12-28T02:00:00Z",
  "last_login": "2025-12-28T03:00:00Z"
}
```

### POST /auth/validate
Validar token (para otros microservicios)

**Request:**
```json
{
  "token": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

**Response:**
```json
{
  "valid": true,
  "user": { ... },
  "exp": 1703721600
}
```

## 🗄️ Modelos de Base de Datos

### User
- `id` (UUID)
- `email` (unique)
- `username` (unique)
- `first_name`
- `last_name`
- `is_active`
- `created_at`
- `last_login`

### RefreshToken
- `id` (UUID)
- `user` (FK)
- `token`
- `jti` (JWT ID)
- `expires_at`
- `ip_address`
- `user_agent`

### RevokedToken
- `id` (UUID)
- `jti` (unique)
- `token_type` (access/refresh)
- `user` (FK)
- `revoked_at`
- `expires_at`
- `reason`

## 🔒 Seguridad

### Rate Limiting
- **Register:** 3 intentos por hora por IP
- **Login:** 5 intentos por hora por IP

### Token Lifetime
- **Access Token:** 15 minutos
- **Refresh Token:** 24 horas

### Blacklist
Los tokens revocados se almacenan en la tabla `RevokedToken` y se verifican en cada validación.

## 🧪 Testing

```bash
# Crear usuario de prueba
curl -X POST http://localhost:8001/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "username": "testuser",
    "password": "TestPassword123!",
    "password2": "TestPassword123!"
  }'

# Login
curl -X POST http://localhost:8001/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "TestPassword123!"
  }'

# Verificar salud del servicio
curl http://localhost:8001/health/
```

## 📦 Variables de Entorno

| Variable | Descripción | Default |
|----------|-------------|---------|
| `SECRET_KEY` | Clave secreta de Django | - |
| `DEBUG` | Modo debug | `True` |
| `ALLOWED_HOSTS` | Hosts permitidos | `localhost,127.0.0.1` |
| `DB_ENGINE` | Motor de base de datos | `sqlite3` |
| `ACCESS_TOKEN_LIFETIME` | Duración access token (min) | `15` |
| `REFRESH_TOKEN_LIFETIME` | Duración refresh token (min) | `1440` |
| `RATE_LIMIT_ENABLE` | Activar rate limiting | `True` |

## 🐳 Arquitectura Docker

```
┌─────────────────────┐
│   auth-service      │
│   (Django REST)     │
│   Port: 8001        │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│   PostgreSQL DB     │
│   (auth_db)         │
└─────────────────────┘
```

## 🔗 Integración con Otros Microservicios

Los otros microservicios pueden validar tokens usando el endpoint `/auth/validate`:

```python
# En otro microservicio
import requests

def verify_token(token):
    response = requests.post(
        'http://auth-service:8000/auth/validate',
        json={'token': token}
    )
    
    if response.status_code == 200 and response.json().get('valid'):
        return response.json()['user']
    return None
```

## 📚 Administración

Accede al panel de administración en:
```
http://localhost:8001/admin/
```

## 🛠️ Tecnologías

- Python 3.11+
- Django 5.0+
- Django REST Framework
- Simple JWT
- PostgreSQL / SQLite
- Docker & Docker Compose
- Gunicorn

## 📝 Licencia

Este proyecto es parte del trabajo académico del Segundo Parcial.
