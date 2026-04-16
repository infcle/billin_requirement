# HU-006 - Calcular Codigo Unico de Facturacion (CUF) (Detailed Sub-tasks)
# Usage: .\10_hu006_cuf_detailed.ps1 [-WhatIf]

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

Write-Host "=== HU-006: Calcular Codigo Unico de Facturacion (Detailed) ===" -ForegroundColor Cyan

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
$mainTitle = "[HU-006] Calcular Codigo Unico de Facturacion (CUF)"
$mainDesc = "Implementar calculo de CUF segun algoritmo del SIN Bolivia. Generar codigo de control. Validar unicidad. Integrar con datos de factura y autorizacion."

$mainQ = 'query { issues(filter: { title: { eq: "' + $mainTitle + '" }, team: { id: { eq: "' + $setup.teamId + '" } } }, first: 1) { nodes { id identifier } } }'
$mainR = Call-Linear $mainQ

$parent = $null
if ($mainR.ok -and $mainR.data.issues.nodes.Count -gt 0) {
    $parent = $mainR.data.issues.nodes[0]
    Write-Host "Main issue exists: $($parent.identifier)" -ForegroundColor Cyan
} elseif ($WhatIf) {
    Write-Host "[WHATIF] Would create: $mainTitle" -ForegroundColor Yellow
    $parent = @{ id = "ISS_WHATIF"; identifier = "INF-WHATIF-006" }
} else {
    $mainM = 'mutation { issueCreate(input: { title: "' + $mainTitle + '", description: "' + $mainDesc + '", teamId: "' + $setup.teamId + '", projectId: "' + $setup.projectId + '", cycleId: "' + $setup.cycleId + '", priority: 2, estimate: 3 }) { success issue { id identifier } } }'
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
    @{ id = "1"; title = "Implementar algoritmo de calculo CUF"; desc = "Crear CUFCalculator con metodo calcularCUF(factura, autorizacion). Implementar algoritmo SIN."; est = 1 },
    @{ id = "2"; title = "Generar codigo de control"; desc = "Implementar ControlCodeGenerator. Calcular codigo de control segun especificaciones SIN."; est = 1 },
    @{ id = "3"; title = "Validar unicidad de CUF"; desc = "Crear CUFValidator. Verificar que CUF no exista en base de datos. Manejar duplicados."; est = 1 },
    @{ id = "4"; title = "Integrar con datos de factura"; desc = "Implementar FacturaDataExtractor. Extraer campos necesarios para calculo CUF."; est = 1 },
    @{ id = "5"; title = "Crear endpoint GET /api/v1/cuf/{facturaId}"; desc = "Crear CUFController. Retornar CUF y codigo de control para factura especifica."; est = 1 },
    @{ id = "6"; title = "Tests unitarios de algoritmo"; desc = "Crear tests para CUFCalculator. Probar con casos de prueba oficiales del SIN."; est = 1 },
    @{ id = "7"; title = "Tests de integracion con factura"; desc = "Crear integration tests. Probar calculo CUF con datos reales de factura."; est = 1 }
)

foreach ($task in $apiTasks) {
    $taskTitle = "[API]HU-006-$($task.id) $($task.title)"
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
    @{ id = "1"; title = "Visualizador de CUF"; desc = "Crear CUFViewerComponent. Mostrar CUF y codigo de control generados. Copy to clipboard."; est = 1 },
    @{ id = "2"; title = "Validador de CUF"; desc = "Implementar CUFValidatorComponent. Validar formato y checksum de CUF ingresado."; est = 1 },
    @{ id = "3"; title = "Historial de CUF generados"; desc = "Crear CUFHistoryComponent. Tabla con CUFs: factura, fecha, CUF, codigo control."; est = 1 },
    @{ id = "4"; title = "Indicador de estado CUF"; desc = "Crear CUFStatusComponent. Mostrar si CUF esta calculado, pendiente, o con error."; est = 1 },
    @{ id = "5"; title = "Tests E2E"; desc = "Crear E2E tests para flujo: crear factura -> calcular CUF -> mostrar resultado."; est = 1 }
)

foreach ($task in $feTasks) {
    $taskTitle = "[FE]HU-006-$($task.id) $($task.title)"
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
    @{ id = "1"; title = "Validar algoritmo CUF contra SIN"; desc = "Probar calculo CUF con casos de prueba oficiales. Verificar resultados coinciden."; est = 1 },
    @{ id = "2"; title = "Probar unicidad de CUF"; desc = "Generar multiples CUFs. Verificar que no hay duplicados. Probar concurrencia."; est = 1 },
    @{ id = "3"; title = "Validar codigo de control"; desc = "Probar generacion de codigo control. Verificar checksum y validacion."; est = 1 }
)

foreach ($task in $qaTasks) {
    $taskTitle = "[QA]HU-006-$($task.id) $($task.title)"
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

Write-Host "`n=== HU-006 Complete ===" -ForegroundColor Green
Write-Host "Total: 1 main + 7 API + 5 FE + 3 QA = 16 issues" -ForegroundColor White
Write-Host "Next: Run 11_hu009_mapeo_detailed.ps1" -ForegroundColor Cyan
