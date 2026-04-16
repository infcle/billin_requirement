# HU-003 - Renovar CUFD Automaticamente (Detailed Sub-tasks)
# Usage: .\04_hu003_cufd_detailed.ps1 [-WhatIf]

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
if (-not (Test-Path "D:\Facturacion en linea\scripts\sprint1_setup.json")) {
    Write-Error "Run 01_sprint1_setup.ps1 first"
    exit 1
}
$setup = Get-Content "D:\Facturacion en linea\scripts\sprint1_setup.json" | ConvertFrom-Json

$headers = @{
    Authorization = $apiKey
    ContentType = "application/json"
}

Write-Host "=== HU-003: Renovar CUFD Automaticamente (Detailed) ===" -ForegroundColor Cyan

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
$mainTitle = "[HU-003] Renovar CUFD Automaticamente"
$mainDesc = "Implementar renovacion automatica de CUFD cada dia antes de su expiracion. CUFD se renueva automaticamente cada 24h. Si falla, reintenta 3 veces con backoff exponencial. Job programado diario."

$mainQ = 'query { issues(filter: { title: { eq: "' + $mainTitle + '" }, team: { id: { eq: "' + $setup.teamId + '" } } }, first: 1) { nodes { id identifier } } }'
$mainR = Call-Linear $mainQ

$parent = $null
if ($mainR.ok -and $mainR.data.issues.nodes.Count -gt 0) {
    $parent = $mainR.data.issues.nodes[0]
    Write-Host "Main issue exists: $($parent.identifier)" -ForegroundColor Cyan
} elseif ($WhatIf) {
    Write-Host "[WHATIF] Would create: $mainTitle" -ForegroundColor Yellow
    $parent = @{ id = "ISS_WHATIF"; identifier = "INF-WHATIF-003" }
} else {
    $mainM = 'mutation { issueCreate(input: { title: "' + $mainTitle + '", description: "' + $mainDesc + '", teamId: "' + $setup.teamId + '", projectId: "' + $setup.projectId + '", cycleId: "' + $setup.cycleId + '", priority: 1, estimate: 8 }) { success issue { id identifier } } }'
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
    @{ id = "1"; title = "Crear entity CUFD y repository"; desc = "Crear JPA entity CUFD con campos: id, codigoCufd, fechaGeneracion, fechaVencimiento, activo. Crear CUFDRepository."; est = 1 },
    @{ id = "2"; title = "Implementar servicio de renovacion CUFD"; desc = "Crear CUFDService con metodos: renovarCUFD(), verificarExpiracion(), obtenerCUFDActivo()."; est = 1 },
    @{ id = "3"; title = "Implementar job diario (cron/scheduler)"; desc = "Configurar @Scheduled para ejecutar renovacion diaria. Verificar CUFD que expiran en 24h."; est = 1 },
    @{ id = "4"; title = "Integrar con servicio SIN para renovacion"; desc = "Crear SINClient con metodo renovarCUFD(). Manejar respuestas exitosas y errores."; est = 1 },
    @{ id = "5"; title = "Logica de reintento 3 veces con backoff"; desc = "Implementar RetryTemplate con backoff exponencial. Configurar maximos reintentos."; est = 1 },
    @{ id = "6"; title = "Tests unitarios"; desc = "Crear unit tests para CUFDService, SINClient y job programado."; est = 1 },
    @{ id = "7"; title = "Tests de integracion con SIN"; desc = "Crear integration tests con mock de SIN. Probar flujo completo de renovacion."; est = 1 }
)

foreach ($task in $apiTasks) {
    $taskTitle = "[API]HU-003-$($task.id) $($task.title)"
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
    @{ id = "1"; title = "Dashboard de estado CUFD"; desc = "Crear componente CUFDashboardComponent. Mostrar CUFD actual, fecha vencimiento, estado."; est = 1 },
    @{ id = "2"; title = "Indicador de proxima renovacion"; desc = "Implementar alerta visual cuando CUFD expire en 24h. Badge con countdown."; est = 1 },
    @{ id = "3"; title = "Boton de renovacion manual"; desc = "Crear boton para renovar CUFD manualmente. Confirmacion y loading state."; est = 1 },
    @{ id = "4"; title = "Notificaciones de renovacion exitosa/fallida"; desc = "Implementar toast notifications para estado de renovacion. Colores segun resultado."; est = 1 },
    @{ id = "5"; title = "Historial de renovaciones"; desc = "Crear tabla con historial de renovaciones. Fecha, resultado, errores."; est = 1 },
    @{ id = "6"; title = "Tests E2E"; desc = "Crear E2E tests para flujo de renovacion automatica y manual."; est = 1 }
)

foreach ($task in $feTasks) {
    $taskTitle = "[FE]HU-003-$($task.id) $($task.title)"
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
    @{ id = "1"; title = "Probar renovacion diaria automatica"; desc = "Simular CUFD que expira en 24h. Verificar que se renueva automaticamente."; est = 1 },
    @{ id = "2"; title = "Simular fallo de servicio SIN"; desc = "Mock SIN para retornar error 503. Verificar retry logic y backoff."; est = 1 },
    @{ id = "3"; title = "Verificar logica de reintento"; desc = "Probar 3 reintentos con backoff exponencial. Validar tiempos de espera."; est = 1 },
    @{ id = "4"; title = "Validar job diario"; desc = "Verificar que job se ejecuta diariamente. Testear con diferentes horarios."; est = 1 },
    @{ id = "5"; title = "Tests de carga"; desc = "Probar renovacion simultanea de multiples CUFD. Verificar performance."; est = 1 }
)

foreach ($task in $qaTasks) {
    $taskTitle = "[QA]HU-003-$($task.id) $($task.title)"
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

Write-Host "`n=== HU-003 Complete ===" -ForegroundColor Green
Write-Host "Total: 1 main + 7 API + 6 FE + 5 QA = 19 issues" -ForegroundColor White
Write-Host "Next: Run 05_hu004_firma_detailed.ps1" -ForegroundColor Cyan
