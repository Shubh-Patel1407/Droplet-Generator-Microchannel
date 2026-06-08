#!/usr/bin/env python3
"""
FSI (Fluid-Structure Interaction) Coupling Script for OpenFOAM
=============================================================

This script implements a one-way (fluid → solid) coupling for droplet transport
through flexible microchannels. It:

1. Reads pressure field from fluid domain (incompressibleVoF)
2. Extracts average pressure on pipe inner wall
3. Updates solid case boundary condition with computed pressure
4. Runs solid solver to get deformed wall geometry
5. (Future: map deformation back to fluid mesh for two-way coupling)

Current approach: Iterative one-way coupling at selected time steps
- Fluid solves first (generates pressure field)
- Solid solves with time-averaged pressure from fluid
- Can be extended to full two-way coupling with mesh morphing
"""

import os
import re
import sys
import struct
import subprocess
from pathlib import Path
from typing import Tuple, Optional
import numpy as np


class OpenFOAMReader:
    """Read OpenFOAM binary/text files."""
    
    @staticmethod
    def read_internal_field(field_path: Path) -> np.ndarray:
        """
        Read internal field from OpenFOAM field file.
        Supports both ascii and binary formats.
        """
        if not field_path.exists():
            raise FileNotFoundError(f"Field file not found: {field_path}")
        
        with open(field_path, 'r') as f:
            content = f.read()
        
        # Find "internalField" section
        internal_match = re.search(
            r'internalField\s+(nonuniform|uniform)\s+(\w+)\s*\n\s*<',
            content,
            re.MULTILINE
        )
        if internal_match:
            # Binary format
            return OpenFOAMReader._read_binary_field(field_path, internal_match.start())
        
        # Try ascii format
        internal_match = re.search(
            r'internalField\s+nonuniform\s+List<(\w+)>\s*\n\s*(\d+)\s*\n\s*\(',
            content,
            re.MULTILINE
        )
        if internal_match:
            list_type = internal_match.group(1)
            n_entries = int(internal_match.group(2))
            
            # Extract the list content
            start = internal_match.end()
            end = content.find(')', start)
            list_content = content[start:end]
            
            # Parse scalar values
            values = re.findall(r'[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?', list_content)
            return np.array([float(v) for v in values[:n_entries]])
        
        # Try uniform format
        uniform_match = re.search(
            r'internalField\s+uniform\s+([-+]?[0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?)',
            content
        )
        if uniform_match:
            value = float(uniform_match.group(1))
            return np.array([value])  # Single uniform value
        
        raise ValueError(f"Could not parse internalField from {field_path}")
    
    @staticmethod
    def _read_binary_field(field_path: Path, start_pos: int) -> np.ndarray:
        """Read binary OpenFOAM field (simplified)."""
        # This is a simplified version - full binary format is complex
        # For now, fall back to ascii extraction
        with open(field_path, 'rb') as f:
            content = f.read().decode('utf-8', errors='ignore')
        
        # Try to extract numbers anyway
        numbers = re.findall(r'[-+]?[0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?', content)
        return np.array([float(n) for n in numbers[:100]])  # Safety limit


