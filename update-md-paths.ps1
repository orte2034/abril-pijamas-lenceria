$projRoot = "C:\Users\SAMUEL\Projects\abril-catalogo"
$root = "$projRoot\public\web\web"
$mdDir = "$projRoot\src\content\products"

# 1. Construir índice de archivos reales en disco: filename (sin path) -> nueva ruta relativa
$realFiles = Get-ChildItem $root -Recurse -File
$fileIndex = @{}
foreach ($f in $realFiles) {
  $rel = $f.FullName.Replace($root + '\','').Replace('\','/')
  $name = $f.Name
  if (-not $fileIndex.ContainsKey($name)) {
    $fileIndex[$name] = $rel
  }
}
Write-Output "Archivos indexados en disco: $($fileIndex.Count)"

# 2. Procesar cada .md
$mdFiles = Get-ChildItem $mdDir -File -Filter *.md
$updated = 0
$notFound = @()

foreach ($md in $mdFiles) {
  $content = Get-Content -LiteralPath $md.FullName -Raw
  $original = $content
  $changed = $false

  # Encontrar todas las líneas de imagen: imagen: "/web/web/..."
  while ($content -match 'imagen:\s*"(/web/web/[^"]+)"') {
    $oldPath = $matches[1]
    $fileName = [System.IO.Path]::GetFileName($oldPath)

    if ($fileIndex.ContainsKey($fileName)) {
      $newPath = $fileIndex[$fileName]
      $content = $content -replace [regex]::Escape($oldPath), $newPath
      $changed = $true
    } else {
      # Intentar buscar por UUID parcial (los primeros 8 chars)
      $uuid = $fileName -replace '^.*?([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}).*$','$1'
      if ($uuid -and $uuid -ne $fileName) {
        $match = $fileIndex.Keys | Where-Object { $_ -like "*$uuid*" } | Select-Object -First 1
        if ($match) {
          $newPath = $fileIndex[$match]
          $content = $content -replace [regex]::Escape($oldPath), $newPath
          $changed = $true
        } else {
          $notFound += "$($md.Name): $oldPath (UUID: $uuid)"
        }
      } else {
        $notFound += "$($md.Name): $oldPath"
      }
    }
  }

  if ($changed) {
    Set-Content -LiteralPath $md.FullName -Value $content -Encoding utf8 -NoNewline
    $updated++
  }
}

Write-Output "=== RESULTADO ==="
Write-Output "MDs actualizados: $updated / $($mdFiles.Count)"
if ($notFound.Count -gt 0) {
  Write-Output "NO ENCONTRADOS ($($notFound.Count)):"
  $notFound | Select-Object -First 10 | ForEach-Object { Write-Output "  $_" }
}

# Verificar algunos
Write-Output "=== MUESTRA ACTUALIZADA ==="
Select-String -Path "$mdDir\*.md" -Pattern 'imagen:' | Select-Object -First 5