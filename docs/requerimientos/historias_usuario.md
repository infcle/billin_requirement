# Historias de Usuario - Sistema de Facturación Electrónica (SFE)

## 1. Gestión de Token Delegado

### HU-001: Registrar y Usar Token Delegado del SIN

**COMO** administrador del sistema de facturación  
**QUIERO** registrar un token delegado otorgado por el SIN  
**PARA** autenticar las solicitudes del sistema ante los servicios SOAP del SIN

#### Criterios de Aceptación (Gherkin)

```gherkin
Escenario: Registrar token delegado exitosamente
  Dado que tengo un token válido del SIN
  Cuando registro el token en el sistema
  Entonces el token se almacena de forma cifrada
  Y el sistema puede usar el token para autenticar solicitudes

Escenario: Rechazar token inválido
  Dado que intento registrar un token con formato incorrecto
  Cuando envío el token al sistema
  Entonces el sistema rechaza el registro
  Y muestra un mensaje de error indicando el formato requerido

Escenario: Actualizar token existente
  Dado que existe un token registrado en el sistema
  Cuando registro un nuevo token válido
  Entonces el token anterior se reemplaza
  Y el nuevo token se usa en las próximas solicitudes
```

---

## 2. Obtención Automatizada de Códigos

### HU-002: Renovar CUIS Automáticamente Antes de Expiración

**COMO** administrador del sistema  
**QUIERO** que el sistema renueve automáticamente el CUIS antes de su expiración (anual)  
**PARA** evitar interrupciones en la emisión de facturas por código expirado

#### Criterios de Aceptación (Gherkin)

```gherkin
Escenario: Programar renovación de CUIS
  Dado que el CUIS actual expira en 30 días
  Cuando se ejecuta la tarea programada de renovación
  Entonces el sistema invoca el servicio SOAP SolicitudCUIS
  Y envía parámetros: codigoAmbiente, codigoSistema, nit, codigoSucursal, codigoPuntoVenta
  Y recibe nuevo CUIS con fechaVigenciaInicio y fechaVigenciaFin (365 días)
  Y almacena el nuevo código en la base de datos
  Y registra la fecha de renovación

Escenario: Validar CUIS antes de usar
  Dado que el CUIS está próximo a expirar
  Cuando se intenta emitir una factura
  Entonces el sistema verifica que el CUIS sea válido
  Y verifica que la fecha actual esté entre fechaVigenciaInicio y fechaVigenciaFin
  Y si está expirado, solicita uno nuevo antes de proceder

Escenario: Manejar error en renovación
  Dado que la solicitud de renovación de CUIS falla
  Cuando se ejecuta el reintento
  Entonces el sistema reintenta hasta 3 veces
  Y espera 2 segundos entre reintentos (backoff exponencial)
  Y registra el error en el log del sistema
  Y notifica al administrador si falla después de 3 intentos
```

### HU-003: Renovar CUFD Automáticamente Diariamente

**COMO** administrador del sistema  
**QUIERO** que el sistema renueve automáticamente el CUFD cada día antes de su expiración  
**PARA** garantizar que siempre hay un código válido disponible para emitir facturas

#### Criterios de Aceptación (Gherkin)

```gherkin
Escenario: Renovar CUFD diariamente
  Dado que el CUFD actual expira hoy
  Cuando se ejecuta la tarea programada a las 23:00 horas
  Entonces el sistema invoca el servicio SOAP SolicitudCUFD
  Y envía parámetros: codigoAmbiente, codigoSistema, nit, codigoSucursal, codigoPuntoVenta, cuis
  Y recibe nuevo CUFD con fechaVigenciaInicio (hoy) y fechaVigenciaFin (mañana 23:59:59)
  Y almacena el nuevo código con su fecha de expiración
  Y el nuevo CUFD está disponible para usar al día siguiente

Escenario: Usar CUFD válido en emisión
  Dado que existe un CUFD válido en el sistema
  Cuando se emite una factura
  Entonces el sistema verifica que el CUFD sea vigente
  Y verifica que la fecha actual esté entre fechaVigenciaInicio y fechaVigenciaFin
  Y usa el CUFD actual en el XML
  Y registra el CUFD utilizado en la factura

Escenario: Cambiar a nuevo CUFD al expirar
  Dado que el CUFD actual ha expirado
  Cuando se intenta emitir una factura
  Entonces el sistema rechaza el uso del CUFD expirado
  Y solicita un nuevo CUFD al SIN inmediatamente
  Y usa el nuevo CUFD en la factura

Escenario: Obtener nuevo CUFD antes de registrar evento
  Dado que se detecta una contingencia
  Cuando se va a registrar el evento significativo
  Entonces el sistema obtiene un nuevo CUFD ANTES de registrar
  Y esto evita problemas de vigencia durante el envío de paquetes
```

