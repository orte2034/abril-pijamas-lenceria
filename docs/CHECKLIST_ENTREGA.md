# Checklist de Entrega - Abril Catálogo

**Proyecto**: Abril Catálogo v1.0  
**Cliente**: Abril Pijamas y Lencería  
**Fecha de entrega**: _______________  
**Responsable técnico**: _______________  
**Contacto cliente**: _______________

---

## 1. Credenciales y Accesos (Entregar por canal seguro)

| Credencial | Entregada ☐ | Canal | Notas |
|------------|-------------|-------|-------|
| **Supabase Project URL** | ☐ | 1Password/Bitwarden/Email enc. | `https://xxxx.supabase.co` |
| **Supabase ANON PUBLIC Key** | ☐ | 1Password/Bitwarden/Email enc. | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` |
| **Supabase Service Role Key** | ☐ | 1Password/Bitwarden/Email enc. | **Solo scripts backend** |
| **Supabase Dashboard URL** | ☐ | Link directo | `https://supabase.com/dashboard/project/xxxx` |
| **Vercel Project URL** | ☐ | Link directo | `https://vercel.com/xxx/abril-catalogo` |
| **Admin Panel URL** | ☐ | Link directo | `https://tudominio.com/admin.html` |
| **Usuario Admin (email)** | ☐ | 1Password/Bitwarden/Email enc. | `admin@tudominio.com` |
| **Password Admin** | ☐ | 1Password/Bitwarden/Email enc. | Generada segura |
| **Dominio personalizado** | ☐ | DNS/Registrar | `tudominio.com` |
| **Git Repo URL** | ☐ | Link directo | `https://github.com/xxx/abril-catalogo` |

> **⚠️ NUNCA** enviar credenciales por Slack, WhatsApp, email plano, ni commitear al repo.

---

## 2. Infraestructura Configurada

### 2.1 Supabase
| Ítem | Verificado ☐ | Detalle |
|------|--------------|---------|
| Proyecto creado (Plan Free) | ☐ | Región: South America (São Paulo) |
| Tabla `productos` creada | ☐ | Con índices y trigger `fecha_actualizacion` |
| RLS habilitado + 4 políticas | ☐ | SELECT public, INSERT/UPDATE/DELETE authenticated |
| Bucket `producto-imagenes` | ☐ | Público, 4 políticas Storage |
| Auth Email/Password habilitado | ☐ | Provider Email = Enabled |
| Usuario admin creado + confirmado | ☐ | Email real del cliente |
| Redirect URLs configuradas | ☐ | `https://tudominio.com/admin.html` |

### 2.2 Hosting (Vercel/Netlify/CF Pages)
| Ítem | Verificado ☐ | Detalle |
|------|--------------|---------|
| Repo conectado | ☐ | GitHub/GitLab/Bitbucket |
| Build configurado | ☐ | Output: `public`, Build: `npm run build` (o vacío) |
| Environment Variables | ☐ | `SUPABASE_URL` + `SUPABASE_ANON_KEY` (Prod/Preview/Dev) |
| Dominio personalizado | ☐ | DNS A + CNAME apuntando, SSL válido |
| Redirects/Rewrites | ☐ | `/catalogo` → `catalogo.html`, `/producto/*` → `producto.html` |
| Headers seguridad | ☐ | CSP, X-Frame-Options, HSTS, Permissions-Policy |
| Cache headers | ☐ | JS/CSS/imágenes: `max-age=31536000, immutable` |

### 2.3 Código Frontend
| Ítem | Verificado ☐ | Archivo |
|------|--------------|---------|
| Credenciales en `supabase-client.js` | ☐ | `public/js/supabase-client.js` líneas 6-7 |
| Credenciales en `admin.html` | ☐ | `admin.html` líneas ~580 |
| `vercel.json` / `netlify.toml` presentes | ☐ | En raíz del repo |
| `_redirects` (Netlify) | ☐ | `public/_redirects` |

---

## 3. Pruebas de Funcionamiento (Todo ✅ = Go-Live)

