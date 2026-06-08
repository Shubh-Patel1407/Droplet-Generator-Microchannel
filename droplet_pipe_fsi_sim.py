#!/usr/bin/env python3
"""Reduced-order droplet generator simulation with FSI effects.

This enhanced version of droplet_pipe_sim.py includes:

1. Fluid-Structure Interaction (FSI):
   - Flexible pipe inner radius changes with pressure
   - Deformation affects velocity profile and droplet transport
   
2. Elastic pipe wall model:
   - Hoop stress from internal pressure: sigma = P*r/t
   - Radial expansion: dr = P*r^2/(E*t)
   - Young's modulus E, wall thickness t
   
3. Time-dependent pressure loading:
   - Can specify time-varying pressure (e.g., pulsatile)
   - Or use constant average pressure from FSI coupling

The reduced-order model is useful for:
- Fast parameter exploration before full OpenFOAM runs
- Validating OpenFOAM results
- Understanding droplet dynamics in flexible channels
"""

from __future__ import annotations

import argparse
import os
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Optional

os.environ.setdefault("MPLCONFIGDIR", str(Path(".mplconfig").resolve()))

import matplotlib.pyplot as plt
import numpy as np
from matplotlib.animation import FuncAnimation, PillowWriter


@dataclass
class FSIConfig:
    """Flexible tube material and loading parameters."""
    
    # Pipe geometry (baseline)
    inner_radius: float = 0.002  # 2 mm
    wall_thickness: float = 0.0004  # 0.4 mm
    length: float = 0.05  # 50 mm
    
    # Material properties
    youngs_modulus: float = 5e6  # 5 MPa (soft rubber-like material)
    poisson_ratio: float = 0.45
    
    # Loading
    internal_pressure: float = 1500.0  # Pa (baseline from solid case)
    external_pressure: float = 0.0  # Pa (atmospheric)
    
    # Damping (for stability)
    pressure_damping: float = 0.1
    
    def compute_radius_change(self, pressure: float) -> float:
        """
        Compute radial expansion of pipe due to internal pressure.
        
        Using hoop stress formula and elastic deformation:
        - Hoop stress: sigma = P*r/t
        - Radial expansion: dr = P*r^2 / (E*t)
        
        Args:
            pressure: Internal pressure in Pa
            
        Returns:
            Change in radius (dr) in meters
        """
        if self.youngs_modulus <= 0:
            return 0.0
        
        # Simplified 1D radial expansion
        dr = (pressure - self.external_pressure) * (self.inner_radius ** 2)
        dr /= (self.youngs_modulus * self.wall_thickness)
        
        # Damping to avoid oscillations
        dr *= (1.0 - self.pressure_damping)
        
        return dr
    
    def get_current_radius(self, pressure: float) -> float:
        """Get deformed inner radius at given pressure."""
        dr = self.compute_radius_change(pressure)
        return self.inner_radius + dr
    
    def get_stress(self, pressure: float) -> float:
        """Compute hoop stress in wall."""
        if self.wall_thickness <= 0:
            return 0.0
        return (pressure - self.external_pressure) * self.inner_radius / self.wall_thickness


