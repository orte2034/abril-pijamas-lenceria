# Guía de Despliegue - Abril Catálogo

Esta guía cubre el proceso completo desde cero hasta producción.

---

## 1. Crear Proyecto en Supabase

### 1.1 Registrarse y crear proyecto
1. Ir a https://supabase.com/dashboard
2. Click "New Project"
3. Organización: Personal o tu equipo
4. Nombre: `abril-catalogo` (o tu preferido)
5. Contraseña BD: Generar una segura (guardar en password manager)
6. Región: **South America (São Paulo)** - más cercano a Colombia
7. Plan: **Free** (suficiente para inicio)
8. Click "Create new project" (tarda ~2 min)

### 1.2 Obtener credenciales
1. En el dashboard del proyecto: Settings (⚙️) > API
2. Copiar:
   - **Project URL** → `SUPABASE_URL`
   - **anon/public key** → `SUPABASE_ANON_KEY`

---

## 2. Ejecutar Schema SQL

### 2.1 Abrir SQL Editor
1. En Supabase Dashboard: SQL Editor (icono `</>` en sidebar izquierdo)
2. Click "New query"

### 2.2 Ejecutar schema
1. Copiar **todo** el contenido de `supabase-schema.sql`
2. Pegar en el editor
3. Click "Run" (Ctrl+Enter)
4. Verificar: sin errores, tablas creadas en Table Editor

### 2.3 Verificar tablas
Ir a Table Editor (icono tabla), deberías ver:
- `productos` (tabla principal)
- Políticas RLS habilitadas

---

## 3. Configurar Storage

### 3.1 Crear Bucket
1. Storage (icono carpeta) > "Create bucket"
2. Nombre: `producto-imagenes`
3. **Public bucket: ON** (importante para que imágenes sean accesibles)
4. Click "Create bucket"

### 3.2 Verificar políticas
El schema SQL ya crea las políticas, pero verifica en Storage > Policies:
- SELECT: Public (todos pueden ver)
- INSERT/UPDATE/DELETE: Authenticated (solo admins)

---

## 4. Configurar Autenticación

### 4.1 Habilitar Email/Password
1. Authentication (icono usuario) > Providers
2. Email: **Enabled** (ya viene por defecto)
3. Opcional: Deshabilitar "Confirm email" para testing (en producción mantener ON)

### 4.2 Crear Usuario Admin
1. Authentication > Users > "Add user" > "Invite user"
2. Email: `admin@tudominio.com` (o el del cliente)
3. Password: Segura (mín 8 chars, mayúscula, número, símbolo)
4. Click "Invite"
5. El usuario recibirá email para confirmar (si confirm email está ON)
   - O ir a Authentication > Users > Click en usuario > "Send magic link" para login sin password

### 4.3 Configurar Redirect URLs (opcional)
Authentication > URL Configuration:
- Site URL: `https://tudominio.com`
- Redirect URLs: `https://tudominio.com/admin.html`

---

## 5. Configurar Archivos del Proyecto

### 5.1 Editar supabase-client.js
```javascript
// public/js/supabase-client.js
const SUPABASE_URL = 'https://TU-PROYECTO.supabase.co';
const SUPABASE_ANON_KEY = 'TU_ANON_KEY_AQUI';
```

### 5.2 Editar admin.html
Buscar al final del archivo (antes de `</script>`):
```javascript
const ADMIN_SUPABASE_URL = 'https://TU-PROYECTO.supabase.co';
const ADMIN_SUPABASE_ANON_KEY = 'TU_ANON_KEY_AQUI';
```

**⚠️ Usar las MISMAS credenciales en ambos archivos.**

---

## 6. Despliegue en Netlify (Recomendado)

### 6.1 Opción A: Git + Netlify (CI/CD automático)
1. Subir código a GitHub/GitLab/Bitbucket
2. En Netlify: "Add new site" > "Import from Git"
3. Conectar repo
3. Configurar:
   - **Build command**: `npm run build` (si usas Astro) / dejar vacío (solo HTML)
   - **Publish directory**: `public`