---

## 3. Firma Digital

### HU-004: Firmar Digitalmente Archivos XML

**COMO** sistema de facturación  
**QUIERO** firmar digitalmente los archivos XML de facturas  
**PARA** cumplir con el estándar de firma digital requerido por el SIN

#### Criterios de Aceptación (Gherkin)

```gherkin
Escenario: Firmar XML exitosamente
  Dado que tengo un archivo XML válido de factura
  Y tengo un certificado digital válido (AGETIC o Digicert)
  Cuando ejecuto el proceso de firma
  Entonces el sistema realiza los siguientes pasos:
    1. Canonicaliza el XML (normaliza formato)
    2. Calcula SHA256 del XML canonicalizado
    3. Codifica el hash en Base64
    4. Agrega etiquetas de firma al XML
    5. Calcula SHA256 de la sección SignedInfo
    6. Encripta con RSA SHA256 V2 usando llave privada
    7. Codifica la firma en Base64
    8. Completa SignatureValue con el valor encriptado
    9. Agrega llave pública en X509Certificate
  Y el tiempo total no excede 2 segundos
  Y el archivo firmado contiene estructura válida de firma

Escenario: Rechazar XML inválido
  Dado que tengo un archivo XML con estructura incorrecta
  Cuando intento firmarlo
  Entonces el sistema rechaza la firma
  Y muestra un error indicando el problema en el XML
  Y no genera firma incompleta

Escenario: Usar certificado válido y vigente
  Dado que tengo un certificado digital registrado
  Cuando firmo un XML
  Entonces se usa el certificado correcto
  Y se verifica que el certificado sea vigente
  Y se verifica que el certificado no esté revocado
  Y la firma es verificable por el SIN

Escenario: Validar firma por el SIN
  Dado que envío un XML firmado al SIN
  Cuando el SIN recibe la factura
  Entonces valida que la firma sea correcta
  Y valida que el certificado sea vigente
  Y valida que el certificado no esté revocado
  Y valida que la firma corresponda al NIT del emisor
  Y si todo es válido: código 903 (Recepción Procesada)
  Y si certificado revocado: código 928 (Certificado Revocado)
  Y si firma inválida: código 921 (Firmado Incorrecto)
```

---

## 4. Generación de XML por Sector

### HU-005: Generar XML de Factura de Compra-Venta

**COMO** sistema de facturación  
**QUIERO** generar automáticamente archivos XML de facturas de compra-venta  
**PARA** cumplir con el esquema XSD oficial del SIN

#### Criterios de Aceptación (Gherkin)

```gherkin
Escenario: Generar XML válido de compra-venta
  Dado que tengo datos de una venta (cliente, items, montos)
  Cuando genero el XML de factura
  Entonces el XML cumple con el esquema XSD oficial
  Y contiene todos los campos obligatorios de cabecera
  Y contiene todos los campos obligatorios de detalle
  Y los montos se calculan correctamente

Escenario: Incluir información del cliente
  Dado que tengo datos del cliente (NIT, razón social, tipo documento)
  Cuando genero el XML
  Entonces el XML incluye nitEmisor, razonSocialEmisor, municipio
  Y el XML incluye nombreRazonSocial, numeroDocumento del cliente
  Y el codigoTipoDocumentoIdentidad es válido (1-5)

Escenario: Calcular montos correctamente
  Dado que tengo items con cantidad, precioUnitario y descuentos
  Cuando genero el XML
  Entonces subTotal = (cantidad × precioUnitario) - montoDescuento
  Y montoTotal = Σ(subTotal) - descuentoAdicional
  Y montoTotalMoneda = montoTotal / tipoCambio
  Y Si Gift Card: montoTotalSujetoIva = montoTotal - montoGiftCard
  Y Si no Gift Card: montoTotalSujetoIva = montoTotal

Escenario: Incluir códigos de control
  Dado que genero una factura
  Cuando completo el XML
  Entonces el XML incluye CUF (Código Único de Facturación)
  Y el XML incluye CUFD (Código Único de Facturación Diario)
  Y el XML incluye codigoSucursal y codigoPuntoVenta

Escenario: Validar formato de fecha
  Dado que genero una factura
  Cuando establezco la fecha de emisión
  Entonces la fecha está en formato UTC Extendido
  Y el formato es: "2020-02-15T08:40:12.215"

Escenario: Incluir información de método de pago
  Dado que tengo un método de pago
  Cuando genero el XML
  Entonces codigoMetodoPago es válido (1=Efectivo, 2=Tarjeta, 3=Cheque, 4=Transferencia, 5=Otros)
  Y Si es tarjeta: numeroTarjeta está ofuscado (primeros 4 y últimos 4 dígitos)
```

