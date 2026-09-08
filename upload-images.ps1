<#
.SYNOPSIS
    Sube imágenes a Supabase Storage y genera SQL para insertar productos
.DESCRIPTION
    Recorre la carpeta "web TALLAS", sube todas las imágenes JPG/PNG a Supabase Storage,
    y genera un archivo SQL con INSERT statements usando las URLs públicas reales.
.PARAMETER ProjectRef
    Tu Project Reference de Supabase (Settings > General > Reference ID)
.PARAMETER Bucket
    Nombre del bucket de Storage (default: producto-imagenes)
.PARAMETER LocalPath
    Ruta local de las imágenes (default: public\web TALLAS)
.PARAMETER AnonKey
    Supabase Anon Key (default: la del proyecto actual)
.EXAMPLE
    .\upload-images.ps1 -ProjectRef "abcdefghijklmnop"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectRef,

    [string]$Bucket = "producto-imagenes",

    [string]$LocalPath = "C:\Users\SAMUEL\Projects\abril-catalogo\public\web TALLAS",

    [string]$AnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNnbWhjYmNvb3ZiYWRzZmptb2VuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg3MjEyMjQsImV4cCI6MjEwNDI5NzIyNH0.iyc1G1izwBkUVUVDJanuRN8vIximJw21GWyqrEVpslA"
)

# Configuración
$supabaseUrl = "https://$ProjectRef.supabase.co"
$storageApiUrl = "$supabaseUrl/storage/v1/object/$Bucket"
$publicUrlBase = "https://$ProjectRef.supabase.co/storage/v1/object/public/$Bucket"

$headers = @{
    "Authorization" = "Bearer $AnonKey"
    "apikey" = $AnonKey
}

# Precios estimados por categoría (ajustar después)
$preciosBase = @{
    "pijamas"   = @{ "base" = 120000; "plus" = 30000 }
    "lenceria"  = @{ "base" = 80000;  "plus" = 25000 }
    "conjuntos" = @{ "base" = 100000; "plus" = 20000 }
}

# Hex colors por nombre de archivo (fallback genéricos)
$colorHexMap = @{
    "blanco"      = "#FFFFFF"; "white"       = "#FFFFFF"
    "negro"       = "#000000"; "black"       = "#000000"
    "rosa"        = "#F8C8DC"; "pink"        = "#F8C8DC"
    "rojo"        = "#C41E3A"; "red"         = "#C41E3A"
    "azul"        = "#2D5AA0"; "blue"        = "#2D5AA0"
    "verde"       = "#2E7D32"; "green"       = "#2E7D32"
    "beige"       = "#F5F0E1"; "cream"       = "#F5F0E1"
    "gris"        = "#9E9E9E"; "gray"        = "#9E9E9E"
    "grisoscuro"  = "#424242"; "darkgray"    = "#424242"
    "marron"      = "#795548"; "brown"       = "#795548"
    "morado"      = "#7B1FA2"; "purple"      = "#7B1FA2"
    "lila"        = "#CE93D8"; "lilac"       = "#CE93D8"
    "champan"     = "#F7E7CE"; "champagne"   = "#F7E7CE"
    "dorado"      = "#FFD700"; "gold"        = "#FFD700"
    "plateado"    = "#C0C0C0"; "silver"      = "#C0C0C0"
    "nude"        = "#E8D5C4"
    "burdeos"     = "#7B2D3F"; "burgundy"    = "#7B2D3F"
    "vino"        = "#7B2D3F"; "wine"        = "#7B2D3F"
    "mostaza"     = "#FFB300"; "mustard"     = "#FFB300"
    "turquesa"    = "#00ACC1"; "teal"        = "#00ACC1"
    "celeste"     = "#81D4FA"; "skyblue"     = "#81D4FA"
    "coral"       = "#FF6F61"
    "salmon"      = "#FA8072"
}

