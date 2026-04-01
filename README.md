# Sistema de Facturación Electrónica (SFE) - Bolivia

[![Linear](https://img.shields.io/badge/Project%20Tracking-Linear-5E6AD2)](https://linear.app/infcle/team/INF)
[![Status](https://img.shields.io/badge/Sprint-1%20In%20Progress-green)]()
[![Points](https://img.shields.io/badge/Story%20Points-193-blue)]()

Sistema de Facturación Electrónica integrado con el SIN (Servicio de Impuestos Nacionales) de Bolivia, cumpliendo con la normativa de facturación en línea según las especificaciones del SIAT (Sistema de Administración Tributaria).

## 🎯 Estado del Proyecto

**Fecha de Inicio:** 01 de Abril 2026  
**Sprint Actual:** Sprint 1 - Fundamentos del Sistema  
**Tickets Completados:** 0/26  
**Story Points Completados:** 0/193  

### Sprints y Cycles

| Sprint | Período | Cycle Linear | Tickets | Puntos | Estado |
|--------|---------|--------------|---------|--------|--------|
| Sprint 1 | 01/04 - 24/04/2026 | [Cycle 1](https://linear.app/infcle/team/INF/cycle/1) | 6 | 42 pts | 🟡 In Progress |
| Sprint 2 | 25/04 - 20/05/2026 | [Cycle 2](https://linear.app/infcle/team/INF/cycle/2) | 11 | 75 pts | ⚪ Planned |
| Sprint 3 | 15/05 - 25/06/2026 | [Cycle 3](https://linear.app/infcle/team/INF/cycle/3) | 6 | 47 pts | ⚪ Planned |
| Sprint 4 | 26/06 - 15/07/2026 | [Cycle 4](https://linear.app/infcle/team/INF/cycle/4) | 6 | 29 pts | ⚪ Planned |

---

## 📋 Documentación del Proyecto

### Requerimientos y Especificaciones

| Documento | Descripción | Ubicación |
|-----------|-------------|-----------|
| **Tickets Linear** | Especificación completa de todos los tickets con criterios de aceptación, especificaciones técnicas y subtareas | [`docs/requerimientos/tickets_linear_spec.md`](docs/requerimientos/tickets_linear_spec.md) |
| **Historias de Usuario** | Historias de usuario detalladas en formato Gherkin | [`docs/requerimientos/historias_usuario.md`](docs/requerimientos/historias_usuario.md) |
| **Criterios de Aceptación** | Resumen de criterios de aceptación mínimos | [`docs/requerimientos/criterios_aceptacion_minimos.md`](docs/requerimientos/criterios_aceptacion_minimos.md) |
| **Requerimientos Obtenidos** | Documento de requerimientos iniciales del SIN | [`docs/requerimientos/requerimientos_obtenidos.md`](docs/requerimientos/requerimientos_obtenidos.md) |

### Plantillas

| Plantilla | Descripción | Ubicación |
|-----------|-------------|-----------|
| Registro Compras Estándar | Plantilla para sector estándar | [`plantillas/PlantillaRegistro_ComprasEstandar.xlsx`](plantillas/PlantillaRegistro_ComprasEstandar.xlsx) |
| Registro Prevaloradas | Plantilla para telecomunicaciones | [`plantillas/PlantillaRegistro_prevaloradastelecomunicaciones.xlsx`](plantillas/PlantillaRegistro_prevaloradastelecomunicaciones.xlsx) |
| Registro Reintegros | Plantilla para sectores especiales | [`plantillas/PlantillaRegistro_reintegros.xlsx`](plantillas/PlantillaRegistro_reintegros.xlsx) |

---

## 🏗️ Arquitectura del Sistema

### Microservicios

```
┌─────────────────────────────────────────────────────────────┐
│                      ANGULAR FRONTEND                       │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                      API GATEWAY                              │
│                   (Spring Cloud Gateway)                      │
└──────────────────────┬──────────────────────────────────────┘
                       │
        ┌──────────────┼──────────────┬──────────────┐
        │              │              │              │
        ▼              ▼              ▼              ▼
┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│siat-auth-   │ │  cuis-      │ │  cufd-      │ │  firma-     │
│  service    │ │  service    │ │  service    │ │digital-     │
│  (Token)    │ │  (CUIS)     │ │  (CUFD)     │ │  service    │
└─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘
        │              │              │              │
        │              │              │              │
        ▼              ▼              ▼              ▼
┌─────────────────────────────────────────────────────────────┐
│              SHARED SERVICES                                  │
│  ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐   │
│  │  factura- │ │ numero-   │ │ catalogo- │ │contingencia│   │
│  │  service  │ │factura-   │ │  service  │ │  -service  │   │
│  │           │ │  service  │ │           │ │            │   │
│  └───────────┘ └───────────┘ └───────────┘ └───────────┘   │
│  ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐   │
│  │  paquete- │ │  pdf-     │ │  email-   │ │  storage- │   │
│  │  service  │ │  service  │ │  service  │ │  service  │   │
│  └───────────┘ └───────────┘ └───────────┘ └───────────┘   │
└─────────────────────────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              INFRAESTRUCTURA                                  │
│  ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐   │
│  │ PostgreSQL│ │  Keycloak │ │   NAS     │ │  Redis    │   │
│  │   (DB)    │ │   (Auth)  │ │ (Backup)  │ │  (Cache)  │   │
│  └───────────┘ └───────────┘ └───────────┘ └───────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Stack Tecnológico

| Capa | Tecnología | Versión |
|------|------------|---------|
| **Backend** | Spring Boot | 3.2.x |
| **Frontend** | Angular | 17.x |
| **Base de Datos** | PostgreSQL | 16.x |
| **Autenticación** | Keycloak | 24.x |
| **Cache** | Redis | 7.x |
| **Mensajería** | RabbitMQ | 3.13.x |
| **Contenedores** | Docker | Latest |
| **Orquestación** | Docker Compose / K8s | - |

---

## 📊 Módulos del Sistema

### Módulo 0: Análisis y Planificación (Sprint 1)
- **SFE-ANALISIS-001**: Análisis de Requerimientos SIN (3 pts)
- **SFE-PLAN-001**: Planificación de Arquitectura (5 pts)

### Módulo A: Gestión de Conectividad y Seguridad
- **SFE-001**: Token Delegado del SIN (5 pts)
- **SFE-002**: Renovación CUIS Anual (8 pts)
- **SFE-003**: Renovación CUFD Diaria (8 pts)
- **SFE-013**: Cifrado de Llaves y Keycloak (13 pts)

### Módulo B: Generación y Firma de Documentos
- **SFE-004.1**: Firma Digital - Algoritmos (8 pts)
- **SFE-004.2**: Firma Digital - Implementación (5 pts)
- **SFE-005.1**: XML Sector Estándar (5 pts)
- **SFE-005.2**: XML Sectores Especiales (5 pts)
- **SFE-005.3**: XML Reintegros (3 pts)
- **SFE-006**: Cálculo CUF Módulo 11 (3 pts)

### Módulo C: Anulación y Reversión
- **SFE-007**: Anulación de Facturas (8 pts)
- **SFE-008**: Reversión de Anulación (8 pts)

### Módulo D: Homologación y Catálogos
- **SFE-009**: Homologación de Productos (13 pts)
- **SFE-009.1**: Frontend Homologación (8 pts)

### Módulo E: Contingencias y Paquetes
- **SFE-010**: Detección de Contingencia (13 pts)
- **SFE-011**: Envío de Paquetes Masivos (13 pts)

### Módulo F: Notificación y Optimización
- **SFE-012.1**: Generación de QR (3 pts)
- **SFE-012.2**: Generación de PDF (5 pts)
- **SFE-012.3**: Envío por Email (5 pts)
- **SFE-014**: Retry Logic (8 pts)
- **SFE-015**: Performance < 2 segundos (13 pts)
- **SFE-016**: Almacenamiento 8 años (13 pts)

### Módulo G: Frontend Angular
- **SFE-F001**: Configuración Frontend (8 pts)
- **SFE-F002**: Dashboard de Monitoreo (8 pts)

---

## 🗓️ Calendario de Feriados (Bolivia 2026)

| Fecha | Feriado | Impacto |
|-------|---------|---------|
| 03/04 | Viernes Santo | No laborable |
| 01/05 | Día del Trabajo | No laborable |
| 04/06 | Corpus Christi | No laborable |
| 16/07 | Día de La Paz* | No laborable (solo La Paz) |

*Aplica según ubicación del equipo

---

## 🚀 Guía de Inicio Rápido

### Requisitos Previos

```bash
# Java 17+
java -version

# Node.js 18+
node -version

# Docker
docker --version

# Docker Compose
docker-compose --version
```

### Configuración del Entorno

```bash
# Clonar repositorio
git clone <repository-url>
cd facturacion-en-linea

# Configurar variables de entorno
cp .env.example .env
# Editar .env con credenciales SIN

# Levantar infraestructura
docker-compose up -d postgres keycloak redis rabbitmq

# Ejecutar migraciones
./mvnw flyway:migrate
```

### Ejecución Local

```bash
# Backend (cada microservicio)
./mvnw spring-boot:run

# Frontend
npm install
ng serve
```

---

## 🔗 Enlaces Importantes

### Documentación SIN
- [Portal SIAT](https://siatinfo.impuestos.gob.bo)
- [Manual de Facturación](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea)
- [Web Services SIN](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/desarrollo-del-sistema)

### Gestión de Proyecto
- [Linear - Team Infcle](https://linear.app/infcle/team/INF)
- [Cycle 1 - Sprint 1](https://linear.app/infcle/team/INF/cycle/1)
- [Cycle 2 - Sprint 2](https://linear.app/infcle/team/INF/cycle/2)
- [Cycle 3 - Sprint 3](https://linear.app/infcle/team/INF/cycle/3)
- [Cycle 4 - Sprint 4](https://linear.app/infcle/team/INF/cycle/4)

---

## 👥 Equipo

| Rol | Responsable |
|-----|-------------|
| Arquitecto | Elmer |
| Backend Lead | TBD |
| Frontend Lead | TBD |
| DevOps | TBD |
| QA Lead | TBD |

---

## 📝 Convenciones

### Branching Strategy (GitFlow)

```
main
  └── develop
        ├── feature/SFE-001-token-delegado
        ├── feature/SFE-002-cuis-renovacion
        └── hotfix/fix-token-validation
```

### Commits

```
feat(SFE-001): implementar endpoint de registro de token
fix(SFE-003): corregir validación de CUFD expirado
docs(SFE-ANALISIS): actualizar matriz de requerimientos
```

### Pull Requests

- Título: `[SFE-XXX] Descripción breve`
- Requiere: 2 aprobaciones
- CI/CD: Tests deben pasar
- Coverage: Mínimo 80%

---

## 📈 Métricas del Proyecto

### Velocity por Sprint

| Sprint | Puntos Planificados | Puntos Completados | Velocity |
|--------|---------------------|-------------------|----------|
| Sprint 1 | 42 | - | - |
| Sprint 2 | 75 | - | - |
| Sprint 3 | 47 | - | - |
| Sprint 4 | 29 | - | - |

### Distribución por Tipo

- **Backend:** 16 tickets (127 pts)
- **Frontend:** 4 tickets (32 pts)
- **Fullstack:** 4 tickets (26 pts)
- **Análisis/Planificación:** 2 tickets (8 pts)

---

## 🔒 Seguridad

- Todos los datos sensibles en variables de entorno
- Encriptación AES-256 para tokens y llaves
- Autenticación OAuth2 con Keycloak
- Logs de auditoría sin datos PII
- Certificados digitales gestionados con HSM

---

## 📞 Contacto

Para dudas sobre el proyecto, contactar al Product Owner o consultar la documentación en Linear.

---

**Última actualización:** 01 de Abril 2026  
**Versión del documento:** 1.0
