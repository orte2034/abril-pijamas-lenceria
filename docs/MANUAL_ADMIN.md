# Manual de Usuario - Panel de Administración Abril Catálogo

**Versión 1.0** | Para el equipo de Abril Pijamas y Lencería

---

## Acceso al Panel

1. Abrir navegador e ir a: `https://tudominio.com/admin.html`
2. Ingresar **correo** y **contraseña** proporcionados
3. Click **"Iniciar sesión"**

> **Nota**: Si olvidaste la contraseña, contacta al administrador técnico para resetearla desde Supabase Dashboard.

---

## Pantalla Principal: Dashboard

Al entrar verás un resumen rápido:

| Métrica | Qué significa |
|---------|---------------|
| **Total Productos** | Cantidad de productos publicados en el catálogo |
| **Destacados** | Productos que aparecen en la página de inicio |
| **Última actualización** | Fecha del producto más reciente |

**Accesos rápidos**:
- **Productos** → Ver listado completo
- **Nuevo** → Crear producto desde cero

---

## Gestión de Productos

### Ver Listado (Pestaña "Productos")

**Tabla con columnas**:
- **Imagen**: Miniatura de la foto principal
- **Producto**: Nombre + categoría/subtipo
- **Categoría**: Badge de color (Pijamas/Conjuntos/Lencería)
- **Precio**: En COP
- **Destacado**: Sí/No (badge verde/gris)
- **Creado**: Fecha de creación
- **Acciones**: Editar | Ver imágenes | Eliminar

**Filtros disponibles**:
- 🔍 **Buscar**: Escribe parte del nombre
- 📂 **Categoría**: Filtrar por Pijamas / Lencería / Conjuntos
- ⭐ **Destacado**: Solo destacados / No destacados / Todos

**Paginación**: 20 productos por página. Usa botones Anterior/Siguiente o números.

---

### Crear Nuevo Producto

Click en **"Nuevo producto"** (botón burdeos + icono +) o pestaña **"Nuevo"**.

#### 1. Información Básica
| Campo | Obligatorio | Descripción |
|-------|-------------|-------------|
| **Título** | ✅ Sí | Nombre visible (ej: "CONJUNTO NIEVE") |
| **Categoría** | ✅ Sí | Pijamas / Lencería / Conjuntos |
| **Subtipo** | No | Babydoll, Bodys, Clásica (solo Lencería) |
| **Colección** | No | "Colección 2026" por defecto |
| **Precio (COP)** | ✅ Sí | Solo números, sin puntos ni $ (ej: 24000) |
| **Destacado** | No | Marcar para que salga en Home |

#### 2. Imágenes del Producto
- **Arrastrar y soltar** o click en zona punteada
- **Máximo 10 imágenes**, **5 MB cada una**
- Formatos: JPG, PNG, WebP, GIF
- **La primera imagen = imagen principal** del catálogo
- Preview visible al instante
- Click **✕** en miniatura para eliminar antes de guardar

#### 3. Colores y Variantes
**Al menos UN color es obligatorio**.

Por cada color:
- **Nombre**: Ej: "Negro", "Beige", "Floral Rojo"
- **HEX**: Código color (click en cuadro para selector visual) - opcional
- **Imagen**: **Obligatoria**. Subir foto específica de ese color

> **Tip**: Si el producto es de un solo color, pon nombre "Único" y sube la misma imagen principal.

Botón **"Añadir color"** para más variantes.

#### 4. Tallas Disponibles
- Por defecto: XS, S, M, L, XL, XXL, Única
- Click en **✕** para quitar tallas que no aplican
- **Añadir talla personalizada**: Escribe (ej: "36", "42", "Talla única") + Enter o botón "Añadir"

#### 5. Especificaciones (JSON)
Información técnica para ficha de producto. Formato JSON:
```json
{
  "material": "Algodón 100% / Encaje",
  "cuidado": "Lavar a mano, secar a la sombra",
  "composicion": "95% Algodón, 5% Elastano"
}
```
> **Si no sabes JSON**: Déjalo vacío o copia el ejemplo y edita los valores.

#### 6. Descripciones
- **Español**: Texto completo para web
- **English**: Opcional, para futuro multi-idioma

#### 7. Guardar
- **"Guardar producto"** (nuevo) / **"Actualizar producto"** (editando)
- Esperar confirmación "Producto creado/actualizado correctamente"
- Redirige automáticamente al listado

---

### Editar Producto Existente

1. En listado, click **📝 Editar** en fila del producto
2. Formulario se precarga con todos los datos
3. Modificar lo necesario
4. **Imágenes**: Las existentes se muestran abajo. Puedes eliminar (✕) o añadir nuevas
4. **Guardar cambios**

