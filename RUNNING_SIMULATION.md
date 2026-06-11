# How to Run the FSI Simulation - Complete Guide

## Table of Contents
1. [Quick Start](#quick-start)
2. [Python Model Test](#python-model-test)
3. [Full OpenFOAM Simulation](#full-openfoam-simulation)
4. [Monitoring Execution](#monitoring-execution)
5. [Using All Cores](#using-all-cores)
6. [Troubleshooting](#troubleshooting)

---

## QUICK START

### The Simplest Way to Start

**Option 1: Use the guided menu (Recommended)**
```bash
cd ~/Droplet-Generator-Microchannel
chmod +x QUICK_START_LINUX.sh
./QUICK_START_LINUX.sh
```

This presents an interactive menu with all options.

**Option 2: One-line Python test (No OpenFOAM required)**
```bash
cd ~/Droplet-Generator-Microchannel
python3 droplet_pipe_fsi_sim.py --enable-fsi --output-dir output_test
```

Expected time: **30 seconds**

---

## PYTHON MODEL TEST

### What It Does
- Simulates droplets in flexible microchannel (reduced-order model)
- Computes deformation due to internal pressure
- Generates visualization plots
- **Does NOT require OpenFOAM or MPI**

### Command
```bash
python3 droplet_pipe_fsi_sim.py --enable-fsi --output-dir output_test
```

### Options
```bash
# With custom Young's modulus (silicone rubber)
python3 droplet_pipe_fsi_sim.py --enable-fsi \
  --youngs-modulus 2.5e6 \
  --wall-thickness 0.0004 \
  --output-dir my_output

# Compare rigid vs. flexible
python3 droplet_pipe_fsi_sim.py --enable-fsi --output-dir fsi_case
python3 droplet_pipe_fsi_sim.py --disable-fsi --output-dir rigid_case

# Longer simulation (3 seconds as originally configured)
python3 droplet_pipe_sim.py --total-time 3.0 --pulse-period 0.15 --cfl 0.5
```

### Output Files
```
output_test/
  ├── droplet_snapshot.png      # Final droplet distribution
  ├── droplet_history.png        # Space-time evolution
  ├── droplet_animation.gif      # Time animation
  └── stress_evolution.png       # Wall stress vs time
```

### Success Indicators
- Should complete in 30 seconds
- Should see "Running simulation... 100%" progress
- Should create PNG and GIF files in output directory

---

## FULL OPENFOAM SIMULATION

### Prerequisites

1. **OpenFOAM 13 installed**
   ```bash
   # Check if installed
   which foamRun
   
   # If not found, install or locate installation path
   find ~ -name "bashrc" 2>/dev/null | grep openfoam
   ```

2. **OpenFOAM environment sourced**
   ```bash
   # Add to ~/.bashrc for permanent effect
   source /opt/openfoam13/etc/bashrc
   
   # Or source it in current terminal
   source /opt/openfoam13/etc/bashrc
   
   # Verify
   foamRun --version
   ```

3. **MPI installed (for parallel execution)**
   ```bash
   # Check
   which mpirun
   
   # If missing:
   # Ubuntu/Debian: sudo apt-get install libopenmpi-dev openmpi-bin
   # CentOS/RHEL: sudo yum install openmpi-devel
   # macOS: brew install open-mpi
   ```

### Run with 1 Core (Test)

```bash
cd ~/Droplet-Generator-Microchannel

# Make script executable
chmod +x run_full_fsi.sh

# Run with 1 core (verify it works)
./run_full_fsi.sh --nprocs 1
```

**Time:** ~70 minutes on 1 CPU

**What it does:**
1. Generates fluid and solid meshes
2. Initializes droplet field
3. Runs incompressibleVoF fluid solver
4. Extracts pressure and runs solidDisplacement
5. Generates validation plots

---

## USING ALL CORES

### Find Number of Available Cores

```bash
# Linux/Mac
nproc
# Or
lscpu | grep "^CPU(s):"
```

### Run with All Cores

```bash
# Auto-detect all cores (7 in your case, or whatever you have)
NCORES=$(nproc)
./run_full_fsi.sh --nprocs $NCORES

# Or manually specify
./run_full_fsi.sh --nprocs 7
```

### Expected Speedup

| Cores | Time | Speedup |
|-------|------|---------|
| 1     | 70 min | 1×    |
| 4     | 20 min | 3.5×  |
| 7     | 12 min | 5.8×  |
| 8     | 11 min | 6.4×  |

---

## MONITORING EXECUTION

### Monitor Progress in Real-Time

**Terminal 1: Run the simulation**
```bash
./run_full_fsi.sh --nprocs 7
```

**Terminal 2: Watch the fluid solver log**
```bash
tail -f fluidCase/log.foamRun
```

You should see lines like:
```
Time = 0.0001s
Courant Number max = 0.29
Continuity errors : sum local = ..., global = ...
```

### Monitor CPU Usage

**Terminal 3: Check CPU utilization**
```bash
# Linux
top
# Or better
htop

# macOS
Activity Monitor
```

You should see:
- **7 foamRun processes** (one per core)
- **~700% CPU usage** (100% × 7 cores)
- **Memory ~400-600 MB**

### Check Disk Usage

```bash
# See how much data is being generated
du -sh fluidCase/ solidCase/
```

Result directories grow over time.

---

## TROUBLESHOOTING

### Issue: "foamRun: command not found"

**Cause:** OpenFOAM not in PATH

**Fix:**
```bash
# Source OpenFOAM bashrc
source /opt/openfoam13/etc/bashrc

# Verify
foamRun --version

# Then run simulation
./run_full_fsi.sh --nprocs 7
```

### Issue: "mpirun: command not found"

**Cause:** MPI not installed

**Option A: Install MPI**
```bash
# Ubuntu/Debian
sudo apt-get install libopenmpi-dev openmpi-bin

# CentOS/RHEL
sudo yum install openmpi-devel

# macOS
brew install open-mpi
```

**Option B: Run with 1 core (no MPI needed)**
```bash
./run_full_fsi.sh --nprocs 1
```

### Issue: "Mesh not found" or similar

**Cause:** Mesh generation failed

**Fix:**
```bash
cd fluidCase
blockMesh
cp -r constant/polyMesh 0/polyMesh
cd ..

cd solidCase
blockMesh
cp -r constant/polyMesh 0/polyMesh
cd ..

# Then retry
./run_full_fsi.sh --nprocs 7
```

### Issue: "setFields had issues"

**Cause:** Droplet initialization failed

**Fix:**
```bash
cd fluidCase

# Check setFieldsDict
cat system/setFieldsDict

# Try manually
setFields 2>&1 | tee setFields.log
tail -20 setFields.log

# If it works, continue with simulation
cd ..
```

### Issue: Fluid solver diverges (NaN in output)

**Cause:** Unstable time stepping

**Fix:**
```bash
# Reduce CFL number (makes timesteps smaller)
# Edit fluidCase/system/controlDict:
# - Change maxCo from 0.4 to 0.2
# - Change maxAlphaCo from 0.25 to 0.1

# Then run again
./run_full_fsi.sh --nprocs 7
```

---

## INTERPRETING RESULTS

### Output Directories

```
fluidCase/
  ├── 0/              # Initial conditions
  ├── 0.001/, 0.002/, ... # Results at each time step
  │   ├── U           # Velocity field
  │   ├── p_rgh       # Pressure field
  │   └── alpha.water # Droplet location
  └── log.foamRun     # Solver log

solidCase/
  ├── 0/              # Initial conditions
  ├── 0.001/, 0.002/, ... # Deformation at each time
  │   └── D           # Displacement field
  └── log.foamRun     # Solver log

output_validation/
  ├── 01_simulation_summary.png
  ├── 02_deformation_analysis.png
  ├── 03_coupling_strategy.png
  └── 04_results_checklist.png
```

### Success Indicators

After completion, you should see:
```
✓ Fluid solver completed
✓ FSI coupling completed
✓ Validation analysis completed
```

And directories should exist:
```bash
ls fluidCase/0.001   # Fluid results at 0.001 seconds
ls solidCase/0.001   # Solid deformation at 0.001 seconds
ls output_validation/*.png  # Validation plots
```

---

## NEXT STEPS AFTER SIMULATION

### 1. Visualize in ParaView

```bash
cd fluidCase
foamToVTK
paraview
# Load VTK/ directory in ParaView
```

### 2. Extract and Analyze Data

```bash
# Extract pressure at specific time
cd fluidCase/0.012
cat p_rgh | head -20

# Extract displacement
cd ../../solidCase/0.012
cat D | head -20
```

### 3. Generate Custom Plots

```bash
# Modify and run
python3 fsi_validation.py \
  --fluid-case fluidCase \
  --solid-case solidCase \
  --validation-output my_analysis
```

---

## COMPLETE WORKFLOW EXAMPLE

### Start Fresh, Run Everything

```bash
cd ~/Droplet-Generator-Microchannel

# Step 1: Setup OpenFOAM environment
source /opt/openfoam13/etc/bashrc

# Step 2: Run diagnostics
chmod +x diagnose_fsi.sh
./diagnose_fsi.sh
# Should show ✓ for foamRun, mpirun, blockMesh, setFields

# Step 3: Python test (quick verification)
python3 droplet_pipe_fsi_sim.py --enable-fsi --output-dir test
# Should complete in 30 seconds

# Step 4: Run full FSI with all cores
chmod +x run_full_fsi.sh
NCORES=$(nproc)
./run_full_fsi.sh --nprocs $NCORES

# Step 5: Monitor (in another terminal)
tail -f fluidCase/log.foamRun

# Step 6: Visualize (after completion)
cd fluidCase
foamToVTK
paraview
```

---

## COMMAND REFERENCE

| Task | Command |
|------|---------|
| Quick test | `python3 droplet_pipe_fsi_sim.py --enable-fsi` |
| Guided menu | `./QUICK_START_LINUX.sh` |
| Diagnostics | `./diagnose_fsi.sh` |
| Full FSI (1 core) | `./run_full_fsi.sh --nprocs 1` |
| Full FSI (all cores) | `./run_full_fsi.sh --nprocs $(nproc)` |
| Full FSI (7 cores) | `./run_full_fsi.sh --nprocs 7` |
| Iterative coupling | `./run_full_fsi.sh --nprocs 7 --iterative` |
| Validation only | `python3 fsi_validation.py` |
| Check OpenFOAM | `foamRun --version` |
| Check MPI | `mpirun --version` |
| Monitor progress | `tail -f fluidCase/log.foamRun` |

---

## SUMMARY

**To run the FSI simulation with all 7 cores:**

```bash
cd ~/Droplet-Generator-Microchannel
source /opt/openfoam13/etc/bashrc
./run_full_fsi.sh --nprocs 7
```

**Expected runtime:** ~12 minutes with 7 cores

**Verify cores are used:**
- Watch `top` or `htop` in another terminal
- Should see 7 foamRun processes with ~700% CPU total
- Each core should show ~100% utilization

---
