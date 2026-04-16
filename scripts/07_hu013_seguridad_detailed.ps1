# HU-013 - Cifrar Llaves Privadas y Gestionar Accesos (Detailed Sub-tasks)
# Usage: .\07_hu013_seguridad_detailed.ps1 [-WhatIf]

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

Write-Host "=== HU-013: Cifrar Llaves Privadas y Accesos (Detailed) ===" -ForegroundColor Cyan

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
$mainTitle = "[HU-013] Cifrar Llaves Privadas y Gestionar Accesos"
$mainDesc = "Implementar cifrado AES-256-CBC de llaves privadas de certificados digitales. Integrar Keycloak para autenticacion. Auditoria de accesos. Rotacion de llaves."

$mainQ = 'query { issues(filter: { title: { eq: "' + $mainTitle + '" }, team: { id: { eq: "' + $setup.teamId + '" } } }, first: 1) { nodes { id identifier } } }'
$mainR = Call-Linear $mainQ

$parent = $null
if ($mainR.ok -and $mainR.data.issues.nodes.Count -gt 0) {
    $parent = $mainR.data.issues.nodes[0]
    Write-Host "Main issue exists: $($parent.identifier)" -ForegroundColor Cyan
} elseif ($WhatIf) {
    Write-Host "[WHATIF] Would create: $mainTitle" -ForegroundColor Yellow
    $parent = @{ id = "ISS_WHATIF"; identifier = "INF-WHATIF-013" }
} else {
    $mainM = 'mutation { issueCreate(input: { title: "' + $mainTitle + '", description: "' + $mainDesc + '", teamId: "' + $setup.teamId + '", projectId: "' + $setup.projectId + '", cycleId: "' + $setup.cycleId + '", priority: 1, estimate: 13 }) { success issue { id identifier } } }'
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
    @{ id = "1"; title = "Implementar servicio de cifrado AES-256-CBC"; desc = "Crear EncryptionService con metodos: cifrarLlave(llave), descifrarLlave(llaveCifrada). Usar AES-256-CBC."; est = 1 },
    @{ id = "2"; title = "Crear entity CertificadoDigital con llave cifrada"; desc = "Crear JPA entity con campos: id, alias, llavePrivadaCifrada, certificadoPublico, fechaVencimiento."; est = 1 },
    @{ id = "3"; title = "Integrar Keycloak para autenticacion OAuth2/JWT"; desc = "Configurar Spring Security con Keycloak. JWT token validation. Role-based access."; est = 1 },
    @{ id = "4"; title = "Implementar servicio de auditoria de accesos"; desc = "Crear AuditService. Loggear accesos a llaves: user, action, timestamp, result."; est = 1 },
    @{ id = "5"; title = "Rotacion automatica de llaves de cifrado"; desc = "Crear KeyRotationService. Rotar llaves de AES cada 90 dias. Migrar datos cifrados."; est = 1 },
    @{ id = "6"; title = "Validacion de roles y permisos"; desc = "Implementar @PreAuthorize. Roles: ADMIN, OPERADOR, AUDITOR. Permisos por recurso."; est = 1 },
    @{ id = "7"; title = "Logging de operaciones sensibles"; desc = "Crear SecurityLogger. Loggear intentos de acceso, descifrado, rotacion. Nivel INFO/WARN."; est = 1 },
    @{ id = "8"; title = "Tests de seguridad"; desc = "Crear SecurityTests. Probar cifrado, roles, auditoria. Penetration testing basico."; est = 1 }
)

foreach ($task in $apiTasks) {
    $taskTitle = "[API]HU-013-$($task.id) $($task.title)"
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
    @{ id = "1"; title = "Login con Keycloak"; desc = "Crear LoginComponent. Integrar con Keycloak OIDC. Handle redirect y token exchange."; est = 1 },
    @{ id = "2"; title = "Gestion de roles y permisos"; desc = "Crear RoleManagementComponent. CRUD de roles. Asignacion de permisos por usuario."; est = 1 },
    @{ id = "3"; title = "Panel de auditoria de accesos"; desc = "Crear AuditPanelComponent. Tabla con logs: usuario, accion, timestamp, IP, resultado."; est = 1 },
    @{ id = "4"; title = "Upload seguro de certificados"; desc = "Crear SecureCertificateUpload. Validar formato, tamaño. Cifrar llave en frontend antes de enviar."; est = 1 },
    @{ id = "5"; title = "Vista de certificados cifrados"; desc = "Crear CertificateListView. Mostrar alias, fecha vencimiento. No mostrar llave privada."; est = 1 },
    @{ id = "6"; title = "Logs de auditoria"; desc = "Crear AuditLogComponent. Filtros por usuario, fecha, accion. Export a CSV."; est = 1 },
    @{ id = "7"; title = "Tests E2E"; desc = "Crear E2E tests para flujo: login -> gestion roles -> upload certificado -> auditoria."; est = 1 }
)

foreach ($task in $feTasks) {
    $taskTitle = "[FE]HU-013-$($task.id) $($task.title)"
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
    @{ id = "1"; title = "Validar cifrado AES-256-CBC"; desc = "Probar cifrado/descifrado de llaves. Verificar que llave privada no se almacena en claro."; est = 1 },
    @{ id = "2"; title = "Probar autenticacion Keycloak"; desc = "Testear login/logout. Validar JWT tokens. Probar refresh token."; est = 1 },
    @{ id = "3"; title = "Verificar roles y permisos"; desc = "Probar acceso denegado sin rol. Testear @PreAuthorize en endpoints."; est = 1 },
    @{ id = "4"; title = "Auditar accesos no autorizados"; desc = "Simular accesos no autorizados. Verificar que se loggeen en auditoria."; est = 1 },
    @{ id = "5"; title = "Tests de penetracion basicos"; desc = "Probar SQL injection, XSS, CSRF en endpoints de certificados."; est = 1 },
    @{ id = "6"; title = "Validar rotacion de llaves"; desc = "Probar rotacion automatica. Verificar que datos viejos se pueden descifrar."; est = 1 }
)

foreach ($task in $qaTasks) {
    $taskTitle = "[QA]HU-013-$($task.id) $($task.title)"
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

Write-Host "`n=== HU-013 Complete ===" -ForegroundColor Green
Write-Host "Total: 1 main + 8 API + 7 FE + 6 QA = 22 issues" -ForegroundColor White
Write-Host "`n=== Sprint 1 Complete ===" -ForegroundColor Green
Write-Host "All Sprint 1 stories with detailed sub-tasks created!" -ForegroundColor White
Write-Host "Total Sprint 1: 117 issues (7 main + 37 API + 28 FE + 21 QA)" -ForegroundColor Cyan
Write-Host "Next: Create scripts for Sprint 2" -ForegroundColor Cyan