> **Importante**: Al editar, las imágenes **existentes se conservan** salvo que las elimines con ✕. Las nuevas se añaden.

---

### Eliminar Producto

1. Click **🗑 Eliminar** en fila del producto
2. Modal de confirmación: "¿Estás seguro de eliminar [NOMBRE]?"
3. Click **"Eliminar"** (botón rojo) para confirmar
4. **Se elimina**: Producto + imágenes de Storage + base de datos
5. **No hay deshacer** → Usar con cuidado

---

### Ver Galería de Imágenes

Click **🖼 Imágenes** en fila del producto → Modal con todas las fotos en grande. Click fuera o ✕ para cerrar.

---

## Flujo de Trabajo Recomendado

### Para Colección Nueva
1. **Preparar fotos**: Carpeta con imágenes optimizadas (max 500KB c/u, 1200px ancho)
2. **Crear productos base**: Uno a uno con info completa
3. **Marcar 4-8 como "Destacado"** para Home
4. **Revisar en catálogo público** (`/catalogo`)
5. **Probar WhatsApp** desde ficha de producto

### Para Actualizar Precios
1. Filtrar por categoría en listado
2. Editar cada producto → cambiar precio → guardar
3. Cambios **inmediatos** en web pública

### Para Cambiar Imagen Principal
1. Editar producto
2. Eliminar imagen principal actual (✕ en previews)
3. Subir nueva primera → se convierte en principal
4. Guardar

---

## Atajos y Tips

| Acción | Atajo / Tip |
|--------|-------------|
| Navegar tabs | Click en Dashboard / Productos / Nuevo |
| Enter en inputs | Salta al siguiente campo (Tab) |
| Selector color HEX | Click en cuadro color → paleta visual |
| Eliminar múltiples imágenes | Click ✕ en cada preview antes de guardar |
| Copiar producto similar | Editar → cambiar título/imágenes → "Guardar" (crea nuevo si borras ID) |

---

## Preguntas Frecuentes (FAQ)

### ❓ "No me deja guardar, dice 'Todos los colores deben tener imagen'"
→ Cada color añadido **requiere** su propia imagen. Sube una foto por color o elimina colores vacíos.

### ❓ "Subí imágenes pero no se ven en la web"
→ Verifica que el producto se **guardó correctamente** (toast verde). Las imágenes se suben a Supabase Storage al guardar.

### ❓ "Quiero que un producto salga primero en el catálogo"
→ El orden es **por fecha de creación (más nuevo primero)**. Para reordenar: edita y vuelve a guardar (actualiza fecha), o pide soporte técnico para añadir campo "orden".

### ❓ "El botón WhatsApp no abre el chat"
→ Verifica que el número en `site.ts` / `admin.js` sea correcto: `573169064533` (formato internacional sin +).

### ❓ "Error 'JSON inválido' en Especificaciones"
→ El JSON debe tener comillas dobles en claves y strings. Ejemplo válido:
```json
{"clave": "valor", "otra": 123}
```
Inválido: `{clave: 'valor'}` (comillas simples) o `{clave: valor}` (sin comillas).

### ❓ "No puedo hacer login en /admin.html"
→ 1. Verifica usuario existe en Supabase Auth
→ 2. Verifica email confirmado (revisa spam)
→ 3. Pide reset de contraseña al admin técnico

---

## Contacto Soporte Técnico

| Canal | Uso |
|-------|-----|
| **WhatsApp Dev** | Urgencias: caídas, errores críticos |
| **Email** | Dudas de uso, mejoras, bugs no urgentes |
| **Repositorio** | Issues técnicos (solo equipo dev) |

**Horario soporte**: Lunes a Viernes 9:00 - 18:00 (GMT-5 Colombia)

---

## Glosario Rápido

| Término | Significado |
|---------|-------------|
| **CRUD** | Create, Read, Update, Delete (Crear, Leer, Actualizar, Eliminar) |
| **RLS** | Row Level Security - seguridad a nivel fila en BD |
| **Storage** | Almacenamiento de archivos (imágenes) en Supabase |
| **Slug** | URL amigable generada del título (ej: "conjunto-nieve") |
| **HEX** | Código de color web (#RRGGBB) |
| **JSON** | Formato de datos estructurado clave-valor |
| **Toast** | Notificación temporal en esquina inferior derecha |
| **Modal** | Ventana emergente centrada (confirmaciones, galerías) |

---

**¡Listo! Con esta guía puedes gestionar todo el catálogo de forma autónoma.** 🎀

*Última actualización: Septiembre 2026*