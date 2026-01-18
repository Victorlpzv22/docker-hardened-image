# ================================================================
# DOCKERFILE INSEGURO - EJEMPLO DE MALAS PRÁCTICAS (Python/Django)
# ================================================================
# Este Dockerfile contiene INTENCIONALMENTE malas prácticas
# de seguridad para demostrar la importancia del hardening.
# ¡NO USAR EN PRODUCCIÓN!
# ================================================================

# ❌ PROBLEMA 1: Usando versión 'latest' sin especificar
# Esto puede introducir cambios inesperados y vulnerabilidades
FROM python:latest

# ❌ PROBLEMA 2: Ejecutando todo como root (usuario por defecto)
# Si un atacante compromete la app, tiene acceso root al contenedor

# ❌ PROBLEMA 3: Secretos hardcodeados en el Dockerfile
# Estos quedan guardados en las capas de la imagen
ENV DJANGO_SECRET_KEY=super-secret-key-hardcoded-in-dockerfile
ENV DB_PASSWORD=admin123456
ENV API_KEY=sk-prod-12345-very-secret-key
ENV AWS_ACCESS_KEY=AKIAIOSFODNN7EXAMPLE
ENV AWS_SECRET_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

# ❌ PROBLEMA 4: DEBUG activado en producción
ENV DEBUG=True
ENV ALLOWED_HOSTS=*

# ❌ PROBLEMA 5: Instalando paquetes innecesarios
# Aumenta la superficie de ataque y el tamaño de la imagen
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    vim \
    nano \
    netcat-openbsd \
    telnet \
    net-tools \
    iputils-ping \
    dnsutils \
    procps \
    htop \
    gcc \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# ❌ PROBLEMA 6: Copiando TODO sin .dockerignore
# Puede incluir archivos sensibles como .git, .env, __pycache__
COPY app/ .

# ❌ PROBLEMA 7: Sin --no-cache-dir, sin hash verification
RUN pip install -r requirements.txt

# ❌ PROBLEMA 8: Sin HEALTHCHECK
# Docker no puede detectar si la aplicación está funcionando correctamente

# ❌ PROBLEMA 9: Puerto expuesto sin restricciones
EXPOSE 8000

# ❌ PROBLEMA 10: Usando servidor de desarrollo en producción
# El servidor de Django NO es adecuado para producción
CMD python manage.py runserver 0.0.0.0:8000
