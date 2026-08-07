$root = "C:\Users\SAMUEL\Projects\abril-catalogo\public\web\web"
$mdDir = "C:\Users\SAMUEL\Projects\abril-catalogo\src\content\products"
$cats = @(
  @{ Path="PIJAMAS"; Cat="pijamas"; Sub="" },
  @{ Path="LENCERIA\BABYDOLL"; Cat="lenceria"; Sub="babydoll" },
  @{ Path="LENCERIA\BODYS"; Cat="lenceria"; Sub="bodys" },
  @{ Path="LENCERIA\LENCERIA"; Cat="lenceria"; Sub="clasica" },
  @{ Path="CONJUNTO PANTALON BURDA"; Cat="conjuntos"; Sub="" },
  @{ Path="CONJUNTO SHORT ANIMADO"; Cat="conjuntos"; Sub="" }
)

function Slugify([string]$s) {
  $s = $s.ToLower().Normalize('FormD')
  $s = $s -replace '[\p{M}]','' -replace 'ñ','n' -replace '\$','' -replace '[^a-z0-9]+','-' -replace '^-+|-+$',''
  return $s
}

function GetPrecio([string]$str) {
  $m = [regex]::Match($str, '\$\s*([\d]+(?:[.,]\d+)*)')
  if (-not $m.Success) { return 0 }
  $raw = $m.Groups[1].Value
  $parts = $raw -split '[.,]'
  if ($parts.Count -eq 1) { return [int]$parts[0] }
  if ($parts[1].Length -eq 3) { return [int]($parts[0] + $parts[1]) }
  $val = [int]($parts[0] + $parts[1])
  while ($val -lt 10000 -and $val -gt 0) { $val *= 10 }
  return $val
}

# Index real files
$fileIndex = @{}
Get-ChildItem $root -Recurse -File | ForEach-Object {
  $rel = $_.FullName.Replace((Get-Item $root).FullName + '\','').Replace('\','/').ToLower()
  $fileIndex[$_.Name] = $rel
}
Write-Output "Index: $($fileIndex.Count) files"

# Scan
$products = @()
$script:counter = 0

function ScanDir([string]$path,[string]$cat,[string]$sub) {
  $item = Get-Item -LiteralPath $path
  $nombre = $item.Name
  $precio = GetPrecio $nombre
  $fotos = @(Get-ChildItem -LiteralPath $path -File -Include *.jpg,*.jpeg,*.png)
  $subs = @(Get-ChildItem -LiteralPath $path -Directory)
  if ($precio -gt 0 -and $fotos.Count -gt 0) {
    $script:counter++
    $nombreLegible = ($nombre -replace '\s*\$[\d\.,]+\s*',' ' -replace '\s+',' ').Trim()
    $slug = Slugify $nombreLegible
    if (-not $slug -or $slug.Length -lt 3) { $slug = "producto-$($script:counter)" }
    $colores = @()
    for ($i=0; $i -lt $fotos.Count; $i++) {
      $fn = $fotos[$i].Name
      $rel = if ($fileIndex.ContainsKey($fn)) { "/web/web/" + $fileIndex[$fn] } else { "" }
      $colores += @{ nombre = if ($fotos.Count -eq 1) { "Color 1" } else { "Color $($i+1)" }; hex = "#cccccc"; imagen = $rel }
    }
    $script:products += @{ Nombre=$nombreLegible; Slug=$slug; Categoria=$cat; Subtipo=$sub; Precio=$precio; Colores=$colores }
    return
  }
  foreach ($s in $subs) { ScanDir $s.FullName $cat $sub }
}

foreach ($e in $cats) {
  $p = Join-Path $root $e.Path
  if (Test-Path -LiteralPath $p) { ScanDir $p $e.Cat $e.Sub }
}

Write-Output "Productos: $($products.Count)"

# Regenerate MDs
Remove-Item "$mdDir\*.md" -Force -ErrorAction SilentlyContinue
foreach ($p in $products) {
  $yaml = ""
  foreach ($c in $p.Colores) {
    $yaml += "  - nombre: `"$($c.nombre)`"`n    hex: `"$($c.hex)`"`n    imagen: `"$($c.imagen)`"`n"
  }
  $nom = $p.Nombre -replace '"',"'"
  $md = @"
---
nombre: "$nom"
categoria: $($p.Categoria)
$(if ($p.Subtipo) { "subtipo: $($p.Subtipo)" })
coleccion: "Coleccion 2026"
precio: $($p.Precio)
destacado: false
colores:
$yaml
tallas: ["XS", "S", "M", "L", "XL"]
descripcion_es: |
  $($p.Nombre) - pieza disenada en Colombia por Abril Pijamas y Lenceria. Tejidos suaves, acabados con cuidado.
descripcion_en: |
  $($p.Nombre) - piece designed in Colombia by Abril Pijamas and Lingerie. Soft fabrics, careful finishes.
---

# $($p.Nombre)

Pieza de la Coleccion 2026 de Abril Pijamas y Lenceria. Hecha a mano en Colombia.
"@
  Set-Content "$mdDir\$($p.Slug).md" $md -Encoding utf8 -NoNewline
}
Write-Output "MDs creados: $($products.Count)"
Select-String -Path "$mdDir\*.md" -Pattern 'imagen:' | Select-Object -First 5