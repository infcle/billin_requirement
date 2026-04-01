# Criterios de Aceptación Mínimos - Sistema de Facturación Electrónica (SFE)

## Módulo A: Gestión de Conectividad y Seguridad

### RF-01: Gestión de Token Delegado
```gherkin
Escenario: Registrar token delegado válido
  Dado que tengo un token válido del SIN
  Cuando registro el token en el sistema
  Entonces el token se almacena de forma cifrada
  Y el sistema puede usarlo para autenticar solicitudes

Escenario: Rechazar token inválido
  Dado que intento registrar un token con formato incorrecto
  Cuando envío el token al sistema
  Entonces el sistema rechaza el registro
```

### RF-02: Obtención Automatizada de Códigos (CUIS y CUFD)
```gherkin
Escenario: Renovar CUIS antes de expiración
  Dado que el CUIS actual expira en 30 días
  Cuando se ejecuta la tarea de renovación automática
  Entonces se obtiene un nuevo CUIS del SIN
  Y se almacena en la base de datos

Escenario: Renovar CUFD diariamente
  Dado que el CUFD expira hoy
  Cuando se ejecuta la tarea programada
  Entonces se obtiene un nuevo CUFD
  Y el sistema lo usa en las emisiones del día siguiente

Escenario: Validar códigos antes de usar
  Dado que se intenta emitir una factura
  Cuando valido CUIS y CUFD
  Entonces ambos códigos son válidos y vigentes
```

### RF-03: Firma Digital
```gherkin
Escenario: Firmar XML exitosamente
  Dado que tengo un XML válido y un certificado vigente
  Cuando ejecuto el firmado
  Entonces el XML se firma correctamente
  Y el tiempo de firma no excede 2 segundos
  Y la firma es verificable por el SIN

Escenario: Rechazar XML inválido
  Dado que intento firmar un XML con estructura incorrecta
  Cuando ejecuto el firmado
  Entonces el sistema rechaza la operación
```

---

## Módulo B: Emisión y Operaciones Fiscales

### RF-04: Generación de XML por Sector
```gherkin
Escenario: Generar XML válido de compra-venta
  Dado que tengo datos de una venta
  Cuando genero el XML
  Entonces cumple con el esquema XSD oficial
  Y contiene todos los campos obligatorios
  Y es verificable contra el XSD

Escenario: Incluir información requerida
  Dado que genero un XML
  Cuando completo los datos
  Entonces incluye: NIT, CUIS, CUFD, CUF, datos cliente, items, montos
```

### RF-05: Algoritmo de Control (CUF)
```gherkin
Escenario: Calcular CUF correctamente
  Dado que tengo los datos de una factura
  Cuando calculo el CUF con Módulo 11
  Entonces el resultado es un número de 4 dígitos válido
  Y el CUF es único para esa factura
```

### RF-06: Gestión de Anulaciones
```gherkin
Escenario: Anular factura válida
  Dado que tengo una factura emitida
  Cuando solicito la anulación
  Entonces se marca como anulada
  Y se envía al SIN

Escenario: Revertir anulación
  Dado que tengo una factura anulada
  Cuando solicito revertir la anulación
  Entonces se marca como válida nuevamente
```

### RF-07: Homologación de Ítems
```gherkin
Escenario: Mapear producto interno a código oficial
  Dado que tengo un producto interno
  Cuando creo el mapeo
  Entonces se vincula al código oficial del SIN
  Y se usa en futuras facturas

Escenario: Usar mapeo en factura
  Dado que existe un mapeo de producto
  Cuando genero una factura
  Entonces el XML incluye el código oficial
```

---

## Módulo C: Contingencias y Distribución

### RF-08: Gestión de Eventos Significativos
```gherkin
Escenario: Detectar pérdida de conexión
  Dado que existe conexión con el SIN
  Cuando se pierde la conexión
  Entonces el sistema la detecta en menos de 5 segundos
  Y registra el evento significativo

Escenario: Activar emisión Tipo 2 (fuera de línea)
  Dado que se ha detectado pérdida de conexión
  Cuando se intenta emitir una factura
  Entonces emite en modo Tipo 2 (fuera de línea)
  Y almacena la factura localmente

Escenario: Restaurar modo en línea
  Dado que el sistema está en modo fuera de línea
  Cuando se restaura la conexión
  Entonces cambia automáticamente a modo en línea
```

