$root = "C:\Users\SAMUEL\Projects\abril-catalogo\public\web\web"
$mdDir = "C:\Users\SAMUEL\Projects\abril-catalogo\src\content\products"

# Index real files
$idx = @{}
Get-ChildItem $root -Recurse -File | ForEach-Object {
  $rel = $_.FullName.Replace((Get-Item $root).FullName + '\','').Replace('\','/')
  $idx[$_.Name] = $rel
}
Write-Output "Index: $($idx.Count) files"

# Process MDs
$mds = Get-ChildItem $mdDir -Filter *.md
$upd = 0
foreach ($f in $mds) {
  $c = Get-Content $f.FullName -Raw
  $orig = $c
  # Replace all imagen paths
  $c = $c -replace 'imagen: "/web/web/[^"]+"', {
    param($m)
    $old = $m.Value
    $fn = [System.IO.Path]::GetFileName(($old -split '"')[1])
    if ($idx.ContainsKey($fn)) { 'imagen: "' + $idx[$fn] + '"' } else { $old }
  }
  if ($c -ne $orig) {
    Set-Content $f.FullName $c -Encoding utf8 -NoNewline
    $upd++
  }
}
Write-Output "Updated: $upd MDs"

# Verify
Select-String -Path "$mdDir\*.md" -Pattern 'imagen:' | Select-Object -First 3