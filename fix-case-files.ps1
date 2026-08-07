# Renombrar ARCHIVOS con mayúsculas a lowercase (slugificado)
$base = "C:\Users\SAMUEL\Projects\abril-catalogo\public\web\web"
$tmpFile = "$env:TEMP\abril_filelist.txt"

cmd /c "dir /b /s /a-d `"$base`"" > $tmpFile 2>&1
$lines = Get-Content $tmpFile

$renamed = 0
$failed = 0
foreach ($line in $lines) {
    if (-not $line) { continue }
    $leaf = Split-Path $line -Leaf
    if (-not ($leaf -cmatch '[A-Z]')) { continue }
    
    $newName = $leaf.ToLower()
    $newName = [System.Text.RegularExpressions.Regex]::Replace($newName, '[^a-z0-9.\-_]', '-')
    $newName = [System.Text.RegularExpressions.Regex]::Replace($newName, '-{2,}', '-')
    $newName = $newName.Trim('-')
    # conservar extension
    if (-not ($newName -cmatch '\.(jpg|jpeg|png|webp)$')) {
        # si la regex quitó la extension, fallamos
        Write-Output "  SKIP (no ext after slug): $leaf"
        $failed++
        continue
    }
    
    if ($newName -cne $leaf) {
        if (-not (Test-Path -LiteralPath $line)) { continue }
        # Truco tmp para Windows case-insensitivity
        $parent = Split-Path $line -Parent
        $tmpName = "__TMP_" + [Guid]::NewGuid().ToString().Substring(0,8) + "__" + $leaf
        cmd /c "rename `"$line`" `"$tmpName`"" 2>&1 | Out-Null
        $tmpFull = Join-Path $parent $tmpName
        if (-not (Test-Path -LiteralPath $tmpFull)) {
            Write-Output "  FAIL step1: $leaf"
            $failed++
            continue
        }
        cmd /c "rename `"$tmpFull`" `"$newName`"" 2>&1 | Out-Null
        $expected = Join-Path $parent $newName
        if (Test-Path -LiteralPath $expected) {
            Write-Output "  OK: $leaf -> $newName"
            $renamed++
        } else {
            Write-Output "  FAIL step2: $tmpName -> $newName"
            # restore
            cmd /c "rename `"$tmpFull`" `"$leaf`"" 2>&1 | Out-Null
            $failed++
        }
    }
}
Write-Output ""
Write-Output "=== Resumen ==="
Write-Output "Renamed: $renamed"
Write-Output "Failed: $failed"