function Get-ColorHex($filename) {
    $name = $filename.ToLower()
    $name = $name -replace '\s+', ''
    foreach ($key in $colorHexMap.Keys) {
        if ($name -like "*$key*") { return $colorHexMap[$key] }
    }
    # Generar color aleatorio consistente basado en hash del nombre
    $hash = [System.StringComparer]::OrdinalIgnoreCase.GetHashCode($name)
    $r = ($hash -band 0xFF0000) -shr 16
    $g = ($hash -band 0x00FF00) -shr 8
    $b = $hash -band 0x0000FF
    $r = [math]::Min(220, $r + 60)
    $g = [math]::Min(220, $g + 60)
    $b = [math]::Min(220, $b + 60)
    return "#{0:X2}{1:X2}{2:X2}" -f $r, $g, $b
}

function Upload-Image($filePath, $storagePath) {
    $bytes = [System.IO.File]::ReadAllBytes($filePath)
    $url = "$storageApiUrl/$storagePath"
    
    try {
        $response = Invoke-RestMethod -Method Post -Uri $url -Headers $headers -Body $bytes -ContentType "image/jpeg" -ErrorAction Stop
        return "$publicUrlBase/$storagePath"
    } catch {
        Write-Warning "Error subiendo $storagePath : $($_.Exception.Message)"
        return $null
    }
}

function Clean-ProductName($folderName) {
    $name = $folderName
    $name = $name -replace '^\d+-', ''
    $name = $name -replace '[_\-]+', ' '
    $name = $name -replace '\s+', ' '
    $name = $name -replace 'talla\s+(unica|unica|sm[-\s]?l|xs[-\s]?xl|\d+[-\s]?\d*)', ''
    $name = $name -replace '(?i)talla\s+(unica|sm[-\s]?l|xs[-\s]?xl|\d+[-\s]?\d*)', ''
    $name = $name -replace '\$\d+[.,]?\d*', ''
    $name = $name.Trim()
    $textInfo = [System.Globalization.CultureInfo]::CurrentCulture.TextInfo
    return $textInfo.ToTitleCase($name.ToLower())
}

function Get-CategoriaFromPath($relPath) {
    if ($relPath -like "pijamas*") { return "pijamas" }
    if ($relPath -like "lenceria*") { return "lenceria" }
    if ($relPath -like "conjunto*") { return "conjuntos" }
    return "pijamas"
}

function Get-SubtipoFromPath($relPath, $folderName) {
    $path = "$relPath $folderName"
    if ($path -like "*babydoll*") { return "babydoll" }
    if ($path -like "*bodys*") { return "bodys" }
    if ($path -like "*tanga*" -or $path -like "*cachetero*" -or $path -like "*bralette*") { return "clasica" }
    if ($path -like "*conjunto*" -and $path -like "*lenceria*") { return "clasica" }
    return $null
}

function Estimate-Price($categoria, $imageCount, $folderName) {
    $base = $preciosBase[$categoria].base
    $plus = $preciosBase[$categoria].plus
    $name = $folderName.ToLower()
    if ($name -like "*plus*" -or $name -like "*premier*" -or $name -like "*4.piezas*" -or $name -like "*4-piezas*") {
        return $base + $plus
    }
    if ($name -like "*3.piezas*" -or $name -like "*3-piezas*" -or $name -like "*tres.piezas*") {
        return [int]($base + ($plus * 0.5))
    }
    if ($name -like "*satin*" -or $name -like "*seda*" -or $name -like "*encaje*") {
        return [int]($base + ($plus * 0.3))
    }
    return $base
}

Write-Host "=== Iniciando subida de imagenes a Supabase ===" -ForegroundColor Cyan
Write-Host "Project Ref: $ProjectRef"
Write-Host "Bucket: $Bucket"
Write-Host "Local Path: $LocalPath"
Write-Host ""

if (-not (Test-Path $LocalPath)) {
    Write-Error "Ruta no existe: $LocalPath"
    exit 1
}

