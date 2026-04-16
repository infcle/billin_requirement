# HU-007 - Manejar Contingencias de Facturacion (Detailed Sub-tasks)
# Usage: .\14_hu007_contingencias_detailed.ps1 [-WhatIf]

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
if (-not (Test-Path "D:\Facturacion en linea\scripts\sprint3_setup.json")) {
    Write-Error "Run 13_sprint3_setup.ps1 first"
    exit 1
}
$setup = Get-Content "D:\Facturacion en linea\scripts\sprint3_setup.json" | ConvertFrom-Json

$headers = @{
    Authorization = $apiKey
    ContentType = "application/json"
}

Write-Host "=== HU-007: Manejar Contingencias de Facturacion (Detailed) ===" -ForegroundColor Cyan

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
$mainTitle = "[HU-007] Manejar Contingencias de Facturacion"
$mainDesc = "Implementar gestion de contingencias cuando SIN no esta disponible. Modo offline con almacenamiento local. Sincronizacion automatica cuando servicio se restaura. Generacion de reportes de contingencia."

$mainQ = 'query { issues(filter: { title: { eq: "' + $mainTitle + '" }, team: { id: { eq: "' + $setup.teamId + '" } } }, first: 1) { nodes { id identifier } } }'
$mainR = Call-Linear $mainQ

$parent = $null
if ($mainR.ok -and $mainR.data.issues.nodes.Count -gt 0) {
    $parent = $mainR.data.issues.nodes[0]
    Write-Host "Main issue exists: $($parent.identifier)" -ForegroundColor Cyan
} elseif ($WhatIf) {
    Write-Host "[WHATIF] Would create: $mainTitle" -ForegroundColor Yellow
    $parent = @{ id = "ISS_WHATIF"; identifier = "INF-WHATIF-007" }
} else {
    $mainM = 'mutation { issueCreate(input: { title: "' + $mainTitle + '", description: "' + $mainDesc + '", teamId: "' + $setup.teamId + '", projectId: "' + $setup.projectId + '", cycleId: "' + $setup.cycleId + '", priority: 2, estimate: 13 }) { success issue { id identifier } } }'
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
    @{ id = "1"; title = "Crear entity Contingencia y repository"; desc = "Crear JPA entity Contingencia con campos: id, tipo, fechaInicio, fechaFin, descripcion, facturasAfectadas."; est = 1 },
    @{ id = "2"; title = "Implementar detector de caida de SIN"; desc = "Crear SINHealthChecker. Monitorear endpoints SIN. Detectar caidas y restauraciones."; est = 1 },
    @{ id = "3"; title = "Modo offline con almacenamiento local"; desc = "Implementar OfflineModeService. Almacenar facturas localmente cuando SIN cae. Usar DB local."; est = 1 },
    @{ id = "4"; title = "Sincronizacion automatica al restaurar"; desc = "Crear SincronizacionService. Enviar facturas pendientes cuando SIN se restaura. Cola de procesamiento."; est = 1 },
    @{ id = "5"; title = "Generacion de reportes de contingencia"; desc = "Implementar ContingenciaReportGenerator. PDF/Excel con facturas afectadas y fechas."; est = 1 },
    @{ id = "6"; title = "Notificaciones de contingencia"; desc = "Crear ContingenciaNotifier. Email/SMS a administradores. Dashboard alerts."; est = 1 },
    @{ id = "7"; title = "Crear endpoint POST /api/v1/contingencias"; desc = "Crear ContingenciaController. Registrar nueva contingencia. Listar activas."; est = 1 },
    @{ id = "8"; title = "Tests unitarios y de integracion"; desc = "Crear tests para deteccion, modo offline, sincronizacion, reportes. Mock de SIN caido."; est = 1 }
)

