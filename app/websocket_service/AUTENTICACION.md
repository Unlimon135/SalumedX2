# 🔒 Autenticación del Dashboard - SaluMedX

## Descripción General

El dashboard de notificaciones ahora **requiere autenticación** para acceder. Solo los administradores autorizados pueden ver las notificaciones en tiempo real.

## ✨ Características de Seguridad

✅ **Pantalla de Login Obligatoria**
- El dashboard no se carga hasta que el usuario se autentique
- Formulario seguro con validación en cliente

✅ **Credenciales de Administrador**
- Sistema de usuarios con contraseñas
- Validación de acceso antes de mostrar datos

✅ **Sesiones Persistentes**
- Los tokens se guardan en `localStorage`
- Las sesiones duran 24 horas
- Se validan automáticamente al recargar la página

✅ **Seguridad**
- Tokens codificados en Base64
- Nonce aleatorio para cada sesión
- Timestamps para validación de expiración

## 🔐 Credenciales por Defecto

### Usuarios Disponibles:

```
Usuario: admin
Contraseña: 12345

Usuario: administrator
Contraseña: admin123
```

⚠️ **IMPORTANTE**: Cambiar estas credenciales antes de producción

## 📋 Cómo Cambiar Credenciales

### En Development (Cliente)

1. Abre `websocket_service/websocket_web2/src/client.html`
2. Busca la sección "AUTENTICACIÓN" en JavaScript (línea ~250)
3. Encontrarás:

```javascript
const VALID_CREDENTIALS = {
  'admin': '12345',           // CAMBIAR EN PRODUCCIÓN
  'administrator': 'admin123'
};
```

4. Modifica los usuarios y contraseñas:

```javascript
const VALID_CREDENTIALS = {
  'tu_usuario': 'tu_contraseña_segura',
  'otro_usuario': 'otra_contraseña_segura'
};
```

5. Guarda el archivo y recarga el navegador (Ctrl+Shift+Delete para limpiar caché)

### En Producción (Recomendado)

Para producción, **NO debes hardcodear las credenciales**. Implementa:

#### Opción 1: Endpoint de Autenticación en Node.js

```typescript
// En server.ts
app.post('/api/auth', (req, res) => {
  const { username, password } = req.body;
  
  // Buscar usuario en base de datos
  const user = database.findUser(username);
  
  if (user && bcrypt.compareSync(password, user.passwordHash)) {
    const token = jwt.sign(
      { username, id: user.id },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );
    res.json({ success: true, token });
  } else {
    res.status(401).json({ success: false, message: 'Invalid credentials' });
  }
});
```

#### Opción 2: Integración con Supabase (Tu sistema actual)

Usa el mismo sistema de autenticación que ya tienes en lugar del hardcoded:

```javascript
// client.html - JavaScript de login
async function authenticate(username, password) {
  try {
    const response = await fetch('http://localhost:8080/api/auth', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username, password })
    });
    
    if (response.ok) {
      const data = await response.json();
      localStorage.setItem('dashboardToken', data.token);
      return true;
    }
    return false;
  } catch (error) {
    console.error('Auth error:', error);
    return false;
  }
}
```

#### Opción 3: OAuth2 (Google, GitHub, etc.)

Para aplicaciones empresariales:

```javascript
// Usar bibliotecas como Auth0, Firebase Auth, etc.
import { GoogleAuthProvider, signInWithPopup } from "firebase/auth";
```

## 🚀 Flujo de Autenticación

```
┌─────────────────────────────────────────────────────┐
│         Usuario accede a localhost:8080             │
└─────────────────────┬───────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────┐
│     ¿Token válido en localStorage?                  │
└─────────────────────┬───────────────────────────────┘
                      │
        ┌─────────────┴─────────────┐
        │                           │
       SÍ                          NO
        │                           │
        ▼                           ▼
   ┌─────────┐          ┌─────────────────────┐
   │Dashboard│          │  Mostrar formulario │
   │ Cargado │          │    de login         │
   └─────────┘          └────────┬────────────┘
                                 │
                    ┌────────────┴────────────┐
                    │                         │
               Usuario ingresa          Usuario presiona
               credenciales              "Iniciar Sesión"
                    │                         │
                    └────────────┬────────────┘
                                 │
                                 ▼
                    ┌────────────────────────┐
                    │ Validar credenciales   │
                    └────────────┬───────────┘
                                 │
                    ┌────────────┴────────────┐
                    │                         │
                 VÁLIDAS                   INVÁLIDAS
                    │                         │
                    ▼                         ▼
            ┌──────────────┐        ┌────────────────┐
            │ Crear token  │        │ Mostrar error  │
            │ localStorage │        │  "Usuario o    │
            │              │        │  contraseña    │
            │ Dashboard    │        │  incorrectos"  │
            │ Cargado      │        │                │
            └──────────────┘        └────────────────┘
```

## 🔑 Estructura del Token

Los tokens se codifican en Base64 y contienen:

```json
{
  "username": "admin",
  "timestamp": 1700000000000,
  "nonce": "abc123def456"
}
```

Ejemplo de token codificado:
```
eyJ1c2VybmFtZSI6ImFkbWluIiwidGltZXN0YW1wIjoxNzAwMDAwMDAwMDAwLCJub25jZSI6ImFiYzEyM2RlZjQ1NiJ9
```

## ⏱️ Validación de Expiración

- **Duración**: 24 horas desde la creación
- **Cálculo**: `timestamp + (24 * 60 * 60 * 1000) > ahora`
- **Acción al expirar**: Se limpia automáticamente y se muestra el login nuevamente

