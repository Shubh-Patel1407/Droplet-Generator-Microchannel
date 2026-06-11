#!/bin/bash
#
# PHASE 4: MASTER FSI ORCHESTRATION SCRIPT (Linux/Mac)
# =====================================================
#
# Complete workflow for running full FSI simulation:
#   1. Generate meshes (fluid + solid)
#   2. Initialize droplet field
#   3. Run fluid solver
#   4. Run FSI coupling (one-way: pressure → deformation)
#   5. Validate with Python model
#
# Usage:
#   chmod +x run_full_fsi.sh
#   ./run_full_fsi.sh --nprocs 4
#
# Options:
#   --nprocs N    : Number of CPU cores (default: 1)
#   --no-mesh     : Skip mesh generation
#   --no-fluid    : Skip fluid solver
#   --no-solid    : Skip FSI coupling
#   --iterative   : Use iterative coupling
#   --validate    : Run Python validation only
#

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NPROCS=1
SKIP_MESH=false
SKIP_FLUID=false
SKIP_SOLID=false
ITERATIVE=false
VALIDATE_ONLY=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --nprocs)
            NPROCS=$2
            shift 2
            ;;
        --no-mesh)
            SKIP_MESH=true
            shift
            ;;
        --no-fluid)
            SKIP_FLUID=true
            shift
            ;;
        --no-solid)
            SKIP_SOLID=true
            shift
            ;;
        --iterative)
            ITERATIVE=true
            shift
            ;;
        --validate)
            VALIDATE_ONLY=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper function
print_section() {
    echo ""
    echo -e "${BLUE}===================================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===================================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
    exit 1
}

# Main workflow
cd "$SCRIPT_DIR"

print_section "FULL FSI COUPLING WORKFLOW"
echo "Working directory: $(pwd)"
echo "Number of processors: $NPROCS"
echo ""

# =========================================================================
# STEP 1: MESH GENERATION
# =========================================================================
if [ "$SKIP_MESH" = false ] && [ "$VALIDATE_ONLY" = false ]; then
    print_section "STEP 1: MESH GENERATION"
    
    # Fluid mesh
    echo "Generating fluid mesh..."
    cd fluidCase
    blockMesh > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        print_success "Fluid blockMesh completed"
    else
        print_error "Fluid blockMesh failed"
    fi
    
    # Copy mesh to 0/ directory
    if [ -d "constant/polyMesh" ]; then
        cp -r constant/polyMesh 0/polyMesh
        print_success "Fluid mesh copied to 0/"
    fi
    
    cd ..
    
    # Solid mesh
    echo "Generating solid mesh..."
    cd solidCase
    blockMesh > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        print_success "Solid blockMesh completed"
    else
        print_error "Solid blockMesh failed"
    fi
    
    if [ -d "constant/polyMesh" ]; then
        cp -r constant/polyMesh 0/polyMesh
        print_success "Solid mesh copied to 0/"
    fi
    
    cd ..
else
    print_warning "Skipping mesh generation (--no-mesh)"
fi

# =========================================================================
# STEP 2: INITIALIZE DROPLET FIELD
# =========================================================================
if [ "$SKIP_FLUID" = false ] && [ "$VALIDATE_ONLY" = false ]; then
    print_section "STEP 2: DROPLET FIELD INITIALIZATION"
    
    cd fluidCase
    echo "Initializing droplet field with setFields..."
    
    if setFields > setFields.log 2>&1; then
        print_success "setFields completed"
    else
        print_warning "setFields had issues (check fluidCase/setFields.log)"
    fi
    
    cd ..
fi

# =========================================================================
# STEP 3: RUN FLUID SOLVER
# =========================================================================
if [ "$SKIP_FLUID" = false ] && [ "$VALIDATE_ONLY" = false ]; then
    print_section "STEP 3: FLUID SOLVER (incompressibleVoF)"
    
    cd fluidCase
    echo "Running fluid solver..."
    echo "  (Monitor progress: tail -f log.foamRun)"
    
    if [ $NPROCS -gt 1 ]; then
        # Parallel
        echo "  Using $NPROCS processors (MPI)"
        decomposePar -force > /dev/null 2>&1
        
        if mpirun -np $NPROCS foamRun -solver incompressibleVoF -parallel > log.foamRun 2>&1; then
            print_success "Fluid solver completed (parallel)"
        else
            print_error "Fluid solver failed (check log.foamRun)"
        fi
        
        reconstructPar -time 0: > /dev/null 2>&1
    else
        # Serial
        echo "  Using 1 processor (serial)"
        if foamRun -solver incompressibleVoF > log.foamRun 2>&1; then
            print_success "Fluid solver completed (serial)"
        else
            print_error "Fluid solver failed (check log.foamRun)"
        fi
    fi
    
    cd ..
fi

# =========================================================================
# STEP 4: RUN FSI COUPLING
# =========================================================================
if [ "$SKIP_SOLID" = false ] && [ "$VALIDATE_ONLY" = false ]; then
    print_section "STEP 4: FSI COUPLING"
    
    echo "Running FSI coupling (one-way: pressure → solid deformation)..."
    
    if [ "$ITERATIVE" = true ]; then
        echo "  Mode: ITERATIVE (converge to residual < 0.5%)"
        python3 fsi_coupling.py \
            --fluid-case fluidCase \
            --solid-case solidCase \
            --iterative \
            --max-iterations 5 \
            --residual-threshold 0.005 \
            --nprocs $NPROCS
    else
        echo "  Mode: SINGLE ITERATION"
        python3 fsi_coupling.py \
            --fluid-case fluidCase \
            --solid-case solidCase \
            --nprocs $NPROCS
    fi
    
    if [ $? -eq 0 ]; then
        print_success "FSI coupling completed"
    else
        print_warning "FSI coupling had issues (check output above)"
    fi
fi

# =========================================================================
# STEP 5: PYTHON VALIDATION & ANALYSIS
# =========================================================================
if [ -f "fsi_validation.py" ]; then
    print_section "STEP 5: PYTHON VALIDATION & ANALYSIS"
    
    echo "Running validation analysis..."
    
    if python3 fsi_validation.py \
        --fluid-case fluidCase \
        --solid-case solidCase \
        --python-output output_fsi \
        --validation-output output_validation > /dev/null 2>&1; then
        print_success "Validation analysis completed"
        echo "  Outputs saved to output_validation/"
    else
        print_warning "Validation had issues (may not have OpenFOAM results yet)"
    fi
else
    print_warning "fsi_validation.py not found (skipping validation)"
fi

# =========================================================================
# STEP 6: SUMMARY
# =========================================================================
print_section "WORKFLOW SUMMARY"

echo ""
echo "Simulation outputs:"
echo "  Fluid results: fluidCase/0.001/, 0.002/, ... (time directories)"
echo "  Solid results: solidCase/0.001/, 0.002/, ... (time directories)"
echo "  Python validation: output_validation/ (comparison plots)"
echo ""
echo "Next steps:"
echo "  1. Check results in ParaView:"
echo "       cd fluidCase && foamToVTK && paraview"
echo ""
echo "  2. Run Python model (fast reduced-order simulation):"
echo "       python3 droplet_pipe_fsi_sim.py --enable-fsi --output-dir output_fsi"
echo ""
echo "  3. Compare rigid vs. flexible pipe:"
echo "       python3 droplet_pipe_fsi_sim.py --disable-fsi --output-dir output_rigid"
echo ""

print_success "FSI Workflow Complete!"
echo ""
