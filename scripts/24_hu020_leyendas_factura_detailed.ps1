# HU-020 - Sincronizar Leyendas de Factura del SIN (Detailed Sub-tasks)
# Usage: .\24_hu020_leyendas_factura_detailed.ps1 [-WhatIf]

param(
    [switch]$WhatIf = $false
)

# Check API Key
$apiKey = $env:LINEAR_API_KEY
if (-not $apiKey) {
    Write-Error "LINEAR_API_KEY not set"
    exit 1
}

# Load setup data from Sprint 2
if (-not (Test-Path "D:\Facturacion en linea\scripts\sprint2_setup.json")) {
    Write-Error "Run 08_sprint2_setup.ps1 first"
    exit 1
}
$setup = Get-Content "D:\Facturacion en linea\scripts\sprint2_setup.json" | ConvertFrom-Json

$headers = @{
    Authorization = $apiKey
    ContentType = "application/json"
}

Write-Host "=== HU-020: Sincronizar Leyendas de Factura del SIN (Detailed) ===" -ForegroundColor Cyan

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
$mainTitle = "[HU-020] Sincronizar Leyendas de Factura del SIN"
$mainDesc = "Implementar sincronizacion de leyendas de factura del SIN. Obtener leyendas obligatorias y opcionales. Mapear códigos y textos. Cache con actualización diaria."

$mainQ = 'query { issues(filter: { title: { eq: "' + $mainTitle + '" }, team: { id: { eq: "' + $setup.teamId + '" } } }, first: 1) { nodes { id identifier } } }'
$mainR = Call-Linear $mainQ

$parent = $null
if ($mainR.ok -and $mainR.data.issues.nodes.Count -gt 0) {
    $parent = $mainR.data.issues.nodes[0]
    Write-Host "Main issue exists: $($parent.identifier)" -ForegroundColor Cyan
} elseif ($WhatIf) {
    Write-Host "[WHATIF] Would create: $mainTitle" -ForegroundColor Yellow
    $parent = @{ id = "ISS_WHATIF"; identifier = "INF-WHATIF-020" }
} else {
    $mainM = 'mutation { issueCreate(input: { title: "' + $mainTitle + '", description: "' + $mainDesc + '", teamId: "' + $setup.teamId + '", projectId: "' + $setup.projectId + '", cycleId: "' + $setup.cycleId + '", priority: 2, estimate: 5 }) { success issue { id identifier } } }'
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
    @{ id = "1"; title = "Crear entity LeyendaFactura y repository"; desc = "Crear JPA entity LeyendaFactura con campos: codigo, descripcion, tipo, obligatoria, activa."; est = 1 },
    @{ id = "2"; title = "Implementar servicio de sincronización"; desc = "Crear LeyendaFacturaSincronizador. Obtener leyendas del SIN API. Mapear campos y validar."; est = 1 },
    @{ id = "3"; title = "Validar tipos de leyendas"; desc = "Implementar LeyendaTipoValidator. Validar tipos: obligatoria, opcional, condicional. Manejar duplicados."; est = 1 },
    @{ id = "4"; title = "Cache de leyendas con Redis"; desc = "Crear LeyendaFacturaCache. Redis cache con TTL 24h. Refresh automatico diario."; est = 1 },
    @{ id = "5"; title = "Crear endpoint GET /api/v1/leyendas-factura"; desc = "Implementar LeyendaFacturaController. Listar leyendas con filtros por tipo y activación."; est = 1 },
    @{ id = "6"; title = "Tests unitarios y de integración"; desc = "Crear tests para sincronizador, validator, cache, endpoint. Mock de API SIN."; est = 1 }
)

foreach ($task in $apiTasks) {
    $taskTitle = "[API]HU-020-$($task.id) $($task.title)"
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
    @{ id = "1"; title = "Lista de leyendas con búsqueda"; desc = "Crear LeyendasFacturaListComponent. Mostrar lista con búsqueda y filtros por tipo."; est = 1 },
    @{ id = "2"; title = "Selector de leyendas"; desc = "Implementar LeyendaSelectorComponent. Selector multiple para leyendas en formularios de factura."; est = 1 },
    @{ id = "3"; title = "Dashboard de estado de sincronización"; desc = "Crear LeyendaSyncDashboard. Mostrar fecha última sincronización, cantidad, errores."; est = 1 },
    @{ id = "4"; title = "Editor de leyendas"; desc = "Implementar LeyendaEditorComponent. Editar descripciones y activar/desactivar leyendas."; est = 1 },
    @{ id = "5"; title = "Tests E2E"; desc = "Crear E2E tests para lista, selector, dashboard, editor, sincronización manual."; est = 1 }
)

foreach ($task in $feTasks) {
    $taskTitle = "[FE]HU-020-$($task.id) $($task.title)"
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
    @{ id = "1"; title = "Probar sincronización de leyendas"; desc = "Verificar sincronización completa. Validar códigos y textos contra API SIN."; est = 1 },
    @{ id = "2"; title = "Validar tipos de leyendas"; desc = "Probar validación de tipos: obligatoria, opcional, condicional. Verificar lógica."; est = 1 },
    @{ id = "3"; title = "Probar cache de leyendas"; desc = "Validar cache Redis con TTL 24h. Probar refresh y actualización."; est = 1 },
    @{ id = "4"; title = "Probar endpoint de leyendas"; desc = "Validar endpoint GET /api/v1/leyendas-factura. Probar filtros y paginación."; est = 1 },
    @{ id = "5"; title = "Tests de rendimiento de sincronización"; desc = "Probar sincronización con gran volumen de leyendas. Medir tiempo y memoria."; est = 1 }
)

foreach ($task in $qaTasks) {
    $taskTitle = "[QA]HU-020-$($task.id) $($task.title)"
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

Write-Host "`n=== HU-020 Complete ===" -ForegroundColor Green
Write-Host "Total: 1 main + 6 API + 5 FE + 5 QA = 17 issues" -ForegroundColor White
Write-Host "Next: Run 25_hu021_mensajes_servicios_detailed.ps1" -ForegroundColor Cyan
