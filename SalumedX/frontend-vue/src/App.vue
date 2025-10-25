<template>
  <header>
    <h1>SalumedX</h1>
    <nav>
      <a href="#" class="active">Registro</a>
      <!-- Aquí puedes añadir más links de navegación -->
    </nav>
  </header>

  <main>
    <Register />
  </main>
</template>

<script setup>
import Register from './components/register.vue'
</script>

<style>
/* Estilos globales */
body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen,
    Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
  background-color: #f5f5f5;
}

/* Estilos del componente App */
header {
  background: #2c3e50;
  padding: 1rem;
  color: white;
}

header h1 {
  margin: 0;
  font-size: 1.5rem;
}

nav {
  margin-top: 1rem;
}

nav a {
  color: #fff;
  text-decoration: none;
  padding: 0.5rem 1rem;
  border-radius: 4px;
}

nav a.active {
  background: rgba(255, 255, 255, 0.2);
}

main {
  padding: 1rem;
}
</style>