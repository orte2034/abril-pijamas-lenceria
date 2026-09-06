# Credenciales de Acceso - Abril Catálogo

**⚠️ CONFIDENCIAL - NO COMMITEAR AL REPOSITORIO**
**Entregar por canal seguro (1Password, Bitwarden, email encriptado, presencial)**

---

## Supabase Project

| Campo | Valor |
|-------|-------|
| **Project URL** | `https://XXXXXXXXXX.supabase.co` |
| **Project ID** | `xxxxxxxxxx` |
| **Región** | South America (São Paulo) |
| **Plan** | Free / Pro |

---

## API Keys (Settings > API)

| Key | Valor | Uso |
|-----|-------|-----|
| **ANON PUBLIC** | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` | Frontend público (catalog.js, product-detail.js, admin.html) |
| **SERVICE ROLE** | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` | **SOLO BACKEND/SCRIPTS** - NUNCA en frontend |

> **IMPORTANTE**: La `ANON PUBLIC` es segura para usar en navegador gracias a RLS. La `SERVICE ROLE` bypasa RLS - solo usar en scripts de migración, backend, CI/CD.

---

## Configuración en Archivos

### `public/js/supabase-client.js`
```javascript
const SUPABASE_URL = 'https://XXXXXXXXXX.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'; // ANON PUBLIC
```

### `admin.html` (al final, antes de </script>)
```javascript
const ADMIN_SUPABASE_URL = 'https://XXXXXXXXXX.supabase.co';
const ADMIN_SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'; // ANON PUBLIC (misma)
```

---

## Variables de Entorno Hosting

### Netlify / Vercel / Cloudflare Pages
```
SUPABASE_URL = https://XXXXXXXXXX.supabase.co
SUPABASE_ANON_KEY = eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## Usuario Administrador (Supabase Auth)

| Campo | Valor |
|-------|-------|
| **Email** | `admin@abril.com` (o email del cliente) |
| **Password** | `[Generada segura - mínimo 12 chars]` |
| **Confirmado** | Sí / No (verificar en Auth > Users) |

**Acceso Admin Panel**: `https://tudominio.com/admin.html`

---

## Storage

| Bucket | Nombre | Público |
|--------|--------|---------|
| Imágenes productos | `producto-imagenes` | **Sí** |

**URLs públicas ejemplo**:
```
https://XXXXXXXXXX.supabase.co/storage/v1/object/public/producto-imagenes/{product_id}/imagen.jpg
```

---

## Base de Datos

### Conexión Directa (Solo si necesario - psql, DBeaver, etc.)
```
Host: db.XXXXXXXXXX.supabase.co
Puerto: 5432
Database: postgres
Usuario: postgres
Password: [Password de BD generada al crear proyecto]
SSL: Require
```

> **Nota**: Preferir siempre Supabase Dashboard (Table Editor, SQL Editor) o SDK. Conexión directa solo para migraciones complejas.

---

## Dashboard Supabase

| Sección | URL |
|---------|-----|
| **Dashboard General** | `https://supabase.com/dashboard/project/XXXXXXXXXX` |
| **Table Editor** | `https://supabase.com/dashboard/project/XXXXXXXXXX/editor` |
| **SQL Editor** | `https://supabase.com/dashboard/project/XXXXXXXXXX/sql` |
| **Authentication** | `https://supabase.com/dashboard/project/XXXXXXXXXX/auth/users` |
| **Storage** | `https://supabase.com/dashboard/project/XXXXXXXXXX/storage/buckets` |
| **Logs** | `https://supabase.com/dashboard/project/XXXXXXXXXX/logs` |
| **Settings > API** | `https://supabase.com/dashboard/project/XXXXXXXXXX/settings/api` |

---

## Hosting (Producción)

| Proveedor | URL Dashboard | Sitio Live |
|-----------|---------------|------------|
| Netlify | `https://app.netlify.com/sites/xxxx` | `https://abril-catalogo.netlify.app` |
| Vercel | `https://vercel.com/xxxx` | `https://abril-catalogo.vercel.app` |
| Cloudflare Pages | `https://dash.cloudflare.com/xxxx` | `https://abril-catalogo.pages.dev` |

**Dominio Personalizado**: `https://abrilpijamasylenceria.com` (o el del cliente)

---

## Checklist de Entrega Segura

- [ ] Credenciales enviadas por canal seguro
- [ ] Cliente confirma recepción
- [ ] Usuario admin creado y probado
- [ ] Variables de entorno configuradas en hosting
- [ ] Dominio personalizado apuntando y SSL activo
- [ ] Backup de credenciales en password manager del cliente
- [ ] Documentación `docs/` entregada completa

---

## Rotación de Credenciales (Recomendado Anualmente)

1. **Supabase**: Settings > API > "Regenerate" ANON KEY
2. **Actualizar** en hosting + archivos JS
3. **Redesplegar** (deploy nuevo)
4. **Verificar** funcionamiento completo

---

**Fecha de generación**: Septiembre 2026
**Generado por**: [Tu Nombre/Empresa]
**Versión proyecto**: 1.0.0