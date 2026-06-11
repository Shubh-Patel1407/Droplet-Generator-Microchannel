# Presentation Visuals - Quick Start

## 🎯 Goal
Generate all plots and animations needed for your professor presentation.

---

## ⚡ Quick Generation (2 minutes)

### **Step 1: Generate Static Plots**

```bash
# In WSL
cd /home/shubh/Droplet-Generator-Microchannel
python3 generate_all_visuals.py
```

This creates 4 plots in `presentation_visuals/`:
1. ✅ `wall_deformation.png` - Displacement vs time
2. ✅ `velocity_profile.png` - Parabolic flow validation
3. ✅ `hoop_stress_validation.png` - Stress safety factor
4. ✅ `dimensionless_numbers.png` - Re, Ca, strain regimes

### **Step 2: Create Droplet Animation in ParaView**

```bash
cd fluidCase
foamToVTK
paraview
```

**In ParaView:**
1. File → Open → `VTK/fluidCase_*.vtk` → Apply
2. Color by: `alpha.water`
3. Add Filter → Threshold → alpha.water: 0.5 to 1.0 → Apply
4. File → Save Animation → droplet_transport.gif (or MP4)

### **Step 3: Create System Schematic**

Open PowerPoint/draw.io and draw:
- Pipe with dimensions (50mm × 4mm)
- Droplet (blue circle, ~2.3mm)
- Arrows showing flow direction
- Labels: inlet (0.30 m/s), outlet (0 Pa), wall (E=2.5 MPa)

---

## 📋 Visuals Checklist for Presentation

### **Must Have (6 visuals):**
- [x] `wall_deformation.png` - Python script ✓
- [x] `velocity_profile.png` - Python script ✓
- [x] `hoop_stress_validation.png` - Python script ✓
- [x] `dimensionless_numbers.png` - Python script ✓
- [ ] `droplet_transport.gif` - ParaView (5 min)
- [ ] `system_schematic.png` - PowerPoint/hand-drawn (10 min)

### **Nice to Have (optional):**
- [ ] Pressure field snapshots (ParaView)
- [ ] 3D droplet beauty shot (ParaView)
- [ ] Results summary table (PowerPoint)

---

## 🖼️ What Each Visual Shows

### **1. Wall Deformation (Line Plot)**
- **X-axis:** Time (0-120 ms)
- **Y-axis:** Radial displacement (0-8 μm)
- **Shows:** Wall expands by 6 μm under pressure
- **Key message:** "Small deformation (0.3% strain) validates linear elasticity"

### **2. Velocity Profile (2-panel)**
- **Left panel:** Velocity vs radius (parabolic curve)
- **Right panel:** 2D visualization with arrows
- **Shows:** CFD matches analytical Poiseuille solution
- **Key message:** "Simulation validated against theory"

### **3. Hoop Stress (Bar Chart)**
- **Bars:** Analytical (7.5 kPa) vs CFD (7.35 kPa)
- **Horizontal line:** Yield stress (1000 kPa)
- **Shows:** Stress is 133× below failure
- **Key message:** "Design is extremely safe"

### **4. Dimensionless Numbers (3-panel)**
- **Panel 1:** Reynolds number (Re=600, laminar zone)
- **Panel 2:** Capillary number (Ca=0.002, surface tension dominates)
- **Panel 3:** Strain (0.3%, linear elastic zone)
- **Key message:** "All parameters in expected regimes"

### **5. Droplet Animation (GIF/MP4)**
- **Shows:** Droplet moving through pipe
- **Duration:** 3-5 seconds, looped
- **Key message:** "Main phenomenon - droplet transport at 0.20 m/s"

### **6. System Schematic (Diagram)**
- **Shows:** Geometry, materials, boundary conditions
- **Key message:** "Problem setup at a glance"

---

## 🎨 Visual Quality Tips

