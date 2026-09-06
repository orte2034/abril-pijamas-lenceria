# Manual de Administración para el Cliente - Abril Catálogo

**Versión 1.0** | Guía paso a paso para gestionar tu catálogo sin conocimientos técnicos

---

## 🎯 Acceso al Panel

### 1. Entrar al Panel
1. Abre tu navegador (Chrome, Firefox, Safari, Edge)
2. Ve a: **`https://tudominio.com/admin.html`**
3. Verás la pantalla de login:

```
┌─────────────────────────────────────┐
│        Panel de Administración      │
│                                     │
│  Correo electrónico: [____________] │
│  Contraseña:        [____________]  │
│                                     │
│        [ Iniciar sesión ]           │
└─────────────────────────────────────┘
```

### 2. Credenciales
- **Correo**: El que te proporcionó el desarrollador (ej: `admin@abril.com`)
- **Contraseña**: La que definiste al crear tu usuario en Supabase

> **¿Olvidaste la contraseña?** Pide al desarrollador que la resetee desde Supabase Dashboard → Authentication → Users → tu usuario → "Send password reset email"

### 3. Primera Vez
- Si es tu primer login, el sistema te llevará directo al **Dashboard**
- Verás un resumen: Total productos, Destacados, Última actualización

---

## 📊 Dashboard - Vista Principal

```
┌────────────────────────────────────────────────────────────┐
│  Dashboard                                    [Productos] [Nuevo] │
├────────────────────────────────────────────────────────────┤
│  📦 Total Productos:    47                                 │
│  ⭐ Destacados:         8                                  │
│  📅 Última actualización: 15/09/2026                       │
├────────────────────────────────────────────────────────────┤
│  Productos Recientes                                    │
│  ┌─────────────────────┬──────────┬────────┬──────┬──────┐│
│  │ Producto            │ Categoría│ Precio │ Dest.│ Acc. ││
│  ├─────────────────────┼──────────┼────────┼──────┼──────┤│
│  │ CONJUNTO NIEVE      │ Lencería │ $24.000│  No  │ ✏️🖼️🗑️││
│  │ PIJAMA TRIO PANTALÓN│ Pijamas  │ $29.000│  Sí  │ ✏️🖼️🗑️││
│  └─────────────────────┴──────────┴────────┴──────┴──────┘│
└────────────────────────────────────────────────────────────┘
```

**Accesos rápidos:**
- **Productos** → Ver listado completo con filtros
- **Nuevo** → Crear producto desde cero

---

## 📦 Gestión de Productos

### Ver Listado Completo
Click en pestaña **Productos** (o enlace "Ver todos" en Dashboard)

**Filtros disponibles:**
- 🔍 **Buscar**: Escribe parte del nombre (ej: "nieve")
- 📂 **Categoría**: Todas / Pijamas / Lencería / Conjuntos
- ⭐ **Destacado**: Sí / No / Todos

**Tabla con acciones:**
| Columna | Qué muestra |
|---------|-------------|
| Imagen | Miniatura foto principal |
| Producto | Nombre + categoría/subtipo |
| Categoría | Badge color: 🟤 Pijamas / 🟣 Lencería / 🟢 Conjuntos |
| Precio | En pesos colombianos |
| Destacado | Badge verde (Sí) / gris (No) |
| Creado | Fecha de creación |
| Acciones | **✏️ Editar** | **🖼️ Ver imágenes** | **🗑️ Eliminar** |

**Paginación**: 20 productos por página. Botones: Anterior / 1, 2, 3... / Siguiente

---

## ➕ Crear Nuevo Producto

Click en **Nuevo** (botón burdeos +) o pestaña **Nuevo**

