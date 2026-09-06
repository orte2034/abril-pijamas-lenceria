/**
 * Página de Detalle de Producto - Abril Pijamas y Lencería
 * Carga datos dinámicamente desde Supabase manteniendo la estructura HTML idéntica
 */

const ProductoDetalle = {
    product: null,
    relatedProducts: [],
    supabase: null,

    i18n: {
        'producto.breadcrumb': 'Inicio',
        'nav.catalogo': 'Catálogo',
        'producto.colores': 'Colores',
        'producto.tallas': 'Tallas',
        'producto.tallaConsultar': '¿No sabes tu talla?',
        'producto.tallaConsultarWA': 'Consultar por WhatsApp',
        'producto.relacionados': 'También te puede interesar',
        'categoria.pijamas': 'Pijamas',
        'categoria.lenceria': 'Lencería',
        'categoria.conjuntos': 'Conjuntos',
        'subtipo.clasica': 'Clásica',
        'subtipo.babydoll': 'Babydoll',
        'subtipo.bodys': 'Bodys'
    },

    async init() {
        await this.waitForSupabase();
        this.supabase = await window.AbrilSupabase.getClient();
        
        // Obtener slug de la URL
        const pathParts = window.location.pathname.split('/');
        const slug = pathParts[pathParts.length - 1];
        
        if (!slug || slug === 'producto') {
            this.showError('Producto no encontrado');
            return;
        }

        await this.loadProduct(slug);
        if (this.product) {
            this.renderProduct();
            await this.loadRelatedProducts();
            this.initInteractions();
            this.initRevealAnimations();
        }
    },

    async waitForSupabase() {
        let attempts = 0;
        while (!window.AbrilSupabase?.getClient && attempts < 50) {
            await new Promise(r => setTimeout(r, 100));
            attempts++;
        }
    },

    async loadProduct(slug) {
        try {
            // Buscar por slug (generado desde el título)
            // Como el slug se genera en el cliente, necesitamos buscar por título similar
            // O almacenar el slug en la BD. Por ahora, buscamos todos y filtramos.
            const { data, error } = await this.supabase
                .from('productos')
                .select('*')
                .order('fecha_creacion', { ascending: false });

            if (error) throw error;

            // Encontrar producto cuyo título genere el mismo slug
            const found = data.find(p => this.slugify(p.titulo) === slug);
            
            if (!found) {
                this.showError('Producto no encontrado');
                return;
            }

            this.product = this.transformProduct(found);
            document.title = `${this.product.nombre} · Abril`;

        } catch (err) {
            console.error('Error cargando producto:', err);
            this.showError('Error al cargar el producto');
        }
    },

    transformProduct(p) {
        const colores = Array.isArray(p.colores) ? p.colores : 
                       (typeof p.colores === 'string' ? JSON.parse(p.colores) : []);
        const tallas = Array.isArray(p.tallas) ? p.tallas : 
                      (typeof p.tallas === 'string' ? p.tallas.split(',').map(t => t.trim()) : ['XS','S','M','L','XL']);
        const imagenes = Array.isArray(p.imagenes) ? p.imagenes : 
                        (typeof p.imagenes === 'string' ? JSON.parse(p.imagenes) : []);

        return {
            id: p.id,
            slug: this.slugify(p.titulo),
            nombre: p.titulo,
            categoria: p.categoria,
            subtipo: p.subtipo,
            coleccion: p.coleccion || 'Colección 2026',
            precio: p.precio,
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

    async loadRelatedProducts() {
        try {
            const { data, error } = await this.supabase
                .from('productos')
                .select('*')
                .eq('categoria', this.product.categoria)
                .neq('id', this.product.id)
                .order('fecha_creacion', { ascending: false })
                .limit(3);

            if (error) throw error;

            this.relatedProducts = data.map(p => this.transformProduct(p));
        } catch (err) {
            console.error('Error cargando productos relacionados:', err);
        }
    },

    renderProduct() {
        const p = this.product;
        const firstColor = p.colores[0];
        const coleccion = p.coleccion;

        // Actualizar meta tags
        this.updateMetaTags(p, firstColor);

        // Renderizar HTML principal (estructura idéntica al Astro original)
        const mainContent = document.querySelector('main');
        if (!mainContent) return;

        mainContent.innerHTML = `
            <article class="container-edit pt-12 pb-24" data-product-card data-nombre="${this.escapeHtml(p.nombre)}" data-coleccion="${this.escapeHtml(coleccion)}">
                <nav class="text-xs text-ink/50 mb-8">
                    <a href="/" class="hover:text-burgundy">${this.i18n['producto.breadcrumb']}</a>
                    <span class="mx-2">/</span>
                    <a href="/catalogo" class="hover:text-burgundy">${this.i18n['nav.catalogo']}</a>
                    <span class="mx-2">/</span>
                    <a href="/catalogo#cat=${p.categoria}" class="hover:text-burgundy capitalize">${this.i18n['categoria.' + p.categoria] || p.categoria}</a>
                    ${p.subtipo && p.subtipo !== 'clasica' ? `
                        <span class="mx-2">/</span>
                        <span class="capitalize">${this.i18n['subtipo.' + p.subtipo] || p.subtipo}</span>
                    ` : ''}
                    <span class="mx-2">/</span>
                    <span>${this.escapeHtml(p.nombre)}</span>
                </nav>

                <div class="grid lg:grid-cols-2 gap-12 lg:gap-20">
                    <div class="relative">
                        <div class="aspect-[3/4] overflow-hidden bg-creamwarm rounded-sm">
                            <img
                                data-product-image
                                src="${firstColor.imagen}"
                                alt="${this.escapeHtml(p.nombre)} ${this.escapeHtml(firstColor.nombre)}"
                                class="w-full h-full object-cover transition-opacity duration-300"
                            />
                        </div>
                        <span class="absolute top-4 left-4 eyebrow bg-crema/90 px-3 py-1.5">${this.escapeHtml(coleccion)}</span>
                        ${p.subtipo && p.subtipo !== 'clasica' ? `
                            <span class="absolute top-4 right-4 eyebrow bg-burgundy text-crema px-3 py-1.5 capitalize">${this.escapeHtml(p.subtipo)}</span>
                        ` : ''}

                        ${p.colores.length > 1 ? `
                            <div class="mt-4 grid grid-cols-4 gap-2">
                                ${p.colores.slice(0, 8).map(c => `
                                    <div class="aspect-square overflow-hidden rounded-sm bg-creamwarm">
                                        <img src="${this.escapeHtml(c.imagen)}" alt="${this.escapeHtml(c.nombre)}" class="w-full h-full object-cover thumbnail" loading="lazy" data-image-url="${this.escapeHtml(c.imagen)}" />
                                    </div>
                                `).join('')}
                            </div>
                        ` : ''}
                    </div>

                    <div class="lg:pt-4">
                        <p class="eyebrow">${this.escapeHtml(coleccion)}</p>
                        <h1 class="mt-3 font-serif text-4xl md:text-5xl text-ink leading-tight">${this.escapeHtml(p.nombre)}</h1>
                        <p class="mt-4 text-2xl text-burgundy">${this.formatCOP(p.precio)}</p>

                        ${p.colores.length > 1 ? `
                            <section class="mt-10">
                                <p class="eyebrow mb-3">${this.i18n['producto.colores']} <span class="text-ink/40 normal-case tracking-normal">· ${p.colores.length} opciones</span></p>
                                ${this.renderColorSelector(p.colores, firstColor.nombre, `pd-${p.slug}`)}
                                <p class="mt-2 text-sm text-ink/70" data-color-name>${this.escapeHtml(firstColor.nombre)}</p>
                            </section>
                        ` : ''}

                        <section class="mt-10">
                            <p class="eyebrow mb-3">${this.i18n['producto.tallas']}</p>
                            ${this.renderSizeSelector(p.nombre, p.tallas)}
                        </section>

                        ${p.descripcion_es ? `
                            <section class="mt-10 text-lead text-ink/80 italic font-body">
                                ${this.escapeHtml(p.descripcion_es)}
                            </section>
                        ` : ''}

                        <div class="mt-10">
                            ${this.renderWhatsAppButton(p.nombre, coleccion, firstColor.nombre)}
                        </div>

                        <span class="hidden" data-talla-selected></span>
                    </div>
                </div>

                ${this.relatedProducts.length > 0 ? `
                    <section class="mt-32 pt-16 border-t border-ink/10">
                        <h2 class="font-serif text-3xl text-ink mb-10">${this.i18n['producto.relacionados']}</h2>
                        <div class="grid grid-cols-2 lg:grid-cols-3 gap-x-6 gap-y-12">
                            ${this.relatedProducts.map(rp => this.renderRelatedProductCard(rp)).join('')}
                        </div>
                    </section>
                ` : ''}
            </article>
        `;
    },

    updateMetaTags(p, firstColor) {
        // Actualizar og:image
        const ogImage = document.querySelector('meta[property="og:image"]');
        if (ogImage) ogImage.setAttribute('content', firstColor.imagen);
        
        // Actualizar twitter:image
        const twitterImage = document.querySelector('meta[name="twitter:image"]');
        if (twitterImage) twitterImage.setAttribute('content', firstColor.imagen);

        // Actualizar description
        const desc = document.querySelector('meta[name="description"]');
        if (desc) desc.setAttribute('content', p.descripcion_es.slice(0, 160));
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

    renderSizeSelector(nombre, tallas) {
        const waLink = this.buildTallasWhatsAppLink(nombre);
        return `
            <div>
                <div class="flex flex-wrap gap-3">
                    ${tallas.map(talla => `
                        <span
                            class="inline-flex items-center justify-center min-w-[2.75rem] h-11 px-3 border border-ink/30 text-sm text-ink cursor-pointer hover:border-burgundy hover:text-burgundy transition"
                            data-talla="${this.escapeHtml(talla)}"
                        >
                            ${this.escapeHtml(talla)}
                        </span>
                    `).join('')}
                </div>
                <p class="mt-4 text-xs text-ink/60">
                    ${this.i18n['producto.tallaConsultar']}&nbsp;
                    <a
                        href="${waLink}"
                        target="_blank"
                        rel="noopener"
                        class="text-burgundy underline hover:no-underline font-medium"
                    >
                        ${this.i18n['producto.tallaConsultarWA']} →
                    </a>
                </p>
            </div>
        `;
    },

    renderWhatsAppButton(nombre, coleccion, color) {
        const lines = ['Hola Abril Pijamas y Lencería, me interesa una prenda de su catálogo.'];
        lines.push(`Pieza: ${nombre}`);
        lines.push(`Colección: ${coleccion}`);
        lines.push(`Color: ${color}`);
        lines.push('¿Está disponible? Gracias.');
        const text = encodeURIComponent(lines.join('\n'));
        const url = `https://wa.me/573169064533?text=${text}`;

        return `
            <a
                href="${url}"
                target="_blank"
                rel="noopener"
                class="inline-flex items-center justify-center w-full py-4 bg-burgundy text-crema text-sm tracking-wider uppercase hover:bg-burgundy-900 transition"
                data-whatsapp-link
            >
                <svg class="w-5 h-5 mr-2" fill="currentColor" viewBox="0 0 24 24"><path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.466-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.263.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421-7.403h-.004a9.87 9.87 0 00-5.031 1.378 9.86 9.86 0 00-1.735 5.247c0 .065.008.129.008.198 0 2.088 1.077 5.387 4.66 7.493a9.825 9.825 0 004.006 1.184c1.735-.008 3.428-.67 4.497-2.064.83-.1.168-.177.25-.372.074-.173.133-.348.149-.52.025-.766-.716-2.783-2.919-3.295-3.622a9.778 9.778 0 00-1.414-2.371c-.098-.124-.174-.223-.25-.297-.446-.446-.97-1.016-1.462-1.49zm-1.296 7.806c-1.147.446-2.492.741-3.57.741-.625 0-1.18-.041-1.67-.15-.497-.107-1.12-.446-1.543-.917-.447-.446-.718-1.016-.818-1.611-.099-.593-.133-1.213-.117-1.844.016-.579.15-1.127.446-1.592.297-.447.766-1.04 1.517-1.462.579-.314 1.127-.607 1.734-.883.607-.314 1.214-.57 1.844-.817.593-.243 1.213-.419 1.844-.447.579-.026 1.147.058 1.704.347.766.372 1.413 1.065 1.907 1.907.497.817.741 1.704.741 2.664 0 .942-.243 1.859-.741 2.635-.497.818-.94 1.517-1.592 2.162-.497.644-.967 1.213-1.462 1.684-.496.47-1.196.845-1.962 1.02zm-2.61-2.694c-.593-.297-1.333-.644-1.762-1.017a1.968 1.968 0 01-.545-1.413c-.099-.497-.026-1.017.149-1.44.199-.447.593-1.016 1.065-1.44.47-.447 1.12-.818 1.734-1.04.607-.243 1.24-.418 1.889-.497.644-.075 1.214.017 1.734.297.497.314.967.846 1.238 1.462.273.644.47 1.333.47 2.075 0 1.18-.47 2.11-1.238 2.71-.765.617-1.53 1.12-2.491 1.44-.858.272-1.804.447-2.815.447-.817 0-1.609-.108-2.351-.347z"/></svg>
                Consultar por WhatsApp
            </a>
        `;
    },

    renderRelatedProductCard(p) {
        const firstColor = p.colores[0];
        const coleccion = p.coleccion || 'Colección 2026';
        return `
            <article class="reveal group cursor-pointer" data-product-card data-slug="${p.slug}" data-nombre="${this.escapeHtml(p.nombre)}" data-coleccion="${this.escapeHtml(coleccion)}" data-categoria="${p.categoria}" data-subtipo="${p.subtipo || ''}">
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
                        ${p.subtipo && p.subtipo !== 'clasica' ? `
                            <div class="absolute top-3 right-3">
                                <span class="eyebrow bg-burgundy/90 text-crema px-2.5 py-1 capitalize">${this.escapeHtml(p.subtipo)}</span>
                            </div>
                        ` : ''}
                    </div>
                    <div class="mt-4 flex items-baseline justify-between">
                        <h3 class="font-serif text-lg text-ink">${this.escapeHtml(p.nombre)}</h3>
                        <span class="text-sm text-ink/70">${this.formatCOP(p.precio)}</span>
                    </div>
                    ${p.colores.length > 1 ? `
                        <p class="mt-1 text-xs text-ink/60">${p.colores.length} ${this.i18n['producto.colores'].toLowerCase()} · <span data-color-name>${this.escapeHtml(firstColor.nombre)}</span></p>
                        <div class="mt-3 [&>[data-color-selector]]:scale-90 [&>[data-color-selector]]:origin-left">
                            ${this.renderColorSelector(p.colores, firstColor.nombre, `card-related-${p.slug}`)}
                        </div>
                    ` : `
                        <p class="mt-1 text-xs text-ink/60 capitalize">${this.i18n['categoria.' + p.categoria] || p.categoria}${p.subtipo && p.subtipo !== 'clasica' ? ` · ${this.escapeHtml(p.subtipo)}` : ''}</p>
                    `}
                </a>
                <span class="hidden" data-talla-selected></span>
            </article>
        `;
    },

    initInteractions() {
        // Thumbnails gallery
        document.addEventListener('click', (e) => {
            const thumb = e.target.closest('.thumbnail');
            if (thumb) {
                const card = thumb.closest('[data-product-card]');
                const mainImg = card?.querySelector('[data-product-image]');
                const newUrl = thumb.getAttribute('data-image-url');
                if (mainImg && newUrl) {
                    mainImg.style.opacity = '0';
                    setTimeout(() => { mainImg.src = newUrl; mainImg.style.opacity = '1'; }, 180);
                }
            }
        });

        // Color selector en producto principal
        document.querySelectorAll('[data-color-selector] button[data-color]').forEach(btn => {
            btn.addEventListener('click', (e) => this.handleColorClick(e, btn));
        });

        // Size selector
        document.querySelectorAll('[data-talla]').forEach(el => {
            el.addEventListener('click', (e) => this.handleSizeClick(e, el));
        });
    },

    handleColorClick(e, btn) {
        const parent = btn.closest('[data-color-selector]');
        if (!parent) return;
        const card = btn.closest('[data-product-card]');
        if (!card) return;

        parent.querySelectorAll('[data-color]').forEach(b => {
            b.setAttribute('aria-pressed', 'false');
            b.classList.remove('border-burgundy', 'border-2', 'ring-2', 'ring-burgundy/30');
            b.classList.add('border-ink/20', 'hover:border-ink/50');
        });
        btn.setAttribute('aria-pressed', 'true');
        btn.classList.add('border-burgundy', 'border-2', 'ring-2', 'ring-burgundy/30');
        btn.classList.remove('border-ink/20', 'hover:border-ink/50');

        const img = card.querySelector('[data-product-image]');
        if (img) {
            const newUrl = btn.getAttribute('data-image');
            if (newUrl) {
                img.style.opacity = '0';
                setTimeout(() => { img.src = newUrl; img.style.opacity = '1'; }, 180);
            }
        }

        const nameEl = card.querySelector('[data-color-name]');
        if (nameEl) nameEl.textContent = btn.getAttribute('data-color') || '';

        this.updateWhatsAppLink(card);
    },

    handleSizeClick(e, sizeEl) {
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

    buildTallasWhatsAppLink(productName) {
        const text = encodeURIComponent(`Hola Abril Pijamas y Lencería, me gustaría consultar información de tallas y disponibilidad de: ${productName}. Gracias.`);
        return `https://wa.me/573169064533?text=${text}`;
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
        const mainContent = document.querySelector('main');
        if (mainContent) {
            mainContent.innerHTML = `
                <div class="container-edit pt-12 pb-24 text-center">
                    <h1 class="font-serif text-3xl text-ink mb-4">Producto no encontrado</h1>
                    <p class="text-ink/60 mb-8">${this.escapeHtml(message)}</p>
                    <a href="/catalogo" class="inline-flex items-center gap-3 px-8 py-4 bg-burgundy text-crema text-sm tracking-wider uppercase hover:bg-burgundy-900 transition">
                        Volver al catálogo
                    </a>
                </div>
            `;
        }
    }
};

// Auto-inicializar en página de producto
document.addEventListener('DOMContentLoaded', () => {
    if (window.location.pathname.startsWith('/producto/')) {
        ProductoDetalle.init().catch(console.error);
    }
});

window.ProductoDetalle = ProductoDetalle;