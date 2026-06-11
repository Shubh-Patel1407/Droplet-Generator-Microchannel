# FSI Simulation Troubleshooting Guide

## Issue: Fluid Solver Failed

You received this error:
```
✗ Fluid solver failed (check log.foamRun)
⚠ setFields had issues (check fluidCase/setFields.log)
```

---

## STEP 1: RUN DIAGNOSTICS

First, let's identify the exact problem:

```bash
cd ~/Droplet-Generator-Microchannel
chmod +x diagnose_fsi.sh
./diagnose_fsi.sh
```

This will check:
- OpenFOAM installation
- MPI availability
- Required files
- Python installation
- Any error logs

---

## STEP 2: COMMON FIXES

### **Issue A: OpenFOAM Not Found**

**Error message looks like:**
```
foamRun: command not found
```

**Fix:**
```bash
# Source OpenFOAM environment (path may vary)
source /opt/openfoam13/etc/bashrc
# OR
source ~/OpenFOAM/OpenFOAM-13/etc/bashrc
# OR check your installation location
find ~ -name "bashrc" 2>/dev/null | grep openfoam
```

After sourcing, verify:
```bash
which foamRun
foamRun --version
```

---

### **Issue B: MPI Not Installed**

**Error message looks like:**
```
mpirun: command not found
```

**Option 1: Run with single core (no MPI needed)**
```bash
./run_full_fsi.sh --nprocs 1
```

**Option 2: Install OpenMPI**
```bash
# Ubuntu/Debian
sudo apt-get install libopenmpi-dev openmpi-bin

# CentOS/RHEL
sudo yum install openmpi-devel

# macOS
brew install open-mpi
```

---

### **Issue C: Mesh Files Missing**

**Error message looks like:**
```
Cannot find file "points" in directory "polyMesh"
```

**Fix:**
```bash
cd ~/Droplet-Generator-Microchannel
cd fluidCase

# Remove old 0/ if corrupted
rm -rf 0/

# Create 0/ and copy mesh
mkdir 0/
cp -r constant/polyMesh 0/

# Verify
ls -la 0/polyMesh/

cd ..
```

---

### **Issue D: setFields Failed**

**Error message in setFields.log looks like:**
```
Cannot read fieldValues
```

**Fix:**
```bash
cd ~/Droplet-Generator-Microchannel/fluidCase

# Check setFieldsDict
cat system/setFieldsDict

# Re-run setFields with output
setFields 2>&1 | tee setFields.log

# Check result
cat setFields.log | tail -20
```

---

## STEP 3: VERIFY SETUP

Before running full simulation, check:

```bash
cd ~/Droplet-Generator-Microchannel

# Check OpenFOAM environment
echo $WM_PROJECT
# Should print: OpenFOAM

# Test blockMesh
cd fluidCase
blockMesh 2>&1 | tail -5
# Should show mesh summary

# Test setFields
setFields 2>&1 | tail -5
# Should complete without errors

cd ..
```

---

## STEP 4: QUICK TEST (No OpenFOAM Required)

If OpenFOAM is still problematic, test the Python model first:

```bash
# This doesn't require OpenFOAM or MPI
python3 droplet_pipe_fsi_sim.py --enable-fsi --output-dir test_output

# Check output
ls -lh test_output/
```

This verifies the FSI physics implementation.

---

## STEP 5: RUN WITH SINGLE CORE FIRST

Once setup is verified, start with 1 core:

```bash
./run_full_fsi.sh --nprocs 1
```

Monitor progress:
```bash
# In another terminal
tail -f fluidCase/log.foamRun
```

Expected time: ~70 minutes on 1 CPU

---

## STEP 6: SCALE TO MULTIPLE CORES

Once it works with 1 core, try with more:

```bash
./run_full_fsi.sh --nprocs 7
```

---

## ADVANCED DEBUGGING

### View detailed solver output:

```bash
cd fluidCase

# Run solver manually to see real-time output
foamRun -solver incompressibleVoF

# For parallel (after decomposition):
decomposePar -force
mpirun -np 7 foamRun -solver incompressibleVoF -parallel
reconstructPar
```

