# FSI Coupling Master Script (PowerShell)
# Orchestrates the sequential fluid-solid interaction simulation
#
# Usage:
#   .\run_fsi_coupling.ps1 [-FluidOnly] [-SolidOnly] [-PythonOnly] [-NProcs N]

param(
    [switch]$FluidOnly,
    [switch]$SolidOnly,
    [switch]$PythonOnly,
    [int]$NProcs = 1
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "FSI COUPLING MASTER SCRIPT (PowerShell)" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Script directory: $ScriptDir" -ForegroundColor Yellow
Write-Host "Number of processors: $NProcs" -ForegroundColor Yellow
Write-Host ""

# Run Python FSI simulation if requested
if ($PythonOnly) {
    Write-Host "Running Python reduced-order FSI model..." -ForegroundColor Green
    & python3 droplet_pipe_fsi_sim.py `
        --enable-fsi `
        --fsi-pressure 1500.0 `
        --youngs-modulus 2.5e6 `
        --wall-thickness 0.0004 `
        --output-dir output_fsi
    Write-Host "Python FSI simulation completed!" -ForegroundColor Green
    exit 0
}

# Run fluid solver
if (-not $SolidOnly) {
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "STEP 1: Running Fluid Solver" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    
    Set-Location "$ScriptDir\fluidCase"
    
    # Clean old runs
    Remove-Item -LiteralPath "log.blockMesh", "log.setFields", "log.foamRun" -Force -ErrorAction SilentlyContinue
    
    # Generate mesh
    Write-Host "Running blockMesh..." -ForegroundColor Yellow
    & blockMesh 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: blockMesh failed!" -ForegroundColor Red
        exit 1
    }
    
    # Copy mesh to 0/
    Remove-Item -LiteralPath "0/polyMesh" -Recurse -Force -ErrorAction SilentlyContinue
    Copy-Item -LiteralPath "constant/polyMesh" -Destination "0/polyMesh" -Recurse
    
    # Initialize fields
    Write-Host "Initializing fields with setFields..." -ForegroundColor Yellow
    & setFields 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: setFields failed!" -ForegroundColor Red
        exit 1
    }
    
    # Run solver
    Write-Host "Running incompressibleVoF solver..." -ForegroundColor Yellow
    if ($NProcs -gt 1) {
        & mpirun -np $NProcs foamRun -solver incompressibleVoF -parallel
    } else {
        & foamRun -solver incompressibleVoF
    }
    
    Write-Host "Fluid solver completed successfully!" -ForegroundColor Green
    Set-Location $ScriptDir
}

# Run FSI coupling Python script
if (-not $FluidOnly) {
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "STEP 2: FSI Coupling (Pressure Transfer)" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    
    & python3 fsi_coupling.py `
        --fluid-case fluidCase `
        --solid-case solidCase `
        --nprocs $NProcs `
        --coupling-interval 0.01
}

# Run Python FSI validation
if (-not $FluidOnly -and -not $PythonOnly) {
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "STEP 3: Python FSI Validation" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    
    & python3 droplet_pipe_fsi_sim.py `
        --enable-fsi `
        --fsi-pressure 1500.0 `
        --youngs-modulus 2.5e6 `
        --output-dir output_fsi_validation
    
    Write-Host "Python FSI validation completed!" -ForegroundColor Green
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "FSI COUPLING COMPLETED" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Results:" -ForegroundColor Yellow
Write-Host "  Fluid output: fluidCase/[0, 0.01, 0.02, ...]/" -ForegroundColor Yellow
Write-Host "  Solid output: solidCase/[0, 0.01, 0.02, ...]/" -ForegroundColor Yellow
Write-Host "  Python FSI: output_fsi_validation/" -ForegroundColor Yellow
Write-Host ""
