#!/bin/bash
# Fix mesh regeneration issue in WSL

cd "$(dirname "$0")"

echo "=========================================="
echo "MESH REGENERATION FIX"
echo "=========================================="

# Remove old mesh to force regeneration
echo "Removing stale mesh..."
rm -rf fluidCase/constant/polyMesh
rm -rf solidCase/constant/polyMesh

# Remove mesh copies from 0/
echo "Removing mesh copies from 0/ directories..."
rm -rf fluidCase/0/polyMesh
rm -rf solidCase/0/polyMesh

# Regenerate fluid mesh
echo "Regenerating fluid mesh with blockMesh..."
cd fluidCase
blockMesh 2>&1 | tee blockMesh.log
if [ $? -eq 0 ]; then
    echo "✓ Fluid blockMesh successful"
else
    echo "✗ Fluid blockMesh failed"
    exit 1
fi

# Copy mesh to 0/
cp -r constant/polyMesh 0/
echo "✓ Fluid mesh copied to 0/"

cd ..

# Regenerate solid mesh
echo "Regenerating solid mesh with blockMesh..."
cd solidCase
blockMesh 2>&1 | tee blockMesh.log
if [ $? -eq 0 ]; then
    echo "✓ Solid blockMesh successful"
else
    echo "✗ Solid blockMesh failed"
    exit 1
fi

# Copy mesh to 0/
cp -r constant/polyMesh 0/
echo "✓ Solid mesh copied to 0/"

cd ..

# Check mesh quality
echo ""
echo "Checking fluid mesh quality..."
cd fluidCase
checkMesh 2>&1 | head -20
MESH_INFO=$(checkMesh 2>&1 | grep -i "cells")
echo "Mesh info: $MESH_INFO"
cd ..

echo ""
echo "=========================================="
echo "MESH REGENERATION COMPLETE"
echo "=========================================="
echo "Next steps:"
echo "  cd fluidCase"
echo "  setFields"
echo "  cd .."
echo "  ./run_full_fsi.sh --nprocs 4"
