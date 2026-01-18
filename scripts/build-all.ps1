# ================================================================
# Script para construir ambas imágenes Docker (PowerShell)
# ================================================================

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Docker Hardening Demo - Build Script" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

$ProjectDir = Split-Path -Parent $PSScriptRoot
if (-not $ProjectDir) { $ProjectDir = Get-Location }

Write-Host "Directorio del proyecto: $ProjectDir" -ForegroundColor Yellow

# Construir imagen INSEGURA
Write-Host ""
Write-Host "==========================================" -ForegroundColor Red
Write-Host "  Construyendo imagen INSEGURA..." -ForegroundColor Red
Write-Host "==========================================" -ForegroundColor Red

docker build -t demo-app:insecure -f "$ProjectDir\insecure\Dockerfile" "$ProjectDir\app"

if ($LASTEXITCODE -eq 0) {
    Write-Host "Imagen insegura construida: demo-app:insecure" -ForegroundColor Red
}
else {
    Write-Host "ERROR: Fallo al construir imagen insegura" -ForegroundColor Red
    exit 1
}

# Construir imagen SEGURA
Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "  Construyendo imagen SEGURA..." -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green

docker build -t demo-app:secure -f "$ProjectDir\secure\Dockerfile" "$ProjectDir\app"

if ($LASTEXITCODE -eq 0) {
    Write-Host "Imagen segura construida: demo-app:secure" -ForegroundColor Green
}
else {
    Write-Host "ERROR: Fallo al construir imagen segura" -ForegroundColor Red
    exit 1
}

# Mostrar tamaños
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Comparacion de tamanos" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

docker images demo-app --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"

Write-Host ""
Write-Host "Build completado exitosamente!" -ForegroundColor Green
