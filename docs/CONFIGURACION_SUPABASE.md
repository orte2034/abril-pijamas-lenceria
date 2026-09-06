# Configuración de Supabase - Abril Catálogo

## 1. Crear Cuenta y Proyecto Gratuito

### 1.1 Registro
1. Ir a [supabase.com](https://supabase.com) → **Start your project**
2. **Sign up** con GitHub (recomendado) o Email
3. Confirmar email si es necesario

### 1.2 Crear Proyecto
1. Dashboard → **New Project**
2. **Organization**: Personal o crear una para el cliente
3. **Name**: `abril-catalogo` (o nombre cliente)
4. **Database Password**: Generar segura (guardar en password manager)
   - Mín 16 chars, mayúsculas, números, símbolos
   - **¡Esta password NO se usa en el código!** Solo para conexiones directas psql/DBeaver
5. **Region**: **South America (São Paulo)** - más cercano a Colombia
6. **Pricing Plan**: **Free** (suficiente para inicio)
   - 500 MB DB, 1 GB Storage, 2 GB bandwidth/mes
7. Click **Create new project** (tarda ~2 minutos)

---

## 2. Ejecutar Schema SQL

### 2.1 Abrir SQL Editor
1. Sidebar izquierdo → **SQL Editor** (icono `</>`)
2. Click **New query**

### 2.2 Copiar y Ejecutar Schema Completo

```sql
-- ============================================================
-- SCHEMA ABRIL CATÁLOGO - Ejecutar completo en SQL Editor
-- ============================================================

-- 1. Extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Tabla principal: productos
CREATE TABLE public.productos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    titulo VARCHAR(255) NOT NULL,
    precio INTEGER NOT NULL DEFAULT 0,
    imagenes TEXT[] NOT NULL DEFAULT '{}',           -- Array URLs imágenes principales
    tallas TEXT[] NOT NULL DEFAULT '{"XS","S","M","L","XL"}',
    especificaciones JSONB,                           -- JSON flexible: material, cuidado, etc.
    categoria VARCHAR(50) NOT NULL DEFAULT 'pijamas', -- pijamas | lenceria | conjuntos
    subtipo VARCHAR(50),                              -- babydoll | bodys | clasica | null
    coleccion VARCHAR(100) DEFAULT 'Colección 2026',
    destacado BOOLEAN DEFAULT FALSE,                  -- Para mostrar en Home
    descripcion_es TEXT DEFAULT '',
    descripcion_en TEXT DEFAULT '',
    colores JSONB NOT NULL DEFAULT '[]'::JSONB,       -- [{nombre, hex, imagen}, ...]
    fecha_creacion TIMESTAMPTZ DEFAULT NOW(),
    fecha_actualizacion TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Índices para performance
CREATE INDEX idx_productos_categoria ON public.productos(categoria);
CREATE INDEX idx_productos_destacado ON public.productos(destacado);
CREATE INDEX idx_productos_fecha_creacion ON public.productos(fecha_creacion DESC);

-- 4. Row Level Security (RLS) - HABILITAR
ALTER TABLE public.productos ENABLE ROW LEVEL SECURITY;

-- 5. Políticas de Seguridad
-- Lectura PÚBLICA (catálogo web)
CREATE POLICY "Productos visibles para todos" ON public.productos
    FOR SELECT USING (TRUE);

-- Escritura SOLO AUTENTICADOS (admins panel)
CREATE POLICY "Admins pueden insertar" ON public.productos
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Admins pueden actualizar" ON public.productos
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Admins pueden eliminar" ON public.productos
    FOR DELETE USING (auth.role() = 'authenticated');

-- 6. Trigger para actualizar fecha_actualizacion automáticamente
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.fecha_actualizacion = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_productos_fecha_actualizacion
    BEFORE UPDATE ON public.productos
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- 7. Storage Bucket para imágenes (ejecutar DESPUÉS de crear bucket en UI)
-- Políticas se crean automáticamente al crear bucket "producto-imagenes" como público
-- Pero si necesitas hacerlo por SQL:
/*
INSERT INTO storage.buckets (id, name, public) VALUES ('producto-imagenes', 'producto-imagenes', true);
*/

-- Políticas Storage (ejecutar después de crear bucket):
CREATE POLICY "Imágenes públicas" ON storage.objects
    FOR SELECT USING (bucket_id = 'producto-imagenes');

CREATE POLICY "Admins suben imágenes" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'producto-imagenes' AND auth.role() = 'authenticated');

CREATE POLICY "Admins actualizan imágenes" ON storage.objects
    FOR UPDATE USING (bucket_id = 'producto-imagenes' AND auth.role() = 'authenticated');

CREATE POLICY "Admins eliminan imágenes" ON storage.objects
    FOR DELETE USING (bucket_id = 'producto-imagenes' AND auth.role() = 'authenticated');
```

3. Click **Run** (Ctrl+Enter) → Verificar: **Success. No rows returned**

### 2.3 Verificar Tabla Creada
1. Sidebar → **Table Editor** (icono tabla)
2. Debe aparecer tabla `productos` con columnas definidas
3. Click en `productos` → **RLS** → Debe estar **Enabled** con 4 políticas

---

## 3. Configurar Storage (Imágenes)

### 3.1 Crear Bucket
1. Sidebar → **Storage** (icono carpeta) → **Create bucket**
2. **Name**: `producto-imagenes`
3. **Public bucket**: **ON** (✅ Activado - crítico para imágenes públicas)
4. Click **Create bucket**

### 3.2 Verificar Políticas Storage
1. Click en bucket `producto-imagenes` → **Policies**
2. Deben existir 4 políticas (creadas por SQL o UI):
   - `Imágenes públicas` (SELECT, public)
   - `Admins suben imágenes` (INSERT, authenticated)
   - `Admins actualizan imágenes` (UPDATE, authenticated)
   - `Admins eliminan imágenes` (DELETE, authenticated)

> **Nota**: Si las políticas no aparecen, ejecutar el bloque SQL de políticas Storage (líneas 70-85 del schema).

---

## 4. Configurar Autenticación (Admin Panel)

### 4.1 Habilitar Email/Password
1. Sidebar → **Authentication** (icono usuario) → **Providers**
2. **Email**: Ya viene **Enabled** por defecto
3. Opcional: **Confirm email** → **OFF** para testing (en producción **ON**)
4. **Secure email change**: ON

### 4.2 Crear Usuario Administrador
1. **Authentication** → **Users** → **Add user** → **Invite user**
2. **Email**: `admin@tudominio.com` (email real del cliente)
3. **Password**: Generar segura (mín 12 chars) → **Copy** para entregarla
4. **Auto Confirm User**: **ON** (para que no necesite email confirmation)
5. Click **Invite user**

> **Resultado**: Usuario aparece en lista con ✅ **Confirmed**

### 4.3 Configurar Redirect URLs (Opcional pero recomendado)
1. **Authentication** → **URL Configuration**
2. **Site URL**: `https://tudominio.com` (dominio final)
3. **Redirect URLs**: 
   ```
   https://tudominio.com/admin.html
   http://localhost:3000/admin.html (para desarrollo local)
   ```

---

## 5. Obtener Credenciales para el Código

### 5.1 API Keys
1. **Settings** (⚙️) → **API**
2. Copiar:
   - **Project URL** → `https://xxxxxxxxxx.supabase.co`
   - **anon/public key** → `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` (larga, empieza con `eyJ`)

> **Estas son las ÚNICAS credenciales que van en el frontend**

### 5.2 Service Role Key (NO USAR EN FRONTEND)
- **service_role/secret key** → `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`
- **Solo para**: Scripts de migración, backend, CI/CD, Supabase CLI
- **Nunca** en `supabase-client.js`, `admin.html`, ni repo público

---

## 6. Pegar Credenciales en el Código

### 6.1 Archivo: `public/js/supabase-client.js`

```javascript
// Línea ~6 - REEMPLAZAR CON TUS CREDENCIALES
const SUPABASE_URL = 'https://TU-PROYECTO.supabase.co';
const SUPABASE_ANON_KEY = 'TU_ANON_KEY_AQUI';
```

### 6.2 Archivo: `admin.html` (al final, antes de `</script>`)

```javascript
// Buscar estas líneas (~línea 580)
const ADMIN_SUPABASE_URL = 'https://TU-PROYECTO.supabase.co';
const ADMIN_SUPABASE_ANON_KEY = 'TU_ANON_KEY_AQUI';
```

> **Usar EXACTAMENTE las mismas credenciales en ambos archivos**

---

## 7. Variables de Entorno en Hosting (Vercel/Netlify)

### 7.1 Vercel
1. Dashboard → Project → **Settings** → **Environment Variables**
2. Añadir:
   ```
   Name: SUPABASE_URL
   Value: https://xxxxxxxxxx.supabase.co
   Environments: Production, Preview, Development
   ```
   ```
   Name: SUPABASE_ANON_KEY
   Value: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   Environments: Production, Preview, Development
   ```

### 7.2 Netlify
1. Site Settings → **Environment Variables**
3. Add variable: `SUPABASE_URL` + `SUPABASE_ANON_KEY`

> **En desarrollo local**: Crear archivo `.env` en raíz (NO commitear):
> ```env
> SUPABASE_URL=https://xxxxxxxxxx.supabase.co
> SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
> ```

---

## 8. Verificación Completa

### 8.1 Checklist Supabase

| Ítem | Verificación |
|------|--------------|
| ✅ Proyecto creado | Dashboard muestra proyecto activo |
| ✅ Tabla `productos` | Table Editor → `productos` visible |
| ✅ RLS habilitado | Table Editor → RLS = Enabled |
| ✅ 4 Políticas RLS | Policies: SELECT public, INSERT/UPDATE/DELETE authenticated |
| ✅ Trigger fecha_actualizacion | Triggers listado en tabla |
| ✅ Bucket `producto-imagenes` | Storage → bucket existe, público |
| ✅ 4 Políticas Storage | Policies: SELECT public, INSERT/UPDATE/DELETE authenticated |
| ✅ Auth Email habilitado | Authentication → Providers → Email = Enabled |
| ✅ Usuario admin creado | Authentication → Users → admin@dominio.com confirmed |
| ✅ Credenciales copiadas | Project URL + anon key guardadas |

### 8.2 Test Rápido en Consola (Opcional)

```sql
-- En SQL Editor - Verificar insert manual
INSERT INTO public.productos (titulo, precio, categoria, imagenes, colores, tallas)
VALUES (
  'PRODUCTO TEST',
  25000,
  'pijamas',
  ARRAY['https://via.placeholder.com/400x500'],
  '[{"nombre":"Test","hex":"#cccccc","imagen":"https://via.placeholder.com/400x500"}]'::jsonb,
  ARRAY['S','M','L']
);

-- Verificar select público (sin auth)
SELECT * FROM public.productos;

-- Limpiar test
DELETE FROM public.productos WHERE titulo = 'PRODUCTO TEST';
```

---

## 9. Límites Plan Free (Referencia)

| Recurso | Límite | Capacidad Estimada |
|---------|--------|-------------------|
| **Database** | 500 MB | ~50,000 productos |
| **Storage** | 1 GB | ~20,000 imágenes (50 KB c/u optimizadas) |
| **Bandwidth** | 2 GB/mes | ~100,000 vistas catálogo/mes |
| **Auth Users** | Ilimitado | N/A |
| **API Requests** | Ilimitado | N/A |
| **Edge Functions** | No incluido | N/A |

> **Upgrade a Pro ($25/mes)** cuando: DB > 400 MB, Storage > 800 MB, necesitas Backups automáticos (PITR), o mayor bandwidth.

---

## 10. Troubleshooting Común

| Error | Causa | Solución |
|-------|-------|----------|
| `Failed to fetch` / CORS | URL/Key incorrectos o CORS no configurado | Verificar credenciales. Settings → API → CORS: añadir `https://tudominio.com` |
| `RLS policy violation` | Usuario no autenticado intentando escribir | Login en `/admin.html` primero. Verificar políticas RLS |
| `Bucket not found` | Bucket no creado o nombre distinto | Storage → crear `producto-imagenes` exacto |
| `Image upload fails` | Políticas Storage faltantes | Verificar 4 políticas en bucket |
| `Auth: Invalid credentials` | Usuario no existe o password incorrecto | Auth → Users → verificar email confirmed + reset password |
| `Slug not found` | Producto no existe en BD | Verificar tabla `productos` tiene datos |

---

## 11. Migración de Datos (Si vienes de Astro Content Collections)

### 11.1 Opción A: Script Node (Recomendado para >50 productos)

```javascript
// migrate.mjs - Ejecutar: node migrate.mjs
import { createClient } from '@supabase/supabase-js';
import fs from 'fs';
import path from 'path';
import matter from 'gray-matter';

const supabase = createClient(
  'https://TU-PROYECTO.supabase.co',
  'TU_SERVICE_ROLE_KEY'  // ¡Service Role para bypassear RLS!
);

const productsDir = './src/content/products';
const files = fs.readdirSync(productsDir).filter(f => f.endsWith('.md'));

for (const file of files) {
  const content = fs.readFileSync(path.join(productsDir, file), 'utf-8');
  const { data } = matter(content);
  
  const { error } = await supabase.from('productos').insert({
    titulo: data.nombre,
    precio: data.precio,
    categoria: data.categoria,
    subtipo: data.subtipo || null,
    coleccion: data.coleccion || 'Colección 2026',
    destacado: data.destacado || false,
    descripcion_es: data.descripcion_es || '',
    descripcion_en: data.descripcion_en || '',
    colores: data.colores,
    tallas: data.tallas || ['XS','S','M','L','XL'],
    imagenes: data.colores.map(c => c.imagen)
  });
  
  if (error) console.error(file, error);
  else console.log('✅', data.nombre);
}
```

### 11.2 Opción B: Manual via Admin Panel (Recomendado <50 productos)
1. Login en `/admin.html`
2. **Nuevo** → Completar formulario → **Guardar**
3. Repetir por producto

### 11.3 Opción C: SQL Inserts Directos
```sql
-- En SQL Editor - Para pocos productos
INSERT INTO productos (titulo, precio, categoria, subtipo, coleccion, destacado, descripcion_es, colores, tallas, imagenes)
VALUES 
('CONJUNTO NIEVE', 24000, 'lenceria', 'clasica', 'Colección 2026', false,
 'Descripción...',
 '[{"nombre":"Color 1","hex":"#cccccc","imagen":"https://..."}]'::jsonb,
 '["XS","S","M","L","XL"]',
 ARRAY['https://...']);
```

---

## 12. Mantenimiento Periódico

| Frecuencia | Acción |
|------------|--------|
| **Semanal** | Exportar CSV productos (Table Editor → Export) |
| **Mensual** | Revisar uso Storage / Bandwidth en Dashboard |
| **Trimestral** | Rotar `ANON KEY` (Settings → API → Regenerate) + actualizar en hosting |
| **Anual** | Revisar plan Supabase (Free → Pro si necesario) |

---

**¡Supabase configurado y listo para producción! 🚀**