# Sprint 2 Setup - Create Sprint 2 Cycle
# Usage: .\08_sprint2_setup.ps1 [-WhatIf]

param(
    [string]$TeamKey = "INF",
    [switch]$WhatIf = $false
)

# Check API Key
$apiKey = $env:LINEAR_API_KEY
if (-not $apiKey) {
    Write-Error "LINEAR_API_KEY not set. Run: [Environment]::SetEnvironmentVariable('LINEAR_API_KEY', 'your_key', 'User')"
    exit 1
}

# Load setup data from Sprint 1
if (-not (Test-Path "D:\Facturacion en linea\scripts\sprint1_setup.json")) {
    Write-Error "Run 01_sprint1_setup.ps1 first"
    exit 1
}
$setup = Get-Content "D:\Facturacion en linea\scripts\sprint1_setup.json" | ConvertFrom-Json

$headers = @{
    Authorization = $apiKey
    ContentType = "application/json"
}

Write-Host "=== Sprint 2 Setup ===" -ForegroundColor Cyan

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

# Create/Get Sprint 2 Cycle
Write-Host "`nSprint 2 Cycle..." -ForegroundColor Cyan
$cycleName = "Sprint 2: Emision y Facturacion"
$cycleQ = 'query { cycles(filter: { name: { eqIgnoreCase: "' + $cycleName + '" }, team: { id: { eq: "' + $setup.teamId + '" } } }) { nodes { id name } } }'
$cycleR = Call-Linear $cycleQ

$cycle = $null
if ($cycleR.ok -and $cycleR.data.cycles.nodes.Count -gt 0) {
    $cycle = $cycleR.data.cycles.nodes[0]
    Write-Host "Cycle exists: $($cycle.name)" -ForegroundColor Cyan
} elseif ($WhatIf) {
    Write-Host "[WHATIF] Would create cycle: $cycleName" -ForegroundColor Yellow
    $cycle = @{ id = "CYC_WHATIF" }
} else {
    $cycleM = 'mutation { cycleCreate(input: { name: "' + $cycleName + '", startsAt: "2026-04-25T00:00:00Z", endsAt: "2026-05-20T23:59:59Z", teamId: "' + $setup.teamId + '" }) { success cycle { id name } } }'
    $cycleR2 = Call-Linear $cycleM
    if ($cycleR2.ok -and $cycleR2.data.cycleCreate.success) {
        $cycle = $cycleR2.data.cycleCreate.cycle
        Write-Host "Created cycle: $($cycle.name)" -ForegroundColor Green
    } else {
        Write-Error "Cycle creation failed: $($cycleR2.err)"
        exit 1
    }
}

# Save Sprint 2 setup data
$sprint2Data = @{
    projectId = $setup.projectId
    projectName = $setup.projectName
    cycleId = $cycle.id
    cycleName = $cycle.name
    teamId = $setup.teamId
}
$sprint2Data | ConvertTo-Json | Set-Content "D:\Facturacion en linea\scripts\sprint2_setup.json"

Write-Host "`n=== Sprint 2 Setup Complete ===" -ForegroundColor Green
Write-Host "Project: $($setup.projectName)" -ForegroundColor White
Write-Host "Cycle: $($cycle.name)" -ForegroundColor White
Write-Host "Setup saved to sprint2_setup.json" -ForegroundColor Gray
Write-Host "`nNext: Run 09_hu005_xml_factura_detailed.ps1" -ForegroundColor Cyan
