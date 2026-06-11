#
# PHASE 4: MASTER FSI ORCHESTRATION SCRIPT (Windows PowerShell)
# =============================================================
#
# Complete workflow for running full FSI simulation:
#   1. Generate meshes (fluid + solid)
#   2. Initialize droplet field
#   3. Run fluid solver
#   4. Run FSI coupling (one-way: pressure → deformation)
#   5. Validate with Python model
#
# Usage:
#   .\run_full_fsi.ps1 -NProcs 4
#
# Parameters:
#   -NProcs       : Number of CPU cores (default: 1)
#   -NoMesh       : Skip mesh generation
#   -NoFluid      : Skip fluid solver
#   -NoSolid      : Skip FSI coupling
#   -Iterative    : Use iterative coupling
#   -ValidateOnly : Run Python validation only
#

param(
    [int]$NProcs = 1,
    [switch]$NoMesh,
    [switch]$NoFluid,
    [switch]$NoSolid,
    [switch]$Iterative,
    [switch]$ValidateOnly
)

# Colors for output
$Green = "Green"
$Red = "Red"
$Yellow = "Yellow"
$Blue = "Cyan"

function Print-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "===================================================================" -ForegroundColor $Blue
    Write-Host $Title -ForegroundColor $Blue
    Write-Host "===================================================================" -ForegroundColor $Blue
}

function Print-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor $Green
}

function Print-Warning {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor $Yellow
}

function Print-Error {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor $Red
    exit 1
}

# Main workflow
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

Print-Section "FULL FSI COUPLING WORKFLOW (Windows)"
Write-Host "Working directory: $(Get-Location)"
Write-Host "Number of processors: $NProcs"
Write-Host ""

# =========================================================================
# STEP 1: MESH GENERATION
# =========================================================================
if (-not $NoMesh -and -not $ValidateOnly) {
    Print-Section "STEP 1: MESH GENERATION"
    
    # Fluid mesh
    Write-Host "Generating fluid mesh..."
    Push-Location fluidCase
    
    $output = & blockMesh 2>&1
    if ($LASTEXITCODE -eq 0) {
        Print-Success "Fluid blockMesh completed"
    } else {
        Print-Error "Fluid blockMesh failed"
    }
    
    # Copy mesh to 0/
    if (Test-Path "constant/polyMesh") {
        Copy-Item -Path "constant/polyMesh" -Destination "0/" -Recurse -Force
        Print-Success "Fluid mesh copied to 0/"
    }
    
    Pop-Location
    
    # Solid mesh
    Write-Host "Generating solid mesh..."
    Push-Location solidCase
    
    $output = & blockMesh 2>&1
    if ($LASTEXITCODE -eq 0) {
        Print-Success "Solid blockMesh completed"
    } else {
        Print-Error "Solid blockMesh failed"
    }
    
    if (Test-Path "constant/polyMesh") {
        Copy-Item -Path "constant/polyMesh" -Destination "0/" -Recurse -Force
        Print-Success "Solid mesh copied to 0/"
    }
    
    Pop-Location
} else {
    Print-Warning "Skipping mesh generation"
}

# =========================================================================
# STEP 2: INITIALIZE DROPLET FIELD
# =========================================================================
if (-not $NoFluid -and -not $ValidateOnly) {
    Print-Section "STEP 2: DROPLET FIELD INITIALIZATION"
    
    Push-Location fluidCase
    Write-Host "Initializing droplet field with setFields..."
    
    $output = & setFields 2>&1 | Out-File -FilePath "setFields.log"
    if ($LASTEXITCODE -eq 0) {
        Print-Success "setFields completed"
    } else {
        Print-Warning "setFields had issues (check fluidCase/setFields.log)"
    }
    
    Pop-Location
}

