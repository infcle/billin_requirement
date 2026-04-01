# Especificación de Requerimientos: Sistema de Facturación Electrónica (SFE)

## 1. Visión General y Contexto

El objetivo es desarrollar un **Sistema Informático de Facturación (SIF)** de modalidad Proveedor, diseñado para integrarse con el ecosistema de servicios SOAP del SIN. El sistema debe ser capaz de gestionar múltiples sectores económicos, garantizando la validez fiscal mediante el uso de tokens delegados y firmas digitales.

---

## 2. Requerimientos Funcionales (RF)

### Módulo A: Gestión de Conectividad y Seguridad

| ID | Requerimiento | Descripción |
|---|---|---|
| **RF-01** | Gestión de Token Delegado | Implementar la interfaz para el registro y uso del token de acceso otorgado por el SIN para sistemas proveedores. |
| **RF-02** | Obtención Automatizada de Códigos | Programar tareas de ejecución periódica para la renovación del CUIS (anual) y del CUFD (diario) antes de su expiración. |
| **RF-03** | Firma Digital | Integrar un módulo de firmado digital para archivos XML bajo el estándar exigido para la modalidad Electrónica en Línea. |

### Módulo B: Emisión y Operaciones Fiscales

| ID | Requerimiento | Descripción |
|---|---|---|
| **RF-04** | Generación de XML por Sector | Dinamizar la creación de archivos XML según el "Documento Sector" (Compra-Venta, Hidrocarburos, Servicios, etc.) cumpliendo con los esquemas XSD oficiales. |
| **RF-05** | Algoritmo de Control (CUF) | Implementar el cálculo del Código Único de Facturación (CUF) utilizando el Algoritmo Módulo 11. |
| **RF-06** | Gestión de Anulaciones | Permitir la anulación y la reversión de anulación de documentos fiscales según los flujos autorizados por el SIAT. |
| **RF-07** | Homologación de Ítems | Desarrollar una matriz de mapeo para relacionar la clasificación interna de productos (categorías/subcategorías) con el catálogo oficial de productos y servicios del SIN. |

### Módulo C: Contingencias y Distribución

| ID | Requerimiento | Descripción |
|---|---|---|
| **RF-08** | Gestión de Eventos Significativos | Capacidad de detectar fallos de red y activar la emisión "Fuera de Línea", registrando el evento según la normativa. |
| **RF-09** | Envío de Paquetes Masivos | Implementar el envío y validación de paquetes de facturas emitidas durante contingencias una vez restablecida la comunicación. |
| **RF-10** | Notificación al Cliente | Almacenar datos de contacto para el envío automatizado del documento fiscal al correo electrónico del cliente. |

---

## 3. Requerimientos No Funcionales (RNF)

| ID | Requerimiento | Descripción |
|---|---|---|
| **RNF-01** | Seguridad de Activos | Cifrado obligatorio de llaves privadas y gestión de accesos mediante Keycloak para el control de roles de emisor. |
| **RNF-02** | Disponibilidad y Resiliencia | Implementación de lógica de reintento (retry logic) ante errores de servidor (500) del SIN. |
| **RNF-03** | Performance | El proceso de firmado y generación de la trama no debe exceder los 2 segundos. |
| **RNF-04** | Persistencia Legal | Garantizar el almacenamiento local de XMLs por un periodo mínimo de 8 años para auditorías tributarias. |

---

## 4. Casos de Uso Críticos para QA

### Caso 1: Emisión Exitosa (Happy Path)
```
Venta → Generación XML → Firma → Validación SIN → Generación PDF/QR → Envío Email
```

### Caso 2: Validación de Identidad
El sistema debe invocar **VerificaNit** antes de procesar el pago para prevenir rechazos.

### Caso 3: Transición a Contingencia
```
Pérdida de conexión → Activación de Emisión Tipo 2 → Guardado local → Sincronización posterior
```

---

## 5. Referencias Técnicas Oficiales

