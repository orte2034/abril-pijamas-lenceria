# parse-tallas-final.ps1 - con mapeo heredado funcionando
$tallasRoot = "C:\Users\SAMUEL\Projects\abril-catalogo\public\web TALLAS"
$webRoot = "C:\Users\SAMUEL\Projects\abril-catalogo\public\web"
$mdDir = "C:\Users\SAMUEL\Projects\abril-catalogo\src\content\products"

# 1. Build tallasCache desde web TALLAS (path limpio -> talla)
$allDirs = Get-ChildItem -Path $tallasRoot -Recurse -Directory | Sort-Object { $_.FullName.Length }
$tallasCache = @{}

foreach ($d in $allDirs) {
    $rel = $d.FullName.Substring($tallasRoot.Length + 1).Replace('\','/')
    $leaf = Split-Path $rel -Leaf
    $tallaRaw = ''
    if ($leaf -imatch '(?i)\s+Talla\s+(.+?)(?:\s*\\|$)') { $tallaRaw = $matches[1].Trim() }
    elseif ($leaf -imatch '(?i)^Talla\s+(.+)$') { $tallaRaw = $matches[1].Trim() }
    if ($tallaRaw) {
        $cleanRel = $rel -ireplace '(?i)\s+Talla\s+[^/\\]+',''
        $cleanRel = $cleanRel -ireplace '(?i)^Talla\s+[^/\\]+\s*',''
        $tallasCache[$cleanRel] = $tallaRaw
    }
}

# 2. Mapear carpetas-hoja web -> talla heredada
$webLeafDirs = Get-ChildItem -Path $webRoot -Recurse -Directory | Where-Object {
    (Get-ChildItem -LiteralPath $_.FullName -File | Where-Object { $_.Extension -in '.jpg','.jpeg','.png' } | Measure-Object).Count -gt 0
}

$productTallas = @{}
foreach ($d in $webLeafDirs) {
    $rel = $d.FullName.Substring($webRoot.Length + 1).Replace('\','/')
    $keySlug = $rel.ToLower() -replace '/', '-'
    if ($tallasCache.ContainsKey($rel)) {
        $productTallas[$keySlug] = $tallasCache[$rel]
    }
}

Write-Output "Productos con talla heredada: $($productTallas.Count)"

# 3. Parsear
function Parse-Talla([string]$raw) {
    if (-not $raw) { return @{ tallaUnica = $false; tallas = @(); tallasConsultar = $true } }
    $r = $raw.ToLower().Trim()
    if ($r -eq 'unica' -or $r -eq 'única') { return @{ tallaUnica = $true; tallas = @('Única'); tallasConsultar = $false } }
    if ($r -eq 'plus') { return @{ tallaUnica = $false; tallas = @('Plus'); tallasConsultar = $false } }
    if ($r -match '^\d+[\-\/]\d+') {
        $tallas = $r -split '\s+' | ForEach-Object { $_.Replace('-','/') }
        return @{ tallaUnica = $false; tallas = $tallas; tallasConsultar = $false }
    }
    $r = $r.Replace(' ', '').Replace('/', '-')
    $hasS = $r -match 's|sm'
    $hasM = $r -match 'm'
    $hasL = $r -match 'l'
    $hasXL = $r -match 'xl'
    $tallas = @()
    if ($hasS) { $tallas += 'S' }
    if ($hasM) { $tallas += 'M' }
    if ($hasL) { $tallas += 'L' }
    if ($hasXL) { $tallas += 'XL' }
    if ($tallas.Count -gt 0) { return @{ tallaUnica = $false; tallas = $tallas; tallasConsultar = $false } }
    return @{ tallaUnica = $false; tallas = @(); tallasConsultar = $true }
}

# 4. Actualizar MDs
$mdFiles = Get-ChildItem -Path $mdDir -Filter *.md
$updated = 0
$noMatch = @()

foreach ($md in $mdFiles) {
    $content = Get-Content $md.FullName -Raw
    $slug = $md.BaseName.ToLower()
    
    if ($productTallas.ContainsKey($slug)) {
        $tallaRaw = $productTallas[$slug]
        $parsed = Parse-Talla $tallaRaw
        $newTallasStr = ($parsed.tallas -join '", "')
        $tallaUnicaStr = if ($parsed.tallaUnica) { 'true' } else { 'false' }
        $tallasConsultarStr = if ($parsed.tallasConsultar) { 'true' } else { 'false' }
        
        # Reemplazar: tallas: [..], tallaUnica:, tallasConsultar: - SIN duplicados
        # Primero borrar líneas existentes de tallaUnica/tallasConsultar
        $newContent = $content -replace 'tallaUnica:\s*(true|false)`n',''
        $newContent = $newContent -replace 'tallasConsultar:\s*(true|false)`n',''
        # Luego reemplazar tallas:
        $newContent = $newContent -replace 'tallas:\s*\[.*?\]', "tallas: [`"$newTallasStr`"]"
        # Agregar tallaUnica y tallasConsultar después de tallas:
        if ($newContent -notmatch 'tallaUnica:') {
            $newContent = $newContent -replace 'tallas:\s*\[.*?\]', "tallas: [`"$newTallasStr`"]`n  tallaUnica: $tallaUnicaStr`n  tallasConsultar: $tallasConsultarStr"
        }
        
        Set-Content $md.FullName $newContent -Encoding utf8 -NoNewline
        $updated++
    } else {
        # Sin talla heredada
        $newContent = $content
        $newContent = $newContent -replace 'tallaUnica:\s*(true|false)`n',''
        $newContent = $newContent -replace 'tallasConsultar:\s*(true|false)`n',''
        $newContent = $newContent -replace 'tallas:\s*\[.*?\]', "tallas: []`n  tallaUnica: false`n  tallasConsultar: true"
        Set-Content $md.FullName $newContent -Encoding utf8 -NoNewline
        $noMatch += $md.Name
    }
}

Write-Output "Actualizados con talla: $updated"
Write-Output "Sin match (tallasConsultar): $($noMatch.Count)"