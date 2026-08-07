# Renombrar carpetas con mayúsculas en el path
# Estrategia: buscar SOLO el último segmento con mayúsculas, shortest-first (padres primero)
$base = "C:\Users\SAMUEL\Projects\abril-catalogo\public\web\web"

function Get-DirsToRename {
    $result = @()
    $allDirs = cmd /c "dir /b /s /ad `"$base`""
    foreach ($line in $allDirs) {
        if ($line -cmatch '[A-Z]') {
            $rel = $line.Substring($base.Length + 1)
            # tomar solo el último segmento (leaf)
            $leaf = Split-Path $rel -Leaf
            if ($leaf -cmatch '[A-Z]') {
                $result += [PSCustomObject]@{ Full = (Join-Path $base $rel); Parent = (Join-Path $base (Split-Path $rel)); Rel = $rel; Leaf = $leaf }
            }
        }
    }
    return $result
}

# Iterar varias veces porque renombrar un padre cambia el path de los hijos
for ($pass = 1; $pass -le 5; $pass++) {
    Write-Output "=== Pass $pass ==="
    $targets = Get-DirsToRename | Sort-Object { $_.Rel.Length }
    if ($targets.Count -eq 0) { Write-Output "Sin carpetas por renombrar"; break }
    
    $renamedThisPass = 0
    foreach ($t in $targets) {
        $newName = $t.Leaf.ToLower()
        $newName = [System.Text.RegularExpressions.Regex]::Replace($newName, '[^a-z0-9\-_]', '-')
        $newName = [System.Text.RegularExpressions.Regex]::Replace($newName, '-{2,}', '-')
        $newName = $newName.Trim('-')
        
        if ($newName -ne $t.Leaf) {
            $tmpName = "__TMP_" + [Guid]::NewGuid().ToString().Substring(0,8) + "__"
            $r1 = cmd /c "rename `"$($t.Full)`" `"$tmpName`"" 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Output "  FAIL step1: $($t.Rel) -> $tmpName  ($r1)"
                continue
            }
            $tmpFull = Join-Path $t.Parent $tmpName
            $r2 = cmd /c "rename `"$tmpFull`" `"$newName`"" 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Output "  FAIL step2: $tmpName -> $newName  ($r2)"
                # revertir
                cmd /c "rename `"$tmpFull`" `"$($t.Leaf)`"" 2>&1 | Out-Null
            } else {
                Write-Output "  OK: $($t.Rel) -> $newName"
                $renamedThisPass++
            }
        }
    }
    Write-Output "Renamed this pass: $renamedThisPass"
    if ($renamedThisPass -eq 0) { break }
}

Write-Output ""
Write-Output "=== Top-level final ==="
cmd /c "dir /b `"$base`""
Write-Output ""
Write-Output "=== Verificar LENCERIA mayus ==="
cmd /c "dir /b /ad `"$base\lenceria`""
