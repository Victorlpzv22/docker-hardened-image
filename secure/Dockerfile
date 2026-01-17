# =============================================
# DOCKERFILE SEGURO - VERSIÓN HARDENED V2
# Implementa mejoras de prioridad ALTA y MEDIA
# =============================================

# ✅ MEJORA 1: Imagen base Alpine (mínima, ~50MB)
FROM python:3.12-alpine AS builder

# ✅ MEJORA 2: Labels de seguridad OCI
LABEL org.opencontainers.image.title="Demo App Secure"
LABEL org.opencontainers.image.description="Django application with security hardening"
LABEL org.opencontainers.image.version="2.0.0"
LABEL org.opencontainers.image.vendor="UPM - Master Ciberseguridad"
LABEL org.opencontainers.image.source="https://github.com/Victorlpzv22/docker-hardened-image"
LABEL org.opencontainers.image.licenses="MIT"
LABEL security.policy="CIS-Docker-Benchmark-v1.6"
LABEL security.scan-date="2026-01"

# ✅ MEJORA: Instalar dependencias de build en Alpine
RUN apk add --no-cache \
    gcc \
    musl-dev \
    libffi-dev

# ✅ MEJORA 3: Crear virtualenv
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

WORKDIR /build

# ✅ MEJORA 4: Copiar requirements primero (cache de capas)
COPY requirements.txt .

# ✅ MEJORA 5: Instalar dependencias con verificación de hash
# --require-hashes asegura integridad de paquetes
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --no-cache-dir --require-hashes -r requirements.txt

# =============================================
# STAGE 2: Runtime (imagen final mínima)
# =============================================
FROM python:3.12-alpine AS runtime

# ✅ Labels repetidos para la imagen final
LABEL org.opencontainers.image.title="Demo App Secure"
LABEL org.opencontainers.image.version="2.0.0"
LABEL security.policy="CIS-Docker-Benchmark-v1.6"

# ✅ MEJORA 6: Usuario no-root con UID/GID numérico
# Más seguro que nombres, evita conflictos
RUN addgroup -g 1001 -S django && \
    adduser -u 1001 -S -G django -h /app appuser

# ✅ MEJORA 7: Directorio de trabajo con permisos correctos
WORKDIR /app
RUN chown appuser:django /app

# ✅ MEJORA 8: Copiar virtualenv desde builder
COPY --from=builder --chown=1001:1001 /opt/venv /opt/venv

# ✅ MEJORA 9: Copiar código con permisos correctos
COPY --chown=1001:1001 . .

# ✅ MEJORA 10: Usar el virtualenv
ENV PATH="/opt/venv/bin:$PATH"

# ✅ MEJORA 11: Variables de entorno seguras
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV DJANGO_SETTINGS_MODULE=hardening_demo.settings
ENV DEBUG=False
ENV ALLOWED_HOSTS=localhost,127.0.0.1

# ✅ MEJORA 12: Cambiar a usuario no-root (por UID)
USER 1001:1001

# ✅ MEJORA 13: Puerto no privilegiado
EXPOSE 8000

# ✅ MEJORA 14: Health check para monitoreo
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health/')" || exit 1

# ✅ MEJORA 15: STOPSIGNAL para graceful shutdown
STOPSIGNAL SIGTERM

# ✅ MEJORA 16: Gunicorn con configuración de producción
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "2", "--timeout", "30", "hardening_demo.wsgi:application"]
