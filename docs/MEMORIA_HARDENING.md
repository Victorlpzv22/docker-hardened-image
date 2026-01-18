# Memoria Técnica: Hardening de Contenedores Docker

**Proyecto**: Protección de la Información - Máster Ciberseguridad UPM
**Fecha**: Enero 2026
**Autor**: Equipo de Desarrollo Seguro

---

# Capítulo 1: Introducción y Análisis del Estado Inseguro

## 1.1 Introducción y Contexto

En el ecosistema actual de despliegue de software, la contenedorización mediante Docker se ha convertido en el estándar de facto por su portabilidad y eficiencia. Sin embargo, esta adopción masiva a menudo ignora los principios de seguridad básicos, resultando en entornos de producción que exponen superficies de ataque innecesariamente amplias.

El objetivo de este proyecto no es simplemente configurar un contenedor, sino documentar el **viaje técnico** desde una implementación "funcional pero negligente" hacia una arquitectura "robusta y auditada". Este documento sirve como memoria de las decisiones tomadas, las vulnerabilidades mitigadas y la validación de las medidas de seguridad (hardening) aplicadas a una aplicación web Python/Django.

El alcance del trabajo abarca desde la cadena de suministro (imagen base) hasta el tiempo de ejecución (syscalls, capacidades kernel), demostrando una estrategia de defensa en profundidad.

---

## 1.2 Análisis Técnico del Estado Inicial (Inseguro)

Para establecer una línea base, partimos de una infraestructura definida en `insecure/Dockerfile` y `docker-compose.yml` (servicio `app-insecure`). A primera vista, la aplicación funciona, pero un análisis detallado revela múltiples fallos críticos de seguridad que violan el principio de "Security by Design".

A continuación, diseccionamos cada decisión arquitectónica errónea encontrada en los ficheros originales:

### 1.2.1 El Peligro de la Imagen Base (`python:latest`)
El `insecure/Dockerfile` inicia con:
```dockerfile
FROM python:latest
```
**Análisis de Riesgo**:
*   **Superficie de Ataque Masiva**: La etiqueta `latest` de Python se basa en Debian. Esta distribución incluye por defecto cientos de librerías, binarios de sistema y utilidades que la aplicación no necesita.
*   **Vulnerabilidades Heredadas**: Al ser una imagen de propósito general (“fat image”), arrastra un historial considerable de CVEs (Common Vulnerabilities and Exposures) en sus librerías base (glibc, openssl, etc.) que aumentan la carga de mantenimiento y parcheo.
*   **Imprevisibilidad**: `latest` es un objetivo móvil. Un rebuild mañana podría descargar una versión diferente del SO, introduciendo incompatibilidades o nuevos bugs sin previo aviso.

### 1.2.2 Ejecución con Privilegios de Root
En el fichero inseguro, no se define ninguna instrucción `USER`. Por defecto, Docker ejecuta los procesos como `root` (UID 0).
**Análisis de Riesgo**:
*   **Impacto de Compromiso**: Si un atacante logra explotar una vulnerabilidad en la aplicación web (ej. RCE en Django), obtendrá ejecución de código con los mismos permisos que el proceso: **root**.
*   **Escape del Contenedor**: Siendo root dentro del contenedor, el atacante tiene mayor facilidad para interactuar con el Kernel del host, manipular el sistema de archivos montado, o intentar técnicas de "container breakout" aprovechando capacidades excesivas.

### 1.2.3 Secretos Hardcodeados e Inyección Insegura
Se observaron las siguientes líneas:
```dockerfile
ENV DJANGO_SECRET_KEY=super-secret-key-hardcoded-in-dockerfile
ENV DB_PASSWORD=admin123456
ENV AWS_SECRET_KEY=wJalrXUtnFEMI...
```
**Análisis de Riesgo**:
*   **Persistencia en Capas**: Aunque se borren estos ficheros después, las instrucciones `ENV` persisten en los metadatos de la imagen. Cualquiera con acceso a la imagen (ej. `docker history` o `docker inspect`) puede leer las credenciales en texto plano.
*   **Fuga en Repositorios**: Al estar en el Dockerfile, estos secretos acaban commiteados en el control de versiones (Git), comprometiendo toda la infraestructura.