### Documentación de Referencia
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/factura-electronica
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/requerimientos/sistema-informatico
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/requerimientos/esquemas-de-conexion
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/requerimientos/esquemas-de-despliegue
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/requerimientos/sucursales-y-puntos-de-venta
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/requerimientos/homologacion-de-productos-servicios
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/emision-y-envio-de-facturas/solicitud-token
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/emision-y-envio-de-facturas/emision-y-envio
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/emision-y-envio-de-facturas/anulacion-de-documentos-fiscales
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/emision-y-envio-de-facturas/reversion-anulacion-documentos-fiscales
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/emision-y-envio-de-facturas/contingencia-y-eventos-significativos
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/emision-y-envio-de-facturas/ingreso-a-contingencia
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/emision-y-envio-de-facturas/comprobante-de-transaccion
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/autorizacion-de-sistemas/proceso-de-autorizacion
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/autorizacion-de-sistemas/pruebas-para-la-autorizacion-del-sistema-de-facturacion/fase-i-pruebas
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/autorizacion-de-sistemas/pruebas-para-la-autorizacion-del-sistema-de-facturacion/fase-ii-inspeccion
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/autorizacion-de-sistemas/pruebas-para-la-autorizacion-del-sistema-de-facturacion/fase-iii-pruebas-piloto
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/autorizacion-de-sistemas/guia-de-usuario-prorroga
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/autorizacion-de-sistemas/gestion-de-solicitudes-de-autorizacion
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/autorizacion-de-sistemas/renovacion-autorizacion
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/autorizacion-de-sistemas/registro-caracteristicas
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/caracteristicas-sfvl/asociacion-de-sistemas
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/caracteristicas-sfvl/inicio-operaciones
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/codigos/notifica-certificado-revocado
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/codigos/solicitud-cufd
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/codigos/solicitud-cufd-masivo
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/codigos/solicitud-cuis
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/codigos/cuis-masivo
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/codigos/verifica-nit
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/operaciones/cierre-de-operaciones
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/operaciones/cierre-punto-de-venta
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/operaciones/consulta-evento-significativo
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/operaciones/consulta-puntos-de-venta
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/operaciones/registro-evento-significativo
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/operaciones/registro-punto-de-venta
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/operaciones/registro-punto-de-venta-comisionista
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/sincronizacion-codigos-catalogos
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/facturacion-electronica/recepcion-factura-electronica
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/facturacion-electronica/anulacion-factura-electronica
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/facturacion-electronica/reversion-anulacion-factura-electronica
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/facturacion-electronica/recepcion-paquete-factura-electronica
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/facturacion-electronica/validacion-recepcion-paquete-factura-electronica
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/facturacion-electronica/verifica-comunicacion
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/facturacion-electronica/recepcion-masiva-electronica
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/facturacion-electronica/validacion-recepcion-masiva-electronica
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/facturacion-electronica/verificacion-estado-factura-electronica
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/facturacion-electronica/recepcion-anexo-electrolineras-elect
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/facturacion-computarizada/recepcion-factura-computarizada
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/facturacion-computarizada/anulacion-factura-computarizada
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/facturacion-computarizada/reversion-anulacion-factura-computarizada
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/facturacion-computarizada/recepcion-paquete-factura-computarizada
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/facturacion-computarizada/validacion-recepcion-paquete-factura-computarizada
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/facturacion-computarizada/verifica-comunicacion-fact-comp
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/facturacion-computarizada/recepcion-masiva-computarizada
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/facturacion-computarizada/validacion-recepcion-masiva-factura-computarizada
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/facturacion-computarizada/verificacion-estado-factura-computarizada
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/facturacion-computarizada/recepcion-anexo-electrolineras
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/servicio-factura-compra-venta/recepcion-factura-compra-venta
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/servicio-factura-compra-venta/anulacion-factura-compra-venta
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/servicio-factura-compra-venta/recepcion-paquete-compra-venta
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/servicio-factura-compra-venta/validacion-recepcion-paquete-compra-venta
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/servicio-factura-compra-venta/recepcion-masiva-compra-venta
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/servicio-factura-compra-venta/validacion-recepcion-masiva-factura-compra-venta
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/servicio-factura-compra-venta/verificacion-estado-factura-compra-venta
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/servicio-factura-compra-venta/recepcion-archivos-anexos
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/servicio-factura-compra-venta/reversion-anulacion-factura-compra-venta
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/nota-credito-debito-comp/recepcion-nota-credito-debito-computarizada
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/nota-credito-debito-comp/anulacion-nota-credito-debito
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/nota-credito-debito-comp/verifica-estado-nota-fiscal-credito-debito-computarizada
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/nota-credito-debito-comp/verifica-comunicacion
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/nota-credito-debito-comp/reversion-anulacion-documento-ajuste
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/recepcion-masiva-ypfb/recepcion-masiva-contratos-ypfb
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/recepcion-masiva-ypfb/validacion-masiva-contratos-ypfb
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/recepcion-masiva-boletos-aereos/recepcion-masiva-boletos
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/recepcion-masiva-boletos-aereos/validacion-recepcion-masiva-boletos
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/recepcion-masiva-boletos-aereos/anulacion-boleto-aereo
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/recepcion-masiva-boletos-aereos/reversion-anulacion-nota-credito-debito-electronica
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/codigos-error-siat
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-de-compra-y-venta
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/recibo-alquiler-bienes-inmuebles
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-comercial-exportacion
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-comercial-exportacion-libre-consignacion
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-de-venta-en-zona-franca
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-de-servicios-turisticos-y-hospedaje
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-de-seguridad-alimentaria-y-abastecimiento
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-tasa-cero
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-de-compra-venta-moneda-extranjera
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-dutty-free
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-sector-educativo
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-comercializacion-hidrocarburos
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-comercializacion-de-gnv
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-comercializacion-de-gn-y-glp
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-servicios-basicos
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-alcanzada-por-ice
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-entidades-financieras
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-hoteles
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-hospitales-clinicas
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-juegos-azar
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-de-hidrocarburos
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-de-hidrocarburos-no-alcanzada-iehd
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-venta-interna-minerales
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-comercial-exportacion-minera
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-telecomunicaciones
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-prevalorada
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/nota-credito-debito
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-comercial-de-exportacion-de-servicios
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/nota-conciliacion
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/boleto-aereo
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-de-suministro-de-energia
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-de-seguros
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-compra-venta-bonificaciones
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-prevalorada-sin-derecho-a-credito-fiscal
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-servicios-basicos-zona-franca
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-compra-venta-tasas
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/alquiler-zona-franca
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-comercial-exportacion-hidrocarburos
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-importacion-y-comercializacion-de-lubricantes
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-comercial-de-exportacion-precio-venta
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-sector-educativo-zona-franca
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/nota-credito-debito-descuento
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/nota-credito-debito-ice
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-telecomunicaciones-zona-franca
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-hospital-clinica-zona-franca
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-engarrafadoras
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-venta-mineral-banco-central
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-compra-venta-de-insumos-para-la-produccion-de-biodiesel-y-o-diesel-ecologico
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-comercializacion-de-combustible-no-subvencionado
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/validaciones-documentos-sector/validaciones
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/validaciones-documentos-sector/validaciones-cont
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/firma-digital/firma-digital
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/firma-digital/generacion-csr/introduccion-a-csr
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/firma-digital/generacion-csr/generacion-de-csr-para-token
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/firma-digital/generacion-csr/generacion-de-csr-para-software
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/firma-digital/generacion-csr/generacion-de-csr-para-certificados-de-prueba-debian
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/firma-digital/generacion-csr/generacion-de-csr-para-certificados-de-prueba-ubuntu
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/firma-digital/firmado-de-xml
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/firma-digital/firma-invalida
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/firma-digital/signatureschema
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/casos-especiales/lineas-aereas
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/casos-especiales/facturacion-conjunta
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/casos-especiales/facturacion-por-terceros
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/casos-especiales/sap-businessone
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/casos-especiales/manuales-contingencia
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/casos-especiales/facturacion-comisionistas
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/casos-especiales/facturacion-por-terceros-ypfb
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/casos-especiales/facturacion-tasa-cero-iva-ley-n-1613
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/casos-especiales/notas-de-credito-debito
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/algoritmos-utilizados/algoritmo-modulo-11
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/algoritmos-utilizados/generacion-de-sha-256-md5-y-crc32
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/algoritmos-utilizados/base-16
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/algoritmos-utilizados/codigo-respuesta-rapida-qr
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/algoritmos-utilizados/comprimir-gzip
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/algoritmos-utilizados/generacion-cuf
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/algoritmos-utilizados/algoritmo-de-redondeo
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/conexion-punto-a-punto/procedimiento-conexion-proveedores
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/conexion-punto-a-punto/procedimiento-conexion
•	https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/titulos-y-subtitulos-fel
•	https://siatinfo.impuestos.gob.bo/index.php/registro-de-compras-y-ventas/registro-de-ventas/ventas-estandar
•	https://siatinfo.impuestos.gob.bo/index.php/registro-de-compras-y-ventas/registro-de-ventas/ventas-de-combustible/ventas-combustible
•	https://siatinfo.impuestos.gob.bo/index.php/registro-de-compras-y-ventas/registro-de-ventas/ventas-de-combustible/codigos-de-paises
•	https://siatinfo.impuestos.gob.bo/index.php/registro-de-compras-y-ventas/registro-de-ventas/registro-prevaloradas
•	https://siatinfo.impuestos.gob.bo/index.php/registro-de-compras-y-ventas/registro-de-ventas/prevaloradas-telecomunicaciones
•	https://siatinfo.impuestos.gob.bo/index.php/registro-de-compras-y-ventas/registro-de-ventas/reintegro
•	https://siatinfo.impuestos.gob.bo/index.php/registro-de-compras-y-ventas/confirmacion-y-registro-de-compras
•	https://siatinfo.impuestos.gob.bo/index.php/registro-de-compras-y-ventas/descarga-de-formatos
•	https://siatinfo.impuestos.gob.bo/index.php/registro-de-compras-y-ventas/registro-de-compras-serv/introduccion-registro
•	https://siatinfo.impuestos.gob.bo/index.php/registro-de-compras-y-ventas/registro-de-compras-serv/consulta-de-compras
•	https://siatinfo.impuestos.gob.bo/index.php/registro-de-compras-y-ventas/registro-de-compras-serv/confirmacioncompras
•	https://siatinfo.impuestos.gob.bo/index.php/registro-de-compras-y-ventas/registro-de-compras-serv/anulacion-compras
•	https://siatinfo.impuestos.gob.bo/index.php/registro-de-compras-y-ventas/registro-de-compras-serv/recepcion-paquete-compras
•	https://siatinfo.impuestos.gob.bo/index.php/registro-de-compras-y-ventas/registro-de-compras-serv/validacion-recepcion-paquete-de-compras



