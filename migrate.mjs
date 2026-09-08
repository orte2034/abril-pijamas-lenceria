import { createClient } from '@supabase/supabase-js';
import fs from 'fs';
import path from 'path';
import matter from 'gray-matter';

// CONFIGURA ESTAS VARIABLES DE ENTORNO:
// - SUPABASE_URL=https://TU_PROJECT.supabase.co
// - SERVICE_ROLE_KEY=tu_service_role_key_aqui (Settings → API)
const SUPABASE_URL = import.meta.env.SUPABASE_URL || 'https://cgmhcbcoovbadsfjmoen.supabase.co';
const SERVICE_ROLE_KEY = import.meta.env.SERVICE_ROLE_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNnbWhjYmNvb3ZiYWRzZmptb2VuIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4ODcyMTIyNCwiZXhwIjoyMTA0Mjk3MjI0fQ.h9i6evXG7AFnDxuNHhFPUgV_kb3RhK6j8IL_oX3qAzs';

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

const productsDir = './src/content/products';
const files = fs.readdirSync(productsDir).filter(f => f.endsWith('.md'));

console.log(`Migrando ${files.length} productos...\n`);

for (const file of files) {
  const content = fs.readFileSync(path.join(productsDir, file), 'utf-8');
  const { data } = matter(content);
  
  const slug = data.nombre
    .toLowerCase()
    .normalize('NFD').replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)/g, '');

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
  
  if (error) {
    console.error(`❌ ${data.nombre}:`, error.message);
  } else {
    console.log(`✅ ${data.nombre}`);
  }
}

console.log('\n✨ Migración completada');