### 1.2.4 "Living off the Land": Herramientas de Hacking Preinstaladas
El Dockerfile inseguro instala explícitamente herramientas administrativas:
```dockerfile
RUN apt-get install -y curl wget vim netcat-openbsd telnet ...
```
**Análisis de Riesgo**:
*   **Facilitación de Post-Explotación**: Un atacante que logre entrar no necesita descargar malware; ya tiene todo lo necesario.
    *   `netcat`/`telnet`: Para establecer reverse shells o exfiltrar datos.
    *   `curl`/`wget`: Para descargar payloads maliciosos o scripts de minería.
    *   `gcc`: Para compilar exploits de kernel "in-situ".
En un entorno de producción inmutable, estas herramientas son innecesarias y peligrosas.

### 1.2.5 Servidor de Desarrollo en Producción
```dockerfile
CMD python manage.py runserver 0.0.0.0:8000
```
**Análisis de Riesgo**:
*   El servidor `runserver` de Django no está diseñado para manejar concurrencia ni resistir ataques de red. Es mono-hilo (por defecto) y carece de mecanismos de seguridad robustos frente a malformaciones de paquetes HTTP, siendo trivialmente vulnerable a ataques de Denegación de Servicio (DoS).

### 1.2.6 Configuración de Resources y Red (Docker Compose)
En el `docker-compose.yml`, el servicio `app-insecure` carece de límites:
*   **Network**: Usa la red por defecto o una red puente sin aislamiento, permitiendo comunicación irrestricta con otros contenedores.
*   **Recursos**: Sin límites de CPU (`cpus`) ni memoria (`memory`). Un solo contenedor comprometido (ej. minería de criptomonedas o bucle infinito) podría consumir el 100% de los recursos del host, tirando abajo toda la infraestructura (DoS por agotamiento de recursos).

---
*Fin del Capítulo 1*

# Capítulo 2: Estrategia de Hardening (Cadena de Suministro e Identidad)

Tras identificar las vulnerabilidades, la primera fase del hardening se centra en asegurar la **construcción de la imagen** (Supply Chain Security) y la **identidad del proceso** (Least Privilege). Estas medidas son fundamentales porque actúan como cimientos: si la imagen base está comprometida o el usuario es root, las capas superiores de seguridad (como firewalls o políticas de red) son mucho menos efectivas.

## 2.1 Seguridad en la Cadena de Suministro

La "Cadena de Suministro de Software" es uno de los vectores de ataque más explotados recientemente. Para mitigar riesgos de inyección de código o dependencias maliciosas, hemos implementado tres controles estrictos en `secure/Dockerfile`.

### 2.1.1 Minimización: Migración a Alpine Linux
**Cambio**: Reemplazo de `python:latest` (Debian) por `python:3.12-alpine`.

La elección de **Alpine Linux** obedece a razones de seguridad, no solo de rendimiento:
*   **Reducción de Superficie**: Alpine utiliza `musl libc` y `busybox`, eliminando miles de binarios innecesarios (como `systemd`, `bash`, `curl`) que existen en Debian. Esto reduce drásticamente el espacio operativo para un atacante ("Living off the Land").
*   **Gestión de Vulnerabilidades**: Al tener menos componentes, la frecuencia de CVEs críticos es significativamente menor.
*   **Eficiencia**: La imagen base pasa de ~1GB a ~50MB, facilitando escaneos de seguridad más rápidos y despliegues ágiles.

### 2.1.2 Integridad: Verificación de Hashes en Dependencias
**Cambio**: Uso de `pip install --require-hashes` y `requirements.txt` con hashes SHA-256.

En el entorno inseguro, `pip install -r requirements.txt` simplemente descargaba la última versión compatible desde PyPI. Esto es vulnerable a ataques de:
*   **Dependency Confusion**: Un atacante sube un paquete malicioso con el mismo nombre a un repositorio público.
*   **Compromiso de PyPI**: Si la cuenta de un mantenedor de una librería legítima (ej. `Django`) es comprometida, podría subir una versión con malware.

**Implementación**:
En `app/requirements.txt`, cada paquete está "bloqueado" criptográficamente:
```text
Django==4.2.9 \
    --hash=sha256:2cc2fc7d1708ada170ddd6c99f35cc25db664f165d3794bc7723f46b2f8c8984
```
En `secure/Dockerfile` (Línea 38), forzamos esta verificación:
```dockerfile
RUN pip install --no-cache-dir --require-hashes -r requirements.txt
```
Si un solo bit del paquete descargado difiere del hash esperado, la construcción de la imagen falla inmediatamente, previniendo la infección.