#### Configuración y Requerimientos del Sistema
- [Requerimientos de Sistema Informático](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/requerimientos/sistema-informatico)
- [Esquemas de Conexión](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/requerimientos/esquemas-de-conexion)
- [Esquemas de Despliegue](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/requerimientos/esquemas-de-despliegue)
- [Sucursales y Puntos de Venta](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/requerimientos/sucursales-y-puntos-de-venta)
- [Homologación de Productos/Servicios](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/requerimientos/homologacion-de-productos-servicios)

#### Gestión de Tokens y Códigos
- [Solicitud de Token](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/emision-y-envio-de-facturas/solicitud-token)
- [Solicitud CUFD](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/codigos/solicitud-cufd)
- [Solicitud CUFD Masivo](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/codigos/solicitud-cufd-masivo)
- [Solicitud CUIS](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/codigos/solicitud-cuis)
- [CUIS Masivo](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/codigos/cuis-masivo)
- [Verifica NIT](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/codigos/verifica-nit)

#### Emisión y Envío de Facturas
- [Emisión y Envío](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/emision-y-envio-de-facturas/emision-y-envio)
- [Anulación de Documentos Fiscales](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/emision-y-envio-de-facturas/anulacion-de-documentos-fiscales)
- [Reversión de Anulación](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/emision-y-envio-de-facturas/reversion-anulacion-documentos-fiscales)

