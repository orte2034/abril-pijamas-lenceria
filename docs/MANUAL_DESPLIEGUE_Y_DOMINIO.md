# Manual de Despliegue y Dominio - Abril Catálogo

## 1. Despliegue en Vercel (Recomendado)

### 1.1 Preparar Repositorio Git

```bash
# En la raíz del proyecto
git init
git add .
git commit -m "Initial commit: Abril Catálogo v1.0"
git branch -M main
git remote add origin https://github.com/TU_USUARIO/abril-catalogo.git
git push -u origin main
```

> **Importante**: El repositorio debe ser **público** o **privado con acceso a Vercel**. No subir archivos `.env` ni `docs/CREDENCIALES.md`.

### 1.2 Conectar con Vercel

1. Ir a [vercel.com](https://vercel.com) → "Add New Project"
2. **Import Git Repository** → Seleccionar tu repo `abril-catalogo`
3. Configuración automática detectada (Vercel detecta `vercel.json`):
   - **Framework Preset**: Other
   - **Build Command**: `npm run build` (o dejar vacío si solo HTML estático)
   - **Output Directory**: `public`
   - **Install Command**: `npm install` (opcional, solo si hay `package.json`)

4. **Environment Variables** (Settings → Environment Variables):
   ```
   SUPABASE_URL = https://xxxxxxxxxx.supabase.co
   SUPABASE_ANON_KEY = eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   ```
   - Añadir ambas como **Production**, **Preview**, **Development**

5. Click **Deploy** → Esperar build (1-2 min)

### 1.3 Verificar Despliegue

| URL | Debe funcionar |
|-----|----------------|
| `https://abril-catalogo.vercel.app` | Home |
| `https://abril-catalogo.vercel.app/catalogo` | Catálogo con productos |
| `https://abril-catalogo.vercel.app/producto/conjunto-nieve` | Detalle producto |
| `https://abril-catalogo.vercel.app/admin.html` | Login admin |

---

## 2. Configuración de Dominio Personalizado

### 2.1 En Vercel Dashboard

1. **Settings** → **Domains** → **Add**
2. Ingresar dominio: `abrilpijamasylenceria.com` (o el del cliente)
3. Vercel muestra registros DNS necesarios:

| Tipo | Nombre | Valor |
|------|--------|-------|
| **A** | `@` | `76.76.21.21` (IP Vercel) |
| **CNAME** | `www` | `cname.vercel-dns.com` |

### 2.2 En Proveedor DNS (Cloudflare, GoDaddy, Namecheap, etc.)

#### Opción A: Cloudflare (Recomendado)
1. DNS → **Add record**:
   - Type: `A`, Name: `@`, Content: `76.76.21.21`, Proxy: **ON** (naranja)
   - Type: `CNAME`, Name: `www`, Content: `cname.vercel-dns.com`, Proxy: **ON**
2. SSL/TLS → **Full (Strict)** (certificado automático)

#### Opción B: Otros proveedores
- Crear registros A + CNAME como arriba
- **Desactivar proxy/CDN** del proveedor si causa conflictos (solo DNS)

### 2.3 Verificar Dominio

1. En Vercel: Status cambiará a **"Valid Configuration"**
2. SSL: **"Automatic"** → Certificado Let's Encrypt válido
3. Probar: `https://abrilpijamasylenceria.com/catalogo`

> **Tiempo de propagación DNS**: 5 min - 24 hrs (usualmente < 10 min con Cloudflare)

---

## 3. Transferencia de Cuenta al Cliente

### 3.1 Opción A: Transferir Proyecto Vercel (Recomendado)

**Desde tu cuenta Vercel:**
1. Settings → **Transfer Project**
2. Email del cliente → **Send Transfer Request**
3. Cliente acepta email → Proyecto pasa a su cuenta Vercel
4. **Mantiene**: Dominio, variables de entorno, historial deploys, analytics

**Ventajas**: Cliente dueño total, facturación a su nombre, sin compartir credenciales.

### 3.2 Opción B: Transferir Repositorio Git + Nueva Cuenta Vercel

**GitHub/GitLab:**
1. Settings → **Transfer ownership** → Cuenta del cliente
2. Cliente clona repo en su máquina

**Vercel (cliente):**
1. Cliente crea cuenta en Vercel
2. Importa repo desde **su** cuenta GitHub
3. Configura **mismas** Environment Variables
4. Añade dominio personalizado (paso 2)

> **Tiempo estimado**: 15-30 min para cliente técnico

### 3.3 Opción C: Equipo Vercel (Si agencia maneja múltiples clientes)

1. Vercel → **Create Team** (Plan Pro $20/mes)
2. Invitar al cliente como **Member** (acceso deploys, logs, dominio)
3. Transferir proyecto al Team
4. Cliente puede ver/gestionar sin ser Owner

---

## 4. Configuración Post-Transferencia (Cliente)

### 4.1 Variables de Entorno en Vercel (Cliente)
Settings → Environment Variables → Verificar/Actualizar:
```
SUPABASE_URL = https://xxxxxxxxxx.supabase.co
SUPABASE_ANON_KEY = eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 4.2 Supabase (Cliente dueño)
- Proyecto Supabase **debe estar en cuenta del cliente** (no del dev)
- Si está en cuenta dev: Settings → **Transfer project** a organización del cliente
- Cliente gestiona: Usuarios admin, backups, plan, facturación

### 4.3 Credenciales a Entregar al Cliente

| Credencial | Dónde se usa | Formato entrega |
|------------|--------------|-----------------|
| Supabase URL + ANON KEY | Vercel Env Vars + `supabase-client.js` + `admin.html` | 1Password / Bitwarden / Email encriptado |
| Supabase Service Role | **Solo scripts backend** (nunca frontend) | Password manager |
| Supabase Dashboard URL | `https://supabase.com/dashboard/project/xxxxx` | Link directo |
| Vercel Dashboard URL | `https://vercel.com/xxx/abril-catalogo` | Link directo |
| Admin Panel URL | `https://tudominio.com/admin.html` | Link directo |
| Usuario Admin (email) | Login `/admin.html` | Definido en Supabase Auth |
| Password Admin | Login `/admin.html` | Definido al crear usuario |

> **NUNCA** commitear credenciales al repo. Usar gestor de contraseñas.

---

## 5. CI/CD Automático

### 5.1 Push to Deploy (Ya configurado)
- Cualquier `git push origin main` → Deploy automático en Vercel
- Preview deployments en PRs
- Rollback: Vercel Dashboard → Deployments → "Promote to Production"

### 5.2 Branch Protection (Recomendado)
GitHub Settings → Branches → Add rule:
- Branch: `main`
- ✅ Require pull request reviews
- ✅ Require status checks (Vercel deploy)
- ✅ Require linear history

---

## 6. Monitoreo y Alertas

### 6.1 Vercel Analytics (Gratis)
- Settings → Analytics → Enable
- Métricas: Visitas, Core Web Vitals, Top pages

### 6.2 Supabase Dashboard
- **Database**: CPU, conexiones, queries lentas
- **API**: Requests/min, latencia P95, errores 5xx
- **Storage**: Uso GB, bandwidth
- **Auth**: Usuarios activos, logins fallidos

### 6.3 Alertas Recomendadas (Supabase Pro+)
- CPU > 80% por 5 min
- API Errors > 1%
- Storage > 80% usado

---

## 7. Rollback y Recuperación

| Escenario | Acción |
|-----------|--------|
| **Bug en deploy** | Vercel → Deployments → "Promote to Production" en versión anterior |
| **Error código** | `git revert <commit>` → push → auto-deploy |
| **BD corrupta** | Supabase → Backups (Plan Pro+) → Point-in-time recovery |
| **Dominio caído** | Verificar DNS → SSL → Vercel Status page |

---

## 8. Checklist Final de Go-Live

- [ ] Repo en GitHub/GitLab (público o acceso Vercel)
- [ ] Vercel project conectado + deploy exitoso
- [ ] Environment variables configuradas (Production + Preview)
- [ ] Dominio personalizado apuntando + SSL válido
- [ ] Supabase project en cuenta del cliente
- [ ] Storage bucket `producto-imagenes` público + políticas RLS
- [ ] Usuario admin creado en Supabase Auth + probado login
- [ ] Catálogo público carga productos + filtros
- [ ] Detalle producto navega + WhatsApp funciona
- [ ] Admin CRUD completo (crear/editar/eliminar/imágenes)
- [ ] Credenciales entregadas por canal seguro
- [ ] Cliente capacitado (ver `MANUAL_ADMIN_CLIENTE.md`)
- [ ] Documentación `docs/` completa en repo

---

**¡Despliegue completado y transferido al cliente! 🎉**