foreach ($task in $apiTasks) {
    $taskTitle = "[API]HU-007-$($task.id) $($task.title)"
    $taskDesc = "$($task.desc)`n`nParent: $($parent.identifier)"
    
    $taskQ = 'query { issues(filter: { title: { eq: "' + $taskTitle + '" }, team: { id: { eq: "' + $setup.teamId + '" } } }, first: 1) { nodes { id identifier } } }'
    $taskR = Call-Linear $taskQ
    
    if ($taskR.ok -and $taskR.data.issues.nodes.Count -gt 0) {
        Write-Host "  [API] $($task.id) exists: $($taskR.data.issues.nodes[0].identifier)" -ForegroundColor DarkCyan
    } elseif ($WhatIf) {
        Write-Host "  [WHATIF] [API] $($task.id)" -ForegroundColor DarkYellow
    } else {
        $taskM = 'mutation { issueCreate(input: { title: "' + $taskTitle + '", description: "' + $taskDesc + '", teamId: "' + $setup.teamId + '", projectId: "' + $setup.projectId + '", cycleId: "' + $setup.cycleId + '", parentId: "' + $parent.id + '", priority: 2, estimate: ' + $task.est + ' }) { success issue { id identifier } } }'
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
    @{ id = "1"; title = "Dashboard de estado del sistema"; desc = "Crear SystemStatusDashboardComponent. Mostrar estado SIN, contingencias activas, metrics."; est = 1 },
    @{ id = "2"; title = "Indicador visual de modo offline"; desc = "Implementar OfflineModeIndicatorComponent. Banner rojo cuando sistema esta en contingencia."; est = 1 },
    @{ id = "3"; title = "Registro manual de contingencias"; desc = "Crear ContingenciaFormComponent. Formulario para registrar contingencias manualmente."; est = 1 },
    @{ id = "4"; title = "Historial de contingencias"; desc = "Crear ContingenciaHistoryComponent. Tabla con contingencias: fechas, tipo, duracion, afectados."; est = 1 },
    @{ id = "5"; title = "Descarga de reportes de contingencia"; desc = "Implementar ReportDownloadComponent. Descargar PDF/Excel de contingencias activas."; est = 1 },
    @{ id = "6"; title = "Notificaciones en tiempo real"; desc = "Crear RealTimeNotificationComponent. WebSocket para alertas de contingencias."; est = 1 },
    @{ id = "7"; title = "Tests E2E"; desc = "Crear E2E tests para flujo: detectar contingencia -> modo offline -> sincronizar."; est = 1 }
)

foreach ($task in $feTasks) {
    $taskTitle = "[FE]HU-007-$($task.id) $($task.title)"
    $taskDesc = "$($task.desc)`n`nParent: $($parent.identifier)"
    
    $taskQ = 'query { issues(filter: { title: { eq: "' + $taskTitle + '" }, team: { id: { eq: "' + $setup.teamId + '" } } }, first: 1) { nodes { id identifier } } }'
    $taskR = Call-Linear $taskQ
    
    if ($taskR.ok -and $taskR.data.issues.nodes.Count -gt 0) {
        Write-Host "  [FE] $($task.id) exists: $($taskR.data.issues.nodes[0].identifier)" -ForegroundColor DarkCyan
    } elseif ($WhatIf) {
        Write-Host "  [WHATIF] [FE] $($task.id)" -ForegroundColor DarkYellow
    } else {
        $taskM = 'mutation { issueCreate(input: { title: "' + $taskTitle + '", description: "' + $taskDesc + '", teamId: "' + $setup.teamId + '", projectId: "' + $setup.projectId + '", cycleId: "' + $setup.cycleId + '", parentId: "' + $parent.id + '", priority: 2, estimate: ' + $task.est + ' }) { success issue { id identifier } } }'
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
    @{ id = "1"; title = "Simular caida de servicio SIN"; desc = "Mock SIN para retornar 503. Verificar deteccion automatica de contingencia."; est = 1 },
    @{ id = "2"; title = "Probar modo offline"; desc = "Generar facturas mientras SIN caido. Verificar almacenamiento local."; est = 1 },
    @{ id = "3"; title = "Validar sincronizacion automatica"; desc = "Restaurar servicio SIN. Verificar que facturas pendientes se sincronicen."; est = 1 },
    @{ id = "4"; title = "Probar generacion de reportes"; desc = "Generar reportes de contingencia. Validar contenido y formato PDF/Excel."; est = 1 },
    @{ id = "5"; title = "Tests de concurrencia de sincronizacion"; desc = "Probar multiples sincronizaciones simultaneas. Verificar no duplicados."; est = 1 },
    @{ id = "6"; title = "Validar notificaciones de contingencia"; desc = "Probar envio de notificaciones. Verificar contenido y destinatarios."; est = 1 }
)

foreach ($task in $qaTasks) {
    $taskTitle = "[QA]HU-007-$($task.id) $($task.title)"
    $taskDesc = "$($task.desc)`n`nParent: $($parent.identifier)"
    
    $taskQ = 'query { issues(filter: { title: { eq: "' + $taskTitle + '" }, team: { id: { eq: "' + $setup.teamId + '" } } }, first: 1) { nodes { id identifier } } }'
    $taskR = Call-Linear $taskQ
    
    if ($taskR.ok -and $taskR.data.issues.nodes.Count -gt 0) {
        Write-Host "  [QA] $($task.id) exists: $($taskR.data.issues.nodes[0].identifier)" -ForegroundColor DarkCyan
    } elseif ($WhatIf) {
        Write-Host "  [WHATIF] [QA] $($task.id)" -ForegroundColor DarkYellow
    } else {
        $taskM = 'mutation { issueCreate(input: { title: "' + $taskTitle + '", description: "' + $taskDesc + '", teamId: "' + $setup.teamId + '", projectId: "' + $setup.projectId + '", cycleId: "' + $setup.cycleId + '", parentId: "' + $parent.id + '", priority: 2, estimate: ' + $task.est + ' }) { success issue { id identifier } } }'
        $taskR2 = Call-Linear $taskM
        if ($taskR2.ok -and $taskR2.data.issueCreate.success) {
            Write-Host "  Created [QA] $($task.id): $($taskR2.data.issueCreate.issue.identifier)" -ForegroundColor DarkGreen
        } else {
            Write-Warning "  [QA] $($task.id) failed: $($taskR2.err)"
        }
    }
    Start-Sleep -Seconds 1
}

Write-Host "`n=== HU-007 Complete ===" -ForegroundColor Green
Write-Host "Total: 1 main + 8 API + 7 FE + 6 QA = 22 issues" -ForegroundColor White
Write-Host "Next: Run 15_hu008_eventos_detailed.ps1" -ForegroundColor Cyan
