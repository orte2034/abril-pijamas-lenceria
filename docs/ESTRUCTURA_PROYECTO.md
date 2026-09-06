# Estructura del Proyecto - Abril Catálogo

## Árbol de Directorios Completo

```
abril-catalogo/
├── .gitignore
├── .astro/                          # Cache interno de Astro (no versionar)
├── node_modules/                    # Dependencias npm (no versionar)
├── dist/                            # Build de producción Astro (legacy, no usar en prod nuevo)
├── public/                          # 🎯 CARPETA PRINCIPAL DE DESPLIEGUE
│   ├── _redirects                   # Redirects Netlify (SPA routing)
│   ├── catalogo.html                # Catálogo público (HTML estático + JS dinámico)
│   ├── producto.html                # Template único para /producto/:slug
│   ├── admin.html                   # Panel de Administración (SPA completa)
│   ├── logo.jpeg                    # Favicon + logo marca
│   ├── robots.txt                   # SEO robots
│   ├── js/                          # JavaScript Vanilla (ES6+ modules)
│   │   ├── supabase-client.js       # Cliente Supabase singleton (CDN)
│   │   ├── catalog.js               # Lógica catálogo: carga, filtros, render, WhatsApp
│   │   ├── product-detail.js        # Lógica detalle: galería, selectores, SEO, relacionados
│   │   └── admin.js                 # Lógica admin: Auth, CRUD, Storage, UI
│   └── styles/
│       └── global.css               # Tailwind build + custom CSS (opcional, CDN usado)
├── src/                             # Código fuente Astro (legacy - referencia)
│   ├── components/
│   │   ├── Header.astro
│   │   ├── Footer.astro
│   │   ├── ProductCard.astro
│   │   ├── ColorSelector.astro
│   │   ├── SizeSelector.astro
│   │   └── WhatsAppButton.astro
│   ├── layouts/
│   │   └── Base.astro
│   ├── pages/
│   │   ├── index.astro
│   │   ├── catalogo.astro
│   │   ├── contacto.astro
│   │   ├── 404.astro
│   │   └── producto/[slug].astro
│   ├── content/
│   │   ├── config.ts                # Schema Zod productos (legacy)
│   │   └── products/*.md            # 100+ productos en Markdown (legacy)
│   ├── i18n/
│   │   ├── index.ts                 # Helper t() + formatCOP()
│   │   ├── es.json
│   │   └── en.json
│   ├── data/
│   │   └── site.ts                  # Config marca + WhatsApp helpers
│   ├── styles/
│   │   └── global.css               # Tailwind @import + custom
│   └── env.d.ts
├── docs/                            # 📚 DOCUMENTACIÓN DE ENTREGA
│   ├── README.md
│   ├── MANUAL_DESPLIEGUE_Y_DOMINIO.md
│   ├── CONFIGURACION_SUPABASE.md
│   ├── MANUAL_ADMIN_CLIENTE.md
│   ├── CHECKLIST_ENTREGA.md
│   └── ESTRUCTURA_PROYECTO.md
├── supabase-schema.sql              # 🗄️ Schema BD completo (ejecutar en Supabase SQL Editor)
├── netlify.toml                     # Config Netlify (redirects, headers, env)
├── vercel.json                      # Config Vercel (rewrites, headers, framework)
├── package.json                     # Scripts Astro (dev, build, preview)
├── tsconfig.json                    # TypeScript config (Astro)
├── tailwind.config.mjs              # Config Tailwind (colores, fuentes, tamaños)
└── README.md                        # Este archivo (raíz)
```

---

## Descripción por Carpeta/Archivo Clave

### `/public` - **Lo que se despliega a producción**
| Archivo | Propósito | Tecnología |
|---------|-----------|------------|
| `catalogo.html` | Entry point catálogo. HTML semántico idéntico al original Astro, contenedores vacíos `data-products-grid`, `data-filter-*` | HTML5 + Tailwind CDN |
| `producto.html` | Template único para todas las URLs `/producto/:slug`. Lee slug de `window.location.pathname` | HTML5 + Tailwind CDN |
| `admin.html` | Panel admin SPA. Login, Dashboard, CRUD, modales, toasts. Todo en un archivo | HTML5 + Tailwind CDN |
| `js/supabase-client.js` | Inicializa `@supabase/supabase-js@2` vía CDN (jsDelivr). Exporta `window.AbrilSupabase` | ES6 Vanilla |
| `js/catalog.js` | Clase `Catalogo`: fetch productos, transform, render cards idénticas a `ProductCard.astro`, filtros client-side, deep-linking, IntersectionObserver | ES6 Vanilla |
| `js/product-detail.js` | Clase `ProductoDetalle`: fetch por slug, render detalle, galería thumbnails, selectores color/talla, WhatsApp contextual, JSON-LD, meta tags dinámicos | ES6 Vanilla |
| `js/admin.js` | Clase `AdminPanel`: Auth state, Dashboard stats, CRUD completo (create/read/update/delete), subida Storage drag&drop, gestión colores/tallas/especs, validaciones, modales, toasts, paginación | ES6 Vanilla |

