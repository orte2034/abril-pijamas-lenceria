# Documentación Técnica - Arquitectura Abril Catálogo

**Versión 1.0** | Documentación para desarrolladores

---

## Visión General

```
┌─────────────────────────────────────────────────────────────────┐
│                        ARQUITECTURA GENERAL                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌──────────────┐      ┌──────────────┐      ┌────────────┐   │
│   │   Navegador  │◄────►│  Hosting     │      │  Supabase  │   │
│   │   (Cliente)  │      │  Estático    │      │  (Backend) │   │
│   └──────┬───────┘      └──────┬───────┘      └─────┬──────┘   │
│          │                     │                     │          │
│    ┌─────┴─────┐         ┌─────┴─────┐         ┌────┴────┐     │
│    │ HTML/CSS  │         │  CDN      │         │  Postgres│     │
│    │ + JS      │         │  (Assets) │         │  + Auth  │     │
│    │ Vanilla   │         │           │         │  + Storage│    │
│    └───────────┘         └───────────┘         └─────────┘     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Principios de Diseño
1. **Zero Build Runtime**: Solo HTML/CSS/JS estáticos en producción
2. **CDN-First**: Supabase SDK via jsDelivr, Tailwind via CDN
3. **Visual Parity**: 100% idéntico al diseño Astro original
4. **Progressive Enhancement**: Funciona sin JS (SSR fallback futuro)
5. **Security by Default**: RLS en BD, Auth obligatorio para escrituras

---

## Stack Tecnológico

| Capa | Tecnología | Versión | Propósito |
|------|------------|---------|-----------|
| **Frontend** | HTML5 + CSS3 + ES6+ | Native | Estructura, estilos, lógica |
| **CSS Framework** | Tailwind CSS | 3.4 (CDN) | Utilidades, design system |
| **Fonts** | Google Fonts | Fraunces + Inter | Tipografía marca |
| **Backend** | Supabase | 2.x (CDN) | BaaS completo |
| **Database** | PostgreSQL | 15+ | Datos relacionales |
| **Auth** | Supabase Auth | GoTrue | Email/Password + JWT |
| **Storage** | Supabase Storage | S3-compatible | Imágenes productos |
| **Hosting** | Netlify/Vercel/CF Pages | - | Static hosting + CDN |

---

## Esquema de Base de Datos

### Tabla: `productos`

```sql
CREATE TABLE public.productos (
    id              UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    titulo          VARCHAR(255) NOT NULL,
    precio          INTEGER     NOT NULL DEFAULT 0,
    imagenes        TEXT[]      NOT NULL DEFAULT '{}',      -- URLs principales
    tallas          TEXT[]      NOT NULL DEFAULT '{"XS","S","M","L","XL"}',
    especificaciones JSONB,                                 -- Flexible specs
    categoria       VARCHAR(50) NOT NULL DEFAULT 'pijamas', -- pijamas|lenceria|conjuntos
    subtipo         VARCHAR(50),                            -- babydoll|bodys|clasica
    coleccion       VARCHAR(100) DEFAULT 'Colección 2026',
    destacado       BOOLEAN     DEFAULT FALSE,
    descripcion_es  TEXT        DEFAULT '',
    descripcion_en  TEXT        DEFAULT '',
    colores         JSONB       NOT NULL DEFAULT '[]'::JSONB, -- [{nombre,hex,imagen}]
    fecha_creacion  TIMESTAMPTZ DEFAULT NOW(),
    fecha_actualizacion TIMESTAMPTZ DEFAULT NOW()
);
```

### Índices
```sql
CREATE INDEX idx_productos_categoria ON productos(categoria);
CREATE INDEX idx_productos_destacado ON productos(destacado);
CREATE INDEX idx_productos_fecha_creacion ON productos(fecha_creacion DESC);
```

### Row Level Security (RLS)

| Política | Operación | Condición |
|----------|-----------|-----------|
| Public Read | SELECT | `TRUE` (todos) |
| Admin Insert | INSERT | `auth.role() = 'authenticated'` |
| Admin Update | UPDATE | `auth.role() = 'authenticated'` |
| Admin Delete | DELETE | `auth.role() = 'authenticated'` |

> **Clave**: `ANON_KEY` solo permite SELECT público. Escrituras requieren sesión autenticada.

### Storage Bucket: `producto-imagenes`

```
producto-imagenes/
├── {product_id}/
│   ├── {timestamp}-{random}-{filename}.jpg
│   └── ...
└── temp/ (para colores antes de crear producto)
```

**Políticas Storage**:
- SELECT: Public (imágenes accesibles vía CDN)
- INSERT/UPDATE/DELETE: `auth.role() = 'authenticated'`

---

## Estructura de Archivos Frontend

```
public/
├── index.html                 # Home (build Astro estático)
├── catalogo.html              # Catálogo público
├── producto/
│   └── [slug].html            # Detalle producto (build Astro estático)
├── admin.html                 # Panel admin (SPA)
├── js/
│   ├── supabase-client.js     # Cliente Supabase singleton (CDN)
│   ├── catalog.js             # Lógica catálogo + filtros
│   ├── product-detail.js      # Lógica detalle + galería + WhatsApp
│   └── admin.js               # Lógica admin completa (CRUD + Auth)
├── styles/
│   └── global.css             # Tailwind build + custom CSS
└── assets/                    # Imágenes estáticas (logo, etc.)
```

---

## Flujo de Datos

### 1. Catálogo Público (`catalogo.html`)

```
DOMContentLoaded
    │
    ▼
