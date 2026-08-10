# Flexible and rigid microchannel cases

Two OpenFOAM cases are provided:

- `rigid`: 100 um channel height
- `flexible`: 93.5 um effective channel height

Shared operating conditions:

- channel width: 100 um
- continuous-phase viscosity: 0.0287 Pa s
- continuous-phase density: 857 kg/m3
- dispersed-phase viscosity: 0.000914 Pa s
- dispersed-phase density: 994 kg/m3
- interfacial tension: 0.003501 N/m
- contact angle: 96.91 degrees
- continuous-phase flow rate: 2.34213 uL/min
- dispersed-phase flow rate: 1.17107 uL/min

Run both cases:

```bash
./Allrun
```

Check only the input files and meshes:

```bash
./Allrun --mesh-only
```

Results are written to `validation_results.csv`.

The complete calculation method and limitations are documented in
`VALIDATION.md`.

From the repository root, open the results with:

```bash
paraFoam -case cases/flexible-rigid/rigid
paraFoam -case cases/flexible-rigid/flexible
```

The current simulation diameters are 134.15 um for the rigid case and
147.57 um for the flexible case. Their differences from the reference values
are -31.92% and -20.08%, respectively.
