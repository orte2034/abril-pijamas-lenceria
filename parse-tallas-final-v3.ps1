# parse-tallas-final-v3.ps1 - regenerar MDs completos con frontmatter correcto
$tallasRoot = "C:\Users\SAMUEL\Projects\abril-catalogo\public\web TALLAS"
$webRoot = "C:\Users\SAMUEL\Projects\abril-catalogo\public\web"
$mdDir = "C:\Users\SAMUEL\Projects\abril-catalogo\src\content\products"

# 1. Build tallasCache con propagación a descendientes
$allDirs = Get-ChildItem -Path $tallasRoot -Recurse -Directory | Sort-Object { $_.FullName.Length }
$tallasCache = @{}

foreach ($d in $allDirs) {
    $rel = $d.FullName.Substring($tallasRoot.Length + 1).Replace('\','/')
    $leaf = Split-Path $rel -Leaf
    $tallaRaw = ''
    if ($leaf -imatch '(?i)\s+Talla\s+(.+?)(?:\s*\\|$)') { $tallaRaw = $matches[1].Trim() }
    elseif ($leaf -imatch '(?i)^Talla\s+(.+)$') { $tallaRaw = $matches[1].Trim() }
    $cleanRel = $rel -ireplace '(?i)\s+Talla\s+[^/\\]+',''
    $cleanRel = $cleanRel -ireplace '(?i)^Talla\s+[^/\\]+\s*',''
    if ($tallaRaw) {
        $tallasCache[$cleanRel] = $tallaRaw
        foreach ($sub in $allDirs) {
            $subRel = $sub.FullName.Substring($tallasRoot.Length + 1).Replace('\','/')
            $subClean = $subRel -ireplace '(?i)\s+Talla\s+[^/\\]+',''
            $subClean = $subClean -ireplace '(?i)^Talla\s+[^/\\]+\s*',''
            if ($subClean -like "$cleanRel/*") { $tallasCache[$subClean] = $tallaRaw }
        }
    }
}

# 2. Mapear web leaf dirs
$webLeafDirs = Get-ChildItem -Path $webRoot -Recurse -Directory | Where-Object {
    (Get-ChildItem -LiteralPath $_.FullName -File | Where-Object { $_.Extension -in '.jpg','.jpeg','.png' } | Measure-Object).Count -gt 0
}
$productTallas = @{}
foreach ($d in $webLeafDirs) {
    $rel = $d.FullName.Substring($webRoot.Length + 1).Replace('\','/')
    $keySlug = $rel.ToLower() -replace '/', '-'
    if ($tallasCache.ContainsKey($rel)) { $productTallas[$keySlug] = $tallasCache[$rel] }
}
Write-Output "Productos con talla: $($productTallas.Count)"

# 3. Parsear
function Parse-Talla([string]$raw) {
    if (-not $raw) { return @{ tallaUnica = $false; tallas = @(); tallasConsultar = $true } }
    $r = $raw.ToLower().Trim()
    if ($r -eq 'unica' -or $r -eq 'única') { return @{ tallaUnica = $true; tallas = @('Única'); tallasConsultar = $false } }
    if ($r -eq 'plus') { return @{ tallaUnica = $false; tallas = @('Plus'); tallasConsultar = $false } }
    if ($r -match '^\d+[\-\/]\d+') { $tallas = $r -split '\s+' | ForEach-Object { $_.Replace('-','/') }; return @{ tallaUnica = $false; tallas = $tallas; tallasConsultar = $false } }
    $r = $r.Replace(' ', '').Replace('/', '-')
    $hasS = $r -match 's|sm'; $hasM = $r -match 'm'; $hasL = $r -match 'l'; $hasXL = $r -match 'xl'
    $tallas = @(); if ($hasS) { $tallas += 'S' }; if ($hasM) { $tallas += 'M' }; if ($hasL) { $tallas += 'L' }; if ($hasXL) { $tallas += 'XL' }
    if ($tallas.Count -gt 0) { return @{ tallaUnica = $false; tallas = $tallas; tallasConsultar = $false } }
    return @{ tallaUnica = $false; tallas = @(); tallasConsultar = $true }
}

# 4. REGENERAR cada MD completamente (leer frontmatter existente, actualizar solo campos de talla, volver a escribir)
$mdFiles = Get-ChildItem -Path $mdDir -Filter *.md
$updated = 0
$noMatch = @()

foreach ($md in $mdFiles) {
    $content = Get-Content $md.FullName -Raw
    $slug = $md.BaseName.ToLower()
    
    # Parsear frontmatter existente (entre --- y ---)
    if ($content -notmatch '^---') { continue }
    $fmEnd = $content.IndexOf("---", 3)
    if ($fmEnd -lt 0) { continue }
    $frontmatter = $content.Substring(0, $fmEnd + 3)
    $body = $content.Substring($fmEnd + 3)
    
    # Convertir frontmatter a objeto (simple parse)
    $data = @{}
    $lines = $frontmatter -split "`n"
    $inColors = $false
    $colorIndex = -1
    foreach ($line in $lines) {
        if ($line -match '^(\w+):\s*(.*)$') {
            $key = $matches[1].Trim()
            $val = $matches[2].Trim()
            if ($key -eq 'colores') { $inColors = $true; $data[$key] = @(); continue }
            if ($inColors -and $line.TrimStart().StartsWith('-')) {
                # color entry - skip parsing individual fields for now
                continue
            }
            if ($inColors -and -not $line.TrimStart().StartsWith('-') -and $line.Trim() -ne '') { $inColors = $false }
            if (-not $inColors) { $data[$key] = $val }
        }
    }
    
    # Obtener valores existentes
    $nombre = $data['nombre'] -replace '^"|"$',''
    $categoria = $data['categoria'] -replace '^"|"$',''
    $subtipo = if ($data.ContainsKey('subtipo')) { $data['subtipo'] -replace '^"|"$','' } else { '' }
    $coleccion = if ($data.ContainsKey('coleccion')) { $data['coleccion'] -replace '^"|"$','' } else { 'Coleccion 2026' }
    $precio = if ($data.ContainsKey('precio')) { [int]$data['precio'] } else { 0 }
    $destacado = if ($data.ContainsKey('destacado')) { $data['destacado'] -eq 'true' } else { $false }
    
    # Parsear colores del frontmatter original
    $colores = @()
    $inColors = $false
    $colorObj = $null
    foreach ($line in $lines) {
        if ($line.Trim() -eq 'colores:') { $inColors = $true; continue }
        if ($inColors) {
            if ($line.TrimStart().StartsWith('-')) {
                if ($colorObj) { $colores += $colorObj }
                $colorObj = @{}
            }
            elseif ($line -match '^\s+(\w+):\s*(.*)$') {
                if ($colorObj) { $colorObj[$matches[1]] = $matches[2].Trim() -replace '^"|"$','' }
            }
            elseif ($line.Trim() -eq '' -or $line -match '^\w+:') { $inColors = $false }
        }
    }
    if ($colorObj) { $colores += $colorObj }
    
    # Obtener talla para este slug
    if ($productTallas.ContainsKey($slug)) {
        $tallaRaw = $productTallas[$slug]
        $parsed = Parse-Talla $tallaRaw
    } else {
        $parsed = Parse-Talla ""
    }
    
    # Construir nuevo frontmatter
    $yaml = ""
    foreach ($c in $colores) {
        $yaml += "  - nombre: `"$($c.nombre)`"`n    hex: `"$($c.hex)`"`n    imagen: `"$($c.imagen)`"`n"
    }
    $newTallasStr = ($parsed.tallas -join '", "')
    $tallaUnicaStr = if ($parsed.tallaUnica) { 'true' } else { 'false' }
    $tallasConsultarStr = if ($parsed.tallasConsultar) { 'true' } else { 'false' }
    
    $nom = $nombre -replace '"',"'"
    $subLine = if ($subtipo) { "subtipo: $subtipo`n" } else { "" }
    $mdText = @"
---
nombre: "$nom"
categoria: $categoria
${subLine}coleccion: "$coleccion"
precio: $precio
destacado: $destacado
colores:
$yaml`tallas: [$newTallasStr]
  tallaUnica: $tallaUnicaStr
  tallasConsultar: $tallasConsultarStr
tallas: ["XS", "S", "M", "L", "XL"]
descripcion_es: |
  $nombre - pieza disenada en Colombia por Abril Pijamas y Lenceria. Tejidos suaves, acabados con cuidado.
descripcion_en: |
  $nombre - piece designed in Colombia by Abril Pijamas and Lingerie. Soft fabrics, careful finishes.
---

# $nombre

Pieza de la Coleccion 2026 de Abril Pijamas y Lenceria. Hecha a mano en Colombia.
"@
    
    Set-Content $md.FullName $mdText -Encoding utf8 -NoNewline
    $updated++
}

Write-Output "MDs regenerados: $updated"

function Parse-Talla([string]$raw) {
    if (-not $raw) { return @{ tallaUnica = $false; tallas = @(); tallasConsultar = $true } }
    $r = $raw.ToLower().Trim()
    if ($r -eq 'unica' -or $r -eq 'única') { return @{ tallaUnica = $true; tallas = @('Única'); tallasConsultar = $false } }
    if ($r -eq 'plus') { return @{ tallaUnica = $false; tallas = @('Plus'); tallasConsultar = $false } }
    if ($r -match '^\d+[\-\/]\d+') { $tallas = $r -split '\s+' | ForEach-Object { $_.Replace('-','/') }; return @{ tallaUnica = $false; tallas = $tallas; tallasConsultar = $false } }
    $r = $r.Replace(' ', '').Replace('/', '-')
    $hasS = $r -match 's|sm'; $hasM = $r -match 'm'; $hasL = $r -match 'l'; $hasXL = $r -match 'xl'
    $tallas = @(); if ($hasS) { $tallas += 'S' }; if ($hasM) { $tallas += 'M' }; if ($hasL) { $tallas += 'L' }; if ($hasXL) { $tallas += 'XL' }
    if ($tallas.Count -gt 0) { return @{ tallaUnica = $false; tallas = $tallas; tallasConsultar = $false } }
    return @{ tallaUnica = $false; tallas = @(); tallasConsultar = $true }
}