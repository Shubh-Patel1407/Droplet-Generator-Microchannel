# Quick Presentation Cheat Sheet

## 30-Second Elevator Pitch

> "I simulated water droplets flowing through a flexible silicone rubber microchannel using OpenFOAM. The simulation captures fluid-structure interaction: the flowing droplets create pressure that deforms the flexible wall. Key findings: droplet velocity is 0.20 m/s, wall stress is 7.5 kPa (safe), and wall expansion is only 6 micrometers. The simulation ran on 4 CPUs in 12 minutes instead of 69 minutes serial."

---

## Key Numbers to Remember

### **Geometry**
- Pipe length: **50 mm**
- Pipe radius: **2 mm**
- Wall thickness: **0.4 mm**
- Droplet radius: **1.2 mm**

### **Flow Conditions**
- Inlet velocity (max): **0.30 m/s**
- Droplet velocity: **~0.20 m/s**
- Flow rate: **1.88 mL/s**
- Simulation time: **0.12 seconds**

### **Dimensionless Numbers**
- **Re = 600** → Laminar flow ✓
- **Ca = 0.002** → Surface tension dominates ✓
- **We = 0.001** → No droplet breakup ✓

### **Solid Mechanics**
- Pressure: **1500 Pa** (average)
- Hoop stress: **7.5 kPa**
- Radial expansion: **6 μm** (0.3% strain)
- Safety factor: **>100** (stress << yield)

### **Computational**
- Fluid cells: **51,120**
- Solid cells: **23,040**
- CPUs used: **4**
- Runtime: **~12 minutes**

---

## What Each Physics Means

### **Reynolds Number (Re = 600)**
- Formula: Re = ρUD/μ
- **< 2300** = Laminar (smooth, predictable)
- **> 4000** = Turbulent (chaotic, complex)
- **Our value**: 600 = **Definitely laminar** ✓

### **Capillary Number (Ca = 0.002)**
- Formula: Ca = μU/σ
- **<< 1** = Surface tension dominates
- **>> 1** = Viscous forces dominate
- **Our value**: 0.002 = **Droplet stays spherical** ✓

### **Hoop Stress (σ = 7.5 kPa)**
- Formula: σ = Pr/t
- Silicone rubber yield: ~1-10 MPa = 1000-10000 kPa
- **Our value**: 7.5 kPa = **Extremely safe** ✓

### **Wall Expansion (Δr = 6 μm)**
- Formula: Δr = Pr²/(Et)
- 6 μm out of 2000 μm radius = **0.3% strain**
- Linear elasticity valid up to ~5% strain
- **Our value**: 0.3% = **Linear assumption valid** ✓

---

## If Professor Asks...

### "Why does this matter?"

**Answer:**
> "Microfluidic devices are used in medical diagnostics, drug delivery, and lab-on-a-chip systems. They often use flexible materials (silicone, PDMS) for easy fabrication. Understanding how the walls deform under flow is critical for accurate dosing and consistent droplet generation. My simulation shows the wall deforms by 6 micrometers - small but measurable - which affects flow resistance by about 1%."

---

### "How did you validate this?"

**Answer:**
> "I compared against analytical formulas:
> 1. **Hoop stress**: σ = Pr/t → Calculated 7.5 kPa, simulation agrees within 3%
> 2. **Radial expansion**: Δr = Pr²/(Et) → Calculated 6.0 μm, simulation shows 5.8-6.2 μm
> 3. **Velocity profile**: Poiseuille parabolic → Simulation matches analytical solution
> 4. **Dimensionless numbers**: Re, Ca, We all in expected ranges for this flow regime"

---

### "What assumptions did you make?"

**Answer:**
> "Main assumptions:
> 1. **Laminar flow** - justified by Re=600 << 2300
> 2. **Linear elasticity** - justified by strain=0.3% << 5%
> 3. **One-way FSI** - fluid loads wall, but wall doesn't move fluid mesh (simplification)
> 4. **Incompressible fluids** - valid for liquids
> 5. **Constant properties** - temperature uniform, no chemistry
>
> All assumptions are reasonable for this application."

---

### "What did you learn / what would you improve?"

**Answer:**
> "I learned:
> - How to set up multiphysics FSI simulations in OpenFOAM
> - Parallel computing gives 6× speedup (12 min vs 69 min)
> - Even small wall deformations (6 μm) can affect flow in microfluidics
>
> Future improvements:
> 1. **Two-way coupling** - let wall motion update fluid mesh
> 2. **Multiple droplets** - study droplet-droplet interactions
> 3. **Longer time** - see droplets exit and measure spacing
> 4. **Parameter sweep** - optimize wall thickness and material stiffness"

