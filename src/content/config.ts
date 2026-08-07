import { defineCollection, z } from 'astro:content';

const products = defineCollection({
  type: 'content',
  schema: z.object({
    nombre: z.string(),
    categoria: z.enum(['pijamas', 'lenceria', 'conjuntos']),
    subtipo: z.enum([
      'babydoll', 'bodys', 'clasica',
      'bobito', 'ninos', 'pijama-plus', 'pijama-satin', 'pijama-camiseta',
      'pijama-pantalon', 'pijama-tiras', 'pijama-batola', 'pijama-crop',
      'pijama-short', 'pijama-clasico',
      'enterizo', 'short', 'pantalon', 'tela-rib', 'conjunto',
      'falda', 'deportivo',
    ]).optional(),
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
    tallasDisponibles: z.array(z.string()).optional(),
    tallaUnica: z.boolean().default(false),
    tallasConsultar: z.boolean().default(false),
    descripcion_es: z.string().default(''),
    descripcion_en: z.string().default(''),
  }),
});

export const collections = { products };
