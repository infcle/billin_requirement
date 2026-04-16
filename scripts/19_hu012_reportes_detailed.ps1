# HU-012 - Generar Reportes de Facturacion (Detailed Sub-tasks)
# Usage: .\19_hu012_reportes_detailed.ps1 [-WhatIf]

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

Write-Host "=== HU-012: Generar Reportes de Facturacion (Detailed) ===" -ForegroundColor Cyan

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
$mainTitle = "[HU-012] Generar Reportes de Facturacion"
$mainDesc = "Implementar generacion de reportes de facturacion. Reportes por periodo, cliente, producto. Exportacion a PDF/Excel. Dashboard de reportes."

$mainQ = 'query { issues(filter: { title: { eq: "' + $mainTitle + '" }, team: { id: { eq: "' + $setup.teamId + '" } } }, first: 1) { nodes { id identifier } } }'
$mainR = Call-Linear $mainQ

$parent = $null
if ($mainR.ok -and $mainR.data.issues.nodes.Count -gt 0) {
    $parent = $mainR.data.issues.nodes[0]
    Write-Host "Main issue exists: $($parent.identifier)" -ForegroundColor Cyan
} elseif ($WhatIf) {
    Write-Host "[WHATIF] Would create: $mainTitle" -ForegroundColor Yellow
    $parent = @{ id = "ISS_WHATIF"; identifier = "INF-WHATIF-012" }
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
    @{ id = "1"; title = "Crear entity Reporte y repository"; desc = "Crear JPA entity Reporte con campos: id, tipo, fechaGeneracion, parametros, contenido. Crear repository."; est = 1 },
    @{ id = "2"; title = "Implementar servicio de generacion de reportes"; desc = "Crear ReporteService con metodos: generarReportePorPeriodo, porCliente, porProducto."; est = 1 },
    @{ id = "3"; title = "Exportacion a PDF y Excel"; desc = "Implementar ReporteExporter. Generar PDF con iText, Excel con Apache POI. Templates personalizables."; est = 1 },
    @{ id = "4"; title = "Reportes por periodo de tiempo"; desc = "Crear PeriodoReportGenerator. Reportes diario, semanal, mensual, anual. Filtros de fecha."; est = 1 },
    @{ id = "5"; title = "Reportes por cliente y producto"; desc = "Implementar ClienteProductoReporter. Reportes por cliente, por producto, cruzados. Totales y promedios."; est = 1 },
    @{ id = "6"; title = "Caching de reportes generados"; desc = "Crear ReporteCache. Almacenar reportes generados. TTL configurable. Redis backend."; est = 1 },
    @{ id = "7"; title = "Crear endpoint GET /api/v1/reportes"; desc = "Crear ReporteController. Generar y descargar reportes. Listar reportes disponibles."; est = 1 },
    @{ id = "8"; title = "Tests unitarios y de integracion"; desc = "Crear tests para ReporteService, exportadores, cache, endpoints. Mock de datos."; est = 1 }
)

foreach ($task in $apiTasks) {
    $taskTitle = "[API]HU-012-$($task.id) $($task.title)"
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
    @{ id = "1"; title = "Dashboard de reportes"; desc = "Crear ReporteDashboardComponent. Mostrar reportes disponibles: tipo, ultima generacion, acciones."; est = 1 },
    @{ id = "2"; title = "Generador de reportes con filtros"; desc = "Implementar ReporteGeneratorComponent. Filtros: periodo, cliente, producto, tipo. Preview de parametros."; est = 1 },
    @{ id = "3"; title = "Visualizacion de reportes"; desc = "Crear ReporteViewerComponent. Mostrar reportes generados. Tablas, graficos, resumenes."; est = 1 },
    @{ id = "4"; title = "Descarga de reportes"; desc = "Implementar ReporteDownloadComponent. Descargar PDF/Excel. Progress indicators. Download history."; est = 1 },
    @{ id = "5"; title = "Programacion de reportes automaticos"; desc = "Crear ReporteSchedulerComponent. Programar reportes periodicos. Email automatico."; est = 1 },
    @{ id = "6"; title = "Historial de reportes generados"; desc = "Crear ReporteHistoryComponent. Tabla con reportes: fecha, usuario, parametros, descarga."; est = 1 },
    @{ id = "7"; title = "Tests E2E"; desc = "Crear E2E tests para flujo: seleccionar reporte -> configurar -> generar -> descargar."; est = 1 }
)

foreach ($task in $feTasks) {
    $taskTitle = "[FE]HU-012-$($task.id) $($task.title)"
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
    @{ id = "1"; title = "Probar generacion de reportes por periodo"; desc = "Generar reportes diario, semanal, mensual. Validar datos y calculos."; est = 1 },
    @{ id = "2"; title = "Validar reportes por cliente y producto"; desc = "Probar reportes filtrados por cliente y producto. Verificar totales y agrupaciones."; est = 1 },
    @{ id = "3"; title = "Probar exportacion a PDF y Excel"; desc = "Generar reportes en ambos formatos. Validar contenido y estructura."; est = 1 },
    @{ id = "4"; title = "Validar caching de reportes"; desc = "Probar cache de reportes generados. Verificar TTL y invalidacion."; est = 1 },
    @{ id = "5"; title = "Tests de rendimiento de generacion"; desc = "Probar generacion con grandes volumenes de datos. Medir tiempo y memoria."; est = 1 },
    @{ id = "6"; title = "Validar programacion de reportes"; desc = "Probar programacion automatica. Verificar envio por email y generacion."; est = 1 }
)

foreach ($task in $qaTasks) {
    $taskTitle = "[QA]HU-012-$($task.id) $($task.title)"
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

Write-Host "`n=== HU-012 Complete ===" -ForegroundColor Green
Write-Host "Total: 1 main + 8 API + 7 FE + 6 QA = 22 issues" -ForegroundColor White
Write-Host "Next: Run 20_hu016_analytics_detailed.ps1" -ForegroundColor Cyan