---

## 5. Algoritmo de Control (CUF)

### HU-006: Calcular Código Único de Facturación (CUF)

**COMO** sistema de facturación  
**QUIERO** calcular automáticamente el CUF usando el Algoritmo Módulo 11  
**PARA** generar un código de control único para cada factura

#### Criterios de Aceptación (Gherkin)

```gherkin
Escenario: Calcular CUF correctamente
  Dado que tengo los datos de una factura (NIT, CUIS, número, fecha)
  Cuando calculo el CUF usando Módulo 11
  Entonces el CUF se calcula según el algoritmo oficial
  Y el resultado es un número de 4 dígitos

Escenario: Validar CUF en factura
  Dado que tengo un CUF calculado
  Cuando valido el CUF
  Entonces el CUF es único para esa factura
  Y el CUF es verificable por el SIN

Escenario: Rechazar cálculo con datos inválidos
  Dado que intento calcular CUF con datos incompletos
  Cuando ejecuto el cálculo
  Entonces el sistema rechaza el cálculo
  Y muestra un error indicando los datos faltantes
```

---

## 6. Gestión de Anulaciones

### HU-007: Anular Documento Fiscal

**COMO** usuario del sistema  
**QUIERO** anular una factura emitida  
**PARA** corregir errores o cambios en la transacción

#### Criterios de Aceptación (Gherkin)

```gherkin
Escenario: Anular factura válida
  Dado que tengo una factura emitida y válida
  Cuando solicito la anulación
  Entonces el sistema marca la factura como anulada
  Y envía la anulación al SIN
  Y registra la fecha y hora de anulación

Escenario: Rechazar anulación de factura no emitida
  Dado que intento anular una factura que no ha sido emitida
  Cuando solicito la anulación
  Entonces el sistema rechaza la solicitud
  Y muestra un mensaje indicando que la factura no existe

Escenario: Registrar motivo de anulación
  Dado que anulo una factura
  Cuando completo el proceso de anulación
  Entonces el sistema registra el motivo de anulación
  Y el motivo es visible en el historial de la factura
```

### HU-008: Revertir Anulación de Documento Fiscal

**COMO** usuario del sistema  
**QUIERO** revertir la anulación de una factura  
**PARA** restaurar una factura anulada por error

#### Criterios de Aceptación (Gherkin)

```gherkin
Escenario: Revertir anulación exitosamente
  Dado que tengo una factura anulada
  Cuando solicito revertir la anulación
  Entonces el sistema marca la factura como válida nuevamente
  Y envía la reversión al SIN
  Y registra la fecha de reversión

Escenario: Rechazar reversión de factura no anulada
  Dado que intento revertir una factura que no está anulada
  Cuando solicito la reversión
  Entonces el sistema rechaza la solicitud
  Y muestra un mensaje indicando que la factura no está anulada
```

---

## 7. Homologación de Ítems

### HU-009: Mapear Productos Internos al Catálogo Oficial

**COMO** administrador del sistema  
**QUIERO** crear una matriz de mapeo entre productos internos y el catálogo oficial del SIN  
**PARA** asegurar que los productos se clasifiquen correctamente en las facturas

#### Criterios de Aceptación (Gherkin)

```gherkin
Escenario: Crear mapeo de producto
  Dado que tengo un producto interno con categoría
  Cuando creo un mapeo al catálogo oficial
  Entonces el producto interno se vincula al código oficial
  Y el mapeo se almacena en la base de datos

Escenario: Usar mapeo en generación de XML
  Dado que tengo un mapeo de producto creado
  Cuando genero una factura con ese producto
  Entonces el XML incluye el código oficial del SIN
  Y no el código interno

Escenario: Rechazar mapeo duplicado
  Dado que existe un mapeo para un producto
  Cuando intento crear otro mapeo para el mismo producto
  Entonces el sistema rechaza la creación
  Y muestra un mensaje indicando que ya existe un mapeo
```

