# 🔐 Integración con Microservicio de Autenticación

## Resumen de cambios

Este documento describe cómo el servicio GraphQL se integra con el **Microservicio de Autenticación** del segundo parcial.

## ⚙️ Configuración

### 1. Instalar dependencia JWT

```bash
cd app
bundle install
```

### 2. Configurar variables de entorno

Editar `app/.env`:

```env
# URL del microservicio de autenticación
AUTH_SERVICE_URL=http://localhost:3001

# Secret compartido para validar JWTs
# ⚠️ Debe coincidir con el del Auth Service
JWT_SECRET=tu_secret_compartido_muy_seguro_aqui
```

**⚠️ IMPORTANTE:** Tu compañero debe proporcionarte:
- La URL del Auth Service
- El JWT_SECRET compartido
- El algoritmo usado (por defecto HS256)

### 3. Levantar el Auth Service

El Auth Service debe estar corriendo **antes** de levantar este servicio GraphQL.

```bash
# En el directorio del Auth Service de tu compañero
npm start  # o el comando que use
```

## 🔄 Flujo de autenticación

### 1. Usuario hace Login

```bash
POST http://localhost:4000/auth/login
Content-Type: application/json

{
  "username": "usuario",
  "password": "contraseña"
}
```

**Respuesta:**
```json
{
  "success": true,
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": 1,
    "username": "usuario",
    "email": "usuario@email.com",
    "role": "medico"
  }
}
```

### 2. Frontend guarda los tokens

```javascript
// Guardar en localStorage o memoria
localStorage.setItem('access_token', response.access_token);
localStorage.setItem('refresh_token', response.refresh_token);
```

### 3. Hacer peticiones GraphQL con JWT

```bash
POST http://localhost:4000/graphql
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
Content-Type: application/json

{
  "query": "query { productos { id nombre precio } }"
}
```

### 4. Refrescar token cuando expira

```bash
POST http://localhost:4000/auth/refresh
Content-Type: application/json

{
  "refresh_token": "eyJhbGciOiJIUzI1NiIs..."
}
```

**Respuesta:**
```json
{
  "success": true,
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs..."
}
```

### 5. Logout

```bash
POST http://localhost:4000/auth/logout
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
Content-Type: application/json

{
  "refresh_token": "eyJhbGciOiJIUzI1NiIs..."
}
```

## 🏗️ Arquitectura

### Validación Local de JWT (sin llamar al Auth Service)

```
┌─────────────┐         ┌──────────────────┐
│  Frontend   │──JWT──▶│  GraphQL Service │
└─────────────┘         └──────────────────┘
                               │
                               ▼
                        ┌──────────────┐
                        │ JWT Validator│ ← Valida localmente
                        │ (jwt_validator.rb) │   (firma + expiración)
                        └──────────────┘
                               │
                               ▼ (solo si necesita verificar blacklist)
                        ┌──────────────────┐
                        │  Auth Service    │
                        │  GET /blacklist  │
                        └──────────────────┘
```

**✅ Ventajas:**
- No hay llamadas al Auth Service en cada request
- Validación rápida (solo verificar firma y expiración)
- El Auth Service solo se consulta para blacklist (cache de 1 minuto)

### Componentes nuevos

#### 1. `jwt_validator.rb` - Validación local de JWT

```ruby
# Valida token sin llamar al Auth Service
result = JwtValidator.validate_token(token)

if result[:valid]
  user_id = result[:user_id]
  username = result[:username]
  role = result[:role]
else
  error = result[:error]
end
```

#### 2. `auth_proxy.rb` - Proxy para login/registro

```ruby
# Login
result = AuthProxy.login(username: "user", password: "pass")

# Registro
result = AuthProxy.register(
  username: "nuevo",
  email: "nuevo@email.com",
  password: "123456",
  role: "paciente"
)

# Refresh
result = AuthProxy.refresh(refresh_token: "...")
```

#### 3. Helpers en `app.rb`

```ruby
# Obtener usuario actual desde JWT
user = current_user
# => { valid: true, user_id: 1, username: "user", role: "medico" }

# Requiere autenticación (lanza 401 si no hay token válido)
require_auth!
```

## 🔧 Uso en Resolvers GraphQL

### Acceder al usuario autenticado en resolvers

```ruby
# app/resolvers/recetas_resolver.rb

def crear_receta(args)
  # Obtener usuario autenticado desde el contexto
  current_user = context[:current_user]
  
  unless current_user && current_user[:valid]
    raise GraphQL::ExecutionError, "No autenticado"
  end
  
  # Verificar permisos por rol
  unless ['medico', 'admin'].include?(current_user[:role])
    raise GraphQL::ExecutionError, "Solo médicos pueden crear recetas"
  end
  
  # Usar user_id en la creación
  medico_id = current_user[:user_id]
  
  # ... lógica de creación ...
end
```

## 📋 Endpoints disponibles

### Autenticación
- `POST /auth/login` - Login (obtener tokens)
- `POST /auth/register` - Registro de usuario
- `POST /auth/logout` - Logout (revocar tokens)
- `POST /auth/refresh` - Refrescar access token
- `GET /auth/me` - Info del usuario actual

### GraphQL
- `POST /graphql` - Consultas y mutaciones GraphQL (requiere JWT)

## 🔒 Seguridad

### Tokens de corta duración

- **Access Token:** 15 minutos (configurable en Auth Service)
- **Refresh Token:** 7 días (configurable en Auth Service)

### Blacklist de tokens revocados

El validador consulta la blacklist del Auth Service con cache de 1 minuto:

```ruby
# Se actualiza automáticamente cada minuto
JwtValidator.update_blacklist_cache
```

### Rate limiting

El Auth Service debe implementar rate limiting en `/auth/login` para prevenir ataques de fuerza bruta.

## 🧪 Testing

### 1. Verificar Auth Service

```bash
curl http://localhost:3001/auth/me
# Debe responder con error 401 o similar
```

### 2. Login de prueba

```bash
curl -X POST http://localhost:4000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"123456"}'
```

### 3. GraphQL con JWT

```bash
TOKEN="eyJhbGciOiJIUzI1NiIs..."

curl -X POST http://localhost:4000/graphql \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query":"{ productos { id nombre } }"}'
```

## 🐛 Troubleshooting

### Error: "Token inválido"

- Verificar que `JWT_SECRET` sea el mismo en Auth Service y GraphQL Service
- Verificar que el token no haya expirado
- Verificar que el formato sea `Bearer <token>`

### Error: "No se pudo conectar al Auth Service"

- Verificar que `AUTH_SERVICE_URL` sea correcto
- Verificar que el Auth Service esté corriendo
- Verificar firewall/puertos

### Error: "Token revocado"

- El usuario hizo logout
- Solicitar nuevo token con `POST /auth/refresh`

## 📝 Coordinación con tu compañero

Tu compañero debe proporcionarte:

1. ✅ URL del Auth Service (ej: `http://localhost:3001`)
2. ✅ JWT_SECRET compartido
3. ✅ Formato del payload JWT:
   ```json
   {
     "user_id": 1,
     "username": "usuario",
     "email": "usuario@email.com",
     "role": "medico",
     "exp": 1234567890,
     "iat": 1234567800
   }
   ```
4. ✅ Estructura del endpoint `/auth/blacklist`
5. ✅ Duración de access y refresh tokens

## 📚 Referencias

- [JWT.io](https://jwt.io/) - Debugger y documentación JWT
- [RFC 7519](https://tools.ietf.org/html/rfc7519) - JWT Specification
- Documento del segundo parcial - Pilar 1: Microservicio de Autenticación