# Verificar bucket existe (usando upload de prueba)
try {
    $testBytes = [System.Text.Encoding]::UTF8.GetBytes("bucket-test")
    $testUrl = "$storageApiUrl/.bucket-test"
    Invoke-RestMethod -Uri $testUrl -Headers $headers -Method Post -Body $testBytes -ContentType "text/plain" -ErrorAction Stop
    # Limpiar test
    Invoke-RestMethod -Uri $testUrl -Headers $headers -Method Delete -ErrorAction SilentlyContinue
    Write-Host "Bucket '$Bucket' verificado correctamente (upload OK)" -ForegroundColor Green
} catch {
    Write-Error "Bucket '$Bucket' no existe o no accesible. Error: $($_.Exception.Message)"
    exit 1
}

$allProducts = @()
$totalUploaded = 0
$totalErrors = 0

# Procesar cada carpeta de producto (directorios que contienen imágenes)
$productFolders = @()
Get-ChildItem $LocalPath -Recurse -Directory | ForEach-Object {
    $files = Get-ChildItem $_.FullName -File -ErrorAction SilentlyContinue | Where-Object { 
        $_.Extension -in @(".jpg",".jpeg",".png",".JPG",".JPEG",".PNG") 
    }
    if ($files.Count -gt 0) { $productFolders += $_ }
}

Write-Host "Encontradas $($productFolders.Count) carpetas con imagenes" -ForegroundColor Yellow
Write-Host ""

