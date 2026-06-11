# Step-by-Step Command Guide for Presentation Materials

## 🎯 Goal
Create all visual materials needed for your professor presentation in the right order with clear commands.

---

## ⏱️ Total Time: ~30 minutes

- Plots generation: 2 minutes
- ParaView animation: 10 minutes  
- System schematic: 10 minutes
- Copy to Windows: 2 minutes
- Build PowerPoint: 6 minutes

---

## 📋 PART 1: Generate Static Plots (2 minutes)

### **What it does:**
Automatically creates 4 high-quality PNG plots for your presentation

### **Commands to run in WSL terminal:**

```bash
# Navigate to project directory
cd /home/shubh/Droplet-Generator-Microchannel

# Run the Python visualization script
python3 generate_all_visuals.py
```

**Expected output:**
```
============================================================
GENERATING PRESENTATION VISUALS
============================================================

[1/4] Generating Wall Deformation Plot...
  ✓ Saved: presentation_visuals/wall_deformation.png
[2/4] Generating Velocity Profile Plot...
  ✓ Saved: presentation_visuals/velocity_profile.png
[3/4] Generating Hoop Stress Validation Plot...
  ✓ Saved: presentation_visuals/hoop_stress_validation.png
[4/4] Generating Dimensionless Numbers Plot...
  ✓ Saved: presentation_visuals/dimensionless_numbers.png

============================================================
✓ ALL VISUALIZATIONS GENERATED SUCCESSFULLY!
============================================================
```

### **Verify success:**
```bash
# Check if files were created
ls -lh presentation_visuals/

# Expected output:
# -rw-r--r-- ... wall_deformation.png
# -rw-r--r-- ... velocity_profile.png
# -rw-r--r-- ... hoop_stress_validation.png
# -rw-r--r-- ... dimensionless_numbers.png
```

✅ **DONE!** 4 plots created. Continue to Part 2.

---

## 🎬 PART 2: Create Droplet Animation in ParaView (10 minutes)

### **What it does:**
Creates a GIF showing the water droplet moving through the pipe

### **Step 1: Prepare data for ParaView**

```bash
# Still in WSL
cd /home/shubh/Droplet-Generator-Microchannel/fluidCase

# Convert OpenFOAM results to VTK format (for ParaView)
foamToVTK

# Verify conversion worked
ls -la VTK/ | head -20
# Should show files like: fluidCase_0.vtk, fluidCase_1.vtk, etc.
```

**Expected output:**
```
Reading case: /home/shubh/Droplet-Generator-Microchannel/fluidCase
Time = 0.001
Converting lagrangian data
...
Time = 0.12
Converting lagrangian data

Writing VTK files
```

### **Step 2: Open ParaView GUI**

```bash
# Launch ParaView (opens graphical window)
paraview &
```

This will open the ParaView window. If it doesn't appear, you may need to use:
```bash
paraview &  # Run in background
# or
paraview    # Run in foreground (terminal will block)
```

### **Step 3: Load and Configure Data (in ParaView)**

**In the ParaView window, follow these exact steps:**

1. **Open file:**
   - Click **File** (top menu)
   - Click **Open**
   - Navigate to: `/home/shubh/Droplet-Generator-Microchannel/fluidCase/VTK/`
   - Select: `fluidCase_*.vtk` (all of them, or just the first one)
   - Click **Open**
   - Click **Apply** button (bottom right)

2. **Color by water phase:**
   - Look for dropdown that says "Solid Color"
   - Click it and select: `alpha.water`
   - This shows blue for water, white for oil

3. **Isolate just the droplet:**
   - Click **Filters** (top menu)
   - Click **Threshold**
   - Set **Scalar:** `alpha.water`
   - Set **Lower threshold:** `0.5`
   - Set **Upper threshold:** `1.0`
   - Click **Apply**
   - This shows ONLY the water droplet (blue)

4. **Adjust view:**
   - Rotate view to see side profile of pipe
   - Scroll to zoom in on droplet
   - Click play button (bottom) to see animation

### **Step 4: Save as Animation**

1. Click **File** → **Save Animation**
2. Choose location: `/home/shubh/Droplet-Generator-Microchannel/`
3. File name: `droplet_transport`
4. File format: 
   - Option A: **PNG image series** (creates individual frames)
   - Option B: **Animated GIF** (single file, easier to use)
5. Set resolution: **1920 x 1080** (or 1280 x 720 for smaller file)
6. Click **Save**
7. Wait for rendering (~1-2 minutes)

### **Step 5: Verify animation**

```bash
# Exit ParaView (close window)
# Back in WSL terminal:

ls -lh droplet_transport.gif
# Should show file with size > 1 MB

# (Optional) Play it to verify
gifsicle droplet_transport.gif | head -5
```

✅ **DONE!** Animation created. Continue to Part 3.

---

## 🖼️ PART 3: Create System Schematic (10 minutes)

### **What it does:**
Create a simple diagram showing the pipe geometry and setup

### **Option A: Hand-draw and photograph**

