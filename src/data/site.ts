export const SITE = {
  brandName: 'Abril Pijamas y Lencería',
  shortName: 'Abril',
  whatsappNumber: '573169064533',
  instagram: 'https://www.instagram.com/abrilpijamasylenceria',
  facebook: 'https://www.facebook.com/people/Abril-pijamas-y-lenceria/61553498622740/',
  tiktok: 'https://www.tiktok.com/@abrilpijamasylenceria',
};

export function buildWhatsAppLink(productName?: string, color?: string, talla?: string, coleccion?: string): string {
  const lines = ['Hola Abril Pijamas y Lencería, me interesa una prenda de su catálogo.'];
  if (productName) lines.push(`Pieza: ${productName}`);
  if (coleccion) lines.push(`Colección: ${coleccion}`);
  if (color) lines.push(`Color: ${color}`);
  if (talla) lines.push(`Talla: ${talla}`);
  lines.push('¿Está disponible? Gracias.');
  const text = encodeURIComponent(lines.join('\n'));
  return `https://wa.me/${SITE.whatsappNumber}?text=${text}`;
}

export function buildTallasWhatsAppLink(productName: string): string {
  const text = encodeURIComponent(`Hola Abril Pijamas y Lencería, me gustaría consultar información de tallas y disponibilidad de: ${productName}. Gracias.`);
  return `https://wa.me/${SITE.whatsappNumber}?text=${text}`;
}
