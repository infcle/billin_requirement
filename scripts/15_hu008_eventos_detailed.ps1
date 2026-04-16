# HU-008 - Registrar Eventos Significativos (Detailed Sub-tasks)
# Usage: .\15_hu008_eventos_detailed.ps1 [-WhatIf]

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

Write-Host "=== HU-008: Registrar Eventos Significativos (Detailed) ===" -ForegroundColor Cyan

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
$mainTitle = "[HU-008] Registrar Eventos Significativos"
$mainDesc = "Implementar registro automatico de eventos significativos del sistema. Auditoria completa. Logs estructurados. Dashboard de eventos. Integracion con ELK stack."

$mainQ = 'query { issues(filter: { title: { eq: "' + $mainTitle + '" }, team: { id: { eq: "' + $setup.teamId + '" } } }, first: 1) { nodes { id identifier } } }'
$mainR = Call-Linear $mainQ

$parent = $null
if ($mainR.ok -and $mainR.data.issues.nodes.Count -gt 0) {
    $parent = $mainR.data.issues.nodes[0]
    Write-Host "Main issue exists: $($parent.identifier)" -ForegroundColor Cyan
} elseif ($WhatIf) {
    Write-Host "[WHATIF] Would create: $mainTitle" -ForegroundColor Yellow
    $parent = @{ id = "ISS_WHATIF"; identifier = "INF-WHATIF-008" }
} else {
    $mainM = 'mutation { issueCreate(input: { title: "' + $mainTitle + '", description: "' + $mainDesc + '", teamId: "' + $setup.teamId + '", projectId: "' + $setup.projectId + '", cycleId: "' + $setup.cycleId + '", priority: 2, estimate: 8 }) { success issue { id identifier } } }'
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
    @{ id = "1"; title = "Crear entity EventoSignificativo y repository"; desc = "Crear JPA entity EventoSignificativo con campos: id, tipo, descripcion, timestamp, usuario, datos. Crear repository."; est = 1 },
    @{ id = "2"; title = "Implementar servicio de logging estructurado"; desc = "Crear EventLoggerService. Usar Logback con JSON format. Niveles: INFO, WARN, ERROR."; est = 1 },
    @{ id = "3"; title = "Definir tipos de eventos significativos"; desc = "Crear EventType enum. Definir: FACTURA_EMITIDA, CONTINGENCIA_INICIO, SIN_CAIDA, etc."; est = 1 },
    @{ id = "4"; title = "Integracion con ELK stack"; desc = "Implementar ELKIntegration. Enviar eventos a Elasticsearch. Configurar Kibana dashboards."; est = 1 },
    @{ id = "5"; title = "Eventos automaticos con AOP"; desc = "Implementar EventAspect. Capturar eventos automaticamente con @Around advice."; est = 1 },
    @{ id = "6"; title = "Crear endpoint GET /api/v1/eventos"; desc = "Crear EventoController. Listar eventos con filtros: tipo, fecha, usuario. Paginacion."; est = 1 },
    @{ id = "7"; title = "Archiving de eventos antiguos"; desc = "Implementar EventArchiver. Mover eventos > 1 año a archivo. Compresion automatica."; est = 1 },
    @{ id = "8"; title = "Tests unitarios y de integracion"; desc = "Crear tests para EventLoggerService, ELKIntegration, EventAspect, endpoint."; est = 1 }
)

foreach ($task in $apiTasks) {
    $taskTitle = "[API]HU-008-$($task.id) $($task.title)"
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
    @{ id = "1"; title = "Dashboard de eventos en tiempo real"; desc = "Crear EventDashboardComponent. Mostrar eventos en tiempo real con WebSocket. Filtros dinamicos."; est = 1 },
    @{ id = "2"; title = "Busqueda avanzada de eventos"; desc = "Implementar EventSearchComponent. Buscar por tipo, fecha, usuario, descripcion. Auto-complete."; est = 1 },
    @{ id = "3"; title = "Visualizacion de eventos por tipo"; desc = "Crear EventTypeChartComponent. Graficos de torta/barras por tipo de evento. Filtros de tiempo."; est = 1 },
    @{ id = "4"; title = "Timeline de eventos"; desc = "Implementar EventTimelineComponent. Timeline visual de eventos importantes. Zoom y navegacion."; est = 1 },
    @{ id = "5"; title = "Export de eventos a CSV/Excel"; desc = "Crear EventExportComponent. Exportar eventos filtrados. Formatos: CSV, Excel, PDF."; est = 1 },
    @{ id = "6"; title = "Alertas de eventos criticos"; desc = "Implementar CriticalAlertsComponent. Notificaciones push para eventos criticos. Sonidos visuales."; est = 1 },
    @{ id = "7"; title = "Tests E2E"; desc = "Crear E2E tests para dashboard, busqueda, filtros, export. Probar WebSocket updates."; est = 1 }
)

foreach ($task in $feTasks) {
    $taskTitle = "[FE]HU-008-$($task.id) $($task.title)"
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
    @{ id = "1"; title = "Validar registro automatico de eventos"; desc = "Probar que eventos se registran automaticamente. Verificar tipos y datos."; est = 1 },
    @{ id = "2"; title = "Probar integracion con ELK stack"; desc = "Verificar que eventos llegan a Elasticsearch. Probar Kibana dashboards."; est = 1 },
    @{ id = "3"; title = "Validar filtros y busqueda"; desc = "Probar filtros por tipo, fecha, usuario. Verificar resultados correctos."; est = 1 },
    @{ id = "4"; title = "Probar archiving de eventos"; desc = "Simular eventos antiguos. Verificar archiving automatico y compresion."; est = 1 },
    @{ id = "5"; title = "Tests de rendimiento de logging"; desc = "Probar alta frecuencia de eventos. Medir impacto en performance del sistema."; est = 1 },
    @{ id = "6"; title = "Validar export de eventos"; desc = "Probar export a CSV/Excel. Validar formato y contenido de datos."; est = 1 }
)

foreach ($task in $qaTasks) {
    $taskTitle = "[QA]HU-008-$($task.id) $($task.title)"
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

Write-Host "`n=== HU-008 Complete ===" -ForegroundColor Green
Write-Host "Total: 1 main + 8 API + 7 FE + 6 QA = 22 issues" -ForegroundColor White
Write-Host "Next: Run 16_hu010_paquetes_detailed.ps1" -ForegroundColor Cyan