### 2.1.3 Arquitectura: Multi-stage Builds
**Cambio**: Separación en etapas `builder` y `runtime`.

Para compilar algunas dependencias de Python, necesitamos herramientas como `gcc`, `musl-dev` y `libffi-dev`. Sin embargo, estas herramientas **jamás** deben estar en producción, ya que permiten a un atacante compilar exploits dentro del contenedor.

**Implementación**:
1.  **Etapa Builder**: Instala compiladores y construye el entorno virtual (`/opt/venv`).
2.  **Etapa Runtime**: Copia *solo* el entorno virtual desde la etapa anterior.

El resultado es una imagen final "estéril", sin capacidad de compilación.

### 2.1.4 Trazabilidad y Compliance: Etiquetas OCI
**Cambio**: Estandarización de metadatos con `LABEL`.

Una imagen segura debe ser auditable. En `secure/Dockerfile` hemos implementado el estándar **Open Container Initiative (OCI)** para etiquetado. Esto permite a herramientas de inventario y escáneres de seguridad identificar el origen y la política de la imagen sin necesidad de analizarla.

```dockerfile
LABEL org.opencontainers.image.source="https://github.com/Victorlpzv22/docker-hardened-image"
LABEL security.policy="CIS-Docker-Benchmark-v1.6"
```
Declarar la política de seguridad (`security.policy`) facilita la auditoría automatizada, asegurando que la imagen cumple con los estándares definidos por el CIS (Center for Internet Security).

---

## 2.2 Gestión de Identidad y Mínimos Privilegios

La ejecución como root es el "pecado original" de los contenedores. Para remediarlo, hemos definido una identidad estricta.

### 2.2.1 Creación de Usuario Dedicado
En lugar de depender de usuarios del sistema, creamos uno específico en el Dockerfile:
```dockerfile
RUN addgroup -g 1001 -S django && \
    adduser -u 1001 -S -G django -h /app appuser
```
*   **UID 1001**: Usamos un ID numérico alto para evitar colisiones con usuarios del host y asegurar consistencia entre despliegues (Kubernetes, etc.).
*   **Sin Shell**: El usuario se crea sin shell de login, dificultando la interacción interactiva.

### 2.2.2 Asignación de Permisos y Ejecución
El cambio de contexto es explícito al final del Dockerfile:
```dockerfile
USER 1001:1001
```
A partir de esta línea, cualquier instrucción (y el propio `CMD`) se ejecuta con privilegios limitados. Esto significa que procesos críticos (como abrir puertos < 1024 o modificar `/etc`) están prohibidos por diseño a nivel de sistema operativo.

---
*Fin del Capítulo 2*

# Capítulo 3: Hardening del Runtime (Aislamiento en Ejecución)

Una vez asegurada la imagen, el siguiente anillo de seguridad es el **Runtime**. Aquí es donde Docker interactúa con el Kernel de Linux. El objetivo es aislar el contenedor para que, incluso si un atacante logra ejecución remota de código (RCE), se encuentre en una "jaula" sin herramientas ni permisos para moverse lateralmente.

Esta fase se implementa íntegramente en la configuración del servicio `app-secure` dentro de `docker-compose.yml`.

## 3.1 Seccomp: Firewall de Syscalls
El Kernel de Linux expone más de 300 llamadas al sistema (syscalls). Una aplicación web típica usa solo una fracción pequeña.

**Implementación**:
Hemos creado un perfil personalizado (`secure/seccomp-profile.json`) que aplica una política de **Lista Blanca (Whitelist)**.
*   **Default Action**: `SCMP_ACT_ERRNO`. Por defecto, cualquier syscall *no* listada explícitamente es bloqueada.
*   **Permitidas**: Solo las necesarias para el funcionamiento de Python/Django, como `accept`, `bind`, `connect`, `read`, `write`, `epoll_wait`.

```yaml
# docker-compose.yml
security_opt:
  - seccomp:./secure/seccomp-profile.json
```
Esto neutraliza una clase entera de exploits de kernel (privilege escalation) que dependen de syscalls oscuras o poco usadas (como `keyctl` o `unshare`).