initSupabase() ──► window.AbrilSupabase.getClient()
    │
    ▼
Catalogo.loadProducts()
    │
    ├──► supabase.from('productos').select('*').order('fecha_creacion', desc)
    │
    ▼
transformProduct() ──► Normaliza a formato UI (slug, colores[], tallas[])
    │
    ▼
renderProducts() ──► Inyecta HTML idéntico a ProductCard.astro
    │
    ├──► bindProductColorSelectors()  (delegación eventos)
    ├──► bindProductSizeSelectors()
    ├──► bindWhatsAppButtons()
    │
    ▼
initFilters() ──► Event listeners: radio, checkbox, buttons, range
    │
    ▼
applyFilters() ──► Filtra en cliente (dataset attributes) → show/hide
    │
    ▼
IntersectionObserver ──► Animaciones .reveal
```

### 2. Detalle Producto (`producto/[slug].html`)

```
DOMContentLoaded
    │
    ▼
ProductoDetalle.init()
    │
    ├──► Extraer slug de URL (/producto/conjunto-nieve)
    │
    ▼
loadProduct(slug)
    │
    ├──► SELECT * FROM productos (filtro client-side por slug)
    │
    ▼
transformProduct()
    │
    ▼
renderProduct() ──► HTML idéntico a [slug].astro
    │
    ├──► updateMetaTags() (OG, Twitter, description)
    ├──► renderColorSelector()
    ├──► renderSizeSelector()
    ├──► renderWhatsAppButton()
    ├──► renderRelatedProducts() (categoría ≠ self, limit 3)
    │
    ▼
initInteractions()
    │
    ├──► Thumbnails gallery (click → swap main image)
    ├──► Color selector (sync main img + WhatsApp)
    ├──► Size selector (sync WhatsApp)
    │
    ▼
initRevealAnimations()
```

### 3. Panel Admin (`admin.html`)

```
DOMContentLoaded
    │
    ▼
AdminPanel.init()
    │
    ├──► cacheElements()
    ├──► bindEvents()
    ├──► initTallas() / initColorForm()
    │
    ▼
checkSession()
    │
    ├──► supabase.auth.getSession()
    │       │
    │       ├── Session válida ──► showAuthenticatedUI() → loadDashboard()
    │       │
    │       └── Sin sesión ──► showLoginUI()
    │
    ▼
supabase.auth.onAuthStateChange() ──► Reactivo a login/logout
```

#### Admin CRUD Flow

**CREATE**:
```
Form Submit
    │
    ├── validateForm() (título, categoria, precio, ≥1 color con imagen)
    │
    ▼
uploadImages() ──► supabase.storage.from('producto-imagenes').upload()
    │       │
    │       ▼ getPublicUrl() → array URLs
    │
    ▼
INSERT INTO productos {titulo, categoria, ..., imagenes[], colores[], tallas[]}
    │
    ▼
Toast success → closeForm() → loadProducts()
```

**READ (Listado)**:
```
loadProducts(page)
    │
    ├── Query con filtros (ilike, eq, range)
    │
    ▼
renderProductsTable() ──► HTML table rows con data-attributes
    │
    ▼
bindActions (edit/delete/images)
```

**UPDATE**:
```
openForm('edit', id)
    │
    ├── loadProductForEdit(id) ──► SELECT * WHERE id
    │
    ▼
Prefill form + renderExistingImages() + renderColores() + renderTallas()
    │
    ▼
