# HU-005 - Generar XML de Factura de Compra-Venta (Detailed Sub-tasks)
# Usage: .\09_hu005_xml_factura_detailed.ps1 [-WhatIf]

param(
    [switch]$WhatIf = $false
)

# Check API Key
$apiKey = $env:LINEAR_API_KEY
if (-not $apiKey) {
    Write-Error "LINEAR_API_KEY not set"
    exit 1
}

# Load setup data
if (-not (Test-Path "D:\Facturacion en linea\scripts\sprint2_setup.json")) {
    Write-Error "Run 08_sprint2_setup.ps1 first"
    exit 1
}
$setup = Get-Content "D:\Facturacion en linea\scripts\sprint2_setup.json" | ConvertFrom-Json

$headers = @{
    Authorization = $apiKey
    ContentType = "application/json"
}

Write-Host "=== HU-005: Generar XML de Factura (Detailed) ===" -ForegroundColor Cyan

# API Call with Retry
function Call-Linear($q, $v = @{}) {
    $body = @{ query = $q; variables = $v } | ConvertTo-Json -Compress
    $attempt = 0
    while ($attempt -lt 5) {
        $attempt++
        try {
            $r = Invoke-RestMethod -Uri "https://api.linear.app/graphql" -Method POST -Headers $headers -Body $body -TimeoutSec 60
            if ($r.errors) { return @{ ok = $false; err = ($r.errors | ConvertTo-Json) } }
            return @{ ok = $true; data = $r.data }
        } catch {
            if ($attempt -lt 5) {
                Write-Host "Retry $attempt/5 in $($attempt * 3)s..." -ForegroundColor Yellow
                Start-Sleep -Seconds ($attempt * 3)
            } else {
                return @{ ok = $false; err = $_.Exception.Message }
            }
        }
    }
    return @{ ok = $false; err = "Max retries" }
}

# Main Issue
Write-Host "`nMain issue..." -ForegroundColor Cyan
$mainTitle = "[HU-005] Generar XML de Factura de Compra-Venta"
$mainDesc = "Implementar generacion de XML de facturas segun especificaciones del SIN Bolivia. Validacion de estructura, campos obligatorios, calculos de totales. Integracion con catalogo de productos."

$mainQ = 'query { issues(filter: { title: { eq: "' + $mainTitle + '" }, team: { id: { eq: "' + $setup.teamId + '" } } }, first: 1) { nodes { id identifier } } }'
$mainR = Call-Linear $mainQ

$parent = $null
if ($mainR.ok -and $mainR.data.issues.nodes.Count -gt 0) {
    $parent = $mainR.data.issues.nodes[0]
    Write-Host "Main issue exists: $($parent.identifier)" -ForegroundColor Cyan
} elseif ($WhatIf) {
    Write-Host "[WHATIF] Would create: $mainTitle" -ForegroundColor Yellow
    $parent = @{ id = "ISS_WHATIF"; identifier = "INF-WHATIF-005" }
} else {
    $mainM = 'mutation { issueCreate(input: { title: "' + $mainTitle + '", description: "' + $mainDesc + '", teamId: "' + $setup.teamId + '", projectId: "' + $setup.projectId + '", cycleId: "' + $setup.cycleId + '", priority: 1, estimate: 13 }) { success issue { id identifier } } }'
    $mainR2 = Call-Linear $mainM
    if ($mainR2.ok -and $mainR2.data.issueCreate.success) {
        $parent = $mainR2.data.issueCreate.issue
        Write-Host "Created main issue: $($parent.identifier)" -ForegroundColor Green
    } else {
        Write-Error "Main issue failed: $($mainR2.err)"
        exit 1
    }
}

# API Sub-tasks
Write-Host "`n[API] Sub-tasks..." -ForegroundColor Cyan

