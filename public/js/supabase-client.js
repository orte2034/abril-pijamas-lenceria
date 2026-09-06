/**
 * Cliente Supabase para Abril Catálogo
 * Se inicializa vía CDN - NO requiere bundler
 * Configuración: Reemplazar URL y ANON_KEY con tus credenciales de Supabase
 */

// Configuración de Supabase - REEMPLAZAR CON TUS CREDENCIALES
const SUPABASE_URL = 'https://cgmhcbcoovbadsfjmoen.supabase.co/rest/v1/';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNnbWhjYmNvb3ZiYWRzZmptb2VuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg3MjEyMjQsImV4cCI6MjEwNDI5NzIyNH0.iyc1G1izwBkUVUVDJanuRN8vIximJw21GWyqrEVpslA';

// Inicializar cliente Supabase vía CDN
// El SDK se carga desde: https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2
let supabase = null;

async function initSupabase() {
    if (typeof window === 'undefined') return null;
    
    // Verificar si el SDK ya está cargado
    if (window.supabase) {
        supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
        return supabase;
    }

    // Cargar SDK dinámicamente si no está disponible
    return new Promise((resolve, reject) => {
        const script = document.createElement('script');
        script.src = 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/dist/umd/supabase.min.js';
        script.onload = () => {
            supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
            resolve(supabase);
        };
        script.onerror = () => reject(new Error('No se pudo cargar el SDK de Supabase'));
        document.head.appendChild(script);
    });
}

// Función helper para obtener el cliente (inicializa si es necesario)
async function getSupabase() {
    if (supabase) return supabase;
    return await initSupabase();
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
    // Pequeño delay para asegurar que el DOM está listo
    document.addEventListener('DOMContentLoaded', () => {
        initSupabase().catch(console.error);
    });
}