4. Environment variables (Site settings > Environment variables):
   ```
   SUPABASE_URL = https://tu-proyecto.supabase.co
   SUPABASE_ANON_KEY = tu-anon-key
   ```
5. Deploy!

### 6.2 Opción B: Drag & Drop (Manual)
1. En Netlify: "Add new site" > "Deploy manually"
2. Arrastrar carpeta `public/` completa
3. Configurar variables de entorno después en Site settings
4. Para admin.html: subir también a la raíz del deploy

### 6.3 Configurar Dominio Personalizado
1. Site settings > Domain management > "Add custom domain"
2. Seguir instrucciones DNS (CNAME a `tu-sitio.netlify.app`)
3. HTTPS automático

---

## 7. Despliegue en Vercel

### 7.1 Via CLI
```bash
npm i -g vercel
cd abril-catalogo
vercel
# Seguir prompts
# Build command: npm run build (Astro) / Skip
# Output directory: public
```

### 7.2 Via Dashboard
1. Importar repo en Vercel
2. Framework: Other / Astro
3. Build: `npm run build` / Output: `public`
4. Environment Variables: añadir `SUPABASE_URL` y `SUPABASE_ANON_KEY`
5. Deploy

### 7.3 Variables de entorno en Vercel
Settings > Environment Variables:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- (Opcional) `ADMIN_SUPABASE_URL`, `ADMIN_SUPABASE_ANON_KEY`

---

## 8. Despliegue en Cloudflare Pages

### 8.1 Via Dashboard
1. Cloudflare Dashboard > Pages > "Create a project"
2. Connect to Git
3. Build settings:
   - Build command: `npm run build` (Astro) / `echo 'static site'`
   - Build output directory: `public`
4. Environment variables (Settings > Environment variables):
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
5. Save and Deploy

---

## 9. Verificación Post-Despliegue

### 9.1 Checklist Público
- [ ] Home carga (`/`)
- [ ] Catálogo carga productos (`/catalogo`)
- [ ] Filtros funcionan (categoría, precio, color)
- [ ] Click en producto navega a detalle (`/producto/[slug]`)
- [ ] Detalle muestra imágenes, colores, tallas, descripción
- [ ] Botón WhatsApp abre chat con datos correctos
- [ ] Productos relacionados aparecen
- [ ] Meta tags OG/Twitter correctos (ver source)
- [ ] Responsive en móvil

### 9.2 Checklist Admin
- [ ] `/admin.html` carga login
- [ ] Login con credenciales Supabase funciona
- [ ] Dashboard muestra stats
- [ ] Tab "Productos" lista productos
- [ ] "Nuevo producto" abre formulario
- [ ] Crear producto con imágenes funciona
- [ ] Editar producto carga datos existentes
- [ ] Eliminar producto pide confirmación
- [ ] Imágenes se suben a Storage (ver en Supabase > Storage)
- [ ] Logout funciona

### 9.3 Verificar en Supabase Dashboard
- Table Editor > `productos`: datos correctos
- Storage > `producto-imagenes`: archivos subidos
- Authentication > Users: admin existe
- Logs > API: requests 200 OK

---

## 10. Configuración de Dominio y SSL

### 10.1 DNS (ejemplo Cloudflare)
| Tipo | Nombre | Contenido | Proxy |
|------|--------|-----------|-------|
| CNAME | @ | tu-sitio.netlify.app | Proxied |
| CNAME | www | tu-sitio.netlify.app | Proxied |

### 10.2 Headers de Seguridad (Netlify)
Crear `public/_headers`:
```
/*
  X-Frame-Options: DENY
  X-Content-Type-Options: nosniff
  Referrer-Policy: strict-origin-when-cross-origin
  Permissions-Policy: camera=(), microphone=(), geolocation=()
```

### 10.3 Redirects (Netlify)
Crear `public/_redirects`:
```
/admin.html    /admin.html    200
/producto/*    /producto/:slug    200
```

---

## 11. Migración de Datos (Opcional)

### 11.1 Desde Astro Content Collections
Si tienes productos en `src/content/products/*.md`:

