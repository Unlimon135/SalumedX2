const { createApp } = Vue;

createApp({
  data() {
    return {
      currentView: 'login',
      activeTab: 'recetas',
      loading: false,
      error: null,
      success: null,
      username: '',
      authToken: null,
      refreshToken: null,
      userRole: null,
      isMedico: false,
      
      loginForm: {
        username: '',
        password: ''
      },
      
      registerForm: {
        username: '',
        email: '',
        password: '',
        password2: '',
        role: 'paciente'
      },
      
      pdfForm: {
        paciente: {
          nombre: 'Cesar',
          cedula: '1122334455'
        },
        medico: {
          nombre: 'Abigail',
          licencia: '987654321'
        },
        detalle: {
          detalleReceta: 1,
          farmacia: 1,
          producto: 1,
          precioEncontrado: 0.30,
          distancia: 3.2,
          fuente: 'Página web de la farmacia'
        }
      },
      
      preciosForm: {
        nombre: 'Paracetamol',
        lat: -0.21,
        lng: -78.49,
        radioKm: 5
      },
      
      respuesta: null,
      API_URL: 'https://salumedx-rest.onrender.com',
      GRAPHQL_URL: 'http://localhost:4000/graphql',
      WEBSOCKET_URL: 'http://localhost:4000/api/notifications',
      isDark: false,
      debugMode: false,
      
      adminIframeLoading: false,
      adminIframeBlocked: false,
      adminLoadingProductos: false,
      adminLoadingFarmacias: false,
      adminLoadingRelacion: false,
      adminData: {
        productos: null,
        farmacias: null,
        productoFarmacia: null
      },
      adminNewProduct: {
        nombre_generico: '',
        nombre_comercial: '',
        principio_activo: '',
        categoria: '',
        presentacion: '',
        concentracion: '',
        precio: null,
        descripcion: ''
      },
      adminCreatingProducto: false,
      adminNewFarmacia: { nombre: '', direccion: '', telefono: '', lat: null, lng: null },
      adminCreatingFarmacia: false,
      adminNewRelacion: { producto: null, farmacia: null, precio: null, stock: null },
      adminCreatingRelacion: false,
      adminEditingProductoId: null,
      adminEditingProducto: null,
      adminEditingFarmaciaId: null,
      adminEditingFarmacia: null,
      adminEditingRelacionId: null,
      adminEditingRelacion: null,
      adminError: null,
      showFormProducto: false,
      showFormFarmacia: false,
      showFormRelacion: false
    };
  },
  
  mounted() {
    this.loadApiUrl();
    this.loadAuthToken();
    this.checkAuth();
    const dm = localStorage.getItem('DARK_MODE');
    this.isDark = dm === '1';
  },
  
  watch: {
    activeTab(newVal) {
      if (newVal === 'admin') {
        setTimeout(() => this.checkAdminIframe(), 300);
      }
    }
  },
  
  methods: {
    isAdmin() {
      return (this.userRole === 'admin') || (this.username && this.username.toLowerCase && this.username.toLowerCase() === 'admin');
    },
    
    clearMessages() {
      this.error = null;
      this.success = null;
    },
    
    toggleDark() { 
      this.isDark = !this.isDark; 
      localStorage.setItem('DARK_MODE', this.isDark ? '1' : '0'); 
    },
    
    toggleDebug() { 
      this.debugMode = !this.debugMode; 
    },
    
    loadApiUrl() {
      const saved = localStorage.getItem('API_URL');
      if (saved) this.API_URL = saved;
    },
    
    saveApiUrl() {
      localStorage.setItem('API_URL', this.API_URL);
      this.success = 'URL de API guardada.';
    },
    
    loadAuthToken() {
      // Compatibilidad: leer nuevas y antiguas claves
      const a = localStorage.getItem('access_token') || localStorage.getItem('AUTH_TOKEN');
      const r = localStorage.getItem('refresh_token') || localStorage.getItem('REFRESH_TOKEN');
      if (a) this.authToken = a;
      if (r) this.refreshToken = r;
    },
    
    saveAuthTokens(access, refresh) {
      this.authToken = access || null;
      this.refreshToken = refresh || null;
      // Nuevas claves (recomendadas por integración del Auth Service)
      if (access) localStorage.setItem('access_token', access); 
      else localStorage.removeItem('access_token');
      if (refresh) localStorage.setItem('refresh_token', refresh); 
      else localStorage.removeItem('refresh_token');
      // Mantener compatibilidad con claves antiguas
      if (access) localStorage.setItem('AUTH_TOKEN', access); 
      else localStorage.removeItem('AUTH_TOKEN');
      if (refresh) localStorage.setItem('REFRESH_TOKEN', refresh); 
      else localStorage.removeItem('REFRESH_TOKEN');
    },

    authBase() {
      // Base del Auth Service derivada del endpoint GraphQL
      return this.GRAPHQL_URL.replace('/graphql', '') + '/auth';
    },

    async refreshAuthToken() {
      if (!this.refreshToken) throw new Error('No hay refresh token');
      const url = `${this.authBase()}/refresh`;
      const res = await axios.post(url, { refresh_token: this.refreshToken }, {
        headers: { 'Content-Type': 'application/json' },
        validateStatus: () => true
      });
      if (res.status >= 400 || !res.data?.success) {
        throw new Error(res.data?.error || `Refresh falló (${res.status})`);
      }
      this.saveAuthTokens(res.data.access_token, res.data.refresh_token);
      return res.data.access_token;
    },
    
    async pingApi() {
      this.clearMessages();
      this.loading = true;
      try {
        const res = await axios.get(`${this.API_URL}/`, {
          validateStatus: () => true,
          timeout: 10000
        });
        if (res.status === 200) {
          this.success = '✅ API disponible (200)';
        } else {
          this.error = `⚠️ API respondió con estado ${res.status}`;
        }
      } catch (e) {
        console.log('Error verificando autenticación:', this.formatAxiosError(e));
        this.error = 'Error de conexión: ' + this.formatAxiosError(e);
      }
    },
    
    async verificarRolUsuario() {
      console.log('🔍 Verificando rol del usuario...');
      try {
        if (!this.authToken) {
          console.warn('No hay token para verificar rol');
          return;
        }

        const endpoints = ['/me/', '/api/user/', '/user/profile/'];
        
        for (const endpoint of endpoints) {
          try {
            const res = await axios.get(`${this.API_URL}${endpoint}`, {
              headers: { 'Authorization': `Bearer ${this.authToken}` },
              validateStatus: () => true,
              timeout: 5000
            });
            
            if (res.status === 200 && res.data) {
              console.log('✅ Perfil obtenido:', res.data);
              
              this.isMedico = res.data.is_medico || 
                             res.data.is_doctor || 
                             res.data.role === 'medico' ||
                             res.data.role === 'doctor' ||
                             res.data.user_type === 'medico' ||
                             !!res.data.licencia_medica;
              
              this.userRole = res.data.role || res.data.user_type || (this.isMedico ? 'medico' : 'paciente');
              
              console.log(`👤 Rol detectado: ${this.userRole} | Es médico: ${this.isMedico}`);
              
              if (this.isMedico) {
                this.success = '🩺 Sesión iniciada como MÉDICO - Puedes generar recetas';
              } else {
                this.success = '👤 Sesión iniciada como PACIENTE - Consulta recetas y precios';
              }
              
              return;
            }
          } catch (e) {
            console.log(`⚠️ No se pudo obtener perfil desde ${endpoint}`);
          }
        }
        
        console.log('🔍 Intentando verificar mediante búsqueda en listas...');
        
        try {
          const pacienteRes = await axios.get(`${this.API_URL}/paciente-info/`, {
            headers: { 'Authorization': `Bearer ${this.authToken}` },
            validateStatus: () => true,
            timeout: 5000
          });
          
          if (pacienteRes.status === 200 && pacienteRes.data) {
            const data = pacienteRes.data;
            const pacientes = Array.isArray(data) ? data : (data.pacientes || data.results || []);
            
            const isPaciente = pacientes.some(p => 
              p.username?.toLowerCase() === this.username?.toLowerCase() ||
              p.nombre?.toLowerCase().includes(this.username?.toLowerCase())
            );
            
            if (isPaciente) {
              console.log('✅ Usuario encontrado en lista de PACIENTES');
              this.isMedico = false;
              this.userRole = 'paciente';
              this.success = '👤 Sesión iniciada como PACIENTE - Consulta recetas y precios';
              return;
            }
          }
        } catch (e) {
          console.log('⚠️ No se pudo verificar lista de pacientes');
        }
        
        try {
          const medicoRes = await axios.get(`${this.API_URL}/medico-info/`, {
            headers: { 'Authorization': `Bearer ${this.authToken}` },
            validateStatus: () => true,
            timeout: 5000
          });
          
          if (medicoRes.status === 200 && medicoRes.data) {
            const data = medicoRes.data;
            const medicos = Array.isArray(data) ? data : (data.medicos || data.results || []);
            
            const isMedico = medicos.some(m => 
              m.username?.toLowerCase() === this.username?.toLowerCase() ||
              m.nombre?.toLowerCase().includes(this.username?.toLowerCase())
            );
            
            if (isMedico) {
              console.log('✅ Usuario encontrado en lista de MÉDICOS');
              this.isMedico = true;
              this.userRole = 'medico';
              this.success = '🩺 Sesión iniciada como MÉDICO - Puedes generar recetas';
              return;
            }
          }
        } catch (e) {
          console.log('⚠️ No se pudo verificar lista de médicos');
        }
        
        console.log('⚠️ No se encontró en ninguna lista, asumiendo PACIENTE por seguridad');
        this.isMedico = false;
        this.userRole = 'paciente';
        
      } catch (error) {
        console.error('❌ Error verificando rol:', error);
        this.isMedico = false;
        this.userRole = 'paciente';
      }
    },
    
    async testAuth() {
      this.clearMessages();
      this.loading = true;
      try {
        if (!this.authToken) {
          this.error = 'No hay token cargado. Inicia sesión primero.';
          return;
        }
        const endpoints = ['/tasks/', '/recetas/', '/farmacias/'];
        for (const endpoint of endpoints) {
          const res = await axios.get(`${this.API_URL}${endpoint}`, {
            headers: { 'Authorization': `Bearer ${this.authToken}` },
            validateStatus: () => true,
            timeout: 10000
          });
          console.log(`→ ${endpoint}: ${res.status}`);
          if (res.status === 200) {
            this.success = `✅ ${endpoint} OK (200)`;
            this.currentView = 'panel';
            return;
          } else if ([401,403].includes(res.status)) {
            this.error = `Auth fallo en ${endpoint}: ${res.status}. Token inválido o expirado.`;
            return;
          }
        }
        this.error = 'Ningún endpoint respondió 200.';
      } catch (e) {
        this.error = 'Error de red: ' + this.formatAxiosError(e);
      } finally {
        this.loading = false;
      }
    },
    
    async handleLogin() {
      this.clearMessages();
      
      // Validar que los campos no estén vacíos
      if (!this.loginForm.username || this.loginForm.username.trim() === '') {
        this.error = '❌ El nombre de usuario es requerido';
        return;
      }
      
      if (!this.loginForm.password || this.loginForm.password.trim() === '') {
        this.error = '❌ La contraseña es requerida';
        return;
      }
      
      this.loading = true;
      
      try {
        const payload = {
          username: this.loginForm.username.trim(),
          email: this.loginForm.username.trim(),
          password: this.loginForm.password,
        };
        
        console.log('📤 Intentando login en:', `${this.API_URL}/signin/`);
        const response = await axios.post(
          `${this.API_URL}/signin/`,
          payload,
          {
            headers: { 'Content-Type': 'application/json' },
            validateStatus: () => true
          }
        );
        
        console.log('📥 Respuesta login:', response.status, response.statusText);
        
        if (response.status >= 400) {
          const errorDetail = response.data?.detail || response.data?.message || response.data?.error;
          if (errorDetail) {
            throw new Error(`Error ${response.status}: ${errorDetail}`);
          } else {
            throw new Error(`Error ${response.status}: ${JSON.stringify(response.data)}`);
          }
        }
        
        const access = response.data?.access;
        const refresh = response.data?.refresh;
        if (!access) {
          console.warn('⚠️ No se recibió token de acceso en la respuesta');
        } else {
          this.saveAuthTokens(access, refresh);
        }
        
        console.log('✅ Login exitoso');
        this.success = '✅ ¡Login exitoso!';
        this.username = this.loginForm.username;

        if (this.username && this.username.toLowerCase && this.username.toLowerCase() === 'admin') {
          this.userRole = 'admin';
          this.isMedico = false;
          this.success = '👑 Sesión iniciada como ADMINISTRADOR - Acceso completo';
        } else {
          await this.verificarRolUsuario();
        }

        this.currentView = 'panel';

        // Intento adicional contra el servicio de autenticación; si falla no bloquea el login principal
        try {
          const url = `${this.authBase()}/login`;
          const payload = {
            username: this.loginForm.username.trim(),
            password: this.loginForm.password
          };
          await axios.post(url, payload, {
            headers: { 'Content-Type': 'application/json' },
            validateStatus: () => true
          });
        } catch (error) {
          console.warn('Login secundario falló:', error);
        }

        this.loginForm.password = '';

      } catch (error) {
        console.error('Error al iniciar sesión:', error);
        this.error = error?.message ? `Error al iniciar sesión: ${error.message}` : 'Error al iniciar sesión.';
      } finally {
        this.loading = false;
      }
    },
    
    async handleLogout() {
      try {
        const url = `${this.authBase()}/logout`;
        const headers = { 'Content-Type': 'application/json' };
        if (this.authToken) headers['Authorization'] = `Bearer ${this.authToken}`;
        await axios.post(url, { refresh_token: this.refreshToken }, { headers, validateStatus: () => true });
      } catch (error) {
        console.error('Error en logout:', error);
      } finally {
        this.currentView = 'login';
        this.username = '';
        this.userRole = null;
        this.isMedico = false;
        this.saveAuthTokens(null, null);
        this.success = 'Sesión cerrada correctamente';
      }
    },
    
    async graphql(query, variables = {}) {
      try {
        const headers = { 'Content-Type': 'application/json' };
        if (this.authToken) headers['Authorization'] = `Bearer ${this.authToken}`;

        const doRequest = async () => {
          return await axios.post(
            this.GRAPHQL_URL,
            { query, variables },
            { headers, validateStatus: () => true }
          );
        };

        let response = await doRequest();

        // Si el servidor responde 401, intentar refresh y reintentar
        if (response.status === 401) {
          try {
            const newToken = await this.refreshAuthToken();
            headers['Authorization'] = `Bearer ${newToken}`;
            response = await doRequest();
          } catch (e) {
            throw e;
          }
        }

        // Si el HTTP es 200 pero hay error de autenticación en GraphQL
        const needsRefresh = Array.isArray(response.data?.errors) && response.data.errors.some(e => {
          const m = (e.message || '').toLowerCase();
          return m.includes('no autenticado') || m.includes('token') || m.includes('expir');
        });
        if (needsRefresh) {
          try {
            const newToken = await this.refreshAuthToken();
            headers['Authorization'] = `Bearer ${newToken}`;
            response = await doRequest();
          } catch (e) {
            // Propagar para que la UI maneje sesión expirada
            throw e;
          }
        }

        return response.data;

      } catch (error) {
        console.error('Error en GraphQL:', this.formatAxiosError(error));
        throw error;
      }
    },
    
    async obtenerRecetas() {
      this.clearMessages();
      this.loading = true;
      this.respuesta = null;
      
      try {
        const query = `
          query {
            recetas {
              id
              fechaEmision
              pacienteId
              medicoId
              observaciones
              detalles {
                id
                productoId
                cantidad
                indicaciones
              }
            }
          }
        `;
        
        const result = await this.graphql(query);
        
        if (result.errors) {
          this.error = result.errors[0].message;
        } else {
          this.respuesta = result.data;
          this.success = 'Recetas cargadas correctamente';
        }
        
      } catch (error) {
        this.error = 'Error al obtener recetas: ' + error.message;
      } finally {
        this.loading = false;
      }
    },
    
    async generarPDF() {
      this.clearMessages();
      this.loading = true;
      this.respuesta = null;
      try {
        const query = `
          mutation($pac: PacienteInput!, $med: MedicoInput!) {
            generarRecetaPdf(paciente: $pac, medico: $med) {
              mensaje
              archivo
            }
          }
        `;
        const variables = {
          pac: this.pdfForm.paciente,
          med: this.pdfForm.medico
        };
        const result = await this.graphql(query, variables);
        if (result.errors) {
          const errorMsg = result.errors[0].message;
          
          if (errorMsg.includes('Solo un médico') || 
              errorMsg.includes('Acceso denegado') || 
              errorMsg.includes('médico puede generar')) {
            this.error = '🩺 ' + errorMsg;
            
            setTimeout(() => {
              if (this.error) {
                this.error += '\n\n💡 Consejo: Si eres paciente, solicita a tu médico que genere la receta por ti.';
              }
            }, 100);
          } else {
            this.error = errorMsg;
          }
        } else {
          this.respuesta = result.data;
          this.success = 'PDF generado correctamente';
          
          if (result.data.generarRecetaPdf && result.data.generarRecetaPdf.archivo) {
            const base = this.GRAPHQL_URL.replace('/graphql', '');
            const url = base + result.data.generarRecetaPdf.archivo;
            window.open(url, '_blank');
          }
        }
      } catch (error) {
        this.error = 'Error al generar PDF: ' + error.message;
      } finally {
        this.loading = false;
      }
    },
    
    async consultarPrecios() {
      this.clearMessages();
      this.loading = true;
      this.respuesta = null;
      
      try {
        const query = `
          query($nombre: String!, $lat: Float!, $lng: Float!, $radioKm: Float!) {
            preciosMasBaratos(nombre: $nombre, lat: $lat, lng: $lng, radioKm: $radioKm) {
              farmaciaNombre
              precio
              distanciaKm
            }
          }
        `;
        
        const variables = this.preciosForm;
        
        const result = await this.graphql(query, variables);
        
        if (result.errors) {
          this.error = result.errors[0].message;
        } else {
          this.respuesta = result.data;
          this.success = 'Precios consultados correctamente';
        }
        
      } catch (error) {
        this.error = 'Error al consultar precios: ' + error.message;
      } finally {
        this.loading = false;
      }
    },
    
    async obtenerPacientes() {
      this.clearMessages();
      this.loading = true;
      this.respuesta = null;
      
      try {
        const query = `
          query {
            pacientes {
              id
              nombre
              cedula
              email
              telefono
              direccion
              fechaNacimiento
              usuarioId
            }
          }
        `;
        
        const result = await this.graphql(query);
        
        if (result.errors) {
          this.error = result.errors[0].message;
        } else {
          this.respuesta = result.data;
          this.success = `${result.data.pacientes.length} paciente(s) encontrado(s)`;
        }
        
      } catch (error) {
        this.error = 'Error al obtener pacientes: ' + error.message;
      } finally {
        this.loading = false;
      }
    },
    
    async fetchAdminProductos() {
      if (!this.isAdmin()) { 
        this.adminError = 'Acceso denegado: sólo administradores.'; 
        return; 
      }
      this.adminError = null;
      this.adminLoadingProductos = true;
      try {
        const opts = {
          withCredentials: true,
          validateStatus: () => true,
          timeout: 10000
        };
        if (this.authToken) opts.headers = { 'Authorization': `Bearer ${this.authToken}` };

        const endpoint = `${this.API_URL}/api/admin/productos/`;
        console.log('🔍 Cargando productos desde:', endpoint);
        const res = await axios.get(endpoint, opts);
        console.log('📦 Respuesta de productos:', res.data, 'Status:', res.status);
        
        if (res.status === 200 && res.data) {
          let data = res.data;
          
          // Intentar extraer datos de diferentes formatos
          if (data.results && Array.isArray(data.results)) {
            data = data.results;
            console.log('✓ Datos extraídos de field "results":', data);
          } else if (!Array.isArray(data)) {
            data = [data];
            console.log('✓ Datos convertidos a array:', data);
          }
          
          if (Array.isArray(data) && data.length > 0) {
            this.adminData.productos = data;
            this.success = `✅ Productos cargados: ${data.length} encontrado(s)`;
            console.log('✓ Productos guardados en estado:', this.adminData.productos);
          } else {
            this.adminData.productos = null;
            this.adminError = 'No hay productos disponibles';
            console.warn('⚠ No hay productos en la respuesta');
          }
        } else {
          this.adminData.productos = null;
          const detail = res.data?.detail || res.data?.message || 'Sin respuesta del servidor';
          this.adminError = `Error ${res.status} al cargar productos: ${detail}`;
          console.error('❌ Error en respuesta:', res.status, detail);
        }
      } catch (e) {
        this.adminData.productos = null;
        this.adminError = 'Error de red: ' + this.formatAxiosError(e);
        console.error('❌ Error cargando productos:', e);
      } finally {
        this.adminLoadingProductos = false;
      }
    },

    clearAdminProductos() { 
      this.adminData.productos = null; 
    },

    async fetchAdminFarmacias() {
      if (!this.isAdmin()) { 
        this.adminError = 'Acceso denegado: sólo administradores.'; 
        return; 
      }
      this.adminError = null;
      this.adminLoadingFarmacias = true;
      try {
        const opts = {
          withCredentials: true,
          validateStatus: () => true,
          timeout: 10000
        };
        if (this.authToken) opts.headers = { 'Authorization': `Bearer ${this.authToken}` };

        const endpoint = `${this.API_URL}/api/admin/farmacias/`;
        console.log('🔍 Cargando farmacias desde:', endpoint);
        const res = await axios.get(endpoint, opts);
        console.log('🏥 Respuesta de farmacias:', res.data, 'Status:', res.status);
        
        if (res.status === 200 && res.data) {
          let data = res.data;
          
          // Intentar extraer datos de diferentes formatos
          if (data.results && Array.isArray(data.results)) {
            data = data.results;
            console.log('✓ Datos extraídos de field "results":', data);
          } else if (!Array.isArray(data)) {
            data = [data];
            console.log('✓ Datos convertidos a array:', data);
          }
          
          if (Array.isArray(data) && data.length > 0) {
            this.adminData.farmacias = data;
            this.success = `✅ Farmacias cargadas: ${data.length} encontrado(s)`;
            console.log('✓ Farmacias guardadas en estado:', this.adminData.farmacias);
          } else {
            this.adminData.farmacias = null;
            this.adminError = 'No hay farmacias disponibles';
            console.warn('⚠ No hay farmacias en la respuesta');
          }
        } else {
          this.adminData.farmacias = null;
          const detail = res.data?.detail || res.data?.message || 'Sin respuesta del servidor';
          this.adminError = `Error ${res.status} al cargar farmacias: ${detail}`;
          console.error('❌ Error en respuesta:', res.status, detail);
        }
      } catch (e) {
        this.adminData.farmacias = null;
        this.adminError = 'Error de red: ' + this.formatAxiosError(e);
        console.error('❌ Error cargando farmacias:', e);
      } finally {
        this.adminLoadingFarmacias = false;
      }
    },

    clearAdminFarmacias() { 
      this.adminData.farmacias = null; 
    },

    async fetchAdminProductoFarmacia() {
      if (!this.isAdmin()) { 
        this.adminError = 'Acceso denegado: sólo administradores.'; 
        return; 
      }
      this.adminError = null;
      this.adminLoadingRelacion = true;
      try {
        const opts = {
          withCredentials: true,
          validateStatus: () => true,
          timeout: 10000
        };
        if (this.authToken) opts.headers = { 'Authorization': `Bearer ${this.authToken}` };

        const endpoint = `${this.API_URL}/api/admin/producto-farmacia/`;
        console.log('🔍 Cargando relaciones desde:', endpoint);
        const res = await axios.get(endpoint, opts);
        console.log('🔗 Respuesta de relaciones:', res.data, 'Status:', res.status);
        
        if (res.status === 200 && res.data) {
          let data = res.data;
          
          // Intentar extraer datos de diferentes formatos
          if (data.results && Array.isArray(data.results)) {
            data = data.results;
            console.log('✓ Datos extraídos de field "results":', data);
          } else if (!Array.isArray(data)) {
            data = [data];
            console.log('✓ Datos convertidos a array:', data);
          }
          
          if (Array.isArray(data) && data.length > 0) {
            this.adminData.productoFarmacia = data;
            this.success = `✅ Relaciones cargadas: ${data.length} encontrado(s)`;
            console.log('✓ Relaciones guardadas en estado:', this.adminData.productoFarmacia);
          } else {
            this.adminData.productoFarmacia = null;
            this.adminError = 'No hay relaciones disponibles';
            console.warn('⚠ No hay relaciones en la respuesta');
          }
        } else {
          this.adminData.productoFarmacia = null;
          const detail = res.data?.detail || res.data?.message || 'Sin respuesta del servidor';
          this.adminError = `Error ${res.status} al cargar relaciones: ${detail}`;
          console.error('❌ Error en respuesta:', res.status, detail);
        }
      } catch (e) {
        this.adminData.productoFarmacia = null;
        this.adminError = 'Error de red: ' + this.formatAxiosError(e);
        console.error('❌ Error cargando relaciones:', e);
      } finally {
        this.adminLoadingRelacion = false;
      }
    },

    clearAdminRelacion() { 
      this.adminData.productoFarmacia = null; 
    },

    startEditProducto(prod) {
      if (!this.isAdmin()) { 
        this.adminError = 'Solo administradores pueden editar productos.'; 
        return; 
      }
      this.adminEditingProductoId = prod.id;
      this.adminEditingProducto = Object.assign({}, prod);
    },
    
    cancelEditProducto() { 
      this.adminEditingProductoId = null; 
      this.adminEditingProducto = null; 
    },
    
    async saveEditProducto() {
      if (!this.isAdmin()) { 
        this.adminError = 'Solo administradores pueden editar productos.'; 
        return; 
      }
      if (!this.adminEditingProductoId || !this.adminEditingProducto) return;
      const id = this.adminEditingProductoId;
      this.adminCreatingProducto = true;
      try {
        const payload = {
          nombre_generico: this.adminEditingProducto.nombre_generico,
          nombre_comercial: this.adminEditingProducto.nombre_comercial || this.adminEditingProducto.nombre,
          principio_activo: this.adminEditingProducto.principio_activo,
          categoria: this.adminEditingProducto.categoria,
          presentacion: this.adminEditingProducto.presentacion,
          concentracion: this.adminEditingProducto.concentracion,
          precio: this.adminEditingProducto.precio,
          descripcion: this.adminEditingProducto.descripcion
        };
        const opts = { 
          headers: { 'Content-Type': 'application/json' }, 
          validateStatus: () => true, 
          timeout: 10000 
        };
        if (this.authToken) opts.headers['Authorization'] = `Bearer ${this.authToken}`;
        const res = await axios.put(`${this.API_URL}/api/admin/productos/${id}/`, payload, opts);
        if (res.status >= 200 && res.status < 300) {
          const idx = this.adminData.productos.findIndex(p => p.id === id);
          const updated = res.data && res.data.id ? res.data : Object.assign({}, payload, { id });
          if (idx !== -1) this.adminData.productos.splice(idx, 1, updated);
          this.success = 'Producto actualizado correctamente.';
          this.cancelEditProducto();
        } else {
          const detail = res.data?.detail || res.data?.message || JSON.stringify(res.data || {});
          this.adminError = `Error ${res.status} actualizando producto: ${detail}`;
        }
      } catch (e) {
        this.adminError = 'Error de red: ' + this.formatAxiosError(e);
      } finally { 
        this.adminCreatingProducto = false; 
      }
    },

    startEditFarmacia(f) {
      if (!this.isAdmin()) { 
        this.adminError = 'Solo administradores pueden editar farmacias.'; 
        return; 
      }
      this.adminEditingFarmaciaId = f.id;
      this.adminEditingFarmacia = Object.assign({}, f);
    },
    
    cancelEditFarmacia() { 
      this.adminEditingFarmaciaId = null; 
      this.adminEditingFarmacia = null; 
    },
    
    async saveEditFarmacia() {
      if (!this.isAdmin()) { 
        this.adminError = 'Solo administradores pueden editar farmacias.'; 
        return; 
      }
      if (!this.adminEditingFarmaciaId || !this.adminEditingFarmacia) return;
      const id = this.adminEditingFarmaciaId;
      try {
        const payload = {
          nombre: this.adminEditingFarmacia.nombre,
          direccion: this.adminEditingFarmacia.direccion,
          telefono: this.adminEditingFarmacia.telefono
        };
        const opts = { 
          headers: { 'Content-Type': 'application/json' }, 
          validateStatus: () => true, 
          timeout: 10000 
        };
        if (this.authToken) opts.headers['Authorization'] = `Bearer ${this.authToken}`;
        const res = await axios.put(`${this.API_URL}/api/admin/farmacias/${id}/`, payload, opts);
        if (res.status >= 200 && res.status < 300) {
          const idx = this.adminData.farmacias.findIndex(x => x.id === id);
          const updated = res.data && res.data.id ? res.data : Object.assign({}, payload, { id });
          if (idx !== -1) this.adminData.farmacias.splice(idx, 1, updated);
          this.success = 'Farmacia actualizada correctamente.';
          this.cancelEditFarmacia();
        } else {
          const detail = res.data?.detail || res.data?.message || JSON.stringify(res.data || {});
          this.adminError = `Error ${res.status} actualizando farmacia: ${detail}`;
        }
      } catch (e) {
        this.adminError = 'Error de red: ' + this.formatAxiosError(e);
      }
    },

    startEditRelacion(r) {
      if (!this.isAdmin()) { 
        this.adminError = 'Solo administradores pueden editar relaciones producto-farmacia.'; 
        return; 
      }
      this.adminEditingRelacionId = r.id;
      this.adminEditingRelacion = { 
        id: r.id, 
        precio: r.precio ?? r.price, 
        farmacia: r.farmacia ?? r.farmaciaId ?? r.farmacia, 
        producto: r.producto ?? r.productoId ?? r.producto 
      };
    },
    
    cancelEditRelacion() { 
      this.adminEditingRelacionId = null; 
      this.adminEditingRelacion = null; 
    },
    
    async saveEditRelacion() {
      if (!this.isAdmin()) { 
        this.adminError = 'Solo administradores pueden editar relaciones producto-farmacia.'; 
        return; 
      }
      if (!this.adminEditingRelacionId || !this.adminEditingRelacion) return;
      const id = this.adminEditingRelacionId;
      try {
        const payload = Object.assign({}, this.adminEditingRelacion);
        const opts = { 
          headers: { 'Content-Type': 'application/json' }, 
          validateStatus: () => true, 
          timeout: 10000 
        };
        if (this.authToken) opts.headers['Authorization'] = `Bearer ${this.authToken}`;
        const res = await axios.put(`${this.API_URL}/api/admin/producto-farmacia/${id}/`, payload, opts);
        if (res.status >= 200 && res.status < 300) {
          const idx = this.adminData.productoFarmacia.findIndex(x => x.id === id);
          const updated = res.data && res.data.id ? res.data : Object.assign({}, payload, { id });
          if (idx !== -1) this.adminData.productoFarmacia.splice(idx, 1, updated);
          this.success = 'Relación actualizada correctamente.';
          this.cancelEditRelacion();
        } else {
          const detail = res.data?.detail || res.data?.message || JSON.stringify(res.data || {});
          this.adminError = `Error ${res.status} actualizando relación: ${detail}`;
        }
      } catch (e) {
        this.adminError = 'Error de red: ' + this.formatAxiosError(e);
      }
    },

    clearAdminNewProduct() {
      this.adminNewProduct = { 
        nombre_generico: '', 
        nombre_comercial: '', 
        principio_activo: '', 
        categoria: '', 
        presentacion: '', 
        concentracion: '', 
        precio: null, 
        descripcion: '' 
      };
    },

    async sendWebSocketNotification(type, data) {
      try {
        await axios.post(this.WEBSOCKET_URL, {
          type: type,
          data: data,
          timestamp: new Date().toISOString(),
          user: this.username
        }, {
          headers: { 'Content-Type': 'application/json' },
          validateStatus: () => true,
          timeout: 5000
        });
        console.log(`✅ Notificación enviada: ${type}`, data);
      } catch (e) {
        console.warn(`⚠ No se pudo enviar notificación WebSocket:`, e.message);
      }
    },

    async addAdminProducto() {
      if (!this.isAdmin()) { 
        this.adminError = 'Acceso denegado: sólo administradores.'; 
        return; 
      }
      this.adminError = null;
      if (!this.adminNewProduct || !this.adminNewProduct.nombre_comercial) {
        this.adminError = 'El nombre comercial del producto es requerido.';
        return;
      }
      this.adminCreatingProducto = true;
      try {
        const payload = {
          nombre_generico: this.adminNewProduct.nombre_generico,
          nombre_comercial: this.adminNewProduct.nombre_comercial,
          principio_activo: this.adminNewProduct.principio_activo,
          categoria: this.adminNewProduct.categoria,
          presentacion: this.adminNewProduct.presentacion,
          concentracion: this.adminNewProduct.concentracion,
          precio: this.adminNewProduct.precio,
          descripcion: this.adminNewProduct.descripcion
        };

        const opts = {
          headers: { 'Content-Type': 'application/json' },
          validateStatus: () => true,
          timeout: 10000
        };
        if (this.authToken) opts.headers['Authorization'] = `Bearer ${this.authToken}`;

        const res = await axios.post(`${this.API_URL}/api/admin/productos/`, payload, opts);

        if (res.status >= 200 && res.status < 300) {
          const created = res.data && res.data.id ? res.data : (res.data && res.data.results && res.data.results[0]) ? res.data.results[0] : res.data;
          if (!this.adminData.productos) this.adminData.productos = [];
          this.adminData.productos.unshift(created || payload);
          this.success = 'Producto creado correctamente.';
          
          // Enviar notificación en tiempo real
          await this.sendWebSocketNotification('PRODUCT_CREATED', {
            id: created?.id,
            nombre_comercial: created?.nombre_comercial || payload.nombre_comercial,
            nombre_generico: created?.nombre_generico || payload.nombre_generico,
            precio: created?.precio || payload.precio,
            mensaje: `Nuevo producto: ${created?.nombre_comercial || payload.nombre_comercial}`
          });
          
          this.clearAdminNewProduct();
        } else {
          const detail = res.data?.detail || res.data?.message || JSON.stringify(res.data || {});
          this.adminError = `Error ${res.status} creando producto: ${detail}`;
        }
      } catch (e) {
        this.adminError = 'Error de red: ' + this.formatAxiosError(e);
      } finally {
        this.adminCreatingProducto = false;
      }
    },

    clearAdminNewFarmacia() {
      this.adminNewFarmacia = { 
        nombre: '', 
        horario: '',
        direccion: '', 
        telefono: '', 
        lat: null, 
        lng: null 
      };
    },

    async addAdminFarmacia() {
      if (!this.isAdmin()) { 
        this.adminError = 'Acceso denegado: sólo administradores.'; 
        return; 
      }
      this.adminError = null;
      if (!this.adminNewFarmacia || !this.adminNewFarmacia.nombre) {
        this.adminError = 'El nombre de la farmacia es requerido.';
        return;
      }
      if (!this.adminNewFarmacia.horario) {
        this.adminError = 'El horario de atención es requerido.';
        return;
      }
      this.adminCreatingFarmacia = true;
      try {
        const payload = {
          nombre_comercial: this.adminNewFarmacia.nombre,
          horario_atencion: this.adminNewFarmacia.horario,
          direccion: this.adminNewFarmacia.direccion || '',
          telefono: this.adminNewFarmacia.telefono || '',
          lat: this.adminNewFarmacia.lat || 0,
          lng: this.adminNewFarmacia.lng || 0
        };

        const opts = {
          headers: { 'Content-Type': 'application/json' },
          validateStatus: () => true,
          timeout: 10000
        };
        if (this.authToken) opts.headers['Authorization'] = `Bearer ${this.authToken}`;

        const res = await axios.post(`${this.API_URL}/api/admin/farmacias/`, payload, opts);

        if (res.status >= 200 && res.status < 300) {
          const created = res.data && res.data.id ? res.data : (res.data && res.data.results && res.data.results[0]) ? res.data.results[0] : res.data;
          if (!this.adminData.farmacias) this.adminData.farmacias = [];
          this.adminData.farmacias.unshift(created || payload);
          this.success = 'Farmacia creada correctamente.';
          
          // Enviar notificación en tiempo real
          await this.sendWebSocketNotification('PHARMACY_CREATED', {
            id: created?.id,
            nombre: created?.nombre_comercial || payload.nombre_comercial,
            direccion: created?.direccion || payload.direccion,
            telefono: created?.telefono || payload.telefono,
            mensaje: `Nueva farmacia: ${created?.nombre_comercial || payload.nombre_comercial}`
          });
          
          this.clearAdminNewFarmacia();
        } else {
          const detail = res.data?.detail || res.data?.message || JSON.stringify(res.data || {});
          this.adminError = `Error ${res.status} creando farmacia: ${detail}`;
        }
      } catch (e) {
        this.adminError = 'Error de red: ' + this.formatAxiosError(e);
      } finally {
        this.adminCreatingFarmacia = false;
      }
    },

    clearAdminNewRelacion() {
      this.adminNewRelacion = { 
        producto: null, 
        farmacia: null, 
        precio: null, 
        stock: null 
      };
    },

    async addAdminRelacion() {
      if (!this.isAdmin()) { 
        this.adminError = 'Acceso denegado: sólo administradores.'; 
        return; 
      }
      this.adminError = null;
      if (!this.adminNewRelacion || !this.adminNewRelacion.producto || !this.adminNewRelacion.farmacia) {
        this.adminError = 'Producto y Farmacia son requeridos.';
        return;
      }
      if (this.adminNewRelacion.precio === null || this.adminNewRelacion.precio === undefined || this.adminNewRelacion.precio === '') {
        this.adminError = 'El precio es requerido.';
        return;
      }
      this.adminCreatingRelacion = true;
      try {
        // Payload según la documentación de la API
        const payload = {
          producto: this.adminNewRelacion.producto,
          farmacia: this.adminNewRelacion.farmacia,
          precio: String(this.adminNewRelacion.precio), // Convertir a string como espera la API
          disponible: true // Por defecto disponible
        };

        console.log('📤 Payload enviado:', JSON.stringify(payload));

        const opts = {
          headers: { 'Content-Type': 'application/json' },
          validateStatus: () => true,
          timeout: 10000
        };
        if (this.authToken) opts.headers['Authorization'] = `Bearer ${this.authToken}`;

        const res = await axios.post(`${this.API_URL}/api/admin/producto-farmacia/`, payload, opts);

        console.log('📥 Respuesta:', res.status, res.data);

        if (res.status >= 200 && res.status < 300) {
          const created = res.data && res.data.id ? res.data : (res.data && res.data.results && res.data.results[0]) ? res.data.results[0] : res.data;
          if (!this.adminData.productoFarmacia) this.adminData.productoFarmacia = [];
          this.adminData.productoFarmacia.unshift(created || payload);
          this.success = 'Relación producto-farmacia creada correctamente.';
          
          // Enviar notificación en tiempo real
          await this.sendWebSocketNotification('PRODUCT_PHARMACY_RELATION_CREATED', {
            id: created?.id,
            producto_id: created?.producto || payload.producto,
            farmacia_id: created?.farmacia || payload.farmacia,
            precio: created?.precio || payload.precio,
            disponible: created?.disponible || payload.disponible,
            mensaje: `Nueva relación: Producto ${created?.producto || payload.producto} en Farmacia ${created?.farmacia || payload.farmacia}`
          });
          
          this.clearAdminNewRelacion();
        } else {
          const detail = res.data?.detail || res.data?.message || JSON.stringify(res.data || {});
          this.adminError = `Error ${res.status} creando relación: ${detail}`;
        }
      } catch (e) {
        this.adminError = 'Error de red: ' + this.formatAxiosError(e);
      } finally {
        this.adminCreatingRelacion = false;
      }
    },

    checkAdminIframe() {
      try {
        this.adminIframeLoading = true;
        this.adminIframeBlocked = false;
        const iframe = document.getElementById('admin-iframe');
        if (!iframe) {
          this.adminIframeLoading = false;
          this.adminIframeBlocked = true;
          return;
        }

        let handled = false;

        const onLoad = () => {
          if (handled) return; 
          handled = true;
          this.adminIframeLoading = false;
          this.adminIframeBlocked = false;
          iframe.removeEventListener('load', onLoad);
        };

        const onError = () => {
          if (handled) return; 
          handled = true;
          this.adminIframeLoading = false;
          this.adminIframeBlocked = true;
          iframe.removeEventListener('error', onError);
        };

        iframe.addEventListener('load', onLoad);
        iframe.addEventListener('error', onError);

        setTimeout(() => {
          if (handled) return;
          handled = true;
          this.adminIframeLoading = false;
          this.adminIframeBlocked = true;
          try { 
            iframe.removeEventListener('load', onLoad); 
            iframe.removeEventListener('error', onError); 
          } catch(_){}
        }, 3000);
      } catch (e) {
        this.adminIframeLoading = false;
        this.adminIframeBlocked = true;
      }
    }
  }
}).mount('#app');