#!/usr/bin/env python3
"""Compare simulated droplet sizes with the reference correlation."""

from __future__ import annotations

import csv
import math
from pathlib import Path


ROOT = Path(__file__).resolve().parent
WIDTH = 100e-6
FLOW_RATIO = 0.5
VISCOSITY_RATIO = 0.000914 / 0.0287


def reference_diameter(kp: float) -> float:
    d_over_w = (
        1.97064
        * (1.0 + kp) ** -0.0655
        * FLOW_RATIO ** 0.13593
        * VISCOSITY_RATIO ** -0.0273
    )
    return d_over_w * WIDTH


def measured_diameter(case: str) -> float | None:
    """Convert the largest detached-region volume to a top-view diameter."""
    base = ROOT / case / "postProcessing" / "dropletSizes"
    candidates = list(base.rglob("regionSizeDistribution*")) if base.exists() else []
    if not candidates:
        return None
    candidates.sort(key=lambda path: float(path.parent.name))

    volumes: list[float] = []
    for line in candidates[-1].read_text(errors="ignore").splitlines():
        if not line.strip() or line.lstrip().startswith(("#", "//")):
            continue
        try:
            values = [float(value) for value in line.split()]
        except ValueError:
            continue
        if len(values) >= 2 and math.isfinite(values[1]) and values[1] > 0:
            volumes.append(values[1])
    if not volumes:
        return None
    height = 100e-6 if case == "rigid" else 93.5e-6
    return math.sqrt(4.0 * max(volumes) / (math.pi * height))


def main() -> None:
    cases = (("rigid", 0.0), ("flexible", 1.695))
    output_rows = []
    print("Flexible and rigid channel comparison")
    for case, kp in cases:
        expected = reference_diameter(kp)
        measured = measured_diameter(case)
        error = None if measured is None else 100.0 * (measured - expected) / expected
        print(f"{case:8s} Kp={kp:5.3f}: reference={expected*1e6:7.2f} um", end="")
        if measured is None:
            print("; CFD droplet histogram not available yet")
        else:
            print(f"; CFD={measured*1e6:7.2f} um; error={error:+6.2f}%")
        output_rows.append((case, kp, expected * 1e6,
                            "" if measured is None else measured * 1e6,
                            "" if error is None else error))

    with (ROOT / "validation_results.csv").open("w", newline="") as handle:
        writer = csv.writer(handle)
        writer.writerow(("case", "Kp", "reference_diameter_um", "simulation_diameter_um", "error_percent"))
        writer.writerows(output_rows)


if __name__ == "__main__":
    main()
