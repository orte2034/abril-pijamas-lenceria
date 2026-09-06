-- Supabase Schema for Abril Catálogo
-- Ejecutar en el SQL Editor de Supabase

-- 1. Habilitar extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Tabla de productos
CREATE TABLE public.productos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    titulo VARCHAR(255) NOT NULL,
    precio INTEGER NOT NULL DEFAULT 0,
    imagenes TEXT[] NOT NULL DEFAULT '{}', -- Array de URLs de imágenes
    tallas TEXT[] NOT NULL DEFAULT '{"XS","S","M","L","XL"}',
    especificaciones JSONB, -- JSON para especificaciones flexibles
    categoria VARCHAR(50) NOT NULL DEFAULT 'pijamas', -- pijamas, lenceria, conjuntos
    subtipo VARCHAR(50), -- clasica, babydoll, bodys, etc.
    coleccion VARCHAR(100) DEFAULT 'Colección 2026',
    destacado BOOLEAN DEFAULT FALSE,
    descripcion_es TEXT DEFAULT '',
    descripcion_en TEXT DEFAULT '',
    colores JSONB NOT NULL DEFAULT '[]'::JSONB, -- Array de {nombre, hex, imagen}
    fecha_creacion TIMESTAMPTZ DEFAULT NOW(),
    fecha_actualizacion TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Índices para mejorar consultas
CREATE INDEX idx_productos_categoria ON public.productos(categoria);
CREATE INDEX idx_productos_destacado ON public.productos(destacado);
CREATE INDEX idx_productos_fecha_creacion ON public.productos(fecha_creacion DESC);

-- 4. Habilitar RLS (Row Level Security)
ALTER TABLE public.productos ENABLE ROW LEVEL SECURITY;

-- 5. Políticas de seguridad para productos
-- Lectura pública (catálogo público)
CREATE POLICY "Productos visibles para todos" ON public.productos
    FOR SELECT USING (TRUE);

-- Inserción/Actualización/Eliminación solo para usuarios autenticados (admins)
CREATE POLICY "Admins pueden insertar productos" ON public.productos
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Admins pueden actualizar productos" ON public.productos
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Admins pueden eliminar productos" ON public.productos
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

-- 7. Storage Bucket para imágenes de productos
-- Ejecutar en Storage > Buckets > Create Bucket
-- Nombre: producto-imagenes
-- Público: Sí (para que las imágenes sean accesibles públicamente)

-- Políticas de Storage (ejecutar después de crear el bucket)
-- INSERT: Admins autenticados pueden subir
CREATE POLICY "Admins pueden subir imágenes" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'producto-imagenes' AND
        auth.role() = 'authenticated'
    );

-- UPDATE: Admins autenticados pueden actualizar
CREATE POLICY "Admins pueden actualizar imágenes" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'producto-imagenes' AND
        auth.role() = 'authenticated'
    );

-- DELETE: Admins autenticados pueden eliminar
CREATE POLICY "Admins pueden eliminar imágenes" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'producto-imagenes' AND
        auth.role() = 'authenticated'
    );

-- SELECT: Público puede ver imágenes
CREATE POLICY "Imágenes visibles para todos" ON storage.objects
    FOR SELECT USING (bucket_id = 'producto-imagenes');

-- 8. Datos de ejemplo (opcional - para testing)
/*
INSERT INTO public.productos (titulo, precio, imagenes, tallas, especificaciones, categoria, subtipo, coleccion, destacado, descripcion_es, descripcion_en, colores)
VALUES (
    'CONJUNTO NIEVE',
    24000,
    ARRAY['/placeholder-image.jpg'],
    ARRAY['XS','S','M','L','XL'],
    '{"material": "Encaje y tul", "cuidado": "Lavar a mano"}'::JSONB,
    'lenceria',
    'clasica',
    'Colección 2026',
    FALSE,
    'CONJUNTO NIEVE - pieza diseñada en Colombia por Abril Pijamas y Lencería. Tejidos suaves, acabados con cuidado y colores que cuidan.',
    'CONJUNTO NIEVE - piece designed in Colombia by Abril Pijamas and Lingerie. Soft fabrics, careful finishes.',
    '[{"nombre": "Color 1", "hex": "#cccccc", "imagen": "/placeholder-image.jpg"}, {"nombre": "Color 2", "hex": "#cccccc", "imagen": "/placeholder-image.jpg"}]'::JSONB
);
*/