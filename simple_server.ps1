# Servidor HTTP simple para Flutter Web
param(
    [string]$Port = "8000"
)

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")

Write-Host "🚀 Iniciando servidor en http://localhost:$Port" -ForegroundColor Green
Write-Host "📁 Sirviendo archivos desde: $(Get-Location)" -ForegroundColor Yellow
Write-Host "🛑 Presiona Ctrl+C para detener" -ForegroundColor Red
Write-Host ""

try {
    $listener.Start()
    
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        $localPath = $request.Url.LocalPath
        if ($localPath -eq "/") {
            $localPath = "/index.html"
        }
        
        $filePath = Join-Path (Get-Location) $localPath.TrimStart("/")
        
        Write-Host "📄 Petición: $localPath" -ForegroundColor Cyan
        
        if (Test-Path $filePath -PathType Leaf) {
            $content = [System.IO.File]::ReadAllBytes($filePath)
            $response.ContentLength64 = $content.Length
            
            # Configurar MIME types
            $extension = [System.IO.Path]::GetExtension($filePath)
            switch ($extension) {
                ".html" { $response.ContentType = "text/html" }
                ".js" { $response.ContentType = "application/javascript" }
                ".css" { $response.ContentType = "text/css" }
                ".json" { $response.ContentType = "application/json" }
                ".png" { $response.ContentType = "image/png" }
                ".jpg" { $response.ContentType = "image/jpeg" }
                ".ico" { $response.ContentType = "image/x-icon" }
                default { $response.ContentType = "application/octet-stream" }
            }
            
            $response.OutputStream.Write($content, 0, $content.Length)
            Write-Host "✅ 200 OK" -ForegroundColor Green
        } else {
            $response.StatusCode = 404
            $notFound = [System.Text.Encoding]::UTF8.GetBytes("404 - Archivo no encontrado: $localPath")
            $response.OutputStream.Write($notFound, 0, $notFound.Length)
            Write-Host "❌ 404 Not Found" -ForegroundColor Red
        }
        
        $response.Close()
    }
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
} finally {
    if ($listener) {
        $listener.Stop()
        Write-Host "🛑 Servidor detenido" -ForegroundColor Red
    }
}
