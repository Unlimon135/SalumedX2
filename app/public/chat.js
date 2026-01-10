const { createApp } = Vue;

createApp({
  data() {
    return {
      // UI State
      isDark: localStorage.getItem('darkMode') === 'true',
      sidebarCollapsed: false,
      loading: false,
      loadingMessage: 'Procesando...',
      isTyping: false,
      error: null,
      
      // User Data
      username: '',
      authToken: null,
      
      // Chat Data
      messages: [],
      messageInput: '',
      stats: null,
      
      // Geolocation
      userLocation: null,
      locationError: null,
      locationRequested: false,
      
      // Config
      AI_GATEWAY_URL: 'http://localhost:5000',
      API_URL: localStorage.getItem('API_URL') || 'https://salumedx-rest.onrender.com'
    };
  },
  
  mounted() {
    this.checkAuth();
    this.loadStats();
    this.adjustTextareaHeight();
    this.requestLocation();
  },
  
  methods: {
    // ========== AUTH ==========
    checkAuth() {
      const token = localStorage.getItem('authToken');
      const username = localStorage.getItem('username');
      
      if (!token || !username) {
        window.location.href = 'app.html';
        return;
      }
      
      this.authToken = token;
      this.username = username;
      
      // Cargar historial automáticamente
      this.loadHistory();
    },
    
    logout() {
      localStorage.removeItem('authToken');
      localStorage.removeItem('username');
      window.location.href = 'app.html';
    },
    
    toggleDarkMode() {
      this.isDark = !this.isDark;
      localStorage.setItem('darkMode', this.isDark);
    },
    
    // ========== GEOLOCATION ==========
    requestLocation() {
      if (!navigator.geolocation) {
        this.locationError = 'Tu navegador no soporta geolocalización';
        console.warn('Geolocalización no disponible');
        return;
      }
      
      this.locationRequested = true;
      
      navigator.geolocation.getCurrentPosition(
        (position) => {
          this.userLocation = {
            latitude: position.coords.latitude,
            longitude: position.coords.longitude,
            accuracy: position.coords.accuracy
          };
          this.locationError = null;
          console.log('📍 Ubicación obtenida:', this.userLocation);
          
          // Mostrar notificación al usuario
          this.addMessage('system', '📍 Ubicación activada. Ahora puedo mostrarte farmacias cercanas.');
        },
        (error) => {
          this.locationError = this.getLocationErrorMessage(error);
          console.error('Error obteniendo ubicación:', error);
          
          // Mostrar mensaje al usuario
          this.addMessage('system', '⚠️ No pude obtener tu ubicación. Las búsquedas de farmacias cercanas no estarán disponibles.');
        },
        {
          enableHighAccuracy: true,
          timeout: 10000,
          maximumAge: 300000 // 5 minutos
        }
      );
    },
    
    getLocationErrorMessage(error) {
      switch(error.code) {
        case error.PERMISSION_DENIED:
          return 'Permiso de ubicación denegado. Por favor, habilita el acceso a la ubicación en tu navegador.';
        case error.POSITION_UNAVAILABLE:
          return 'Ubicación no disponible.';
        case error.TIMEOUT:
          return 'Tiempo de espera agotado al obtener ubicación.';
        default:
          return 'Error desconocido al obtener ubicación.';
      }
    },
    
    retryLocation() {
      this.locationError = null;
      this.requestLocation();
    },
    
    // ========== CHAT ==========
    async sendMessage() {
      const message = this.messageInput.trim();
      if (!message || this.loading) return;
      
      console.log('📤 Enviando mensaje:', message);
      
      // Agregar mensaje del usuario
      this.addMessage('user', message);
      this.messageInput = '';
      
      // Mostrar indicador de escritura
      this.isTyping = true;
      this.loading = true;
      this.loadingMessage = 'Pensando...';
      
      try {
        // Preparar payload con ubicación si está disponible
        const payload = { message };
        if (this.userLocation) {
          payload.user_lat = this.userLocation.latitude;
          payload.user_lng = this.userLocation.longitude;
        }
        
        console.log('📡 Enviando request a:', `${this.AI_GATEWAY_URL}/chat/message`);
        
        const response = await axios.post(
          `${this.AI_GATEWAY_URL}/chat/message`,
          payload,
          {
            headers: {
              'Authorization': `Bearer ${this.authToken}`,
              'Content-Type': 'application/json'
            }
          }
        );
        
        console.log('✅ Respuesta recibida:', response.data);
        
        // Validar que existe la respuesta
        if (!response.data || !response.data.response) {
          console.error('⚠️ Respuesta vacía o inválida:', response.data);
          throw new Error('Respuesta vacía del servidor');
        }
        
        // Agregar respuesta del asistente
        const assistantMessage = {
          role: 'assistant',
          content: response.data.response,
          tools_used: response.data.tools_used || [],
          data: response.data.data || null,
          timestamp: Date.now(),
          showData: false
        };
        
        console.log('💬 Agregando mensaje del asistente:', assistantMessage);
        this.messages.push(assistantMessage);
        
        console.log('📋 Total mensajes:', this.messages.length);
        
        this.$nextTick(() => {
          this.scrollToBottom();
        });
        
      } catch (err) {
        console.error('❌ Error completo:', err);
        console.error('Response data:', err.response?.data);
        console.error('Response status:', err.response?.status);
        
        this.error = err.response?.data?.error || err.message || 'Error al comunicarse con el asistente';
        
        // Agregar mensaje de error
        this.addMessage('assistant', '❌ Lo siento, ocurrió un error al procesar tu mensaje. Por favor intenta de nuevo.');
        
      } finally {
        this.isTyping = false;
        this.loading = false;
        console.log('✅ Proceso completado');
      }
    },
    
    async uploadImage(event) {
      const file = event.target.files[0];
      if (!file) return;
      
      this.loading = true;
      this.loadingMessage = 'Procesando imagen con OCR...';
      this.isTyping = true;
      
      // Agregar mensaje del usuario
      this.addMessage('user', `📷 Imagen subida: ${file.name}`);
      
      try {
        const formData = new FormData();
        formData.append('image', file);
        
        const response = await axios.post(
          `${this.AI_GATEWAY_URL}/chat/image`,
          formData,
          {
            headers: {
              'Authorization': `Bearer ${this.authToken}`,
              'Content-Type': 'multipart/form-data'
            }
          }
        );
        
        // Agregar respuesta del asistente
        const assistantMessage = {
          role: 'assistant',
          content: response.data.response,
          tools_used: response.data.tools_used || [],
          data: response.data.data || null,
          timestamp: Date.now()
        };
        
        this.messages.push(assistantMessage);
        this.scrollToBottom();
        
      } catch (err) {
        console.error('Error procesando imagen:', err);
        this.error = err.response?.data?.error || 'Error al procesar la imagen';
        this.addMessage('assistant', '❌ No pude procesar la imagen. Asegúrate de que sea legible.');
        
      } finally {
        this.isTyping = false;
        this.loading = false;
        event.target.value = '';
      }
    },
    
    async uploadPDF(event) {
      const file = event.target.files[0];
      if (!file) return;
      
      this.loading = true;
      this.loadingMessage = 'Extrayendo texto del PDF...';
      this.isTyping = true;
      
      // Agregar mensaje del usuario
      this.addMessage('user', `📄 PDF subido: ${file.name}`);
      
      try {
        const formData = new FormData();
        formData.append('pdf', file);
        
        const response = await axios.post(
          `${this.AI_GATEWAY_URL}/chat/pdf`,
          formData,
          {
            headers: {
              'Authorization': `Bearer ${this.authToken}`,
              'Content-Type': 'multipart/form-data'
            }
          }
        );
        
        // Agregar respuesta del asistente
        const assistantMessage = {
          role: 'assistant',
          content: response.data.response,
          tools_used: response.data.tools_used || [],
          data: response.data.data || null,
          timestamp: Date.now()
        };
        
        this.messages.push(assistantMessage);
        this.scrollToBottom();
        
      } catch (err) {
        console.error('Error procesando PDF:', err);
        this.error = err.response?.data?.error || 'Error al procesar el PDF';
        this.addMessage('assistant', '❌ No pude procesar el PDF. Verifica que sea un archivo válido.');
        
      } finally {
        this.isTyping = false;
        this.loading = false;
        event.target.value = '';
      }
    },
    
    async loadHistory() {
      this.loading = true;
      this.loadingMessage = 'Cargando historial...';
      
      try {
        const response = await axios.get(
          `${this.AI_GATEWAY_URL}/chat/history?limit=50`,
          {
            headers: {
              'Authorization': `Bearer ${this.authToken}`
            }
          }
        );
        
        // Convertir historial al formato de mensajes
        this.messages = response.data.history.map(h => ({
          role: h.role,
          content: h.message,
          timestamp: h.created_at * 1000, // Unix timestamp a milliseconds
          showData: false
        }));
        
        this.scrollToBottom();
        
      } catch (err) {
        console.error('Error cargando historial:', err);
        if (err.response?.status !== 404) {
          this.error = 'Error al cargar el historial';
        }
      } finally {
        this.loading = false;
      }
    },
    
    async clearCurrentChat() {
      if (!confirm('¿Estás seguro de que quieres limpiar el historial del chat?')) {
        return;
      }
      
      this.loading = true;
      this.loadingMessage = 'Limpiando historial...';
      
      try {
        await axios.delete(
          `${this.AI_GATEWAY_URL}/chat/history`,
          {
            headers: {
              'Authorization': `Bearer ${this.authToken}`
            }
          }
        );
        
        this.messages = [];
        this.error = null;
        
      } catch (err) {
        console.error('Error limpiando historial:', err);
        this.error = 'Error al limpiar el historial';
      } finally {
        this.loading = false;
      }
    },
    
    newChat() {
      this.messages = [];
      this.error = null;
      this.messageInput = '';
    },
    
    async loadStats() {
      try {
        const response = await axios.get(`${this.AI_GATEWAY_URL}/chat/stats`);
        this.stats = response.data;
      } catch (err) {
        console.error('Error cargando estadísticas:', err);
      }
    },
    
    // ========== UI HELPERS ==========
    addMessage(role, content) {
      this.messages.push({
        role,
        content,
        timestamp: Date.now(),
        showData: false
      });
      this.scrollToBottom();
    },
    
    getMessageIcon(role) {
      switch(role) {
        case 'user': return 'fas fa-user';
        case 'system': return 'fas fa-info-circle';
        default: return 'fas fa-robot';
      }
    },
    
    getMessageAuthor(role) {
      switch(role) {
        case 'user': return this.username;
        case 'system': return 'Sistema';
        default: return 'AI Assistant';
      }
    },
    
    toggleData(index) {
      this.messages[index].showData = !this.messages[index].showData;
    },
    
    scrollToBottom() {
      this.$nextTick(() => {
        const container = this.$refs.messagesContainer;
        if (container) {
          container.scrollTop = container.scrollHeight;
        }
      });
    },
    
    adjustTextareaHeight() {
      // Auto-ajustar altura del textarea
      const textarea = document.querySelector('.message-input');
      if (textarea) {
        textarea.addEventListener('input', function() {
          this.style.height = 'auto';
          this.style.height = Math.min(this.scrollHeight, 150) + 'px';
        });
      }
    },
    
    formatTime(timestamp) {
      const date = new Date(timestamp);
      const now = new Date();
      const diff = now - date;
      
      // Si es hoy
      if (date.toDateString() === now.toDateString()) {
        return date.toLocaleTimeString('es', { hour: '2-digit', minute: '2-digit' });
      }
      
      // Si es ayer
      const yesterday = new Date(now);
      yesterday.setDate(yesterday.getDate() - 1);
      if (date.toDateString() === yesterday.toDateString()) {
        return 'Ayer ' + date.toLocaleTimeString('es', { hour: '2-digit', minute: '2-digit' });
      }
      
      // Fecha completa
      return date.toLocaleDateString('es', { 
        day: '2-digit', 
        month: '2-digit',
        hour: '2-digit',
        minute: '2-digit'
      });
    },
    
    formatMessage(content) {
      if (!content) return '';
      
      // Convertir URLs a links
      let formatted = content.replace(
        /(https?:\/\/[^\s]+)/g,
        '<a href="$1" target="_blank" rel="noopener">$1</a>'
      );
      
      // Convertir saltos de línea
      formatted = formatted.replace(/\n/g, '<br>');
      
      // Resaltar código entre backticks
      formatted = formatted.replace(
        /`([^`]+)`/g,
        '<code>$1</code>'
      );
      
      // Resaltar bloques de código
      formatted = formatted.replace(
        /```([^`]+)```/g,
        '<pre><code>$1</code></pre>'
      );
      
      return formatted;
    }
  }
}).mount('#app');
