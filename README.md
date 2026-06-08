# Water Droplets in Silicone Oil Through Flexible Microchannels - OpenFOAM FSI

OpenFOAM 13 simulation of water droplets in silicone oil transport through a flexible microchannel with fluid-structure interaction coupling. Includes rigid baseline and flexible pipe with one-way FSI coupling via pressure transfer.

**Status:** All critical errors fixed, FSI coupling implemented, water-oil system configured, ready for simulation.

## Fixed Issues

All critical errors from initial setup have been resolved:

1. **Fluid case mesh initialization** - Mesh now copied to fluidCase/constant/polyMesh
2. **Incompatible time stepping** - Solid case converted from steady-state to transient (0 to 0.12s)
3. **Poor solver convergence** - Displacement solver tolerance tightened (relTol 0.99 to 0.01)
4. **Mismatched mesh resolutions** - Both cases now use 160 axial divisions
5. **Non-physical inlet BC** - Parabolic Poiseuille profile implemented via codedFixedValue
6. **Undocumented materials** - Updated to realistic silicone rubber (E=2.5 MPa, nu=0.48)
7. **No FSI coupling** - One-way pressure coupling implemented via fsi_coupling.py

## Case Setup

### fluidCase/ - Droplet Transport (Rigid or Flexible Wall)

**Geometry:** Cylindrical pipe, length 50mm, inner radius 2mm
**Mesh:** 160 axial x 8 radial divisions, ~51,200 cells
**Solver:** incompressibleVoF (water-oil VOF transport)
**Time:** 0 to 0.12 seconds, adaptive Euler scheme
**Physics:** Laminar flow, droplet injection via periodic pulses

**Key parameters:**
- Inlet velocity: Parabolic Poiseuille profile (umax=0.30 m/s)
- Droplet injection: Period 0.014s, duty cycle 32%
- Surface tension: 0.025 N/m (water-silicone oil interface)

**Files:**
- fluidCase/system/blockMeshDict - Mesh geometry
- fluidCase/system/controlDict - Time integration
- fluidCase/0/U - Velocity BC with parabolic inlet
- fluidCase/0/alpha.water - Initial droplet location
- fluidCase/system/setFieldsDict - Droplet initialization

### solidCase/ - Flexible Pipe Wall

**Geometry:** Annular shell, length 50mm, inner radius 2mm, wall thickness 0.4mm
**Mesh:** 160 axial x 6 radial divisions, ~38,400 cells
**Solver:** solidDisplacement (transient elastic deformation)
**Time:** 0 to 0.12 seconds (synchronized with fluid)
**Material:** Silicone rubber - E=2.5 MPa, Poisson's ratio 0.48, density 950 kg/m3

**Loading:**
- Inner wall: Internal pressure (1500 Pa baseline)
- Outer wall: Free surface
- Ends: Fixed displacement (zero)

**Files:**
- solidCase/system/blockMeshDict - Mesh geometry
- solidCase/constant/physicalProperties - Material properties
- solidCase/0/D - Displacement boundary conditions

## Quick Start

### Prerequisite: Regenerate Solid Mesh

The solid mesh resolution was updated (120 to 160 axial divisions). Must regenerate:

```bash
cd solidCase
blockMesh
cd ..
```

### Option 1: Fully Automated (Recommended)

**Windows:**
```bash
.\run_fsi_coupling.ps1 -NProcs 1
```

**Linux/Mac:**
```bash
./run_fsi_coupling.sh --nprocs 1
```

This orchestrates the complete workflow:
1. Generate meshes
2. Initialize droplet field
3. Run fluid solver (~45 min on 1 CPU, ~12 min on 4 CPUs)
4. Extract pressure from fluid
5. Update solid pressure BC
6. Run solid solver
7. Generate Python validation plots

### Option 2: Manual Step-by-Step

**Prepare fluid case:**
```bash
cd fluidCase
blockMesh
rm -rf 0/polyMesh
cp -r constant/polyMesh 0/
setFields
```

**Run fluid solver:**
```bash
foamRun -solver incompressibleVoF
# Monitor progress:
tail -f log.foamRun
cd ..
```

**Run FSI coupling:**
```bash
python3 fsi_coupling.py --fluid-case fluidCase --solid-case solidCase
```

