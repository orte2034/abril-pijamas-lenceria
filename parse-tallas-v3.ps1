# parse-tallas-v3.ps1 - normalizar keys a slug-format
$tallasRoot = "C:\Users\SAMUEL\Projects\abril-catalogo\public\web TALLAS"
$mdDir = "C:\Users\SAMUEL\Projects\abril-catalogo\src\content\products"

$tallasDirs = Get-ChildItem -Path $tallasRoot -Recurse -Directory
$tallasMap = @{}

foreach ($d in $tallasDirs) {
    $rel = $d.FullName.Substring($tallasRoot.Length + 1).Replace('\','/')
    $leaf = Split-Path $rel -Leaf
    $tallaRaw = ''
    if ($leaf -imatch '(?i)\s+Talla\s+(.+?)(?:\s*\\|$)') { $tallaRaw = $matches[1].Trim() }
    elseif ($leaf -imatch '(?i)^Talla\s+(.+)$') { $tallaRaw = $matches[1].Trim() }
    if ($tallaRaw) {
        $keyPath = $rel -ireplace '\s+Talla\s+.+?(\s*\\|$)',''
        $keyPath = $keyPath -ireplace '\\s*Talla\s+.+$',''
        # Normalizar a slug: / -> -
        $keySlug = $keyPath.ToLower() -replace '/', '-'
        $tallasMap[$keySlug] = $tallaRaw
    }
}
Write-Output "Keys en tallasMap (slug format): $($tallasMap.Count)"

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

$mdFiles = Get-ChildItem -Path $mdDir -Filter *.md
$updated = 0
$noMatch = @()

foreach ($md in $mdFiles) {
    $content = Get-Content $md.FullName -Raw
    $slug = $md.BaseName.ToLower()
    
    if ($tallasMap.ContainsKey($slug)) {
        $tallaRaw = $tallasMap[$slug]
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
        # Sin match -> consultar
        $newContent = $content -replace 'tallas:\s*\[.*?\]', "tallas: []`n  tallaUnica: false`n  tallasConsultar: true"
        Set-Content $md.FullName $newContent -Encoding utf8 -NoNewline
        $noMatch += $md.Name
    }
}

Write-Output "Actualizados con talla: $updated"
Write-Output "Sin match (tallasConsultar): $($noMatch.Count)"