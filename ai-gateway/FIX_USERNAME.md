# 🔧 Solución: Username muestra "sin nombre"

## ❌ Problema

El log muestra:
```
👤 Usuario: 13 (sin nombre)
👥 Rol: paciente
```

El `user_id` se extrae correctamente pero el `username` aparece como "sin nombre".

## 🔍 Diagnóstico

Esto ocurre cuando el JWT no tiene el campo que estamos buscando, o el campo tiene un nombre diferente.

## ✅ Solución Paso a Paso

### 1. **Obtener y decodificar el token JWT**

**Opción A: Desde el navegador**
1. Abre: http://localhost:4567/obtener_token.html
2. Haz clic en "🔓 Decodificar en el Navegador"
3. Verás todos los campos del token
4. Identifica el campo que tiene tu nombre

**Opción B: Desde la terminal**
```powershell
# 1. Obtén el token desde el navegador
# En la consola del navegador (F12):
localStorage.getItem('authToken')

# 2. Copia el token y ejecuta:
cd d:\graphql_service\ai-gateway
ruby check_jwt.rb "PEGA_TU_TOKEN_AQUI"
```

### 2. **Identificar el campo correcto**

El script mostrará algo como:
```
CAMPOS IMPORTANTES
============================================================
👤 User ID: 13
📝 Username: ❌ NO ENCONTRADO
📧 Email: juan@example.com
🎭 Role: paciente

TODOS LOS CAMPOS DEL PAYLOAD:
{
  "sub": "13",
  "email": "juan@example.com",
  "role": "paciente",
  "first_name": "Juan",    ← 🎯 ESTE podría ser
  "last_name": "Pérez",
  "exp": 1736897234
}
```

### 3. **Actualizar el código**

Si encuentras que el campo es `first_name`, edita [controllers/chat_controller.rb](d:\graphql_service\ai-gateway\controllers\chat_controller.rb):

```ruby
# Buscar la función extract_user_info
def extract_user_info(token)
  # ...
  
  # OPCIÓN 1: Si el nombre está en first_name + last_name
  username = if data['first_name'] || data['last_name']
               "#{data['first_name']} #{data['last_name']}".strip
             else
               data['username'] || data['name'] || data['user_name'] ||
               data['nombre'] || data['full_name'] || data['displayName']
             end
  
  # OPCIÓN 2: Si está en otro campo específico
  username = data['first_name'] ||  # ← Agrega el campo correcto aquí
             data['username'] || 
             data['name'] || 
             data['user_name'] ||
             data['nombre'] || 
             data['full_name'] || 
             data['displayName']
  
  # ...
end
```

### 4. **Reiniciar el servidor**

```powershell
# Detener servidor actual (Ctrl+C)

# Reiniciar
cd d:\graphql_service\ai-gateway
ruby app.rb
```

### 5. **Verificar la solución**

Envía un mensaje y verifica el log:
```
👤 Usuario: 13 (Juan Pérez)  ← ✅ Ahora muestra el nombre
👥 Rol: paciente
```

## 📋 Campos Comunes en JWT

Diferentes sistemas usan diferentes nombres:

| Campo | Sistema que lo usa |
|-------|-------------------|
| `username` | Django, Rails estándar |
| `name` | Google, Facebook OAuth |
| `first_name` + `last_name` | Django, sistemas de usuarios |
| `full_name` | Custom implementations |
| `displayName` | Firebase, Auth0 |
| `preferred_username` | Keycloak, OIDC |
| `given_name` + `family_name` | OpenID Connect |

## 🔧 Modificación Actual

Ya se agregaron estos campos a [controllers/chat_controller.rb](d:\graphql_service\ai-gateway\controllers\chat_controller.rb):

```ruby
username = data['username'] || data['name'] || data['user_name'] ||
           data['nombre'] || data['full_name'] || data['displayName']
```

Si ninguno de estos funciona, debes:
1. Identificar el campo correcto con `obtener_token.html`
2. Agregarlo a la lista

## 💡 Debug en Vivo

El código ahora incluye logging:

```ruby
puts "🔍 JWT decodificado - Campos disponibles:"
puts data.keys.inspect
```

Verifica en la consola del servidor qué campos están disponibles.

## 🎯 Resultado Esperado

Después de la corrección:

**Antes:**
```
👤 Usuario: 13 (sin nombre)
```

**Después:**
```
👤 Usuario: 13 (Juan Pérez)
```

Y en las respuestas del agente:
```
¡Hola Juan Pérez! Como paciente, puedo ayudarte a buscar medicamentos...
```

## 📞 Si el Problema Persiste

1. ✅ Verifica que el token JWT efectivamente tenga un campo con el nombre
2. ✅ Revisa los logs del servidor para ver qué campos están disponibles
3. ✅ Confirma que el token no esté expirado
4. ✅ Verifica que el backend de autenticación incluya el nombre en el token

---

**Archivos relacionados:**
- [controllers/chat_controller.rb](d:\graphql_service\ai-gateway\controllers\chat_controller.rb) - Extracción de JWT
- [obtener_token.html](d:\graphql_service\ai-gateway\obtener_token.html) - Herramienta de diagnóstico
- [check_jwt.rb](d:\graphql_service\ai-gateway\check_jwt.rb) - Script de verificación CLI
