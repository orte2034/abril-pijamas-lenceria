/**
 * Catálogo Dinámico - Abril Pijamas y Lencería
 * Renderiza productos desde Supabase manteniendo la estructura HTML y clases CSS idénticas al diseño original
 * NO modifica la apariencia visual, solo inyecta datos dinámicamente
 */

const Catalogo = {
    // Estado
    products: [],
    filteredProducts: [],
    maxPrice: 0,
    
    // Filtros activos
    filters: {
        categoria: '',
        subtipos: new Set(),
        colores: new Set(),
        precioMax: 0
    },

    // Elementos DOM
    elements: {},

    // Textos i18n (mismos que en Astro)
    i18n: {
        'hero.eyebrow': 'NUEVA COLECCIÓN',
        'catalogo.title': 'Catálogo',
        'catalogo.filter.categoria': 'Categoría',
        'catalogo.filter.subtipo': 'Subtipo',
        'catalogo.filter.precio': 'Precio',
        'catalogo.filter.color': 'Color',
        'catalogo.clear': 'Limpiar filtros',
        'catalogo.verTodo': 'Ver todo',
        'catalogo.empty': 'No hay productos que coincidan con los filtros seleccionados.',
        'nav.catalogo': 'Catálogo',
        'producto.colores': 'Colores',
        'categoria.pijamas': 'Pijamas',
        'categoria.lenceria': 'Lencería',
        'categoria.conjuntos': 'Conjuntos',
        'subtipo.clasica': 'Clásica',
        'subtipo.babydoll': 'Babydoll',
        'subtipo.bodys': 'Bodys'
    },

    async init() {
        // Esperar a que Supabase esté listo
        await this.waitForSupabase();
        
        // Cachear elementos DOM
        this.cacheElements();
        
        // Cargar productos
        await this.loadProducts();
        
        // Inicializar filtros
        this.initFilters();
        
        // Renderizar productos iniciales
        this.renderProducts();
        
        // Configurar IntersectionObserver para animaciones reveal
        this.initRevealAnimations();
    },

    async waitForSupabase() {
        let attempts = 0;
        while (!window.AbrilSupabase?.getClient && attempts < 50) {
            await new Promise(r => setTimeout(r, 100));
            attempts++;
        }
        this.supabase = await window.AbrilSupabase.getClient();
    },

    cacheElements() {
        this.elements = {
            grid: document.querySelector('[data-products-grid]'),
            empty: document.querySelector('[data-empty]'),
            catInputs: Array.from(document.querySelectorAll('[data-filter-cat]')),
            subtipoInputs: Array.from(document.querySelectorAll('[data-filter-subtipo]')),
            colorBtns: Array.from(document.querySelectorAll('[data-filter-color]')),
            priceRange: document.querySelector('[data-price-max]'),
            priceMaxLabel: document.querySelector('[data-price-max-label]'),
            clearBtn: document.querySelector('[data-clear-filters]')
        };
    },

    async loadProducts() {
        try {
            const { data, error } = await this.supabase
                .from('productos')
                .select('*')
                .order('fecha_creacion', { ascending: false });

            if (error) throw error;

            // Transformar datos de Supabase al formato esperado por el template
            this.products = data.map(p => this.transformProduct(p));
            
            // Calcular precio máximo para el slider
            this.maxPrice = Math.max(...this.products.map(p => p.precio), 0);
            
            // Actualizar slider
            if (this.elements.priceRange) {
                this.elements.priceRange.max = this.maxPrice;
                this.elements.priceRange.value = this.maxPrice;
                this.filters.precioMax = this.maxPrice;
            }
            if (this.elements.priceMaxLabel) {
                this.elements.priceMaxLabel.textContent = this.formatCOP(this.maxPrice);
            }

            // Extraer colores únicos para los botones de filtro
            this.updateColorFilterButtons();

        } catch (err) {
            console.error('Error cargando productos:', err);
            this.showError('No se pudieron cargar los productos. Verifica la conexión a Supabase.');
        }
    },

    transformProduct(p) {
        // Los colores vienen como JSONB array: [{nombre, hex, imagen}, ...]
        const colores = Array.isArray(p.colores) ? p.colores : 
                       (typeof p.colores === 'string' ? JSON.parse(p.colores) : []);
        
        // Las tallas vienen como array de texto
        const tallas = Array.isArray(p.tallas) ? p.tallas : 
                      (typeof p.tallas === 'string' ? p.tallas.split(',').map(t => t.trim()) : ['XS','S','M','L','XL']);

        // Imágenes: usar la primera imagen de cada color, o el array imagenes
        const imagenes = Array.isArray(p.imagenes) ? p.imagenes : 
                        (typeof p.imagenes === 'string' ? JSON.parse(p.imagenes) : []);

        return {
            id: p.id,
            slug: this.slugify(p.titulo),
            nombre: p.titulo,
            categoria: p.categoria,
            subtipo: p.subtipo,
            coleccion: p.coleccion,
            precio: p.precio,
            destacado: p.destacado,
            colores: colores.length > 0 ? colores : [
                { nombre: 'Único', hex: '#cccccc', imagen: imagenes[0] || '/logo.jpeg' }
            ],
            tallas: tallas,
            descripcion_es: p.descripcion_es || '',
            descripcion_en: p.descripcion_en || '',
            imagenes: imagenes,
            fecha_creacion: p.fecha_creacion
        };
    },

    slugify(text) {
        return text
            .toLowerCase()
            .normalize('NFD').replace(/[\u0300-\u036f]/g, '')
            .replace(/[^a-z0-9]+/g, '-')
            .replace(/(^-|-$)/g, '');
    },

    updateColorFilterButtons() {
        const colorContainer = document.querySelector('[data-filter-group="color"] .flex');
        if (!colorContainer) return;

        // Obtener colores únicos de todos los productos
        const allColors = new Map();
        this.products.forEach(p => {
            p.colores.forEach(c => {
                if (!allColors.has(c.nombre)) {
                    allColors.set(c.nombre, c.hex);
                }
            });
        });

        // Reconstruir botones de color
        colorContainer.innerHTML = '';
        allColors.forEach((hex, nombre) => {
            const btn = document.createElement('button');
            btn.type = 'button';
            btn.setAttribute('data-filter-color', nombre);
            btn.className = 'w-7 h-7 rounded-full border border-ink/15 transition';
            btn.style.backgroundColor = hex && hex !== '#cccccc' ? hex : '#cccccc';
            btn.title = nombre;
            btn.setAttribute('aria-label', nombre);
            colorContainer.appendChild(btn);
        });

        // Re-cachear botones de color
        this.elements.colorBtns = Array.from(document.querySelectorAll('[data-filter-color]'));
        this.bindColorButtons();
    },

    bindColorButtons() {
        this.elements.colorBtns.forEach(btn => {
            btn.addEventListener('click', () => this.handleColorClick(btn));
        });
    },

    initFilters() {
        // Categoría (radio)
        this.elements.catInputs.forEach(input => {
            input.addEventListener('change', () => this.handleCategoriaChange(input));
        });

        // Subtipo (checkbox)
        this.elements.subtipoInputs.forEach(input => {
            input.addEventListener('change', () => this.handleSubtipoChange(input));
        });

        // Color (botones) - ya enlazados en updateColorFilterButtons

        // Precio (range)
        if (this.elements.priceRange) {
            this.elements.priceRange.addEventListener('input', () => this.handlePriceChange());
        }

        // Limpiar filtros
        if (this.elements.clearBtn) {
            this.elements.clearBtn.addEventListener('click', () => this.clearFilters());
        }

        // Hash URL para deep linking
        this.handleHash();
    },

    handleCategoriaChange(input) {
        this.filters.categoria = input.value;
        this.applyFilters();
    },

    handleSubtipoChange(input) {
        if (input.checked) this.filters.subtipos.add(input.value);
        else this.filters.subtipos.delete(input.value);
        this.applyFilters();
    },

    handleColorClick(btn) {
        const color = btn.getAttribute('data-filter-color');
        if (this.filters.colores.has(color)) {
            this.filters.colores.delete(color);
            btn.style.outline = 'none';
        } else {
            this.filters.colores.add(color);
            btn.style.outline = '2px solid #7B2D3F';
            btn.style.outlineOffset = '2px';
        }
        this.applyFilters();
    },

    handlePriceChange() {
        this.filters.precioMax = Number(this.elements.priceRange.value);
        if (this.elements.priceMaxLabel) {
            this.elements.priceMaxLabel.textContent = this.formatCOP(this.filters.precioMax);
        }
        this.applyFilters();
    },

    clearFilters() {
        this.filters = {
            categoria: '',
            subtipos: new Set(),
            colores: new Set(),
            precioMax: this.maxPrice
        };

        // Resetear UI
        this.elements.catInputs.forEach(c => c.checked = (c.value === ''));
        this.elements.subtipoInputs.forEach(c => c.checked = false);
        this.elements.colorBtns.forEach(b => b.style.outline = 'none');
        if (this.elements.priceRange) {
            this.elements.priceRange.value = this.maxPrice;
            if (this.elements.priceMaxLabel) {
                this.elements.priceMaxLabel.textContent = this.formatCOP(this.maxPrice);
            }
        }

        this.applyFilters();
    },

    applyFilters() {
        let visible = 0;

        this.products.forEach(product => {
            const itemEl = document.querySelector(`[data-product-item][data-slug="${product.slug}"]`);
            if (!itemEl) return;

            const cat = product.categoria;
            const sub = product.subtipo || '';
            const precio = product.precio;
            const colores = product.colores.map(c => c.nombre);

            const okCat = !this.filters.categoria || this.filters.categoria === cat;
            const okSub = !this.filters.categoria || this.filters.categoria !== 'lenceria' || 
                         this.filters.subtipos.size === 0 || this.filters.subtipos.has(sub || 'clasica');
            const okColor = this.filters.colores.size === 0 || colores.some(c => this.filters.colores.has(c));
            const okPrice = precio <= this.filters.precioMax;

            if (okCat && okSub && okColor && okPrice) {
                itemEl.style.display = '';
                visible++;
            } else {
                itemEl.style.display = 'none';
            }
        });

        if (this.elements.empty) {
            this.elements.empty.classList.toggle('hidden', visible > 0);
        }
    },

    handleHash() {
        const hash = window.location.hash.substring(1);
        if (!hash) return;

        const params = new URLSearchParams(hash.replace(/&/g, '&'));
        const cat = params.get('cat');
        if (cat && ['pijamas', 'lenceria', 'conjuntos'].includes(cat)) {
            const input = document.querySelector(`[data-filter-cat="${cat}"]`);
            if (input) {
                input.checked = true;
                this.filters.categoria = cat;
                this.applyFilters();
            }
        }
    },

    renderProducts() {
        if (!this.elements.grid) return;

        // Generar HTML para cada producto usando la MISMA estructura que ProductCard.astro
        this.elements.grid.innerHTML = this.products.map(p => this.renderProductCard(p)).join('');

        // Re-inicializar botones de color después de renderizar
        this.bindProductColorSelectors();
        this.bindProductSizeSelectors();
        this.bindWhatsAppButtons();
    },

    renderProductCard(p) {
        const firstColor = p.colores[0];
        const coleccion = p.coleccion || 'Colección 2026';
        const categoria = p.categoria;
        const subtipo = p.subtipo;

        return `
            <div data-product-item
                 data-slug="${p.slug}"
                 data-categoria="${categoria}"
                 data-subtipo="${subtipo || ''}"
                 data-precio="${p.precio}"
                 data-colores="${p.colores.map(c => c.nombre).join('|')}">
                <article class="reveal group cursor-pointer" data-product-card data-slug="${p.slug}" data-nombre="${this.escapeHtml(p.nombre)}" data-coleccion="${this.escapeHtml(coleccion)}" data-categoria="${categoria}" data-subtipo="${subtipo || ''}">
                    <a href="/producto/${p.slug}" class="block" aria-label="Ver ${this.escapeHtml(p.nombre)}">
                        <div class="relative aspect-[3/4] overflow-hidden bg-creamwarm rounded-sm">
                            <img
                                data-product-image
                                src="${firstColor.imagen}"
                                alt="${this.escapeHtml(p.nombre)} ${this.escapeHtml(firstColor.nombre)}"
                                class="w-full h-full object-cover transition-all duration-500 ease-editorial group-hover:scale-[1.03]"
                                loading="lazy"
                            />
                            <div class="absolute top-3 left-3">
                                <span class="eyebrow bg-crema/90 px-2.5 py-1">${this.escapeHtml(coleccion)}</span>
                            </div>
                            ${subtipo && subtipo !== 'clasica' ? `
                                <div class="absolute top-3 right-3">
                                    <span class="eyebrow bg-burgundy/90 text-crema px-2.5 py-1 capitalize">${this.escapeHtml(subtipo)}</span>
                                </div>
                            ` : ''}
                        </div>

                        <div class="mt-4 flex items-baseline justify-between">
                            <h3 class="font-serif text-lg text-ink">${this.escapeHtml(p.nombre)}</h3>
                            <span class="text-sm text-ink/70">${this.formatCOP(p.precio)}</span>
                        </div>

                        ${p.colores.length > 1 ? `
                            <p class="mt-1 text-xs text-ink/60">${p.colores.length} ${this.i18n['producto.colores'].toLowerCase()} · <span data-color-name>${this.escapeHtml(firstColor.nombre)}</span></p>
                        ` : `
                            <p class="mt-1 text-xs text-ink/60 capitalize">${this.i18n['categoria.' + categoria] || categoria}${subtipo && subtipo !== 'clasica' ? ` · ${this.escapeHtml(subtipo)}` : ''}</p>
                        `}

                        ${p.colores.length > 1 ? `
                            <div class="mt-3 [&>[data-color-selector]]:scale-90 [&>[data-color-selector]]:origin-left" data-color-selector-wrapper>
                                ${this.renderColorSelector(p.colores, firstColor.nombre, `card-${p.slug}`)}
                            </div>
                        ` : ''}
                    </a>
                    <span class="hidden" data-talla-selected></span>
                </article>
            </div>
        `;
    },

    renderColorSelector(colores, selectedNombre, id) {
        return `
            <div class="flex flex-wrap gap-2" data-color-selector="${id}">
                ${colores.map((c, i) => {
                    const isSelected = c.nombre === selectedNombre;
                    return `
                        <button
                            type="button"
                            class="relative w-9 h-9 rounded-full border transition overflow-hidden ${isSelected ? 'ring-2 ring-burgundy/30 border-burgundy border-2' : 'border-ink/20 hover:border-ink/50'}"
                            style="${c.hex && c.hex !== '#cccccc' ? `background-color: ${c.hex};` : ''}"
                            data-color="${this.escapeHtml(c.nombre)}"
                            data-image="${this.escapeHtml(c.imagen)}"
                            data-idx="${i}"
                            aria-label="${this.escapeHtml(c.nombre)}"
                            aria-pressed="${isSelected}"
                            title="${this.escapeHtml(c.nombre)}"
                        >
                            ${c.hex === '#cccccc' ? `<img src="${this.escapeHtml(c.imagen)}" alt="${this.escapeHtml(c.nombre)}" class="w-full h-full object-cover" loading="lazy" />` : ''}
                        </button>
                    `;
                }).join('')}
            </div>
        `;
    },

    bindProductColorSelectors() {
        document.querySelectorAll('[data-color-selector] button[data-color]').forEach(btn => {
            btn.addEventListener('click', (e) => this.handleProductColorClick(e, btn));
        });
    },

    handleProductColorClick(e, btn) {
        const parent = btn.closest('[data-color-selector]');
        if (!parent) return;
        const card = btn.closest('[data-product-card]');
        if (!card) return;

        // Actualizar estado visual
        parent.querySelectorAll('[data-color]').forEach(b => {
            b.setAttribute('aria-pressed', 'false');
            b.classList.remove('border-burgundy', 'border-2', 'ring-2', 'ring-burgundy/30');
            b.classList.add('border-ink/20', 'hover:border-ink/50');
        });
        btn.setAttribute('aria-pressed', 'true');
        btn.classList.add('border-burgundy', 'border-2', 'ring-2', 'ring-burgundy/30');
        btn.classList.remove('border-ink/20', 'hover:border-ink/50');

        // Cambiar imagen principal
        const img = card.querySelector('[data-product-image]');
        if (img) {
            const newUrl = btn.getAttribute('data-image');
            if (newUrl) {
                img.style.opacity = '0';
                setTimeout(() => {
                    img.src = newUrl;
                    img.style.opacity = '1';
                }, 180);
            }
        }

        // Actualizar nombre del color
        const nameEl = card.querySelector('[data-color-name]');
        if (nameEl) {
            nameEl.textContent = btn.getAttribute('data-color') || '';
        }

        // Actualizar link de WhatsApp
        this.updateWhatsAppLink(card);
    },

    bindProductSizeSelectors() {
        document.querySelectorAll('[data-talla]').forEach(el => {
            el.addEventListener('click', (e) => this.handleProductSizeClick(e, el));
        });
    },

    handleProductSizeClick(e, sizeEl) {
        const card = sizeEl.closest('[data-product-card]');
        if (!card) return;

        card.querySelectorAll('[data-talla]').forEach(t => {
            t.classList.remove('border-burgundy', 'text-burgundy', 'bg-burgundy/5');
        });
        sizeEl.classList.add('border-burgundy', 'text-burgundy', 'bg-burgundy/5');

        const marker = card.querySelector('[data-talla-selected]');
        if (marker) marker.textContent = sizeEl.textContent;

        this.updateWhatsAppLink(card);
    },

    bindWhatsAppButtons() {
        document.querySelectorAll('[data-whatsapp-link]').forEach(btn => {
            // Los botones ya tienen el href base, solo necesitamos asegurar que funcionen
        });
    },

    updateWhatsAppLink(card) {
        const wa = card.querySelector('[data-whatsapp-link]');
        if (!wa) return;

        const ruta = wa.getAttribute('href') || '';
        const textIdx = ruta.indexOf('text=');
        if (textIdx <= 0) return;

        const base = ruta.substring(0, textIdx);
        const producto = card.getAttribute('data-nombre') || '';
        const coleccion = card.getAttribute('data-coleccion') || '';
        const colorEl = card.querySelector('[data-color-name]');
        const color = colorEl ? colorEl.textContent : '';
        const tallaEl = card.querySelector('[data-talla-selected]');
        const talla = tallaEl ? tallaEl.textContent : '';

        const lines = ['Hola Abril Pijamas y Lencería, me interesa una prenda de su catálogo.'];
        if (producto) lines.push('Pieza: ' + producto);
        if (coleccion) lines.push('Colección: ' + coleccion);
        if (color) lines.push('Color: ' + color);
        if (talla) lines.push('Talla: ' + talla);
        lines.push('¿Está disponible? Gracias.');

        wa.setAttribute('href', base + 'text=' + encodeURIComponent(lines.join('\n')));
    },

    initRevealAnimations() {
        const obs = new IntersectionObserver((entries) => {
            entries.forEach(e => {
                if (e.isIntersecting) {
                    e.target.classList.add('is-visible');
                    obs.unobserve(e.target);
                }
            });
        }, { threshold: 0.12 });
        document.querySelectorAll('.reveal').forEach(el => obs.observe(el));
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

    showError(message) {
        if (this.elements.grid) {
            this.elements.grid.innerHTML = `
                <div class="col-span-full text-center py-16 text-ink/60">
                    <p>${this.escapeHtml(message)}</p>
                </div>
            `;
        }
    }
};

// Auto-inicializar cuando el DOM esté listo
document.addEventListener('DOMContentLoaded', () => {
    // Solo inicializar si estamos en la página de catálogo
    if (document.querySelector('[data-products-grid]')) {
        Catalogo.init().catch(console.error);
    }
});

// Exportar para uso global
window.Catalogo = Catalogo;