### Check mesh quality:

```bash
cd fluidCase
checkMesh
# Should show mesh statistics
```

### Examine control parameters:

```bash
# Check time stepping settings
cat system/controlDict | grep -A5 "writeControl"

# Check solver settings
cat system/fvSolution | grep -A10 "p_rgh"
```

---

## COMPLETE WORKFLOW (Step-by-Step)

If starting fresh and wanting to be 100% sure each step works:

```bash
cd ~/Droplet-Generator-Microchannel

# Step 1: Source OpenFOAM
source /opt/openfoam13/etc/bashrc

# Step 2: Generate meshes manually
echo "Generating fluid mesh..."
cd fluidCase
blockMesh
cp -r constant/polyMesh 0/polyMesh
cd ..

echo "Generating solid mesh..."
cd solidCase
blockMesh
cp -r constant/polyMesh 0/polyMesh
cd ..

# Step 3: Initialize droplet field
echo "Initializing droplet..."
cd fluidCase
setFields
cd ..

# Step 4: Run fluid solver (1 core, to verify)
echo "Running fluid solver (1 core)..."
cd fluidCase
foamRun -solver incompressibleVoF > log.foamRun 2>&1
cd ..

# Check if it succeeded
if [ -d "fluidCase/0.001" ]; then
    echo "✓ Fluid solver succeeded"
    
    # Step 5: Run FSI coupling
    echo "Running FSI coupling..."
    python3 fsi_coupling.py --fluid-case fluidCase --solid-case solidCase
    
    # Step 6: Validation
    echo "Running validation..."
    python3 fsi_validation.py --fluid-case fluidCase --solid-case solidCase
    
    echo "✓ Complete FSI workflow succeeded!"
else
    echo "✗ Fluid solver failed - check fluidCase/log.foamRun"
    tail -50 fluidCase/log.foamRun
fi
```

---

## IF STILL STUCK

Create a detailed report:

```bash
# Save diagnostic info
./diagnose_fsi.sh > diagnostic_report.txt 2>&1
tail -100 fluidCase/log.foamRun > fluid_error.txt 2>&1
tail -100 fluidCase/setFields.log > setfields_error.txt 2>&1

# Show what's going on
cat diagnostic_report.txt
cat fluid_error.txt
cat setfields_error.txt
```

Then refer to the specific error messages to the documentation.

---

## MINIMAL WORKING EXAMPLE

If you just want to verify FSI works without full OpenFOAM:

```bash
# Python model only (no OpenFOAM needed)
python3 droplet_pipe_fsi_sim.py --enable-fsi --output-dir minimal_test

# This should complete in 30 seconds
# Check output:
ls -lh minimal_test/
```

This proves the FSI implementation works.

---

## EXPECTED BEHAVIOR

**With 7 cores:**
- Mesh generation: 2 minutes
- Fluid solver: 8-10 minutes
- FSI coupling: 4 minutes
- Validation: 2 minutes
- **Total: ~16-18 minutes**

**Progress indicators:**
- Should see "Using 7 processors (MPI)"
- In another terminal: `top` or `htop` should show all 7 cores active
- `tail -f fluidCase/log.foamRun` should show solver progress

---

## SUCCESS INDICATORS

After completion, you should see:

```
✓ Fluid solver completed
✓ FSI coupling completed
✓ Validation analysis completed

Output directory: output_validation/
Generated plots:
  - 01_simulation_summary.png
  - 02_deformation_analysis.png
  - 03_coupling_strategy.png
  - 04_results_checklist.png
```

And in the fluidCase directory:
```
0.001/, 0.002/, ..., 0.120/
```
(Time directories with simulation results)

---

## STILL HAVE ISSUES?

**Try minimal test first:**
```bash
python3 droplet_pipe_fsi_sim.py --enable-fsi
```

If this works, FSI is fine - the issue is with OpenFOAM setup.

If this fails, check Python installation:
```bash
python3 --version
python3 -c "import numpy; import matplotlib; print('✓ Dependencies OK')"
```

---
