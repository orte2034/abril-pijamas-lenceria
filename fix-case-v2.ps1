# Renombrar las carpetas que aún quedan en mayúsculas
# Estrategia: cmd /c rename with TEMP intermediate (forzar case en Windows)
$base = "C:\Users\SAMUEL\Projects\abril-catalogo\public\web\web"

# Lista de carpetas a arreglar (paths relativos desde $base, con el nombre ACTUAL en mayus)
# La idea: por cada path, hacer rename -> __TMP__ -> lowercase
$pending = @(
    "PIJAMAS"
    "PIJAMAS\BOBITO"  
    "PIJAMAS\ENTERIZOS"
    "PIJAMAS\NUEVO"
    "lenceria\BABYDOLL"
    "lenceria\BODYS"
    "lenceria\LENCERIA"
    "lenceria\LENCERIA\NUEVO"
    "conjunto-pantalon-burda\ENTERIZOS"
    "conjunto-pantalon-burda\ENTERIZOS\ENTERIZOS"
)

# Primero identificar dinámicamente TODAS las carpetas con mayúsculas en el path
$allDirs = cmd /c "dir /b /s /ad `"$base`""
$upperDirs = @()
foreach ($line in $allDirs) {
    if ($line -match '[A-Z]') {
        # path relativo
        $rel = $line.Substring($base.Length + 1)
        $upperDirs += $rel
    }
}

Write-Output "Carpetas con mayusculas encontradas: $($upperDirs.Count)"
$upperDirs | Select-Object -First 10

# Ordenar de MAS profundo a MENOS profundo (longitud desc) para renombrar hojas primero
$upperDirsSorted = $upperDirs | Sort-Object { $_.Length } -Descending

foreach ($rel in $upperDirsSorted) {
    $full = Join-Path $base $rel
    $parent = Split-Path $full -Parent
    $name = Split-Path $full -Leaf
    $newName = $name.ToLower()
    # slugify
    $newName = [System.Text.RegularExpressions.Regex]::Replace($newName, '[^a-z0-9\-_]', '-')
    $newName = [System.Text.RegularExpressions.Regex]::Replace($newName, '-{2,}', '-')
    $newName = $newName.Trim('-')
    
    if ($newName -ne $name) {
        $tmpName = "__TMP_" + [Guid]::NewGuid().ToString().Substring(0,8) + "__"
        # rename a tmp
        $r1 = cmd /c "rename `"$full`" `"$tmpName`"" 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Output "FAIL step1: $rel -> $tmpName  ($r1)"
            continue
        }
        # rename a final
        $tmpFull = Join-Path $parent $tmpName
        $r2 = cmd /c "rename `"$tmpFull`" `"$newName`"" 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Output "FAIL step2: $tmpName -> $newName  ($r2)"
        } else {
            Write-Output "OK: $rel -> $newName"
        }
    }
}

Write-Output ""
Write-Output "=== Estado final top-level ==="
cmd /c "dir /b `"$base`""