foreach ($folder in $productFolders) {
    $relPath = $folder.FullName.Substring($LocalPath.Length + 1)
    $categoria = Get-CategoriaFromPath $relPath
    $subtipo = Get-SubtipoFromPath $relPath $folder.Name
    $productTitle = Clean-ProductName $folder.Name
    
    $imageFiles = Get-ChildItem $folder.FullName -File -ErrorAction SilentlyContinue | Where-Object { 
        $_.Extension -in @(".jpg",".jpeg",".png",".JPG",".JPEG",".PNG") 
    } | Sort-Object Name
    
    if ($imageFiles.Count -eq 0) { continue }
    
    Write-Host "Procesando: $productTitle ($categoria) - $($imageFiles.Count) imagenes" -ForegroundColor Gray
    
    $colores = @()
    $imagenesUrls = @()
    $colorIndex = 0
    
    foreach ($imgFile in $imageFiles) {
        $ext = $imgFile.Extension.ToLower()
        $guid = [System.Guid]::NewGuid()
        $safeTitle = $productTitle -replace '[^a-zA-Z0-9]+', '-' -replace '^-+|-+$', ''
        $storagePath = "productos/$safeTitle/$guid$ext"
        
        $publicUrl = Upload-Image $imgFile.FullName $storagePath
        
        if ($publicUrl) {
            $imagenesUrls += $publicUrl
            
            $colorName = "Color $($colorIndex + 1)"
            $hex = Get-ColorHex $imgFile.Name
            
            if ($colorIndex -eq 0) { $colorName = "Principal" }
            
            $colores += @{
                nombre  = $colorName
                hex     = $hex
                imagen  = $publicUrl
            }
            
            $totalUploaded++
            $colorIndex++
        } else {
            $totalErrors++
        }
    }
    
    if ($imagenesUrls.Count -eq 0) {
        Write-Warning "  No se subio ninguna imagen para $productTitle"
        continue
    }
    
    $precio = Estimate-Price $categoria $imagenesUrls.Count $folder.Name
    
    $tallas = @("XS","S","M","L","XL")
    if ($categoria -eq "lenceria" -and $subtipo -in @("babydoll","bodys")) {
        $tallas = @("XS","S","M","L")
    }
    
    $descEs = "$productTitle - Disenado y confeccionado en Colombia por Abril Pijamas y Lenceria. Tejidos suaves, acabados con cuidado."
    $descEn = "$productTitle - Designed and made in Colombia by Abril Pijamas y Lenceria. Soft fabrics, careful finishes."
    
    $product = [PSCustomObject]@{
        titulo         = $productTitle
        precio         = $precio
        categoria      = $categoria
        subtipo        = $subtipo
        coleccion      = "Coleccion 2026"
        destacado      = $false
        descripcion_es = $descEs
        descripcion_en = $descEn
        colores        = $colores
        imagenes       = $imagenesUrls
        tallas         = $tallas
    }
    
    $allProducts += $product
    Write-Host "  OK $($imagenesUrls.Count) imagenes subidas, precio estimado: $([string]::Format('{0:N0}', $precio)) COP" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Resumen ===" -ForegroundColor Cyan
Write-Host "Productos procesados: $($allProducts.Count)"
Write-Host "Imagenes subidas: $totalUploaded"
Write-Host "Errores: $totalErrors"
Write-Host ""

# Generar SQL
$sqlLines = @()
$sqlLines += "-- Productos generados automaticamente desde imagenes locales"
$sqlLines += "-- Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$sqlLines += "-- Proyecto: $ProjectRef"
$sqlLines += ""
$sqlLines += "INSERT INTO public.productos (titulo, precio, imagenes, tallas, categoria, subtipo, coleccion, destacado, descripcion_es, descripcion_en, colores) VALUES"

$valueLines = @()
foreach ($p in $allProducts) {
    $titulo = $p.titulo.Replace("'", "''")
    $descEs = $p.descripcion_es.Replace("'", "''")
    $descEn = $p.descripcion_en.Replace("'", "''")
    
    $imagenesJson = ($p.imagenes | ForEach-Object { "'" + $_ + "'" }) -join ','
    $imagenesPg = "ARRAY[$imagenesJson]"
    
    $tallasQuoted = $p.tallas | ForEach-Object { "'$_'" }
    $tallasPg = "ARRAY[$($tallasQuoted -join ',')]"
    
    $coloresJsonParts = @()
    foreach ($c in $p.colores) {
        $cNombre = $c.nombre.Replace('"', '\"')
        $cHex = $c.hex
        $cImagen = $c.imagen
        $coloresJsonParts += '{"nombre":"' + $cNombre + '","hex":"' + $cHex + '","imagen":"' + $cImagen + '"}'
    }
    $coloresJson = "[" + ($coloresJsonParts -join ',') + "]"
    
    $subtipoSql = if ($p.subtipo) { "'$($p.subtipo)'" } else { "NULL" }
    
    $valueLines += "('$titulo', $($p.precio), $imagenesPg, $tallasPg, '$($p.categoria)', $subtipoSql, '$($p.coleccion)', $($p.destacado), '$descEs', '$descEn', '$coloresJson'::jsonb)"
}

$sqlLines += ($valueLines -join ",\n") + ";"

$sqlContent = $sqlLines -join "`n"
$sqlPath = "C:\Users\SAMUEL\Projects\abril-catalogo\insert-products.sql"
$sqlContent | Out-File -FilePath $sqlPath -Encoding UTF8

Write-Host "SQL generado en: $sqlPath" -ForegroundColor Green
Write-Host ""
Write-Host "=== PROXIMOS PASOS ===" -ForegroundColor Yellow
Write-Host "1. Revisa el archivo SQL y AJUSTA PRECIOS manualmente (son estimados)"
Write-Host "2. Ejecuta el SQL en Supabase > SQL Editor"
Write-Host "3. Verifica en Supabase > Table Editor > productos"
Write-Host "4. Verifica en Supabase > Storage > $Bucket > productos/"
Write-Host ""
Write-Host "=== VERIFICACION RAPIDA ===" -ForegroundColor Cyan
$allProducts | Select-Object titulo, categoria, subtipo, @{n='Precio';e={'$' + [string]::Format('{0:N0}', $_.precio)}}, @{n='Imgs';e={$_.imagenes.Count}}, @{n='Colores';e={$_.colores.Count}} | Format-Table -AutoSize