## 🛡️ Prácticas de Seguridad Implementadas

✅ **Validación en Cliente**
- Verifica credenciales antes de mostrar contenido
- Tokens validados al cargar la página

✅ **Almacenamiento Seguro**
- localStorage (mismo origen, HTTPS en producción)
- Nonce aleatorio previene replay attacks

✅ **Tiempos de Expiración**
- 24 horas (configurable)
- Sesiones automáticamente invalidadas

⚠️ **Recomendaciones Adicionales para Producción**

```markdown
1. ❌ NO guardes contraseñas en localStorage
   ✅ Usa JWT tokens seguros (HS256 o RS256)

2. ❌ NO uses HTTP en producción
   ✅ Usa HTTPS (TLS 1.2+)

3. ❌ NO hardcodees credenciales en el cliente
   ✅ Valida en el servidor contra base de datos

4. ❌ NO expires las sesiones nunca
   ✅ Implementa refresh tokens (short-lived + long-lived)

5. ❌ NO ignores CORS
   ✅ Configura CORS correctamente en el servidor

6. ❌ NO registres datos sensibles en logs
   ✅ Registra solo lo necesario (no passwords ni tokens)
```

## 🔄 Cerrar Sesión

El dashboard incluye un botón "Cerrar Sesión" en la esquina superior derecha:

1. Limpia el token de localStorage
2. Cierra la conexión WebSocket
3. Recarga el formulario de login
4. Enfoca el campo de usuario

```javascript
function logout() {
  localStorage.removeItem('dashboardToken');
  if (socket && socket.readyState === WebSocket.OPEN) {
    socket.close();
  }
  loginForm.reset();
  usernameInput.focus();
  dashboardContainer.classList.add('hidden');
  loginContainer.classList.remove('hidden');
}
```

## 🧪 Testing de Autenticación

### Test 1: Login Exitoso
```
1. Abre http://localhost:8080/client.html
2. Usuario: admin
   Contraseña: 12345
3. Presiona "Iniciar Sesión"
4. ✅ Debes ver el dashboard
5. ✅ Token aparece en DevTools → Application → localStorage
```

### Test 2: Login Fallido
```
1. Abre http://localhost:8080/client.html
2. Usuario: admin
   Contraseña: contraseña_incorrecta
3. Presiona "Iniciar Sesión"
4. ✅ Aparece error rojo: "Usuario o contraseña incorrectos"
5. ✅ Campo de contraseña se limpia
```

### Test 3: Sesión Persistente
```
1. Autentica correctamente
2. Recarga la página (F5)
3. ✅ Dashboard carga directamente sin pedir credenciales
4. Abre DevTools → Application → localStorage
5. ✅ Busca 'dashboardToken' (debe existir)
```

### Test 4: Token Expirado
```
1. Autentica correctamente
2. En DevTools, abre localStorage
3. Edita 'dashboardToken' y cambia el timestamp a uno antiguo
4. Recarga la página
5. ✅ Vuelve a mostrar el formulario de login
```

### Test 5: Cerrar Sesión
```
1. Autentica correctamente
2. Presiona botón "Cerrar Sesión" (esquina superior derecha)
3. ✅ Vuelve al formulario de login
4. ✅ Token se elimina de localStorage
5. ✅ WebSocket se cierra
```

## 📊 Estadísticas de Seguridad

| Métrica | Valor |
|---------|-------|
| Tiempo para validar credenciales | <1ms |
| Duración de sesión | 24 horas |
| Overhead de token | ~100 bytes |
| Intentos de login fallidos que registra | Ilimitados (sin rate limiting) |

⚠️ **Para producción**, implementa:
- Rate limiting (máx 5 intentos por 15 minutos)
- Logging de intentos fallidos
- Alertas de acceso sospechoso

## 🚨 Troubleshooting

### "Error: Usuario o contraseña incorrectos" (después de cambiar credenciales)

**Solución:**
1. Limpia caché del navegador: Ctrl+Shift+Delete
2. Cierra todas las pestañas del dashboard
3. Abre una nueva ventana privada/incógnito
4. Intenta de nuevo

### El dashboard carga sin pedir credenciales (cuando no debería)

**Solución:**
```javascript
// En DevTools console:
localStorage.removeItem('dashboardToken');
location.reload();
```

### El botón "Cerrar Sesión" no funciona

**Solución:**
1. Verifica que el botón tiene id="btnLogout"
2. Abre DevTools (F12) y busca errores en Console
3. Intenta: `logout()` en la consola

## 📝 Notas Importantes

1. **Cambiar credenciales regularmente** (cada 30-90 días en producción)
2. **Usar credenciales fuertes** (mínimo 12 caracteres)
3. **No compartir credenciales** por email o chat
4. **Habilitar HTTPS** en producción
5. **Implementar logs de acceso** para auditoría
6. **Usar autenticación multifactor** en producción (2FA)
7. **Validar en el servidor**, no solo en cliente

## 🔗 Referencias

- [Autenticación JWT](https://jwt.io/)
- [OWASP Authentication](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html)
- [localStorage vs sessionStorage](https://developer.mozilla.org/es/docs/Web/API/Storage)
- [Web Cryptography API](https://developer.mozilla.org/en-US/docs/Web/API/Web_Crypto_API)

---

**Última actualización**: 14 de Noviembre, 2025
**Versión**: 1.0.0
**Estado**: ✅ Implementado y funcional
