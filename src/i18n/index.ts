import es from '../i18n/es.json';
import en from '../i18n/en.json';

const dictionaries: Record<string, any> = { es, en };

export function t(key: string, locale: string = 'es'): string {
  const dict = dictionaries[locale] ?? dictionaries.es;
  return (dict[key] as string) ?? key;
}

export function formatCOP(value: number): string {
  return new Intl.NumberFormat('es-CO', {
    style: 'currency',
    currency: 'COP',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(value);
}
