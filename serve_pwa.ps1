# Script para servir la PWA localmente
Write-Host "🚀 Sirviendo PWA del Calendario Familiar..." -ForegroundColor Green
Write-Host "📁 Directorio: build/web" -ForegroundColor Yellow
Write-Host "🌐 URL: http://localhost:8000" -ForegroundColor Cyan
Write-Host ""

# Navegar al directorio build/web
Set-Location "build/web"

# Crear un servidor HTTP simple usando PowerShell
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:8000/")
$listener.Start()

Write-Host "✅ Servidor iniciado en http://localhost:8000" -ForegroundColor Green
Write-Host "📱 Abre tu navegador y ve a la URL anterior" -ForegroundColor Yellow
Write-Host "🛑 Presiona Ctrl+C para detener el servidor" -ForegroundColor Red
Write-Host ""

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        $localPath = $request.Url.LocalPath
        if ($localPath -eq "/") {
            $localPath = "/index.html"
        }
        
        $filePath = Join-Path (Get-Location) $localPath.TrimStart("/")
        
        if (Test-Path $filePath -PathType Leaf) {
            $content = [System.IO.File]::ReadAllBytes($filePath)
            $response.ContentLength64 = $content.Length
            $response.OutputStream.Write($content, 0, $content.Length)
        } else {
            $response.StatusCode = 404
            $notFound = [System.Text.Encoding]::UTF8.GetBytes("404 - Archivo no encontrado")
            $response.OutputStream.Write($notFound, 0, $notFound.Length)
        }
        
        $response.Close()
    }
} finally {
    $listener.Stop()
    Write-Host "🛑 Servidor detenido" -ForegroundColor Red
}