---

## 8. Gestión de Eventos Significativos

### HU-010: Detectar Fallo de Red y Activar Emisión Fuera de Línea

**COMO** sistema de facturación  
**QUIERO** detectar automáticamente fallos de conexión con el SIN  
**PARA** activar la emisión "Fuera de Línea" (Tipo 2) y continuar operando

#### Criterios de Aceptación (Gherkin)

```gherkin
Escenario: Detectar pérdida de conexión
  Dado que el sistema está conectado al SIN
  Cuando se pierde la conexión de red
  Entonces el sistema detecta la pérdida en menos de 5 segundos
  Y registra el evento significativo (Tipo 1: Corte de Internet)
  Y activa el modo fuera de línea (Tipo 2)

Escenario: Cambiar a emisión Tipo 2
  Dado que se ha detectado pérdida de conexión
  Cuando se intenta emitir una factura
  Entonces el sistema emite en modo Tipo 2 (fuera de línea)
  Y usa el CUFD vigente (antes del corte)
  Y almacena la factura localmente en paquetes
  Y genera un comprobante de transacción local
  Y marca la factura como "pendiente de sincronización"

Escenario: Restaurar conexión
  Dado que el sistema está en modo fuera de línea
  Cuando se restaura la conexión con el SIN
  Entonces el sistema detecta la restauración
  Y cambia automáticamente a modo en línea
  Y registra el evento de restauración

Escenario: Tipos de eventos que generan contingencia
  Dado que ocurre un evento significativo
  Cuando el evento es uno de: corte Internet, inaccesibilidad SIN, zona sin Internet, virus/falla software
  Entonces el sistema activa emisión Tipo 2 (fuera de línea)
  Y cuando el evento es: cambio infraestructura, falla hardware, corte energía
  Entonces el sistema usa facturas de contingencia pre-autorizadas

Escenario: Registrar evento hasta 48 horas después
  Dado que finaliza una contingencia
  Cuando se restaura la operación
  Entonces el sistema tiene hasta 48 horas para registrar el evento
  Y invoca el servicio RegistroEventoSignificativo
  Y incluye tipo de evento, fecha inicio, fecha fin, descripción
```

---

## 9. Envío de Paquetes Masivos

### HU-011: Enviar Paquete de Facturas Emitidas en Contingencia

**COMO** sistema de facturación  
**QUIERO** enviar automáticamente un paquete de facturas emitidas durante contingencia  
**PARA** sincronizar las facturas con el SIN una vez restablecida la conexión

#### Criterios de Aceptación (Gherkin)

```gherkin
Escenario: Empaquetar facturas de contingencia
  Dado que existen facturas emitidas en modo fuera de línea
  Cuando se restaura la conexión
  Entonces el sistema agrupa las facturas en un paquete
  Y comprime el paquete en formato GZIP
  Y calcula el SHA-256 del paquete comprimido
  Y prepara el paquete para envío

Escenario: Obtener nuevo CUFD antes de envío
  Dado que se va a enviar un paquete de contingencia
  Cuando se restaura la conexión
  Entonces el sistema obtiene un nuevo CUFD ANTES de enviar
  Y esto evita problemas de vigencia del CUFD durante el envío

Escenario: Enviar paquete al SIN
  Dado que tengo un paquete de facturas listo
  Cuando envío el paquete al SIN
  Entonces invoco el servicio RecepcionPaqueteFacturaElectronica
  Y envío parámetros: codigoAmbiente, codigoSistema, nit, codigoSucursal, codigoPuntoVenta, cuis, cufd, archivo, hashArchivo, fechaEnvio
  Y el SIN recibe el paquete
  Y valida el contenido
  Y retorna un codigoRecepcion único

Escenario: Validar recepción del paquete
  Dado que envié un paquete de facturas
  Cuando consulto el estado de recepción
  Entonces el sistema muestra el estado del paquete
  Y registra la fecha y hora de recepción
  Y marca las facturas como sincronizadas

Escenario: Verificar estado de facturas post-contingencia
  Dado que finaliza el envío de paquetes
  Cuando se completa la sincronización
  Entonces el sistema invoca VerificacionEstadoFactura para cada factura
  Y identifica si fueron registradas en el SIN
  Y anula facturas duplicadas si es necesario
  Y evita duplicidades en el registro
```

