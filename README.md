# Docker Image Hardening

**Trabajo 10** - Protección y Seguridad de Sistemas  
Universidad Politécnica de Madrid | Enero 2026

## Descripción

Este proyecto demuestra las diferencias de seguridad entre una imagen Docker vulnerable y una imagen Docker hardened (segura) utilizando Python/Django y escaneo de vulnerabilidades con Trivy.

## Resultados del Análisis

| Métrica | Imagen Insegura | Imagen Segura | Reducción |
|---------|-----------------|---------------|-----------|
| Tamaño | 1.22 GB | 90.4 MB | 92.6% |
| Total CVEs | 1,257 | 29 | 97.7% |
| CVEs CRITICAL | 78 | 0 | 100% |
| CVEs HIGH | 408 | 1 | 99.8% |
| CVEs MEDIUM | 530 | 9 | 98.3% |

## Estructura del Proyecto

```
docker-hardened-image/
├── app/                    # Aplicación Django
│   ├── demo/               # App con endpoints API
│   ├── hardening_demo/     # Configuración Django
│   ├── manage.py
│   └── requirements.txt
├── insecure/               # Dockerfile con malas prácticas
│   └── Dockerfile
├── secure/                 # Dockerfile hardened
│   ├── Dockerfile
│   ├── .dockerignore
│   └── seccomp-profile.json
├── scripts/                # Scripts de automatización
│   ├── build-all.ps1
│   └── scan-images.ps1
├── docs/                   # Documentación
│   └── VULNERABILITY-COMPARISON.md
├── demo/                   # Guía de demostración
├── reports/                # Reportes de Trivy (generados)
└── docker-compose.yml
```

## Requisitos

- Docker Desktop
- PowerShell

## Uso

### 1. Construir imágenes

```powershell
cd scripts
.\build-all.ps1
```

### 2. Comparar tamaños

```powershell
docker images demo-app
```

### 3. Escanear vulnerabilidades

```powershell
.\scan-images.ps1
```

Los reportes JSON se generan en la carpeta `reports/`.

### 4. Ejecutar demostración

```powershell
docker-compose up -d
```

- Aplicación insegura: http://localhost:8001
- Aplicación segura: http://localhost:8002

### 5. Verificar diferencias de seguridad

```powershell
# Usuario (insegura = root, segura = appuser)
docker exec demo-insecure whoami
docker exec demo-secure whoami

# Secretos expuestos
docker exec demo-insecure env | findstr SECRET
docker exec demo-secure env | findstr SECRET
```

## Vulnerabilidades Demostradas

| Problema | Imagen Insegura | Imagen Segura |
|----------|-----------------|---------------|
| Base image | `python:latest` (1.79 GB) | `python:3.12-alpine` (153 MB) |
| Usuario | root | UID 1001 (non-root) |
| Servidor | Django runserver | Gunicorn (producción) |
| Secretos | Hardcoded en Dockerfile | Inyectados en runtime |
| DEBUG | True | False |
| Health check | No | Sí |
| Multi-stage build | No | Sí |
| Seccomp profile | Default | Custom restrictivo |
| Network isolation | No | Sí (red interna) |
| Dependency hashes | No | Sí (SHA256) |
| AppArmor | No | docker-default |
| Logging limits | No | max-size: 10m |

## Documentación

- [Análisis de Vulnerabilidades](docs/VULNERABILITY-COMPARISON.md)
- [Guía de Demostración](demo/README.md)

## Equipo

- Víctor López Valero
- Pedro Ortiz Villanueva
- Santiago Díaz Izquierdo
- Jorge Pastor Velasco

## Referencias

- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [Docker Security Best Practices](https://docs.docker.com/develop/security-best-practices/)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [OWASP Docker Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)

