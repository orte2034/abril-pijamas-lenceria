/**
 * Panel de Administración - Abril Catálogo
 * CRUD completo para productos con Supabase Auth y Storage
 * Funciona con JavaScript vanilla + Supabase SDK via CDN
 */

const AdminPanel = {
    // Estado
    supabase: null,
    user: null,
    session: null,
    products: [],
    filteredProducts: [],
    currentPage: 1,
    pageSize: 20,
    editingProductId: null,
    uploadedImages: [], // Archivos subidos temporalmente
    existingImages: [], // Imágenes existentes al editar
    coloresData: [], // Datos de colores del formulario
    tallasData: [], // Tallas seleccionadas
    deleteTargetId: null,

    // Elementos DOM cacheados
    elements: {},

    // Constantes
    STORAGE_BUCKET: 'producto-imagenes',
    MAX_FILE_SIZE: 5 * 1024 * 1024, // 5MB
    MAX_FILES: 10,
    ALLOWED_TYPES: ['image/jpeg', 'image/png', 'image/webp', 'image/gif'],

    async init() {
        this.cacheElements();
        this.bindEvents();
        this.initTallas();
        this.initColorForm();
        
        // Verificar sesión existente
        await this.checkSession();
        
        // Escuchar cambios de auth
        this.supabase.auth.onAuthStateChange((event, session) => {
            this.handleAuthChange(event, session);
        });
    },

    cacheElements() {
        // Vistas
        this.elements = {
            loginView: document.getElementById('loginView'),
            dashboardView: document.getElementById('dashboardView'),
            productosView: document.getElementById('productosView'),
            formView: document.getElementById('formView'),
            
            // Auth
            loginForm: document.getElementById('loginForm'),
            loginBtn: document.getElementById('loginBtn'),
            logoutBtn: document.getElementById('logoutBtn'),
            loginSubmit: document.getElementById('loginSubmit'),
            loginSpinner: document.getElementById('loginSpinner'),
            loginError: document.getElementById('loginError'),
            userEmail: document.getElementById('userEmail'),
            adminNav: document.getElementById('adminNav'),
            
            // Navegación tabs
            tabButtons: document.querySelectorAll('[data-tab]'),
            tabLinks: document.querySelectorAll('[data-tab-link]'),
            
            // Dashboard
            statTotal: document.getElementById('statTotal'),
            statDestacados: document.getElementById('statDestacados'),
            statUltima: document.getElementById('statUltima'),
            recentProductsBody: document.getElementById('recentProductsBody'),
            recentEmpty: document.getElementById('recentEmpty'),
            
            // Productos listado
            btnNuevoProducto: document.getElementById('btnNuevoProducto'),
            searchProducts: document.getElementById('searchProducts'),
            filterCategoria: document.getElementById('filterCategoria'),
            filterDestacado: document.getElementById('filterDestacado'),
            productsBody: document.getElementById('productsBody'),
            productsEmpty: document.getElementById('productsEmpty'),
            pagination: document.getElementById('pagination'),
            paginationInfo: document.getElementById('paginationInfo'),
            paginationButtons: document.getElementById('paginationButtons'),
            
            // Formulario
            productForm: document.getElementById('productForm'),
            formTitle: document.getElementById('formTitle'),
            productId: document.getElementById('productId'),
            submitBtn: document.getElementById('submitBtn'),
            submitText: document.getElementById('submitText'),
            submitSpinner: document.getElementById('submitSpinner'),
            cancelFormBtn: document.getElementById('cancelFormBtn'),
            
            // Campos formulario
            titulo: document.getElementById('titulo'),
            categoria: document.getElementById('categoria'),
            subtipo: document.getElementById('subtipo'),
            coleccion: document.getElementById('coleccion'),
            precio: document.getElementById('precio'),
            destacado: document.getElementById('destacado'),
            descripcion_es: document.getElementById('descripcion_es'),
            descripcion_en: document.getElementById('descripcion_en'),
            especificaciones: document.getElementById('especificaciones'),
            
            // Imágenes
            dropzone: document.getElementById('dropzone'),
            imagenesInput: document.getElementById('imagenesInput'),
            imagePreviews: document.getElementById('imagePreviews'),
            existingImages: document.getElementById('existingImages'),
            existingImagesGrid: document.getElementById('existingImagesGrid'),
            
            // Colores
            coloresContainer: document.getElementById('coloresContainer'),
            addColorBtn: document.getElementById('addColorBtn'),
            
            // Tallas
            tallasContainer: document.getElementById('tallasContainer'),
            nuevaTalla: document.getElementById('nuevaTalla'),
            addTallaBtn: document.getElementById('addTallaBtn'),
            
            // Modales
            deleteModal: document.getElementById('deleteModal'),
            deleteProductName: document.getElementById('deleteProductName'),
            cancelDeleteBtn: document.getElementById('cancelDeleteBtn'),
            confirmDeleteBtn: document.getElementById('confirmDeleteBtn'),
            imageModal: document.getElementById('imageModal'),
            imageModalGrid: document.getElementById('imageModalGrid'),
            closeImageModal: document.getElementById('closeImageModal'),
            
            // Toast
            toastContainer: document.getElementById('toastContainer'),
        };
    },

    bindEvents() {
        // Auth
        this.elements.loginForm?.addEventListener('submit', (e) => this.handleLogin(e));
        this.elements.logoutBtn?.addEventListener('click', () => this.handleLogout());
        
        // Navegación tabs
        this.elements.tabButtons.forEach(btn => {
            btn.addEventListener('click', () => this.switchTab(btn.dataset.tab));
        });
        this.elements.tabLinks.forEach(link => {
            link.addEventListener('click', (e) => {
                e.preventDefault();
                this.switchTab(link.dataset.tabLink);
            });
        });
        
        // Productos - Nuevo
        this.elements.btnNuevoProducto?.addEventListener('click', () => this.openForm('create'));
        
        // Filtros
        this.elements.searchProducts?.addEventListener('input', this.debounce(() => this.loadProducts(1), 300));
        this.elements.filterCategoria?.addEventListener('change', () => this.loadProducts(1));
        this.elements.filterDestacado?.addEventListener('change', () => this.loadProducts(1));
        
        // Formulario
        this.elements.productForm?.addEventListener('submit', (e) => this.handleFormSubmit(e));
        this.elements.cancelFormBtn?.addEventListener('click', () => this.closeForm());
        
        // Dropzone imágenes
        this.setupDropzone();
        
        // Colores
        this.elements.addColorBtn?.addEventListener('click', () => this.addColorRow());
        
        // Tallas
        this.elements.addTallaBtn?.addEventListener('click', () => this.addCustomTalla());
        
        // Modales
        this.elements.cancelDeleteBtn?.addEventListener('click', () => this.hideDeleteModal());
        this.elements.confirmDeleteBtn?.addEventListener('click', () => this.confirmDelete());
        this.elements.closeImageModal?.addEventListener('click', () => this.hideImageModal());
        this.elements.deleteModal?.addEventListener('click', (e) => {
            if (e.target === this.elements.deleteModal) this.hideDeleteModal();
        });
        this.elements.imageModal?.addEventListener('click', (e) => {
            if (e.target === this.elements.imageModal) this.hideImageModal();
        });
    },

    // ========== AUTENTICACIÓN ==========
    
    async checkSession() {
        const { data: { session } } = await this.supabase.auth.getSession();
        if (session) {
            this.session = session;
            this.user = session.user;
            this.showAuthenticatedUI();
            await this.loadDashboard();
        } else {
            this.showLoginUI();
        }
    },

    handleAuthChange(event, session) {
        this.session = session;
        this.user = session?.user || null;
        
        if (session) {
            this.showAuthenticatedUI();
            this.loadDashboard();
        } else {
            this.showLoginUI();
        }
    },

    async handleLogin(e) {
        e.preventDefault();
        
        const email = this.elements.loginForm.email.value.trim();
        const password = this.elements.loginForm.password.value;
        
        if (!email || !password) {
            this.showLoginError('Completa todos los campos');
            return;
        }
        
        this.setLoading(this.elements.loginSubmit, this.elements.loginSpinner, true);
        this.hideLoginError();
        
        const { data, error } = await this.supabase.auth.signInWithPassword({
            email,
            password
        });
        
        this.setLoading(this.elements.loginSubmit, this.elements.loginSpinner, false);
        
        if (error) {
            this.showLoginError(error.message);
        } else {
            this.showToast('Bienvenido, ' + data.user.email, 'success');
        }
    },

    async handleLogout() {
        await this.supabase.auth.signOut();
        this.showToast('Sesión cerrada', 'info');
    },

    showAuthenticatedUI() {
        this.elements.loginView.classList.add('hidden');
        this.elements.dashboardView.classList.remove('hidden');
        this.elements.productosView.classList.add('hidden');
        this.elements.formView.classList.add('hidden');
        this.elements.adminNav.style.display = 'flex';
        this.elements.loginBtn.classList.add('hidden');
        this.elements.logoutBtn.classList.remove('hidden');
        this.elements.userEmail.textContent = this.user?.email || '';
        this.elements.userEmail.classList.remove('hidden');
        this.switchTab('dashboard');
    },

    showLoginUI() {
        this.elements.loginView.classList.remove('hidden');
        this.elements.dashboardView.classList.add('hidden');
        this.elements.productosView.classList.add('hidden');
        this.elements.formView.classList.add('hidden');
        this.elements.adminNav.style.display = 'none';
        this.elements.loginBtn.classList.remove('hidden');
        this.elements.logoutBtn.classList.add('hidden');
        this.elements.userEmail.classList.add('hidden');
        this.elements.loginForm.reset();
    },

    showLoginError(message) {
        this.elements.loginError.textContent = message;
        this.elements.loginError.classList.remove('hidden');
    },

    hideLoginError() {
        this.elements.loginError.classList.add('hidden');
    },

    // ========== NAVEGACIÓN ==========
    
    switchTab(tabName) {
        // Actualizar botones
        this.elements.tabButtons.forEach(btn => {
            btn.classList.toggle('active', btn.dataset.tab === tabName);
        });
        
        // Ocultar todas las vistas
        this.elements.dashboardView.classList.add('hidden');
        this.elements.productosView.classList.add('hidden');
        this.elements.formView.classList.add('hidden');
        
        // Mostrar vista seleccionada
        switch (tabName) {
            case 'dashboard':
                this.elements.dashboardView.classList.remove('hidden');
                this.loadDashboard();
                break;
            case 'productos':
                this.elements.productosView.classList.remove('hidden');
                this.loadProducts(1);
                break;
            case 'nuevo':
                this.openForm('create');
                break;
        }
    },

    // ========== DASHBOARD ==========
    
    async loadDashboard() {
        try {
            const { data, error } = await this.supabase
                .from('productos')
                .select('id, destacado, fecha_creacion', { count: 'exact' })
                .order('fecha_creacion', { ascending: false })
                .limit(5);
            
            if (error) throw error;
            
            const total = data.length; // count no viene en select simple, hacemos query aparte
            const { count } = await this.supabase
                .from('productos')
                .select('*', { count: 'exact', head: true });
            
            const destacados = data.filter(p => p.destacado).length;
            const ultima = data[0]?.fecha_creacion ? new Date(data[0].fecha_creacion).toLocaleDateString('es-ES') : '—';
            
            this.elements.statTotal.textContent = count || 0;
            this.elements.statDestacados.textContent = destacados;
            this.elements.statUltima.textContent = ultima;
            
            // Productos recientes
            this.renderRecentProducts(data);
            
        } catch (err) {
            console.error('Error cargando dashboard:', err);
            this.showToast('Error cargando dashboard', 'error');
        }
    },

    renderRecentProducts(products) {
        if (!products.length) {
            this.elements.recentProductsBody.innerHTML = '';
            this.elements.recentEmpty.classList.remove('hidden');
            return;
        }
        
        this.elements.recentEmpty.classList.add('hidden');
        this.elements.recentProductsBody.innerHTML = products.map(p => this.transformProduct(p)).map(p => `
            <tr class="hover:bg-ink/5">
                <td class="px-4 py-3">
                    <div class="font-medium text-ink">${this.escapeHtml(p.nombre)}</div>
                    <div class="text-xs text-ink/50">${p.categoria}${p.subtipo ? ` · ${p.subtipo}` : ''}</div>
                </td>
                <td class="px-4 py-3 text-sm text-ink/70">
                    <span class="badge ${p.categoria === 'lenceria' ? 'badge-burgundy' : p.categoria === 'conjuntos' ? 'badge-green' : 'badge-gray'}">
                        ${p.categoria}
                    </span>
                </td>
                <td class="px-4 py-3 text-sm text-ink">${this.formatCOP(p.precio)}</td>
                <td class="px-4 py-3">
                    <span class="badge ${p.destacado ? 'badge-green' : 'badge-gray'}">
                        ${p.destacado ? 'Sí' : 'No'}
                    </span>
                </td>
                <td class="px-4 py-3 text-right text-sm text-ink/60">
                    <button data-edit="${p.id}" class="text-burgundy hover:underline mr-3 text-sm">Editar</button>
                    <button data-delete="${p.id}" class="text-red-600 hover:underline text-sm">Eliminar</button>
                </td>
            </tr>
        `).join('');
        
        // Bind actions
        this.elements.recentProductsBody.querySelectorAll('[data-edit]').forEach(btn => {
            btn.addEventListener('click', () => this.openForm('edit', btn.dataset.edit));
        });
        this.elements.recentProductsBody.querySelectorAll('[data-delete]').forEach(btn => {
            btn.addEventListener('click', () => this.showDeleteModal(btn.dataset.delete));
        });
    },

    // ========== PRODUCTOS CRUD ==========
    
    async loadProducts(page = 1) {
        this.currentPage = page;
        this.showLoading(this.elements.productsBody);
        
        try {
            let query = this.supabase
                .from('productos')
                .select('*', { count: 'exact' })
                .order('fecha_creacion', { ascending: false })
                .range((page - 1) * this.pageSize, page * this.pageSize - 1);
            
            // Filtros
            const search = this.elements.searchProducts?.value.trim();
            if (search) {
                query = query.ilike('titulo', `%${search}%`);
            }
            const cat = this.elements.filterCategoria?.value;
            if (cat) {
                query = query.eq('categoria', cat);
            }
            const dest = this.elements.filterDestacado?.value;
            if (dest !== '') {
                query = query.eq('destacado', dest === 'true');
            }
            
            const { data, error, count } = await query;
            
            if (error) throw error;
            
            this.products = data || [];
            this.renderProductsTable(this.products);
            this.renderPagination(count || 0, page);
            
        } catch (err) {
            console.error('Error cargando productos:', err);
            this.showToast('Error cargando productos', 'error');
            this.elements.productsBody.innerHTML = '';
        }
    },

    renderProductsTable(products) {
        if (!products.length) {
            this.elements.productsBody.innerHTML = '';
            this.elements.productsEmpty.classList.remove('hidden');
            this.elements.pagination.classList.add('hidden');
            return;
        }
        
        this.elements.productsEmpty.classList.add('hidden');
        this.elements.pagination.classList.remove('hidden');
        
        this.elements.productsBody.innerHTML = products.map(p => {
            const tp = this.transformProduct(p);
            const firstImage = tp.colores[0]?.imagen || tp.imagenes[0] || '/logo.jpeg';
            return `
                <tr class="hover:bg-ink/5">
                    <td class="px-4 py-3">
                        <div class="w-16 h-12 rounded overflow-hidden bg-creamwarm">
                            <img src="${this.escapeHtml(firstImage)}" alt="${this.escapeHtml(tp.nombre)}" class="w-full h-full object-cover" loading="lazy">
                        </div>
                    </td>
                    <td class="px-4 py-3">
                        <div class="font-medium text-ink">${this.escapeHtml(tp.nombre)}</div>
                        <div class="text-xs text-ink/50">${tp.categoria}${tp.subtipo ? ` · ${tp.subtipo}` : ''}</div>
                    </td>
                    <td class="px-4 py-3 text-sm text-ink/70">
                        <span class="badge ${tp.categoria === 'lenceria' ? 'badge-burgundy' : tp.categoria === 'conjuntos' ? 'badge-green' : 'badge-gray'}">
                            ${tp.categoria}
                        </span>
                    </td>
                    <td class="px-4 py-3 text-sm text-ink">${this.formatCOP(tp.precio)}</td>
                    <td class="px-4 py-3">
                        <span class="badge ${tp.destacado ? 'badge-green' : 'badge-gray'}">
                            ${tp.destacado ? 'Sí' : 'No'}
                        </span>
                    </td>
                    <td class="px-4 py-3 text-sm text-ink/60">${new Date(p.fecha_creacion).toLocaleDateString('es-ES')}</td>
                    <td class="px-4 py-3 text-right text-sm text-ink/60">
                        <button data-edit="${p.id}" class="text-burgundy hover:underline mr-3">Editar</button>
                        <button data-images="${p.id}" class="text-ink/60 hover:text-burgundy mr-3">Imágenes</button>
                        <button data-delete="${p.id}" class="text-red-600 hover:underline">Eliminar</button>
                    </td>
                </tr>
            `;
        }).join('');
        
        // Bind actions
        this.elements.productsBody.querySelectorAll('[data-edit]').forEach(btn => {
            btn.addEventListener('click', () => this.openForm('edit', btn.dataset.edit));
        });
        this.elements.productsBody.querySelectorAll('[data-images]').forEach(btn => {
            btn.addEventListener('click', () => this.showImageModal(btn.dataset.delete));
        });
        this.elements.productsBody.querySelectorAll('[data-delete]').forEach(btn => {
            btn.addEventListener('click', () => this.showDeleteModal(btn.dataset.delete));
        });
    },

    renderPagination(total, currentPage) {
        const totalPages = Math.ceil(total / this.pageSize);
        this.elements.paginationInfo.textContent = `Mostrando ${(currentPage - 1) * this.pageSize + 1} - ${Math.min(currentPage * this.pageSize, total)} de ${total} productos`;
        
        if (totalPages <= 1) {
            this.elements.paginationButtons.innerHTML = '';
            return;
        }
        
        let html = '';
        if (currentPage > 1) {
            html += `<button data-page="${currentPage - 1}" class="btn-secondary text-sm px-3 py-1">Anterior</button>`;
        }
        
        // Páginas
        const start = Math.max(1, currentPage - 2);
        const end = Math.min(totalPages, currentPage + 2);
        
        for (let i = start; i <= end; i++) {
            html += `<button data-page="${i}" class="tab-btn ${i === currentPage ? 'active' : ''} px-3 py-1">${i}</button>`;
        }
        
        if (currentPage < totalPages) {
            html += `<button data-page="${currentPage + 1}" class="btn-secondary text-sm px-3 py-1">Siguiente</button>`;
        }
        
        this.elements.paginationButtons.innerHTML = html;
        
        this.elements.paginationButtons.querySelectorAll('[data-page]').forEach(btn => {
            btn.addEventListener('click', () => this.loadProducts(parseInt(btn.dataset.page)));
        });
    },

    // ========== FORMULARIO ==========
    
    openForm(mode, productId = null) {
        this.editingProductId = productId;
        this.uploadedImages = [];
        this.existingImages = [];
        this.coloresData = [];
        this.tallasData = ['XS', 'S', 'M', 'L', 'XL'];
        
        // Reset form
        this.elements.productForm.reset();
        this.elements.productId.value = '';
        this.elements.imagePreviews.innerHTML = '';
        this.elements.existingImages.classList.add('hidden');
        this.elements.existingImagesGrid.innerHTML = '';
        this.elements.coloresContainer.innerHTML = '';
        this.elements.tallasContainer.innerHTML = '';
        this.elements.nuevaTalla.value = '';
        
        if (mode === 'edit' && productId) {
            this.elements.formTitle.textContent = 'Editar producto';
            this.elements.submitText.textContent = 'Actualizar producto';
            this.loadProductForEdit(productId);
        } else {
            this.elements.formTitle.textContent = 'Nuevo producto';
            this.elements.submitText.textContent = 'Guardar producto';
            this.addColorRow(); // Al menos un color
            this.renderTallas();
        }
        
        // Cambiar vista
        this.elements.dashboardView.classList.add('hidden');
        this.elements.productosView.classList.add('hidden');
        this.elements.formView.classList.remove('hidden');
        
        // Actualizar tabs
        this.elements.tabButtons.forEach(btn => {
            btn.classList.toggle('active', btn.dataset.tab === 'nuevo');
        });
    },

    closeForm() {
        this.editingProductId = null;
        this.elements.formView.classList.add('hidden');
        this.elements.productosView.classList.remove('hidden');
        this.elements.tabButtons.forEach(btn => {
            btn.classList.toggle('active', btn.dataset.tab === 'productos');
        });
    },

    async loadProductForEdit(id) {
        try {
            const { data, error } = await this.supabase
                .from('productos')
                .select('*')
                .eq('id', id)
                .single();
            
            if (error) throw error;
            if (!data) throw new Error('Producto no encontrado');
            
            // Llenar formulario
            this.elements.productId.value = data.id;
            this.elements.titulo.value = data.titulo;
            this.elements.categoria.value = data.categoria;
            this.elements.subtipo.value = data.subtipo || '';
            this.elements.coleccion.value = data.coleccion || 'Colección 2026';
            this.elements.precio.value = data.precio;
            this.elements.destacado.checked = data.destacado || false;
            this.elements.descripcion_es.value = data.descripcion_es || '';
            this.elements.descripcion_en.value = data.descripcion_en || '';
            this.elements.especificaciones.value = data.especificaciones ? JSON.stringify(data.especificaciones, null, 2) : '';
            
            // Imágenes existentes
            const imagenes = Array.isArray(data.imagenes) ? data.imagenes : 
                           (typeof data.imagenes === 'string' ? JSON.parse(data.imagenes) : []);
            this.existingImages = imagenes;
            this.renderExistingImages();
            
            // Colores
            const colores = Array.isArray(data.colores) ? data.colores : 
                          (typeof data.colores === 'string' ? JSON.parse(data.colores) : []);
            this.coloresData = colores.map((c, i) => ({
                nombre: c.nombre,
                hex: c.hex || '#cccccc',
                imagen: c.imagen,
                isNew: false,
                index: i
            }));
            this.renderColores();
            
            // Tallas
            const tallas = Array.isArray(data.tallas) ? data.tallas : 
                         (typeof data.tallas === 'string' ? data.tallas.split(',').map(t => t.trim()) : ['XS','S','M','L','XL']);
            this.tallasData = tallas;
            this.renderTallas();
            
        } catch (err) {
            console.error('Error cargando producto:', err);
            this.showToast('Error cargando producto para editar', 'error');
            this.closeForm();
        }
    },

    async handleFormSubmit(e) {
        e.preventDefault();
        
        // Validar
        if (!this.validateForm()) return;
        
        this.setLoading(this.elements.submitBtn, this.elements.submitSpinner, true);
        
        try {
            // Subir imágenes nuevas primero
            const imageUrls = await this.uploadImages();
            
            // Combinar imágenes existentes + nuevas
            const allImages = [...this.existingImages, ...imageUrls];
            
            // Preparar colores
            const colores = this.getColoresData();
            
            // Preparar tallas
            const tallas = this.getTallasData();
            
            // Preparar especificaciones
            let especificaciones = null;
            try {
                const specText = this.elements.especificaciones.value.trim();
                if (specText) especificaciones = JSON.parse(specText);
            } catch {
                this.showToast('Especificaciones: JSON inválido', 'error');
                this.setLoading(this.elements.submitBtn, this.elements.submitSpinner, false);
                return;
            }
            
            const productData = {
                titulo: this.elements.titulo.value.trim(),
                categoria: this.elements.categoria.value,
                subtipo: this.elements.subtipo.value || null,
                coleccion: this.elements.coleccion.value.trim() || 'Colección 2026',
                precio: parseInt(this.elements.precio.value),
                destacado: this.elements.destacado.checked,
                descripcion_es: this.elements.descripcion_es.value.trim(),
                descripcion_en: this.elements.descripcion_en.value.trim(),
                especificaciones,
                imagenes: allImages,
                colores: colores,
                tallas: tallas
            };
            
            let result;
            if (this.editingProductId) {
                result = await this.supabase
                    .from('productos')
                    .update(productData)
                    .eq('id', this.editingProductId)
                    .select()
                    .single();
            } else {
                result = await this.supabase
                    .from('productos')
                    .insert(productData)
                    .select()
                    .single();
            }
            
            if (result.error) throw result.error;
            
            this.showToast(
                this.editingProductId ? 'Producto actualizado correctamente' : 'Producto creado correctamente',
                'success'
            );
            
            this.closeForm();
            this.loadProducts(this.currentPage);
            
        } catch (err) {
            console.error('Error guardando producto:', err);
            this.showToast('Error guardando producto: ' + err.message, 'error');
        } finally {
            this.setLoading(this.elements.submitBtn, this.elements.submitSpinner, false);
        }
    },

    validateForm() {
        const required = [
            { field: this.elements.titulo, name: 'Título' },
            { field: this.elements.categoria, name: 'Categoría' },
            { field: this.elements.precio, name: 'Precio' }
        ];
        
        for (const { field, name } of required) {
            if (!field.value || (field.type === 'number' && field.value === '')) {
                this.showToast(`${name} es obligatorio`, 'error');
                field.focus();
                return false;
            }
        }
        
        // Validar al menos un color
        const colores = this.getColoresData();
        if (colores.length === 0) {
            this.showToast('Debe añadir al menos un color', 'error');
            return false;
        }
        
        // Validar que cada color tenga imagen
        for (const c of colores) {
            if (!c.imagen) {
                this.showToast('Todos los colores deben tener imagen', 'error');
                return false;
            }
        }
        
        return true;
    },

    // ========== IMÁGENES ==========
    
    setupDropzone() {
        const dropzone = this.elements.dropzone;
        const input = this.elements.imagenesInput;
        
        // Click para abrir selector
        dropzone.addEventListener('click', () => input.click());
        
        // Drag & drop
        ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
            dropzone.addEventListener(eventName, (e) => {
                e.preventDefault();
                e.stopPropagation();
            }, false);
        });
        
        ['dragenter', 'dragover'].forEach(eventName => {
            dropzone.addEventListener(eventName, () => dropzone.classList.add('active'), false);
        });
        
        ['dragleave', 'drop'].forEach(eventName => {
            dropzone.addEventListener(eventName, () => dropzone.classList.remove('active'), false);
        });
        
        dropzone.addEventListener('drop', (e) => {
            const files = Array.from(e.dataTransfer.files);
            this.handleFiles(files);
        });
        
        input.addEventListener('change', (e) => {
            const files = Array.from(e.target.files);
            this.handleFiles(files);
            input.value = ''; // Reset para permitir mismo archivo de nuevo
        });
    },

    handleFiles(files) {
        const validFiles = files.filter(file => {
            if (!this.ALLOWED_TYPES.includes(file.type)) {
                this.showToast(`${file.name}: tipo no permitido (solo JPG, PNG, WebP, GIF)`, 'error');
                return false;
            }
            if (file.size > this.MAX_FILE_SIZE) {
                this.showToast(`${file.name}: excede 5MB`, 'error');
                return false;
            }
            return true;
        });
        
        const currentCount = this.uploadedImages.length + this.existingImages.length;
        const remaining = this.MAX_FILES - currentCount;
        
        if (validFiles.length > remaining) {
            this.showToast(`Máximo ${this.MAX_FILES} imágenes. Se añadirán las primeras ${remaining}.`, 'error');
            validFiles.splice(remaining);
        }
        
        validFiles.forEach(file => {
            this.uploadedImages.push(file);
            this.renderImagePreview(file, true);
        });
    },

    renderImagePreview(file, isNew = true) {
        const url = URL.createObjectURL(file);
        const idx = this.uploadedImages.indexOf(file);
        
        const div = document.createElement('div');
        div.className = 'image-preview relative';
        div.dataset.index = idx;
        div.innerHTML = `
            <img src="${url}" alt="Preview" loading="lazy">
            <button type="button" class="remove" data-remove="${idx}" aria-label="Eliminar imagen">×</button>
            ${isNew ? '<span class="absolute bottom-1 left-1 right-1 bg-black/50 text-white text-xs px-1 text-center">Nueva</span>' : ''}
        `;
        
        div.querySelector('[data-remove]').addEventListener('click', (e) => {
            e.stopPropagation();
            this.removeUploadedImage(idx);
        });
        
        this.elements.imagePreviews.appendChild(div);
    },

    renderExistingImages() {
        if (!this.existingImages.length) {
            this.elements.existingImages.classList.add('hidden');
            return;
        }
        
        this.elements.existingImages.classList.remove('hidden');
        this.elements.existingImagesGrid.innerHTML = this.existingImages.map((url, idx) => `
            <div class="image-preview relative" data-existing="${idx}">
                <img src="${this.escapeHtml(url)}" alt="Imagen ${idx + 1}" loading="lazy">
                <button type="button" class="remove" data-remove-existing="${idx}" aria-label="Eliminar imagen">×</button>
            </div>
        `).join('');
        
        this.elements.existingImagesGrid.querySelectorAll('[data-remove-existing]').forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.stopPropagation();
                const idx = parseInt(btn.dataset.removeExisting);
                this.removeExistingImage(idx);
            });
        });
    },

    removeUploadedImage(index) {
        URL.revokeObjectURL(this.uploadedImages[index]?.previewUrl);
        this.uploadedImages.splice(index, 1);
        this.rebuildImagePreviews();
    },

    removeExistingImage(index) {
        this.existingImages.splice(index, 1);
        this.renderExistingImages();
    },

    rebuildImagePreviews() {
        this.elements.imagePreviews.innerHTML = '';
        this.uploadedImages.forEach((file, idx) => this.renderImagePreview(file, true));
    },

    async uploadImages() {
        if (!this.uploadedImages.length) return [];
        
        this.showToast('Subiendo imágenes...', 'info');
        const urls = [];
        
        for (const file of this.uploadedImages) {
            try {
                const fileName = `${Date.now()}-${Math.random().toString(36).substr(2, 9)}-${file.name.replace(/[^a-zA-Z0-9.-]/g, '_')}`;
                const path = `${this.editingProductId || 'new'}/${fileName}`;
                
                const { data, error } = await this.supabase.storage
                    .from(this.STORAGE_BUCKET)
                    .upload(path, file, {
                        cacheControl: '3600',
                        upsert: false
                    });
                
                if (error) throw error;
                
                const { data: { publicUrl } } = this.supabase.storage
                    .from(this.STORAGE_BUCKET)
                    .getPublicUrl(data.path);
                
                urls.push(publicUrl);
            } catch (err) {
                console.error('Error subiendo imagen:', err);
                this.showToast(`Error subiendo ${file.name}`, 'error');
            }
        }
        
        return urls;
    },

    // ========== COLORES ==========
    
    initColorForm() {
        // Inicializar con un color vacío
    },

    addColorRow(data = null) {
        const index = this.coloresData.length;
        const colorData = data || { nombre: '', hex: '#cccccc', imagen: '', isNew: true, index };
        
        this.coloresData.push(colorData);
        this.renderColores();
    },

    renderColores() {
        this.elements.coloresContainer.innerHTML = this.coloresData.map((c, i) => `
            <div class="card p-4 flex flex-col md:flex-row gap-4 items-start" data-color-index="${i}">
                <div class="md:w-1/3">
                    <label class="label-field">Nombre del color *</label>
                    <input type="text" name="color_nombre" class="input-field" value="${this.escapeHtml(c.nombre)}" placeholder="Ej: Negro, Beige, Floral" required>
                </div>
                <div class="md:w-1/3">
                    <label class="label-field">Código HEX</label>
                    <div class="flex gap-2">
                        <input type="color" name="color_hex" class="w-12 h-10 border border-ink/30 rounded cursor-pointer" value="${c.hex}" title="Selector de color">
                        <input type="text" name="color_hex_text" class="input-field flex-1 font-mono text-sm uppercase" value="${c.hex}" placeholder="#RRGGBB" maxlength="7" pattern="#[0-9a-fA-F]{6}">
                    </div>
                </div>
                <div class="md:w-1/3">
                    <label class="label-field">Imagen *</label>
                    <div class="flex gap-2">
                        <input type="file" name="color_imagen" accept="image/*" class="input-field flex-1 color-image-input" data-index="${i}">
                        ${c.imagen ? `
                            <button type="button" class="btn-secondary px-3" data-view-color="${i}" title="Ver imagen">
                                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path></svg>
                            </button>
                        ` : ''}
                    </div>
                    ${c.imagen ? `<img src="${this.escapeHtml(c.imagen)}" alt="${this.escapeHtml(c.nombre)}" class="mt-2 h-16 w-auto rounded border border-ink/10">` : ''}
                </div>
                <div class="md:w-auto flex items-end">
                    <button type="button" class="btn-danger text-sm" data-remove-color="${i}" title="Eliminar color">
                        <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
                        Eliminar
                    </button>
                </div>
            </div>
        `).join('');
        
        // Bind eventos de colores
        this.elements.coloresContainer.querySelectorAll('[data-remove-color]').forEach(btn => {
            btn.addEventListener('click', () => this.removeColor(parseInt(btn.dataset.removeColor)));
        });
        
        this.elements.coloresContainer.querySelectorAll('[data-view-color]').forEach(btn => {
            btn.addEventListener('click', () => this.viewColorImage(parseInt(btn.dataset.viewColor)));
        });
        
        // Sincronizar hex input y color picker
        this.elements.coloresContainer.querySelectorAll('[name="color_hex"]').forEach((picker, i) => {
            const textInput = this.elements.coloresContainer.querySelectorAll('[name="color_hex_text"]')[i];
            picker.addEventListener('input', () => {
                textInput.value = picker.value;
                this.coloresData[i].hex = picker.value;
            });
            textInput.addEventListener('input', () => {
                if (/^#[0-9a-fA-F]{6}$/.test(textInput.value)) {
                    picker.value = textInput.value;
                    this.coloresData[i].hex = textInput.value;
                }
            });
        });
        
        // Nombre
        this.elements.coloresContainer.querySelectorAll('[name="color_nombre"]').forEach((input, i) => {
            input.addEventListener('input', () => {
                this.coloresData[i].nombre = input.value;
            });
        });
        
        // Imagen
        this.elements.coloresContainer.querySelectorAll('[name="color_imagen"]').forEach(input => {
            input.addEventListener('change', (e) => this.handleColorImage(e, parseInt(input.dataset.index)));
        });
    },

    removeColor(index) {
        this.coloresData.splice(index, 1);
        this.renderColores();
    },

    async handleColorImage(e, index) {
        const file = e.target.files[0];
        if (!file) return;
        
        if (!this.ALLOWED_TYPES.includes(file.type)) {
            this.showToast('Tipo de imagen no permitido', 'error');
            return;
        }
        if (file.size > this.MAX_FILE_SIZE) {
            this.showToast('Imagen excede 5MB', 'error');
            return;
        }
        
        // Subir directamente a Supabase Storage
        try {
            this.showToast('Subiendo imagen...', 'info');
            const fileName = `color-${Date.now()}-${Math.random().toString(36).substr(2, 9)}-${file.name.replace(/[^a-zA-Z0-9.-]/g, '_')}`;
            const path = `${this.editingProductId || 'temp'}/${fileName}`;
            
            const { data, error } = await this.supabase.storage
                .from(this.STORAGE_BUCKET)
                .upload(path, file);
            
            if (error) throw error;
            
            const { data: { publicUrl } } = this.supabase.storage
                .from(this.STORAGE_BUCKET)
                .getPublicUrl(data.path);
            
            this.coloresData[index].imagen = publicUrl;
            this.renderColores();
            this.showToast('Imagen subida', 'success');
        } catch (err) {
            console.error('Error subiendo imagen de color:', err);
            this.showToast('Error subiendo imagen', 'error');
        }
    },

    viewColorImage(index) {
        const url = this.coloresData[index]?.imagen;
        if (url) {
            this.showImageModal(null, [url]);
        }
    },

    getColoresData() {
        return this.coloresData
            .filter(c => c.nombre.trim())
            .map(c => ({
                nombre: c.nombre.trim(),
                hex: c.hex || '#cccccc',
                imagen: c.imagen
            }));
    },

    // ========== TALLAS ==========
    
    initTallas() {
        const defaultTallas = ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'Única'];
        this.tallasData = [...defaultTallas];
    },

    renderTallas() {
        this.elements.tallasContainer.innerHTML = this.tallasData.map(talla => `
            <span class="inline-flex items-center gap-1 px-3 py-1.5 bg-creamwarm border border-ink/20 rounded text-sm text-ink cursor-pointer hover:border-burgundy hover:bg-burgundy/5 transition talla-tag" data-talla="${this.escapeHtml(talla)}">
                ${this.escapeHtml(talla)}
                <button type="button" class="ml-1 text-ink/40 hover:text-red-500" data-remove-talla="${this.escapeHtml(talla)}" aria-label="Eliminar talla">×</button>
            </span>
        `).join('');
        
        this.elements.tallasContainer.querySelectorAll('[data-remove-talla]').forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.stopPropagation();
                this.removeTalla(btn.dataset.removeTalla);
            });
        });
    },

    addCustomTalla() {
        const value = this.elements.nuevaTalla.value.trim().toUpperCase();
        if (!value) return;
        
        if (this.tallasData.includes(value)) {
            this.showToast('Esa talla ya existe', 'error');
            return;
        }
        
        this.tallasData.push(value);
        this.elements.nuevaTalla.value = '';
        this.renderTallas();
    },

    removeTalla(talla) {
        this.tallasData = this.tallasData.filter(t => t !== talla);
        this.renderTallas();
    },

    getTallasData() {
        return this.tallasData.filter(t => t.trim());
    },

    // ========== ELIMINAR ==========
    
    showDeleteModal(productId) {
        const product = this.products.find(p => p.id === productId);
        this.deleteTargetId = productId;
        this.elements.deleteProductName.textContent = product?.titulo || 'este producto';
        this.elements.deleteModal.classList.remove('hidden');
        document.body.style.overflow = 'hidden';
    },

    hideDeleteModal() {
        this.elements.deleteModal.classList.add('hidden');
        this.deleteTargetId = null;
        document.body.style.overflow = '';
    },

    async confirmDelete() {
        if (!this.deleteTargetId) return;
        
        this.setLoading(this.elements.confirmDeleteBtn, null, true);
        
        try {
            // Obtener imágenes para borrar de Storage
            const { data: product } = await this.supabase
                .from('productos')
                .select('imagenes, colores')
                .eq('id', this.deleteTargetId)
                .single();
            
            // Eliminar de BD
            const { error } = await this.supabase
                .from('productos')
                .delete()
                .eq('id', this.deleteTargetId);
            
            if (error) throw error;
            
            // Eliminar imágenes de Storage (best effort)
            if (product) {
                const allImages = [
                    ...(Array.isArray(product.imagenes) ? product.imagenes : []),
                    ...(Array.isArray(product.colores) ? product.colores.map(c => c.imagen).filter(Boolean) : [])
                ];
                
                for (const url of allImages) {
                    try {
                        const path = this.extractStoragePath(url);
                        if (path) {
                            await this.supabase.storage.from(this.STORAGE_BUCKET).remove([path]);
                        }
                    } catch {}
                }
            }
            
            this.showToast('Producto eliminado', 'success');
            this.hideDeleteModal();
            this.loadProducts(this.currentPage);
            this.loadDashboard();
            
        } catch (err) {
            console.error('Error eliminando:', err);
            this.showToast('Error eliminando producto', 'error');
        } finally {
            this.setLoading(this.elements.confirmDeleteBtn, null, false);
        }
    },

    extractStoragePath(url) {
        try {
            const bucketUrl = `${this.supabase.storageUrl}/object/public/${this.STORAGE_BUCKET}/`;
            if (url.includes(bucketUrl)) {
                return url.split(bucketUrl)[1];
            }
        } catch {}
        return null;
    },

    // ========== MODAL IMÁGENES ==========
    
    showImageModal(productId, images = null) {
        if (images) {
            this.elements.imageModalGrid.innerHTML = images.map(url => `
                <div class="image-preview">
                    <img src="${this.escapeHtml(url)}" alt="Imagen" loading="lazy">
                </div>
            `).join('');
            this.elements.imageModal.classList.remove('hidden');
            document.body.style.overflow = 'hidden';
            return;
        }
        
        // Cargar imágenes del producto
        const product = this.products.find(p => p.id === productId);
        if (!product) return;
        
        const allImages = [
            ...(Array.isArray(product.imagenes) ? product.imagenes : []),
            ...(Array.isArray(product.colores) ? product.colores.map(c => c.imagen).filter(Boolean) : [])
        ];
        
        if (!allImages.length) {
            this.showToast('El producto no tiene imágenes', 'info');
            return;
        }
        
        this.elements.imageModalGrid.innerHTML = allImages.map(url => `
            <div class="image-preview">
                <img src="${this.escapeHtml(url)}" alt="Imagen" loading="lazy">
            </div>
        `).join('');
        
        this.elements.imageModal.classList.remove('hidden');
        document.body.style.overflow = 'hidden';
    },

    hideImageModal() {
        this.elements.imageModal.classList.add('hidden');
        document.body.style.overflow = '';
    },

    // ========== UTILIDADES ==========
    
    setLoading(btn, spinner, loading) {
        if (btn) btn.disabled = loading;
        if (spinner) spinner.classList.toggle('hidden', !loading);
        if (btn && !spinner) {
            btn.style.opacity = loading ? '0.7' : '1';
        }
    },

    showLoading(container) {
        container.innerHTML = `
            <tr>
                <td colspan="7" class="px-4 py-12 text-center">
                    <div class="flex flex-col items-center gap-4">
                        <div class="w-8 h-8 border-4 border-burgundy border-t-transparent rounded-full animate-spin"></div>
                        <p class="text-ink/50">Cargando productos...</p>
                    </div>
                </td>
            </tr>
        `;
    },

    showToast(message, type = 'info') {
        const toast = document.createElement('div');
        toast.className = `toast toast-${type}`;
        toast.textContent = message;
        this.elements.toastContainer.appendChild(toast);
        
        setTimeout(() => {
            toast.style.opacity = '0';
            toast.style.transform = 'translateY(20px)';
            setTimeout(() => toast.remove(), 300);
        }, 4000);
    },

    formatCOP(value) {
        return new Intl.NumberFormat('es-CO', {
            style: 'currency',
            currency: 'COP',
            minimumFractionDigits: 0,
            maximumFractionDigits: 0
        }).format(value);
    },

    escapeHtml(text) {
        if (!text) return '';
        return String(text)
            .replace(/&/g, '&')
            .replace(/</g, '<')
            .replace(/>/g, '>')
            .replace(/"/g, '"')
            .replace(/'/g, '&#039;');
    },

    transformProduct(p) {
        const colores = Array.isArray(p.colores) ? p.colores : 
                       (typeof p.colores === 'string' ? JSON.parse(p.colores) : []);
        return {
            id: p.id,
            nombre: p.titulo,
            categoria: p.categoria,
            subtipo: p.subtipo,
            precio: p.precio,
            destacado: p.destacado,
            colores,
            fecha_creacion: p.fecha_creacion
        };
    },

    debounce(fn, delay) {
        let timeoutId;
        return (...args) => {
            clearTimeout(timeoutId);
            timeoutId = setTimeout(() => fn.apply(this, args), delay);
        };
    }
};

// Exportar para uso global
window.AdminPanel = AdminPanel;