---

## 10. Notificación al Cliente

### HU-012: Enviar Factura por Correo Electrónico

**COMO** sistema de facturación  
**QUIERO** enviar automáticamente la factura al correo del cliente  
**PARA** que el cliente reciba el documento fiscal de forma inmediata

#### Criterios de Aceptación (Gherkin)

```gherkin
Escenario: Generar QR de validación
  Dado que tengo una factura emitida exitosamente
  Cuando genero el código QR
  Entonces el QR contiene la URL con parámetros:
    - nit: NIT del emisor
    - cuf: Código Único de Facturación
    - numero: Número correlativo de factura
    - t: Tamaño (1=rollo, 2=media hoja)
  Y la URL es: https://pilotosiat.impuestos.gob.bo/consulta/QR?nit=...&cuf=...&numero=...&t=...
  Y el QR tiene dimensión mínima de 3x3 cm
  Y el QR es legible con dispositivos móviles

Escenario: Generar PDF con QR
  Dado que tengo una factura firmada
  Y tengo un QR generado
  Cuando genero el PDF
  Entonces el PDF incluye:
    - Datos de la factura (cabecera y detalle)
    - Código QR visible (mínimo 3x3 cm)
    - Información del emisor
    - Información del cliente
    - Montos y cálculos
    - Leyenda de actividad económica

Escenario: Enviar factura por email
  Dado que tengo una factura emitida exitosamente
  Y tengo el correo electrónico del cliente
  Cuando se completa la emisión
  Entonces el sistema envía la factura por email
  Y el email incluye el PDF de la factura
  Y el email incluye el XML firmado como adjunto
  Y el email incluye el código QR en el PDF

Escenario: Almacenar datos de contacto
  Dado que tengo datos de un cliente
  Cuando registro el cliente en el sistema
  Entonces el correo electrónico se almacena
  Y el correo se usa para futuras notificaciones
  Y el correo se valida antes de almacenar
```

---

## 11. Requerimientos No Funcionales

### HU-013: Cifrar Llaves Privadas y Gestionar Accesos

**COMO** administrador de seguridad  
**QUIERO** que el sistema cifre las llaves privadas de certificados digitales  
**PARA** proteger la información sensible ante accesos no autorizados

#### Criterios de Aceptación (Gherkin)

```gherkin
Escenario: Almacenar llave privada cifrada
  Dado que registro un certificado digital en el sistema
  Cuando almaceno la llave privada
  Entonces la llave se cifra usando AES-256-CBC
  Y se almacena cifrada en la base de datos
  Y no se guarda nunca en texto plano
  Y solo el administrador puede acceder

Escenario: Controlar acceso mediante Keycloak
  Dado que un usuario intenta acceder a funciones de firmado
  Cuando ingresa al sistema
  Entonces Keycloak valida su identidad
  Y verifica su rol (Emisor, Administrador, Auditor)
  Y solo permite acciones autorizadas para su rol
  Y registra el acceso en el log de auditoría

Escenario: Auditar acceso a certificados
  Dado que se accede a un certificado digital
  Cuando se realiza una operación de firmado
  Entonces se registra: usuario, fecha, hora, operación realizada
  Y el registro es inmutable
  Y se mantiene durante 8 años para auditoría

Escenario: Rotar llaves periódicamente
  Dado que existe un certificado digital
  Cuando expira o se actualiza
  Entonces el sistema permite renovar el certificado
  Y la nueva llave se cifra con los mismos estándares
  Y la llave anterior se revoca
```

### HU-014: Implementar Retry Logic y Resiliencia

**COMO** sistema de facturación  
**QUIERO** implementar lógica de reintento ante errores del servidor SIN  
**PARA** garantizar la disponibilidad ante fallos temporales

#### Criterios de Aceptación (Gherkin)

