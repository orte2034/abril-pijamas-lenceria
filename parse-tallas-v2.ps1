# parse-tallas-v2.ps1 - matching mejorado: busca talla en toda la cadena de ancestros
$tallasRoot = "C:\Users\SAMUEL\Projects\abril-catalogo\public\web TALLAS"
$mdDir = "C:\Users\SAMUEL\Projects\abril-catalogo\src\content\products"

# 1. Leer TODAS las carpetas de web TALLAS y extraer talla de CADA nivel
$tallasDirs = Get-ChildItem -Path $tallasRoot -Recurse -Directory
$tallasMap = @{}  # key = slug sin "talla xxx", value = talla raw

foreach ($d in $tallasDirs) {
    $rel = $d.FullName.Substring($tallasRoot.Length + 1).Replace('\','/')
    $leaf = Split-Path $rel -Leaf
    
    # Buscar "Talla xxx" en esta carpeta
    $tallaRaw = ''
    if ($leaf -imatch '(?i)\s+Talla\s+(.+?)(?:\s*\\|$)') {
        $tallaRaw = $matches[1].Trim()
    }
    elseif ($leaf -imatch '(?i)^Talla\s+(.+)$') {
        $tallaRaw = $matches[1].Trim()
    }
    
    if ($tallaRaw) {
        # Crear key SIN el segmento "Talla xxx"
        $keyPath = $rel -ireplace '\s+Talla\s+.+?(\s*\\|$)',''
        $keyPath = $keyPath.Trim()
        # También quitar Talla al final si está solo
        $keyPath = $keyPath -ireplace '\\s*Talla\s+.+$',''
        $tallasMap[$keyPath] = $tallaRaw
    }
}
Write-Output "Paths con talla en web TALLAS: $($tallasMap.Count)"

# 2. Función parsear talla
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

# 3. Para cada MD, buscar match
$mdFiles = Get-ChildItem -Path $mdDir -Filter *.md
$updated = 0
$noMatch = @()

foreach ($md in $mdFiles) {
    $content = Get-Content $md.FullName -Raw
    $slug = $md.BaseName.ToLower()
    
    $tallaRaw = $null
    
    # Intentar match exacto
    if ($tallasMap.ContainsKey($slug)) {
        $tallaRaw = $tallasMap[$slug]
    } else {
        # Buscar si el slug contiene alguna key o viceversa
        foreach ($key in $tallasMap.Keys) {
            if ($slug -like "*$key*" -or $key -like "*$slug*") {
                $tallaRaw = $tallasMap[$key]
                break
            }
        }
    }
    
    if ($tallaRaw) {
        $parsed = Parse-Talla $tallaRaw
        $newTallasStr = ($parsed.tallas -join '", "')
        $tallaUnicaStr = if ($parsed.tallaUnica) { 'true' } else { 'false' }
        $tallasConsultarStr = if ($parsed.tallasConsultar) { 'true' } else { 'false' }
        
        $newContent = $content -replace 'tallas:\s*\[.*?\]', "tallas: [`"$newTallasStr`"]"
        if ($newContent -notmatch 'tallaUnica:') {
            $newContent = $newContent -replace 'tallas:\s*\[.*?\]', "tallas: [`"$newTallasStr`"]`n  tallaUnica: $tallaUnicaStr`n  tallasConsultar: $tallasConsultarStr"
        } else {
            $newContent = $newContent -replace 'tallaUnica: (true|false)', "tallaUnica: $tallaUnicaStr"
            $newContent = $newContent -replace 'tallasConsultar: (true|false)', "tallasConsultar: $tallasConsultarStr"
        }
        Set-Content $md.FullName $newContent -Encoding utf8 -NoNewline
        $updated++
    } else {
        # Sin talla explícita -> consultar
        $newContent = $content -replace 'tallas:\s*\[.*?\]', "tallas: []`n  tallaUnica: false`n  tallasConsultar: true"
        Set-Content $md.FullName $newContent -Encoding utf8 -NoNewline
        $noMatch += $md.Name
    }
}

Write-Output "Actualizados con talla: $updated"
Write-Output "Sin match (tallasConsultar): $($noMatch.Count)"