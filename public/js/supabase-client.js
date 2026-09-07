/**
 * Cliente Supabase para Abril Catálogo
 * Se inicializa vía CDN - NO requiere bundler
 * Configuración: Reemplazar URL y ANON_KEY con tus credenciales de Supabase
 */

// Configuración de Supabase - REEMPLAZAR CON TUS CREDENCIALES
const SUPABASE_URL = 'https://cgmhcbcoovbadsfjmoen.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNnbWhjYmNvb3ZiYWRzZmptb2VuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg3MjEyMjQsImV4cCI6MjEwNDI5NzIyNH0.iyc1G1izwBkUVUVDJanuRN8vIximJw21GWyqrEVpslA';

// Inicializar cliente Supabase (window.supabase ya viene del script tag CDN)
let supabase = null;

function initSupabase() {
    if (typeof window === 'undefined') return null;
    
    if (!window.supabase) {
        console.error('Supabase SDK no cargado. Verifica script tag en HTML.');
        return null;
    }
    
    supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
    return supabase;
}

// Función helper para obtener el cliente (inicializa si es necesario)
async function getSupabase() {
    if (supabase) return supabase;
    return initSupabase();
}

// Exportar para uso global
window.AbrilSupabase = {
    init: initSupabase,
    getClient: getSupabase,
    get URL() { return SUPABASE_URL; },
    get ANON_KEY() { return SUPABASE_ANON_KEY; }
};

// Auto-inicializar si estamos en el navegador
if (typeof window !== 'undefined') {
    document.addEventListener('DOMContentLoaded', () => {
        initSupabase();
    });
}