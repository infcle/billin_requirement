# HU-010 - Generar Paquetes de Envio al SIN (Detailed Sub-tasks)
# Usage: .\16_hu010_paquetes_detailed.ps1 [-WhatIf]

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

Write-Host "=== HU-010: Generar Paquetes de Envio al SIN (Detailed) ===" -ForegroundColor Cyan

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
$mainTitle = "[HU-010] Generar Paquetes de Envio al SIN"
$mainDesc = "Implementar generacion de paquetes de envio de facturas al SIN. Compresion de XMLs. Generacion de manifiesto. Envio batch. Tracking de envios."

$mainQ = 'query { issues(filter: { title: { eq: "' + $mainTitle + '" }, team: { id: { eq: "' + $setup.teamId + '" } } }, first: 1) { nodes { id identifier } } }'
$mainR = Call-Linear $mainQ

$parent = $null
if ($mainR.ok -and $mainR.data.issues.nodes.Count -gt 0) {
    $parent = $mainR.data.issues.nodes[0]
    Write-Host "Main issue exists: $($parent.identifier)" -ForegroundColor Cyan
} elseif ($WhatIf) {
    Write-Host "[WHATIF] Would create: $mainTitle" -ForegroundColor Yellow
    $parent = @{ id = "ISS_WHATIF"; identifier = "INF-WHATIF-010" }
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
    @{ id = "1"; title = "Crear entity PaqueteEnvio y repository"; desc = "Crear JPA entity PaqueteEnvio con campos: id, nombre, fechaCreacion, facturas, estado. Crear repository."; est = 1 },
    @{ id = "2"; title = "Implementar servicio de empaquetado"; desc = "Crear PaqueteService. Agrupar facturas por fecha/limite. Generar ZIP con XMLs."; est = 1 },
    @{ id = "3"; title = "Generacion de manifiesto de envio"; desc = "Implementar ManifiestoGenerator. XML con lista de facturas, totales, checksums."; est = 1 },
    @{ id = "4"; title = "Compresion y optimizacion de archivos"; desc = "Crear FileCompressor. Comprimir XMLs con ZIP. Optimizar tamaño y estructura."; est = 1 },
    @{ id = "5"; title = "Envio batch a API del SIN"; desc = "Implementar SINBatchSender. Enviar paquetes via HTTP. Manejar respuestas y errores."; est = 1 },
    @{ id = "6"; title = "Tracking de envios y recepciones"; desc = "Crear EnvioTracker. Monitorear estado de paquetes. Actualizar estado segun respuestas SIN."; est = 1 },
    @{ id = "7"; title = "Crear endpoint POST /api/v1/paquetes"; desc = "Crear PaqueteController. Crear y enviar paquetes. Consultar estado de envios."; est = 1 },
    @{ id = "8"; title = "Tests unitarios y de integracion"; desc = "Crear tests para PaqueteService, compresion, envio SIN, tracking. Mock de API."; est = 1 }
)

foreach ($task in $apiTasks) {
    $taskTitle = "[API]HU-010-$($task.id) $($task.title)"
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
    @{ id = "1"; title = "Dashboard de paquetes"; desc = "Crear PaqueteDashboardComponent. Mostrar paquetes: estado, tamaño, facturas, fecha envio."; est = 1 },
    @{ id = "2"; title = "Generador de paquetes manual"; desc = "Implementar PaqueteGeneratorComponent. Seleccionar rango de fechas, facturas. Crear paquete."; est = 1 },
    @{ id = "3"; title = "Indicador de estado de envio"; desc = "Crear EnvioStatusComponent. Mostrar: pendiente, enviando, enviado, recibido, error."; est = 1 },
    @{ id = "4"; title = "Vista previa de manifiesto"; desc = "Implementar ManifiestoPreviewComponent. Mostrar contenido del manifiesto antes de enviar."; est = 1 },
    @{ id = "5"; title = "Historial de envios"; desc = "Crear EnvioHistoryComponent. Tabla con historial: fecha, paquete, estado, respuesta SIN."; est = 1 },
    @{ id = "6"; title = "Descarga de paquetes y manifiestos"; desc = "Crear PaqueteDownloadComponent. Descargar ZIP y manifiesto. Progress indicators."; est = 1 },
    @{ id = "7"; title = "Tests E2E"; desc = "Crear E2E tests para flujo: generar paquete -> enviar -> track -> descargar."; est = 1 }
)

foreach ($task in $feTasks) {
    $taskTitle = "[FE]HU-010-$($task.id) $($task.title)"
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
    @{ id = "1"; title = "Validar generacion de paquetes"; desc = "Probar creacion de paquetes con diferentes cantidades de facturas. Verificar estructura ZIP."; est = 1 },
    @{ id = "2"; title = "Probar generacion de manifiesto"; desc = "Validar contenido del manifiesto XML. Verificar checksums y totales."; est = 1 },
    @{ id = "3"; title = "Validar envio a API SIN"; desc = "Probar envio de paquetes. Simular respuestas exitosas y con errores."; est = 1 },
    @{ id = "4"; title = "Probar tracking de envios"; desc = "Verificar actualizacion de estados. Probar notificaciones de cambios."; est = 1 },
    @{ id = "5"; title = "Tests de rendimiento de empaquetado"; desc = "Probar empaquetado de 1000+ facturas. Medir tiempo y uso de memoria."; est = 1 },
    @{ id = "6"; title = "Validar compresion de archivos"; desc = "Probar optimizacion de tamaño. Verificar integridad de XMLs comprimidos."; est = 1 }
)

foreach ($task in $qaTasks) {
    $taskTitle = "[QA]HU-010-$($task.id) $($task.title)"
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

Write-Host "`n=== HU-010 Complete ===" -ForegroundColor Green
Write-Host "Total: 1 main + 8 API + 7 FE + 6 QA = 22 issues" -ForegroundColor White
Write-Host "Next: Run 17_hu011_validacion_detailed.ps1" -ForegroundColor Cyan