$apiTasks = @(
    @{ id = "1"; title = "Crear entity Factura y repository"; desc = "Crear JPA entity Factura con campos: numero, fechaEmision, montoTotal, cliente, items. Crear FacturaRepository."; est = 1 },
    @{ id = "2"; title = "Implementar servicio de generacion XML"; desc = "Crear FacturaXMLService con metodo generarXML(factura). Usar JAXB o similar para XML generation."; est = 1 },
    @{ id = "3"; title = "Validar estructura XML segun SIN"; desc = "Implementar validador XSD contra esquema SIN. Validar campos obligatorios y formatos."; est = 1 },
    @{ id = "4"; title = "Calcular totales y subtotales"; desc = "Implementar CalculadoraTotales. Calcular subtotal, IVA, descuentos, total. Validar consistencia."; est = 1 },
    @{ id = "5"; title = "Integrar con catalogo de productos"; desc = "Crear ProductoService. Validar productos contra catalogo SIN. Obtener descripcion y precio."; est = 1 },
    @{ id = "6"; title = "Generar numero de factura unico"; desc = "Implementar GeneradorNumeracion. Secuencia por punto de venta. Validar no duplicados."; est = 1 },
    @{ id = "7"; title = "Crear endpoint POST /api/v1/facturas"; desc = "Crear FacturaController. Recibir datos de factura, generar XML, retornar resultado."; est = 1 },
    @{ id = "8"; title = "Tests unitarios y de integracion"; desc = "Crear tests para FacturaXMLService, validacion XSD, calculadora totales, endpoint."; est = 1 }
)

foreach ($task in $apiTasks) {
    $taskTitle = "[API]HU-005-$($task.id) $($task.title)"
    $taskDesc = "$($task.desc)`n`nParent: $($parent.identifier)"
    
    $taskQ = 'query { issues(filter: { title: { eq: "' + $taskTitle + '" }, team: { id: { eq: "' + $setup.teamId + '" } } }, first: 1) { nodes { id identifier } } }'
    $taskR = Call-Linear $taskQ
    
    if ($taskR.ok -and $taskR.data.issues.nodes.Count -gt 0) {
        Write-Host "  [API] $($task.id) exists: $($taskR.data.issues.nodes[0].identifier)" -ForegroundColor DarkCyan
    } elseif ($WhatIf) {
        Write-Host "  [WHATIF] [API] $($task.id)" -ForegroundColor DarkYellow
    } else {
        $taskM = 'mutation { issueCreate(input: { title: "' + $taskTitle + '", description: "' + $taskDesc + '", teamId: "' + $setup.teamId + '", projectId: "' + $setup.projectId + '", cycleId: "' + $setup.cycleId + '", parentId: "' + $parent.id + '", priority: 1, estimate: ' + $task.est + ' }) { success issue { id identifier } } }'
        $taskR2 = Call-Linear $taskM
        if ($taskR2.ok -and $taskR2.data.issueCreate.success) {
            Write-Host "  Created [API] $($task.id): $($taskR2.data.issueCreate.issue.identifier)" -ForegroundColor DarkGreen
        } else {
            Write-Warning "  [API] $($task.id) failed: $($taskR2.err)"
        }
    }
    Start-Sleep -Seconds 1
}

# FE Sub-tasks
Write-Host "`n[FE] Sub-tasks..." -ForegroundColor Cyan

$feTasks = @(
    @{ id = "1"; title = "Formulario de creacion de factura"; desc = "Crear FacturaFormComponent. Campos: cliente, productos, cantidades, precios. Auto-calculo de totales."; est = 1 },
    @{ id = "2"; title = "Buscador de productos del catalogo"; desc = "Crear ProductoSearchComponent. Autocomplete con catalogo SIN. Mostrar descripcion y precio."; est = 1 },
    @{ id = "3"; title = "Validacion de formulario en tiempo real"; desc = "Implementar validaciones: campos obligatorios, formatos, rangos. Mensajes de error."; est = 1 },
    @{ id = "4"; title = "Vista previa de XML generado"; desc = "Crear XMLPreviewComponent. Mostrar XML formateado con syntax highlighting. Download option."; est = 1 },
    @{ id = "5"; title = "Calculadora de totales en UI"; desc = "Implementar TotalesCalculatorComponent. Actualizar subtotal, IVA, total en tiempo real."; est = 1 },
    @{ id = "6"; title = "Historial de facturas creadas"; desc = "Crear FacturaHistoryComponent. Tabla con facturas: numero, fecha, cliente, monto, acciones."; est = 1 },
    @{ id = "7"; title = "Tests E2E"; desc = "Crear E2E tests para flujo completo: crear factura -> validar -> generar XML -> descargar."; est = 1 }
)

