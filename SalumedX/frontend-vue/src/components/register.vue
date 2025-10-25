<template>
  <div class="register">
    <h1>Crear una cuenta en SalumedX</h1>
    <p class="subtitle">Complete los siguientes datos para registrarse</p>

    <form @submit.prevent="handleSubmit" novalidate>
      <div class="form-group">
        <label for="username">Nombre de usuario</label>
        <input 
          id="username" 
          v-model="form.username" 
          type="text" 
          required
          :disabled="isLoading"
          placeholder="Ingrese un nombre de usuario único"
        />
        <small>El nombre de usuario debe ser único y no puede cambiarse después</small>
      </div>

      <div class="form-group">
        <label for="password1">Contraseña</label>
        <input 
          id="password1" 
          v-model="form.password1" 
          type="password" 
          required
          :disabled="isLoading"
          placeholder="Ingrese su contraseña"
        />
        <small>Use una contraseña segura con letras, números y símbolos</small>
      </div>

      <div class="form-group">
        <label for="password2">Confirmar contraseña</label>
        <input 
          id="password2" 
          v-model="form.password2" 
          type="password" 
          required
          :disabled="isLoading"
          placeholder="Repita su contraseña"
        />
        <small>Debe coincidir exactamente con la contraseña ingresada</small>
      </div>

      <div v-if="error" class="error-box">
        <p class="error">{{ error }}</p>
      </div>

      <div v-if="success" class="success-box">
        <p class="success">{{ success }}</p>
      </div>

      <button 
        type="submit" 
        :disabled="isLoading"
        :class="{ loading: isLoading }"
      >
        {{ isLoading ? 'Registrando...' : 'Crear cuenta' }}
      </button>

      <p class="login-link">
        ¿Ya tienes una cuenta? <a href="/login">Iniciar sesión</a>
      </p>
    </form>

    <div v-if="import.meta.env.DEV" class="debug">
      <h3>Debug (solo desarrollo)</h3>
      <pre>{{ form }}</pre>
    </div>
  </div>
</template>

<script setup lang="ts">
import { reactive, ref } from 'vue'
import { registerUser } from '../services/registerService'

const form = reactive({
  username: '',
  password1: '',
  password2: '',
})

const error = ref('')
const success = ref('')
const isLoading = ref(false)

async function handleSubmit() {
  error.value = ''
  success.value = ''
  
  // Validaciones frontend
  if (!form.username || !form.password1 || !form.password2) {
    error.value = 'Por favor complete todos los campos.'
    return
  }
  
  if (form.password1 !== form.password2) {
    error.value = 'Las contraseñas no coinciden.'
    return
  }

  if (form.password1.length < 8) {
    error.value = 'La contraseña debe tener al menos 8 caracteres.'
    return
  }

  try {
    isLoading.value = true
    const result = await registerUser(form)
    
    if (result.success) {
      success.value = '¡Cuenta creada exitosamente!'
      // Resetear formulario
      form.username = ''
      form.password1 = ''
      form.password2 = ''
      // Opcional: redirigir al login
      // setTimeout(() => window.location.href = '/login', 2000)
    } else {
      error.value = result.error || 'Error al crear la cuenta'
    }
  } catch (e) {
    error.value = 'Error de conexión. Intente nuevamente.'
    console.error('Error:', e)
  } finally {
    isLoading.value = false
  }
}
</script>

<style scoped>
.register {
  max-width: 420px;
  margin: 18px auto;
  padding: 20px;
  border: 1px solid #ddd;
  border-radius: 8px;
  background: #fff;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.register h1 {
  margin: 0 0 8px 0;
  font-size: 1.5rem;
  color: #2c3e50;
}

.subtitle {
  color: #666;
  margin-bottom: 24px;
  font-size: 0.9rem;
}

.form-group {
  margin-bottom: 20px;
}

.form-group label {
  display: block;
  margin-bottom: 6px;
  font-weight: 600;
  color: #2c3e50;
}

.form-group input {
  width: 100%;
  padding: 8px 12px;
  border: 2px solid #ddd;
  border-radius: 4px;
  font-size: 1rem;
  transition: border-color 0.2s;
}

.form-group input:focus {
  border-color: #42b983;
  outline: none;
}

.form-group small {
  display: block;
  margin-top: 4px;
  color: #666;
  font-size: 0.8rem;
}

button {
  width: 100%;
  padding: 12px;
  background: #42b983;
  color: white;
  border: none;
  border-radius: 4px;
  font-size: 1rem;
  cursor: pointer;
  transition: background 0.2s;
}

button:hover:not(:disabled) {
  background: #3aa876;
}

button:disabled {
  background: #93d7b7;
  cursor: not-allowed;
}

button.loading {
  position: relative;
  cursor: wait;
}

.error-box, .success-box {
  padding: 12px;
  margin: 12px 0;
  border-radius: 4px;
}

.error-box {
  background: #fee;
  border: 1px solid #fcc;
}

.success-box {
  background: #e8f5e9;
  border: 1px solid #a5d6a7;
}

.error {
  color: #d32f2f;
  margin: 0;
}

.success {
  color: #2e7d32;
  margin: 0;
}

.login-link {
  text-align: center;
  margin-top: 16px;
  font-size: 0.9rem;
}

.login-link a {
  color: #42b983;
  text-decoration: none;
}

.login-link a:hover {
  text-decoration: underline;
}

.debug {
  margin-top: 24px;
  padding-top: 16px;
  border-top: 1px dashed #ddd;
  font-size: 0.8rem;
  color: #666;
}
</style>
