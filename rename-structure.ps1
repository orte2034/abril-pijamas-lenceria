$root = "C:\Users\SAMUEL\Projects\abril-catalogo\public\web\web"

function SlugifyName([string]$name) {
  $name = $name.ToLower()
  $name = $name.Normalize('FormD')
  $name = $name -replace '[\p{M}]',''
  $name = $name -replace 'ñ','n'
  $name = $name -replace '\$',''
  $name = $name -replace '[^a-z0-9._-]','-'
  $name = $name -replace '-+','-'
  $name = $name -replace '^-|-$',''
  return $name
}

# 1. Obtener TODOS los directorios (bottom-up: más profundos primero)
$allDirs = Get-ChildItem $root -Recurse -Directory | Sort-Object { $_.FullName.Length } -Descending
Write-Output "Directorios a renombrar: $($allDirs.Count)"

$dirMap = @{}  # oldFullPath -> newFullPath

foreach ($dir in $allDirs) {
  $parent = $dir.Parent.FullName
  $oldName = $dir.Name
  $newName = SlugifyName $oldName
  if ($oldName -ne $newName) {
    $oldFull = $dir.FullName
    $newFull = Join-Path $parent $newName
    # Renombrar si no existe ya
    if (-not (Test-Path $newFull)) {
      Rename-Item -LiteralPath $oldFull -NewName $newName -Force
      Write-Output "DIR: $oldName -> $newName"
    } else {
      Write-Output "DIR SKIP (existe): $oldName -> $newName"
    }
    $dirMap[$oldFull] = $newFull
  }
}

# 2. Renombrar archivos dentro de cada directorio
$allFiles = Get-ChildItem $root -Recurse -File
Write-Output "Archivos a renombrar: $($allFiles.Count)"

$fileMap = @{}  # oldRelativePath -> newRelativePath

foreach ($file in $allFiles) {
  $dir = $file.Directory
  $oldName = $file.Name
  $newName = SlugifyName $oldName
  if ($oldName -ne $newName) {
    $oldFull = $file.FullName
    $newFull = Join-Path $dir.FullName $newName
    if (-not (Test-Path $newFull)) {
      Rename-Item -LiteralPath $oldFull -NewName $newName -Force
      Write-Output "FILE: $oldName -> $newName"
    } else {
      Write-Output "FILE SKIP (existe): $oldName -> $newName"
    }
  }
  # Guardar mapping relativo desde root
  $oldRel = $file.FullName.Replace($root + '\','').Replace('\','/')
  $newRel = $oldRel  # se recalculará después
  $fileMap[$oldRel] = $newRel
}

# 3. Recalcular mappings finales (después de renombrar dirs y files)
$finalFiles = Get-ChildItem $root -Recurse -File
$finalMap = @{}
foreach ($f in $finalFiles) {
  $oldRel = $f.FullName.Replace($root + '\','').Replace('\','/')
  # El path original antes de renombrar no lo tenemos fácil, pero podemos reconstruir
  # Lo importante: ahora los paths son limpios
}

Write-Output "=== Renombrado completado ==="
Write-Output "Verificando estructura..."
Get-ChildItem $root -Recurse -File | Select-Object -First 5 | ForEach-Object {
  $rel = $_.FullName.Replace($root + '\','').Replace('\','/')
  Write-Output $rel
}