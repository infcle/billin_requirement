# HU-001 - Registrar y Usar Token Delegado del SIN (Detailed Sub-tasks)
# Usage: .\02_hu001_token_detailed.ps1 [-WhatIf]

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

Write-Host "=== HU-001: Token Delegado del SIN (Detailed) ===" -ForegroundColor Cyan

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
$mainTitle = "[HU-001] Registrar y Usar Token Delegado del SIN"
$mainDesc = "Implementar registro y uso de token delegado SIN. Token se almacena cifrado con AES-256-CBC. Endpoints: POST /api/v1/siat/token, GET /api/v1/siat/token/{id}. Microservicio: siat-auth-service."

$mainQ = 'query { issues(filter: { title: { eq: "' + $mainTitle + '" }, team: { id: { eq: "' + $setup.teamId + '" } } }, first: 1) { nodes { id identifier } } }'
$mainR = Call-Linear $mainQ

$parent = $null
if ($mainR.ok -and $mainR.data.issues.nodes.Count -gt 0) {
    $parent = $mainR.data.issues.nodes[0]
    Write-Host "Main issue exists: $($parent.identifier)" -ForegroundColor Cyan
} elseif ($WhatIf) {
    Write-Host "[WHATIF] Would create: $mainTitle" -ForegroundColor Yellow
    $parent = @{ id = "ISS_WHATIF"; identifier = "INF-WHATIF-001" }
} else {
    $mainM = 'mutation { issueCreate(input: { title: "' + $mainTitle + '", description: "' + $mainDesc + '", teamId: "' + $setup.teamId + '", projectId: "' + $setup.projectId + '", cycleId: "' + $setup.cycleId + '", priority: 1, estimate: 5 }) { success issue { id identifier } } }'
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
    @{ id = "1"; title = "Crear entity Token y repository"; desc = "Crear JPA entity Token con campos: id, tokenCifrado, fechaCreacion, fechaExpiracion, activo. Crear TokenRepository."; est = 1 },
    @{ id = "2"; title = "Implementar servicio de cifrado AES-256"; desc = "Crear EncryptionService con metodos: cifrar(texto), descifrar(textoCifrado). Usar AES-256-CBC."; est = 1 },
    @{ id = "3"; title = "Implementar TokenService"; desc = "Crear TokenService con metodos: registrarToken(token), obtenerToken(id), validarToken(id)."; est = 1 },
    @{ id = "4"; title = "Crear endpoint POST /api/v1/siat/token"; desc = "Crear controller para registrar token. Validar formato, cifrar y almacenar."; est = 1 },
    @{ id = "5"; title = "Crear endpoint GET /api/v1/siat/token/{id}"; desc = "Crear controller para obtener token por ID. Descifrar y retornar si activo."; est = 1 },
    @{ id = "6"; title = "Tests unitarios"; desc = "Crear unit tests para TokenService, EncryptionService y controllers."; est = 1 },
    @{ id = "7"; title = "Documentar API en Swagger"; desc = "Configurar Swagger/OpenAPI. Documentar endpoints con ejemplos."; est = 1 }
)

foreach ($task in $apiTasks) {
    $taskTitle = "[API]HU-001-$($task.id) $($task.title)"
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
    @{ id = "1"; title = "Formulario de registro de token"; desc = "Crear componente TokenFormComponent con campos: token, descripcion. Validaciones."; est = 1 },
    @{ id = "2"; title = "Validacion de formato de token"; desc = "Implementar validadores: formato JWT, longitud minima, caracteres especiales."; est = 1 },
    @{ id = "3"; title = "Mensajes de error"; desc = "Crear mensajes de error para validaciones y respuestas del servidor. Toast notifications."; est = 1 },
    @{ id = "4"; title = "Tests E2E"; desc = "Crear E2E tests para flujo completo de registro y consulta de tokens."; est = 1 }
)

foreach ($task in $feTasks) {
    $taskTitle = "[FE]HU-001-$($task.id) $($task.title)"
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
    @{ id = "1"; title = "Validar cifrado AES-256"; desc = "Verificar que token se cifra correctamente. Probar descifrado. Validar que no se almacena en claro."; est = 1 },
    @{ id = "2"; title = "Probar integracion con SIN"; desc = "Simular llamadas a endpoints SIN. Validar manejo de respuestas exitosas y errores."; est = 1 },
    @{ id = "3"; title = "Verificar manejo de errores"; desc = "Probar casos de error: token invalido, fallo de cifrado, base de datos caida."; est = 1 }
)

foreach ($task in $qaTasks) {
    $taskTitle = "[QA]HU-001-$($task.id) $($task.title)"
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

Write-Host "`n=== HU-001 Complete ===" -ForegroundColor Green
Write-Host "Total: 1 main + 7 API + 4 FE + 3 QA = 15 issues" -ForegroundColor White
Write-Host "Next: Run 03_hu002_cuis_detailed.ps1" -ForegroundColor Cyan
