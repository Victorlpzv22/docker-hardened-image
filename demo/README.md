# 🎬 Guía de Demostración (Python/Django)

Esta guía explica cómo realizar la demostración del proyecto de Docker Hardening con Django.

## Prerrequisitos

- Docker Desktop instalado y funcionando
- Terminal/PowerShell
- Navegador web

## Paso 1: Construir las Imágenes

```powershell
cd c:\Users\victo\Documents\proteccion_info\docker-hardened-image

# Construir imagen INSEGURA
docker build -t demo-app:insecure -f insecure/Dockerfile ./app

# Construir imagen SEGURA
docker build -t demo-app:secure -f secure/Dockerfile ./app
```

## Paso 2: Comparar Tamaños

```powershell
docker images demo-app
```

**Resultado esperado:**
| REPOSITORY | TAG | SIZE |
|------------|-----|------|
| demo-app | insecure | ~1.2 GB |
| demo-app | secure | ~200 MB |

> 💡 La imagen segura es ~85% más pequeña!

## Paso 3: Escanear con Trivy

```powershell
# Escanear imagen insegura (MUCHAS vulnerabilidades)
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image demo-app:insecure

# Escanear imagen segura (POCAS vulnerabilidades)
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image demo-app:secure
```

## Paso 4: Ejecutar y Probar

```powershell
docker-compose up -d

# Probar endpoints:
# Insegura: http://localhost:8001/health/
# Segura:   http://localhost:8002/health/

# Ver logs
docker-compose logs -f
```

## Paso 5: Demostrar Diferencias

### Usuario en contenedor

```powershell
# Imagen insegura (root)
docker exec demo-insecure whoami
# Output: root

# Imagen segura (appuser)
docker exec demo-secure whoami
# Output: appuser
```

### Secretos expuestos

```powershell
# Imagen insegura (secretos visibles!)
docker exec demo-insecure env | findstr SECRET
# Output: DJANGO_SECRET_KEY=super-secret-key-hardcoded...

# Imagen segura (sin secretos)
docker exec demo-secure env | findstr SECRET
# Output: (vacío)
```

### Servidor de producción vs desarrollo

```powershell
# Imagen insegura: usa runserver (dev)
docker exec demo-insecure ps aux
# Output: python manage.py runserver

# Imagen segura: usa Gunicorn (producción)
docker exec demo-secure ps aux
# Output: gunicorn hardening_demo.wsgi
```

## Paso 6: Limpiar

```powershell
docker-compose down
docker rmi demo-app:insecure demo-app:secure
```

## Puntos Clave

1. **Tamaño**: ~85% reducción
2. **Vulnerabilidades**: Cientos vs Pocas
3. **Usuario**: root vs appuser
4. **Servidor**: Django dev vs Gunicorn
5. **Secretos**: Hardcoded vs Runtime injection
6. **Health Check**: Solo la segura lo tiene