```bash
# Simple approach - draw on paper, take photo
# Requirements: paper, pen, phone camera, 5 minutes
# Steps:
# 1. Draw horizontal rectangle (pipe)
# 2. Draw small circle inside (droplet, blue)
# 3. Add arrow showing flow direction (→)
# 4. Label: "50 mm length", "2 mm radius", "0.4 mm wall"
# 5. Label: "Inlet u=0.30 m/s" on left
# 6. Label: "Outlet p=0 Pa" on right
# 7. Take clear photo
# 8. Name it: system_schematic.jpg
```

### **Option B: Use PowerPoint (5 minutes)**

```bash
# If using PowerPoint on Windows:
# 1. Open PowerPoint
# 2. Insert → Shapes → Rectangle
# 3. Draw rectangle (50mm long, 4mm tall)
# 4. Insert → Shapes → Circle
# 5. Draw circle inside (droplet, color blue)
# 6. Insert → Text Box
# 7. Add labels with dimensions
# 8. File → Export as Picture → PNG
```

### **Option C: Use draw.io (online, free)**

```bash
# In web browser: https://draw.io
# Create diagram with shapes:
# - Rectangle = pipe
# - Circle = droplet
# - Arrows = flow
# - Text = labels
# Export as PNG
```

**Result:** You should have `system_schematic.png` (or .jpg)

✅ **DONE!** Schematic created. Continue to Part 4.

---

## 💾 PART 4: Copy Files to Windows Desktop (2 minutes)

### **What it does:**
Move all visuals from WSL to Windows so you can use them in PowerPoint

### **Commands in WSL terminal:**

```bash
# Create Desktop folder for presentation
mkdir -p /mnt/c/Users/space/Desktop/Presentation_Visuals

# Copy all plots
cp -r /home/shubh/Droplet-Generator-Microchannel/presentation_visuals/* \
  /mnt/c/Users/space/Desktop/Presentation_Visuals/

# Copy animation
cp /home/shubh/Droplet-Generator-Microchannel/droplet_transport.gif \
  /mnt/c/Users/space/Desktop/Presentation_Visuals/

# Copy schematic
cp /home/shubh/Droplet-Generator-Microchannel/system_schematic.* \
  /mnt/c/Users/space/Desktop/Presentation_Visuals/

# Verify all files
ls -lh /mnt/c/Users/space/Desktop/Presentation_Visuals/
```

**Expected files in Windows Desktop folder:**
```
Presentation_Visuals/
├── wall_deformation.png
├── velocity_profile.png
├── hoop_stress_validation.png
├── dimensionless_numbers.png
├── droplet_transport.gif
└── system_schematic.png
```

✅ **DONE!** Files copied. Now build PowerPoint.

---

## 📊 PART 5: Build PowerPoint Presentation (6 minutes)

### **What it does:**
Create 9-slide presentation with your visuals

### **In Windows, open PowerPoint:**

**Slide 1 - Title**
```
Title: "Droplet Transport in Flexible Microchannel"
Subtitle: "OpenFOAM Fluid-Structure Interaction Simulation"
Background: Use droplet_transport.gif as background (optional)
```

**Slide 2 - System Overview**
```
Title: "System Design"
Content: Insert system_schematic.png
Add text annotations:
  - Pipe length: 50 mm
  - Inner radius: 2 mm
  - Wall thickness: 0.4 mm
  - Material: Silicone rubber
```

**Slide 3 - Physics**
```
Title: "Flow Regime Analysis"
Content: Insert dimensionless_numbers.png
Bullet points:
  - Reynolds = 600 → Laminar flow
  - Capillary = 0.002 → Surface tension dominates
  - Strain = 0.3% → Linear elasticity valid
```

**Slide 4 - Main Result**
```
Title: "Droplet Transport Animation"
Content: Insert droplet_transport.gif (or .mp4)
Text: "Water droplet transported through pipe at 0.20 m/s"
Note: Embed GIF in slide so it plays in presentation mode
```

**Slide 5 - Flow Validation**
```
Title: "Velocity Profile Validation"
Content: Insert velocity_profile.png
Text: "CFD results match analytical Poiseuille solution"
```

**Slide 6 - Wall Deformation**
```
Title: "Wall Deformation Over Time"
Content: Insert wall_deformation.png
Text: "Wall expands 6 micrometers (0.3% strain)"
```

**Slide 7 - Structural Analysis**
```
Title: "Stress Analysis - Safe Design"
Content: Insert hoop_stress_validation.png
Text: "Wall stress 7.5 kPa << Yield 1 MPa (Safety factor: 133×)"
```

**Slide 8 - Results Summary**
```
Title: "Key Results"
Create table:
  Parameter               Value           Status
  Droplet Velocity        0.20 m/s        ✓
  Reynolds Number         600             ✓ Laminar
  Capillary Number        0.002           ✓ Stable
  Wall Stress             7.5 kPa         ✓ Safe
  Wall Expansion          6 μm            ✓ Small
  Simulation Runtime      12 min (4 CPUs) ✓ Efficient
```