#### Contingencias y Eventos
- [Contingencia y Eventos Significativos](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/emision-y-envio-de-facturas/contingencia-y-eventos-significativos)
- [Ingreso a Contingencia](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/emision-y-envio-de-facturas/ingreso-a-contingencia)
- [Registro de Evento Significativo](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/operaciones/registro-evento-significativo)
- [Consulta de Evento Significativo](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/operaciones/consulta-evento-significativo)

#### Facturación Electrónica
- [Recepción de Factura Electrónica](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/facturacion-electronica/recepcion-factura-electronica)
- [Anulación de Factura Electrónica](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/facturacion-electronica/anulacion-factura-electronica)
- [Reversión de Anulación](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/facturacion-electronica/reversion-anulacion-factura-electronica)
- [Recepción de Paquete](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/facturacion-electronica/recepcion-paquete-factura-electronica)
- [Validación de Recepción de Paquete](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/facturacion-electronica/validacion-recepcion-paquete-factura-electronica)
- [Verifica Comunicación](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/facturacion-electronica/verifica-comunicacion)
- [Verificación de Estado](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/facturacion-electronica/verificacion-estado-factura-electronica)

#### Firma Digital
- [Firma Digital](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/firma-digital/firma-digital)
- [Generación de CSR para Token](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/firma-digital/generacion-csr/generacion-de-csr-para-token)
- [Generación de CSR para Software](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/firma-digital/generacion-csr/generacion-de-csr-para-software)
- [Firmado de XML](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/firma-digital/firmado-de-xml)
- [Firma Inválida](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/firma-digital/firma-invalida)