```javascript
// Ejecutar en consola del navegador en localhost:4321/catalogo
// Genera array de objetos listos para insertar
const products = [];
document.querySelectorAll('[data-product-item]').forEach(el => {
  products.push({
    titulo: el.dataset.nombre,
    categoria: el.dataset.categoria,
    subtipo: el.dataset.subtipo || null,
    precio: parseInt(el.dataset.precio),
    // ... más campos
  });
});
console.log(JSON.stringify(products, null, 2));
```

### 11.2 Importar via SQL
```sql
-- En Supabase SQL Editor
INSERT INTO productos (titulo, categoria, subtipo, precio, colores, tallas, imagenes, descripcion_es, coleccion, destacado)
VALUES 
('CONJUNTO NIEVE', 'lenceria', 'clasica', 24000, 
 '[{"nombre":"Color 1","hex":"#cccccc","imagen":"https://..."}]'::jsonb,
 '["XS","S","M","L","XL"]',
 '["https://..."]',
 'Descripción...',
 'Colección 2026',
 false);
```

---

## 12. Rollback y Recovery

### 12.1 Rollback de Código
- Netlify/Vercel: Deploy previo en "Deploys" > "Publish deploy"
- Git: `git revert` + push

### 12.2 Recovery de BD
- Supabase Free: Point-in-time recovery NO disponible
- Exportar CSV regularmente: Table Editor > Export
- Plan Pro+: Backups automáticos + PITR

---

## 13. Monitoreo y Alertas

### 13.1 Supabase Dashboard
- **Database**: CPU, RAM, conexiones
- **API**: Requests, latencia, errores
- **Storage**: Uso, bandwidth
- **Auth**: Usuarios, logins

### 13.2 Alertas Recomendadas
- CPU > 80% por 5 min
- API errors > 1%
- Storage > 80% usado

---

## 14. Costos Estimados (Supabase Free Tier)

| Recurso | Límite Free | Estimado Abril |
|---------|-------------|----------------|
| Database | 500 MB | ~50 MB (1000 productos) |
| Storage | 1 GB | ~200 MB (imágenes optimizadas) |
| Bandwidth | 2 GB/mes | ~500 MB/mes |
| Auth users | Ilimitado | 1-5 admins |
| API requests | Ilimitado | ~10k/día |

**Total: $0/mes** dentro de límites Free.

---

## 15. Troubleshooting Común

### "Failed to fetch" en consola
- Verificar `SUPABASE_URL` y `ANON_KEY` correctos
- Verificar CORS en Supabase (Settings > API > CORS: añadir tu dominio)
- Verificar que no bloquea CSP

### Login admin no funciona
- Verificar usuario existe en Authentication > Users
- Verificar email confirmado (si "Confirm email" está ON)
- Verificar RLS policies en tabla `productos`

### Imágenes no suben
- Verificar bucket `producto-imagenes` existe y es público
- Verificar políticas Storage (INSERT para authenticated)
- Verificar tamaño < 5MB y tipo permitido

### Productos no aparecen en catálogo
- Verificar `SELECT * FROM productos` en SQL Editor
- Verificar RLS policy "Productos visibles para todos"
- Verificar consola JS por errores de red

---

## 16. Checklist Final de Entrega

- [ ] Supabase project creado y configurado
- [ ] Schema SQL ejecutado sin errores
- [ ] Storage bucket creado y público
- [ ] Usuario admin creado y probado
- [ ] Credenciales configuradas en `supabase-client.js` y `admin.html`
- [ ] Desplegado en hosting (Netlify/Vercel/CF Pages)
- [ ] Variables de entorno configuradas en hosting
- [ ] Dominio personalizado configurado
- [ ] SSL/HTTPS activo
- [ ] Checklist público OK
- [ ] Checklist admin OK
- [ ] Documentación entregada (`docs/`)
- [ ] Credenciales entregadas de forma segura (NO en repo)
- [ ] Cliente capacitado (ver `docs/MANUAL_ADMIN.md`)

---

**¡Despliegue completado! 🎉**