### `/supabase-schema.sql` - **Base de Datos**
Ejecutar **una vez** en Supabase SQL Editor. Crea:
- Tabla `productos` con campos: `id, titulo, precio, imagenes[], tallas[], especificaciones(JSONB), categoria, subtipo, coleccion, destacado, descripcion_es/en, colores(JSONB), fecha_creacion, fecha_actualizacion`
- Índices: `categoria`, `destacado`, `fecha_creacion DESC`
- RLS: 4 políticas (SELECT public, INSERT/UPDATE/DELETE authenticated)
- Trigger `update_updated_at_column`
- Storage bucket `producto-imagenes` + 4 políticas (mediante UI + SQL)

### `/docs` - **Documentación de Entrega (6 archivos)**
| Archivo | Audiencia | Contenido |
|---------|-----------|-----------|
| `README.md` | Todos | Resumen proyecto, features, stack, arquitectura |
| `MANUAL_DESPLIEGUE_Y_DOMINIO.md` | DevOps / Cliente técnico | Vercel deploy, DNS, transferencia cuenta, CI/CD, rollback |
| `CONFIGURACION_SUPABASE.md` | Dev / Cliente técnico | Crear proyecto Free, SQL schema, Storage, Auth, credenciales, migración datos |
| `MANUAL_ADMIN_CLIENTE.md` | Cliente final (no técnico) | Guía visual paso a paso: login, crear/editar/eliminar productos, imágenes, colores, tallas, FAQ |
| `CHECKLIST_ENTREGA.md` | PM / QA / Cliente | 100+ checks: credenciales, infra, tests funcionales, perf, SEO, docs, capacitación, firmas |
| `ESTRUCTURA_PROYECTO.md` | Dev futuro | Este archivo: árbol, descripción, flujos, convenciones |

### Configuración de Despliegue
| Archivo | Plataforma | Qué configura |
|---------|------------|---------------|
| `vercel.json` | Vercel | Rewrites (`/catalogo`, `/producto/:slug`, `/admin`), Headers seguridad + cache, Framework: Astro |
| `netlify.toml` | Netlify | Redirects, Headers seguridad + cache, Env vars template |
| `public/_redirects` | Netlify (legacy) | Redirects simples para SPA routing |

### Código Legacy (`/src`) - Solo Referencia
El código en `src/` es el **proyecto Astro original** que generaba HTML estático en build time. Se mantiene como **referencia histórica** y para migración de datos. **No se usa en producción** con la nueva arquitectura Supabase + Vanilla JS.

---

## Flujos de Datos Principales

### 1. Catálogo Público (`catalogo.html` → `catalog.js`)
```
DOMContentLoaded
    │
    ▼
AbrilSupabase.getClient() ──► supabase.from('productos').select('*').order('fecha_creacion', desc)
    │
    ▼
transformProduct() ──► Normaliza: slug, colores[], tallas[], primera imagen
    │
    ▼
renderProducts() ──► Inyecta HTML idéntico a ProductCard.astro en [data-products-grid]
    │
    ├── bindProductColorSelectors()  (delegación click → swap imagen + WhatsApp)
    ├── bindProductSizeSelectors()   (click → marker + WhatsApp)
    ├── bindWhatsAppButtons()
    │
    ▼
initFilters() ──► Event listeners: radio(cat), checkbox(sub), buttons(color), range(precio)
    │
    ▼
applyFilters() ──► Filtra en cliente via dataset attributes → style.display = ''/none
    │
    ▼
IntersectionObserver ──► .reveal → .is-visible (animación fade-up)
```

### 2. Detalle Producto (`producto.html` → `product-detail.js`)
```
DOMContentLoaded
    │
    ▼
Extraer slug de pathname (/producto/conjunto-nieve → "conjunto-nieve")
    │
    ▼
SELECT * FROM productos (filtro client-side por slug generado)
    │
    ▼
transformProduct()
    │
    ▼
renderProduct() ──► HTML idéntico a [slug].astro + meta tags OG/Twitter + JSON-LD
    │
    ├── updateMetaTags() (og:image, og:title, description, twitter:card)
    ├── renderColorSelector() (igual que catálogo)
    ├── renderSizeSelector() (igual que catálogo)
    ├── renderWhatsAppButton() (contexto: producto, color, talla, colección)
    ├── renderRelatedProducts() (categoría ≠ self, limit 3)
    │
    ▼
initInteractions() ──► Thumbnails gallery + Color selector + Size selector (todos sync WhatsApp)
    │
    ▼
IntersectionObserver ──► Animaciones reveal
```

