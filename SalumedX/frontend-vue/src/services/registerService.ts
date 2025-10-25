interface RegisterData {
  username: string
  password1: string
  password2: string
}

// URLs del backend
const API_URL = 'http://127.0.0.1:8000'

export async function registerUser(data: RegisterData): Promise<{ success: boolean; error?: string }> {
  try {
    const response = await fetch(`${API_URL}/signup/`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        // Obtener el token CSRF de la cookie si existe
        'X-CSRFToken': getCookie('csrftoken') || '',
      },
      credentials: 'include', // importante para cookies
      body: JSON.stringify(data),
    })

    if (!response.ok) {
      // Intentar obtener mensaje de error del backend
      const errorData = await response.json().catch(() => ({}))
      throw new Error(errorData.error || 'Error al registrar usuario')
    }

    const result = await response.json()
    return { success: true }
  } catch (error) {
    console.error('Error en registro:', error)
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Error desconocido',
    }
  }
}

// Utilidad para obtener cookies (necesario para CSRF)
function getCookie(name: string): string | null {
  const value = `; ${document.cookie}`
  const parts = value.split(`; ${name}=`)
  if (parts.length === 2) {
    return parts.pop()?.split(';').shift() || null
  }
  return null
}