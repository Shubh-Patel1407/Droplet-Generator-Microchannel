#!/bin/bash
#
# FSI SIMULATION DIAGNOSTIC SCRIPT
# ================================
#
# Run this to diagnose issues with FSI simulation
#
# Usage: ./diagnose_fsi.sh
#

echo "=========================================================================="
echo "FSI SIMULATION DIAGNOSTICS"
echo "=========================================================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to check if command exists
check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 found"
        echo "  Location: $(which $1)"
        return 0
    else
        echo -e "${RED}✗${NC} $1 NOT FOUND"
        return 1
    fi
}

# Function to print section
print_section() {
    echo ""
    echo "=========================================================================="
    echo "$1"
    echo "=========================================================================="
}

# 1. Check system
print_section "SYSTEM INFORMATION"
echo "Hostname: $(hostname)"
echo "OS: $(uname -s)"
echo "CPUs: $(nproc || echo 'unknown')"
echo "Memory: $(free -h | head -2)"
echo "Disk space: $(df -h . | tail -1)"

# 2. Check OpenFOAM
print_section "OPENFOAM INSTALLATION"
check_command foamRun
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}⚠ OpenFOAM not in PATH${NC}"
    echo "Try sourcing OpenFOAM bashrc:"
    echo "  source /opt/openfoam13/etc/bashrc"
fi

check_command foamToVTK
check_command blockMesh
check_command setFields

# 3. Check MPI
print_section "MPI INSTALLATION"
check_command mpirun
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}⚠ MPI not found - needed for parallel execution${NC}"
fi

# 4. Check Python
print_section "PYTHON INSTALLATION"
check_command python3
python3 --version

# 5. Check project files
print_section "PROJECT FILES"
for file in droplet_pipe_sim.py droplet_pipe_fsi_sim.py fsi_coupling.py fsi_validation.py; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $file"
    else
        echo -e "${RED}✗${NC} $file MISSING"
    fi
done

# 6. Check fluid case
print_section "FLUID CASE CHECK"
echo "Checking fluidCase directory..."
if [ -d "fluidCase/system" ]; then
    echo -e "${GREEN}✓${NC} fluidCase/system exists"
    
    if [ -f "fluidCase/system/blockMeshDict" ]; then
        echo -e "${GREEN}✓${NC} blockMeshDict found"
    else
        echo -e "${RED}✗${NC} blockMeshDict missing"
    fi
    
    if [ -f "fluidCase/system/controlDict" ]; then
        echo -e "${GREEN}✓${NC} controlDict found"
    else
        echo -e "${RED}✗${NC} controlDict missing"
    fi
else
    echo -e "${RED}✗${NC} fluidCase/system missing"
fi

if [ -d "fluidCase/0" ]; then
    echo -e "${GREEN}✓${NC} fluidCase/0 exists"
    if [ -d "fluidCase/0/polyMesh" ]; then
        echo -e "${GREEN}✓${NC} Mesh copied to 0/polyMesh"
    else
        echo -e "${YELLOW}⚠${NC} Mesh NOT in 0/polyMesh (will be copied during setup)"
    fi
else
    echo -e "${RED}✗${NC} fluidCase/0 missing"
fi

# 7. Check solid case
print_section "SOLID CASE CHECK"
echo "Checking solidCase directory..."
if [ -d "solidCase/system" ]; then
    echo -e "${GREEN}✓${NC} solidCase/system exists"
else
    echo -e "${RED}✗${NC} solidCase/system missing"
fi

# 8. Check logs if they exist
print_section "ERROR LOGS (if present)"
if [ -f "fluidCase/log.foamRun" ]; then
    echo -e "${YELLOW}Fluid solver log found - showing last 50 lines:${NC}"
    tail -50 fluidCase/log.foamRun
else
    echo "No fluid solver log yet (simulation hasn't run)"
fi

if [ -f "fluidCase/setFields.log" ]; then
    echo -e "${YELLOW}setFields log found - showing last 30 lines:${NC}"
    tail -30 fluidCase/setFields.log
else
    echo "No setFields log yet"
fi

# 9. Recommendations
print_section "RECOMMENDATIONS"
echo ""

if ! command -v foamRun &> /dev/null; then
    echo -e "${RED}CRITICAL: OpenFOAM not found${NC}"
    echo "Action: Install OpenFOAM 13 or source it:"
    echo "  source /opt/openfoam13/etc/bashrc"
    echo ""
fi

if ! command -v mpirun &> /dev/null; then
    echo -e "${YELLOW}WARNING: MPI not found${NC}"
    echo "Action: Run with single core instead:"
    echo "  ./run_full_fsi.sh --nprocs 1"
    echo ""
fi

if [ ! -f "droplet_pipe_fsi_sim.py" ]; then
    echo -e "${RED}CRITICAL: Python FSI model missing${NC}"
    echo "Action: Check project files"
    echo ""
fi

echo "=========================================================================="
echo "DIAGNOSIS COMPLETE"
echo "=========================================================================="
echo ""
echo "Next steps:"
echo "  1. Fix any CRITICAL issues above"
echo "  2. For quick test (no OpenFOAM needed):"
echo "     python3 droplet_pipe_fsi_sim.py --enable-fsi"
echo "  3. For full FSI (requires OpenFOAM):"
echo "     ./run_full_fsi.sh --nprocs 1  (start with 1 core)"
echo ""
