# ================================================================
# Script para escanear imágenes con Trivy y generar informes
# ================================================================

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Docker Hardening Demo - Trivy Scanner" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

$ProjectDir = Split-Path -Parent $PSScriptRoot
if (-not $ProjectDir) { $ProjectDir = (Get-Location).Path -replace '\\scripts$', '' }
$ReportsDir = Join-Path $ProjectDir "reports"

# Crear directorio de reportes
if (-not (Test-Path $ReportsDir)) {
    New-Item -ItemType Directory -Path $ReportsDir -Force | Out-Null
}

Write-Host "Reportes se guardaran en: $ReportsDir" -ForegroundColor Yellow

# ========================================
# Escanear imagen INSEGURA
# ========================================
Write-Host ""
Write-Host "==========================================" -ForegroundColor Red
Write-Host "  Escaneando imagen INSEGURA..." -ForegroundColor Red
Write-Host "==========================================" -ForegroundColor Red

# Reporte JSON
Write-Host "Generando reporte JSON..." -ForegroundColor Yellow
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock `
    -v "${ReportsDir}:/reports" `
    aquasec/trivy image --format json --output /reports/insecure-report.json demo-app:insecure

# Reporte tabla (texto)
Write-Host "Generando reporte de texto..." -ForegroundColor Yellow
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock `
    -v "${ReportsDir}:/reports" `
    aquasec/trivy image --severity HIGH, CRITICAL --output /reports/insecure-report.txt demo-app:insecure

Write-Host "Reportes imagen insegura generados!" -ForegroundColor Red

# ========================================
# Escanear imagen SEGURA
# ========================================
Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "  Escaneando imagen SEGURA..." -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green

# Reporte JSON
Write-Host "Generando reporte JSON..." -ForegroundColor Yellow
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock `
    -v "${ReportsDir}:/reports" `
    aquasec/trivy image --format json --output /reports/secure-report.json demo-app:secure

# Reporte tabla (texto)
Write-Host "Generando reporte de texto..." -ForegroundColor Yellow
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock `
    -v "${ReportsDir}:/reports" `
    aquasec/trivy image --severity HIGH, CRITICAL --output /reports/secure-report.txt demo-app:secure

Write-Host "Reportes imagen segura generados!" -ForegroundColor Green

# ========================================
# Resumen
# ========================================
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  REPORTES GENERADOS" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

Write-Host ""
Write-Host "Imagen INSEGURA:" -ForegroundColor Red
Write-Host "  - $ReportsDir\insecure-report.json"
Write-Host "  - $ReportsDir\insecure-report.txt"

Write-Host ""
Write-Host "Imagen SEGURA:" -ForegroundColor Green  
Write-Host "  - $ReportsDir\secure-report.json"
Write-Host "  - $ReportsDir\secure-report.txt"

Write-Host ""
Write-Host "Escaneo completado!" -ForegroundColor Green