### 3.1 Catálogo Público (`/catalogo`)
| Test | ✅/❌ | Observaciones |
|------|------|---------------|
| Carga inicial sin errores JS | ☐ | Consola limpia |
| Productos se muestran (cards) | ☐ | Al menos 1 producto de prueba |
| Filtro Categoría (radio) | ☐ | Pijamas / Lencería / Conjuntos |
| Filtro Subtipo (checkbox) | ☐ | Solo activa en Lencería |
| Filtro Precio (slider) | ☐ | Min/Max labels actualizan |
| Filtro Color (botones) | ☐ | Outline burdeos al seleccionar |
| Deep linking `#cat=lenceria` | ☐ | URL hash funciona |
| Limpiar filtros | ☐ | Resetea todo |
| Paginación/Scroll infinito | ☐ | 20+ productos |
| Animaciones reveal | ☐ | Fade-up al hacer scroll |

### 3.2 Detalle Producto (`/producto/:slug`)
| Test | ✅/❌ | Observaciones |
|------|------|---------------|
| Navegación desde catálogo | ☐ | Click card → detalle |
| Imagen principal carga | ☐ | Lazy loading OK |
| Miniaturas galería | ☐ | Click → swap imagen principal |
| Selector colores | ☐ | Cambia imagen + nombre color |
| Selector tallas | ☐ | Feedback visual + marker oculto |
| Descripción + specs | ☐ | Renderiza correctamente |
| Botón WhatsApp | ☐ | Abre chat con datos correctos |
| Productos relacionados | ☐ | 3 items misma categoría |
| Meta tags OG/Twitter | ☐ | View source → og:image, og:title |
| Schema.org JSON-LD | ☐ | View source → `application/ld+json` |

### 3.3 Panel Admin (`/admin.html`)
| Test | ✅/❌ | Observaciones |
|------|------|---------------|
| Login con credenciales | ☐ | Redirect a Dashboard |
| Logout | ☐ | Vuelve a login, limpia sesión |
| Dashboard stats | ☐ | Total, Destacados, Última actualización |
| Listado Productos | ☐ | Tabla con 20 items/página |
| Búsqueda + Filtros listado | ☐ | Nombre, Categoría, Destacado |
| **CREAR** producto | ☐ | Form completo → Guardar → Toast éxito |
| Imágenes drag & drop | ☐ | Múltiples, previews, ✕ borrar |
| Colores variantes | ☐ | Nombre + HEX + imagen obligatoria |
| Tallas personalizables | ☐ | Quitar default + añadir custom |
| Especificaciones JSON | ☐ | Valida JSON al guardar |
| Descripciones ES/EN | ☐ | Textareas funcionan |
| **EDITAR** producto | ☐ | Carga datos + imágenes existentes |
| Conserva imágenes al editar | ☐ | Solo borra las marcadas ✕ |
| **ELIMINAR** producto | ☐ | Modal confirm → Borra BD + Storage |
| Ver galería imágenes | ☐ | Modal con todas las fotos |
| Paginación listado | ☐ | Anterior/Siguiente + números |
| Responsive admin (móvil) | ☐ | 320px - 768px usable |

### 3.4 Integración WhatsApp
| Test | ✅/❌ | Observaciones |
|------|------|---------------|
| Botón catálogo | ☐ | Incluye producto + colección |
| Botón detalle | ☐ | Incluye producto + color + talla + colección |
| Botón "Consultar tallas" | ☐ | Mensaje específico tallas |
| Número correcto | ☐ | `573169064533` (formato internacional) |

### 3.5 Rendimiento y SEO
| Test | ✅/❌ | Herramienta |
|------|------|-------------|
| Lighthouse Performance > 90 | ☐ | Chrome DevTools → Lighthouse |
| Lighthouse Accessibility > 95 | ☐ | Chrome DevTools → Lighthouse |
| Lighthouse Best Practices > 90 | ☐ | Chrome DevTools → Lighthouse |
| Lighthouse SEO > 95 | ☐ | Chrome DevTools → Lighthouse |
| Core Web Vitals (LCP < 2.5s) | ☐ | PageSpeed Insights / Search Console |
| No errores 404 en Network | ☐ | DevTools → Network (recarga) |
| Imágenes WebP/AVIF | ☐ | Network → Img → type |

---

## 4. Documentación Entregada