## 3.2 Linux Capabilities: Desarme del Root
Aunque el usuario `appuser` no es root, Linux divide los privilegios de superusuario en unidades llamadas "Capabilities". Por defecto, Docker mantiene algunas peligrosas como `CAP_CHOWN` o `CAP_NET_RAW`.

**Decisión Técnica**: Eliminación total.
```yaml
cap_drop:
  - ALL
```
Al hacer `DROP ALL`, despojamos al proceso de cualquier poder administrativo. El contenedor no puede:
*   Cambiar propietarios de ficheros (`chown`).
*   Manipular interfaces de red (`net_admin`).
*   Ejecutar ptrace o depurar procesos (`sys_ptrace`).

Esta es una medida de defensa en profundidad crucial: si el atacante lograra escalar a root dentro del contenedor, ese root sería impotente.

## 3.3 Inmutabilidad del Sistema de Ficheros
La persistencia es el primer objetivo de un atacante (instalar backdoors, modificar scripts de inicio).

**Implementación**:
```yaml
read_only: true
```
El sistema de archivos raíz (`/`) se monta como **Solo Lectura**. Nadie, ni siquiera root, puede escribir en disco.
*   **Prevención de Malware**: No se pueden descargar y hacer ejecutables nuevos binarios (`wget http://malware -O /bin/malware` fallará).
*   **Protección del Código**: El código fuente de la aplicación no puede ser alterado.

**Excepción Gestionada (`tmpfs`)**:
Las aplicaciones necesitan escribir ficheros temporales. Usamos un montaje en memoria RAM:
```yaml
tmpfs:
  - /tmp:noexec,nosuid,size=10m
```
*   `noexec`: Impide ejecutar binarios desde `/tmp` (clásico directorio de staging de malware).
*   `nosuid`: Impide bits de setuid.
*   `size=10m`: Evita que se llene la memoria del host.

## 3.4 Capas Adicionales de Aislamiento
*   **No New Privileges**:
    ```yaml
    security_opt:
      - no-new-privileges:true
    ```
    Impide que un proceso obtenga más privilegios que su padre mediante la ejecución de binarios `setuid`. Es una barrera efectiva contra escalada de privilegios local.

*   **AppArmor**:
    ```yaml
    security_opt:
      - apparmor:docker-default
    ```
    Utilizamos el perfil por defecto de Docker para AppArmor como red de seguridad adicional de Control de Acceso Obligatorio (MAC).

---
*Fin del Capítulo 3*

# Capítulo 4: Infraestructura y Validación de Resultados

La seguridad no termina en el contenedor. El orquestador (Docker Compose) debe garantizar que un servicio comprometido no pueda afectar a la disponibilidad del host ni moverse lateralmente hacia otros servicios (bases de datos, APIs internas).

## 4.1 Infraestructura Segura (Orquestador)

### 4.1.1 Segmentación de Red
En el diseño inseguro, todos los servicios compartían la red `default`.
**Implementación**:
Hemos definido dos redes aisladas:
1.  **Externa (`external`)**: Única red expuesta al host/internet. El balanceador de carga o proxy inverso residiría aquí.
2.  **Interna (`internal`)**: Red privada para backend y base de datos con `internal: true`.

```yaml
networks:
  internal:
    internal: true  # Sin acceso a internet
    driver_opts:
      com.docker.network.bridge.enable_ip_masquerade: "false"
```
Esto impide que malware dentro de la red interna pueda "llamar a casa" (C2 servers) para descargar payloads o exfiltrar datos.

### 4.1.2 Prevención de Denegación de Servicio (DoS)
Un ataque común es saturar la CPU o Memoria para colgar el servidor.
**Implementación**:
Límites duros en `docker-compose.yml`:
```yaml
deploy:
  resources:
    limits:
      cpus: '0.5'     # Max 50% de un núcleo
      memory: 128M    # Max 128MB RAM
```
Si el proceso intenta exceder estos valores, el Kernel lo estrangula (CPU) o lo mata (OOM Killer para memoria), salvaguardando la estabilidad del host.

Adicionalmente, hemos configurado **reservas** (`reservations`) para garantizar la disponibilidad del servicio incluso en condiciones de carga alta en el host:
```yaml
        reservations:
          cpus: '0.1'     # Garantiza mínimo 10% de CPU
          memory: 64M     # Garantiza mínimo 64MB RAM
```
Esto previene que otros contenedores o procesos del sistema "roben" recursos vitales para el funcionamiento base de nuestra aplicación (evitando el problema del "Noisy Neighbor").