# =========================================================================
# STEP 3: RUN FLUID SOLVER
# =========================================================================
if (-not $NoFluid -and -not $ValidateOnly) {
    Print-Section "STEP 3: FLUID SOLVER (incompressibleVoF)"
    
    Push-Location fluidCase
    Write-Host "Running fluid solver..."
    Write-Host "  (Monitor progress: tail -f log.foamRun)"
    
    if ($NProcs -gt 1) {
        # Parallel
        Write-Host "  Using $NProcs processors (MPI)"
        
        $output = & decomposePar -force 2>&1 | Out-Null
        
        $mpiCmd = "mpirun -np $NProcs foamRun -solver incompressibleVoF -parallel"
        $output = & cmd /c $mpiCmd 2>&1 | Out-File -FilePath "log.foamRun"
        
        if ($LASTEXITCODE -eq 0) {
            Print-Success "Fluid solver completed (parallel)"
        } else {
            Print-Error "Fluid solver failed (check log.foamRun)"
        }
        
        $output = & reconstructPar -time 0: 2>&1 | Out-Null
    } else {
        # Serial
        Write-Host "  Using 1 processor (serial)"
        
        $output = & foamRun -solver incompressibleVoF 2>&1 | Out-File -FilePath "log.foamRun"
        
        if ($LASTEXITCODE -eq 0) {
            Print-Success "Fluid solver completed (serial)"
        } else {
            Print-Error "Fluid solver failed (check log.foamRun)"
        }
    }
    
    Pop-Location
}

# =========================================================================
# STEP 4: RUN FSI COUPLING
# =========================================================================
if (-not $NoSolid -and -not $ValidateOnly) {
    Print-Section "STEP 4: FSI COUPLING"
    
    Write-Host "Running FSI coupling (one-way: pressure → solid deformation)..."
    
    if ($Iterative) {
        Write-Host "  Mode: ITERATIVE (converge to residual < 0.5%)"
        $output = & python fsi_coupling.py `
            --fluid-case fluidCase `
            --solid-case solidCase `
            --iterative `
            --max-iterations 5 `
            --residual-threshold 0.005 `
            --nprocs $NProcs
    } else {
        Write-Host "  Mode: SINGLE ITERATION"
        $output = & python fsi_coupling.py `
            --fluid-case fluidCase `
            --solid-case solidCase `
            --nprocs $NProcs
    }
    
    if ($LASTEXITCODE -eq 0) {
        Print-Success "FSI coupling completed"
    } else {
        Print-Warning "FSI coupling had issues"
    }
}

# =========================================================================
# STEP 5: PYTHON VALIDATION & ANALYSIS
# =========================================================================
if (Test-Path "fsi_validation.py") {
    Print-Section "STEP 5: PYTHON VALIDATION & ANALYSIS"
    
    Write-Host "Running validation analysis..."
    
    $output = & python fsi_validation.py `
        --fluid-case fluidCase `
        --solid-case solidCase `
        --python-output output_fsi `
        --validation-output output_validation 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Print-Success "Validation analysis completed"
        Write-Host "  Outputs saved to output_validation/"
    } else {
        Print-Warning "Validation had issues (may not have OpenFOAM results yet)"
    }
} else {
    Print-Warning "fsi_validation.py not found (skipping validation)"
}

# =========================================================================
# STEP 6: SUMMARY
# =========================================================================
Print-Section "WORKFLOW SUMMARY"

Write-Host ""
Write-Host "Simulation outputs:"
Write-Host "  Fluid results: fluidCase/0.001/, 0.002/, ... (time directories)"
Write-Host "  Solid results: solidCase/0.001/, 0.002/, ... (time directories)"
Write-Host "  Python validation: output_validation/ (comparison plots)"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Check results in ParaView:"
Write-Host "       cd fluidCase && foamToVTK && paraview"
Write-Host ""
Write-Host "  2. Run Python model (fast reduced-order simulation):"
Write-Host "       python droplet_pipe_fsi_sim.py --enable-fsi --output-dir output_fsi"
Write-Host ""
Write-Host "  3. Compare rigid vs. flexible pipe:"
Write-Host "       python droplet_pipe_fsi_sim.py --disable-fsi --output-dir output_rigid"
Write-Host ""

Print-Success "FSI Workflow Complete!"
Write-Host ""
