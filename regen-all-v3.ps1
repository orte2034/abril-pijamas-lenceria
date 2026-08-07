# regen-all-v3.ps1 - Slug = path completo slugificado, nombre hereda de padres
$root = "C:\Users\SAMUEL\Projects\abril-catalogo\public\web"
$webPrefixLen = $root.Length + 1
$mdDir = "C:\Users\SAMUEL\Projects\abril-catalogo\src\content\products"

function Get-Subtipo([string]$categoria, [string]$path, [string]$leafName) {
    if ($categoria -eq 'lenceria') {
        if ($path -like 'lenceria/babydoll/*') { return 'babydoll' }
        if ($path -like 'lenceria/bodys/*') { return 'bodys' }
        if ($path -like 'lenceria/lenceria/*') { return 'clasica' }
        return 'clasica'
    }
    if ($categoria -eq 'pijamas') {
        # mirar TODO el path para detectar subtipo correcto
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
        # mirar todo el path
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

function Extract-Precio([string]$leafName, [string]$parentName) {
    foreach ($str in @($leafName, $parentName)) {
        # patron principal NN-000 o NN000
        $m = [regex]::Match($str, '(\d{1,3})[\-\.]?000')
        if ($m.Success) { return [int]($m.Groups[1].Value + '000') }
        $m2 = [regex]::Match($str, '(\d{1,3})[\-\.]?(\d{3})')
        if ($m2.Success) {
            $val = [int]($m2.Groups[1].Value + $m2.Groups[2].Value)
            if ($val -ge 5000) { return $val }
        }
        $m3 = [regex]::Match($str, '(\d{2,3}000)')
        if ($m3.Success) { return [int]$m3.Groups[1].Value }
    }
    return 0
}

function Capitalize-Words([string]$s) {
    if (-not $s) { return $s }
    $words = $s -split ' '
    $out = @()
    foreach ($w in $words) {
        if ($w.Length -eq 0) { continue }
        $out += $w.Substring(0,1).ToUpper() + $w.Substring(1).ToLower()
    }
    return ($out -join ' ')
}

function Build-Nombre([string]$leafName, [string]$parentName, [int]$precio) {
    # Si el leafName es solo un numero/precio, usar parentName
    $cleanLeaf = $leafName
    $cleanParent = $parentName
    
    # quita precios de cada uno
    $cleanLeaf = [regex]::Replace($cleanLeaf, '(\d{1,3})[\-\.]?000', '')
    $cleanLeaf = [regex]::Replace($cleanLeaf, '(\d{2,3}000)', '')
    $cleanLeaf = $cleanLeaf.Trim('-','_',' ')
    
    $cleanParent = [regex]::Replace($cleanParent, '(\d{1,3})[\-\.]?000', '')
    $cleanParent = [regex]::Replace($cleanParent, '(\d{2,3}000)', '')
    $cleanParent = $cleanParent.Trim('-','_',' ')
    
    # Si leafName despues de limpiar queda vacio o solo digitos, usar parent
    $nameSource = $cleanLeaf
    if (-not $nameSource -or $nameSource -match '^\d+$') {
        $nameSource = $cleanParent
    }
    # Si parent tambien esta vacio, fallback a leaf original
    if (-not $nameSource) { $nameSource = $leafName }
    
    # capitalizar
    $parts = ($nameSource -split '-') | Where-Object { $_ -and $_.Length -gt 0 }
    $nameSource = ($parts | ForEach-Object { [char]::ToUpper($_[0]) + $_.Substring(1).ToLower() }) -join ' '
    return $nameSource.Trim()
}

function Slugify([string]$s) {
    $s = $s.ToLower()
    $s = [regex]::Replace($s, '[^a-z0-9\-_/]', '-')
    $s = [regex]::Replace($s, '-{2,}', '-')
    $s = [regex]::Replace($s, '/+', '-')
    $s = $s.Trim('-')
    return $s
}

# === PASO 1: identificar carpetas-hoja ===
$allDirs = Get-ChildItem -Path $root -Recurse -Directory | Sort-Object FullName
$leafDirs = @()
foreach ($d in $allDirs) {
    $hasSubdirs = (Get-ChildItem -LiteralPath $d.FullName -Directory -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0
    if (-not $hasSubdirs) { $leafDirs += $d }
}
Write-Output "Carpetas-hoja: $($leafDirs.Count)"

# === PASO 2: construir productos ===
$products = @()
$slugsUsed = @{}
foreach ($d in $leafDirs) {
    $files = Get-ChildItem -LiteralPath $d.FullName -File | Where-Object { $_.Extension -in '.jpg','.jpeg','.png' }
    if ($files.Count -eq 0) { continue }
    
    $rel = $d.FullName.Substring($webPrefixLen).Replace('\','/').ToLower()
    $parts = $rel -split '/'
    $categoriaRaw = $parts[0]
    if ($categoriaRaw -in @('conjunto-pantalon-burda','conjunto-short-animado')) {
        $categoria = 'conjuntos'
    } else {
        $categoria = $categoriaRaw
    }
    if ($categoria -notin @('pijamas','lenceria','conjuntos')) { continue }
    
    $leafName = $parts[-1]
    $parentName = if ($parts.Length -ge 2) { $parts[-2] } else { '' }
    
    $subtipo = Get-Subtipo -categoria $categoria -path $rel -leafName $leafName
    $precio = Extract-Precio -leafName $leafName -parentName $parentName
    $nombre = Build-Nombre -leafName $leafName -parentName $parentName -precio $precio
    
    # slug: path completo con la ultima parte, slugificado, sin extensiones -000
    $slugPath = $rel
    $slug = Slugify $slugPath
    # si slug es muy largo, recortar manteniendo la unicidad (dejar ultimos 60 chars)
    if ($slug.Length -gt 100) {
        $slug = $slug.Substring([Math]::Max(0, $slug.Length - 100))
        $slug = $slug.TrimStart('-')
    }
    # evitar duplicados
    if ($slugsUsed.ContainsKey($slug)) {
        $counter = 2
        while ($slugsUsed.ContainsKey("$slug-$counter")) { $counter++ }
        $slug = "$slug-$counter"
    }
    $slugsUsed[$slug] = $true
    
    # colores (cada archivo = 1 color)
    $colores = @()
    $i = 0
    foreach ($f in $files) {
        $i++
        $colores += @{
            nombre = "Color $i"
            hex = "#cccccc"
            imagen = "/web/$rel/" + $f.Name.ToLower()
        }
    }
    
    $products += @{
        Nombre = $nombre
        Slug = $slug
        Categoria = $categoria
        Subtipo = $subtipo
        Precio = $precio
        Colores = $colores
        Carpeta = $rel
    }
}
Write-Output "Productos detectados: $($products.Count)"

# === PASO 3: volcar MDs ===
Remove-Item "$mdDir\*.md" -Force -ErrorAction SilentlyContinue
$created = 0
foreach ($p in $products) {
    $yaml = ""
    foreach ($c in $p.Colores) {
        $yaml += "  - nombre: `"$($c.nombre)`"`n    hex: `"$($c.hex)`"`n    imagen: `"$($c.imagen)`"`n"
    }
    $nom = $p.Nombre -replace '"',"'"
    $subLine = if ($p.Subtipo) { "subtipo: $($p.Subtipo)`n" } else { "" }
    $md = "---`n" +
"nombre: `"$nom`"`n" +
"categoria: $($p.Categoria)`n" +
$subLine +
"coleccion: `"Coleccion 2026`"`n" +
"precio: $($p.Precio)`n" +
"destacado: false`n" +
"colores:`n" +
$yaml +
"tallas: [`"XS`", `"S`", `"M`", `"L`", `"XL`"]`n" +
"descripcion_es: |`n" +
"  $($p.Nombre) - pieza disenada en Colombia por Abril Pijamas y Lenceria. Tejidos suaves, acabados con cuidado.`n" +
"descripcion_en: |`n" +
"  $($p.Nombre) - piece designed in Colombia by Abril Pijamas and Lingerie. Soft fabrics, careful finishes.`n" +
"---`n`n" +
"# $($p.Nombre)`n`n" +
"Pieza de la Coleccion 2026 de Abril Pijamas y Lenceria. Hecha a mano en Colombia.`n"
    Set-Content "$mdDir\$($p.Slug).md" $md -Encoding utf8 -NoNewline
    $created++
}
Write-Output "MDs creados: $created"
Write-Output ""
Write-Output "=== Resumen por categoria ==="
foreach ($cat in @('pijamas','lenceria','conjuntos')) {
    $count = ($products | Where-Object { $_.Categoria -eq $cat }).Count
    Write-Output "  ${cat}: $count"
}
Write-Output ""
Write-Output "=== Resumen por subtipo ==="
$subtipos = $products | Select-Object -ExpandProperty Subtipo -Unique | Sort-Object
foreach ($s in $subtipos) {
    $c = ($products | Where-Object { $_.Subtipo -eq $s }).Count
    Write-Output "  ${s}: $c"
}
Write-Output ""
Write-Output "=== Muestra (primeros 5 productos) ==="
$products | Select-Object -First 5 | ForEach-Object {
    Write-Output "  [$($_.Categoria)/$($_.Subtipo)] $($_.Nombre) (slug=$($_.Slug), precio=$($_.Precio))"
}