### 4.1.3 Logging Seguro
Logs infinitos pueden llenar el disco duro del servidor (`Disk Exhaustion`).
**Implementación**:
```yaml
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```
Activación de rotación de logs: máximo 3 ficheros de 10MB.

## 4.2 Servidor de Aplicación
Abandonamos el servidor de desarrollo (`runserver`) por **Gunicorn**, configurado para producción.
*   **Workers**: Gestión eficiente de concurrencia.
*   **Healthcheck**: Monitorización proactiva (`HEALTHCHECK CMD python ...`).

Además, hemos configurado explícitamente el **Graceful Shutdown**:
```dockerfile
STOPSIGNAL SIGTERM
```
Gunicorn/Django requieren `SIGTERM` para cerrar conexiones a base de datos y terminar peticiones en curso ordenadamente. Por defecto, algunos orquestadores podrían enviar señales que la aplicación no maneja correctamente, llevando a pérdida de datos o corrupción de transacciones. Con esta directiva, garantizamos la integridad de los datos durante reinicios o despliegues.

---

## 4.3 Validación y Resultados Comparativos

Para validar objetivamente la mejora, sometimos ambas imágenes (`insecure` y `secure`) a un análisis estático de vulnerabilidades utilizando **Trivy v0.68**.

### 4.3.1 Métricas de Reducción de Vulnerabilidades
Los resultados son contundentes. Hemos pasado de un sistema con **1,257 vulnerabilidades conocidas** a uno con solo **29**, reduciendo la superficie de ataque en un **97.7%**.

| Métrica | Imagen Insegura | Imagen Segura | Mejora |
|:--- |:--- |:--- |:--- |
| **Tamaño Imagen** | 1.22 GB | 90.4 MB | **Reducción 92.6%** |
| **Total CVEs** | 1,257 | 29 | **Reducción 97.7%** |
| **CRITICAS** | 78 | 0 | **Reducción 100%** |
| **ALTAS** | 408 | 1 | **Reducción 99.8%** |

*> La imagen segura ha logrado eliminar **todas** las vulnerabilidades críticas, un hito importante para la seguridad del proyecto.*

### 4.3.2 Interpretación de Seguridad
1.  **Eliminación de Vectores de SO**: Al usar Alpine, hemos eliminado más de 800 vulnerabilidades de nivel BAJO/MEDIO asociadas a librerías de Debian no usadas (`libperl`, `bash`, etc.).
2.  **Mitigación de Explosión**: Incluso si las vulnerabilidades restantes fueran explotadas, el atacante se encontraría con un sistema de archivos de solo lectura y sin herramientas (`curl`/`sh` restringido), haciendo la post-explotación extremadamente difícil.

---
*Fin del Capítulo 4*

# Capítulo 5: Conclusiones y Próximos Pasos

## 5.1 Conclusión Final
Este proyecto demuestra que la seguridad en contenedores no es un estado binario ("seguro/inseguro"), sino un proceso continuo de capas defensivas. Hemos transformado una aplicación vulnerable en una arquitectura robusta mediante:
1.  **Minimización**: Imagen base Alpine de 50MB (vs 1.2GB).
2.  **Identidad**: Usuario no-root estricto y eliminación de Capabilities.
3.  **Aislamiento**: Runtime blindado con Seccomp y Read-only Filesystem.

El resultado es un contenedor resiliente donde, incluso ante un fallo de la aplicación, el impacto en el sistema es despreciable.

## 5.2 Recomendaciones Futuras
Para mantener este nivel de seguridad en el tiempo, se recomienda:

*   **CI/CD Automatizado**: Integrar un paso en GitHub/GitLab CI que ejecute `trivy image` y bloquee el despliegue si detecta vulnerabilidades críticas.
*   **Gestión de Secretos**: En producción real, migrar de variables de entorno a **Docker Secrets** o **HashiCorp Vault** para rotación automática de claves.
*   **Monitoreo de Runtime**: Implementar herramientas como **Falco** para detectar anomalías de comportamiento en tiempo real (ej. intentos de abrir una shell).

---
**Fin de la Memoria Técnica**

