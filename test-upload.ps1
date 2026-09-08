$headers = @{
    Authorization = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNnbWhjYmNvb3ZiYWRzZmptb2VuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg3MjEyMjQsImV4cCI6MjEwNDI5NzIyNH0.iyc1G1izwBkUVUVDJanuRN8vIximJw21GWyqrEVpslA"
    apikey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNnbWhjYmNvb3ZiYWRzZmptb2VuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg3MjEyMjQsImV4cCI6MjEwNDI5NzIyNH0.iyc1G1izwBkUVUVDJanuRN8vIximJw21GWyqrEVpslA"
}

# Crear archivo de prueba
$testContent = "test"
$bytes = [System.Text.Encoding]::UTF8.GetBytes($testContent)

try {
    $url = "https://cgmhcbcoovbadsfjmoen.supabase.co/storage/v1/object/producto-imagenes/test.txt"
    $result = Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body $bytes -ContentType "text/plain"
    Write-Host "Upload OK: $($result.Key)" -ForegroundColor Green
    
    # Verificar que se puede leer
    $readUrl = "https://cgmhcbcoovbadsfjmoen.supabase.co/storage/v1/object/public/producto-imagenes/test.txt"
    $read = Invoke-RestMethod -Uri $readUrl -Method Get
    Write-Host "Public read OK: $read" -ForegroundColor Green
    
    # Limpiar
    Invoke-RestMethod -Uri "https://cgmhcbcoovbadsfjmoen.supabase.co/storage/v1/object/producto-imagenes/test.txt" -Headers $headers -Method Delete
    Write-Host "Test limpio" -ForegroundColor Cyan
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails) { Write-Host "Details: $($_.ErrorDetails.Message)" }
}