### Paso 1: Información Básica
```
┌─────────────────────────────────────────────────────────────┐
│  Información básica                                         │
├─────────────────────────────────────────────────────────────┤
│  Título *          [CONJUNTO NIEVE              ]           │
│  Categoría *       [Lencería ▼]  Subtipo [Clásica ▼]       │
│  Colección         [Colección 2026            ]            │
│  Precio (COP) *    [24000                  ]               │
│  ☐ Destacado en Home                                          │
└─────────────────────────────────────────────────────────────┘
```

| Campo | Obligatorio | Qué poner |
|-------|-------------|-----------|
| **Título** | ✅ Sí | Nombre visible en web (ej: "CONJUNTO NIEVE") |
| **Categoría** | ✅ Sí | Pijamas / Lencería / Conjuntos |
| **Subtipo** | Solo Lencería | Babydoll / Bodys / Clásica (dejar vacío = Clásica) |
| **Colección** | No | "Colección 2026" por defecto |
| **Precio** | ✅ Sí | Solo números, sin puntos ni $ (ej: `24000`) |
| **Destacado** | No | Marcar ✅ para que salga en página de Inicio |

---

### Paso 2: Imágenes del Producto
```
┌─────────────────────────────────────────────────────────────┐
│  Imágenes del producto                    [📁 Arrastrar]    │
│  ─────────────────────────────────────────────────────────  │
│  📎 Arrastra aquí o haz clic para seleccionar              │
│  Máx 10 imágenes • 5 MB cada una • JPG, PNG, WebP, GIF    │
├─────────────────────────────────────────────────────────────┤
│  [🖼️] [🖼️] [🖼️] [🖼️]  ← Miniaturas con ✕ para borrar    │
└─────────────────────────────────────────────────────────────┘
```

**Cómo hacerlo:**
1. **Arrastra** tus fotos desde la carpeta del computador al área punteada
2. O **clic** en el área → selecciona varias fotos a la vez (Ctrl+Click)
3. Verás **miniaturas** al instante
4. **La primera imagen = foto principal** en el catálogo
5. Para borrar: click **✕** en la miniatura (antes de guardar)

> **Tips:**
> - Usa fotos **cuadradas o verticales** (relación 3:4 ideal)
> - Peso recomendado: **< 500 KB** cada una
> - Ancho: **1200 px** mínimo
> - Nombra archivos sin espacios: `conjunto-nieve-1.jpg`

---

### Paso 3: Colores y Variantes (¡Al menos 1 obligatorio!)
```
┌─────────────────────────────────────────────────────────────┐
│  Colores y variantes              [+ Añadir color]         │
├─────────────────────────────────────────────────────────────┤
│  Color 1                                                          
│  Nombre: [Negro          ]  HEX: [#000000 ▼] [#000000]      
│  Imagen: [📁 Subir foto]  [🖼️ Ver]                             
│  ─────────────────────────────────────────────────────────  │
│  Color 2                                                          
│  Nombre: [Beige          ]  HEX: [#F5F0E1 ▼] [#F5F0E1]      
│  Imagen: [📁 Subir foto]  [🖼️ Ver]                             
└─────────────────────────────────────────────────────────────┘
```

**Por cada color:**
1. **Nombre**: Ej: "Negro", "Beige", "Floral Rojo", "Único"
2. **HEX** (opcional): Click en el cuadro ▼ → paleta de colores → elige tono
3. **Imagen** ✅ **OBLIGATORIA**: Click "Subir foto" → elige foto de ESE color
   - Si el producto es **un solo color**: Pon nombre "Único" y sube la misma foto principal

> **Botón "Añadir color"** → Agrega otra fila para más variantes

---

### Paso 4: Tallas Disponibles
```
┌─────────────────────────────────────────────────────────────┐
│  Tallas disponibles                                         │
├─────────────────────────────────────────────────────────────┤
│  [XS] [S] [M] [L] [XL] [XXL] [Única]  ← Click ✕ para quitar │
├─────────────────────────────────────────────────────────────┤
│  Añadir talla personalizada: [36        ] [Añadir]         │
└─────────────────────────────────────────────────────────────┘
```