class FSICoupler:
    """Manage FSI coupling between fluid and solid domains."""
    
    def __init__(self, 
                 fluid_case: Path = None,
                 solid_case: Path = None,
                 coupling_interval: float = 0.01):
        """
        Initialize FSI coupler.
        
        Args:
            fluid_case: Path to fluid case directory
            solid_case: Path to solid case directory
            coupling_interval: Time interval for pressure sampling (seconds)
        """
        self.base_dir = Path.cwd()
        self.fluid_case = fluid_case or self.base_dir / "fluidCase"
        self.solid_case = solid_case or self.base_dir / "solidCase"
        self.coupling_interval = coupling_interval
        
        # Validate case directories
        for case in [self.fluid_case, self.solid_case]:
            if not (case / "system" / "controlDict").exists():
                raise ValueError(f"Invalid case directory: {case}")
        
        self.pressure_history = []
        self.time_steps_coupled = []
    
    def get_latest_fluid_time(self) -> Optional[float]:
        """Find the latest time directory in fluid case."""
        time_dirs = []
        for item in (self.fluid_case).iterdir():
            if item.is_dir() and not item.name.startswith('0'):
                try:
                    t = float(item.name)
                    time_dirs.append(t)
                except ValueError:
                    pass
        
        return max(time_dirs) if time_dirs else None
    
    def extract_pressure_at_boundary(self, 
                                     time_step: float,
                                     boundary: str = "pipeWall") -> float:
        """
        Extract average pressure on a boundary patch.
        
        Args:
            time_step: Time directory to read from
            boundary: Boundary patch name
            
        Returns:
            Average pressure value in Pa
        """
        p_rgh_file = self.fluid_case / str(time_step) / "p_rgh"
        
        if not p_rgh_file.exists():
            print(f"Warning: p_rgh file not found at time {time_step}")
            return 0.0
        
        try:
            pressure_field = OpenFOAMReader.read_internal_field(p_rgh_file)
            
            # Simple heuristic: use mean of all pressure values
            # (Better approach: use boundaryField data if available)
            avg_pressure = np.mean(pressure_field[pressure_field != 0])
            
            print(f"  Extracted avg pressure at t={time_step:.5f}s: {avg_pressure:.2f} Pa")
            self.pressure_history.append(avg_pressure)
            
            return avg_pressure
            
        except Exception as e:
            print(f"Error reading pressure: {e}")
            return 0.0
    
    def update_solid_pressure_bc(self, pressure_value: float):
        """
        Update solid case inner wall pressure boundary condition.
        
        Args:
            pressure_value: Pressure in Pa to apply to innerWall
        """
        d_file = self.solid_case / "0" / "D"
        
        if not d_file.exists():
            raise FileNotFoundError(f"Displacement field not found: {d_file}")
        
        # Read the D file
        with open(d_file, 'r') as f:
            content = f.read()
        
        # Find and replace the pressure value in innerWall boundary condition
        # Pattern: innerWall { ... pressure uniform <VALUE>; ... }
        pattern = r'(innerWall\s*\{[^}]*pressure\s+uniform\s+)[-+]?[0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?'
        
        new_content = re.sub(pattern, rf'\g<1>{pressure_value:.1f}', content)
        
        # Write back
        with open(d_file, 'w') as f:
            f.write(new_content)
        
        print(f"  Updated innerWall pressure in {d_file.name} to {pressure_value:.1f} Pa")
    
    def run_fluid_solver(self, nprocs: int = 1):
        """
        Run the fluid solver (incompressibleVoF).
        
        Args:
            nprocs: Number of processors for parallel run (1 = serial)
        """
        print("\n=== Running Fluid Solver ===")
        os.chdir(self.fluid_case)
        
        if nprocs > 1:
            cmd = f"mpirun -np {nprocs} foamRun -solver incompressibleVoF -parallel"
        else:
            cmd = "foamRun -solver incompressibleVoF"
        
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        
        if result.returncode != 0:
            print(f"Fluid solver failed:\n{result.stderr}")
            return False
        
        print("Fluid solver completed successfully")
        return True
    
    def run_solid_solver(self, nprocs: int = 1):
        """
        Run the solid solver (solidDisplacement).
        
        Args:
            nprocs: Number of processors for parallel run
        """
        print("\n=== Running Solid Solver ===")
        os.chdir(self.solid_case)
        
        if nprocs > 1:
            cmd = f"mpirun -np {nprocs} foamRun -solver solidDisplacement -parallel"
        else:
            cmd = "foamRun -solver solidDisplacement"
        
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        
        if result.returncode != 0:
            print(f"Solid solver failed:\n{result.stderr}")
            return False
        
        print("Solid solver completed successfully")
        return True
    
    def run_coupling_iteration(self, nprocs: int = 1):
        """
        Execute one full FSI coupling iteration.
        
        Steps:
        1. Run fluid solver
        2. Extract pressure from latest fluid time step
        3. Update solid case pressure BC
        4. Run solid solver
        
        Args:
            nprocs: Number of processors
        """
        print("\n" + "="*60)
        print("FSI COUPLING ITERATION")
        print("="*60)
        
        # Step 1: Run fluid
        if not self.run_fluid_solver(nprocs):
            return False
        
        # Step 2: Extract pressure
        os.chdir(self.base_dir)
        latest_time = self.get_latest_fluid_time()
        if latest_time is None:
            print("Error: No time directories found in fluid case")
            return False
        
        pressure = self.extract_pressure_at_boundary(latest_time)
        self.time_steps_coupled.append(latest_time)
        
        # Step 3: Update solid BC
        self.update_solid_pressure_bc(pressure)
        
        # Step 4: Run solid
        if not self.run_solid_solver(nprocs):
            return False
        
        print("\nFSI coupling iteration completed successfully")
        return True
    
    def print_summary(self):
        """Print coupling summary."""
        print("\n" + "="*60)
        print("FSI COUPLING SUMMARY")
        print("="*60)
        print(f"Fluid case: {self.fluid_case}")
        print(f"Solid case: {self.solid_case}")
        print(f"Time steps coupled: {len(self.time_steps_coupled)}")
        if self.time_steps_coupled:
            print(f"  Times: {self.time_steps_coupled}")
        if self.pressure_history:
            print(f"Pressure range: {min(self.pressure_history):.2f} to {max(self.pressure_history):.2f} Pa")
            print(f"Mean pressure: {np.mean(self.pressure_history):.2f} Pa")


def main():
    """Command-line interface for FSI coupling."""
    import argparse
    
    parser = argparse.ArgumentParser(
        description="FSI coupling script for OpenFOAM droplet-tube simulations"
    )
    parser.add_argument("--fluid-case", type=Path, default=Path("fluidCase"),
                        help="Path to fluid case directory")
    parser.add_argument("--solid-case", type=Path, default=Path("solidCase"),
                        help="Path to solid case directory")
    parser.add_argument("--coupling-interval", type=float, default=0.01,
                        help="Time interval for pressure sampling (seconds)")
    parser.add_argument("--nprocs", type=int, default=1,
                        help="Number of processors for parallel execution")
    parser.add_argument("--no-run", action="store_true",
                        help="Only update BC without running solvers")
    
    args = parser.parse_args()
    
    try:
        coupler = FSICoupler(
            fluid_case=args.fluid_case,
            solid_case=args.solid_case,
            coupling_interval=args.coupling_interval
        )
        
        if not args.no_run:
            coupler.run_coupling_iteration(nprocs=args.nprocs)
        else:
            # Just update BC as demo
            coupler.update_solid_pressure_bc(1500.0)
        
        coupler.print_summary()
        
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
