import { defineCollection, z } from 'astro:content';

const products = defineCollection({
  type: 'content',
  schema: z.object({
    nombre: z.string(),
    categoria: z.enum(['pijamas', 'lenceria', 'conjuntos']),
    subtipo: z.string().optional(),
    coleccion: z.string().default('Colección 2026'),
    precio: z.number().int().nonnegative(),
    destacado: z.boolean().default(false),
    colores: z.array(
      z.object({
        nombre: z.string(),
        hex: z.string().default('#cccccc'),
        imagen: z.string(),
      })
    ).min(1),
    tallas: z.array(z.string()).default(['XS', 'S', 'M', 'L', 'XL']),
    descripcion_es: z.string().default(''),
    descripcion_en: z.string().default(''),
  }),
});

export const collections = { products };
