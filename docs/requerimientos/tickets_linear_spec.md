# Tickets Linear - Sistema de Facturación Electrónica (SFE)

## 📋 Plantilla de Tickets

```
TICKET: SFE-XXX
Tipo: [Backend | Frontend | Fullstack]
Microservicio: [Sí | No]
Prioridad: [P0 | P1 | P2]
Estimación: X pts
Fecha Inicio: DD/MM/YYYY
Fecha Conclusión: DD/MM/YYYY
Documentación: [Link a referencia SIN si aplica]
```

---

## MÓDULO 0: ANÁLISIS Y PLANIFICACIÓN (SPRINT 1)

---

### TICKET: SFE-ANALISIS-001

**Título:** Análisis de Requerimientos SIN y Documentación Técnica

**Tipo:** Análisis  
**Microservicio:** No  
**Prioridad:** P0 - Critical  
**Estimación:** 3 pts  
**Fecha Inicio:** 01/04/2026  
**Fecha Conclusión:** 02/04/2026

**Documentación Requerida:**

- 📖 [Portal de Información SIAT](https://siatinfo.impuestos.gob.bo)
- 📖 [Manual de Facturación SIN](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea)

**Descripción:**
Análisis exhaustivo de los requerimientos del SIN y documentación técnica para garantizar el cumplimiento normativo.

**Criterios de Aceptación:**

- [ ] Revisión completa de documentación oficial del SIN
- [ ] Análisis de especificaciones SOAP y XSD
- [ ] Identificación de casos de uso críticos
- [ ] Matriz de requerimientos funcionales y no funcionales
- [ ] Checklist de cumplimiento SIN

**Entregables:**

```
1. Documento de análisis de requerimientos SIN
2. Matriz de trazabilidad de requerimientos
3. Identificación de riesgos técnicos y regulatorios
4. Checklist de cumplimiento SIN
```

**Nota:** Ticket inicial del proyecto. Debe completarse antes de cualquier desarrollo.

---

### TICKET: SFE-PLAN-001

**Título:** Planificación de Arquitectura y Microservicios

**Tipo:** Planificación  
**Microservicio:** No  
**Prioridad:** P0 - Critical  
**Estimación:** 5 pts  
**Fecha Inicio:** 06/04/2026  
**Fecha Conclusión:** 07/04/2026

**Documentación Requerida:**

- 📖 Documentación de arquitectura de microservicios
- 📖 Especificaciones técnicas del stack elegido

**Descripción:**
Definición de la arquitectura de microservicios y plan de desarrollo para establecer una base técnica sólida.

**Criterios de Aceptación:**

- [ ] Arquitectura de microservicios definida (siat-auth, cuis, cufd, firma, factura)
- [ ] Tecnologías especificadas (Spring Boot, Angular, PostgreSQL, Keycloak)
- [ ] Modelo de datos inicial (ERD) diseñado
- [ ] API contracts entre frontend y backend definidos
- [ ] Estrategia de CI/CD planificada
- [ ] Convenciones de código y branching strategy (GitFlow) definidas

**Entregables:**

```
1. Diagrama de arquitectura de microservicios
2. Diagrama ERD de base de datos
3. API contract documentation (OpenAPI/Swagger)
4. Plan de CI/CD
5. Guía de desarrollo y estándares de código
```

**Nota:** Considera que el 03/04 (Viernes Santo) es feriado. La planificación comienza el lunes 06/04. Depende de: SFE-ANALISIS-001

---

## MÓDULO A: GESTIÓN DE CONECTIVIDAD Y SEGURIDAD

---

### TICKET: SFE-001

**Título:** Implementar Gestión de Token Delegado del SIN

**Tipo:** Backend (Spring Boot)  
**Microservicio:** Sí - `siat-auth-service`  
**Prioridad:** P0 - Critical  
**Estimación:** 5 pts  
**Fecha Inicio:** 01/04/2026  
**Fecha Conclusión:** 10/04/2026  

**Documentación Requerida:**

- 📖 [Solicitud de Token SIN](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/emision-y-envio-de-facturas/solicitud-token)
- 📖 [Esquemas de Conexión](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/requerimientos/esquemas-de-conexion)

**Descripción:**
Implementar el servicio de registro, almacenamiento cifrado y gestión del token delegado otorgado por el SIN para autenticar solicitudes en los servicios SOAP del ecosistema del SIN.

**Criterios de Aceptación:**

- [ ] Token se almacena cifrado con AES-256-CBC
- [ ] Token inválido es rechazado con mensaje de error
- [ ] Token válido se puede usar en todas las solicitudes SOAP

**Especificaciones Técnicas:**

```
Endpoint REST:
  POST /api/v1/siat/token
  Headers: Authorization: Bearer {jwt}
  Body: {
    tokenDelegado: string,
    nit: string,
    codigoSistema: string
  }
  Response: { id, tokenHash, estado, fechaRegistro }

Almacenamiento:
  - Base de datos: Tabla `siat_tokens`
  - Campos: id (PK), nit, tokenCifrado, tokenHash, estado, fechaRegistro, fechaVencimiento
  - Cifrado: javax.crypto.Cipher con AES/CBC/PKCS5Padding
  - Key Management: Guardar en application.yml con Spring Cloud Config

Validación:
  - Token no puede estar vacío
  - Formato: alfanumérico de 64-256 caracteres
  - Verificar contra endpoint "VerificaComunicacion" del SIN

Referencia SIN:
  https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/emision-y-envio-de-facturas/solicitud-token
```

**Subtareas:**

- [ ] Crear entity Token y repository
- [ ] Implementar servicio de cifrado AES-256
- [ ] Implementar TokenService
- [ ] Crear endpoint POST /api/v1/siat/token
- [ ] Crear endpoint GET /api/v1/siat/token/{id}
- [ ] Crear tests unitarios
- [ ] Documentar API en Swagger

**Prioridad:** P0 - Critical
**Estimación:** 5 pts

---

### TICKET: SFE-002

**Título:** Renovación Automática de CUIS (Anual)

**Tipo:** Backend (Spring Boot)  
**Microservicio:** Sí - `cuis-service`  
**Prioridad:** P0 - Critical  
**Estimación:** 8 pts  
**Fecha Inicio:** 11/04/2026  
**Fecha Conclusión:** 24/04/2026  

**Documentación Requerida:**

- 📖 [Solicitud CUIS](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/codigos/solicitud-cuis)
- 📖 [Códigos del SIN](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/codigos-error-siat)

**Descripción:**
Implementar tarea programada (scheduler) que renueve automáticamente el CUIS 30 días antes de su expiración y gestione su almacenamiento y validación.

**Criterios de Aceptación:**

- [ ] CUIS se renueva automáticamente 30 días antes de expiración
- [ ] Nuevo CUIS se obtiene del SIN y se almacena
- [ ] Si falla, reintenta 3 veces con backoff exponencial
- [ ] Se registra en logs cada intento

**Especificaciones Técnicas:**


```
Scheduler (Cron):
  - Ejecutar diariamente a las 02:00 AM
  - Cron: "0 2 * * *"
  - Timezone: America/La_Paz
  - Usar @Scheduled en Spring Framework

Datos del CUIS:
  - Vigencia: 365 días
  - Formato: 32 caracteres alfanuméricos
  - Tabla: `cuis_codigos`
  - Campos: id, nit, codigoPuntoVenta, cuisActual, fechaVigenciaInicio, 
            fechaVigenciaFin, estado, intentos

Lógica de Renovación:
  1. Consultar CUIS vigente con fechaVigenciaFin - hoy <= 30
  2. Invocar servicio SOAP: SolicitudCUIS
     Parámetros: codigoAmbiente, codigoSistema, nit, codigoSucursal, codigoPuntoVenta
  3. Recibir: { cuis, fechaVigenciaInicio, fechaVigenciaFin, codigo, descripcion }
  4. Guardar nuevo CUIS
  5. Registrar evento en tabla `cuis_eventos`

Manejo de Errores:
  - Error 500 del SIN: reintentar 3 veces
  - Espera: 2s (1er), 4s (2do), 8s (3er) - exponencial
  - Si falla: enviar email a administrador
  - Log: nivel WARN

RetryLogic:
  - Usar Spring Retry o Resilience4j
  - maxAttempts: 3
  - waitDuration: 2000ms inicial
  - multiplier: 2.0

Referencia SIN:
  https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/codigos/solicitud-cuis
```

**Subtareas:**
- [ ] Crear entity CUIS y CUISEvento
- [ ] Implementar servicio SOAP SolicitudCUIS
- [ ] Implementar scheduler con @Scheduled
- [ ] Implementar RetryTemplate para reintentos
- [ ] Crear notificación por email
- [ ] Crear tests de scheduler
- [ ] Documentar en logs

**Prioridad:** P0 - Critical
**Estimación:** 8 pts

---

### TICKET: SFE-003
**Título:** Renovación Automática de CUFD (Diaria)

**Tipo:** Backend (Spring Boot)  
**Microservicio:** Sí - `cufd-service`  
**Prioridad:** P0 - Critical  
**Estimación:** 8 pts  
**Fecha Inicio:** 11/04/2026  
**Fecha Conclusión:** 24/04/2026  

**Documentación Requerida:**
- 📖 [Solicitud CUFD](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/codigos/solicitud-cufd)
- 📖 [Solicitud CUFD Masivo](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/codigos/solicitud-cufd-masivo)

**Descripción:**
Implementar tarea programada que renueve automáticamente el CUFD cada día antes de las 23:59:59 horas, garantizando que siempre hay un código válido para emitir facturas.

**Criterios de Aceptación:**
- [ ] CUFD se renueva diariamente a las 23:00 horas
- [ ] Nuevo CUFD vigente desde ese día hasta las 23:59:59
- [ ] Si falla, reintenta 3 veces con backoff exponencial
- [ ] El CUFD se valida antes de usar en cada factura

**Especificaciones Técnicas:**

```
Scheduler (Cron):
  - Ejecutar diariamente a las 23:00 AM
  - Cron: "0 23 * * *"
  - Timezone: America/La_Paz

Datos del CUFD:
  - Vigencia: 24 horas (desde 00:00 a 23:59:59)
  - Formato: 32 caracteres alfanuméricos
  - Tabla: `cufd_codigos`
  - Campos: id, nit, codigoPuntoVenta, cufdActual, cufdAnterior, fechaVigenciaInicio,
            fechaVigenciaFin, estado, createdAt

Lógica de Renovación:
  1. Verificar si ya existe CUFD para hoy
  2. Si sí existe y es vigente: usar existente
  3. Si no existe o está expirado:
     a. Invocar servicio SOAP: SolicitudCUFD
        Parámetros: codigoAmbiente, codigoSistema, nit, codigoSucursal, codigoPuntoVenta, cuis
     b. Recibir: { cufd, fechaVigenciaInicio, fechaVigenciaFin, codigo, descripcion }
     c. Guardar nuevo CUFD
     d. Marcar anterior como historial
  4. Registrar en tabla `cufd_eventos`

Validación Pre-Emisión:
  - Cada vez que se va a emitir una factura:
    1. Obtener CUFD vigente
    2. Validar que fecha actual esté en [vigenciaInicio, vigenciaFin]
    3. Si CUFD expiró: obtener nuevo ANTES de procesar
    4. Para paquetes de contingencia: obtener nuevo CUFD ANTES de envío

Manejo de Errores:
  - Retry: 3 veces con backoff exponencial
  - Si falla tras 3 intentos: marcar como crítico
  - Sistema debe continuar con CUFD anterior temporalmente

Referencia SIN:
  https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/codigos/solicitud-cufd
```

**Subtareas:**
- [ ] Crear entity CUFD y CUFDEvento
- [ ] Implementar servicio SOAP SolicitudCUFD
- [ ] Implementar scheduler 23:00 horas
- [ ] Implementar validación pre-emisión
- [ ] Implementar cambio de CUFD en paquetes de contingencia
- [ ] Crear tests
- [ ] Monitoreo y alertas

**Prioridad:** P0 - Critical
**Estimación:** 8 pts

---

### TICKET: SFE-004
**Título:** Implementar Firma Digital de Archivos XML

**Tipo:** Backend (Spring Boot)  
**Microservicio:** Sí - `firma-digital-service`  
**Prioridad:** P0 - Critical  
**Estimación:** 13 pts  
**Fecha Inicio:** 01/04/2026  
**Fecha Conclusión:** 20/04/2026  

**Documentación Requerida:**
- 📖 [Firma Digital](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/firma-digital/firma-digital)
- 📖 [Firmado de XML](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/firma-digital/firmado-de-xml)
- 📖 [Generación CSR](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/firma-digital/generacion-csr/generacion-de-csr-para-software)
- 📖 [Signature Schema](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/firma-digital/signatureschema)

**Descripción:**
Implementar módulo de firma digital de archivos XML usando certificados digitales válidos según el estándar del SIN, cumpliendo con tiempo máximo de 2 segundos.

**Criterios de Aceptación:**
- [ ] XML se firma correctamente en menos de 2 segundos
- [ ] Certificado vigente es validado antes de firmar
- [ ] XML inválido es rechazado
- [ ] Firma es verificable por el SIN

**Especificaciones Técnicas:**

```
Proceso de Firma (RSA SHA256 V2):
  1. Canonicalizar XML (normalizar espacios, formato)
  2. Calcular SHA-256 del XML canonicalizado
  3. Codificar hash en Base64
  4. Crear estructura SignedInfo con referencias
  5. Calcular SHA-256 de SignedInfo
  6. Encriptar con RSA + SHA256 V2 usando llave privada
  7. Codificar firma resultante en Base64
  8. Agregar etiquetas de firma XML
  9. Incluir certificado X509 en estructura

Librerías:
  - Apache XML Security (org.apache.santuario:xmlsec)
  - Bouncy Castle para manejo de certificados
  - Java Cryptography Architecture (JCA/JCE)

Almacenamiento de Certificados:
  - Llave privada: cifrada con AES-256 en BD
  - Llave pública: en BD sin cifrado
  - Formato: PKCS#12 (.p12)
  - Tabla: `certificados_digitales`
  - Campos: id, nit, nombreEmisor, fechaInicio, fechaVencimiento, 
            privadoCifrado, publicoX509, estado, tipoEmision

Validación de Certificado:
  - Verificar vigencia: fechaInicio <= hoy <= fechaVencimiento
  - Verificar NO esté revocado (Verificar con SIN)
  - Verificar que pertenezca al NIT emisor
  - Código error 928: Certificado Revocado

Estructura XML Firmado:
  <ds:Signature xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
    <ds:SignedInfo>
      <ds:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
      <ds:SignatureMethod Algorithm="http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"/>
      <ds:Reference URI="">
        <ds:Transforms>...</ds:Transforms>
        <ds:DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256"/>
        <ds:DigestValue>...</ds:DigestValue>
      </ds:Reference>
    </ds:SignedInfo>
    <ds:SignatureValue>...</ds:SignatureValue>
    <ds:KeyInfo>
      <ds:X509Data>
        <ds:X509Certificate>...</ds:X509Certificate>
      </ds:X509Data>
    </ds:KeyInfo>
  </ds:Signature>

Performance:
  - Meta: < 2 segundos total
  - Desglose esperado:
    * Canonicalización: < 300ms
    * Cálculo SHA256: < 100ms
    * Encriptación RSA: < 1000ms
    * Codificación B64: < 200ms
  - Cachear certificado en memoria si es posible
  - Usar thread pool para procesamiento paralelo

Referencia SIN:
  https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/firma-digital/firmado-de-xml
  https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/firma-digital/signatureschema
```

**Subtareas:**
- [ ] Crear entity CertificadoDigital
- [ ] Implementar servicio de carga de certificados (.p12)
- [ ] Implementar cifrado de llave privada (AES-256)
- [ ] Implementar firmado XML (canonicalización + firma RSA)
- [ ] Implementar validación de certificado
- [ ] Implementar verificación de revocación con SIN
- [ ] Tests de performance (< 2 segundos)
- [ ] Tests de integridad de firma

**Prioridad:** P0 - Critical
**Estimación:** 13 pts

---

## MÓDULO B: EMISIÓN Y OPERACIONES FISCALES

---

### TICKET: SFE-005
**Título:** Generar XML de Factura Compra-Venta

**Tipo:** Backend (Spring Boot)  
**Microservicio:** Sí - `factura-service`  
**Prioridad:** P0 - Critical  
**Estimación:** 13 pts  
**Fecha Inicio:** 25/04/2026  
**Fecha Conclusión:** 14/05/2026  

**Documentación Requerida:**
- 📖 [Factura de Compra y Venta XSD](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-de-compra-y-venta)
- 📖 [Validaciones Documentos Sector](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/validaciones-documentos-sector/validaciones)

**Descripción:**
Implementar generador de archivos XML de facturas de compra-venta según esquema XSD oficial del SIN, validando estructura y contenido obligatorio.

**Criterios de Aceptación:**
- [ ] XML generado cumple esquema XSD oficial
- [ ] Contiene todos los campos obligatorios de cabecera
- [ ] Contiene todos los campos obligatorios de detalle
- [ ] Montos se calculan correctamente
- [ ] XML es válido contra XSD antes de retornar

**Especificaciones Técnicas:**

```
Estructura de Datos - Factura Compra-Venta:

Cabecera (FacturaCompraVenta):
  - numeroFactura: correlativo único por punto de venta (1-9999999)
  - cuis: Código Único de Sistema Informático (32 chars)
  - cufd: Código Único de Facturación Diaria (32 chars)
  - codigoControl: CUF calculado (4 dígitos)
  - codigoSucursal: 0-99
  - codigoPuntoVenta: 0-999
  - fecha: UTC Extended "2026-04-01T10:30:45.123"
  - codigoAmbiente: 1=Producción, 2=Pruebas
  - codigoTipoEmision: 1=En Línea, 2=Fuera de Línea
  - tipoFactura: 1=Factura, 5=Boleta
  - tipoMoneda: BOB (Bolivianos)
  - tipoCambio: 1.0 si es BOB

Emisor:
  - nitEmisor: RFC/NIT
  - razonSocialEmisor
  - nombreFantasiaEmisor
  - actividadEconomicaCodigo
  - telefonoEmisor
  - correoEmisor
  - municipioEmisor

Comprador:
  - codigoTipoDocumentoIdentidad: 1=CI, 2=Pasaporte, 3=NIT, 4=Otros, 5=Extranjero
  - numeroDocumento
  - nombreRazonSocial
  - telefonoCliente
  - correoCliente
  - municipioCliente (SI codigoTipoDocumentoIdentidad = 3 o municipioEmisor != municipioCliente)

Items:
  - linea: número secuencial del item
  - codigoProducto: código interno
  - codigoProductoSIN: código del catálogo oficial del SIN (homologado)
  - descripcion
  - cantidad: número con 2 decimales
  - unidadMedida: código oficial
  - precioUnitario: sin descuento
  - montoDescuento: por item (opcional)
  - montoTotal: = (cantidad * precioUnitario) - descuento

Totales:
  - subTotalVentas: Σ(cantidad * precioUnitario) - descuentos = Σ(montoTotal)
  - descuentoAdicional: descuento general
  - montoTotalSujetoIva: subTotalVentas - descuentoAdicional
  - montoIva: 13% de montoTotalSujetoIva (si aplica)
  - montoTotalMoneda: transacción en moneda original
  - montoGiftCard: si aplica (opcional)
  - montoLiquidoFinanciero: total final

Métodos de Pago:
  - codigoMetodoPago: 1=Efectivo, 2=Tarjeta, 3=Cheque, 4=Transferencia, 5=Otros
  - Si es tarjeta: numeroTarjeta ofuscado (primeros 4 y últimos 4)

Generación de XML:
  - Usar JAXB (Jakarta Persistence) o XStream
  - Validar contra XSD antes de retornar
  - Usar pretty-print para legibilidad

Validaciones:
  - Todos los campos obligatorios presentes
  - Números en rango válido
  - Strings sin caracteres especiales peligrosos
  - Suma de items = total
  - NIT comprador si es nacional
  - Email válido si se incluye
  - Fecha actual o pasada

Referencia SIN:
  https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-de-compra-y-venta
```

**Subtareas:**
- [ ] Crear entities/DTOs para estructura de factura
- [ ] Implementar validaciones de datos obligatorios
- [ ] Implementar cálculo de montos
- [ ] Generar XML con JAXB
- [ ] Implementar validación contra XSD
- [ ] Crear tests con múltiples escenarios
- [ ] Documentar estructura de entrada

**Prioridad:** P0 - Critical
**Estimación:** 13 pts

---

### TICKET: SFE-006
**Título:** Calcular Código Único de Facturación (CUF) - Módulo 11

**Tipo:** Backend (Spring Boot)  
**Microservicio:** No - Librería compartida  
**Prioridad:** P1 - High  
**Estimación:** 3 pts  
**Fecha Inicio:** 25/04/2026  
**Fecha Conclusión:** 27/04/2026  

**Documentación Requerida:**
- 📖 [Generación CUF - Algoritmo Módulo 11](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/algoritmos-utilizados/generacion-cuf)
- 📖 [Algoritmo Módulo 11](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/algoritmos-utilizados/algoritmo-modulo-11)

**Descripción:**
Implementar algoritmo Módulo 11 para calcular el Código Único de Facturación (CUF) de 4 dígitos según normativa SIN.

**Criterios de Aceptación:**
- [ ] CUF se calcula correctamente usando Módulo 11
- [ ] Resultado es número de 4 dígitos
- [ ] CUF es único por factura
- [ ] Validable por el SIN

**Especificaciones Técnicas:**

```
Algoritmo Módulo 11:
  
Entrada:
  - nit: NIT del emisor
  - cuis: Código del sistema
  - numero: número correlativo de factura
  - fecha: fecha de emisión AAAAMMDD

Proceso:
  1. Concatenar: cuis + numero + fecha
  2. Convertir a array de dígitos
  3. Multiplicar cada dígito por peso (2, 3, 4, 5, 6, 7, 2, 3, 4, 5...)
     (pesos ciclados: 2,3,4,5,6,7,2,3,4,5,6,7,...)
  4. Sumar todos los productos: Σ(dígito * peso)
  5. Dividir suma entre 11 y obtener residuo
  6. Restar residuo de 11: resultado = 11 - residuo
  7. Si resultado = 11: CUF = 0
     Si resultado = 10: CUF = 9
     Sino: CUF = resultado
  8. Cuando entrada es NIT: usar últimos 8 dígitos ciclados

Ejemplo:
  entrada: "123456789012345678"
  pesos:   [2,3,4,5,6,7,2,3,4,5,6,7,2,3,4,5,6,7]
  productos: [2,6,12,20,30,42,14,24,36,50,66,84,2,9,16,25,36,49]
  suma: 523
  residuo: 523 % 11 = 6
  cuf: 11 - 6 = 5

Implementar en clase CUFCalculator:

  public static String calcularCUF(String nit, String cuis, 
                                    String numero, LocalDate fecha) {
      // lógica del algoritmo
      return cuaf; // 4 dígitos
  }

Uso en Factura:
  String cuf = CUFCalculator.calcularCUF(
      facturaDTO.getNIT(),
      facturaDTO.getCUIS(),
      String.format("%07d", numeroFactura),
      LocalDate.now()
  );

Referencia SIN:
  https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/algoritmos-utilizados/generacion-cuf
```

**Subtareas:**
- [ ] Implementar clase CUFCalculator
- [ ] Crear tests con ejemplos del SIN
- [ ] Validar contra casos de prueba oficiales
- [ ] Documentar fórmula

**Prioridad:** P1 - High
**Estimación:** 3 pts

---

### TICKET: SFE-007
**Título:** Gestión de Anulación de Facturas

**Tipo:** Backend (Spring Boot)  
**Microservicio:** Sí - `factura-service`  
**Prioridad:** P1 - High  
**Estimación:** 8 pts  
**Fecha Inicio:** 15/05/2026  
**Fecha Conclusión:** 25/05/2026  

**Documentación Requerida:**
- 📖 [Anulación Factura Electrónica](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/facturacion-electronica/anulacion-factura-electronica)
- 📖 [Anulación de Documentos Fiscales](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/emision-y-envio-de-facturas/anulacion-de-documentos-fiscales)

**Descripción:**
Implementar servicio de anulación de facturas emitidas, enviando notificación al SIN y registrando cambios de estado.

**Criterios de Aceptación:**
- [ ] Factura válida se puede anular
- [ ] Intento de anular factura no emitida es rechazado
- [ ] Anulación se registra en SIN
- [ ] Motivo de anulación se almacena

**Especificaciones Técnicas:**

```
Modelos de Datos:

Tabla: facturas
  - id (PK)
  - numeroFactura
  - nit
  - fechaEmision
  - estado: EMITIDA, ANULADA, REVERSADA
  - codigoControl (CUF)
  - fechaAnulacion (nullable)
  - motivoAnulacion (nullable)
  - usuarios_id (FK - quién anula)

Tabla: historial_facturas
  - id (PK)
  - factura_id (FK)
  - estadoAnterior
  - estadoNuevo
  - fechaCambio
  - usuario_id
  - motivo

Endpoint REST:
  DELETE /api/v1/facturas/{id}/anular
  Body: { motivo: string }
  Response: { id, estado: "ANULADA", fechaAnulacion }

Lógica de Anulación:
  1. Validar que factura exista
  2. Validar que estado = EMITIDA
  3. Validar que esté registrada en SIN
  4. Invocar servicio SOAP: AnulacionFacturaElectronica
     Parámetros: codigoAmbiente, codigoSistema, nit, codigoSucursal, 
                 codigoPuntoVenta, cuis, cufd, numeroFactura, codigoControl
  5. Recibir respuesta: { codigo, descripcion, codigoRecepcion }
  6. Si código = 903 (procesada):
     - Actualizar estado a ANULADA
     - Guardar motivo
     - Registrar en historial
     - Responder con éxito
  7. Si código de error:
     - No cambiar estado
     - Registrar intento fallido
     - Retornar error al cliente

Validaciones:
  - Factura debe existir
  - Usuario debe tener permisos de anulación
  - No se pueden anular facturas de hace > 6 meses (validar con normativa)

Referencia SIN:
  https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/facturacion-electronica/anulacion-factura-electronica
```

**Subtareas:**
- [ ] Crear campos en entity Factura
- [ ] Crear entity HistorialFactura
- [ ] Implementar servicio SOAP AnulacionFacturaElectronica
- [ ] Implementar endpoint DELETE
- [ ] Tests de anulación exitosa y fallida
- [ ] Auditoría de cambios

**Prioridad:** P1 - High
**Estimación:** 8 pts

---

### TICKET: SFE-008
**Título:** Reversión de Anulación de Facturas

**Tipo:** Backend (Spring Boot)  
**Microservicio:** Sí - `factura-service`  
**Prioridad:** P2 - Medium  
**Estimación:** 5 pts  
**Fecha Inicio:** 25/05/2026  
**Fecha Conclusión:** 01/06/2026  

**Documentación Requerida:**
- 📖 [Reversión Anulación Factura Electrónica](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/facturacion-electronica/reversion-anulacion-factura-electronica)
- 📖 [Reversión Anulación de Documentos](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/emision-y-envio-de-facturas/reversion-anulacion-documentos-fiscales)

**Descripción:**
Implementar servicio de reversión de anulación para restaurar facturas anuladas por error.

**Criterios de Aceptación:**
- [ ] Factura anulada se puede revertir
- [ ] Intento de revertir factura no anulada es rechazado
- [ ] Reversión se registra en SIN
- [ ] Estado retorna a EMITIDA

**Especificaciones Técnicas:**

```
Endpoint REST:
  POST /api/v1/facturas/{id}/revertir-anulacion
  Response: { id, estado: "EMITIDA", fechaReversion }

Lógica de Reversión:
  1. Validar que factura exista
  2. Validar que estado = ANULADA
  3. Invocar servicio SOAP: ReversionAnulacionFacturaElectronica
     Parámetros: codigoAmbiente, codigoSistema, nit, codigoSucursal,
                 codigoPuntoVenta, cuis, cufd, numeroFactura, codigoControl
  4. Recibir respuesta: { codigo, descripcion }
  5. Si código = 903:
     - Actualizar estado a EMITIDA
     - Registrar en historial
     - Limpiar motivoAnulacion
  6. Si código de error:
     - No cambiar estado
     - Retornar error

Referencia SIN:
  https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/facturacion-electronica/reversion-anulacion-factura-electronica
```

**Subtareas:**
- [ ] Implementar servicio SOAP ReversionAnulacion
- [ ] Implementar endpoint POST
- [ ] Tests de reversión

**Prioridad:** P2 - Medium
**Estimación:** 5 pts

---

### TICKET: SFE-009
**Título:** Homologación de Productos - Mapeo de Catálogo Interno

**Tipo:** Fullstack (Backend Spring Boot + Frontend Angular)  
**Microservicio:** Sí - `catalogo-service` (Backend)  
**Prioridad:** P1 - High  
**Estimación:** 13 pts  
**Fecha Inicio:** 28/04/2026  
**Fecha Conclusión:** 17/05/2026  

**Documentación Requerida:**
- 📖 [Homologación de Productos/Servicios](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/requerimientos/homologacion-de-productos-servicios)
- 📖 [Sincronización Catálogos](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/sincronizacion-codigos-catalogos)

**Descripción:**
Implementar matriz de mapeo entre categorías internas de productos y códigos oficiales del catálogo del SIN para asegurar clasificación correcta.

**Criterios de Aceptación:**
- [ ] Se pueden crear mapeos de producto
- [ ] Mapeo se usa automáticamente en generación de XML
- [ ] No se permiten mapeos duplicados
- [ ] Interfaz para gestionar mapeos (Frontend)

**Especificaciones Técnicas:**

```
Backend:

Entity ProductoHomologado:
  - id (PK)
  - codigoInterno: código usado en sistema interno
  - codigoSIN: código oficial del catálogo SIN
  - nombreProducto
  - descripcion
  - activo: boolean
  - fechaCreacion
  - empresas_id (FK)

Endpoints REST:
  POST   /api/v1/productos/homologaciones
  GET    /api/v1/productos/homologaciones
  GET    /api/v1/productos/homologaciones/{id}
  PUT    /api/v1/productos/homologaciones/{id}
  DELETE /api/v1/productos/homologaciones/{id}

Validaciones:
  - codigoInterno único por empresa
  - codigoSIN debe existir en catálogo oficial del SIN
  - No duplicados (único constraint en BD)

Frontend (Angular):

Componentes:
  - ProductoHomologacionListComponent: tabla de mapeos
  - ProductoHomologacionFormComponent: crear/editar mapeo
  - CatalogoBuscadorComponent: autocomplete para códigos SIN

Servicio:
  - ProductoHomologacionService: CRUD
  - CatalogoSINService: buscar códigos oficiales

Validaciones Frontend:
  - Código único
  - Campo obligatorio
  - Confirmación antes de eliminar

Uso en Facturación:
  - Al seleccionar producto en factura: buscar homologación
  - Si existe: usar codigoSIN en XML
  - Si no existe: alert al usuario

Referencia SIN:
  https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/requerimientos/homologacion-de-productos-servicios
```

**Subtareas:**
- [ ] BACKEND: Crear entity ProductoHomologado
- [ ] BACKEND: Implementar endpoints CRUD
- [ ] BACKEND: Validaciones en BD
- [ ] FRONTEND: Crear componentes Angular
- [ ] FRONTEND: Servicio de consumo API
- [ ] FRONTEND: Tabla de mapeos
- [ ] FRONTEND: Formulario crear/editar
- [ ] Tests E2E

**Prioridad:** P1 - High
**Estimación:** 13 pts

---

## MÓDULO C: CONTINGENCIAS Y DISTRIBUCIÓN

---

### TICKET: SFE-010
**Título:** Detección de Pérdida de Conexión y Activación de Modo Contingencia

**Tipo:** Backend (Spring Boot)  
**Microservicio:** Sí - `contingencia-service`  
**Prioridad:** P0 - Critical  
**Estimación:** 13 pts  
**Fecha Inicio:** 15/05/2026  
**Fecha Conclusión:** 04/06/2026  

**Documentación Requerida:**
- 📖 [Contingencia y Eventos Significativos](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/emision-y-envio-de-facturas/contingencia-y-eventos-significativos)
- 📖 [Ingreso a Contingencia](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/emision-y-envio-de-facturas/ingreso-a-contingencia)
- 📖 [Eventos Significativos](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/operaciones/registro-evento-significativo)

**Descripción:**
Implementar monitoreo de conectividad con SIN, detectar pérdida de conexión en menos de 5 segundos y cambiar automáticamente a emisión Tipo 2 (fuera de línea).

**Criterios de Aceptación:**
- [ ] Pérdida de conexión se detecta en < 5 segundos
- [ ] Evento significativo se registra automáticamente
- [ ] Sistema cambia a modo Tipo 2
- [ ] Facturas se emiten localmente en modo contingencia

**Especificaciones Técnicas:**

```
Monitoreo de Conectividad:

Scheduler Health Check:
  - Cada 30 segundos: invocar VerificaComunicacion del SIN
  - Usar endpoint: https://pilotofactura.impuestos.gob.bo/v2/sincronizacion/sincronizador
  - Timeout: 5 segundos
  - Si no responde en 5s: marcar como desconectado

Estado de Conexión:
  - Variable: conexionSINActiva (volatile boolean)
  - La- bleListener para cambios de estado
  - Publicar evento cuando cambia estado

Cambio a Modo Contingencia (Tipo 2):

  1. Cuando conexión falla:
     - Registrar evento significativo Tipo 1 (Corte Internet)
     - Cambiar flag: modoContingencia = true
     - Cambiar codigoTipoEmision = 2 en facturas nuevas
     - Emitir evento Spring para notificadores

  2. Facturas en contingencia:
     - Se guardan localmente en paquetes
     - Se almacenan en tabla: facturas_contingencia
     - Se genera comprobante de transacción local
     - Se marcan como "pendiente_sincronizacion"

  3. Datos en tabla facturas_contingencia:
     - id
     - numeroFactura
     - xmlFactura (completo)
     - xmlFirmado (con firma digital)
     - paqueteId (para agrupar)
     - fechaEmision
     - estado: PENDIENTE, PROCESADA, ERROR
     - intentosSincronizacion
     - ultimoErrorCode

Tipos de Eventos Significativos que activan Tipo 2:
  - 1: Corte de Internet
  - 2: Inaccesibilidad del SIN
  - 7: Zona sin cobertura de Internet
  - 3: Virus/falla de software

Eventos que NO activan Tipo 2 (usan pre-autorizadas):
  - 4: Cambio de infraestructura
  - 5: Falla de hardware
  - 6: Corte de energía

Restauración de Conexión:

  1. Health check detecta disponibilidad nuevamente
  2. Cambiar: conexionSINActiva = true
  3. Cambiar: modoContingencia = false
  4. Registrar evento de restauración
  5. Emitir evento para procesar paquetes pendientes

Publicación de Eventos:
  - Usar org.springframework.context.ApplicationEvent
  - ConexionPerdidaEvent
  - ConexionRestoradaEvent
  - Listeners pueden reaccionar (enviar email, actualizar UI, etc)

Referencia SIN:
  https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/emision-y-envio-de-facturas/contingencia-y-eventos-significativos
```

**Subtareas:**
- [ ] Crear entity EventoSignificativo y FacturaContingencia
- [ ] Implementar health check scheduler
- [ ] Implementar cambios de estado conexión
- [ ] Implementar publicación de eventos Spring
- [ ] Crear listeners para cambios
- [ ] Tests de detección de corte
- [ ] Tests de sincronización de paquetes

**Prioridad:** P0 - Critical
**Estimación:** 13 pts

---

### TICKET: SFE-011
**Título:** Empaquetamiento y Envío de Paquetes Masivos de Contingencia

**Tipo:** Backend (Spring Boot)  
**Microservicio:** Sí - `paquete-service`  
**Prioridad:** P0 - Critical  
**Estimación:** 13 pts  
**Fecha Inicio:** 05/06/2026  
**Fecha Conclusión:** 25/06/2026  

**Documentación Requerida:**
- 📖 [Recepción Paquete Factura Electrónica](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/facturacion-electronica/recepcion-paquete-factura-electronica)
- 📖 [Validación Recepción Paquete](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/facturacion-electronica/validacion-recepcion-paquete-factura-electronica)
- 📖 [Compresión GZIP](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/algoritmos-utilizados/comprimir-gzip)
- 📖 [Generación SHA-256](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/algoritmos-utilizados/generacion-de-sha-256-md5-y-crc32)

**Descripción:**
Implementar lógica de empaquetamiento de facturas emitidas en contingencia, compresión GZIP, cálculo de hash SHA-256 y envío al SIN cuando se restaure conexión.

**Criterios de Aceptación:**
- [ ] Facturas se empacan correctamente
- [ ] Paquete se comprime en GZIP
- [ ] Se calcula SHA-256 del paquete
- [ ] Se obtiene nuevo CUFD antes de enviar
- [ ] Paquete se envía correctamente al SIN
- [ ] Se recibe codigoRecepcion

**Especificaciones Técnicas:**

```
Proceso de Empaquetamiento:

1. Obtención de Nuevo CUFD (CRÍTICO):
   - ANTES de empacar y enviar
   - Invocar SolicitudCUFD
   - Guardar nuevo CUFD para el envío
   - Importante: el CUFD actual puede tener diferentes fecVigencia

2. Estructura del Paquete:
   - Archivo: contenedor.xml (lista de XMLs de facturas)
   - Formato: ZIP o simplemente múltiples archivos XML comprimidos
   - Metadatos del paquete:
     * fechaPaquete
     * cantidadFacturas
     * montoBruto
     * hashFacturas

3. Datos en BD - Tabla paquetes_contingencia:
   - id (PK)
   - fechaCreacion
   - fechaEnvio (nullable)
   - cantidadFacturas
   - hashArchivo (SHA-256 del paquete comprimido)
   - codigoRecepcion (retorno del SIN)
   - estado: CREADO, ENVIADO, PROCESADO, ERROR
   - intentosEnvio
   - ultimoError

   Relación: paquetes_contingencia <- facturas_contingencia

4. Lógica de Envío (POST - cuando se restaura conexión):

   a) Obtener facturas pendientes:
      SELECT * FROM facturas_contingencia WHERE estado = 'PENDIENTE'
   
   b) Si no hay facturas: terminar
   
   c) Agrupar en paquete:
      - Máximo 500 facturas por paquete
      - Paquetes con fecha emisión similar
   
   d) Para cada paquete:
      1. Obtener nuevo CUFD (ANTES de preparar paquete)
      2. Crear contenedor.xml con referencias de facturas
      3. Comprimir en GZIP
      4. Calcular SHA-256 del archivo comprimido
      5. Llamar servicio: RecepcionPaqueteFacturaElectronica
         Parámetros:
           - codigoAmbiente: número
           - codigoSistema: 1 a 99999
           - nit: NIT del emisor
           - codigoSucursal: 0-99
           - codigoPuntoVenta: 0-999
           - cuis: Código actual
           - cufd: CUFD nuevo obtenido antes
           - archivo: bytes del paquete comprimido (Base64)
           - hashArchivo: SHA-256 en hexadecimal
           - fechaEnvio: timestamp del envío
      
      6. Recibir respuesta:
         { codigo, descripcion, codigoRecepcion, fechaRecepcion }
      
      7. Si código = 903 (procesada):
         - Guardar codigoRecepcion
         - Cambiar estado paquete a ENVIADO
         - Marcar facturas del paquete como PROCESADA
         - Registrar en logs
      
      8. Si código de error:
         - Registrar error en BD
         - Incrementar intentosEnvio
         - Si intentosEnvio > 3: marcar como ERROR y notificar admin
         - Si < 3: reintento automático en 5 minutos

5. Compresión GZIP:
   - Usar java.util.zip.GZIPOutputStream
   - Nivel de compresión: 9 (máximo)
   - Resultado: archivo .gz

6. Cálculo SHA-256:
   - Sobre el archivo comprimido (.gz)
   - Usar java.security.MessageDigest("SHA-256")
   - Codificar en hexadecimal lowercase
   - Ejemplo: "a3f8d5c2b1e4f7a9d3c6e1b4f7a2c5f8"

Validación Pre-Envío:
  - Verificar todas las facturas tienen XML válido
  - Verificar CUIS y CUFD vigentes
  - Verificar paquete corrupto antes de enviar
  - Checksum local vs remoto

Retry Logic:
  - Máximo 3 intentos de envío
  - Espera entre intentos: 5, 10, 20 minutos
  - Si falla tras 3 intentos: notificar administrador

Monitoreo:
  - Log de cada paso del proceso
  - Dashboa

rd de paquetes pendientes

Referencia SIN:
  https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/facturacion-electronica/recepcion-paquete-factura-electronica
```

**Subtareas:**
- [ ] Crear entity PaqueteContingencia
- [ ] Implementar lógica de obtención de CUFD previo
- [ ] Implementar empaquetamiento y compresión GZIP
- [ ] Implementar cálculo SHA-256
- [ ] Implementar servicio SOAP RecepcionPaquete
- [ ] Implementar retry logic
- [ ] Tests de empaquetamiento
- [ ] Tests de compresión y hash
- [ ] Monitoreo y logging

**Prioridad:** P0 - Critical
**Estimación:** 13 pts

---

### TICKET: SFE-012
**Título:** Envío de Factura por Correo Electrónico

**Tipo:** Fullstack (Backend Spring Boot + Frontend Angular)  
**Microservicio:** Sí - `email-service` y `pdf-service` (Backend)  
**Prioridad:** P1 - High  
**Estimación:** 13 pts  
**Fecha Inicio:** 26/06/2026  
**Fecha Conclusión:** 15/07/2026  

**Documentación Requerida:**
- 📖 [Código QR - Respuesta Rápida](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/algoritmos-utilizados/codigo-respuesta-rapida-qr)

**Descripción:**
Implementar generación de código QR, PDF con QR incluido y envío automático de factura por correo electrónico al cliente con XML firmado como adjunto.

**Criterios de Aceptación:**
- [ ] QR se genera correctamente con parámetros de factura
- [ ] PDF incluye QR visual (mínimo 3x3 cm)
- [ ] Email se envía automáticamente
- [ ] Email incluye PDF y XML como adjuntos

**Especificaciones Técnicas:**

```
Backend:

1. Generación de QR:

   Datos del QR:
   - URL base: https://pilotosiat.impuestos.gob.bo/consulta/QR
   - Parámetros GET:
     * nit: NIT del emisor
     * cuf: Código Único de Facturación (4 dígitos)
     * numero: Número correlativo de factura (7 dígitos)
     * t: Tipo (1=Rollo, 2=Media hoja)
   
   Ejemplo URL:
   https://pilotosiat.impuestos.gob.bo/consulta/QR?nit=123456789&cuf=1234&numero=0000001&t=2
   
   Librería: ZXing (com.google.zxing:core)
   
   Código:
   
   public String generarQR(String nit, String cuf, String numero) {
       String urlQR = String.format(
           "https://pilotosiat.impuestos.gob.bo/consulta/QR?nit=%s&cuf=%s&numero=%s&t=2",
           nit, cuf, numero
       );
       
       QRCodeWriter writer = new QRCodeWriter();
       BitMatrix bitMatrix = writer.encode(urlQR, BarcodeFormat.QR_CODE, 512, 512);
       BufferedImage qrImage = MatrixToImageWriter.toBufferedImage(bitMatrix);
       
       return convertBufferedImageToBase64(qrImage);
   }
   
   Dimensiones:
   - Tamaño mínimo: 3 x 3 cm (300 DPI = ~354 x 354 píxeles)
   - Resolución: 300 DPI mínimo para impresión

2. Generación de PDF con QR:

   Librería: iText (com.itextpdf:itextpdf o itextpdf7)
   
   Estructura del PDF:
   - Encabezado con logo empresa y datos emisor
   - Sección: Datos del Comprador
   - Tabla de items con:
     * Código Producto
     * Descripción
     * Cantidad
     * Precio Unitario
     * Monto Total
   - Totales: Subtotal, IVA, Total
   - QR (3x3 cm mínimo) en esquina inferior derecha
   - Pie de página: "Factura digital con Certificado Digital"
   - Línea con: NIT del Emisor, CUF, Número Factura
   
   Código:
   
   public byte[] generarPDF(FacturaDTO factura, String qrBase64) {
       ByteArrayOutputStream baos = new ByteArrayOutputStream();
       PdfWriter writer = new PdfWriter(baos);
       PdfDocument pdfDoc = new PdfDocument(writer);
       Document document = new Document(pdfDoc);
       
       // Agregar contenido...
       // Agregar QR...
       
       document.close();
       return baos.toByteArray();
   }
   
   Nota: Usar iText 7+ (con licencia AGPL si es open source)

3. Almacenamiento de Datos de Contacto:

   Entity/DTO Cliente:
   - id
   - nombreRazonSocial
   - numeroDocumento
   - correoElectronico (validado)
   - telefonoCliente
   - direccion

   Validaciones:
   - Email válido (regex o javax.mail.internet.InternetAddress)
   - Campo requerido antes de emitir
   - Al menos un contacto (email o teléfono)

4. Envío de Email:

   Configuración:
   - SMTP: configurable en application.yml
   - Servidor: Gmail, SendGrid, o SMTP corporativo
   - Puerto: 465 (TLS) o 587 (STARTTLS)
   - Timeout: 30 segundos
   
   application.yml:
   ```yaml
   spring:
     mail:
       host: smtp.gmail.com
       port: 465
       username: ${MAIL_USERNAME}
       password: ${MAIL_PASSWORD}
       properties:
         mail:
           smtp:
             auth: true
             socketFactory:
               port: 465
               class: javax.net.ssl.SSLSocketFactory
   ```
   
   Servicio EmailService:
   
   public void enviarFactura(FacturaDTO factura, byte[] pdfBytes, String xmlFirmado) {
       String destinatario = factura.getCliente().getCorreoElectronico();
       String asunto = "Factura " + factura.getNumeroFactura() + " - " + factura.getRazonSocialEmisor();
       
       String cuerpo = "Estimado cliente,\n\n" +
           "Adjuntamos su factura digital NRO. " + factura.getNumeroFactura() + "\n\n" +
           "Detalles:\n" +
           "Emisor: " + factura.getRazonSocialEmisor() + "\n" +
           "NIT: " + factura.getNIT() + "\n" +
           "Fecha: " + factura.getFecha() + "\n" +
           "Total: " + factura.getMontoTotalMoneda() + " BOB\n\n" +
           "Adjunto encontrará:\n" +
           "- Factura en PDF\n" +
           "- Archivo XML firmado digitalmente\n\n" +
           "Dirección SIN: https://pilotosiat.impuestos.gob.bo/consulta/QR?\n\n" +
           "Agradecemos su compra.";
       
       SimpleMailMessage message = new SimpleMailMessage();
       message.setTo(destinatario);
       message.setSubject(asunto);
       message.setText(cuerpo);
       
       // Adjuntos no soportados en SimpleMailMessage, usar MimeMessage
       MimeMessage mimeMessage = mailSender.createMimeMessage();
       MimeMessageHelper helper = new MimeMessageHelper(mimeMessage, true);
       helper.setTo(destinatario);
       helper.setSubject(asunto);
       helper.setText(cuerpo);
       helper.addAttachment("factura_" + numeroFactura + ".pdf", 
           new ByteArrayResource(pdfBytes), "application/pdf");
       helper.addAttachment("factura_" + numeroFactura + ".xml", 
           new ByteArrayResource(xmlFirmado.getBytes()), "application/xml");
       
       mailSender.send(mimeMessage);
   }
   
   Manejo de Errores:
   - Si email falla: registrar en BD para reintentos
   - No bloquear emisión de factura si email falla
   - Log de intentos de envío
   - Máximo 3 reintentos

Frontend (Angular):

Componente: FacturaEditComponent
- Campo input para email del cliente
- Validación: email válido
- Checkbox: "Enviar factura por email después de emitir"
- Botón "Enviar Factura por Email" en vista de factura emitida

Servicio FacturaService:
- descargarPDF(facturaId): Promise<Blob>
- descargarXML(facturaId): Promise<Blob>
- enviarPorEmail(facturaId, email): Promise response

Secuencia:
1. Usuario emite factura
2. Sistema calcula CUF
3. Sistema genera XML
4. Sistema firma XML
5. Sistema produce PDF con QR
6. Sistema envía email automáticamente (async)
7. Pantalla muestra confirmación

Referencia SIN:
  https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/algoritmos-utilizados/codigo-respuesta-rapida-qr
```

**Subtareas:**
- [ ] BACKEND: Implementar generación de QR con ZXing
- [ ] BACKEND: Implementar generación de PDF con iText
- [ ] BACKEND: Implementar servicio de email
- [ ] BACKEND: Crear entity ClienteContacto
- [ ] BACKEND: Endpoint para enviar email manual
- [ ] BACKEND: Implementar reintentos de email
- [ ] FRONTEND: Crear formulario de contacto
- [ ] FRONTEND: Componentes para descargar PDF/XML
- [ ] FRONTEND: Componente para reenviar email
- [ ] Tests de generación QR/PDF
- [ ] Tests de envío email

**Prioridad:** P1 - High
**Estimación:** 13 pts

---

## REQUERIMIENTOS NO FUNCIONALES

---

### TICKET: SFE-013
**Título:** Cifrado de Llaves Privadas y Control de Acceso con Keycloak

**Tipo:** Backend (Spring Boot)  
**Microservicio:** Sí - `auth-service`  
**Prioridad:** P0 - Critical  
**Estimación:** 13 pts  
**Fecha Inicio:** 01/04/2026  
**Fecha Conclusión:** 20/04/2026  

**Documentación Requerida:**
- 📖 [Firma Digital](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/firma-digital/firma-digital)

**Descripción:**
Implementar cifrado AES-256-CBC de llaves privadas de certificados digitales y control de acceso mediante Keycloak con roles (Emisor, Administrador, Auditor).

**Criterios de Aceptación:**
- [ ] Llaves privadas se cifran con AES-256-CBC
- [ ] Keycloak valida identidad y roles
- [ ] Solo usuarios autorizados pueden firmar
- [ ] Acceso se registra en auditoría

**Especificaciones Técnicas:**

```
Backend:

1. Cifrado AES-256-CBC:

   Dependencias:
   - org.springframework.security:spring-security-crypto
   - org.bouncycastle:bcprov-jdk15on
   
   Configuración:
   
   @Configuration
   public class EncryptionConfig {
       @Bean
       public EncryptionService encryptionService() {
           return new EncryptionService(
               "application.security.encryption.key", // 32 bytes para AES-256
               "application.security.encryption.salt"
           );
       }
   }
   
   Servicio EncryptionService:
   
   public class EncryptionService {
       private final String encryptionKey;
       private final String salt;
       
       public String encrypt(String plaintext) throws Exception {
           Cipher cipher = Cipher.getInstance("AES/CBC/PKCS5Padding");
           SecretKeySpec keySpec = new SecretKeySpec(
               encryptionKey.getBytes(), 0, 32, "AES"
           );
           IvParameterSpec ivSpec = new IvParameterSpec(
               salt.getBytes()
           );
           cipher.init(Cipher.ENCRYPT_MODE, keySpec, ivSpec);
           byte[] encrypted = cipher.doFinal(plaintext.getBytes());
           return Base64.getEncoder().encodeToString(encrypted);
       }
       
       public String decrypt(String encrypted) throws Exception {
           Cipher cipher = Cipher.getInstance("AES/CBC/PKCS5Padding");
           SecretKeySpec keySpec = new SecretKeySpec(
               encryptionKey.getBytes(), 0, 32, "AES"
           );
           IvParameterSpec ivSpec = new IvParameterSpec(
               salt.getBytes()
           );
           cipher.init(Cipher.DECRYPT_MODE, keySpec, ivSpec);
           byte[] decodedBytes = Base64.getDecoder().decode(encrypted);
           byte[] decrypted = cipher.doFinal(decodedBytes);
           return new String(decrypted);
       }
   }
   
   Entity CertificadoDigital:
   ```java
   @Entity
   @Table(name = "certificados_digitales")
   public class CertificadoDigital {
       @Id
       private UUID id;
       
       @Column(nullable = false)
       private String nit;
       
       @Lob
       @Column(nullable = false, columnDefinition = "LONGBLOB")
       private String privadoCifrado; // <- almacenado cifrado
       
       @Lob
       @Column(nullable = false, columnDefinition = "LONGBLOB")
       private String publicoX509; // <- sin cifrado
       
       @Column(nullable = false)
       private LocalDateTime fechaInicio;
       
       @Column(nullable = false)
       private LocalDateTime fechaVencimiento;
       
       @Enumerated(EnumType.STRING)
       private EstadoCertificado estado;
       
       // Getters/Setters
       public String getPrivadoDescifrado(EncryptionService encryptionService) 
           throws Exception {
           return encryptionService.decrypt(this.privadoCifrado);
       }
   }
   ```

2. Integración Keycloak:

   Dependencias:
   - org.keycloak:keycloak-spring-boot-starter
   - org.springframework.security:spring-security-oauth2-resource-server
   
   application.yml:
   ```yaml
   keycloak:
     realm: facturacion
     auth-server-url: https://keycloak.example.com/auth
     ssl-required: external
     resource: facturacion-api
     public-client: false
     credentials:
       secret: ${KEYCLOAK_SECRET}
   ```
   
   Configuración de Seguridad:
   ```java
   @Configuration
   @EnableWebSecurity
   public class SecurityConfig extends WebSecurityConfigurerAdapter {
       @Override
       protected void configure(HttpSecurity http) throws Exception {
           http
               .authorizeRequests()
               .antMatchers("/public/**").permitAll()
               .antMatchers("/api/v1/facturas/emitir").hasRole("EMISOR")
               .antMatchers("/api/v1/certificados/**").hasRole("ADMIN")
               .antMatchers("/api/v1/auditoria/**").hasRole("AUDITOR")
               .anyRequest().authenticated()
               .and()
               .oauth2ResourceServer()
               .jwt();
       }
   }
   ```

3. Controles de Acceso:

   Roles en Keycloak:
   - EMISOR: puede emitir facturas, usar certificados
   - ADMINISTRADOR: puede gestionar certificados, tokens, usuarios
   - AUDITOR: acceso solo lectura a historial, facturas, logs
   
   Anotación Personalizada:
   ```java
   @Target(ElementType.METHOD)
   @Retention(RetentionPolicy.RUNTIME)
   public @interface RequiereRol {
       String[] roles();
   }
   ```
   
   Uso:
   ```java
   @PostMapping("/api/v1/facturas/emitir")
   @RequiereRol(roles = {"EMISOR", "ADMINISTRADOR"})
   public ResponseEntity<?> emitirFactura(@RequestBody Factura factura) {
       // lógica
   }
   ```

4. Auditoría de Acceso:

   Entity AuditoriaAcceso:
   ```java
   @Entity
   @Table(name = "auditoria_acceso")
   public class AuditoriaAcceso {
       @Id
       private UUID id;
       
       @Column(nullable = false)
       private String usuario; // del JWT
       
       @Column(nullable = false)
       private String accion; // "EMITIR_FACTURA", "FIRMAR_XML", etc
       
       @Column(nullable = false)
       private LocalDateTime fechaHora;
       
       @Column(nullable = false)
       private String resultado; // "EXITO", "ERROR"
       
       private String detalleError;
       
       @Column(nullable = false)
       private String ipOrigen;
       
       private String recursos; // IDs de facturas/certs afectados
   }
   ```
   
   Interceptor:
   ```java
   @Component
   public class AuditoriaInterceptor implements HandlerInterceptor {
       @Override
       public boolean preHandle(HttpServletRequest request, 
                                HttpServletResponse response, 
                                Object handler) {
           // Extraer usuario del JWT
           String usuario = extraerUsuarioDelJWT(request);
           request.setAttribute("usuario", usuario);
           request.setAttribute("ipOrigen", request.getRemoteAddr());
           return true;
       }
   }
   ```

Referencia SIN:
  https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/firma-digital/firma-digital
```

**Subtareas:**
- [ ] Configurar Keycloak
- [ ] Implementar servicio de encriptación AES-256
- [ ] Integrar Spring Security con OAuth2
- [ ] Crear entidades de auditoría
- [ ] Implementar interceptor de auditoría
- [ ] Crear tests de seguridad
- [ ] Documentar roles y permisos

**Prioridad:** P0 - Critical
**Estimación:** 13 pts

---

### TICKET: SFE-014
**Título:** Implementar Retry Logic y Resiliencia

**Tipo:** Backend (Spring Boot)  
**Microservicio:** No - Infrastructure layer (compartida)  
**Prioridad:** P0 - Critical  
**Estimación:** 8 pts  
**Fecha Inicio:** 21/04/2026  
**Fecha Conclusión:** 30/04/2026  

**Documentación Requerida:**
- 📖 [Códigos de Error SIAT](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/codigos-error-siat)

**Descripción:**
Implementar lógica de reintento automático ante errores de servidor del SIN (5xx) con backoff exponencial, diferenciando errores recuperables de no recuperables.

**Criterios de Aceptación:**
- [ ] Reintento automático ante error 500 del SIN
- [ ] Espera exponencial entre reintentos (2s, 4s, 8s)
- [ ] Máximo 3 reintentos
- [ ] Errores 4xx no se reintent an
- [ ] Administrador se notifica si fallan 3 intentos

**Especificaciones Técnicas:**

```
Dependencias:
- org.springframework.retry:spring-retry
- io.github.resilience4j:resilience4j-spring-boot2-starter
- io.github.resilience4j:resilience4j-retry

Configuración:

@Configuration
@EnableRetry
public class RetryConfig {
    
    @Bean
    public RetryTemplate retryTemplate() {
        RetryTemplate template = new RetryTemplate();
        
        // Política de backoff exponencial
        ExponentialBackOffPolicy backOffPolicy = new ExponentialBackOffPolicy();
        backOffPolicy.setInitialInterval(2000); // 2 segundos
        backOffPolicy.setMultiplier(2.0); // 2x cada intento
        backOffPolicy.setMaxInterval(8000); // máximo 8 segundos
        template.setBackOffPolicy(backOffPolicy);
        
        // Política de reintento
        SimpleRetryPolicy retryPolicy = new SimpleRetryPolicy();
        retryPolicy.setMaxAttempts(3);
        template.setRetryPolicy(retryPolicy);
        
        // Establecer recuperables vs no recuperables
        template.setRetryContextCache(new MapRetryContextCache());
        
        return template;
    }
}

Servicio SOAP con Retry:

@Service
public class SIATSoapService {
    
    private final RetryTemplate retryTemplate;
    private final NotificationService notificationService;
    
    @Retryable(
        value = {HttpServerErrorException.InternalServerError.class, 
                 HttpServerErrorException.BadGateway.class,
                 HttpServerErrorException.ServiceUnavailable.class},
        maxAttempts = 3,
        backoff = @Backoff(
            delay = 2000,
            multiplier = 2.0,
            maxDelay = 8000
        )
    )
    public SolicitudCUISResponse solicitudCUIS(SolicitudCUISRequest request) {
        try {
            return llamarServicioSIN(request);
        } catch (HttpServerErrorException e) {
            // Log del intento
            logger.warn("Error en SolicitudCUIS, reintentando...", e);
            throw e; // Re-lanzar para que @Retryable maneje el reintento
        }
    }
    
    @Recover
    public SolicitudCUISResponse recuperarSolicitudCUIS(
        Exception ex, 
        SolicitudCUISRequest request) {
        // Se ejecuta después de que fallan todos los reintentos
        logger.error("Falló SolicitudCUIS después de 3 intentos", ex);
        notificationService.notificarAdministrador(
            "Error en SolicitudCUIS para NIT: " + request.getNit(),
            ex.getMessage()
        );
        throw new ApiException("No se pudo obtener CUIS después de 3 intentos", ex);
    }
}

Diferenciación de Errores:

public class HttpErrorHandler {
    
    public static boolean esRecuperable(HttpStatusCode statusCode) {
        // Errores de servidor (recuperables con retry)
        return statusCode.value() >= 500 && statusCode.value() < 600;
    }
    
    public static boolean esErrorCliente(HttpStatusCode statusCode) {
        // Errores de cliente (NO recuperables)
        return statusCode.value() >= 400 && statusCode.value() < 500;
    }
}

Uso:

try {
    SolicitudCUISResponse response = siatSoapService.solicitudCUIS(request);
} catch (HttpClientErrorException e) {
    // Error 4xx: no reintenta
    logger.error("Error en solicitud: " + e.getStatusCode(), e);
    throw new BusinessException("Solicitud inválida...");
} catch (HttpServerErrorException e) {
    // Error 5xx: @Retryable ya maneja
    throw e;
}

Resilience4j Alternative:

@Retry(name = "siatSoapRetry")
@CircuitBreaker(name = "siatSoapCircuitBreaker")
public SolicitudCUISResponse solicitudCUIS(SolicitudCUISRequest request) {
    return llamarServicioSIN(request);
}

Configuración en application.yml:

resilience4j:
  retry:
    instances:
      siatSoapRetry:
        maxAttempts: 3
        waitDuration: 2000
        intervalFunction: exponential
        exponentialRandomizationFactor: 0.5
        retryExceptions:
          - java.io.IOException
          - org.springframework.web.client.HttpServerErrorException
        ignoreExceptions:
          - org.springframework.web.client.HttpClientErrorException
  
  circuitbreaker:
    instances:
      siatSoapCircuitBreaker:
        registerHealthIndicator: true
        slidingWindowType: COUNT_BASED
        slidingWindowSize: 10
        minimumNumberOfCalls: 5
        automaticTransitionFromOpenToHalfOpenEnabled: true
        waitDurationInOpenState: 60000
        failureRateThreshold: 50.0
        slowCallRateThreshold: 100.0
        slowCallDurationThreshold: 5000
```

**Subtareas:**
- [ ] Configurar Spring Retry
- [ ] Implementar decoradores @Retryable en servicios SOAP
- [ ] Implementar diferenciación de errores 4xx vs 5xx
- [ ] Implementar circuit breaker con Resilience4j
- [ ] Crear servicio de notificación a administrador
- [ ] Tests de retry con fallos simulados
- [ ] Monitoreo de intentos y failures

**Prioridad:** P0 - Critical
**Estimación:** 8 pts

---

### TICKET: SFE-015
**Título:** Optimización de Performance - Firma Digital < 2 segundos

**Tipo:** Backend (Spring Boot)  
**Microservicio:** Sí - `firma-digital-service`  
**Prioridad:** P1 - High  
**Estimación:** 13 pts  
**Fecha Inicio:** 29/04/2026  
**Fecha Conclusión:** 20/05/2026  

**Documentación Requerida:**
- 📖 [Firma Digital SIAT - Especificación](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/firma-digital/firmado-de-xml)
- 📖 [Certificados Digitales Bolivia](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/firma-digital)

**Descripción:**
Optimizar proceso de firma digital para que se complete en menos de 2 segundos, incluyendo canonicalización, cálculo de hash, encriptación y codificación.

**Criterios de Aceptación:**
- [ ] Tiempo total firma < 2000ms
- [ ] Canonicalización < 300ms
- [ ] Cálculo SHA256 < 100ms
- [ ] Encriptación RSA < 1000ms
- [ ] JMH Benchmark: promedio < 2000ms
- [ ] Tests de performance: 100 firmas paralelas < 200s

**Subtareas:**
- [ ] Ejecutar profiling inicial
- [ ] Cachear certificado en memoria
- [ ] Optimizar canonicalización
- [ ] Implementar thread pools
- [ ] Implementar procesamiento paralelo
- [ ] Crear benchmark JMH
- [ ] Crear tests de performance
- [ ] Configurar Prometheus + Grafana
- [ ] Documentar resultados

---

### TICKET: SFE-016
**Título:** Almacenamiento Persistente de Facturas - 8 años

**Tipo:** Backend (Spring Boot)  
**Microservicio:** Sí - `storage-service`  
**Prioridad:** P0 - Critical  
**Estimación:** 13 pts  
**Fecha Inicio:** 20/05/2026  
**Fecha Conclusión:** 10/06/2026  

**Documentación Requerida:**
- 📖 [Requerimientos de Almacenamiento SIAT](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/requerimientos/sistema-informatico)
- 📖 [Auditoría de Facturas](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/auditoria/historial-facturas)

**Descripción:**
Implementar estrategia de almacenamiento durable de todas las facturas, XMLs, PDFs y metadatos durante 8 años con redundancia, verificación de integridad y auditoría.

**Criterios de Aceptación:**
- [ ] XML original se almacena para todas las facturas
- [ ] Metadatos se asocian correctamente
- [ ] Hash de integridad se calcula y verifica
- [ ] Almacenamiento es redundante (2+ copias)
- [ ] Datos están disponibles 8 años

**Subtareas:**
- [ ] Diseñar schema BD para almacenamiento persistente
- [ ] Implementar entity Factura con campos obligatorios
- [ ] Implementar entidad FacturaIntegridad para verificación
- [ ] Implementar auditoría de acceso y recuperación
- [ ] Configurar redundancia y backups
- [ ] Implementar políticas de retención de 8 años
- [ ] Crear índices para búsquedas por NIT/número factura
- [ ] Crear tests de integridad de datos
- [ ] Documentar procedimiento de auditoría y recuperación

---

## TABLA RESUMEN DE TICKETS

| # | Ticket | Títul | Tipo | Microservice | P | Pts | Inicio | Fin |
|---|--------|-------|------|-------------|---|-----|--------|-----|
## TABLA RESUMEN DE TICKETS

| # | Ticket | Título | Tipo | Microservice | P | Pts | Inicio | Fin | Linear ID |
|---|--------|--------|------|-------------|---|-----|--------|-----|-----------|
| 0.1 | SFE-ANALISIS-001 | Análisis Requerimientos SIN | Análisis | N/A | P0 | 3 | 01/04 | 02/04 | INF-133 |
| 0.2 | SFE-PLAN-001 | Planificación Arquitectura | Planificación | N/A | P0 | 5 | 06/04 | 07/04 | INF-134 |
| 1 | SFE-001 | Token Delegado | Backend | siat-auth-service | P0 | 5 | 01/04 | 10/04 | INF-106 |
| 2 | SFE-002 | CUIS Renovación | Backend | cuis-service | P0 | 8 | 11/04 | 24/04 | INF-107 |
| 3 | SFE-003 | CUFD Renovación | Backend | cufd-service | P0 | 8 | 11/04 | 24/04 | INF-108 |
| 4 | SFE-004.1 | Firma Digital - Algoritmos | Backend | firma-digital-service | P0 | 8 | 25/04 | 10/05 | INF-109 |
| 4.2 | SFE-004.2 | Firma Digital - Implementación | Backend | firma-digital-service | P0 | 5 | 11/05 | 15/05 | INF-110 |
| 5.1 | SFE-005.1 | XML Generación - Sector Estándar | Backend | factura-service | P0 | 5 | 14/04 | 22/04 | INF-111 |
| 5.2 | SFE-005.2 | XML Generación - Sectores Especiales | Backend | factura-service | P0 | 5 | 23/04 | 29/04 | INF-124 |
| 5.3 | SFE-005.3 | XML Generación - Reintegros | Backend | factura-service | P0 | 3 | 30/04 | 06/05 | INF-125 |
| 6 | SFE-006 | CUF Cálculo | Backend | numero-factura-service | P0 | 3 | 21/04 | 24/04 | INF-112 |
| 7 | SFE-007 | Anulación | Backend | factura-service | P1 | 8 | 27/04 | 11/05 | INF-113 |
| 8 | SFE-008 | Reversión | Backend | factura-service | P1 | 8 | 18/05 | 25/06 | INF-128 |
| 9 | SFE-009 | Homologación | Fullstack | catalogo-service | P1 | 13 | 28/04 | 17/05 | INF-114 |
| 9.1 | SFE-009.1 | Homologación Frontend | Frontend | Angular | P1 | 8 | 28/04 | 17/05 | INF-129 |
| 10 | SFE-010 | Detección Contingencia | Backend | contingencia-service | P0 | 13 | 15/05 | 04/06 | INF-115 |
| 11 | SFE-011 | Paquetes Masivos | Backend | paquete-service | P0 | 13 | 05/06 | 25/06 | INF-116 |
| 12.1 | SFE-012.1 | QR Validación | Backend | pdf-service | P1 | 3 | 26/06 | 15/07 | INF-117 |
| 12.2 | SFE-012.2 | PDF con QR | Backend | pdf-service | P1 | 5 | 26/06 | 15/07 | INF-118 |
| 12.3 | SFE-012.3 | Email Factura | Fullstack | email-service | P1 | 5 | 26/06 | 15/07 | INF-119 |
| 13 | SFE-013 | Cifrado + Keycloak | Backend | auth-service | P0 | 13 | 01/04 | 20/04 | INF-120 |
| 14 | SFE-014 | Retry Logic | Backend | Infrastructure | P0 | 8 | 25/04 | 20/05 | INF-121 |
| 15 | SFE-015 | Performance < 2s | Backend | firma-digital-service | P1 | 13 | 29/04 | 20/05 | INF-122 |
| 16 | SFE-016 | Almacenamiento 8 años | Backend | storage-service | P0 | 13 | 20/05 | 10/06 | INF-123 |
| F001 | SFE-F001 | Frontend Config | Frontend | Angular | P1 | 8 | 28/04 | 15/07 | INF-130 |
| F002 | SFE-F002 | Dashboard Monitoreo | Frontend | Angular | P1 | 8 | 26/06 | 15/07 | INF-131 |

**Total de Tickets:** 26  
**Total Story Points:** 193 pts

---

## PLAN DE EJECUCIÓN

**Sprint 1 (15/03 - 05/04):** RF-01 a RF-05
- SFE-001: Token Delegado (5 pts)
- SFE-002/003: CUIS/CUFD (16 pts)
- SFE-006: CUF Cálculo (3 pts)
- SFE-009: Homologación frontal (13 pts)
- SFE-013: Cifrado + Keycloak (13 pts)
Total: 50 pts

**Sprint 2 (06/04 - 24/04):**
- SFE-004: Firma Digital (13 pts)
- SFE-014: Retry Logic (8 pts)
- SFE-015: Performance (13 pts)
Total: 34 pts

**Sprint 3 (25/04 - 14/05):**
- SFE-005: XML Generación (13 pts)
- SFE-007: Anulación (8 pts)
- SFE-016: Almacenamiento 8 años (13 pts)
Total: 34 pts

**Sprint 4 (15/05 - 10/07):**
- SFE-008: Reversión (8 pts)
- SFE-010: Contingencia (5 pts)
- SFE-011: Paquetes (8 pts)
- SFE-012: Email + QR + PDF (13 pts)
Total: 34 pts

**Estimación Total: 152 pts**

@Entity
@Table(name = "factura_integridad")
public class FacturaIntegridad {
    @Id
    private UUID id;
    
    @ManyToOne
    @JoinColumn(name = "factura_id", nullable = false)
    private Factura factura;
    
    @Column(nullable = false)
    private String hashSHA256Almacenado; // al momento de guardar
    
    @Column(nullable = false)
    private String hashSHA256Verificado; // al momento de verificar
    
    @Column(nullable = false)
    private LocalDateTime fechaVerificacion;
    
    @Enumerated(EnumType.STRING)
    private EstadoIntegridad estado; // OK, CORRUPTO, FALTANTE
    
    @Column(nullable = false)
    private String ubicacionAlmacenamiento; // local, backup, cloud
    
    private String detalleError;
}

Estrategia de Almacenamiento Redundante:

1. Almacenamiento Local (SSD):
   - Base de datos relacional (MySQL/PostgreSQL)
   - BLOB almacenados en BD
   - Acceso rápido
   - Backup local diario

2. Almacenamiento Backup (NAS):
   - Sistema de almacenamiento en red
   - Copia exacta de BD
   - Sincronización cada 6 horas
   - Separado físicamente del servidor principal

3. Almacenamiento Cloud (Opcional):
   - AWS S3 o Azure Blob Storage (con encriptación)
   - Backup mensual de datos críticos
   - Encriptación AES-256 en tránsito
   - Replicación geográfica

Configuración de Retención:

application.yml:
```yaml
facturacion:
  almacenamiento:
    # Retención de datos
    retencion-años: 8
    fecha-inicio-calculo: fechaCreacionRegistro
    
    # Local
    local:
      ruta: /data/facturas
      espacio-minimo-gb: 500
    
    # Backup
    backup:
      ruta: /backup/facturas
      frecuencia-horas: 6
      replicar-activo: true
    
    # Cloud (opcional)
    cloud:
      activo: false
      proveedor: aws # o azure
      bucket: facturas-backup
      region: us-east-1
      encriptacion: AES256
```

Lógica de Elimación (postdata-8years):

@Component
@Scheduled(cron = "0 2 * * 0") // Domingos 2 AM
public class PoliticaRetencionFacturas {
    
    public void verificarFacturasAntiguasParaEliminacion() {
        LocalDateTime hace8Anios = LocalDateTime.now().minusYears(8);
        
        List<Factura> facturasAntiguas = facturaRepository
            .findByFechaCreacionRegistroBefore(hace8Anios);
        
        for (Factura factura : facturasAntiguas) {
            // Verificar integridad antes de eliminar
            boolean integraOk = verificarIntegridad(factura);
            
            if (integraOk) {
                // Guardar en archivo histórico
                archivarFactura(factura);
                
                // Eliminar de BD activa
                facturaRepository.delete(factura);
                
                // Registrar disposición
                registrarDisposicion(factura, "ARCHIVADA", "Retención completada");
            }
        }
    }
}

Verificación de Integridad:

@Service
public class IntegridadFacturaService {
    
    public boolean verificarIntegridad(Factura factura) {
        // Calcular hash actual
        String hashActual = calcularSHA256(factura.getXmlFirmado());
        
        // Comparar con hash almacenado
        boolean integra = hashActual.equals(factura.getHashSHA256XML());
        
        // Registrar verificación
        FacturaIntegridad integridad = new FacturaIntegridad();
        integridad.setFactura(factura);
        integridad.setHashSHA256Almacenado(factura.getHashSHA256XML());
        integridad.setHashSHA256Verificado(hashActual);
        integridad.setFechaVerificacion(LocalDateTime.now());
        integridad.setEstado(integra ? EstadoIntegridad.OK : EstadoIntegridad.CORRUPTO);
        
        integridadRepository.save(integridad);
        
        return integra;
    }
}

Recuperación para Auditoría:

@Service
public class AuditoriaFacturaService {
    
    public FacturaHistoricaDTO obtenerFacturaParaAuditoria(
        String nit, 
        String numeroFactura, 
        LocalDate fecha) {
        
        // Buscar por NIT, número y fecha
        Factura factura = facturaRepository
            .findByNitAndNumeroFacturaAndFechaEmision(
                nit, numeroFactura, fecha.atStartOfDay());
        
        if (factura == null) {
            throw new FacturaNoEncontradaException(
                "Factura " + numeroFactura + " no encontrada");
        }
        
        // Verificar integridad
        boolean integra = integridad Service.verificarIntegridad(factura);
        
        if (!integra) {
            logger.warn("Integridad comprometida para factura: " + numeroFactura);
        }
        
        FacturaHistoricaDTO dto = new FacturaHistoricaDTO();
        dto.setFactura(factura);
        dto.setIntegra(integra);
        dto.setFechaRecuperacion(LocalDateTime.now());
        dto.setUsuarioAuditor(obtenerUsuarioActual());
        
        // Registrar acceso en auditoría
        registrarAccesoAuditoria(dto);
        
        return dto;
    }
}

Monitoreo de Espacio:

@Component
public class MonitorAlmacenamiento {
    
    @Scheduled(cron = "0 */12 * * *") // Cada 12 horas
    public void verificarEspacioDisponible() {
        long espacioLocalGB = obtenerEspacioDisponible("/data/facturas");
        long espacioBackupGB = obtenerEspacioDisponible("/backup/facturas");
        
        if (espacioLocalGB < 100) {
            alertarAdministrador("Espacio local bajo: " + espacioLocalGB + "GB");
        }
        
        if (espacioBackupGB < 100) {
            alertarAdministrador("Espacio backup bajo: " + espacioBackupGB + "GB");
        }
    }
}

Referencia SIN:
  https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/requerimientos/sistema-informatico
```

**Subtareas:**
- [ ] Diseñar schema BD para almacenamiento persistente
- [ ] Implementar almacenamiento de XMLs/PDFs
- [ ] Implementar cálculo y verificación de hash
- [ ] Implementar política de retención (8 años)
- [ ] Configurar sincronización NAS
- [ ] Configurar backup a cloud (opcional)
- [ ] Crear scheduler de disposición de datos antiguos
- [ ] Crear utility de recuperación para auditoría
- [ ] Crear monitoreo de espacio
- [ ] Tests de integridad
- [ ] Documentación de política de retención

**Prioridad:** P0 - Critical
**Estimación:** 13 pts

---

## RESUMEN DE TICKETS

| Ticket | Título | Stack | Pts | Prioridad |
|--------|--------|-------|-----|-----------|
| SFE-001 | Gestión de Token Delegado | Backend | 5 | P0 |
| SFE-002 | Renovación CUIS (Anual) | Backend | 8 | P0 |
| SFE-003 | Renovación CUFD (Diaria) | Backend | 8 | P0 |
| SFE-004 | Firma Digital XML | Backend | 13 | P0 |
| SFE-005 | Generar XML Compra-Venta | Backend | 13 | P0 |
| SFE-006 | Calcular CUF (Módulo 11) | Backend | 3 | P1 |
| SFE-007 | Anulación de Facturas | Backend | 8 | P1 |
| SFE-008 | Reversión de Anulación | Backend | 5 | P2 |
| SFE-009 | Homologación Productos | Backend + Frontend | 13 | P1 |
| SFE-010 | Detección Contingencia | Backend | 13 | P0 |
| SFE-011 | Envío Paquetes Masivos | Backend | 13 | P0 |
| SFE-012 | Email + QR + PDF | Backend + Frontend | 13 | P1 |
| SFE-013 | Seguridad (Keycloak + AES) | Backend | 13 | P0 |
| SFE-014 | Retry Logic | Backend | 8 | P0 |
| SFE-015 | Performance Firma < 2s | Backend | 13 | P1 |
| SFE-016 | Almacenamiento 8 años | Backend | 13 | P0 |
| **TOTAL** | | | **171 pts** | |

---

## Plan de Ejecución Recomendado

**Sprint 1 (P0 - Crítico):**
- SFE-001, SFE-002, SFE-003, SFE-004, SFE-014
- 42 pts

**Sprint 2 (P0 - Crítico):**
- SFE-005, SFE-010, SFE-011, SFE-013, SFE-016
- 65 pts

**Sprint 3 (P1 - Alta):**
- SFE-006, SFE-007, SFE-009, SFE-012, SFE-015
- 51 pts

**Sprint 4 (P2 - Media):**
- SFE-008 + Tests E2E + Integración
- 5 + más

---

## Notas para el Equipo

1. **Documentación de Referencia SIN:** todos los tickets incluyen enlaces a la documentación oficial del SIAT
2. **Estándares de Código:**
   - Usar Java 17+ para Spring Boot 3.x
   - Angular 15+
   - Seguir patrones de diseño: Service, Repository, DTO, Entity
   - Cobertura mínima: 80% de unit tests
3. **Seguridad:**
   - Todas las contraseñas/keys en variables de entorno
   - Encriptación AES-256 obligatoria para datos sensibles
   - Logs de auditoría sin datos PII
4. **Performance:**
   - Métrica SLA principal: firma < 2 segundos
   - Monitoreo con Prometheus/Grafana
   - Tests de carga (JMeter) antes de producción
5. **CI/CD:**
   - Tests automáticos en cada PR
   - Build Docker incluido
   - Deployment con Kubernetes o Docker Compose