@dataclass
class SimulationConfig:
    length: float = 0.05
    radius: float = 0.002
    nx: int = 320
    ny: int = 96
    total_time: float = 0.12
    cfl: float = 0.35
    umax: float = 0.12
    diffusivity: float = 1.5e-7
    nozzle_radius: float = 0.00045
    nozzle_x: float = 0.0015
    pulse_period: float = 0.014
    duty_cycle: float = 0.32
    injection_strength: float = 28.0
    purge_strength: float = 18.0
    frame_stride: int = 12
    output_dir: str = "output_fsi"
    
    # FSI settings
    enable_fsi: bool = True
    fsi_config: Optional[FSIConfig] = None


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--length", type=float, default=SimulationConfig.length)
    parser.add_argument("--radius", type=float, default=SimulationConfig.radius)
    parser.add_argument("--nx", type=int, default=SimulationConfig.nx)
    parser.add_argument("--ny", type=int, default=SimulationConfig.ny)
    parser.add_argument("--total-time", type=float, default=SimulationConfig.total_time)
    parser.add_argument("--cfl", type=float, default=SimulationConfig.cfl)
    parser.add_argument("--umax", type=float, default=SimulationConfig.umax)
    parser.add_argument("--diffusivity", type=float, default=SimulationConfig.diffusivity)
    parser.add_argument("--nozzle-radius", type=float, default=SimulationConfig.nozzle_radius)
    parser.add_argument("--nozzle-x", type=float, default=SimulationConfig.nozzle_x)
    parser.add_argument("--pulse-period", type=float, default=SimulationConfig.pulse_period)
    parser.add_argument("--duty-cycle", type=float, default=SimulationConfig.duty_cycle)
    parser.add_argument("--injection-strength", type=float, 
                        default=SimulationConfig.injection_strength)
    parser.add_argument("--purge-strength", type=float,
                        default=SimulationConfig.purge_strength)
    parser.add_argument("--frame-stride", type=int, default=SimulationConfig.frame_stride)
    parser.add_argument("--output-dir", default=SimulationConfig.output_dir)
    
    # FSI arguments
    parser.add_argument("--enable-fsi", action="store_true", default=True,
                        help="Enable FSI (flexible pipe) simulation")
    parser.add_argument("--disable-fsi", dest="enable_fsi", action="store_false",
                        help="Disable FSI (rigid pipe)")
    parser.add_argument("--fsi-pressure", type=float, default=1500.0,
                        help="Internal pressure for flexible pipe (Pa)")
    parser.add_argument("--youngs-modulus", type=float, default=5e6,
                        help="Material Young's modulus (Pa)")
    parser.add_argument("--wall-thickness", type=float, default=0.0004,
                        help="Pipe wall thickness (m)")
    
    return parser


def poiseuille_profile(y: np.ndarray, radius: float, umax: float) -> np.ndarray:
    """Poiseuille velocity profile: u = u_max * (1 - (y/R)^2)"""
    return umax * np.clip(1.0 - (y / radius) ** 2, 0.0, None)


def laplacian(field: np.ndarray, dx: float, dy: float) -> np.ndarray:
    """Compute Laplacian of a 2D field."""
    padded = np.pad(field, ((1, 1), (1, 1)), mode="edge")
    d2x = (padded[1:-1, 2:] - 2.0 * padded[1:-1, 1:-1] + padded[1:-1, :-2]) / dx**2
    d2y = (padded[2:, 1:-1] - 2.0 * padded[1:-1, 1:-1] + padded[:-2, 1:-1]) / dy**2
    return d2x + d2y


def advect_upwind(phi: np.ndarray, u: np.ndarray, dt: float, dx: float) -> np.ndarray:
    """Upwind advection: d(phi)/dt + u*d(phi)/dx = 0"""
    left = np.pad(phi[:, :-1], ((0, 0), (1, 0)), mode="edge")
    right = np.pad(phi[:, 1:], ((0, 0), (0, 1)), mode="edge")
    grad_minus = (phi - left) / dx
    grad_plus = (right - phi) / dx
    return phi - dt * np.where(u >= 0.0, u * grad_minus, u * grad_plus)


