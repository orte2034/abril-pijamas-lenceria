# Renombrar carpetas con mayúsculas - versión con Get-Content desde archivo
# (cmd /c directo en PowerShell normaliza el case al capturar stdout)
$base = "C:\Users\SAMUEL\Projects\abril-catalogo\public\web\web"
$tmpFile = "$env:TEMP\abril_dirlist.txt"

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

function Get-ToFixList {
    cmd /c "dir /b /s /ad `"$base`"" > $tmpFile 2>&1
    $lines = Get-Content $tmpFile
    $list = New-Object System.Collections.ArrayList
    foreach ($line in $lines) {
        if (-not $line) { continue }
        $leaf = Split-Path $line -Leaf
        if (-not ($leaf -cmatch '[A-Z]')) { continue }
        $newName = $leaf.ToLower()
        $newName = [System.Text.RegularExpressions.Regex]::Replace($newName, '[^a-z0-9\-_]', '-')
        $newName = [System.Text.RegularExpressions.Regex]::Replace($newName, '-{2,}', '-')
        $newName = $newName.Trim('-')
        if ($newName -cne $leaf) {
            [void]$list.Add(@{ Full = $line; NewName = $newName; Leaf = $leaf })
        }
    }
    return $list
}

$pass = 0
$maxPasses = 10
while ($pass -lt $maxPasses) {
    $pass++
    Write-Output "=== Pass $pass ==="
    $toFix = Get-ToFixList
    $sorted = $toFix | Sort-Object { $_.Full.Length }
    Write-Output "  Para renombrar: $($sorted.Count)"
    if ($sorted.Count -eq 0) { Write-Output "  Listo!"; break }
    
    $count = 0
    foreach ($item in $sorted) {
        if (-not (Test-Path -LiteralPath $item.Full)) { continue }
        $ok = Invoke-RenameOne -fullPath $item.Full -newName $item.NewName
        if ($ok) { Write-Output "  OK: $($item.Leaf) -> $($item.NewName)"; $count++ }
        else { Write-Output "  FAIL: $($item.Full)" }
    }
    Write-Output "  Renamed this pass: $count"
    if ($count -eq 0) { break }
}

Write-Output ""
Write-Output "=== Estado final top-level ==="
cmd /c "dir /b `"$base`""
Write-Output ""
Write-Output "=== lenceria/ ==="
cmd /c "dir /b `"$base\lenceria`"" > $tmpFile 2>&1; Get-Content $tmpFile
