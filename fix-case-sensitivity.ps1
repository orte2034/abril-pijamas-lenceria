# Renombrar TODAS las carpetas y archivos en public\web\web a minúsculas (slugs limpios)
# Necesita ir de hojas hacia arriba (deepest-first) para que el rename de padres no rompa paths

$base = "C:\Users\SAMUEL\Projects\abril-catalogo\public\web\web"

# 1. Renombrar archivos primero (deepest first)
$files = Get-ChildItem -Path $base -Recurse -File | Sort-Object { $_.FullName.Length } -Descending
$filesRenamed = 0
foreach ($f in $files) {
    $newName = $f.Name.ToLower()
    # Solo caracteres seguros para rutas web: a-z 0-9 . - _
    $newName = [System.Text.RegularExpressions.Regex]::Replace($newName, '[^a-z0-9.\-_]', '-')
    $newName = [System.Text.RegularExpressions.Regex]::Replace($newName, '-{2,}', '-')
    $newName = $newName.Trim('-')
    # Restaurar extension minúscula conocida
    if ($newName -match '\.(jpg|jpeg|png|webp)$') { } else {
        # mantener extension original (ya lower)
    }
    if ($newName -ne $f.Name) {
        $newPath = [System.IO.Path]::Combine($f.DirectoryName, $newName)
        # Truco: rename via cmd para evitar normalizacion PS
        $parent = $f.DirectoryName
        cmd /c "rename `"$($f.FullName)`" `"$newName`"" 2>&1 | Out-Null
        $filesRenamed++
    }
}
Write-Output "Archivos renombrados: $filesRenamed"

# 2. Renombrar carpetas (deepest first) con truco temporal para forzar case
$dirs = Get-ChildItem -Path $base -Recurse -Directory | Sort-Object { $_.FullName.Length } -Descending
$dirsRenamed = 0
foreach ($d in $dirs) {
    $newName = $d.Name.ToLower()
    $newName = [System.Text.RegularExpressions.Regex]::Replace($newName, '[^a-z0-9\-_]', '-')
    $newName = [System.Text.RegularExpressions.Regex]::Replace($newName, '-{2,}', '-')
    $newName = $newName.Trim('-')
    if ($newName -ne $d.Name) {
        $parent = $d.Parent.FullName
        $tmpName = $newName + "__TMP_RENAME__"
        # rename a tmp, luego a su nombre final (truco windows case)
        cmd /c "rename `"$($d.FullName)`" `"$tmpName`"" 2>&1 | Out-Null
        cmd /c "rename `"$parent\$tmpName`" `"$newName`"" 2>&1 | Out-Null
        $dirsRenamed++
    }
}
Write-Output "Carpetas renombradas: $dirsRenamed"

Write-Output "=== Estado final top-level ==="
cmd /c "dir /b $base"
