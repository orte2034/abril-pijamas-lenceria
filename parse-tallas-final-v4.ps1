# parse-tallas-final-v4.ps1 - actualización quirúrgica de campos
$tallasRoot = "C:\Users\SAMUEL\Projects\abril-catalogo\public\web TALLAS"
$webRoot = "C:\Users\SAMUEL\Projects\abril-catalogo\public\web"
$mdDir = "C:\Users\SAMUEL\Projects\abril-catalogo\src\content\products"

# 1. Build tallasCache con propagación
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

# 3. Actualización quirúrgica: leer archivo, reemplazar solo líneas específicas
$mdFiles = Get-ChildItem -Path $mdDir -Filter *.md
$updated = 0
$noMatch = @()

foreach ($md in $mdFiles) {
    $content = Get-Content $md.FullName -Raw
    $lines = $content -split "`n"
    $slug = $md.BaseName.ToLower()
    
    if ($productTallas.ContainsKey($slug)) {
        $tallaRaw = $productTallas[$slug]
        $parsed = Parse-Talla $tallaRaw
    } else {
        $parsed = Parse-Talla ""
    }
    
    $newTallasStr = ($parsed.tallas -join '", "')
    $tallaUnicaStr = if ($parsed.tallaUnica) { 'true' } else { 'false' }
    $tallasConsultarStr = if ($parsed.tallasConsultar) { 'true' } else { 'false' }
    
    # Construir línea tallas: como YAML flow sequence correcto
    if ($parsed.tallas.Count -gt 0) {
        $tallasLine = 'tallas: ["' + $newTallasStr + '"]'
    } else {
        $tallasLine = 'tallas: []'
    }
    $tallaUnicaLine = "  tallaUnica: " + $tallaUnicaStr
    $tallasConsultarLine = "  tallasConsultar: " + $tallasConsultarStr
    
    # Procesar líneas
    $newLines = @()
    $inFrontmatter = $false
    $frontmatterEnded = $false
    $tallasReplaced = $false
    $tallaUnicaReplaced = $false
    $tallasConsultarReplaced = $false
    
    foreach ($line in $lines) {
        if (-not $frontmatterEnded) {
            if ($line -eq '---') {
                if ($inFrontmatter) { $frontmatterEnded = $true }
                else { $inFrontmatter = $true }
            }
            
            if ($inFrontmatter -and -not $frontmatterEnded) {
                # Reemplazar tallas:
                if ($line.TrimStart() -match '^tallas:\s*\[') {
                    $newLines += $tallasLine
                    $tallasReplaced = $true
                    continue
                }
                # Reemplazar tallaUnica:
                if ($line.TrimStart() -match '^tallaUnica:') {
                    $newLines += $tallaUnicaLine
                    $tallaUnicaReplaced = $true
                    continue
                }
                # Reemplazar tallasConsultar:
                if ($line.TrimStart() -match '^tallasConsultar:') {
                    $newLines += $tallasConsultarLine
                    $tallasConsultarReplaced = $true
                    continue
                }
                # Eliminar líneas duplicadas vacías o malformadas de tallas/tallaUnica/tallasConsultar
                if ($line.TrimStart() -match '^(tallas:|tallaUnica:|tallasConsultar:)' -and ($tallasReplaced -or $tallaUnicaReplaced -or $tallasConsultarReplaced)) {
                    continue
                }
            }
        }
        $newLines += $line
    }
    
    # Si no se reemplazó (no existía), agregar después de la última línea del frontmatter antes de ---
    if (-not $tallasReplaced -or -not $tallaUnicaReplaced -or -not $tallasConsultarReplaced) {
        # Buscar posición del cierre de frontmatter (---)
        $fmEndIdx = -1
        for ($i = 0; $i -lt $newLines.Count; $i++) {
            if ($newLines[$i] -eq '---' -and $i -gt 0) { $fmEndIdx = $i; break }
        }
        if ($fmEndIdx -gt 0) {
            $insertIdx = $fmEndIdx
            if (-not $tallasReplaced) { $newLines.Insert($insertIdx, $tallasLine); $insertIdx++ }
            if (-not $tallaUnicaReplaced) { $newLines.Insert($insertIdx, $tallaUnicaLine); $insertIdx++ }
            if (-not $tallasConsultarReplaced) { $newLines.Insert($insertIdx, $tallasConsultarLine); $insertIdx++ }
        }
    }
    
    Set-Content $md.FullName ($newLines -join "`n") -Encoding utf8 -NoNewline
    $updated++
}

Write-Output "Actualizados: $updated"