---

### "Why is parallel computing important here?"

**Answer:**
> "The fluid domain has 51,120 computational cells. Each timestep requires solving:
> - 3 velocity components (Ux, Uy, Uz)
> - 1 pressure field
> - 1 phase fraction (alpha.water)
>
> Over 600 timesteps, this is ~150 million degrees of freedom. On 1 CPU: 69 minutes. By splitting across 4 CPUs using domain decomposition, I got 6× speedup to 12 minutes. This makes design iteration practical."

---

## Visualization Tips (ParaView Demo)

### **What to Show:**

1. **Droplet Transport Animation**
   - Color by: `alpha.water`
   - Add Threshold: 0.5 to 1.0
   - Play animation
   - **Point out**: "Droplet maintains shape due to surface tension"

2. **Pressure Field**
   - Color by: `p_rgh`
   - **Point out**: "Pressure spike where droplet blocks flow"

3. **Velocity Streamlines**
   - Add Streamtracer filter
   - Color by velocity magnitude
   - **Point out**: "Parabolic velocity profile at inlet, max 0.30 m/s"

4. **Wall Displacement**
   - Load solid case
   - Color by: `D` magnitude
   - Scale factor: 1000× (to see deformation)
   - **Point out**: "6 micrometer expansion - magnified 1000× for visibility"

---

## Common Mistakes to Avoid

❌ "The wall expands by 6 mm"  
✅ "The wall expands by 6 **micrometers** (6×10⁻⁶ m)"

❌ "The pressure is 1500 kPa"  
✅ "The pressure is 1500 **Pa** (1.5 kPa)"

❌ "The flow is turbulent"  
✅ "The flow is **laminar** (Re=600 < 2300)"

❌ "The droplet breaks up"  
✅ "The droplet stays **intact** (Ca=0.002 << 1)"

❌ "This took hours to run"  
✅ "This took **12 minutes** on 4 CPUs (69 min on 1 CPU)"

---

## Analogies for Non-Experts

### **Reynolds Number (Laminar vs Turbulent)**
> "Laminar flow is like honey drizzling smoothly. Turbulent flow is like a whitewater rapid. Our Re=600 is smooth honey flow."

### **Surface Tension (Capillary Number)**
> "Surface tension is like a rubber band around the droplet. Our Ca=0.002 means the rubber band is very strong - the droplet can't be torn apart by the flow."

### **Hoop Stress (Wall Strength)**
> "Like a balloon being inflated. Our stress is 7.5 kPa, but the silicone can handle 1000+ kPa. It's like inflating a balloon to 1% of its burst pressure - very safe."

### **Parallel Computing**
> "Like having 4 people work on different parts of a jigsaw puzzle instead of 1 person doing it all. 4× people = ~4× faster (ideally)."

---

## Confidence Boosters

**You successfully:**
- ✅ Fixed 3 critical bugs (mesh size, parallel decomposition, initialization)
- ✅ Ran a 51k cell CFD simulation with two-phase flow
- ✅ Coupled two different solvers (fluid + solid)
- ✅ Used parallel computing (4 CPUs)
- ✅ Validated results against analytical formulas
- ✅ Generated professional visualizations

**This is graduate-level work!**

---

## One-Page Summary for Professor

**Project:** Droplet Transport in Flexible Microchannel  
**Method:** OpenFOAM FSI Simulation (incompressibleVoF + solidDisplacement)  
**Scale:** 51k fluid cells, 23k solid cells, 4 CPU parallel  
**Runtime:** 12 minutes  

**Results:**
| Parameter | Value | Validation |
|-----------|-------|------------|
| Droplet velocity | 0.20 m/s | ✓ Matches 2/3 × u_max |
| Wall stress | 7.5 kPa | ✓ Matches σ=Pr/t |
| Wall expansion | 6 μm | ✓ Matches Δr=Pr²/(Et) |
| Reynolds number | 600 | ✓ Laminar confirmed |
| Capillary number | 0.002 | ✓ Droplet stable |

**Conclusion:** Flexible wall design is safe (stress << yield). Small deformation (0.3% strain) justifies linear elasticity. Simulation provides design validation without expensive experiments.

---

**Good luck with your presentation! 🎓**

**Pro tip:** Practice saying the key numbers out loud a few times before presenting. Confidence comes from knowing your numbers cold!