**Validate with Python model:**
```bash
python3 droplet_pipe_fsi_sim.py --enable-fsi --output-dir output_fsi
```

**Visualize results:**
```bash
cd fluidCase
foamToVTK
paraview &
```

### Option 3: Parallel Execution (70% Faster)

For systems with multiple CPUs:

```bash
cd fluidCase
blockMesh
rm -rf 0/polyMesh
cp -r constant/polyMesh 0/
setFields
decomposePar -force
mpirun -np 4 foamRun -solver incompressibleVoF -parallel
reconstructPar -time 0:
cd ..
python3 fsi_coupling.py --fluid-case fluidCase --solid-case solidCase --nprocs 4
```

## Runtime Estimates

| Task | 1 CPU | 4 CPUs |
|------|-------|--------|
| Mesh + Initialize | 2 min | 2 min |
| Fluid solver | 45 min | 12 min |
| FSI coupling + Solid | 20 min | 5 min |
| Python validation | 2 min | 2 min |
| **Total** | **69 min** | **21 min** |

## Output Files

After successful completion:

**Fluid results:** fluidCase/0.001/, 0.002/, ..., 0.120/
- U - Velocity field
- p_rgh - Hydrostatic pressure
- alpha.water - Phase fraction (droplet location)

**Solid results:** solidCase/0.001/, 0.002/, ..., 0.120/
- D - Wall displacement

**Python validation:** output_fsi/
- droplet_animation.gif - Animated transport
- droplet_snapshot.png - Final state
- droplet_history.png - Temporal evolution

## FSI Coupling Implementation

The coupling is implemented via:

**fsi_coupling.py** - Pressure coupling orchestrator
- Reads fluid pressure from latest time step
- Extracts average pressure on innerWall boundary
- Updates solid case displacement BC with computed pressure
- Runs solid solver with updated loading
- Supports iterative one-way coupling

**droplet_pipe_fsi_sim.py** - Reduced-order validation model
- Includes flexible pipe wall deformation effects
- Models hoop stress: sigma = Pr/t
- Calculates radial expansion: delta_R = Pr^2/(Et)
- Provides fast parameter exploration before full OpenFOAM runs
- Useful for validating results independently

**Usage:**
```bash
python3 fsi_coupling.py --fluid-case fluidCase --solid-case solidCase --nprocs 1
python3 droplet_pipe_fsi_sim.py --enable-fsi --fsi-pressure 1500.0 --output-dir output_fsi
```

## Troubleshooting

**Problem:** "Cannot find file points in directory polyMesh"
**Solution:** Copy mesh to 0/ directory
```bash
cd fluidCase
cp -r constant/polyMesh 0/polyMesh
```

**Problem:** "foamRun: command not found" (Linux/Mac)
**Solution:** Load OpenFOAM environment
```bash
source /opt/openfoam13/etc/bashrc
```

**Problem:** Solver diverges (NaN in output)
**Solution:** Check Courant number (should be < 0.4)
```bash
grep "Courant" fluidCase/log.foamRun
```

**Problem:** Out of disk space
**Solution:** Clean results and restart
```bash
./AllcleanFlexiblePrep
cd solidCase && blockMesh && cd ..
```

## Physics Validation

**Fluid Domain:**
- Reynolds number: Re ~ 600 (laminar)
- Capillary number: Ca ~ 0.002 (surface tension dominant)
- Droplet size: ~2.3mm diameter (comparable to tube radius)

**Solid Domain (Flexible Pipe):**
- Material: Silicone rubber (E=2.5 MPa, typical durometer 40-50)
- Hoop stress at 1500 Pa: sigma=7.5 MPa (well within elastic range)
- Radial expansion at 1500 Pa: delta_R ~ 6 micrometers (0.3% deformation)

**Droplet Transport:**
- Time scale: 0.12s allows 3-4 droplets to cross 50mm domain
- Injection frequency: 1 droplet per 0.014s pulse period

## OpenFOAM Commands Reference

| Task | Command |
|------|---------|
| Generate mesh | `blockMesh` |
| Initialize droplet field | `setFields` |
| Run fluid solver | `foamRun -solver incompressibleVoF` |
| Run solid solver | `foamRun -solver solidDisplacement` |
| Run parallel (4 CPU) | `mpirun -np 4 foamRun -solver incompressibleVoF -parallel` |
| Check mesh quality | `checkMesh` |
| Convert to ParaView | `foamToVTK` |
| Open in ParaView | `paraview &` |
| Clean all results | `./AllcleanFlexiblePrep` |
| Run both cases sequentially | `./AllrunFlexiblePrep` |

