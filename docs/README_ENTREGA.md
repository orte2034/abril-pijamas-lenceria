# Abril Catálogo - Documentación de Entrega

## Resumen del Proyecto

Este proyecto convierte el catálogo estático de **Abril Pijamas y Lencería** (construido originalmente en Astro con content collections) en un **catálogo dinámico con Panel de Administración** usando **Supabase** como backend, manteniendo **100% la identidad visual** original.

### Tecnologías Utilizadas
- **Frontend**: HTML5, CSS3 (Tailwind CSS via CDN), JavaScript Vanilla (ES6+)
- **Backend**: Supabase (PostgreSQL + Auth + Storage)
- **SDK**: `@supabase/supabase-js@2` via CDN (sin bundlers)
- **Despliegue**: Cualquier hosting estático (Netlify, Vercel, Cloudflare Pages, GitHub Pages, etc.)

---

## Estructura de Archivos Entregados

```
abril-catalogo/
├── public/
│   ├── index.html              # Home (se mantiene igual, usa Astro build)
│   ├── catalogo.html           # Catálogo público (versión HTML estática + JS dinámico)
│   ├── producto/
│   │   └── [slug].html         # Detalle de producto (versión HTML estática + JS dinámico)
│   ├── js/
│   │   ├── supabase-client.js  # Cliente Supabase compartido (CDN)
│   │   ├── catalog.js          # Lógica catálogo público
│   │   ├── product-detail.js   # Lógica detalle producto
│   │   └── admin.js            # Lógica panel administración
│   └── styles/
│       └── global.css          # Estilos globales (Tailwind build)
├── admin.html                  # Panel de Administración (archivo independiente)
├── supabase-schema.sql         # Schema SQL para Supabase
├── docs/
│   ├── GUIA_DESPLIEGUE.md      # Guía paso a paso de despliegue
│   ├── MANUAL_ADMIN.md         # Manual de usuario para el cliente
│   ├── ARQUITECTURA.md         # Documentación técnica
│   └── CREDENCIALES.md         # Plantilla para credenciales (NO commit)
└── package.json                # Solo para desarrollo local (Astro)
```

---

## Características Implementadas

### 1. Catálogo Público Dinámico (`catalogo.html` + `catalog.js`)
- ✅ Carga productos desde Supabase en tiempo real
- ✅ Filtros funcionales: Categoría, Subtipo, Precio (slider), Color
- ✅ Deep linking via hash URL (`#cat=lenceria`)
- ✅ Animaciones `reveal` idénticas al original
- ✅ Selector de colores con cambio de imagen principal
- ✅ Selector de tallas con feedback visual
- ✅ Botón WhatsApp con datos contextuales (producto, color, talla, colección)
- ✅ Paginación infinita / carga completa
- ✅ Responsive idéntico al diseño original

### 2. Detalle de Producto (`producto/[slug].html` + `product-detail.js`)
- ✅ Galería de miniaturas con cambio de imagen principal
- ✅ Selector de colores completo
- ✅ Selector de tallas
- ✅ Descripción completa
- ✅ Botón WhatsApp contextual
- ✅ Productos relacionados (misma categoría)
- ✅ Schema.org Product JSON-LD para SEO
- ✅ Meta tags Open Graph / Twitter dinámicos

### 3. Panel de Administración (`admin.html` + `admin.js`)
- ✅ **Login seguro** con Supabase Auth (email/password)
- ✅ **Dashboard** con estadísticas (total, destacados, última actualización)
- ✅ **CRUD Productos completo**:
  - Crear nuevos productos
  - Editar productos existentes
  - Eliminar productos (con confirmación)
  - Ver galería de imágenes
- ✅ **Gestión de imágenes**:
  - Drag & drop múltiple (máx 10, 5MB cada una)
  - Subida directa a Supabase Storage
  - Vista previa y eliminación
  - Imágenes por color/variante
- ✅ **Campos de producto**:
  - Título, Categoría, Subtipo, Colección, Precio
  - Destacado (checkbox para home)
  - Colores ilimitados (nombre, HEX, imagen)
  - Tallas personalizables
  - Especificaciones JSON
  - Descripciones ES/EN
- ✅ **UX profesional**:
  - Toast notifications
  - Modales para confirmaciones
  - Validaciones en cliente
  - Loading states
  - Paginación en listado
  - Búsqueda y filtros en listado

---

## Requisitos Previos

