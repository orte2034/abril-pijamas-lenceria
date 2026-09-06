# Abril Catálogo - Documentación del Proyecto

## Resumen

**Abril Catálogo** es una solución completa de catálogo dinámico con panel de administración para **Abril Pijamas y Lencería**, marca colombiana de pijamas, lencería y conjuntos. El proyecto convierte un sitio estático (Astro + Content Collections) en una aplicación **100% dinámica** consumiendo datos desde **Supabase**, manteniendo **idéntica la identidad visual** original.

## Características Principales

### 🛍️ Catálogo Público (`/catalogo`)
- **Carga dinámica** de productos desde Supabase PostgreSQL
- **Filtros en tiempo real**: Categoría (Pijamas/Lencería/Conjuntos), Subtipo (Babydoll/Bodys/Clásica), Precio (slider), Color (botones visuales)
- **Deep linking** via hash URL (`#cat=lenceria&sub=bodys`)
- **Selectores interactivos**: Cambio de color con swap de imagen principal, selección de talla con feedback visual
- **WhatsApp contextual**: Botón que incluye producto, color, talla y colección en el mensaje
- **Animaciones reveal** idénticas al diseño original (IntersectionObserver)
- **Responsive** mobile-first (320px - 1920px)

### 📄 Detalle de Producto (`/producto/:slug`)
- Galería de miniaturas con swap de imagen principal
- Selectores de color y talla totalmente funcionales
- Descripción completa + especificaciones técnicas
- **Schema.org Product JSON-LD** para SEO
- Meta tags Open Graph / Twitter dinámicos
- Productos relacionados (misma categoría, excluyendo actual)

### 🔐 Panel de Administración (`/admin.html`)
- **Login seguro** con Supabase Auth (Email/Password + JWT)
- **Dashboard** con estadísticas: total productos, destacados, última actualización
- **CRUD completo** de productos:
  - Crear: Título, categoría, subtipo, colección, precio, destacado
  - **Imágenes**: Drag & drop múltiple (máx 10, 5MB c/u) → Subida directa a Supabase Storage
  - **Colores ilimitados**: Nombre, HEX (color picker), imagen obligatoria por variante
  - **Tallas personalizables**: Lista base + añadir tallas custom
  - **Especificaciones JSON**: Editor con validación
  - **Descripciones bilingües** (ES/EN)
  - Editar: Carga datos existentes, conserva imágenes salvo eliminación explícita
  - Eliminar: Confirmación modal + limpieza Storage
- **Paginación** (20 items/página) + Búsqueda + Filtros en listado
- **Toast notifications** + Modales de confirmación + Loading states
- **UX profesional**: Validaciones cliente, shortcuts, atajos de teclado

## Stack Técnico

| Capa | Tecnología | Detalle |
|------|------------|---------|
| **Frontend** | HTML5 + CSS3 + ES6+ | Vanilla JS, sin bundlers |
| **CSS Framework** | Tailwind CSS 3.4 | Via CDN (JIT mode), config idéntica al diseño original |
| **Tipografía** | Google Fonts | Fraunces (display) + Inter (body) |
| **Backend (BaaS)** | Supabase | PostgreSQL 15 + GoTrue Auth + S3 Storage |
| **SDK** | `@supabase/supabase-js@2` | Via CDN (jsDelivr) |
| **Hosting** | Vercel / Netlify / Cloudflare Pages | Static hosting + Edge CDN |
| **Dominio** | Personalizado | SSL automático, DNS gestionado |

## Arquitectura

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────┐
│  Navegador  │────▶│  Hosting Estático │     │  Supabase   │
│  (Cliente)  │     │  (Vercel/Netlify) │     │  (Backend)  │
└─────────────┘     └──────────────────┘     └──────┬──────┘
                                                    │
                              ┌─────────────────────┼─────────────────────┐
                              ▼                     ▼                     ▼
                        ┌──────────┐          ┌───────────┐          ┌──────────┐
                        │PostgreSQL│          │   Auth    │          │ Storage  │
                        │ productos│          │  (JWT)    │          │imágenes  │
                        └──────────┘          └───────────┘          └──────────┘
```

## Seguridad

- **RLS (Row Level Security)**: Lectura pública, escritura solo `authenticated`
- **ANON KEY** segura en frontend (políticas RLS protegen datos)
- **Service Role** solo para scripts backend/migraciones
- **Headers de seguridad**: CSP, X-Frame-Options, HSTS, etc.
- **Validación dual**: Cliente (UX) + Servidor (constraints + RLS)

## Rendimiento

- **JS Total**: ~45 KB gzipped (4 módulos pequeños)
- **Lazy loading** nativo en todas las imágenes
- **Aspect-ratio containers** previenen CLS
- **Supabase Storage CDN** global para imágenes
- **Debounce** en filtros/búsqueda (300ms)
- **Paginación server-side** en admin

---

**Versión**: 1.0.0  
**Fecha**: Septiembre 2026  
**Desarrollado para**: Abril Pijamas y Lencería