```gherkin
Escenario: Reintentar ante error 500 del SIN
  Dado que invoco un servicio SOAP del SIN
  Cuando el servidor retorna error 500 (Internal Server Error)
  Entonces el sistema reintenta automáticamente
  Y espera 2 segundos antes del primer reintento
  Y espera 4 segundos antes del segundo reintento (backoff exponencial)
  Y espera 8 segundos antes del tercer reintento
  Y reintenta máximo 3 veces
  Y si sigue fallando después de 3 intentos: registra error y notifica

Escenario: Diferenciar errores recuperables de no recuperables
  Dado que recibo una respuesta del SIN
  Cuando el código es 500, 502, 503 (error servidor)
  Entonces reintento según la lógica de backoff
  Y cuando el código es 400, 401, 404, 422 (error cliente)
  Entonces NO reintento
  Y registro el error inmediatamente

Escenario: Mantener estado consistente en reintentos
  Dado que se está reintentando una solicitud
  Cuando falla y se reintentan
  Entonces el estado del sistema se mantiene consistente
  Y no se generan duplicados
  Y se registra cada intento en el log

Escenario: Alertar si fallan reintentos
  Dado que fallan todos los reintentos de una solicitud crítica
  Cuando se agotan los 3 intentos
  Entonces el sistema notifica al administrador
  Y registra el error con severidad CRÍTICA
  Y permite reintentar manualmente desde la interfaz
```

### HU-015: Optimizar Performance de Firmado

**COMO** usuario del sistema  
**QUIERO** que el firmado y generación de trama de factura sea rápido  
**PARA** garantizar una experiencia de usuario fluida

#### Criterios de Aceptación (Gherkin)

```gherkin
Escenario: Completar firma en menos de 2 segundos
  Dado que tengo un XML válido de factura
  Y tengo un certificado digital cargado
  Cuando ejecuto el proceso de firma
  Entonces el tiempo total es menor a 2 segundos
  Y incluye: canonicalización, cálculo hash, encriptación y codificación

Escenario: Medir tiempo de cada etapa
  Dado que estoy procesando una factura
  Cuando completo el firma
  Entonces registro el tiempo de cada etapa:
    - Canonicalización: < 300ms
    - Cálculo hash: < 100ms
    - Encriptación RSA: < 1000ms
    - Codificación Base64: < 200ms
    - Total: < 2000ms

Escenario: Cachear datos para mejorar performance
  Dado que el sistema procesa múltiples facturas
  Cuando genera facturas consecutivas
  Entonces cachea el certificado en memoria
  Y reutiliza configuraciones de firma
  Y evita operaciones redundantes
  Y mejora la performance en lotes

Escenario: Usar procesamiento paralelo cuando sea posible
  Dado que hay paquetes con múltiples facturas
  Cuando proceso el paquete
  Entonces proceso hasta 4 facturas en paralelo
  Y mantienen la información de auditoría de cada una
  Y cumplen con el límite de 2 segundos por factura
```

### HU-016: Almacenar Facturas Durante 8 Años

**COMO** auditor fiscal  
**QUIERO** que el sistema almacene históricamente todas las facturas por 8 años  
**PARA** cumplir con requisitos de auditoría tributaria

#### Criterios de Aceptación (Gherkin)

```gherkin
Escenario: Almacenar XML original
  Dado que se emite una factura exitosamente
  Cuando finaliza la emisión
  Entonces el sistema almacena:
    - XML firmado completo
    - PDF generado
    - Metadata: fecha, hora, usuario, estado
    - Hash de verificación
  Y los archivos se guardan en el formato original
  Y se valida la integridad del almacenamiento

Escenario: Mantener histórico durante 8 años
  Dado que existen facturas emitidas hace varios años
  Cuando se ejecuta política de retención
  Entonces las facturas se mantienen durante 8 años completos
  Y después de 8 años se pueden archivar o eliminar
  Y se registra la disposición final

Escenario: Garantizar disponibilidad para auditoría
  Dado que un auditor requiere verificar facturas
  Cuando solicita acceso al historial
  Entonces puede recuperar cualquier factura dentro del periodo de retención
  Y la factura incluye todos los datos originales
  Y se registra quien accedió y cuando

Escenario: Verificar integridad de almacenamiento
  Dado que accedo a una factura antigua
  Cuando valido su integridad
  Entonces el hash actual coincide con el hash almacenado
  Y confirma que no ha sido modificada
  Y certifica la autenticidad del documento

Escenario: Usar almacenamiento redundante
  Dado que es un periodo de auditoría crítico
  Cuando se almacenan facturas
  Entonces se usan al menos 2 copias en medios diferentes
    - Local en SSD (acceso rápido)
    - Backup en NAS (redundancia)
    - Opcional: Cloud con encriptación
  Y las copias se sincronizan automáticamente
  Y se verifica regularmente la integridad
```

---

## Matriz de Trazabilidad: RF → HU