### 3. Panel Admin (`admin.html` → `admin.js`)
```
DOMContentLoaded
    │
    ▼
AdminPanel.init() → cacheElements() + bindEvents() + initTallas/ColorForm
    │
    ▼
checkSession() → supabase.auth.getSession()
    │       ├── Session OK → showAuthenticatedUI() → loadDashboard()
    │       └── Sin sesión → showLoginUI()
    │
    ▼
supabase.auth.onAuthStateChange() → Reactivo login/logout
```

**CRUD Flow:**
```
CREATE: Form Submit → validateForm() → uploadImages() → INSERT productos → Toast → closeForm → loadProducts()
READ:   loadProducts(page) → Query con filtros + range → renderProductsTable() + bindActions
UPDATE: openForm('edit', id) → loadProductForEdit() → Prefill + renderExistingImages/Colores/Tallas → Form Submit → uploadImages() → UPDATE productos
DELETE: showDeleteModal(id) → confirmDelete() → SELECT imagenes → DELETE productos → storage.remove() → Toast → loadProducts()
```

---

## Convenciones de Código

### JavaScript
- **ES6+**: `const`/`let`, arrow functions, destructuring, template literals, async/await
- **Clases**: Patrón Module/Class para cada feature (`Catalogo`, `ProductoDetalle`, `AdminPanel`)
- **Event Delegation**: Un listener en `document` para elementos dinámicos (color/talla/thumb)
- **Data Attributes**: Contrato HTML-JS via `data-*` (`data-product-card`, `data-color`, `data-talla`, `data-whatsapp-link`)
- **No dependencias externas** salvo Supabase SDK (CDN) y Tailwind (CDN)

### HTML/CSS
- **Tailwind CDN** con config idéntica a `tailwind.config.mjs` (colores, fuentes, tamaños)
- **Clases utilitarias** únicamente (sin CSS custom salvo variables `:root` y keyframes `fadeup`)
- **Estructura idéntica** al output Astro original (mismos `data-*`, mismas clases, mismo orden)
- **Accesibilidad**: `aria-label`, `aria-pressed`, `role`, `alt`, focus visible, semántica

### Supabase
- **ANON KEY** en frontend (seguro por RLS)
- **Service Role** solo scripts backend/CI
- **Storage paths**: `{product_id}/{timestamp}-{random}-{filename}`
- **JSONB** para `colores` y `especificaciones` (flexibilidad)
- **TEXT[]** para `imagenes` y `tallas` (arrays nativos PG)

---

## Puntos de Extensión Futura

| Feature | Dónde tocar | Esfuerzo |
|---------|-------------|----------|
| **Campo `slug` único en BD** | `supabase-schema.sql` + `transformProduct()` + `product-detail.js` | Bajo |
| **Búsqueda full-text (pg_trgm)** | SQL: `CREATE EXTENSION pg_trgm; CREATE INDEX...` + RPC function | Medio |
| **Orden manual (drag & drop)** | BD: `orden INT` + Admin: SortableJS + PATCH | Medio |
| **Stock por variante** | BD: tabla `variantes` (producto_id, color, talla, stock) + Admin UI | Alto |
| **Analytics eventos** | `catalog.js`/`product-detail.js` → `supabase.functions.invoke('track')` | Bajo |
| **Webhook WhatsApp Business** | Supabase Edge Function + Meta API | Medio |
| **Multi-idioma real** | BD: tabla `translations` + i18n dinámico | Alto |

---

## Dependencias Externas (CDN)

| Librería | Versión | URL | Propósito |
|----------|---------|-----|-----------|
| `@supabase/supabase-js` | 2.x | `https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/dist/umd/supabase.min.js` | Cliente BD + Auth + Storage |
| `tailwindcss` | 3.4 | `https://cdn.tailwindcss.com` | Utility-first CSS (JIT en navegador) |
| Google Fonts | - | `https://fonts.googleapis.com/css2?family=Fraunces...&family=Inter...` | Tipografía marca |

> **Sin `package.json` en producción**. Solo archivos estáticos en `public/`.

---

## Migración desde Astro (Legado)

| Aspecto | Astro (Original) | Vanilla + Supabase (Actual) |
|---------|------------------|----------------------------|
| **Rendering** | Build-time (SSG) | Client-side (CSR) |
| **Data Source** | `src/content/` (MD + frontmatter) | Supabase PostgreSQL |
| **Images** | `/public/` local (optimizadas en build) | Supabase Storage CDN |
| **Auth** | Ninguno | Supabase Auth (Email/Password) |
| **Admin** | No existe | `admin.html` SPA completo |
| **Deploy** | `npm run build` → `dist/` | `public/` + `admin.html` directo |
| **Visual Parity** | Referencia | **100% idéntico** (mismas clases, data-attrs, animaciones) |

---

**Fin de documentación de estructura**  
Para dudas técnicas ver `ARQUITECTURA.md` y `CONFIGURACION_SUPABASE.md`.