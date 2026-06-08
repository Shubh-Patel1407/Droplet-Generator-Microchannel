#!/bin/bash
# FSI Coupling Master Script
# Orchestrates the sequential fluid-solid interaction simulation
#
# Usage:
#   ./run_fsi_coupling.sh [--fluid-only] [--solid-only] [--python-only] [--nprocs N]
#
# This script:
# 1. Runs the fluid solver (incompressibleVoF)
# 2. Extracts pressure from fluid domain
# 3. Updates solid case pressure boundary condition
# 4. Runs the solid solver (solidDisplacement)
# 5. Can optionally run Python reduced-order FSI model for validation

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Default options
FLUID_ONLY=0
SOLID_ONLY=0
PYTHON_ONLY=0
NPROCS=1

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --fluid-only)
            FLUID_ONLY=1
            shift
            ;;
        --solid-only)
            SOLID_ONLY=1
            shift
            ;;
        --python-only)
            PYTHON_ONLY=1
            shift
            ;;
        --nprocs)
            NPROCS=$2
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "=========================================="
echo "FSI COUPLING MASTER SCRIPT"
echo "=========================================="
echo "Script directory: $SCRIPT_DIR"
echo "Number of processors: $NPROCS"
echo

# Run Python FSI simulation if requested
if [ $PYTHON_ONLY -eq 1 ]; then
    echo "Running Python reduced-order FSI model..."
    python3 droplet_pipe_fsi_sim.py \
        --enable-fsi \
        --fsi-pressure 1500.0 \
        --youngs-modulus 2.5e6 \
        --wall-thickness 0.0004 \
        --output-dir output_fsi
    echo "Python FSI simulation completed!"
    exit 0
fi

# Run fluid solver
if [ $SOLID_ONLY -eq 0 ]; then
    echo "=========================================="
    echo "STEP 1: Running Fluid Solver"
    echo "=========================================="
    
    cd "$SCRIPT_DIR/fluidCase"
    
    # Clean old runs
    rm -f log.blockMesh log.setFields log.foamRun
    
    # Generate mesh, initialize fields, run solver
    echo "Running blockMesh..."
    blockMesh > /dev/null 2>&1 || { echo "blockMesh failed!"; exit 1; }
    
    rm -rf 0/polyMesh
    cp -r constant/polyMesh 0/
    
    echo "Initializing fields with setFields..."
    setFields > /dev/null 2>&1 || { echo "setFields failed!"; exit 1; }
    
    echo "Running incompressibleVoF solver..."
    if [ $NPROCS -gt 1 ]; then
        mpirun -np $NPROCS foamRun -solver incompressibleVoF -parallel
    else
        foamRun -solver incompressibleVoF
    fi
    
    echo "Fluid solver completed successfully!"
    cd "$SCRIPT_DIR"
fi

# Run FSI coupling Python script
if [ $FLUID_ONLY -eq 0 ]; then
    echo
    echo "=========================================="
    echo "STEP 2: FSI Coupling (Pressure Transfer)"
    echo "=========================================="
    
    python3 fsi_coupling.py \
        --fluid-case fluidCase \
        --solid-case solidCase \
        --nprocs $NPROCS \
        --coupling-interval 0.01
fi

# Run Python FSI validation
if [ $FLUID_ONLY -eq 0 ] && [ $PYTHON_ONLY -eq 0 ]; then
    echo
    echo "=========================================="
    echo "STEP 3: Python FSI Validation"
    echo "=========================================="
    
    python3 droplet_pipe_fsi_sim.py \
        --enable-fsi \
        --fsi-pressure 1500.0 \
        --youngs-modulus 2.5e6 \
        --output-dir output_fsi_validation
    
    echo "Python FSI validation completed!"
fi

echo
echo "=========================================="
echo "FSI COUPLING COMPLETED"
echo "=========================================="
echo "Results:"
echo "  Fluid output: fluidCase/[0, 0.01, 0.02, ...]/"
echo "  Solid output: solidCase/[0, 0.01, 0.02, ...]/"
echo "  Python FSI: output_fsi_validation/"
echo