- **Por defecto**: XS, S, M, L, XL, XXL, Única
- **Quitar**: Click **✕** en las que NO apliquen
- **Añadir personalizada**: Escribe (ej: "36", "42", "Talla única") → Enter o "Añadir"

---

### Paso 5: Especificaciones Técnicas (Opcional)
```
┌─────────────────────────────────────────────────────────────┐
│  Especificaciones (JSON)                                    │
├─────────────────────────────────────────────────────────────┤
│  {                                                          
│    "material": "Algodón 100% / Encaje",                    
│    "cuidado": "Lavar a mano, secar a la sombra",           
│    "composicion": "95% Algodón, 5% Elastano"               
│  }                                                          
└─────────────────────────────────────────────────────────────┘
```

**Si no sabes JSON**: Déjalo vacío o copia el ejemplo y cambia solo los textos entre comillas.

> **Formato válido**: Claves y textos entre comillas dobles `""`, números sin comillas.

---

### Paso 6: Descripciones
```
┌─────────────────────────────────────────────────────────────┐
│  Descripción (Español)          Descripción (English)       │
│  [                                                          ] │  [                                                          ]
│  [                                                          ] │  [                                                          ]
└─────────────────────────────────────────────────────────────┘
```

- **Español**: Texto completo para la web (lo ven tus clientes)
- **English**: Opcional, para futuro multi-idioma

---

### Paso 7: Guardar
```
┌─────────────────────────────────────────────────────────────┐
│                    [Cancelar]    [Guardar producto]         │
└─────────────────────────────────────────────────────────────┘
```

- Click **Guardar producto** (botón burdeos)
- Verás toast verde: **"Producto creado correctamente"**
- Redirige automáticamente al listado

---

## ✏️ Editar Producto Existente

1. En listado → Click **✏️ Editar** en la fila del producto
2. Formulario se carga **con todos los datos actuales**
3. **Modifica lo que necesites**
4. **Imágenes existentes**: Se muestran abajo con ✕ para borrar
5. **Nuevas imágenes**: Arrastra al área → se añaden a las existentes
6. Click **Actualizar producto**
7. Toast verde: **"Producto actualizado correctamente"**

> **Importante**: Al editar, las imágenes **se conservan** salvo que las borres con ✕. Las nuevas se **añaden**.

---

## 🗑️ Eliminar Producto

1. En listado → Click **🗑️ Eliminar** en la fila
2. **Modal de confirmación**:
```
┌─────────────────────────────────────┐
│  Eliminar producto                  │
├─────────────────────────────────────┤
│  ¿Estás seguro de eliminar          │
│  CONJUNTO NIEVE?                    │
│                                     │
│  Esta acción no se puede deshacer   │
│  y eliminará también las imágenes.  │
│                                     │
│  [Cancelar]      [Eliminar] 🔴      │
└─────────────────────────────────────┘
```
3. Click **Eliminar** (botón rojo)
4. Toast verde: **"Producto eliminado"**

> **⚠️ No hay deshacer**. Usa con cuidado.

---

## 🖼️ Ver Galería de Imágenes

1. En listado → Click **🖼️ Ver imágenes** en la fila
2. Modal con **todas las fotos en grande**
3. Click fuera o **✕** para cerrar

---

## 🎯 Flujo de Trabajo Recomendado

### Para Lanzar Colección Nueva
1. **Prepara fotos**: Carpeta con imágenes optimizadas (<500 KB, 1200px ancho)
2. **Crea productos base**: Uno a uno con info completa
3. **Marca 4-8 como "Destacado"** (checkbox) → Salen en Home
4. **Revisa en web pública**: `https://tudominio.com/catalogo`
5. **Prueba WhatsApp**: Desde ficha de producto → abre chat con datos correctos

### Para Actualizar Precios
1. Filtra por categoría en listado
2. **✏️ Editar** → cambiar precio → **Actualizar**
3. Cambios **inmediatos** en web pública

