# HU-001 - Registrar y Usar Token Delegado del SIN
# Usage: .\02_hu001_token.ps1 [-WhatIf]

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

Write-Host "=== HU-001: Token Delegado del SIN ===" -ForegroundColor Cyan

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

# API Sub-issue
Write-Host "`n[API] Sub-issue..." -ForegroundColor Cyan
$apiTitle = "[API]HU-001 Registrar y Usar Token Delegado del SIN"
$apiDesc = "Backend implementation tasks:`n- Crear entity Token y repository`n- Implementar servicio de cifrado AES-256`n- Implementar TokenService`n- Crear endpoint POST /api/v1/siat/token`n- Crear endpoint GET /api/v1/siat/token/{id}`n- Tests unitarios`n- Documentar API en Swagger`n`nParent: $($parent.identifier)"

$apiQ = 'query { issues(filter: { title: { eq: "' + $apiTitle + '" }, team: { id: { eq: "' + $setup.teamId + '" } } }, first: 1) { nodes { id identifier } } }'
$apiR = Call-Linear $apiQ

if ($apiR.ok -and $apiR.data.issues.nodes.Count -gt 0) {
    Write-Host "[API] exists: $($apiR.data.issues.nodes[0].identifier)" -ForegroundColor Cyan
} elseif ($WhatIf) {
    Write-Host "[WHATIF] Would create [API] sub-issue" -ForegroundColor Yellow
} else {
    $apiM = 'mutation { issueCreate(input: { title: "' + $apiTitle + '", description: "' + $apiDesc + '", teamId: "' + $setup.teamId + '", projectId: "' + $setup.projectId + '", cycleId: "' + $setup.cycleId + '", parentId: "' + $parent.id + '", priority: 1, estimate: 2 }) { success issue { id identifier } } }'
    $apiR2 = Call-Linear $apiM
    if ($apiR2.ok -and $apiR2.data.issueCreate.success) {
        Write-Host "Created [API]: $($apiR2.data.issueCreate.issue.identifier)" -ForegroundColor Green
    } else {
        Write-Warning "[API] failed: $($apiR2.err)"
    }
}

# FE Sub-issue
Write-Host "`n[FE] Sub-issue..." -ForegroundColor Cyan
$feTitle = "[FE]HU-001 Registrar y Usar Token Delegado del SIN"
$feDesc = "Frontend implementation tasks:`n- Formulario de registro de token`n- Validacion de formato de token`n- Mensajes de error`n- Tests E2E`n`nParent: $($parent.identifier)"

$feQ = 'query { issues(filter: { title: { eq: "' + $feTitle + '" }, team: { id: { eq: "' + $setup.teamId + '" } } }, first: 1) { nodes { id identifier } } }'
$feR = Call-Linear $feQ

if ($feR.ok -and $feR.data.issues.nodes.Count -gt 0) {
    Write-Host "[FE] exists: $($feR.data.issues.nodes[0].identifier)" -ForegroundColor Cyan
} elseif ($WhatIf) {
    Write-Host "[WHATIF] Would create [FE] sub-issue" -ForegroundColor Yellow
} else {
    $feM = 'mutation { issueCreate(input: { title: "' + $feTitle + '", description: "' + $feDesc + '", teamId: "' + $setup.teamId + '", projectId: "' + $setup.projectId + '", cycleId: "' + $setup.cycleId + '", parentId: "' + $parent.id + '", priority: 1, estimate: 2 }) { success issue { id identifier } } }'
    $feR2 = Call-Linear $feM
    if ($feR2.ok -and $feR2.data.issueCreate.success) {
        Write-Host "Created [FE]: $($feR2.data.issueCreate.issue.identifier)" -ForegroundColor Green
    } else {
        Write-Warning "[FE] failed: $($feR2.err)"
    }
}

# QA Sub-issue
Write-Host "`n[QA] Sub-issue..." -ForegroundColor Cyan
$qaTitle = "[QA]HU-001 Registrar y Usar Token Delegado del SIN"
$qaDesc = "QA testing tasks:`n- Validar cifrado AES-256`n- Probar integracion con SIN`n- Verificar manejo de errores`n`nParent: $($parent.identifier)"

$qaQ = 'query { issues(filter: { title: { eq: "' + $qaTitle + '" }, team: { id: { eq: "' + $setup.teamId + '" } } }, first: 1) { nodes { id identifier } } }'
$qaR = Call-Linear $qaQ

if ($qaR.ok -and $qaR.data.issues.nodes.Count -gt 0) {
    Write-Host "[QA] exists: $($qaR.data.issues.nodes[0].identifier)" -ForegroundColor Cyan
} elseif ($WhatIf) {
    Write-Host "[WHATIF] Would create [QA] sub-issue" -ForegroundColor Yellow
} else {
    $qaM = 'mutation { issueCreate(input: { title: "' + $qaTitle + '", description: "' + $qaDesc + '", teamId: "' + $setup.teamId + '", projectId: "' + $setup.projectId + '", cycleId: "' + $setup.cycleId + '", parentId: "' + $parent.id + '", priority: 1, estimate: 1 }) { success issue { id identifier } } }'
    $qaR2 = Call-Linear $qaM
    if ($qaR2.ok -and $qaR2.data.issueCreate.success) {
        Write-Host "Created [QA]: $($qaR2.data.issueCreate.issue.identifier)" -ForegroundColor Green
    } else {
        Write-Warning "[QA] failed: $($qaR2.err)"
    }
}

Write-Host "`n=== HU-001 Complete ===" -ForegroundColor Green
Write-Host "Next: Run 03_hu002_cuis.ps1" -ForegroundColor Cyan
