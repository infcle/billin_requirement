# HU-014 - Implementar Retry Logic y Resiliencia (Detailed Sub-tasks)
# Usage: .\06_hu014_retry_detailed.ps1 [-WhatIf]

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

Write-Host "=== HU-014: Retry Logic y Resiliencia (Detailed) ===" -ForegroundColor Cyan

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
$mainTitle = "[HU-014] Implementar Retry Logic y Resiliencia"
$mainDesc = "Implementar logica de reintento ante errores del servidor SIN. Retry con backoff exponencial. Mapeo de errores recuperables. RetryTemplate global. Indicador de reintentos en UI."

$mainQ = 'query { issues(filter: { title: { eq: "' + $mainTitle + '" }, team: { id: { eq: "' + $setup.teamId + '" } } }, first: 1) { nodes { id identifier } } }'
$mainR = Call-Linear $mainQ

$parent = $null
if ($mainR.ok -and $mainR.data.issues.nodes.Count -gt 0) {
    $parent = $mainR.data.issues.nodes[0]
    Write-Host "Main issue exists: $($parent.identifier)" -ForegroundColor Cyan
} elseif ($WhatIf) {
    Write-Host "[WHATIF] Would create: $mainTitle" -ForegroundColor Yellow
    $parent = @{ id = "ISS_WHATIF"; identifier = "INF-WHATIF-014" }
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
    @{ id = "1"; title = "Implementar RetryTemplate global con backoff exponencial"; desc = "Crear GlobalRetryConfig. Configurar ExponentialBackOffPolicy. Max retries: 3, initial delay: 1s."; est = 1 },
    @{ id = "2"; title = "Mapeo de errores HTTP recuperables (500/502/503)"; desc = "Crear RetryableErrorClassifier. Mapear 500, 502, 503 como recuperables. 400, 401 no recuperables."; est = 1 },
    @{ id = "3"; title = "Configuracion de maximos reintentos por endpoint"; desc = "Crear EndpointRetryConfig. Configurar retries diferentes por endpoint: SIN endpoints 3, internos 2."; est = 1 },
    @{ id = "4"; title = "Circuit breaker pattern"; desc = "Implementar CircuitBreaker. Configurar failure threshold: 5, timeout: 60s, half-open retries: 3."; est = 1 },
    @{ id = "5"; title = "Logging de reintentos"; desc = "Crear RetryLogger. Loggear intentos, delays, errores. Incluir correlation ID."; est = 1 },
    @{ id = "6"; title = "Tests de resiliencia"; desc = "Crear ResilienceTests. Probar retry logic, circuit breaker, backoff."; est = 1 },
    @{ id = "7"; title = "Configuracion de timeouts"; desc = "Configurar timeouts por endpoint. SIN: 30s, internos: 10s. Timeout handling."; est = 1 }
)

foreach ($task in $apiTasks) {
    $taskTitle = "[API]HU-014-$($task.id) $($task.title)"
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
    @{ id = "1"; title = "Indicador de reintentos en UI"; desc = "Crear RetryIndicatorComponent. Mostrar: Attempt 2/3, Retry in 3s. Progress bar."; est = 1 },
    @{ id = "2"; title = "Toast de error con boton de retry manual"; desc = "Crear ErrorToastComponent. Mostrar error + boton Retry. Auto-dismiss after 10s."; est = 1 },
    @{ id = "3"; title = "Estado de loading con contador de reintentos"; desc = "Crear LoadingRetryComponent. Spinner + Retry counter. Disable actions."; est = 1 },
    @{ id = "4"; title = "Deshabilitar acciones durante retry"; desc = "Implementar retry guard. Disable buttons, forms. Show overlay."; est = 1 },
    @{ id = "5"; title = "Historial de reintentos"; desc = "Crear RetryHistoryComponent. Mostrar log de reintentos: timestamp, attempt, error."; est = 1 },
    @{ id = "6"; title = "Tests E2E"; desc = "Crear E2E tests para retry flow. Simular errores 500, verificar retry UI."; est = 1 }
)

foreach ($task in $feTasks) {
    $taskTitle = "[FE]HU-014-$($task.id) $($task.title)"
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
    @{ id = "1"; title = "Simular errores 500/502/503"; desc = "Mock SIN para retornar 500, 502, 503. Verificar retry logic y backoff."; est = 1 },
    @{ id = "2"; title = "Verificar backoff exponencial"; desc = "Probar delays: 1s, 2s, 4s. Validar exponential backoff calculation."; est = 1 },
    @{ id = "3"; title = "Probar circuit breaker"; desc = "Simular 5 fallos seguidos. Verificar circuit breaker open, recovery."; est = 1 },
    @{ id = "4"; title = "Validar no-duplicacion de requests"; desc = "Probar que requests fallidos no se ejecutan multiples veces. Idempotency."; est = 1 },
    @{ id = "5"; title = "Tests de carga con fallos"; desc = "Probar 100 concurrent requests con 50% error rate. Verificar resilience."; est = 1 },
    @{ id = "6"; title = "Verificar retry manual"; desc = "Probar boton retry manual en UI. Verificar que solo reintenta una vez."; est = 1 }
)

foreach ($task in $qaTasks) {
    $taskTitle = "[QA]HU-014-$($task.id) $($task.title)"
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

Write-Host "`n=== HU-014 Complete ===" -ForegroundColor Green
Write-Host "Total: 1 main + 7 API + 6 FE + 6 QA = 20 issues" -ForegroundColor White
Write-Host "Next: Run 07_hu013_seguridad_detailed.ps1" -ForegroundColor Cyan