### Para Cambiar Foto Principal
1. **✏️ Editar** producto
2. **✕** en foto principal actual (miniaturas)
3. Arrastra **nueva primera** → se convierte en principal
4. **Actualizar**

---

## ⌨️ Atajos y Tips Rápidos

| Acción | Cómo hacerlo |
|--------|--------------|
| Navegar secciones | Click en **Dashboard / Productos / Nuevo** (arriba) |
| Saltar campos | **Tab** para siguiente, **Shift+Tab** anterior |
| Seleccionar color HEX | Click en cuadro ▼ → paleta visual |
| Borrar varias fotos | Click **✕** en cada miniatura antes de guardar |
| Duplicar producto similar | **✏️ Editar** → cambia título/fotos → **Guardar** (crea nuevo) |
| Ver producto en web | Click en nombre del producto en listado (se abre en nueva pestaña) |

---

## ❓ Preguntas Frecuentes (FAQ)

### "No me deja guardar, dice 'Todos los colores deben tener imagen'"
→ Cada color añadido **requiere** su propia foto. Sube una foto por color o **elimina** colores vacíos (click ✕ en fila del color).

### "Subí imágenes pero no se ven en la web"
→ Verifica que el producto se **guardó correctamente** (toast verde). Las imágenes se suben a la nube **al guardar**.

### "Quiero que un producto salga primero en el catálogo"
→ El orden es **por fecha: más nuevo primero**. Para reordenar: **✏️ Editar** → **Actualizar** (cambia fecha), o pide al desarrollador añadir campo "orden".

### "El botón WhatsApp no abre el chat"
→ Verifica que el número en la web sea correcto. Contacta al desarrollador si falla.

### "Error 'JSON inválido' en Especificaciones"
→ El JSON debe tener comillas **dobles** en claves y textos:
```json
✅ {"material": "Algodón", "cuidado": "Lavar en frío"}
❌ {material: 'Algodón'}  (comillas simples)
❌ {material: Algodón}    (sin comillas)
```

### "No puedo hacer login en /admin.html"
1. Verifica usuario existe (pide al dev revisar Supabase Auth)
2. Verifica email confirmado (revisa spam)
3. Pide reset de contraseña al desarrollador

---

## 📞 Contacto Soporte Técnico

| Canal | Para qué |
|-------|----------|
| **WhatsApp Dev** | Urgencias: web caída, errores críticos |
| **Email** | Dudas de uso, mejoras, bugs no urgentes |
| **Horario** | Lunes a Viernes 9:00 - 18:00 (GMT-5 Colombia) |

---

## 📚 Glosario Rápido

| Término | Significado simple |
|---------|-------------------|
| **CRUD** | Crear, Leer, Actualizar, Eliminar (las 4 acciones básicas) |
| **RLS** | Seguridad automática: público ve, solo admins editan |
| **Storage** | Nube donde se guardan tus fotos (Supabase) |
| **Slug** | URL amigable automática: "Conjunto Nieve" → `conjunto-nieve` |
| **HEX** | Código de color web: `#000000` = negro, `#FFFFFF` = blanco |
| **JSON** | Formato ordenado para datos técnicos (clave: "valor") |
| **Toast** | Aviso verde/rojo que sale abajo a la derecha |
| **Modal** | Ventana emergente centrada (confirmaciones, galerías) |

---

## ✅ Checklist Rápido Diario

- [ ] Entrar a `/admin.html` y ver Dashboard
- [ ] Revisar si hay productos nuevos que agregar
- [ ] Verificar que precios estén actualizados
- [ ] Confirmar que productos "Destacados" son los correctos (máx 8)
- [ ] Probar 1-2 productos en web pública (`/catalogo`)

---

**¡Listo! Con esta guía puedes gestionar todo tu catálogo de forma autónoma.** 🎀

*Última actualización: Septiembre 2026*  
*Versión del panel: 1.0.0*