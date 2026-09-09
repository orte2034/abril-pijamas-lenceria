import ws from "ws";
import type { APIRoute } from 'astro';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  import.meta.env.SUPABASE_URL || 'https://cgmhcbcoovbadsfjmoen.supabase.co',
  import.meta.env.SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJleCI6ImNnbWhjYmNvb3ZiYWRzZmptb2VuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg3MjEyMjQsImV4cCI6MjEwNDI5NzIyNH0.iyc1G1izwBkUVUVDJanuRN8vIximJw21GWyqrEVpslA',
  {
    realtime: {
      transport: ws as any
    }
  }
);

interface ProductoRaw {
  id: string;
  titulo: string;
  precio: number;
  categoria: string;
  subtipo: string | null;
  coleccion: string | null;
  destacado: boolean;
  colores: any;
  tallas: any;
  imagenes: any;
  descripcion_es: string | null;
  descripcion_en: string | null;
  fecha_creacion: string;
}

interface Producto {
  id: string;
  slug: string;
  nombre: string;
  categoria: string;
  subtipo: string | null;
  coleccion: string;
  precio: number;
  destacado: boolean;
  colores: Array<{ nombre: string; hex: string; imagen: string }>;
  tallas: string[];
  descripcion_es: string;
  descripcion_en: string;
  imagenes: string[];
  fecha_creacion: string;
}

function transformProduct(p: ProductoRaw): Producto {
  const colores = Array.isArray(p.colores) ? p.colores :
                 (typeof p.colores === 'string' ? JSON.parse(p.colores) : []);
  const tallas = Array.isArray(p.tallas) ? p.tallas :
                (typeof p.tallas === 'string' ? p.tallas.split(',').map((t: string) => t.trim()) : ['XS','S','M','L','XL']);
  const imagenes = Array.isArray(p.imagenes) ? p.imagenes :
                  (typeof p.imagenes === 'string' ? JSON.parse(p.imagenes) : []);
  
  const slug = p.titulo
    .toLowerCase()
    .normalize('NFD').replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)/g, '');

  return {
    id: p.id,
    slug,
    nombre: p.titulo,
    categoria: p.categoria,
    subtipo: p.subtipo,
    coleccion: p.coleccion || 'Colección 2026',
    precio: p.precio,
    destacado: p.destacado,
    colores: colores.length > 0 ? colores : [
      { nombre: 'Único', hex: '#cccccc', imagen: imagenes[0] || '/logo.jpeg' }
    ],
    tallas,
    descripcion_es: p.descripcion_es || '',
    descripcion_en: p.descripcion_en || '',
    imagenes,
    fecha_creacion: p.fecha_creacion
  };
}

export const GET: APIRoute = async ({ url }) => {
  try {
    const categoria = url.searchParams.get('categoria');
    const destacado = url.searchParams.get('destacado');
    const limit = parseInt(url.searchParams.get('limit') || '100');
    const offset = parseInt(url.searchParams.get('offset') || '0');
    const slug = url.searchParams.get('slug');

    let query = supabase
      .from('productos')
      .select('*', { count: 'exact' })
      .order('fecha_creacion', { ascending: false })
      .range(offset, offset + limit - 1);

    if (categoria) {
      query = query.eq('categoria', categoria);
    }
    if (destacado === 'true') {
      query = query.eq('destacado', true);
    }
    if (slug) {
      query = supabase
        .from('productos')
        .select('*', { count: 'exact' })
        .or(`titulo.ilike.%${slug}%,slug.eq.${slug}`);
    }

    const { data, error, count } = await query;

    if (error) throw error;

    const products: Producto[] = (data || []).map(transformProduct);

    return new Response(JSON.stringify({ products, count }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (err: unknown) {
    console.error('API Error:', err);
    const message = err instanceof Error ? err.message : 'Error desconocido';
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};