# HU-004 - Firmar Digitalmente XML (Detailed Sub-tasks)
# Usage: .\05_hu004_firma_detailed.ps1 [-WhatIf]

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

Write-Host "=== HU-004: Firmar Digitalmente XML (Detailed) ===" -ForegroundColor Cyan

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
$mainTitle = "[HU-004] Firmar Digitalmente XML"
$mainDesc = "Implementar firma digital de archivos XML de facturas con certificados digitales. Firma XML con XAdES-EPES. Validacion de certificados. Manejo de errores de firma."

$mainQ = 'query { issues(filter: { title: { eq: "' + $mainTitle + '" }, team: { id: { eq: "' + $setup.teamId + '" } } }, first: 1) { nodes { id identifier } } }'
$mainR = Call-Linear $mainQ

$parent = $null
if ($mainR.ok -and $mainR.data.issues.nodes.Count -gt 0) {
    $parent = $mainR.data.issues.nodes[0]
    Write-Host "Main issue exists: $($parent.identifier)" -ForegroundColor Cyan
} elseif ($WhatIf) {
    Write-Host "[WHATIF] Would create: $mainTitle" -ForegroundColor Yellow
    $parent = @{ id = "ISS_WHATIF"; identifier = "INF-WHATIF-004" }
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
    @{ id = "1"; title = "Implementar servicio de firma digital XAdES-EPES"; desc = "Crear XMLSignatureService con metodo firmarXML(xml, certificado). Implementar XAdES-EPES."; est = 1 },
    @{ id = "2"; title = "Crear entity CertificadoDigital y repository"; desc = "Crear JPA entity CertificadoDigital con campos: id, alias, contenidoCifrado, fechaVencimiento, activo."; est = 1 },
    @{ id = "3"; title = "Validacion de certificados (expiracion, revocacion)"; desc = "Crear CertificateValidator. Verificar expiracion, revocacion via CRL/OCSP."; est = 1 },
    @{ id = "4"; title = "Manejo de PKCS#12 (.p12) y certificados PEM"; desc = "Implementar CertificateLoader para cargar .p12 y PEM. Extraer private key y certificate."; est = 1 },
    @{ id = "5"; title = "Integracion con libreria de firma (BouncyCastle)"; desc = "Configurar BouncyCastle para firma XML. Implementar XAdES signature profile."; est = 1 },
    @{ id = "6"; title = "Servicio de firma de XML"; desc = "Crear FirmaService con endpoints: POST /api/v1/firma/xml. Validar y firmar XML."; est = 1 },
    @{ id = "7"; title = "Validacion de firma generada"; desc = "Implementar validador de firma XAdES. Verificar signature y certificate chain."; est = 1 },
    @{ id = "8"; title = "Tests unitarios y de integracion"; desc = "Crear tests para XMLSignatureService, CertificateValidator, FirmaService."; est = 1 }
)

foreach ($task in $apiTasks) {
    $taskTitle = "[API]HU-004-$($task.id) $($task.title)"
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
    @{ id = "1"; title = "Upload de certificados digitales"; desc = "Crear CertificateUploadComponent. Soportar .p12 y PEM. Validar formato y tamaño."; est = 1 },
    @{ id = "2"; title = "Vista previa de certificado (datos, validez)"; desc = "Crear CertificatePreviewComponent. Mostrar subject, issuer, valid dates."; est = 1 },
    @{ id = "3"; title = "Boton de firma de facturas"; desc = "Crear FirmaButtonComponent. Seleccionar factura y certificado. Confirmacion."; est = 1 },
    @{ id = "4"; title = "Indicador de estado de firma"; desc = "Implementar FirmaStatusComponent. Mostrar: no firmado, firmando, firmado, error."; est = 1 },
    @{ id = "5"; title = "Visualizacion de firma en XML"; desc = "Crear SignatureViewerComponent. Mostrar firma XAdES en XML con syntax highlighting."; est = 1 },
    @{ id = "6"; title = "Validacion visual de firma"; desc = "Implementar validacion visual. Mostrar si firma es valida, certificado info."; est = 1 },
    @{ id = "7"; title = "Tests E2E"; desc = "Crear E2E tests para flujo completo: upload certificado -> firma -> validacion."; est = 1 }
)

foreach ($task in $feTasks) {
    $taskTitle = "[FE]HU-004-$($task.id) $($task.title)"
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
    @{ id = "1"; title = "Probar firma con diferentes certificados"; desc = "Testear con .p12 y PEM. Validar firma XAdES-EPES generada."; est = 1 },
    @{ id = "2"; title = "Validar firma XAdES-EPES"; desc = "Verificar estructura XAdES. Validar signature value y certificate chain."; est = 1 },
    @{ id = "3"; title = "Simular certificados expirados"; desc = "Probar con certificados expirados. Verificar manejo de errores."; est = 1 },
    @{ id = "4"; title = "Verificar manejo de errores"; desc = "Simular certificados invalidos, XML malformado. Validar mensajes de error."; est = 1 },
    @{ id = "5"; title = "Tests de rendimiento de firma"; desc = "Probar performance de firma con XMLs de diferentes tamaños. Medir tiempos."; est = 1 },
    @{ id = "6"; title = "Validacion contra SIN"; desc = "Probar firma con XMLs de prueba del SIN. Validar aceptacion."; est = 1 }
)

foreach ($task in $qaTasks) {
    $taskTitle = "[QA]HU-004-$($task.id) $($task.title)"
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
            Write-Host "Created [QA] $($task.id): $($taskR2.data.issueCreate.issue.identifier)" -ForegroundColor DarkGreen
        } else {
            Write-Warning "  [QA] $($task.id) failed: $($taskR2.err)"
        }
    }
    Start-Sleep -Seconds 1
}

Write-Host "`n=== HU-004 Complete ===" -ForegroundColor Green
Write-Host "Total: 1 main + 8 API + 7 FE + 6 QA = 22 issues" -ForegroundColor White
Write-Host "Next: Run 06_hu014_retry_detailed.ps1" -ForegroundColor Cyan
