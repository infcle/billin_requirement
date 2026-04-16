# HU-011 - Validar Paquetes de Envio (Detailed Sub-tasks)
# Usage: .\17_hu011_validacion_detailed.ps1 [-WhatIf]

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

Write-Host "=== HU-011: Validar Paquetes de Envio (Detailed) ===" -ForegroundColor Cyan

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
$mainTitle = "[HU-011] Validar Paquetes de Envio"
$mainDesc = "Implementar validacion de paquetes antes de enviar al SIN. Validacion de estructura, checksums, firmas. Reporte de errores. Correccion automatica de problemas comunes."

$mainQ = 'query { issues(filter: { title: { eq: "' + $mainTitle + '" }, team: { id: { eq: "' + $setup.teamId + '" } } }, first: 1) { nodes { id identifier } } }'
$mainR = Call-Linear $mainQ

$parent = $null
if ($mainR.ok -and $mainR.data.issues.nodes.Count -gt 0) {
    $parent = $mainR.data.issues.nodes[0]
    Write-Host "Main issue exists: $($parent.identifier)" -ForegroundColor Cyan
} elseif ($WhatIf) {
    Write-Host "[WHATIF] Would create: $mainTitle" -ForegroundColor Yellow
    $parent = @{ id = "ISS_WHATIF"; identifier = "INF-WHATIF-011" }
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
    @{ id = "1"; title = "Crear entity ValidacionPaquete y repository"; desc = "Crear JPA entity ValidacionPaquete con campos: id, paqueteId, resultado, errores, fechaValidacion."; est = 1 },
    @{ id = "2"; title = "Implementar validador de estructura ZIP"; desc = "Crear ZIPStructureValidator. Validar estructura de carpetas, nombres de archivos, extensiones."; est = 1 },
    @{ id = "3"; title = "Validacion de checksums y hashes"; desc = "Implementar ChecksumValidator. Calcular y validar MD5/SHA256 de archivos. Comparar con manifiesto."; est = 1 },
    @{ id = "4"; title = "Validacion de firmas digitales"; desc = "Crear FirmaDigitalValidator. Verificar firmas XAdES en XMLs. Validar certificados."; est = 1 },
    @{ id = "5"; title = "Correccion automatica de errores"; desc = "Implementar ErrorAutoCorrector. Corregir problemas comunes: nombres, estructura, encoding."; est = 1 },
    @{ id = "6"; title = "Generacion de reporte de validacion"; desc = "Crear ValidacionReportGenerator. Reporte detallado de errores encontrados y correcciones."; est = 1 },
    @{ id = "7"; title = "Crear endpoint POST /api/v1/paquetes/validar"; desc = "Crear ValidacionController. Validar paquete, retornar resultado y reporte."; est = 1 },
    @{ id = "8"; title = "Tests unitarios y de integracion"; desc = "Crear tests para validadores, autocorreccion, reportes. Mock de paquetes con errores."; est = 1 }
)

foreach ($task in $apiTasks) {
    $taskTitle = "[API]HU-011-$($task.id) $($task.title)"
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
    @{ id = "1"; title = "Upload y validacion de paquetes"; desc = "Crear PaqueteValidationComponent. Upload ZIP, mostrar resultados en tiempo real."; est = 1 },
    @{ id = "2"; title = "Dashboard de resultados de validacion"; desc = "Implementar ValidationResultDashboard. Mostrar errores, warnings, estado general."; est = 1 },
    @{ id = "3"; title = "Visor detallado de errores"; desc = "Crear ErrorDetailsComponent. Expandir cada error con descripcion y sugerencias."; est = 1 },
    @{ id = "4"; title = "Correccion automatica de errores"; desc = "Implementar AutoCorrectionUI. Boton para aplicar correcciones automaticas. Preview de cambios."; est = 1 },
    @{ id = "5"; title = "Descarga de reportes de validacion"; desc = "Crear ValidationReportDownloadComponent. Descargar reporte PDF/Excel con resultados."; est = 1 },
    @{ id = "6"; title = "Historial de validaciones"; desc = "Crear ValidationHistoryComponent. Tabla con validaciones anteriores: fecha, paquete, resultado."; est = 1 },
    @{ id = "7"; title = "Tests E2E"; desc = "Crear E2E tests para flujo: upload -> validar -> corregir -> descargar reporte."; est = 1 }
)

foreach ($task in $feTasks) {
    $taskTitle = "[FE]HU-011-$($task.id) $($task.title)"
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
    @{ id = "1"; title = "Probar validacion de estructura ZIP"; desc = "Crear ZIPs con estructuras invalidas. Verificar deteccion de errores."; est = 1 },
    @{ id = "2"; title = "Validar checksums y hashes"; desc = "Probar archivos con checksums incorrectos. Verificar validacion MD5/SHA256."; est = 1 },
    @{ id = "3"; title = "Probar validacion de firmas digitales"; desc = "Crear XMLs con firmas invalidas/expiradas. Verificar deteccion."; est = 1 },
    @{ id = "4"; title = "Validar correccion automatica"; desc = "Probar autocorreccion de errores comunes. Verificar que no introduce nuevos errores."; est = 1 },
    @{ id = "5"; title = "Tests de rendimiento de validacion"; desc = "Probar validacion de paquetes grandes (1000+ XMLs). Medir tiempo y memoria."; est = 1 },
    @{ id = "6"; title = "Validar reportes de validacion"; desc = "Probar generacion de reportes. Validar contenido y formato PDF/Excel."; est = 1 }
)

foreach ($task in $qaTasks) {
    $taskTitle = "[QA]HU-011-$($task.id) $($task.title)"
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

Write-Host "`n=== HU-011 Complete ===" -ForegroundColor Green
Write-Host "Total: 1 main + 8 API + 7 FE + 6 QA = 22 issues" -ForegroundColor White
Write-Host "`n=== Sprint 3 Complete ===" -ForegroundColor Green
Write-Host "All Sprint 3 stories with detailed sub-tasks created!" -ForegroundColor White
Write-Host "Total Sprint 3: 88 issues (4 main + 32 API + 28 FE + 24 QA)" -ForegroundColor Cyan
Write-Host "Next: Create scripts for Sprint 4" -ForegroundColor Cyan