foreach ($task in $feTasks) {
    $taskTitle = "[FE]HU-005-$($task.id) $($task.title)"
    $taskDesc = "$($task.desc)`n`nParent: $($parent.identifier)"
    
    $taskQ = 'query { issues(filter: { title: { eq: "' + $taskTitle + '" }, team: { id: { eq: "' + $setup.teamId + '" } } }, first: 1) { nodes { id identifier } } }'
    $taskR = Call-Linear $taskQ
    
    if ($taskR.ok -and $taskR.data.issues.nodes.Count -gt 0) {
        Write-Host "  [FE] $($task.id) exists: $($taskR.data.issues.nodes[0].identifier)" -ForegroundColor DarkCyan
    } elseif ($WhatIf) {
        Write-Host "  [WHATIF] [FE] $($task.id)" -ForegroundColor DarkYellow
    } else {
        $taskM = 'mutation { issueCreate(input: { title: "' + $taskTitle + '", description: "' + $taskDesc + '", teamId: "' + $setup.teamId + '", projectId: "' + $setup.projectId + '", cycleId: "' + $setup.cycleId + '", parentId: "' + $parent.id + '", priority: 1, estimate: ' + $task.est + ' }) { success issue { id identifier } } }'
        $taskR2 = Call-Linear $taskM
        if ($taskR2.ok -and $taskR2.data.issueCreate.success) {
            Write-Host "  Created [FE] $($task.id): $($taskR2.data.issueCreate.issue.identifier)" -ForegroundColor DarkGreen
        } else {
            Write-Warning "  [FE] $($task.id) failed: $($taskR2.err)"
        }
    }
    Start-Sleep -Seconds 1
}

# QA Sub-tasks
Write-Host "`n[QA] Sub-tasks..." -ForegroundColor Cyan

$qaTasks = @(
    @{ id = "1"; title = "Validar estructura XML contra XSD"; desc = "Probar XML generado contra esquema SIN. Verificar todos los campos obligatorios."; est = 1 },
    @{ id = "2"; title = "Probar calculos de totales"; desc = "Verificar calculos de subtotal, IVA, descuentos. Probar con diferentes combinaciones."; est = 1 },
    @{ id = "3"; title = "Validar integracion con catalogo"; desc = "Probar productos validos e invalidos. Verificar mensajes de error."; est = 1 },
    @{ id = "4"; title = "Probar generacion de numeros unicos"; desc = "Verificar secuencia de numeros. Probar concurrencia. Validar no duplicados."; est = 1 },
    @{ id = "5"; title = "Tests de validacion de formulario"; desc = "Probar validaciones frontend: campos vacios, formatos invalidos, rangos."; est = 1 },
    @{ id = "6"; title = "Validar XML contra SIN"; desc = "Enviar XML de prueba a ambiente de pruebas SIN. Verificar aceptacion."; est = 1 }
)

foreach ($task in $qaTasks) {
    $taskTitle = "[QA]HU-005-$($task.id) $($task.title)"
    $taskDesc = "$($task.desc)`n`nParent: $($parent.identifier)"
    
    $taskQ = 'query { issues(filter: { title: { eq: "' + $taskTitle + '" }, team: { id: { eq: "' + $setup.teamId + '" } } }, first: 1) { nodes { id identifier } } }'
    $taskR = Call-Linear $taskQ
    
    if ($taskR.ok -and $taskR.data.issues.nodes.Count -gt 0) {
        Write-Host "  [QA] $($task.id) exists: $($taskR.data.issues.nodes[0].identifier)" -ForegroundColor DarkCyan
    } elseif ($WhatIf) {
        Write-Host "  [WHATIF] [QA] $($task.id)" -ForegroundColor DarkYellow
    } else {
        $taskM = 'mutation { issueCreate(input: { title: "' + $taskTitle + '", description: "' + $taskDesc + '", teamId: "' + $setup.teamId + '", projectId: "' + $setup.projectId + '", cycleId: "' + $setup.cycleId + '", parentId: "' + $parent.id + '", priority: 1, estimate: ' + $task.est + ' }) { success issue { id identifier } } }'
        $taskR2 = Call-Linear $taskM
        if ($taskR2.ok -and $taskR2.data.issueCreate.success) {
            Write-Host "  Created [QA] $($task.id): $($taskR2.data.issueCreate.issue.identifier)" -ForegroundColor DarkGreen
        } else {
            Write-Warning "  [QA] $($task.id) failed: $($taskR2.err)"
        }
    }
    Start-Sleep -Seconds 1
}

Write-Host "`n=== HU-005 Complete ===" -ForegroundColor Green
Write-Host "Total: 1 main + 8 API + 7 FE + 6 QA = 22 issues" -ForegroundColor White
Write-Host "Next: Run 10_hu006_cuf_detailed.ps1" -ForegroundColor Cyan
