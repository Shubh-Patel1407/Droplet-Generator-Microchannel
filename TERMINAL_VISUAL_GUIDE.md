# Terminal Visual Guide - Know What You're Looking At

## What is a Terminal/CMD?

A terminal (also called command line, console, or CMD) is where you type text commands to control your computer.

- **Windows:** CMD, PowerShell, or WSL terminal
- **Linux/Mac:** Terminal, Bash, or Shell
- **You'll use:** WSL (Windows Subsystem for Linux) terminal

---

## 📍 WSL Terminal - What You See

When you open WSL, you'll see something like this:

```
shubh@Shubh:~/Droplet-Generator-Microchannel$
```

Breaking this down:
```
shubh          = Your username
@Shubh         = Computer name
:~             = You're in home directory (~)
/Droplet...    = Current folder
$              = Ready for input (Linux/WSL prompt)
```

---

## 🎯 COMMAND #1: Navigate to Project

**Type this:**
```
cd /home/shubh/Droplet-Generator-Microchannel
```

**Press:** `Enter` (very important!)

**What you see:**
```
shubh@Shubh:~/Droplet-Generator-Microchannel$
```
(Notice the `~/` changed to show you're in the project folder)

---

## 🎯 COMMAND #2: Generate Plots

**Type this:**
```
python3 generate_all_visuals.py
```

**Press:** `Enter`

**What you see (takes ~5 seconds):**
```
shubh@Shubh:~/Droplet-Generator-Microchannel$ python3 generate_all_visuals.py
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

shubh@Shubh:~/Droplet-Generator-Microchannel$ _
```

✅ **SUCCESS!** If you see the checkmarks (✓), the plots were created!

---

## 🎯 COMMAND #3: Navigate to Fluid Case

**Type this:**
```
cd fluidCase
```

**What you see:**
```
shubh@Shubh:~/Droplet-Generator-Microchannel/fluidCase$
```

---

## 🎯 COMMAND #4: Convert to VTK Format

**Type this:**
```
foamToVTK
```

**Press:** `Enter`

**What you see (takes ~30 seconds):**
```
Reading case: /home/shubh/Droplet-Generator-Microchannel/fluidCase
    Read 121 time directories

Reading field: U
Reading field: p_rgh
Reading field: alpha.water

Writing VTK output
Time = 0.001
Time = 0.002
...
Time = 0.120

shubh@Shubh:~/Droplet-Generator-Microchannel/fluidCase$ _
```

✅ **SUCCESS!** If it completes without errors, you're ready for ParaView.

---

## 🎯 COMMAND #5: Open ParaView

**Type this:**
```
paraview &
```

**Press:** `Enter`

**What you see:**
```
shubh@Shubh:~/Droplet-Generator-Microchannel/fluidCase$ paraview &
[1] 12345

shubh@Shubh:~/Droplet-Generator-Microchannel/fluidCase$ _
```

Then a **ParaView window** opens (a separate graphical window, not in the terminal).

**If you don't see the window:**
- Wait 5 seconds
- Check taskbar
- Or try: `paraview` (without the `&`)

---

## 🎬 ParaView Window - What You See

When ParaView opens, you see:

```
┌─────────────────────────────────────────────┐
│  File Edit View Tools Help                  │
├─────────────────────────────────────────────┤
│                                             │
│  [Left panel]    [Main viewport]   [Right] │
│  Files/Objects   (shows 3D model)  panel   │
│                                             │
├─────────────────────────────────────────────┤
│  [Buttons: Play, Reset, etc.]  [Apply]     │
└─────────────────────────────────────────────┘
```

### **Step 1: Open File**
- Click **File** (top menu)
- Click **Open**
- Navigate to: `/home/shubh/Droplet-Generator-Microchannel/fluidCase/VTK/`
- Select any `.vtk` file
- Click **Open** button

### **Step 2: Apply and Visualize**
- Click **Apply** button (bottom right, green)
- Your simulation data appears in main viewport
- It looks like a gray pipe

### **Step 3: Color by Water**
- Look for dropdown showing "Solid Color"
- Click dropdown
- Select **alpha.water**
- The pipe turns blue/white (blue = water, white = oil)

### **Step 4: Add Threshold Filter**
- Click **Filters** (top menu)
- Look for **Threshold** option
- Click it
- A dialog appears with:
  ```
  Scalar: alpha.water
  Lower: [___] 
  Upper: [___]
  ```
- Type: Lower = 0.5, Upper = 1.0
- Click **Apply**
- Now you see only the blue droplet!

### **Step 5: Play Animation**
- Look at bottom of screen
- Find **Play button** (►)
- Click it
- Watch the droplet move! 🎬

### **Step 6: Save Animation**
- Click **File** (top menu)
- Click **Save Animation**
- Choose filename: `droplet_transport`
- Format: **PNG image series** or **GIF**
- Click **Save**
- Wait 1-2 minutes while it renders...

---

## ✅ ParaView Checklist

As you follow the steps, check these:

- [ ] ParaView window opened
- [ ] File dialog appeared
- [ ] Selected a .vtk file
- [ ] Clicked "Open"
- [ ] Clicked "Apply"
- [ ] Gray pipe visible in viewport
- [ ] Changed color to "alpha.water"
- [ ] Pipe is now blue/white
- [ ] Added Threshold filter
- [ ] Set range 0.5 to 1.0
- [ ] Clicked "Apply" on filter
- [ ] See only blue droplet now
- [ ] Clicked Play button
- [ ] Animation plays (droplet moves)
- [ ] File → Save Animation
- [ ] Selected GIF format
- [ ] Animation saved successfully

---

## 💾 COMMAND #6: Copy to Windows

**Back in WSL terminal** (close ParaView first):

```bash
# Create destination folder
mkdir -p /mnt/c/Users/space/Desktop/Presentation_Visuals

# Copy plots
cp -r presentation_visuals/* /mnt/c/Users/space/Desktop/Presentation_Visuals/

# Copy animation
cp droplet_transport.gif /mnt/c/Users/space/Desktop/Presentation_Visuals/

# Verify
ls /mnt/c/Users/space/Desktop/Presentation_Visuals/
```

**What you see:**
```
shubh@Shubh:~/Droplet-Generator-Microchannel/fluidCase$ mkdir -p /mnt/c/Users/space/Desktop/Presentation_Visuals
shubh@Shubh:~/Droplet-Generator-Microchannel/fluidCase$ cp -r presentation_visuals/* /mnt/c/Users/space/Desktop/Presentation_Visuals/
shubh@Shubh:~/Droplet-Generator-Microchannel/fluidCase$ cp droplet_transport.gif /mnt/c/Users/space/Desktop/Presentation_Visuals/
shubh@Shubh:~/Droplet-Generator-Microchannel/fluidCase$ ls /mnt/c/Users/space/Desktop/Presentation_Visuals/
wall_deformation.png
velocity_profile.png
hoop_stress_validation.png
dimensionless_numbers.png
droplet_transport.gif
system_schematic.png

shubh@Shubh:~/Droplet-Generator-Microchannel/fluidCase$ _
```

✅ **SUCCESS!** All files copied!

---

## 📂 Check Windows Desktop

On your Windows machine, check:
```
C:\Users\space\Desktop\Presentation_Visuals\
```

Should contain:
```
📁 Presentation_Visuals
├── 📄 wall_deformation.png
├── 📄 velocity_profile.png
├── 📄 hoop_stress_validation.png
├── 📄 dimensionless_numbers.png
├── 🎬 droplet_transport.gif
└── 🖼️ system_schematic.png
```

---

## 💡 Common Terminal Tips

### **"Command not found"**
```
shubh@Shubh:~$ python3 generate_all_visuals.py
bash: python3: command not found
```
**Solution:** Install Python
```bash
apt-get update
apt-get install python3
```

### **"Permission denied"**
```
shubh@Shubh:~$ python3 generate_all_visuals.py
Permission denied
```
**Solution:** Add execute permission
```bash
chmod +x generate_all_visuals.py
python3 generate_all_visuals.py
```

### **"No such file or directory"**
```
shubh@Shubh:~$ cd /home/shubh/Droplet-Generator-Microchannel
bash: cd: /home/shubh/Droplet-Generator-Microchannel: No such file or directory
```
**Solution:** Check path is correct
```bash
pwd  # Shows current directory
ls   # Shows files in current directory
# Navigate to correct location
```

### **Script takes too long**
```
shubh@Shubh:~$ python3 generate_all_visuals.py
[waiting... waiting... waiting...]
```
**This is normal!** Python plotting can take 10-30 seconds. Be patient. Don't press Ctrl+C.

---

## 🎮 Keyboard Shortcuts

| Key | What it does |
|-----|-------------|
| `Enter` | Run the command you typed |
| `Ctrl+C` | Stop a running command |
| `Ctrl+L` | Clear the screen |
| `↑ Arrow` | Scroll through previous commands |
| `↓ Arrow` | Scroll forward through commands |
| `Tab` | Auto-complete (type start, press Tab) |
| `Ctrl+A` | Jump to start of line |
| `Ctrl+E` | Jump to end of line |

---

## 🚨 If You Get Stuck

**Stuck in ParaView?** 
- Close the window (X button)
- Terminal will return to prompt

**Stuck in command?** 
- Press `Ctrl+C` to cancel
- Terminal will return to prompt

**Terminal frozen?**
- Press `Ctrl+C`
- Or close terminal window and open new one

**Don't know what to do?**
- Type: `clear` (press Enter) to clear screen
- Start fresh with a simple command: `pwd` (shows current directory)

---

## 📋 FULL COMMAND SEQUENCE (Copy & Paste)

If you want to just copy-paste all at once:

```bash
# 1. Navigate to project
cd /home/shubh/Droplet-Generator-Microchannel

# 2. Generate plots (wait for checkmarks)
python3 generate_all_visuals.py

# 3. Go to fluid case
cd fluidCase

# 4. Convert to VTK (wait for completion)
foamToVTK

# 5. Open ParaView (follows GUI steps above)
paraview &

# 6. (After you save animation in ParaView)
# Copy files to Windows
mkdir -p /mnt/c/Users/space/Desktop/Presentation_Visuals
cp -r ../presentation_visuals/* /mnt/c/Users/space/Desktop/Presentation_Visuals/
cp droplet_transport.gif /mnt/c/Users/space/Desktop/Presentation_Visuals/

# 7. Verify
ls /mnt/c/Users/space/Desktop/Presentation_Visuals/
```

---

## ✅ YOU DID IT!

If you see all the files in the Windows folder, you have successfully:
- ✅ Generated 4 plots automatically
- ✅ Created droplet animation in ParaView
- ✅ Copied everything to Windows
- ✅ Ready to build PowerPoint!

**Next: Open PowerPoint and follow STEP_BY_STEP_COMMANDS.md PART 5** 🎓

---

**You've got this! Don't worry if terminal looks scary - it's just text input/output. One command at a time!** 💪