1. **Cuenta en Supabase** (gratis: https://supabase.com)
2. **Proyecto Supabase creado**
3. **Hosting estático** (Netlify, Vercel, Cloudflare Pages, etc.)
4. **Dominio propio** (opcional, recomendado)

---

## Variables de Entorno Requeridas

Crear archivo `.env` local o configurar en hosting:

```env
# Supabase (obtener en Settings > API)
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_ANON_KEY=tu-anon-key-aqui

# Solo para admin (misma ANON_KEY funciona con RLS)
ADMIN_SUPABASE_URL=https://tu-proyecto.supabase.co
ADMIN_SUPABASE_ANON_KEY=tu-anon-key-aqui
```

**⚠️ IMPORTANTE**: La `ANON_KEY` es segura para uso en frontend gracias a RLS (Row Level Security).

---

## Pasos de Despliegue Rápido

### 1. Configurar Supabase
```bash
# 1. Ir a SQL Editor en Supabase Dashboard
# 2. Ejecutar contenido de supabase-schema.sql
# 3. Ir a Storage > Crear bucket "producto-imagenes" (Público: Sí)
# 4. Ir a Authentication > Providers > Email > Habilitar
# 5. Crear usuario admin en Authentication > Users > Invite user
```

### 2. Configurar Variables
Editar `public/js/supabase-client.js` y `admin.html`:
```javascript
const SUPABASE_URL = 'https://TU-PROYECTO.supabase.co';
const SUPABASE_ANON_KEY = 'TU_ANON_KEY_AQUI';
```

### 3. Desplegar
**Opción A: Netlify (recomendado)**
```bash
# Conectar repo a Netlify
# Build command: npm run build (si usas Astro) / Ninguno (si solo HTML)
# Publish directory: public
# Environment variables: SUPABASE_URL, SUPABASE_ANON_KEY
```

**Opción B: Vercel**
```bash
# vercel --prod
# Configurar variables de entorno en dashboard
```

**Opción C: Cloudflare Pages**
```bash
# Conectar repo
# Build: npm run build / Output: public
```

### 4. Verificar
- ✅ Catálogo público carga productos
- ✅ Filtros funcionan
- ✅ Detalle producto navega correctamente
- ✅ Admin login funciona
- ✅ CRUD completo funciona
- ✅ Imágenes se suben a Storage

---

## Credenciales de Acceso Admin

| Campo | Valor |
|-------|-------|
| URL Admin | `https://tudominio.com/admin.html` |
| Email | El creado en Supabase Auth |
| Password | Definido al crear usuario |

**Nota**: Solo usuarios en `auth.users` pueden acceder. No hay registro público.

---

## Migración de Datos Existentes

Si tienes productos en el Astro `src/content/products/`:

1. **Opción A: Script de migración** (recomendado)
   ```javascript
   // Ejecutar en consola del navegador en página de catálogo Astro
   // Genera JSON para importar manualmente o via script
   ```

2. **Opción B: Manual via Admin Panel**
   - Entrar a `/admin.html`
   - Crear productos uno a uno (recomendado para < 50 productos)

3. **Opción C: SQL directo**
   - Usar `INSERT` statements en SQL Editor

---

## Mantenimiento y Soporte

### Backups
- Supabase incluye backups automáticos (Plan Pro+)
- Para Plan Free: exportar CSV desde Table Editor periódicamente

### Actualizaciones
- Solo reemplazar archivos en `public/` y `admin.html`
- No requiere rebuild ni deploy de funciones

### Logs y Debugging
- Console del navegador (F12)
- Supabase Dashboard > Logs > API / Auth / Storage
- Network tab para ver requests a Supabase

---

## Limitaciones Conocidas

1. **Slugs**: Se generan client-side desde el título. Para URLs canónicas fijas, añadir campo `slug` único en BD.
2. **Búsqueda full-text**: Filtro actual es `ilike` básico. Para búsqueda avanzada, añadir `pg_trgm` o Meilisearch.
3. **Multi-idioma**: i18n básico hardcodeado en JS. Para CMS completo, añadir tabla `translations`.
4. **Órdenes/ventas**: No incluido. Solo catálogo + WhatsApp lead generation.

---

## Roadmap Futuro (Sugerido)

- [ ] Campo `slug` único en BD + redirect canónico
- [ ] Búsqueda full-text con pg_trgm
- [ ] Gestión de categorías/subtipos desde admin
- [ ] Ordenar productos (drag & drop)
- [ ] Variantes de precio por talla/color
- [ ] Stock/inventario básico
- [ ] Analytics simples (vistas por producto)
- [ ] Webhook WhatsApp Business API

---

## Contacto y Soporte

**Desarrollado por**: [Tu Nombre/Empresa]
**Fecha de entrega**: Septiembre 2026
**Versión**: 1.0.0

Para dudas técnicas revisar `docs/ARQUITECTURA.md` y `docs/GUIA_DESPLIEGUE.md`.