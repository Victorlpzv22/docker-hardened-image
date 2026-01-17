#!/bin/bash
# ================================================================
# Script para escanear imágenes con Trivy
# ================================================================

set -e

echo "=========================================="
echo "  Docker Hardening Demo - Trivy Scanner"
echo "=========================================="

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directorio base
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
REPORTS_DIR="$PROJECT_DIR/reports"

# Crear directorio de reportes si no existe
mkdir -p "$REPORTS_DIR"

# Verificar si Trivy está instalado
if command -v trivy &> /dev/null; then
    TRIVY_CMD="trivy"
    echo -e "${GREEN}✅ Trivy encontrado en el sistema${NC}"
else
    echo -e "${YELLOW}⚠️  Trivy no encontrado. Usando Docker para ejecutar Trivy...${NC}"
    TRIVY_CMD="docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v $REPORTS_DIR:/reports aquasec/trivy"
fi

# ========================================
# Escanear imagen INSEGURA
# ========================================
echo ""
echo -e "${RED}=========================================="
echo "  🔓 Escaneando imagen INSEGURA"
echo "==========================================${NC}"

echo -e "${YELLOW}Generando reporte en tabla...${NC}"
$TRIVY_CMD image --severity HIGH,CRITICAL demo-app:insecure

echo -e "${YELLOW}Generando reporte JSON...${NC}"
if [ "$TRIVY_CMD" = "trivy" ]; then
    trivy image --format json --output "$REPORTS_DIR/insecure-report.json" demo-app:insecure
else
    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v "$REPORTS_DIR:/reports" aquasec/trivy \
        image --format json --output /reports/insecure-report.json demo-app:insecure
fi

echo -e "${RED}📄 Reporte guardado: $REPORTS_DIR/insecure-report.json${NC}"

# ========================================
# Escanear imagen SEGURA
# ========================================
echo ""
echo -e "${GREEN}=========================================="
echo "  🔒 Escaneando imagen SEGURA"
echo "==========================================${NC}"

echo -e "${YELLOW}Generando reporte en tabla...${NC}"
$TRIVY_CMD image --severity HIGH,CRITICAL demo-app:secure

echo -e "${YELLOW}Generando reporte JSON...${NC}"
if [ "$TRIVY_CMD" = "trivy" ]; then
    trivy image --format json --output "$REPORTS_DIR/secure-report.json" demo-app:secure
else
    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v "$REPORTS_DIR:/reports" aquasec/trivy \
        image --format json --output /reports/secure-report.json demo-app:secure
fi

echo -e "${GREEN}📄 Reporte guardado: $REPORTS_DIR/secure-report.json${NC}"

# ========================================
# Resumen
# ========================================
echo ""
echo "=========================================="
echo "  📊 RESUMEN DE ESCANEO"
echo "=========================================="

# Contar vulnerabilidades (si jq está disponible)
if command -v jq &> /dev/null; then
    INSECURE_VULNS=$(jq '[.Results[].Vulnerabilities // [] | length] | add // 0' "$REPORTS_DIR/insecure-report.json")
    SECURE_VULNS=$(jq '[.Results[].Vulnerabilities // [] | length] | add // 0' "$REPORTS_DIR/secure-report.json")
    
    echo -e "${RED}🔓 Imagen Insegura: $INSECURE_VULNS vulnerabilidades${NC}"
    echo -e "${GREEN}🔒 Imagen Segura:   $SECURE_VULNS vulnerabilidades${NC}"
    echo ""
    
    DIFF=$((INSECURE_VULNS - SECURE_VULNS))
    PERCENT=$(echo "scale=1; ($DIFF / $INSECURE_VULNS) * 100" | bc 2>/dev/null || echo "N/A")
    echo -e "${BLUE}📉 Reducción: $DIFF vulnerabilidades ($PERCENT%)${NC}"
else
    echo -e "${YELLOW}⚠️  Instala 'jq' para ver resumen de vulnerabilidades${NC}"
    echo "   Los reportes JSON están disponibles en: $REPORTS_DIR/"
fi

echo ""
echo -e "${GREEN}✅ Escaneo completado${NC}"