### **Colors:**
- **Water droplet:** Blue (#4ECDC4)
- **Wall/stress:** Red/orange (#FF6B6B)
- **Safe zones:** Green (#4CAF50)
- **Analytical:** Red dashed lines
- **CFD:** Blue solid lines/dots

### **Fonts:**
- **Title:** 16pt, bold
- **Axis labels:** 14pt, bold
- **Legend:** 12pt
- **Annotations:** 12-14pt

### **Resolution:**
- All PNGs: 300 DPI minimum
- GIF: 1920×1080 pixels
- For printing: Use vector formats (PDF/SVG) if possible

---

## 📊 Recommended Presentation Flow

**Slide Order:**

1. **Title slide** - 3D droplet beauty shot
2. **System overview** - Schematic diagram
3. **Physics overview** - Dimensionless numbers infographic
4. **Main result** - Droplet animation (GIF)
5. **Flow validation** - Velocity profile
6. **Wall response** - Deformation plot
7. **Safety check** - Hoop stress validation
8. **Summary** - Results table
9. **Conclusions** - Key takeaways

**Total: 9 slides, 5-7 minutes**

---

## 💾 File Locations After Generation

```
Droplet-Generator-Microchannel/
├── presentation_visuals/         ← Python-generated plots
│   ├── wall_deformation.png
│   ├── velocity_profile.png
│   ├── hoop_stress_validation.png
│   └── dimensionless_numbers.png
├── fluidCase/VTK/                ← ParaView source files
│   └── fluidCase_*.vtk
└── droplet_transport.gif         ← Animation (create in ParaView)
```

**Copy to Windows for PowerPoint:**
```bash
cp presentation_visuals/*.png /mnt/c/Users/space/Desktop/Presentation/
cp droplet_transport.gif /mnt/c/Users/space/Desktop/Presentation/
```

---

## 🚀 Quick Commands Reference

```bash
# Generate all Python plots (2 min)
python3 generate_all_visuals.py

# Create ParaView animation (5 min)
cd fluidCase && foamToVTK && paraview

# Check what was generated
ls -lh presentation_visuals/

# Copy to Windows Desktop
cp -r presentation_visuals /mnt/c/Users/space/Desktop/
```

---

## 🎓 Presenting Tips

### **For Each Visual:**

1. **State what it shows** (1 sentence)
2. **Point out key feature** (arrow/circle on slide)
3. **Interpret the result** (what does it mean?)
4. **Relate to validation** (matches theory? safe? expected?)

### **Example Script for Wall Deformation Plot:**

> "This plot shows the wall deformation over time. [POINT] The blue line represents our CFD simulation, showing the wall expands by 6 micrometers under 1500 Pascal internal pressure. [POINT] The red dashed line is the analytical formula, Δr = Pr²/Et, which gives the same result. This 6 micrometer expansion is only 0.3% strain, which validates our linear elasticity assumption and confirms the design is well within the elastic range."

### **Time per Slide:**
- Title: 10 seconds
- Overview/schematic: 30 seconds
- Each result plot: 45-60 seconds
- Animation: 30 seconds (let it loop)
- Summary: 30 seconds

**Total: ~5-7 minutes**

---

## ✅ Final Checklist Before Presentation

- [ ] All 6 visuals generated and saved
- [ ] Visuals copied to presentation folder
- [ ] Plots are high resolution (300 DPI)
- [ ] GIF plays smoothly in PowerPoint
- [ ] Schematic is clear and labeled
- [ ] Numbers match PRESENTATION_CHEAT_SHEET.md
- [ ] Practiced presentation timing (5-7 min)
- [ ] Backup plan if tech fails (printed slides)

---

## 🆘 Troubleshooting

**Q: Python script fails with "No module named matplotlib"**  
A: Install: `pip3 install matplotlib numpy`

**Q: Seaborn style not found**  
A: Install: `pip3 install seaborn` (optional, plots work without it)

**Q: ParaView won't open VTK files**  
A: Make sure you ran `foamToVTK` first in fluidCase/

**Q: GIF is too large**  
A: Reduce resolution to 1280×720 or use MP4 format instead

**Q: Plots look blurry in PowerPoint**  
A: Check DPI is 300, don't resize in PowerPoint (resize before import)

---

**Good luck with your presentation! 🎓**

---

**See also:**
- [SIMULATION_GUIDE.md](SIMULATION_GUIDE.md) - Full technical details
- [PRESENTATION_CHEAT_SHEET.md](PRESENTATION_CHEAT_SHEET.md) - Key numbers to remember
- [VISUALIZATION_GUIDE.md](VISUALIZATION_GUIDE.md) - Detailed visual creation steps
