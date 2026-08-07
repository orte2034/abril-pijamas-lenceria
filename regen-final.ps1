# regen-final.ps1 - Usando lógica probada de regen-all-v3 + tallas
$root = "C:\Users\SAMUEL\Projects\abril-catalogo\public\web"
$tallasRoot = "C:\Users\SAMUEL\Projects\abril-catalogo\public\web TALLAS"
$mdDir = "C:\Users\SAMUEL\Projects\abril-catalogo\src\content\products"

# ===== 1. TALLAS CACHE CON PROPAGACIÓN =====
$allDirsTallas = Get-ChildItem -Path $tallasRoot -Recurse -Directory | Sort-Object { $_.FullName.Length }
$tallasCache = @{}
foreach ($d in $allDirsTallas) {
    $rel = $d.FullName.Substring($tallasRoot.Length + 1).Replace('\','/')
    $leaf = Split-Path $rel -Leaf
    $tallaRaw = ''
    if ($leaf -imatch '(?i)\s+Talla\s+(.+?)(?:\s*\\|$)') { $tallaRaw = $matches[1].Trim() }
    elseif ($leaf -imatch '(?i)^Talla\s+(.+)$') { $tallaRaw = $matches[1].Trim() }
    $cleanRel = $rel -ireplace '(?i)\s+Talla\s+[^/\\]+',''
    $cleanRel = $cleanRel -ireplace '(?i)^Talla\s+[^/\\]+\s*',''
    if ($tallaRaw) {
        $tallasCache[$cleanRel] = $tallaRaw
        foreach ($sub in $allDirsTallas) {
            $subRel = $sub.FullName.Substring($tallasRoot.Length + 1).Replace('\','/')
            $subClean = $subRel -ireplace '(?i)\s+Talla\s+[^/\\]+',''
            $subClean = $subClean -ireplace '(?i)^Talla\s+[^/\\]+\s*',''
            if ($subClean -like "$cleanRel/*") { $tallasCache[$subClean] = $tallaRaw }
        }
    }
}

$webLeafDirs = Get-ChildItem -Path "C:\Users\SAMUEL\Projects\abril-catalogo\public\web" -Recurse -Directory | Where-Object {
    (Get-ChildItem -LiteralPath $_.FullName -File | Where-Object { $_.Extension -in '.jpg','.jpeg','.png' } | Measure-Object).Count -gt 0
}
$productTallas = @{}
foreach ($d in $webLeafDirs) {
    $rel = $d.FullName.Substring("C:\Users\SAMUEL\Projects\abril-catalogo\public\web".Length + 1).Replace('\','/')
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

# ===== USAR LÓGICA PROBADA DE regen-all-v3.ps1 =====
$webRoot = "C:\Users\SAMUEL\Projects\abril-catalogo\public\web"
$allDirs = Get-ChildItem -Path $webRoot -Recurse -Directory | Sort-Object FullName
$leafDirs = @()
foreach ($d in $allDirs) {
    $hasSubdirs = (Get-ChildItem -LiteralPath $d.FullName -Directory -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0
    if (-not $hasSubdirs) { $leafDirs += $d }
}
Write-Output "Carpetas-hoja: $($leafDirs.Count)"

# Cargar funciones auxiliares desde regen-all-v3.ps1 (ya existen en memoria si se ejecutó antes)
# Las definimos de nuevo aquí para asegurar que están disponibles:

function Get-Subtipo($categoria, $path, $leafName) {
    if ($categoria -eq 'lenceria') {
        if ($path -like 'lenceria/babydoll/*') { return 'babydoll' }
        if ($path -like 'lenceria/bodys/*') { return 'bodys' }
        if ($path -like 'lenceria/lenceria/*') { return 'clasica' }
        return 'clasica'
    }
    if ($categoria -eq 'pijamas') {
        if ($path -like 'pijamas/nin-s/*') { return 'ninos' }
        if ($path -like '*bobito*') { return 'bobito' }
        if ($path -like '*plus*' -or $path -like 'pijamas/plus-*') { return 'pijama-plus' }
        if ($path -like '*satin*' -or $path -like '*saten*') { return 'pijama-satin' }
        if ($path -like '*camiseta*') { return 'pijama-camiseta' }
        if ($path -like '*pantalon*') { return 'pijama-pantalon' }
        if ($path -like '*tiras*') { return 'pijama-tiras' }
        if ($path -like '*batola*') { return 'pijama-batola' }
        if ($path -like '*crop*') { return 'pijama-crop' }
        if ($path -like '*short*') { return 'pijama-short' }
        return 'pijama-clasico'
    }
    if ($categoria -eq 'conjuntos') {
        if ($path -like '*enterizo*' -or $path -like '*manga-corta*' -or $path -like '*manga-larga*' -or $path -like '*marmol*' -or $path -like '*alo-*' -or $path -like '*enterixo-suplex*' -or $path -like '*manga-28*' -or $path -like '*enterizo-tira*') { return 'enterizo' }
        if ($path -like '*short*' -or $path -like 'falda-short-y-top*') { return 'short' }
        if ($path -like '*pantalon*' -or $path -like '*cargo*' -or $path -like '*joger*' -or $path -like 'yomper*') { return 'pantalon' }
        if ($path -like '*tela-rib*' -or $path -like '*/botones*' -or $path -like '*/cremallera*' -or $path -like '*/otros*') { return 'tela-rib' }
        if ($path -like '*marmolado*') { return 'conjunto' }
        if ($path -like 'tela-rib-47-000*') { return 'tela-rib' }
        if ($path -like '*falda*') { return 'falda' }
        if ($path -like '*deportivo*') { return 'deportivo' }
        if ($path -like 'pijamas-coquetas*') { return 'pijama-coquetas' }
        return 'conjunto'
    }
    return ''
}

function Extract-Precio($leafName, $parentName) {
    foreach ($str in @($leafName, $parentName)) {
        $m = [regex]::Match($str, '(\d{1,3})[\-\.]?000')
        if ($m.Success) { return [int]($m.Groups[1].Value + '000') }
        $m2 = [regex]::Match($str, '(\d{1,3})[\-\.]?(\d{3})')
        if ($m2.Success) { $val = [int]($m2.Groups[1].Value + $m2.Groups[2].Value); if ($val -ge 5000) { return $val } }
        $m3 = [regex]::Match($str, '(\d{2,3}000)')
        if ($m3.Success) { return [int]$m3.Groups[1].Value }
    }
    return 0
}

function Build-Nombre($leafName, $parentName, $precio) {
    $cleanLeaf = [regex]::Replace($leafName, '(\d{1,3})[\-\.]?000', '')
    $cleanLeaf = [regex]::Replace($cleanLeaf, '(\d{2,3}000)', '')
    $cleanLeaf = $cleanLeaf.Trim('-','_',' ')
    $cleanParent = [regex]::Replace($parentName, '(\d{1,3})[\-\.]?000', '')
    $cleanParent = [regex]::Replace($cleanParent, '(\d{2,3}000)', '')
    $cleanParent = $cleanParent.Trim('-','_',' ')
    $nameSource = $cleanLeaf
    if (-not $nameSource -or $nameSource -match '^\d+$') { $nameSource = $cleanParent }
    if (-not $nameSource) { $nameSource = $leafName }
    $words = ($nameSource -split '-') | Where-Object { $_ -and $_.Length -gt 0 }
    $out = ($words | ForEach-Object { $_.Substring(0,1).ToUpper() + $_.Substring(1).ToLower() }) -join ' '
    return $out.Trim()
}

function Slugify($s) {
    $s = $s.ToLower()
    $s = [regex]::Replace($s, '[^a-z0-9\-_/]', '-')
    $s = [regex]::Replace($s, '-{2,}', '-')
    $s = [regex]::Replace($s, '/+', '-')
    $s = $s.Trim('-')
    return $s
}

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

# ===== CONSTRUIR PRODUCTOS =====
$products = @()
$slugsUsed = @{}
foreach ($d in $leafDirs) {
    $files = Get-ChildItem -LiteralPath $d.FullName -File | Where-Object { $_.Extension -in '.jpg','.jpeg','.png' }
    if ($files.Count -eq 0) { continue }
    $rel = $d.FullName.Substring("C:\Users\SAMUEL\Projects\abril-catalogo\public\web".Length + 1).Replace('\','/').ToLower()
    $parts = $rel -split '/'
    $categoriaRaw = $parts[0]
    if ($categoriaRaw -in @('conjunto-pantalon-burda','conjunto-short-animado')) { $categoria = 'conjuntos' } else { $categoria = $categoriaRaw }
    if ($categoria -notin @('pijamas','lenceria','conjuntos')) { continue }
    $leafName = $parts[-1]
    $parentName = if ($parts.Length -ge 2) { $parts[-2] } else { '' }
    $subtipo = Get-Subtipo -categoria $categoria -path ($rel) -leafName $leafName
    $precio = Extract-Precio -leafName $leafName -parentName $parentName
    $nombre = Build-Nombre -leafName $leafName -parentName $parentName -precio $precio
    $slug = Slugify $rel
    # Evitar duplicados
    $slugAux = $slug; $counter = 2
    while ($slugsUsed.ContainsKey($slugAux)) { $slugAux = "$slug-$counter"; $counter++ }
    $slugsUsed[$slugAux] = $true
    $slug = $slugAux
    
    $colores = @()
    $i = 0
    foreach ($f in (Get-ChildItem -LiteralPath $d.FullName -File | Where-Object { $_.Extension -in '.jpg','.jpeg','.png' })) {
        $i++; $colores += @{ nombre = "Color $i"; hex = "#cccccc"; imagen = "/web/$rel/" + $f.Name.ToLower() }
    }
    
    $tallaRaw = if ($productTallas.ContainsKey($slug)) { $productTallas[$slug] } else { '' }
    $parsed = Parse-Talla $tallaRaw
    
    $products += @{
        Nombre = $nombre; Slug = $slug; Categoria = $categoria; Subtipo = $subtipo
        Precio = $precio; Colores = $colores; Carpeta = $rel
        Tallas = $parsed.tallas; TallaUnica = $parsed.tallaUnica; TallasConsultar = $parsed.tallasConsultar
    }
}
Write-Output "Productos totales: $($products.Count)"

# ===== REGENERAR MDs =====
$mdDir = "C:\Users\SAMUEL\Projects\abril-catalogo\src\content\products"
Remove-Item "$mdDir\*.md" -Force -ErrorAction SilentlyContinue
$created = 0
foreach ($p in $products) {
    $yaml = ""
    foreach ($c in $p.Colores) {
        $yaml += "  - nombre: `"$($c.nombre)`"`n    hex: `"$($c.hex)`"`n    imagen: `"$($c.imagen)`"`n"
    }
    $newTallasStr = ($p.Tallas -join '", "')
    $tallaUnicaStr = if ($p.TallaUnica) { 'true' } else { 'false' }
    $tallasConsultarStr = if ($p.TallasConsultar) { 'true' } else { 'false' }
    $nom = $p.Nombre -replace '"',"'"
    $subLine = if ($p.Subtipo) { "subtipo: $($p.Subtipo)`n" } else { "" }
    
    $fm = @"
---
nombre: "$nom"
categoria: $($p.Categoria)
${subLine}coleccion: "Coleccion 2026"
precio: $($p.Precio)
destacado: false
colores:
$yaml`tallas: ["$newTallasStr"]
  tallaUnica: $tallaUnicaStr
  tallasConsultar: $tallasConsultarStr
tallas: ["XS", "S", "M", "L", "XL"]
descripcion_es: |
  $($p.Nombre) - pieza disenada en Colombia por Abril Pijamas y Lenceria. Tejidos suaves, acabados con cuidado.
descripcion_en: |
  $($p.Nombre) - piece designed in Colombia by Abril Pijamas and Lingerie. Soft fabrics, careful finishes.
---

# $($p.Nombre)

Pieza de la Coleccion 2026 de Abril Pijamas y Lenceria. Hecha a mano en Colombia.
"@
    Set-Content "C:\Users\SAMUEL\Projects\abril-catalogo\src\content\products\$($p.Slug).md" $fm -Encoding utf8 -NoNewline
    $created++
}
Write-Output "MDs creados: $created"