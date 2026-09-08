$headers = @{
    Authorization = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNnbWhjYmNvb3ZiYWRzZmptb2VuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg3MjEyMjQsImV4cCI6MjEwNDI5NzIyNH0.iyc1G1izwBkUVUVDJanuRN8vIximJw21GWyqrEVpslA"
    apikey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNnbWhjYmNvb3ZiYWRzZmptb2VuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg3MjEyMjQsImV4cCI6MjEwNDI5NzIyNH0.iyc1G1izwBkUVUVDJanuRN8vIximJw21GWyqrEVpslA"
}

try {
    $buckets = Invoke-RestMethod -Uri "https://cgmhcbcoovbadsfjmoen.supabase.co/storage/v1/bucket" -Headers $headers -Method Get
    Write-Host "Buckets encontrados:" -ForegroundColor Cyan
    $buckets | ForEach-Object { 
        Write-Host "  - $($_.name) (public: $($_.public), id: $($_.id))" 
    }
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails) { Write-Host "Details: $($_.ErrorDetails.Message)" }
}