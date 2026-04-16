# HU-015 - Optimizar Performance de Firmado (Detailed Sub-tasks)
# Usage: .\12_hu015_performance_detailed.ps1 [-WhatIf]

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

Write-Host "=== HU-015: Optimizar Performance de Firmado (Detailed) ===" -ForegroundColor Cyan

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
$mainTitle = "[HU-015] Optimizar Performance de Firmado"
$mainDesc = "Optimizar performance de proceso de firmado digital. Implementar caching, batch processing, async operations. Reducir tiempo de firma de XMLs."

$mainQ = 'query { issues(filter: { title: { eq: "' + $mainTitle + '" }, team: { id: { eq: "' + $setup.teamId + '" } } }, first: 1) { nodes { id identifier } } }'
$mainR = Call-Linear $mainQ

$parent = $null
if ($mainR.ok -and $mainR.data.issues.nodes.Count -gt 0) {
    $parent = $mainR.data.issues.nodes[0]
    Write-Host "Main issue exists: $($parent.identifier)" -ForegroundColor Cyan
} elseif ($WhatIf) {
    Write-Host "[WHATIF] Would create: $mainTitle" -ForegroundColor Yellow
    $parent = @{ id = "ISS_WHATIF"; identifier = "INF-WHATIF-015" }
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
    @{ id = "1"; title = "Implementar caching de certificados"; desc = "Crear CertificateCache. Cache en Redis de certificados frecuentes. TTL 1 hora."; est = 1 },
    @{ id = "2"; title = "Optimizar algoritmo de firma"; desc = "Refactorizar XMLSignatureService. Usar streaming para XMLs grandes. Optimizar BouncyCastle."; est = 1 },
    @{ id = "3"; title = "Implementar batch processing"; desc = "Crear BatchFirmaService. Procesar multiples XMLs en paralelo. Limitar concurrencia."; est = 1 },
    @{ id = "4"; title = "Async operations con CompletableFuture"; desc = "Implementar firma asincrona. Retornar job ID. Endpoint para verificar estado."; est = 1 },
    @{ id = "5"; title = "Pool de conexiones a keystore"; desc = "Optimizar KeyStoreLoader. Pool de conexiones para evitar reopening de keystores."; est = 1 },
    @{ id = "6"; title = "Memory optimization para XMLs grandes"; desc = "Implementar streaming XML processing. Usar SAX parser en lugar de DOM para XMLs > 10MB."; est = 1 },
    @{ id = "7"; title = "Crear endpoint POST /api/v1/firma/batch"; desc = "Crear BatchFirmaController. Aceptar lista de XMLs. Retornar job ID."; est = 1 },
    @{ id = "8"; title = "Performance monitoring y metrics"; desc = "Implementar metrics con Micrometer. Track tiempo de firma, throughput, errores."; est = 1 }
)

foreach ($task in $apiTasks) {
    $taskTitle = "[API]HU-015-$($task.id) $($task.title)"
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
    @{ id = "1"; title = "Upload de multiples archivos"; desc = "Crear MultiFileUploadComponent. Drag & drop de multiples XMLs. Progress bars."; est = 1 },
    @{ id = "2"; title = "Dashboard de jobs de firma"; desc = "Implementar JobDashboardComponent. Mostrar jobs activos, cola, completados, fallidos."; est = 1 },
    @{ id = "3"; title = "Indicadores de performance en tiempo real"; desc = "Crear PerformanceMetricsComponent. Mostrar throughput, tiempo promedio, cola."; est = 1 },
    @{ id = "4"; title = "Notificaciones de jobs completados"; desc = "Implementar JobNotificationService. WebSocket para notificaciones en tiempo real."; est = 1 },
    @{ id = "5"; title = "Descarga batch de resultados"; desc = "Crear BatchDownloadComponent. Zip con todos los XMLs firmados. Download progress."; est = 1 },
    @{ id = "6"; title = "Tests E2E de performance"; desc = "Crear E2E tests para batch processing. Medir tiempos de respuesta UI."; est = 1 }
)

foreach ($task in $feTasks) {
    $taskTitle = "[FE]HU-015-$($task.id) $($task.title)"
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
    @{ id = "1"; title = "Tests de carga de firma individual"; desc = "Probar 1000 firmas individuales. Medir throughput y memoria. Target: <100ms por firma."; est = 1 },
    @{ id = "2"; title = "Tests de carga de batch processing"; desc = "Probar batch de 100 XMLs. Medir tiempo total. Target: <30 segundos total."; est = 1 },
    @{ id = "3"; title = "Validar caching de certificados"; desc = "Probar cache hits/miss. Medir mejora de performance con cache activo."; est = 1 },
    @{ id = "4"; title = "Tests de memoria con XMLs grandes"; desc = "Probar XMLs de 50MB. Verificar memory usage no excede límites. Streaming validation."; est = 1 },
    @{ id = "5"; title = "Tests de concurrencia"; desc = "Probar 50 concurrent signature requests. Verificar no race conditions."; est = 1 },
    @{ id = "6"; title = "Validar metrics y monitoring"; desc = "Probar que metrics se registran correctamente. Verificar dashboard actualiza en tiempo real."; est = 1 }
)

foreach ($task in $qaTasks) {
    $taskTitle = "[QA]HU-015-$($task.id) $($task.title)"
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

Write-Host "`n=== HU-015 Complete ===" -ForegroundColor Green
Write-Host "Total: 1 main + 8 API + 6 FE + 6 QA = 21 issues" -ForegroundColor White
Write-Host "`n=== Sprint 2 Complete ===" -ForegroundColor Green
Write-Host "All Sprint 2 stories with detailed sub-tasks created!" -ForegroundColor White
Write-Host "Total Sprint 2: 100 issues (4 main + 30 API + 23 FE + 19 QA)" -ForegroundColor Cyan
Write-Host "Next: Create scripts for Sprint 3" -ForegroundColor Cyan
