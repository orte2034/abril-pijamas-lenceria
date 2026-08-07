$root = "C:\Users\SAMUEL\Projects\abril-catalogo\public\web\web"
$mdDir = "C:\Users\SAMUEL\Projects\abril-catalogo\src\content\products"

# 1. Index folder -> files
$folderFiles = @{}
Get-ChildItem $root -Recurse -File | ForEach-Object {
  $folder = $_.Directory.FullName.Replace((Get-Item $root).FullName + '\','').Replace('\','/').ToLower()
  if (-not $folderFiles.ContainsKey($folder)) { $folderFiles[$folder] = @() }
  $folderFiles[$folder] += $_.FullName.Replace((Get-Item $root).FullName + '\','').Replace('\','/').ToLower()
}

# 2. Load 84 MDs metadata
$products = @()
Get-ChildItem "C:\Users\SAMUEL\Projects\abril-catalogo\src\content\products" -Filter *.md | ForEach-Object {
  $c = Get-Content $_.FullName -Raw
  $nombre = [regex]::Match($c, 'nombre:\s*"([^"]+)"').Groups[1].Value
  $cat = [regex]::Match($c, 'categoria:\s*(\w+)').Groups[1].Value
  $sub = [regex]::Match($c, 'subtipo:\s*(\w+)').Groups[1].Value
  $precio = [regex]::Match($c, 'precio:\s*(\d+)').Groups[1].Value
  $slug = $_.BaseName
  if ($nombre -and $cat -and $precio) {
    $keywords = $_.BaseName -split '-' | Where-Object { $_ -and $_.Length -gt 2 }
    $bestFolder = $null; $bestScore = 0
    foreach ($folder in $folderFiles.Keys) {
      $score = 0
      foreach ($k in $keywords) { if ($folder -like "*$k*") { $score++ } }
      if ($score -gt $bestScore) { $bestScore = $score; $bestFolder = $folder }
    }
    if ($bestFolder -and $bestScore -gt 0) {
      $files = $folderFiles[$bestFolder]
      $colores = @()
      for ($i=0; $i -lt $files.Count; $i++) {
        $colores += @{ nombre = if ($files.Count -eq 1) { "Color 1" } else { "Color $($i+1)" }; hex = "#cccccc"; imagen = "/web/web/" + $files[$i] }
      }
      $script:finalProducts += @{ 
        Nombre = [regex]::Match($c, 'nombre:\s*"([^"]+)"').Groups[1].Value
        Slug = $slug
        Categoria = $cat
        Subtipo = $sub
        Precio = [int]$precio
        Colores = $colores
      }
    }
  }
}

# 3. Regenerate MDs
$finalProducts = $script:finalProducts
Remove-Item "$mdDir\*.md" -Force -ErrorAction SilentlyContinue
foreach ($p in $finalProducts) {
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
Write-Output "MDs regenerados: $($finalProducts.Count)"
Select-String -Path "$mdDir\*.md" -Pattern 'imagen:' | Select-Object -First 5