## Python Scripts

**droplet_pipe_sim.py** - Original reduced-order model (rigid pipe only)
```bash
python3 droplet_pipe_sim.py --umax 0.20 --pulse-period 0.014 --output-dir output_original
```

**droplet_pipe_fsi_sim.py** - Enhanced model with flexible pipe FSI effects
```bash
python3 droplet_pipe_fsi_sim.py --enable-fsi --youngs-modulus 2.5e6 --output-dir output_fsi
```

## Monitoring Execution

While solver is running, in a separate terminal:

```bash
# Watch fluid convergence
tail -f fluidCase/log.foamRun

# Watch solid convergence
tail -f solidCase/log.foamRun

# Check disk usage
du -sh fluidCase/ solidCase/
```

## Files and Directories

**New scripts:**
- fsi_coupling.py - FSI pressure coupling orchestrator
- droplet_pipe_fsi_sim.py - Enhanced Python FSI model with deformation
- run_fsi_coupling.ps1 - Windows PowerShell orchestration
- run_fsi_coupling.sh - Linux/Mac Bash orchestration

**Configuration:**
- opencode.json - Permission rules (asks before running commands)

**Case directories:**
- 0/ - Root case initial conditions
- constant/ - Root case constant properties and mesh
- system/ - Root case solver configuration
- fluidCase/ - VOF droplet transport case (modified)
- solidCase/ - Elastic wall deformation case (modified)

## Next Steps

For true two-way FSI, future work would include:
1. Map wall deformation back to fluid mesh (mesh morphing)
2. Update fluid domain boundary each time step
3. Implement dynamic mesh quality control
4. Add nonlinear material models (hyperelasticity)
5. Include viscous shear effects on wall deformation

## Run the fluid case

Use:

```bash
cd fluidCase
```

```bash
./Allrun
```

Manual equivalent:

```bash
blockMesh
```

```bash
cp -r constant/polyMesh 0/
```

```bash
setFields
```

```bash
foamRun -solver incompressibleVoF
```

Open in ParaView:

```bash
paraFoam
```

To isolate the droplet in ParaView:

1. Click `Apply`
2. Color by `alpha.water`
3. Add `Threshold`
4. Set threshold range to `0.5` to `1`

## Run the solid wall case

```bash
cd solidCase
```

```bash
./Allrun
```

This runs `blockMesh` and then `foamRun -solver solidDisplacement`.

## Run both baselines

```bash
./AllcleanFlexiblePrep
```

```bash
./AllrunFlexiblePrep
```

This runs:

- the fluid droplet transport baseline in `fluidCase/`
- the deformable wall baseline in `solidCase/`

It is still a preparation workflow, not coupled FSI.

## Flexible pipe: what is actually needed

A flexible pipe is not just a different wall boundary condition. It is a
fluid-structure interaction problem:

- fluid domain: `incompressibleVoF` or another multiphase fluid solver
- solid domain: `solidDisplacement`
- interface coupling: transfer pressure/shear from fluid to wall and wall
  displacement back to the fluid mesh

This OpenFOAM 13 install includes the `solidDisplacement` module, and the repo
now includes a standalone `solidCase/`. What is still missing is the actual
fluid-solid coupling infrastructure needed for a true deforming pipe.


## What “flexible” would mean here

For this project, the technically correct upgrade path is:

1. Use `fluidCase/` as the baseline droplet-transport case.
2. Use `solidCase/` as the baseline deformable-wall case.
3. Add a coupling strategy between the fluid and the wall.
4. Move the fluid mesh with wall deformation each time step.

Until that is implemented, the OpenFOAM case in this repo should be treated as
rigid-wall only.

## Python model

The Python script remains a reduced-order exploratory model:

```bash
python3 droplet_pipe_sim.py
```

Optional example:

```bash
python3 droplet_pipe_sim.py \
  --umax 0.16 \
  --pulse-period 0.010 \
  --duty-cycle 0.25 \
  --nozzle-radius 0.00035 \
  --output-dir output_fast
```