| RF | Descripción | Historia de Usuario | Estado |
|---|---|---|---|
| RF-01 | Gestión de Token Delegado | HU-001 | ✓ |
| RF-02 | Obtención Automatizada de Códigos | HU-002, HU-003 | ✓ |
| RF-03 | Firma Digital | HU-004 | ✓ |
| RF-04 | Generación de XML por Sector | HU-005 | ✓ |
| RF-05 | Algoritmo de Control (CUF) | HU-006 | ✓ |
| RF-06 | Gestión de Anulaciones | HU-007, HU-008 | ✓ |
| RF-07 | Homologación de Ítems | HU-009 | ✓ |
| RF-08 | Gestión de Eventos Significativos | HU-010 | ✓ |
| RF-09 | Envío de Paquetes Masivos | HU-011 | ✓ |
| RF-10 | Notificación al Cliente | HU-012 | ✓ |

---

## Matriz de Trazabilidad: RNF → HU

| RNF | Descripción | Historia de Usuario | Estado |
|---|---|---|---|
| RNF-01 | Seguridad de Activos | HU-013 | ✓ |
| RNF-02 | Disponibilidad y Resiliencia | HU-014 | ✓ |
| RNF-03 | Performance | HU-015 | ✓ |
| RNF-04 | Persistencia Legal | HU-016 | ✓ |

Escenario: Manejar email inválido
  Dado que intento enviar una factura a un email inválido
  Cuando el sistema intenta enviar
  Entonces el envío falla
  Y se registra el error
  Y se notifica al usuario para que corrija el email
```

### HU-018: Validar Factura Mediante QR

**COMO** cliente  
**QUIERO** validar que una factura es auténtica escaneando el código QR  
**PARA** verificar que la factura está registrada en el SIN

#### Criterios de Aceptación (Gherkin)

```gherkin
Escenario: Escanear QR y validar factura
  Dado que tengo una factura impresa con código QR
  Cuando escaneo el QR con un dispositivo móvil
  Entonces se abre el portal tributario del SIN
  Y se consulta la base de datos con parámetros: nit, cuf, numero
  Y se muestra el estado de la factura:
    - ✅ Registrada (código 903)
    - ⚠️ Observada (código 904)
    - ❌ Rechazada (código 902)
    - ❌ Anulada (código 905)

Escenario: QR con dimensión correcta
  Dado que tengo un código QR en una factura
  Cuando intento escanearlo
  Entonces el QR tiene dimensión mínima de 3x3 cm
  Y el QR es legible con cámaras de calidad media
  Y el QR tiene contraste alto (fondo blanco, código negro)

Escenario: QR con parámetros correctos
  Dado que tengo un código QR
  Cuando lo escaneo
  Entonces contiene los parámetros correctos:
    - nit: NIT del emisor (correcto)
    - cuf: CUF de la factura (correcto)
    - numero: Número de factura (correcto)
    - t: Tamaño especificado (1 o 2)
```

---

## 11. Seguridad de Activos

### HU-013: Cifrar Llaves Privadas

**COMO** administrador del sistema  
**QUIERO** que las llaves privadas se cifren automáticamente  
**PARA** proteger los activos criptográficos del sistema

#### Criterios de Aceptación (Gherkin)

```gherkin
Escenario: Cifrar llave privada al registrar
  Dado que registro un certificado digital
  Cuando se almacena la llave privada
  Entonces la llave se cifra automáticamente
  Y se usa un algoritmo de cifrado seguro
  Y la llave cifrada se almacena en la base de datos

Escenario: Descifrar llave para usar
  Dado que tengo una llave privada cifrada
  Cuando necesito usar la llave para firmar
  Entonces el sistema descifra la llave
  Y usa la llave descifrada en memoria
  Y descarta la llave descifrada después de usar

Escenario: Rechazar acceso sin autenticación
  Dado que intento acceder a una llave privada
  Cuando no tengo permisos de acceso
  Entonces el sistema rechaza el acceso
  Y registra el intento de acceso no autorizado
```

---

## 12. Disponibilidad y Resiliencia

### HU-014: Reintentar Solicitud ante Error del Servidor

**COMO** sistema de facturación  
**QUIERO** reintentar automáticamente las solicitudes cuando el SIN retorna error 500  
**PARA** mejorar la disponibilidad y reducir fallos transitorios

#### Criterios de Aceptación (Gherkin)

```gherkin
Escenario: Reintentar ante error 500
  Dado que envío una solicitud al SIN
  Cuando el SIN retorna error 500
  Entonces el sistema reintenta la solicitud
  Y espera 2 segundos antes de reintentar
  Y reintenta hasta 3 veces

