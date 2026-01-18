#!/bin/bash
# ================================================================
# Script para construir ambas imágenes Docker
# ================================================================

set -e

echo "=========================================="
echo "  Docker Hardening Demo - Build Script"
echo "=========================================="

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Directorio base
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${YELLOW}📁 Directorio del proyecto: $PROJECT_DIR${NC}"

# Desactivar BuildKit para compatibilidad
export DOCKER_BUILDKIT=0
echo -e "${YELLOW}⚙️  BuildKit desactivado para compatibilidad${NC}"

# Construir imagen INSEGURA
echo ""
echo -e "${RED}🔓 Construyendo imagen INSEGURA...${NC}"
docker build \
    -t demo-app:insecure \
    -f "$PROJECT_DIR/insecure/Dockerfile" \
    "$PROJECT_DIR"

echo -e "${RED}✅ Imagen insegura construida: demo-app:insecure${NC}"

# Construir imagen SEGURA
echo ""
echo -e "${GREEN}🔒 Construyendo imagen SEGURA...${NC}"

# Intentar con BuildKit primero
echo -e "${YELLOW}⚙️  Intentando build con BuildKit...${NC}"
export DOCKER_BUILDKIT=1
if docker build \
    -t demo-app:secure \
    -f "$PROJECT_DIR/secure/Dockerfile" \
    "$PROJECT_DIR" 2>/dev/null; then
    echo -e "${GREEN}✅ Imagen segura construida con BuildKit: demo-app:secure${NC}"
else
    echo -e "${YELLOW}⚠️  BuildKit falló, reintentando sin BuildKit...${NC}"
    export DOCKER_BUILDKIT=0
    docker build \
        -t demo-app:secure \
        -f "$PROJECT_DIR/secure/Dockerfile" \
        "$PROJECT_DIR"
    echo -e "${GREEN}✅ Imagen segura construida sin BuildKit: demo-app:secure${NC}"
fi

# Mostrar tamaños
echo ""
echo "=========================================="
echo "  📊 Comparación de tamaños"
echo "=========================================="
docker images demo-app --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"

echo ""
echo -e "${GREEN}✅ Build completado exitosamente${NC}"
