// Actualización del frontend para JWT
// Agregar estas funciones a public/app.js

// ==========================================
// 🔐 GESTIÓN DE AUTENTICACIÓN JWT
// ==========================================

// Guardar tokens después del login
function saveTokens(accessToken, refreshToken) {
  localStorage.setItem('access_token', accessToken);
  localStorage.setItem('refresh_token', refreshToken);
}

// Obtener access token
function getAccessToken() {
  return localStorage.getItem('access_token');
}

// Obtener refresh token
function getRefreshToken() {
  return localStorage.getItem('refresh_token');
}

// Limpiar tokens (logout)
function clearTokens() {
  localStorage.removeItem('access_token');
  localStorage.removeItem('refresh_token');
}

// Login
async function login(username, password) {
  try {
    const response = await fetch('http://localhost:4000/auth/login', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ username, password })
    });
    
    const data = await response.json();
    
    if (data.success) {
      saveTokens(data.access_token, data.refresh_token);
      console.log('✅ Login exitoso:', data.user);
      return data;
    } else {
      console.error('❌ Login falló:', data.error);
      throw new Error(data.error);
    }
  } catch (error) {
    console.error('❌ Error en login:', error);
    throw error;
  }
}

// Logout
async function logout() {
  try {
    const accessToken = getAccessToken();
    const refreshToken = getRefreshToken();
    
    if (!accessToken || !refreshToken) {
      clearTokens();
      return;
    }
    
    await fetch('http://localhost:4000/auth/logout', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${accessToken}`
      },
      body: JSON.stringify({ refresh_token: refreshToken })
    });
    
    clearTokens();
    console.log('✅ Logout exitoso');
  } catch (error) {
    console.error('⚠️ Error en logout:', error);
    clearTokens(); // Limpiar tokens de todos modos
  }
}

// Refrescar access token
async function refreshAccessToken() {
  try {
    const refreshToken = getRefreshToken();
    
    if (!refreshToken) {
      throw new Error('No hay refresh token');
    }
    
    const response = await fetch('http://localhost:4000/auth/refresh', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ refresh_token: refreshToken })
    });
    
    const data = await response.json();
    
    if (data.success) {
      saveTokens(data.access_token, data.refresh_token);
      console.log('✅ Token refrescado');
      return data.access_token;
    } else {
      throw new Error(data.error || 'Refresh falló');
    }
  } catch (error) {
    console.error('❌ Error refrescando token:', error);
    clearTokens();
    throw error;
  }
}

// Hacer petición GraphQL con JWT y retry automático
async function graphqlFetch(query, variables = {}) {
  const accessToken = getAccessToken();
  
  if (!accessToken) {
    throw new Error('No autenticado. Por favor, haz login.');
  }
  
  try {
    const response = await fetch('http://localhost:4000/graphql', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${accessToken}`
      },
      body: JSON.stringify({ query, variables })
    });
    
    // Si es 401, intentar refrescar token y reintentar
    if (response.status === 401) {
      console.log('⚠️ Token expirado, intentando refrescar...');
      
      try {
        const newToken = await refreshAccessToken();
        
        // Reintentar con nuevo token
        const retryResponse = await fetch('http://localhost:4000/graphql', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${newToken}`
          },
          body: JSON.stringify({ query, variables })
        });
        
        return await retryResponse.json();
      } catch (refreshError) {
        console.error('❌ No se pudo refrescar token, redirigir a login');
        clearTokens();
        // Aquí puedes redirigir a la página de login
        throw new Error('Sesión expirada. Por favor, inicia sesión nuevamente.');
      }
    }
    
    return await response.json();
  } catch (error) {
    console.error('❌ Error en petición GraphQL:', error);
    throw error;
  }
}

// Obtener info del usuario actual
async function getCurrentUser() {
  try {
    const accessToken = getAccessToken();
    
    if (!accessToken) {
      return null;
    }
    
    const response = await fetch('http://localhost:4000/auth/me', {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${accessToken}`
      }
    });
    
    if (response.ok) {
      return await response.json();
    } else {
      return null;
    }
  } catch (error) {
    console.error('❌ Error obteniendo usuario:', error);
    return null;
  }
}

// ==========================================
// 📝 EJEMPLO DE USO
// ==========================================

// 1. Login
/*
await login('usuario', 'contraseña');
*/

// 2. Hacer query GraphQL (con refresh automático si expira)
/*
const result = await graphqlFetch(`
  query {
    productos {
      id
      nombre
      precio
    }
  }
`);
console.log(result);
*/

// 3. Obtener usuario actual
/*
const user = await getCurrentUser();
console.log('Usuario actual:', user);
*/

// 4. Logout
/*
await logout();
*/

// ==========================================
// 🎨 UI HELPERS
// ==========================================

// Mostrar/ocultar elementos según autenticación
async function updateUIAuth() {
  const user = await getCurrentUser();
  
  const loginBtn = document.getElementById('login-btn');
  const logoutBtn = document.getElementById('logout-btn');
  const userInfo = document.getElementById('user-info');
  
  if (user) {
    loginBtn?.style.setProperty('display', 'none');
    logoutBtn?.style.setProperty('display', 'block');
    if (userInfo) {
      userInfo.textContent = `${user.username} (${user.role})`;
      userInfo.style.display = 'block';
    }
  } else {
    loginBtn?.style.setProperty('display', 'block');
    logoutBtn?.style.setProperty('display', 'none');
    userInfo?.style.setProperty('display', 'none');
  }
}

// Llamar al cargar la página
document.addEventListener('DOMContentLoaded', async () => {
  await updateUIAuth();
});