Escenario: Registrar fallo después de reintentos
  Dado que he reintentado 3 veces sin éxito
  Cuando se agota el número de reintentos
  Entonces el sistema registra el error
  Y notifica al usuario
  Y guarda la solicitud para reintento manual

Escenario: Usar backoff exponencial
  Dado que reintento una solicitud fallida
  Cuando ejecuto los reintentos
  Entonces el tiempo de espera aumenta exponencialmente
  Y el primer reintento espera 2 segundos
  Y el segundo reintento espera 4 segundos
  Y el tercer reintento espera 8 segundos
```

---

## 13. Performance

### HU-015: Completar Firma y Generación en Menos de 2 Segundos

**COMO** usuario del sistema  
**QUIERO** que el proceso de firma y generación de trama sea rápido  
**PARA** no afectar la experiencia del usuario

#### Criterios de Aceptación (Gherkin)

```gherkin
Escenario: Firmar XML en menos de 2 segundos
  Dado que tengo un XML de factura listo
  Cuando ejecuto el proceso de firma
  Entonces el tiempo total no excede 2 segundos
  Y el XML se firma correctamente

Escenario: Generar trama en menos de 2 segundos
  Dado que tengo datos de factura
  Cuando genero la trama XML
  Entonces el tiempo total no excede 2 segundos
  Y la trama es válida

Escenario: Medir performance en carga
  Dado que proceso múltiples facturas
  Cuando mido el tiempo promedio
  Entonces el promedio no excede 1.5 segundos por factura
```

---

## 14. Persistencia Legal

### HU-016: Almacenar XMLs por 8 Años

**COMO** administrador del sistema  
**QUIERO** que los XMLs de facturas se almacenen por un mínimo de 8 años  
**PARA** cumplir con los requisitos de auditoría tributaria

#### Criterios de Aceptación (Gherkin)

```gherkin
Escenario: Almacenar XML de factura
  Dado que emito una factura
  Cuando se completa la emisión
  Entonces el XML se almacena en la base de datos
  Y se registra la fecha de almacenamiento
  Y se establece una fecha de retención de 8 años

Escenario: Recuperar XML almacenado
  Dado que tengo un XML almacenado
  Cuando solicito recuperar el XML
  Entonces el sistema retorna el XML original
  Y el XML es íntegro y sin modificaciones

Escenario: Proteger XMLs de eliminación prematura
  Dado que tengo XMLs almacenados
  Cuando intento eliminar un XML antes de 8 años
  Entonces el sistema rechaza la eliminación
  Y muestra un mensaje indicando la fecha de retención
```

---

## 15. Validación de Identidad

### HU-017: Verificar NIT del Cliente Antes de Procesar

**COMO** sistema de facturación  
**QUIERO** invocar el servicio VerificaNit antes de procesar la emisión  
**PARA** prevenir rechazos por identidad inválida

#### Criterios de Aceptación (Gherkin)

```gherkin
Escenario: Verificar NIT válido
  Dado que tengo un NIT de cliente
  Cuando invoco el servicio SOAP VerificaNit
  Entonces envío parámetros: codigoAmbiente, nit
  Y el SIN confirma que el NIT es válido
  Y retorna razonSocial del cliente
  Y el sistema permite proceder con la factura

Escenario: Rechazar NIT inválido
  Dado que tengo un NIT inválido
  Cuando invoco el servicio VerificaNit
  Entonces el SIN retorna que el NIT es inválido
  Y retorna codigoError
  Y el sistema rechaza la emisión
  Y muestra un mensaje de error al usuario

Escenario: Cachear resultado de verificación
  Dado que verifico un NIT
  Cuando verifico el mismo NIT nuevamente
  Entonces el sistema usa el resultado en caché
  Y no invoca nuevamente el servicio VerificaNit
  Y el caché expira después de 24 horas

Escenario: Usar excepción para NIT inválido en contingencia
  Dado que estoy en modo contingencia
  Y tengo un cliente con NIT inválido
  Cuando emito la factura
  Entonces establezco codigoExcepcion = 1
  Y el sistema permite la emisión en contingencia
  Y registra la excepción en el XML
```