**Slide 9 - Conclusions**
```
Title: "Conclusions"
Bullet points:
  ✓ FSI simulation successfully validates design
  ✓ Wall deformation is small (0.3% strain)
  ✓ Stress is far below failure threshold (133× safety factor)
  ✓ All physics in expected regime (laminar, stable droplets)
  ✓ Device is ready for fabrication
```

### **Save presentation:**
```
File → Save As → "Droplet_Presentation.pptx"
Location: C:\Users\space\Desktop\
```

✅ **DONE!** Presentation created.

---

## 🔄 IF SOMETHING GOES WRONG

### **Python script fails:**
```bash
# Install missing package
pip3 install matplotlib numpy

# Try again
python3 generate_all_visuals.py
```

### **ParaView won't open:**
```bash
# Check if installed
which paraview

# If not found, install
sudo apt-get update
sudo apt-get install paraview

# Then try again
paraview &
```

### **foamToVTK fails:**
```bash
# Make sure you're in the right directory
pwd  # Should be: /home/shubh/Droplet-Generator-Microchannel/fluidCase

# Check if log.foamRun exists (proof simulation ran)
ls -l log.foamRun

# If not, simulation didn't complete - run it first
foamRun -solver incompressibleVoF -parallel
# or
mpirun -np 4 foamRun -solver incompressibleVoF -parallel
```

### **Can't copy to Windows:**
```bash
# Make sure /mnt/c exists (mounted Windows drive)
ls /mnt/c/

# If not, mount it
sudo mount -t drvfs C: /mnt/c

# Then copy
cp file.png /mnt/c/Users/space/Desktop/
```

---

## 📋 COMPLETE CHECKLIST

### **Plots (Automated)**
```bash
cd /home/shubh/Droplet-Generator-Microchannel
python3 generate_all_visuals.py
```
- [ ] wall_deformation.png created
- [ ] velocity_profile.png created
- [ ] hoop_stress_validation.png created
- [ ] dimensionless_numbers.png created

### **Animation (ParaView)**
```bash
cd fluidCase
foamToVTK
paraview &
# (Follow GUI steps above)
```
- [ ] VTK files generated
- [ ] ParaView opened successfully
- [ ] Data colored by alpha.water
- [ ] Threshold filter applied (0.5-1.0)
- [ ] Animation saved as droplet_transport.gif

### **Schematic (Hand-drawn or PowerPoint)**
- [ ] System schematic drawn/created
- [ ] system_schematic.png saved

### **Copy to Windows**
```bash
cp -r presentation_visuals /mnt/c/Users/space/Desktop/Presentation_Visuals/
cp droplet_transport.gif /mnt/c/Users/space/Desktop/Presentation_Visuals/
cp system_schematic.png /mnt/c/Users/space/Desktop/Presentation_Visuals/
```
- [ ] All files copied to Windows
- [ ] Verified in C:\Users\space\Desktop\Presentation_Visuals\

### **PowerPoint (Manual)**
- [ ] Presentation created (9 slides)
- [ ] All images inserted
- [ ] GIF embedded and plays
- [ ] Text and bullets added
- [ ] Saved as Droplet_Presentation.pptx

---

## 🎓 FINAL VERIFICATION

```bash
# In Windows (or check folder visually):
# C:\Users\space\Desktop\Presentation_Visuals\

# Should contain:
# - wall_deformation.png
# - velocity_profile.png
# - hoop_stress_validation.png
# - dimensionless_numbers.png
# - droplet_transport.gif (or .mp4)
# - system_schematic.png
```

Then:
- [ ] Open Droplet_Presentation.pptx
- [ ] Check all 9 slides load correctly
- [ ] Verify GIF plays in slideshow mode
- [ ] Print one backup copy
- [ ] Test presentation on projector (if possible)

---

## 🚀 YOU'RE READY!

If all checkmarks are done, you have everything needed for your presentation:
✅ Professional plots  
✅ Animated droplet  
✅ System diagram  
✅ Complete PowerPoint  
✅ Backup documentation (cheat sheet, quick reference)

**Good luck! 🎓**

---

## 📞 QUICK COMMAND SUMMARY (Copy & Paste)

```bash
# 1. Generate plots
cd /home/shubh/Droplet-Generator-Microchannel
python3 generate_all_visuals.py

# 2. Prepare animation data
cd fluidCase
foamToVTK

# 3. Open ParaView
paraview &

# 4. Copy to Windows
mkdir -p /mnt/c/Users/space/Desktop/Presentation_Visuals
cp -r presentation_visuals/* /mnt/c/Users/space/Desktop/Presentation_Visuals/
cp droplet_transport.gif /mnt/c/Users/space/Desktop/Presentation_Visuals/
cp system_schematic.png /mnt/c/Users/space/Desktop/Presentation_Visuals/

# 5. Verify files
ls -lh /mnt/c/Users/space/Desktop/Presentation_Visuals/
```

Then open PowerPoint on Windows and follow Part 5 above.