| Documento | Entregado ☐ | Ubicación |
|-----------|-------------|-----------|
| `README.md` | ☐ | `/docs/README.md` |
| `MANUAL_DESPLIEGUE_Y_DOMINIO.md` | ☐ | `/docs/MANUAL_DESPLIEGUE_Y_DOMINIO.md` |
| `CONFIGURACION_SUPABASE.md` | ☐ | `/docs/CONFIGURACION_SUPABASE.md` |
| `MANUAL_ADMIN_CLIENTE.md` | ☐ | `/docs/MANUAL_ADMIN_CLIENTE.md` |
| `CHECKLIST_ENTREGA.md` (este) | ☐ | `/docs/CHECKLIST_ENTREGA.md` |
| `ESTRUCTURA_PROYECTO.md` | ☐ | `/docs/ESTRUCTURA_PROYECTO.md` |

---

## 5. Capacitación al Cliente

| Actividad | Realizada ☐ | Fecha | Duración | Notas |
|-----------|-------------|-------|----------|-------|
| Demo completa panel admin | ☐ | | 30 min | Crear/Editar/Eliminar/Imágenes |
| Explicación flujo WhatsApp | ☐ | | 10 min | Datos que envía cada botón |
| Gestión de imágenes (optimización) | ☐ | | 15 min | Peso, dimensiones, nombres |
| Cómo marcar "Destacados" | ☐ | | 5 min | Checkbox en formulario |
| Resolución dudas FAQ | ☐ | | 15 min | Ver `MANUAL_ADMIN_CLIENTE.md` |
| Entrega de credenciales (seguro) | ☐ | | 5 min | 1Password/Bitwarden |
| Contacto soporte futuro | ☐ | | 5 min | Canales, horarios, SLA |

---

## 6. Recomendaciones de Mantenimiento

### Para el Cliente (Mensual)
- [ ] Revisar Dashboard Supabase: Storage < 80%, Bandwidth < 80%
- [ ] Exportar CSV productos (Table Editor → Export) como backup
- [ ] Verificar que productos "Destacados" son actuales (máx 8)
- [ ] Probar 2-3 productos en web pública + WhatsApp

### Para el Desarrollador (Trimestral)
- [ ] Rotar `ANON KEY` (Supabase Settings → API → Regenerate)
- [ ] Actualizar key en Vercel/Netlify + redeploy
- [ ] Revisar logs Supabase: API errors, slow queries
- [ ] Verificar plan Supabase (upgrade si DB > 400MB o Storage > 800MB)
- [ ] Actualizar dependencias CDN (Tailwind, Supabase SDK) si hay breaking changes

### Anual
- [ ] Renovación dominio + SSL
- [ ] Revisar costos hosting + Supabase
- [ ] Auditoría seguridad: RLS, headers, CSP
- [ ] Backup completo BD (Plan Pro+ PITR o export manual)

---

## 7. Firmas de Conformidad

### Cliente
```
Nombre: _________________________________
Cargo: _________________________________
Firma: _________________________________
Fecha: _________________________________
```

### Desarrollador / Agencia
```
Nombre: _________________________________
Cargo: _________________________________
Firma: _________________________________
Fecha: _________________________________
```

---

## 8. Soporte Post-Entrega (SLA)

| Nivel | Tiempo Respuesta | Canales | Incluye |
|-------|------------------|---------|---------|
| **Crítico** (web caída, datos perdidos) | < 2 hrs | WhatsApp / Llamada | Hotfix deploy, rollback, recovery BD |
| **Alto** (bug funcional, WhatsApp falla) | < 8 hrs | Email / WhatsApp | Fix + deploy en horas laborales |
| **Medio** (mejora, duda uso, bug visual) | < 48 hrs | Email | Próximo sprint / deploy semanal |
| **Bajo** (docs, configuración, consejo) | < 5 días | Email | Asesoría, documentación |

**Horario soporte**: Lunes a Viernes 9:00 - 18:00 (GMT-5 Colombia)  
**Excluido**: Cambios de diseño, nuevas features, migraciones masivas, gestión de contenido

---

## 9. Estado Final

```
☐ TODOS LOS CHECKS ✅ → ENTREGA APROBADA
☐ PENDIENTES: _______________________________________________
                _______________________________________________
                _______________________________________________

Próxima revisión: _________________________________
```

---

**¡Entrega completada con éxito! 🎉**

*Proyecto: Abril Catálogo v1.0*  
*Stack: HTML5 + CSS3 + JS Vanilla + Supabase + Vercel*  
*Documentación: 6 archivos en `/docs/`*