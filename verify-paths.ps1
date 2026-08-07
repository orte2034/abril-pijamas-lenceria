# Verificar 1:1 correspondencia MDs ↔ archivos físicos
$root = "C:\Users\SAMUEL\Projects\abril-catalogo\public\web\web"
$mdDir = "C:\Users\SAMUEL\Projects\abril-catalogo\src\content\products"
$projectRoot = "C:\Users\SAMUEL\Projects\abril-catalogo"

# 1. Listar todos los archivos físicos (path relativo desde /web/web/)
$diskFiles = New-Object System.Collections.Generic.HashSet[string]
cmd /c "dir /b /s /a-d `"$root`"" > "$env:TEMP\abril_diskfiles.txt" 2>&1
$lines = Get-Content "$env:TEMP\abril_diskfiles.txt"
foreach ($line in $lines) {
    if (-not $line) { continue }
    $rel = $line.Substring($root.Length + 1).Replace('\','/').ToLower()
    [void]$diskFiles.Add($rel)
}
Write-Output "Archivos en disco: $($diskFiles.Count)"

# 2. Listar todas las rutas referenciadas en los MDs
$mdRefs = @()
$missing = @()
Get-ChildItem "$mdDir\*.md" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $matches = [regex]::Matches($content, 'imagen:\s*"/web/web/([^"]+)"')
    foreach ($m in $matches) {
        $ref = $m.Groups[1].Value
        $mdRefs += $ref
        if (-not ($diskFiles.Contains($ref))) {
            $missing += @{ MD = $_.Name; Ref = $ref }
        }
    }
}
Write-Output "Rutas referenciadas en MDs: $($mdRefs.Count)"
Write-Output "Referencias rotas (sin archivo): $($missing.Count)"
if ($missing.Count -gt 0) {
    Write-Output ""
    Write-Output "=== Missing files (max 20) ==="
    $missing | Select-Object -First 20 | ForEach-Object { Write-Output "  $($_.MD): /web/web/$($_.Ref)" }
}
