# ================================================================
# DOCKERFILE SEGURO - MEJORES PRÁCTICAS DE HARDENING (Python/Django)
# ================================================================
# Este Dockerfile implementa las mejores prácticas de seguridad
# para contenedores Docker con aplicaciones Python/Django.
# ================================================================

# ============================================================
# STAGE 1: Builder - Compilación y dependencias
# ============================================================
# ✅ MEJORA 1: Multi-stage build para reducir tamaño final
FROM python:3.12-slim-bookworm AS builder

# ✅ MEJORA 2: Versión específica y imagen slim (mínima)
# slim-bookworm es ~150MB vs ~1GB de python:latest

WORKDIR /app

# ✅ MEJORA 3: Copiar solo requirements primero (cache optimization)
COPY requirements.txt .

# ✅ MEJORA 4: Crear virtualenv e instalar dependencias
# --no-cache-dir reduce el tamaño de la imagen
RUN python -m venv /opt/venv && \
    /opt/venv/bin/pip install --no-cache-dir --upgrade pip && \
    /opt/venv/bin/pip install --no-cache-dir -r requirements.txt

# ============================================================
# STAGE 2: Production - Imagen final mínima
# ============================================================
FROM python:3.12-slim-bookworm AS production

# ✅ MEJORA 5: Etiquetas de metadatos
LABEL maintainer="PRSS Team - Victor & Pedro"
LABEL description="Docker Hardening Demo - Secure Django Image"
LABEL version="1.0.0"

# ✅ MEJORA 6: Crear usuario no-root
# Nunca ejecutar como root en producción
RUN groupadd -g 1001 django && \
    useradd -u 1001 -g django -s /bin/false -M appuser

WORKDIR /app

# ✅ MEJORA 7: Copiar virtualenv desde builder
COPY --from=builder /opt/venv /opt/venv

# ✅ MEJORA 8: Copiar código con permisos correctos
COPY --chown=appuser:django . .

# ✅ MEJORA 9: Usar el virtualenv
ENV PATH="/opt/venv/bin:$PATH"

# ✅ MEJORA 10: Variables de entorno seguras (sin secretos)
# Los secretos se inyectan en runtime vía Docker Secrets o env vars
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV DJANGO_SETTINGS_MODULE=hardening_demo.settings
ENV DEBUG=False
ENV ALLOWED_HOSTS=localhost,127.0.0.1

# ✅ MEJORA 11: Cambiar a usuario no-root ANTES de exponer
USER appuser

# ✅ MEJORA 12: Puerto no privilegiado (>1024)
EXPOSE 8000

# ✅ MEJORA 13: Health check para monitoreo
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health/')" || exit 1

# ✅ MEJORA 14: Usar Gunicorn (servidor WSGI de producción)
# No usar el servidor de desarrollo de Django
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "2", "hardening_demo.wsgi:application"]