Form Submit → uploadImages() → UPDATE productos SET ... WHERE id
```

**DELETE**:
```
showDeleteModal(id)
    │
    ├── confirmDelete()
    │       │
    │       ├── SELECT imagenes, colores para borrar Storage
    │       ├── DELETE FROM productos WHERE id
    │       ├── supabase.storage.remove(paths[])
    │       │
    │       ▼ Toast success → loadProducts()
    │
    ▼ hideDeleteModal()
```

---

## Seguridad

### Autenticación
- **Provider**: Email/Password (Supabase Auth)
- **Tokens**: JWT en localStorage (manejado por SDK)
- **Refresh**: Automático vía SDK
- **Logout**: `signOut()` + limpieza localStorage

### Autorización (RLS)
```sql
-- Solo autenticados pueden escribir
CREATE POLICY "Admin write" ON productos
  FOR ALL USING (auth.role() = 'authenticated');

-- Todos pueden leer
CREATE POLICY "Public read" ON productos
  FOR SELECT USING (TRUE);
```

### Validación Cliente + Servidor
| Validación | Cliente (JS) | Servidor (RLS/Constraints) |
|------------|--------------|----------------------------|
| Campos requeridos | ✅ | NOT NULL en BD |
| Tipos de datos | ✅ | CHECK constraints |
| Tamaño archivos | ✅ (5MB) | - |
| Tipos MIME | ✅ (image/*) | - |
| Propiedad datos | - | RLS por auth.uid() |

### Headers de Seguridad (Hosting)
```
Content-Security-Policy: default-src 'self'; script-src 'self' https://cdn.jsdelivr.net https://cdn.tailwindcss.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data: https://*.supabase.co; connect-src 'self' https://*.supabase.co;
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: camera=(), microphone=(), geolocation=()
```

---

## Rendimiento

### Métricas Objetivo
| Métrica | Objetivo | Estrategia |
|---------|----------|------------|
| **FCP** | < 1.5s | CSS crítico inline, fonts preconnect |
| **LCP** | < 2.5s | Imágenes WebP, lazy loading, CDN |
| **TTI** | < 3.5s | JS mínimo, code splitting manual |
| **CLS** | < 0.1 | Aspect-ratio en imágenes, font-display |

### Optimizaciones Implementadas
1. **Lazy Loading**: `loading="lazy"` en todas las imágenes
2. **Aspect Ratio**: `aspect-[3/4]` contenedores previenen CLS
3. **Image CDN**: Supabase Storage = CDN global automático
4. **Cache**: `Cache-Control: public, max-age=3600` en Storage
5. **Debounce**: Filtros 300ms, búsqueda 300ms
6. **Pagination**: 20 items/página en admin
7. **IntersectionObserver**: Animaciones solo al viewport

### Bundle Sizes (aprox)
| Archivo | Tamaño (gz) |
|---------|-------------|
| `supabase-client.js` | ~2 KB |
| `catalog.js` | ~8 KB |
| `product-detail.js` | ~10 KB |
| `admin.js` | ~25 KB |
| **Total JS** | **~45 KB gz** |
| Tailwind CSS (CDN) | ~15 KB gz (JIT) |
| Fuentes | ~40 KB (woff2) |

---

## Escalabilidad y Límites

### Supabase Free Tier
| Recurso | Límite | Capacidad Estimada |
|---------|--------|-------------------|
| Database | 500 MB | ~50,000 productos |
| Storage | 1 GB | ~20,000 imágenes (50 KB c/u) |
| Bandwidth | 2 GB/mes | ~100,000 vistas/mes |
| Auth Users | Ilimitado | N/A |
| API Requests | Ilimitado | N/A |

### Cuellos de Botella Futuros
1. **Filtros client-side**: Al crecer > 1000 productos, mover filtros a BD (RPC functions)
2. **Búsqueda**: `ilike` → Full-text search (`tsvector` + `pg_trgm`)
3. **Imágenes**: Añadir transformación on-the-fly (Supabase Image Transformation)
4. **Admin**: Paginación server-side ya implementada

---

## Testing

### Manual Checklist
- [ ] Catálogo carga sin errores JS
- [ ] Filtros combinados (cat + precio + color)
- [ ] Deep linking `#cat=lenceria`
- [ ] Detalle producto navega y carga datos
- [ ] Galería miniaturas swap
- [ ] WhatsApp link incluye color/talla/colección
- [ ] Admin login/logout
- [ ] CRUD completo (crear/editar/eliminar/ver)
- [ ] Subida imágenes múltiples
- [ ] Validaciones formulario
- [ ] Responsive 320px - 1920px
- [ ] Accesibilidad básica (alt, aria, focus)

