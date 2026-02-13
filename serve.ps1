$port = 8000
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
try {
    $listener.Start()
    Write-Host "Venix Sports Website is now running at: http://localhost:$port/"
    Write-Host "Press Ctrl+C to stop the server."
    
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        $path = $request.Url.LocalPath
        if ($path -eq "/") { $path = "/index.html" }
        
        # Security: Prevent directory traversal
        $path = $path.Replace("..", "")
        $fullPath = Join-Path (Get-Location) $path.TrimStart('/')
        
        if (Test-Path $fullPath -PathType Leaf) {
            $extension = [System.IO.Path]::GetExtension($fullPath).ToLower()
            $contentType = switch ($extension) {
                ".html" { "text/html" }
                ".css"  { "text/css" }
                ".js"   { "application/javascript" }
                ".jpg"  { "image/jpeg" }
                ".jpeg" { "image/jpeg" }
                ".png"  { "image/png" }
                default { "application/octet-stream" }
            }
            
            $buffer = [System.IO.File]::ReadAllBytes($fullPath)
            $response.ContentType = $contentType
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        } else {
            $response.StatusCode = 404
            $response.StatusDescription = "Not Found"
            $errorMessage = "404 - File Not Found"
            $errorBuffer = [System.Text.Encoding]::UTF8.GetBytes($errorMessage)
            $response.ContentLength64 = $errorBuffer.Length
            $response.OutputStream.Write($errorBuffer, 0, $errorBuffer.Length)
        }
        $response.Close()
    }
} catch {
    Write-Error "Failed to start server: $_"
} finally {
    $listener.Stop()
}