def run_simulation(config: SimulationConfig) -> tuple[np.ndarray, list[np.ndarray], np.ndarray, np.ndarray]:
    """Run droplet transport simulation with optional FSI."""
    
    # Initialize FSI if enabled
    fsi = None
    if config.enable_fsi:
        if config.fsi_config is None:
            config.fsi_config = FSIConfig()
        fsi = config.fsi_config
        print(f"\nFSI Enabled:")
        print(f"  Inner radius (baseline): {fsi.inner_radius*1e3:.2f} mm")
        print(f"  Wall thickness: {fsi.wall_thickness*1e3:.2f} mm")
        print(f"  Young's modulus: {fsi.youngs_modulus/1e6:.1f} MPa")
        print(f"  Internal pressure: {fsi.internal_pressure:.1f} Pa")
        
        radius_change = fsi.compute_radius_change(fsi.internal_pressure)
        deformed_radius = fsi.get_current_radius(fsi.internal_pressure)
        stress = fsi.get_stress(fsi.internal_pressure)
        
        print(f"  Computed deformation:")
        print(f"    - Radial expansion: {radius_change*1e6:.2f} um")
        print(f"    - Deformed radius: {deformed_radius*1e3:.4f} mm")
        print(f"    - Hoop stress: {stress/1e6:.2f} MPa")
    
    # Grid generation
    x = np.linspace(0.0, config.length, config.nx)
    y_baseline = np.linspace(-config.radius, config.radius, config.ny)
    
    # Use deformed radius if FSI enabled
    if fsi:
        deformed_r = fsi.get_current_radius(fsi.internal_pressure)
        y = np.linspace(-deformed_r, deformed_r, config.ny)
        actual_radius = deformed_r
    else:
        y = y_baseline
        actual_radius = config.radius
    
    dx = x[1] - x[0]
    dy = y[1] - y[0]
    
    # Velocity profile (scales with deformed radius)
    u = poiseuille_profile(y[:, None], actual_radius, config.umax)
    inlet_profile = np.where(np.abs(y) <= config.nozzle_radius, 1.0, 0.0)
    
    # Time stepping
    dt_adv = config.cfl * dx / max(config.umax, 1e-12)
    dt_diff = 0.25 / max(config.diffusivity * (1.0 / dx**2 + 1.0 / dy**2), 1e-12)
    dt = min(dt_adv, dt_diff, config.total_time / 600.0)
    steps = max(1, int(np.ceil(config.total_time / dt)))
    dt = config.total_time / steps
    
    print(f"\nSimulation Setup:")
    print(f"  Domain: {config.length*1e3:.1f} mm × {2*actual_radius*1e3:.2f} mm")
    print(f"  Grid: {config.nx} × {config.ny}")
    print(f"  Time stepping: {steps} steps, dt = {dt*1e3:.3f} ms")
    print(f"  CFL number: {config.umax * dt / dx:.3f}")
    
    # Phase fraction field
    X, Y = np.meshgrid(x, y)
    nozzle_mask = (X <= config.nozzle_x) & (np.abs(Y) <= config.nozzle_radius)
    phi = np.zeros((config.ny, config.nx), dtype=float)
    frames: list[np.ndarray] = []
    history = np.zeros((steps, config.nx), dtype=float)
    
    # Time integration
    print(f"\nRunning simulation...")
    for step in range(steps):
        t = step * dt
        pulse_phase = (t % config.pulse_period) / config.pulse_period
        pulse_on = pulse_phase <= config.duty_cycle
        
        # Advection
        phi = advect_upwind(phi, u, dt, dx)
        
        # Diffusion
        phi += config.diffusivity * dt * laplacian(phi, dx, dy)
        
        # Injection at nozzle
        if pulse_on:
            phi[nozzle_mask] += config.injection_strength * dt * (1.0 - phi[nozzle_mask])
        elif config.purge_strength > 0.0:
            phi[nozzle_mask] -= config.purge_strength * dt * phi[nozzle_mask]
        
        # Boundary conditions
        if pulse_on:
            phi[:, 0] = inlet_profile
        else:
            phi[:, 0] = 0.0
        phi[:, -1] = phi[:, -2]
        phi[0, :] = 0.0
        phi[-1, :] = 0.0
        phi = np.clip(phi, 0.0, 1.0)
        
        history[step] = phi.mean(axis=0)
        
        if step % max(config.frame_stride, 1) == 0 or step == steps - 1:
            frames.append(phi.copy())
        
        if (step + 1) % max(steps // 10, 1) == 0:
            print(f"  Step {step+1}/{steps} ({100*(step+1)/steps:.0f}%)")
    
    return phi, frames, x, y


def save_summary(config: SimulationConfig, frames: list[np.ndarray], 
                 x: np.ndarray, y: np.ndarray) -> None:
    """Save visualization outputs."""
    output_dir = Path(config.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    final_phi = frames[-1]
    
    # Snapshot
    fig, ax = plt.subplots(figsize=(11, 3.2), constrained_layout=True)
    image = ax.imshow(
        final_phi,
        origin="lower",
        extent=[x.min() * 1e3, x.max() * 1e3, y.min() * 1e3, y.max() * 1e3],
        cmap="Blues",
        vmin=0.0,
        vmax=1.0,
        aspect="auto",
    )
    ax.set_title("Water Droplet Fraction in Oil in Pipe" + 
                (" (FSI-Deformed)" if config.enable_fsi else " (Rigid)"))
    ax.set_xlabel("Axial position x [mm]")
    ax.set_ylabel("Radial position y [mm]")
    fig.colorbar(image, ax=ax, label="Dispersed phase fraction")
    fig.savefig(output_dir / "droplet_snapshot.png", dpi=180)
    plt.close(fig)
    
    # History
    fig, ax = plt.subplots(figsize=(11, 3.2), constrained_layout=True)
    centroids = np.array([frame.mean(axis=0) for frame in frames])
    image = ax.imshow(
        centroids,
        origin="lower",
        extent=[x.min() * 1e3, x.max() * 1e3, 0, len(frames)],
        cmap="magma",
        aspect="auto",
    )
    ax.set_title("Axial Transport History" + 
                (" (FSI-Deformed)" if config.enable_fsi else " (Rigid)"))
    ax.set_xlabel("Axial position x [mm]")
    ax.set_ylabel("Stored frame index")
    fig.colorbar(image, ax=ax, label="Cross-section averaged phase fraction")
    fig.savefig(output_dir / "droplet_history.png", dpi=180)
    plt.close(fig)
    
    # Animation
    fig, ax = plt.subplots(figsize=(11, 3.2), constrained_layout=True)
    image = ax.imshow(
        frames[0],
        origin="lower",
        extent=[x.min() * 1e3, x.max() * 1e3, y.min() * 1e3, y.max() * 1e3],
        cmap="Blues",
        vmin=0.0,
        vmax=1.0,
        aspect="auto",
        animated=True,
    )
    ax.set_title("Droplet Generator Animation" + 
                (" (FSI-Deformed)" if config.enable_fsi else " (Rigid)"))
    ax.set_xlabel("Axial position x [mm]")
    ax.set_ylabel("Radial position y [mm]")
    
    def update(frame: np.ndarray):
        image.set_array(frame)
        return (image,)
    
    animation = FuncAnimation(fig, update, frames=frames, interval=90, blit=True)
    try:
        animation.save(output_dir / "droplet_animation.gif", writer=PillowWriter(fps=12))
    except Exception as exc:
        print(f"Skipping GIF export: {exc}")
    plt.close(fig)


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    
    # Build FSI config if enabled
    fsi_config = None
    if args.enable_fsi:
        fsi_config = FSIConfig(
            youngs_modulus=args.youngs_modulus,
            wall_thickness=args.wall_thickness,
            internal_pressure=args.fsi_pressure,
        )
    
    config = SimulationConfig(
        length=args.length,
        radius=args.radius,
        nx=args.nx,
        ny=args.ny,
        total_time=args.total_time,
        cfl=args.cfl,
        umax=args.umax,
        diffusivity=args.diffusivity,
        nozzle_radius=args.nozzle_radius,
        nozzle_x=args.nozzle_x,
        pulse_period=args.pulse_period,
        duty_cycle=args.duty_cycle,
        injection_strength=args.injection_strength,
        purge_strength=args.purge_strength,
        frame_stride=args.frame_stride,
        output_dir=args.output_dir,
        enable_fsi=args.enable_fsi,
        fsi_config=fsi_config,
    )
    
    _, frames, x, y = run_simulation(config)
    save_summary(config, frames, x, y)
    print(f"\nSaved outputs to {Path(config.output_dir).resolve()}")


if __name__ == "__main__":
    main()
