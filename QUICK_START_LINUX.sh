#!/bin/bash
#
# QUICK START GUIDE FOR LINUX/MAC
# ===============================
#
# This script guides you through running the FSI simulation on Linux/Mac
#
# Usage: ./QUICK_START_LINUX.sh
#

echo ""
echo "================================================================================"
echo "FSI SIMULATION - QUICK START FOR LINUX/MAC"
echo "================================================================================"
echo ""

# Check if we're in the right directory
if [ ! -f "droplet_pipe_sim.py" ]; then
    echo "Error: Run this script from the Droplet-Generator-Microchannel directory"
    echo "cd ~/Droplet-Generator-Microchannel && ./QUICK_START_LINUX.sh"
    exit 1
fi

echo "Current directory: $(pwd)"
echo ""

# Menu
echo "What would you like to do?"
echo ""
echo "1. Run diagnostics (check if system is set up)"
echo "2. Run Python FSI model (fast, no OpenFOAM needed)"
echo "3. Run full OpenFOAM FSI with 1 core (verify setup)"
echo "4. Run full OpenFOAM FSI with all available cores"
echo "5. Show help & troubleshooting"
echo "6. Exit"
echo ""

read -p "Enter choice (1-6): " choice

case $choice in
    1)
        echo ""
        echo "Running diagnostics..."
        echo ""
        chmod +x diagnose_fsi.sh
        ./diagnose_fsi.sh
        ;;
    2)
        echo ""
        echo "Running Python FSI model..."
        echo "(This doesn't require OpenFOAM, takes ~30 seconds)"
        echo ""
        python3 droplet_pipe_fsi_sim.py --enable-fsi --output-dir output_test
        if [ $? -eq 0 ]; then
            echo ""
            echo "✓ Python FSI model succeeded!"
            echo "Check outputs: ls -lh output_test/"
        else
            echo ""
            echo "✗ Python model failed"
            echo "Check dependencies: python3 --version"
            echo "Install if needed: pip3 install numpy matplotlib"
        fi
        ;;
    3)
        echo ""
        echo "Running full FSI with 1 core..."
        echo "(This is a test to verify setup before scaling to 7 cores)"
        echo "Expected time: ~70 minutes"
        echo ""
        ./run_full_fsi.sh --nprocs 1
        if [ $? -eq 0 ]; then
            echo ""
            echo "✓ FSI with 1 core succeeded!"
            echo "Safe to try with more cores: ./run_full_fsi.sh --nprocs 7"
        fi
        ;;
    4)
        echo ""
        NCORES=$(nproc)
        echo "Running full FSI with ALL available cores ($NCORES cores)"
        echo "Expected time: ~$((70 / NCORES)) minutes"
        echo ""
        echo "To monitor progress in another terminal:"
        echo "  tail -f fluidCase/log.foamRun"
        echo ""
        ./run_full_fsi.sh --nprocs $NCORES
        if [ $? -eq 0 ]; then
            echo ""
            echo "✓ FSI simulation succeeded!"
            echo "Check outputs: ls fluidCase/0.*"
        fi
        ;;
    5)
        echo ""
        echo "Displaying help and troubleshooting..."
        echo ""
        if [ -f "TROUBLESHOOTING_FSI.md" ]; then
            less TROUBLESHOOTING_FSI.md
        else
            echo "TROUBLESHOOTING_FSI.md not found"
        fi
        ;;
    6)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "================================================================================"
echo ""
