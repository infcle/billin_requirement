# HU-009 - Mapear Productos Internos al Catalogo Oficial (Detailed Sub-tasks)
# Usage: .\11_hu009_mapeo_detailed.ps1 [-WhatIf]

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

Write-Host "=== HU-009: Mapear Productos Internos al Catalogo Oficial (Detailed) ===" -ForegroundColor Cyan

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
$mainTitle = "[HU-009] Mapear Productos Internos al Catalogo Oficial"
$mainDesc = "Implementar mapeo entre productos internos y catalogo oficial SIN. Sincronizacion automatica. Manejo de productos sin mapeo. Actualizacion de precios y descripciones."

$mainQ = 'query { issues(filter: { title: { eq: "' + $mainTitle + '" }, team: { id: { eq: "' + $setup.teamId + '" } } }, first: 1) { nodes { id identifier } } }'
$mainR = Call-Linear $mainQ

$parent = $null
if ($mainR.ok -and $mainR.data.issues.nodes.Count -gt 0) {
    $parent = $mainR.data.issues.nodes[0]
    Write-Host "Main issue exists: $($parent.identifier)" -ForegroundColor Cyan
} elseif ($WhatIf) {
    Write-Host "[WHATIF] Would create: $mainTitle" -ForegroundColor Yellow
    $parent = @{ id = "ISS_WHATIF"; identifier = "INF-WHATIF-009" }
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
    @{ id = "1"; title = "Crear entity ProductoInterno y repository"; desc = "Crear JPA entity ProductoInterno con campos: id, codigoInterno, nombre, precio, activo. Crear repository."; est = 1 },
    @{ id = "2"; title = "Crear entity CatalogoSIN y repository"; desc = "Crear JPA entity CatalogoSIN con campos: codigoSIN, descripcion, precioUnitario, actividadEconomica."; est = 1 },
    @{ id = "3"; title = "Implementar servicio de mapeo"; desc = "Crear ProductoMappingService con metodo mapearProducto(codigoInterno). Buscar en catalogo SIN."; est = 1 },
    @{ id = "4"; title = "Sincronizacion automatica con SIN"; desc = "Implementar CatalogoSincronizador. Job diario para actualizar catalogo SIN via API."; est = 1 },
    @{ id = "5"; title = "Manejo de productos sin mapeo"; desc = "Crear ProductoNoMapeadoHandler. Loggear productos sin mapeo. Notificar administrador."; est = 1 },
    @{ id = "6"; title = "Actualizacion de precios y descripciones"; desc = "Implementar ActualizadorPrecios. Sincronizar precios y descripciones desde catalogo SIN."; est = 1 },
    @{ id = "7"; title = "Crear endpoint GET /api/v1/productos/mapeo"; desc = "Crear ProductoMapeoController. Retornar mapeo de productos internos a catalogo SIN."; est = 1 },
    @{ id = "8"; title = "Tests unitarios y de integracion"; desc = "Crear tests para mapping, sincronizacion, actualizacion de precios. Mock de API SIN."; est = 1 }
)

foreach ($task in $apiTasks) {
    $taskTitle = "[API]HU-009-$($task.id) $($task.title)"
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
    @{ id = "1"; title = "Panel de administracion de mapeo"; desc = "Crear MapeoAdminComponent. Tabla con productos internos y su mapeo a catalogo SIN."; est = 1 },
    @{ id = "2"; title = "Busqueda y seleccion de productos SIN"; desc = "Implementar ProductoSINSearchComponent. Autocomplete con catalogo SIN para mapeo manual."; est = 1 },
    @{ id = "3"; title = "Indicador de productos sin mapeo"; desc = "Crear ProductoSinMapeoBadgeComponent. Mostrar contador de productos sin mapeo. Alertas visuales."; est = 1 },
    @{ id = "4"; title = "Sincronizacion manual de catalogo"; desc = "Implementar SincronizacionManualButton. Boton para sincronizar catalogo SIN manualmente."; est = 1 },
    @{ id = "5"; title = "Historial de sincronizaciones"; desc = "Crear SincronizacionHistoryComponent. Mostrar log de sincronizaciones: fecha, productos actualizados, errores."; est = 1 },
    @{ id = "6"; title = "Validacion de productos en formulario"; desc = "Crear ProductoValidatorComponent. Validar que productos seleccionados tengan mapeo SIN."; est = 1 },
    @{ id = "7"; title = "Tests E2E"; desc = "Crear E2E tests para flujo: mapear producto -> sincronizar -> validar en factura."; est = 1 }
)

foreach ($task in $feTasks) {
    $taskTitle = "[FE]HU-009-$($task.id) $($task.title)"
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
    @{ id = "1"; title = "Probar mapeo de productos"; desc = "Verificar que productos internos se mapean correctamente a catalogo SIN. Probar casos borde."; est = 1 },
    @{ id = "2"; title = "Validar sincronizacion automatica"; desc = "Probar job diario de sincronizacion. Verificar actualizacion de catalogo SIN."; est = 1 },
    @{ id = "3"; title = "Probar manejo de productos sin mapeo"; desc = "Simular productos sin mapeo. Verificar notificaciones y manejo de errores."; est = 1 },
    @{ id = "4"; title = "Validar actualizacion de precios"; desc = "Probar sincronizacion de precios desde catalogo SIN. Verificar consistencia."; est = 1 },
    @{ id = "5"; title = "Tests de rendimiento de mapeo"; desc = "Probar mapeo de gran volumen de productos. Verificar performance y memoria."; est = 1 },
    @{ id = "6"; title = "Validar concurrencia de sincronizacion"; desc = "Probar multiples sincronizaciones simultaneas. Verificar bloqueos y consistencia."; est = 1 }
)

foreach ($task in $qaTasks) {
    $taskTitle = "[QA]HU-009-$($task.id) $($task.title)"
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

Write-Host "`n=== HU-009 Complete ===" -ForegroundColor Green
Write-Host "Total: 1 main + 8 API + 7 FE + 6 QA = 22 issues" -ForegroundColor White
Write-Host "Next: Run 12_hu015_performance_detailed.ps1" -ForegroundColor Cyan