### RF-09: Envío de Paquetes Masivos
```gherkin
Escenario: Empaquetar facturas de contingencia
  Dado que existen facturas emitidas fuera de línea
  Cuando se restaura la conexión
  Entonces se empacan las facturas
  Y se comprime en GZIP
  Y se calcula su SHA-256

Escenario: Enviar paquete al SIN
  Dado que tengo un paquete listo
  Cuando envío al SIN
  Entonces recibo un codigoRecepcion
  Y las facturas se sincronizan

Escenario: Obtener CUFD antes de envío
  Dado que se debe enviar paquete de contingencia
  Cuando se restaura conexión
  Entonces obtiene nuevo CUFD ANTES de enviar
```

### RF-10: Notificación al Cliente
```gherkin
Escenario: Generar QR de validación
  Dado que tengo una factura emitida
  Cuando genero el QR
  Entonces contiene: NIT, CUF, número, parámetro tipo
  Y es legible desde dispositivos móviles

Escenario: Generar PDF con QR
  Dado que tengo factura y QR
  Cuando genero PDF
  Entonces incluye datos de factura
  Y incluye QR visible (mínimo 3x3 cm)

Escenario: Enviar factura por email
  Dado que tengo factura y correo del cliente
  Cuando finaliza la emisión
  Entonces envía email con PDF y XML
```

---

## Requerimientos No Funcionales

### RNF-01: Seguridad de Activos
```gherkin
Escenario: Cifrar llaves privadas
  Dado que registro un certificado
  Cuando almaceno la llave privada
  Entonces se cifra con AES-256-CBC
  Y nunca se guarda en texto plano

Escenario: Controlar acceso con Keycloak
  Dado que un usuario accede al sistema
  Cuando intenta operación de firmado
  Entonces Keycloak valida su rol
  Y solo permite acciones autorizadas

Escenario: Auditar acceso a certificados
  Dado que se usa un certificado
  Cuando se firma un documento
  Entonces se registra: usuario, fecha, hora, operación
```

### RNF-02: Disponibilidad y Resiliencia
```gherkin
Escenario: Reintentar ante error 500
  Dado que invoco un servicio del SIN
  Cuando retorna error 500
  Entonces reintenta automáticamente
  Y espera 2 segundos entre reintentos
  Y máximo 3 reintentos

Escenario: No reintentar errores de cliente
  Dado que recibo error 400, 401, 404
  Cuando el servidor responde
  Entonces NO reintento
  Y registro el error inmediatamente

Escenario: Notificar si fallan reintentos
  Dado que fallan 3 intentos
  Cuando se agotan los reintentos
  Entonces notifica al administrador
```

### RNF-03: Performance
```gherkin
Escenario: Completar firma en menos de 2 segundos
  Dado que tengo XML y certificado
  Cuando ejecuto la firma
  Entonces el tiempo total es < 2 segundos
  Y incluye canonicalización, hash, encriptación

Escenario: Procesar lotes en paralelo
  Dado que hay 4 facturas para procesar
  Cuando proceso el paquete
  Entonces proceso hasta 4 en paralelo
  Y cada una cumple con limite de 2 segundos
```

### RNF-04: Persistencia Legal
```gherkin
Escenario: Almacenar XML original
  Dado que se emite una factura
  Cuando finaliza
  Entonces almacena: XML, PDF, metadata, hash
  Y se guarda en formato original

Escenario: Mantener archivo 8 años
  Dado que existe una factura registrada
  Cuando se cumplen 8 años
  Entonces el archivo está disponible
  Y la integridad está verificada con hash

Escenario: Recuperar fact ura para auditoría
  Dado que un auditor solicita acceso
  Cuando consulta el historial
  Entonces recupera la factura completa
  Y se registra acceso en auditoría

Escenario: Usar almacenamiento redundante
  Dado que se almacena una factura
  Cuando se guarda
  Entonces se replica en al menos 2 ubicaciones
  Y se sincronizan automáticamente
```

---

## Resumen de Criterios por Requerimiento

| ID | Requerimiento | Criterios Mínimos |
|---|---|---|
| RF-01 | Token Delegado | 2 escenarios |
| RF-02 | Códigos (CUIS/CUFD) | 3 escenarios |
| RF-03 | Firma Digital | 2 escenarios |
| RF-04 | XML por Sector | 2 escenarios |
| RF-05 | Algoritmo CUF | 1 escenario |
| RF-06 | Anulaciones | 2 escenarios |
| RF-07 | Homologación | 2 escenarios |
| RF-08 | Eventos Significativos | 3 escenarios |
| RF-09 | Paquetes Masivos | 3 escenarios |
| RF-10 | Notificación Cliente | 3 escenarios |
| RNF-01 | Seguridad | 3 escenarios |
| RNF-02 | Resiliencia | 3 escenarios |
| RNF-03 | Performance | 2 escenarios |
| RNF-04 | Persistencia | 4 escenarios |
| **TOTAL** | | **36 escenarios** |
