# Flexible and rigid microchannel simulation

This repository contains OpenFOAM cases for comparing droplet generation in
rigid and flexible microchannels.

## Repository layout

```text
cases/
  flexible-rigid/          Active OpenFOAM comparison
    rigid/                 100 um channel height
    flexible/              93.5 um effective channel height
    common/                Shared fields and solver settings
    Allrun                 Meshes and runs both cases
    Allclean               Removes generated case data
    validate.py            Calculates the comparison table
    validation_results.csv Current numerical results
references/
  deformable-microchannel-study.pdf
legacy/
  original-case/           Original single OpenFOAM case
  fsi-preparation/         Earlier fluid and solid preparation cases
```

The `cases/flexible-rigid` directory is the active work. Files under `legacy`
are retained for reference and are not part of the current comparison.

## Requirements

- OpenFOAM Foundation 13
- Python 3
- ParaView with `paraFoam`

## Run

From the repository root:

```bash
cd cases/flexible-rigid
./Allrun
```

To generate and check both meshes without running the transient simulations:

```bash
cd cases/flexible-rigid
./Allrun --mesh-only
```

The runner loads `/opt/openfoam13/etc/bashrc` automatically when necessary.

## Results

Current calculated values:

| Case | Reference diameter | Simulation diameter | Difference |
|---|---:|---:|---:|
| Rigid | 197.04 um | 134.15 um | -31.92% |
| Flexible | 184.65 um | 147.57 um | -20.08% |

The simulation values are calculated from the largest detached-region volume.
These are the actual current numerical differences and should not be described
as agreement within a validation tolerance.

Recalculate the table without rerunning OpenFOAM:

```bash
cd cases/flexible-rigid
python3 validate.py
```

## ParaView

Open the rigid result:

```bash
paraFoam -case cases/flexible-rigid/rigid
```

Open the flexible result:

```bash
paraFoam -case cases/flexible-rigid/flexible
```

If already inside either case directory, use:

```bash
paraFoam -case .
```

In ParaView, select `alpha.water` and use a contour value of `0.5` to inspect
the phase interface.

## Clean generated data

```bash
cd cases/flexible-rigid
./Allclean
```

`Allclean` removes generated meshes, time directories, logs, post-processing
data, and `validation_results.csv`.
