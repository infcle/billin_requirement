# Sprint 1 Setup - Create Project and Cycle
# Usage: .\01_sprint1_setup.ps1 [-WhatIf]

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

$headers = @{
    Authorization = $apiKey
    ContentType = "application/json"
}

Write-Host "=== Sprint 1 Setup ===" -ForegroundColor Cyan

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

# Get Team
Write-Host "`nGetting team $TeamKey..." -ForegroundColor Cyan
$teamQ = 'query { teams(filter: { key: { eqIgnoreCase: "' + $TeamKey + '" } }) { nodes { id name } } }'
$teamR = Call-Linear $teamQ
if (-not $teamR.ok) { Write-Error "Failed to get team: $($teamR.err)"; exit 1 }
$teamId = $teamR.data.teams.nodes[0].id
Write-Host "Team: $($teamR.data.teams.nodes[0].name)" -ForegroundColor Green

# Create/Get Project
Write-Host "`nProject..." -ForegroundColor Cyan
$projName = "SFE - Sistema de Facturacion Electronica"
$projQ = 'query { projects(filter: { name: { eq: "' + $projName + '" } }) { nodes { id name } } }'
$projR = Call-Linear $projQ

$project = $null
if ($projR.ok -and $projR.data.projects.nodes.Count -gt 0) {
    $project = $projR.data.projects.nodes[0]
    Write-Host "Project exists: $($project.name)" -ForegroundColor Cyan
} elseif ($WhatIf) {
    Write-Host "[WHATIF] Would create project: $projName" -ForegroundColor Yellow
    $project = @{ id = "PROJ_WHATIF" }
} else {
    $desc = "Sistema de Facturacion Electronica - SIN Bolivia. Sprint 1: Fundamentos SIN"
    $projM = 'mutation { projectCreate(input: { name: "' + $projName + '", description: "' + $desc + '", teamIds: ["' + $teamId + '"], color: "#0EA5E9", state: started }) { success project { id name } } }'
    $projR2 = Call-Linear $projM
    if ($projR2.ok -and $projR2.data.projectCreate.success) {
        $project = $projR2.data.projectCreate.project
        Write-Host "Created project: $($project.name)" -ForegroundColor Green
    } else {
        Write-Error "Project creation failed: $($projR2.err)"
        exit 1
    }
}

# Create/Get Sprint 1 Cycle
Write-Host "`nSprint 1 Cycle..." -ForegroundColor Cyan
$cycleName = "Sprint 1: Fundamentos SIN"
$cycleQ = 'query { cycles(filter: { name: { eqIgnoreCase: "' + $cycleName + '" }, team: { id: { eq: "' + $teamId + '" } } }) { nodes { id name } } }'
$cycleR = Call-Linear $cycleQ

$cycle = $null
if ($cycleR.ok -and $cycleR.data.cycles.nodes.Count -gt 0) {
    $cycle = $cycleR.data.cycles.nodes[0]
    Write-Host "Cycle exists: $($cycle.name)" -ForegroundColor Cyan
} elseif ($WhatIf) {
    Write-Host "[WHATIF] Would create cycle: $cycleName" -ForegroundColor Yellow
    $cycle = @{ id = "CYC_WHATIF" }
} else {
    $cycleM = 'mutation { cycleCreate(input: { name: "' + $cycleName + '", startsAt: "2026-04-01T00:00:00Z", endsAt: "2026-04-24T23:59:59Z", teamId: "' + $teamId + '" }) { success cycle { id name } } }'
    $cycleR2 = Call-Linear $cycleM
    if ($cycleR2.ok -and $cycleR2.data.cycleCreate.success) {
        $cycle = $cycleR2.data.cycleCreate.cycle
        Write-Host "Created cycle: $($cycle.name)" -ForegroundColor Green
    } else {
        Write-Error "Cycle creation failed: $($cycleR2.err)"
        exit 1
    }
}

# Save IDs for next scripts
$setupData = @{
    projectId = $project.id
    projectName = $project.name
    cycleId = $cycle.id
    cycleName = $cycle.name
    teamId = $teamId
}
$setupData | ConvertTo-Json | Set-Content "D:\Facturacion en linea\scripts\sprint1_setup.json"

Write-Host "`n=== Sprint 1 Setup Complete ===" -ForegroundColor Green
Write-Host "Project: $($project.name)" -ForegroundColor White
Write-Host "Cycle: $($cycle.name)" -ForegroundColor White
Write-Host "Setup saved to sprint1_setup.json" -ForegroundColor Gray
Write-Host "`nNext: Run 02_hu001_token.ps1" -ForegroundColor Cyan