### Automatizado (Futuro)
```bash
# Playwright E2E
npm test -- --project=chromium

# Lighthouse CI
npx lighthouse-ci autorun
```

---

## Debugging

### Console Logs Útiles
```javascript
// Ver cliente Supabase
window.AbrilSupabase.getClient()

// Ver estado catálogo
window.Catalogo.products.length
window.Catalogo.filters

// Ver estado admin
window.AdminPanel.products
window.AdminPanel.currentPage

// Forzar recarga catálogo
window.Catalogo.loadProducts()

// Ver sesión actual
supabase.auth.getSession()
```

### Network Tab
- Filtrar por `supabase.co`
- Verificar: `GET /rest/v1/productos` (200)
- Verificar: `POST /auth/v1/token?grant_type=password` (login)
- Verificar: `POST /storage/v1/object/producto-imagenes/...` (upload)

### Supabase Dashboard Logs
- **API Logs**: Requests REST, Auth, Realtime
- **Database Logs**: Queries lentas, errores
- **Storage Logs**: Uploads, downloads, errores

---

## Migración desde Astro (Referencia)

### Diferencias Clave
| Aspecto | Astro (Original) | Vanilla + Supabase (Nuevo) |
|---------|------------------|----------------------------|
| Rendering | Build-time (SSG) | Client-side (CSR) |
| Data Source | `src/content/` (MD) | Supabase PostgreSQL |
| Images | `/public/` local | Supabase Storage CDN |
| Auth | Ninguno | Supabase Auth |
| Admin | No existe | `admin.html` SPA |
| Deploy | Build → Static | Static + JS runtime |

### Compatibilidad Visual
- **HTML Structure**: Idéntica (mismos `data-attributes`, clases)
- **CSS Classes**: Idénticas (Tailwind mismo config)
- **Animations**: Mismo `IntersectionObserver` + `.reveal.is-visible`
- **Interactions**: Mismos event handlers (color, size, WhatsApp)

---

## Extensibilidad

### Añadir Campo Nuevo
1. **BD**: `ALTER TABLE productos ADD COLUMN nuevo_campo TIPO;`
2. **RLS**: Policy automática (hereda de tabla)
3. **Admin**: Añadir input en `admin.html` + manejar en `admin.js`
4. **Público**: Añadir render en `catalog.js` / `product-detail.js`
5. **Types**: Actualizar `transformProduct()`

### Añadir Tabla Relacionada (ej: `pedidos`)
```sql
CREATE TABLE pedidos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  producto_id UUID REFERENCES productos(id),
  cliente_nombre VARCHAR(255),
  cliente_whatsapp VARCHAR(20),
  color VARCHAR(100),
  talla VARCHAR(20),
  estado VARCHAR(50) DEFAULT 'nuevo',
  creado_en TIMESTAMPTZ DEFAULT NOW()
);
-- RLS: cliente ve solo sus pedidos, admin ve todos
```

### Webhooks (Futuro)
- **Nuevo pedido** → WhatsApp Business API / Email
- **Stock bajo** → Alerta admin
- **Sync externo** → ERP / Google Sheets

---

## Mantenimiento

### Tareas Periódicas
| Frecuencia | Tarea |
|------------|-------|
| **Diaria** | Verificar logs Supabase (errores 5xx) |
| **Semanal** | Backup CSV productos (Table Editor > Export) |
| **Mensual** | Revisar uso Storage / Bandwidth |
| **Trimestral** | Rotar `ANON_KEY` (Settings > API > Regenerate) |
| **Anual** | Revisar plan Supabase (upgrade si necesario) |

### Actualizaciones de Dependencias
- **Supabase SDK**: Verificar changelog @supabase/supabase-js
- **Tailwind**: CDN siempre latest (3.x), breaking changes raros
- **Fuentes**: Google Fonts estables

---

## Referencias

- [Supabase JS SDK Docs](https://supabase.com/docs/reference/javascript)
- [PostgreSQL JSONB Functions](https://www.postgresql.org/docs/current/functions-json.html)
- [Tailwind CSS CDN](https://tailwindcss.com/docs/installation/play-cdn)
- [RLS Best Practices](https://supabase.com/docs/guides/auth/row-level-security)
- [Storage Resumable Uploads](https://supabase.com/docs/guides/storage/uploads/resumable-uploads)

---

**Fin de documentación técnica**