# Renombrar carpetas con mayúsculas - versión simple
$base = "C:\Users\SAMUEL\Projects\abril-catalogo\public\web\web"

function Invoke-RenameOne($fullPath, $newName) {
    $parent = Split-Path $fullPath -Parent
    $tmpName = "__TMP_" + [Guid]::NewGuid().ToString().Substring(0,8) + "__"
    $tmpFull = Join-Path $parent $tmpName
    cmd /c "rename `"$fullPath`" `"$tmpName`"" 2>&1 | Out-Null
    if (-not (Test-Path -LiteralPath $tmpFull)) { return $false }
    cmd /c "rename `"$tmpFull`" `"$newName`"" 2>&1 | Out-Null
    $expectedFinal = Join-Path $parent $newName
    return (Test-Path -LiteralPath $expectedFinal)
}

# Loop multi-pass: cada pass renombra carpetas leaf con mayúsculas, parents primero (shortest path)
$pass = 0
$maxPasses = 8
while ($pass -lt $maxPasses) {
    $pass++
    Write-Output "=== Pass $pass ==="
    
    # Listar carpetas absolutas
    $allDirs = cmd /c "dir /b /s /ad `"$base`""
    # Filtrar paths absolutos que terminan en segmento con mayus
    $toFix = New-Object System.Collections.ArrayList
    foreach ($line in $allDirs) {
        if (-not $line) { continue }
        if (-not ($line -cmatch '[A-Z]')) { continue }
        $leaf = Split-Path $line -Leaf
        if ($leaf -cmatch '[A-Z]') {
            $newName = $leaf.ToLower()
            $newName = [System.Text.RegularExpressions.Regex]::Replace($newName, '[^a-z0-9\-_]', '-')
            $newName = [System.Text.RegularExpressions.Regex]::Replace($newName, '-{2,}', '-')
            $newName = $newName.Trim('-')
            if ($newName -ne $leaf) {
                [void]$toFix.Add(@{ Full = $line; NewName = $newName; Leaf = $leaf })
            }
        }
    }
    
    # Ordenar por profundidad (path length) ASCENDING - padres primero
    $sorted = $toFix | Sort-Object { $_.Full.Length }
    Write-Output "  Para renombrar este pass: $($sorted.Count)"
    
    if ($sorted.Count -eq 0) { Write-Output "  Listo."; break }
    
    $count = 0
    foreach ($item in $sorted) {
        # Antes de renombrar, verificar que aún existe (puede haber cambiado por rename previo en el mismo pass)
        if (-not (Test-Path -LiteralPath $item.Full)) {
            continue
        }
        $ok = Invoke-RenameOne -fullPath $item.Full -newName $item.NewName
        if ($ok) {
            Write-Output "  OK: $($item.Leaf) -> $($item.NewName)"
            $count++
        } else {
            Write-Output "  FAIL: $($item.Full)"
        }
    }
    Write-Output "  Renamed: $count"
    if ($count -eq 0) { break }
}

Write-Output ""
Write-Output "=== Estado final top-level ==="
cmd /c "dir /b `"$base`""
Write-Output ""
Write-Output "=== lenceria ==="
cmd /c "dir /b `"$base\lenceria`""
