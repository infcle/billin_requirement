# HU-016 - Dashboard Analytics (Detailed Sub-tasks)
# Usage: .\20_hu016_analytics_detailed.ps1 [-WhatIf]

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
if (-not (Test-Path "D:\Facturacion en linea\scripts\sprint4_setup.json")) {
    Write-Error "Run 18_sprint4_setup.ps1 first"
    exit 1
}
$setup = Get-Content "D:\Facturacion en linea\scripts\sprint4_setup.json" | ConvertFrom-Json

$headers = @{
    Authorization = $apiKey
    ContentType = "application/json"
}

Write-Host "=== HU-016: Dashboard Analytics (Detailed) ===" -ForegroundColor Cyan

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
$mainTitle = "[HU-016] Dashboard Analytics"
$mainDesc = "Implementar dashboard analytics con KPIs, graficos interactivos, tiempo real. Integracion con data warehouse. Drill-down capabilities."

$mainQ = 'query { issues(filter: { title: { eq: "' + $mainTitle + '" }, team: { id: { eq: "' + $setup.teamId + '" } } }, first: 1) { nodes { id identifier } } }'
$mainR = Call-Linear $mainQ

$parent = $null
if ($mainR.ok -and $mainR.data.issues.nodes.Count -gt 0) {
    $parent = $mainR.data.issues.nodes[0]
    Write-Host "Main issue exists: $($parent.identifier)" -ForegroundColor Cyan
} elseif ($WhatIf) {
    Write-Host "[WHATIF] Would create: $mainTitle" -ForegroundColor Yellow
    $parent = @{ id = "ISS_WHATIF"; identifier = "INF-WHATIF-016" }
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
    @{ id = "1"; title = "Crear entity AnalyticsMetric y repository"; desc = "Crear JPA entity AnalyticsMetric con campos: id, nombre, tipo, valor, timestamp, dimensiones."; est = 1 },
    @{ id = "2"; title = "Implementar servicio de calculo de KPIs"; desc = "Crear KPICalculatorService. Calcular: facturacion mensual, crecimiento, top clientes, productos."; est = 1 },
    @{ id = "3"; title = "Data warehouse integration"; desc = "Implementar DataWarehouseConnector. Extraer datos de DW. Agregar y transformar metrics."; est = 1 },
    @{ id = "4"; title = "Real-time data processing"; desc = "Crear RealTimeProcessor. Procesar eventos en tiempo real. Kafka streams. Actualizar KPIs."; est = 1 },
    @{ id = "5"; title = "API de graficos y dashboards"; desc = "Crear AnalyticsController. Endpoints para KPIs, graficos, drill-down. Cache de datos."; est = 1 },
    @{ id = "6"; title = "Drill-down capabilities"; desc = "Implementar DrillDownService. Navegacion jerarquica: periodo -> cliente -> factura."; est = 1 },
    @{ id = "7"; title = "Caching de datos de analytics"; desc = "Crear AnalyticsCache. Redis cache para KPIs. TTL configurable. Refresh automatico."; est = 1 },
    @{ id = "8"; title = "Tests unitarios y de integracion"; desc = "Crear tests para KPICalculator, DataWarehouse, RealTimeProcessor, endpoints."; est = 1 }
)

foreach ($task in $apiTasks) {
    $taskTitle = "[API]HU-016-$($task.id) $($task.title)"
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
    @{ id = "1"; title = "Dashboard principal de KPIs"; desc = "Crear MainDashboardComponent. KPIs principales: facturacion mensual, crecimiento, top metrics."; est = 1 },
    @{ id = "2"; title = "Graficos interactivos"; desc = "Implementar InteractiveChartsComponent. Graficos de barras, lineas, torta. Zoom y filtros."; est = 1 },
    @{ id = "3"; title = "Drill-down navigation"; desc = "Crear DrillDownNavigationComponent. Navegacion jerarquica: periodo -> cliente -> factura -> detalle."; est = 1 },
    @{ id = "4"; title = "Real-time updates"; desc = "Implementar RealTimeUpdatesComponent. WebSocket para actualizaciones en tiempo real. Live metrics."; est = 1 },
    @{ id = "5"; title = "Custom dashboard builder"; desc = "Crear DashboardBuilderComponent. Arrastrar y soltar widgets. Guardar configuraciones personalizadas."; est = 1 },
    @{ id = "6"; title = "Export de graficos y datos"; desc = "Implementar ChartExportComponent. Exportar graficos como PNG/SVG. Exportar datos como CSV/Excel."; est = 1 },
    @{ id = "7"; title = "Tests E2E"; desc = "Crear E2E tests para dashboard, graficos, drill-down, real-time updates, export."; est = 1 }
)

foreach ($task in $feTasks) {
    $taskTitle = "[FE]HU-016-$($task.id) $($task.title)"
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
    @{ id = "1"; title = "Validar calculo de KPIs"; desc = "Probar calculo de KPIs principales. Verificar formulas y resultados contra datos esperados."; est = 1 },
    @{ id = "2"; title = "Probar integracion con data warehouse"; desc = "Validar extraccion y transformacion de datos. Probar conexion y queries."; est = 1 },
    @{ id = "3"; title = "Validar real-time updates"; desc = "Probar actualizaciones en tiempo real. Simular eventos y verificar WebSocket updates."; est = 1 },
    @{ id = "4"; title = "Probar drill-down navigation"; desc = "Navegar por jerarquia de datos. Verificar consistencia y performance."; est = 1 },
    @{ id = "5"; title = "Tests de rendimiento de dashboard"; desc = "Probar carga de dashboard con grandes volumenes de datos. Medir tiempos de carga."; est = 1 },
    @{ id = "6"; title = "Validar export de graficos"; desc = "Probar export de graficos y datos. Validar formatos y contenido."; est = 1 }
)

foreach ($task in $qaTasks) {
    $taskTitle = "[QA]HU-016-$($task.id) $($task.title)"
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

Write-Host "`n=== HU-016 Complete ===" -ForegroundColor Green
Write-Host "Total: 1 main + 8 API + 7 FE + 6 QA = 22 issues" -ForegroundColor White
Write-Host "`n=== Sprint 4 Complete ===" -ForegroundColor Green
Write-Host "All Sprint 4 stories with detailed sub-tasks created!" -ForegroundColor White
Write-Host "Total Sprint 4: 44 issues (2 main + 16 API + 14 FE + 12 QA)" -ForegroundColor Cyan
Write-Host "`n=== PROJECT COMPLETE ===" -ForegroundColor Green
Write-Host "All 4 sprints with detailed sub-tasks created!" -ForegroundColor White
Write-Host "Total Project: 349 issues (16 main + 115 API + 87 FE + 75 QA)" -ForegroundColor Cyan
Write-Host "Ready to execute scripts sequentially!" -ForegroundColor White
