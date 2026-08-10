# Validation method and results

## Method

The comparison uses a published droplet-diameter correlation:

\[
\frac{D}{W}=1.97064(1+K_p)^{-0.0655}r^{0.13593}\lambda^{-0.0273}
\]

The inputs are:

| Parameter | Value |
|---|---:|
| Channel width, `W` | 100 um |
| Flow-rate ratio, `r` | 0.5 |
| Viscosity ratio, `lambda` | 0.000914 / 0.0287 |
| Rigid-case `Kp` | 0 |
| Flexible-case `Kp` | 1.695 |

The resulting reference diameters are 197.04 um for the rigid case and
184.65 um for the flexible case.

## CFD measurement

OpenFOAM's `regionSizeDistribution` function identifies disconnected water
regions using `alpha.water > 0.5`. The largest detected detached-region
volume, `V`, is converted to projected area using the channel height:

\[
A=\frac{V}{h}
\]

An area-equivalent top-view diameter is then calculated:

\[
D_{CFD}=\sqrt{\frac{4V}{\pi h}}
\]

The rigid case uses `h = 100 um`; the flexible case uses `h = 93.5 um`.

The percentage difference is:

\[
\mathrm{difference}=100\frac{D_{CFD}-D_{reference}}{D_{reference}}
\]

## Results

| Case | Reference diameter | CFD diameter | Difference |
|---|---:|---:|---:|
| Rigid | 197.04 um | 134.15 um | -31.92% |
| Flexible | 184.65 um | 147.57 um | -20.08% |

The machine-readable values are stored in `validation_results.csv`. Run
`python3 validate.py` to recalculate them from the available OpenFOAM
post-processing output.

## Limitations

- This compares CFD results with a correlation, not raw experimental points.
- The flexible case uses a reduced effective channel height; it is not a
  fully coupled fluid-structure interaction simulation.
- The CFD diameter is derived from the largest detected region volume and an
  area-equivalent top-view approximation.
- The current differences are substantial and should not be reported as
  agreement within a validation tolerance.