#### Algoritmos y Cálculos
- [Algoritmo Módulo 11](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/algoritmos-utilizados/algoritmo-modulo-11)
- [Generación de SHA-256, MD5 y CRC32](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/algoritmos-utilizados/generacion-de-sha-256-md5-y-crc32)
- [Generación de CUF](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/algoritmos-utilizados/generacion-cuf)
- [Código QR](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/algoritmos-utilizados/codigo-respuesta-rapida-qr)
- [Compresión GZIP](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/algoritmos-utilizados/comprimir-gzip)
- [Algoritmo de Redondeo](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/algoritmos-utilizados/algoritmo-de-redondeo)

#### Autorización y Homologación
- [Proceso de Autorización](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/autorizacion-de-sistemas/proceso-de-autorizacion)
- [Fase I - Pruebas](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/autorizacion-de-sistemas/pruebas-para-la-autorizacion-del-sistema-de-facturacion/fase-i-pruebas)
- [Fase II - Inspección](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/autorizacion-de-sistemas/pruebas-para-la-autorizacion-del-sistema-de-facturacion/fase-ii-inspeccion)
- [Fase III - Pruebas Piloto](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/autorizacion-de-sistemas/pruebas-para-la-autorizacion-del-sistema-de-facturacion/fase-iii-pruebas-piloto)

#### Archivos XML/XSD por Sector
- [Factura de Compra y Venta](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-de-compra-y-venta)
- [Factura de Servicios Turísticos y Hospedaje](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-de-servicios-turisticos-y-hospedaje)
- [Factura de Hidrocarburos](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-de-hidrocarburos)
- [Factura de Servicios Básicos](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-servicios-basicos)
- [Factura Sector Educativo](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-sector-educativo)
- [Factura de Telecomunicaciones](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/factura-telecomunicaciones)
- [Nota de Crédito/Débito](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/nota-credito-debito)
- [Boleto Aéreo](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/boleto-aereo)
- [Validaciones de Documentos por Sector](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/archivos-xml-xsd-de-facturas-electronicas/validaciones-documentos-sector/validaciones)

#### Casos Especiales
- [Líneas Aéreas](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/casos-especiales/lineas-aereas)
- [Facturación Conjunta](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/casos-especiales/facturacion-conjunta)
- [Facturación por Terceros](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/casos-especiales/facturacion-por-terceros)
- [Facturación de Comisionistas](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/casos-especiales/facturacion-comisionistas)
- [Manuales de Contingencia](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/casos-especiales/manuales-contingencia)

#### Códigos de Error
- [Códigos de Error SIAT](https://siatinfo.impuestos.gob.bo/index.php/facturacion-en-linea/implementacion-servicios-facturacion/codigos-error-siat)

---

## 6. Notas Importantes

- Todos los requerimientos deben cumplir con la normativa fiscal boliviana vigente.
- La integración con el SIN es obligatoria y debe validarse en todas las fases de desarrollo.
- Los certificados digitales deben ser gestionados de forma segura y con auditoría completa.
- El sistema debe mantener logs detallados de todas las operaciones fiscales para auditoría tributaria.
