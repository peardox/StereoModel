# StereoModel
Test 3D model in Glasses-free

StereoModel shows a 3D model in a Gorilla3D viewport through the Peardox
orbital camera, as the first step towards showing it on a glasses-free
(autostereoscopic) display. Delphi 13, FireMonkey, Gorilla3D 1.5.3.

## Layout

| Folder | What is in it |
|---|---|
| `src/` | The program: `StereoModel.dpr` / `.dproj`, forms in `src/ui/`, helpers in `src/common/` (`FmxLinuxMenu`, an unchanged copy from G3DGames/TSteamAPI: the main menu as an FMX menu bar on desktop Linux) |
| `lib/` | The Peardox components, kept apart because other projects reuse them |
| `lib/icons/` | Their palette icons (`.ico`, and the `.svg` sources in `svg/`) |
| `models/` | Test models: `uvcube.glb` (a cube with a UV test texture), `Mage.glb`, and `SRDemoScene.glb` / `SRDemoSceneNoWall.glb` (SRDelphiFMX's demo scene, written by `tools/gen_srdemo_scene.py`) |
| `packages/` | The Peardox packages: `Peardox` (runtime) and `dclPeardox` (design time) |
| `tools/` | Scripts: the packages, the palette icons, and the PasDoc reference |
| `delphi-neon/` | Neon, the JSON library (submodule), compiled into the PeardoxLeiaSR package |
| `SRDelphiFMX/` | peardox/SRDelphiFMX (submodule, never changed here): LeiaSR from Delphi, with the C++ bridge, `SRBridge.dll` in its `dll` folder |
| `FastMM5/` | FastMM5, the memory manager on Windows (submodule); Debug builds report leaks |

## Peardox components

Registered on the **Peardox** page of the palette by `lib/Peardox.Reg.pas`
(design-time). They are FireMonkey components and show only while an FMX
form is designed. Every Peardox type is named `TPeardox...`.

### TPeardoxOrbitalCamera (`lib/Peardox.OrbitalCamera.pas`)

An orbit camera for a `TGorillaViewport`. It is non-visual: drop it on the
form, or create it in code, and set **Viewport**. At run time it builds the
camera in that viewport and makes it the viewport's camera; at design time
it only keeps its settings.

| Property | |
|---|---|
| `Viewport` | The `TGorillaViewport` the camera goes in |
| `Headlight` | True (default): a point light rides on the camera, lighting whatever is in view. False: no light is made; add the scene's lights yourself |
| `Azimuth`, `PolarAngle`, `Roll` | The camera's angles in degrees round the orbit centre. `PolarAngle` is not limited, so the camera can go over the poles |
| `Distance` | From the orbit centre (default 10) |
| `FOV` | Field of view in degrees (default 45) |
| `ProjectionMode` | Perspective (default), orthographic or isometric |
| `OrthoHeight`, `OrthoWidth` | The view's size in orthographic and isometric mode; 0 leaves Gorilla3D's own height, and a width of 0 follows the height |
| `Locked` | While True nothing moves or turns the camera |
| `Subject` | A model the camera may not go inside: the wheel, `Distance`, orbits and angles stop at the face nearest the camera (its bounding box, plus a gap of twice the viewport's near plane) |

Methods: `FitToBounds` frames a subject for the current angles, and
`FitToBoundsMax` for every angle (orbit freely afterwards). Both work as
Sprite3D frames a model: the subject is centred in the view and the target
(the orbit centre) is put on its turning axis, the up axis through its
centre of rotation, so the camera turns about the subject's own axis.
`FitToBounds` makes the subject as large as it goes for the current angles;
`FitToBoundsMax` frames the ball round it, centred on that axis halfway up,
so no angle takes any of it out of view. Each sets the target and
`Distance`, or the orthographic size, from the angles, `FOV` and projection
as they are, and takes the subject as:

- a model: `FitToBounds(Model)`, turning about its `RotationCenter`;
- a group of models: `FitToBounds([Model1, Model2])`, the box holding them
  all, turning about its middle;
- a box in the scene's space: `FitToBounds(Box)`, turning about its middle;
- a box in an object's own space, such as part of a model:
  `FitToBounds(Box, Model)`, turning about the model's `RotationCenter`.

A box has no centre of rotation of its own, so the box and group forms
also take one: `FitToBounds(Box, Center)`, `FitToBounds(Box, Model, Center)`
(in the model's coordinates), `FitToBounds([Model1, Model2], Center)`.
All take an optional margin. Also: `SetTargetDepth` (moves the target
nearer or deeper along the line of sight without moving the camera: the
picture is unchanged, the point the camera orbits, and `Distance`, change;
for the stereo pair this is the depth that will sit on the display's
surface), `Orbit`, `Zoom` (works in every projection), `LookAt`,
`MoveCenterTo`, and `MinimumDistance` (how near the camera may come along
its present line without entering `Subject`).

It is a component of its own rather than the camera itself because the
camera hangs under three pivots, one per angle, that are not stored: as a
camera placed on a form it would never be written to the `.fmx`.

The camera came from Sprite3D's `Sprite3DCamera` unit
(<https://github.com/peardox/Sprite3D>), renamed so both can be used in one
program.

### LeiaSR, glasses-free 3D (package PeardoxLeiaSR)

The components for LeiaSR (Simulated Reality) eye-tracked displays, after
peardox/SRDelphiFMX, in a package of their own. LeiaSR is Windows 64-bit
only, but the units compile everywhere, so the package and the programs
using it stay cross-platform; elsewhere nothing is offered. A program needs
`SRBridge.dll` (SRDelphiFMX's C++ bridge to the SR weaver) beside its
executable: StereoModel's Win64 post-build step copies it from the
`SRDelphiFMX` submodule.

| Unit | |
|---|---|
| `Peardox.LeiaSR` | `TPeardoxLeiaSR` (made in code for now): `Installed` (Win64 and the LeiaSR runtime present; where it is not, `Start` does nothing and raises no event, so a program can hide everything to do with glasses-free 3D), `Start` (checks for the SR service and display on a background thread, so the window never freezes, then starts SR with the bridge's window over `Control`), `Stop`. While running it logs the SR platform, the display, where `Control` lies on it in millimetres, SR's events and the tracked eyes (`OnLog`, `OnEyes`). `OnProblem` says why it could not start (no service, no display, no bridge). It weaves nothing itself: a renderer sets `Weaving` (the bridge's window over `Control`, the lens on) and hands it each side-by-side frame with `SubmitViews`; `UpdateEyes` reads the eyes just before a frame |
| `Peardox.LeiaSR.Settings` | `TPeardoxLeiaSRSettings`: the viewer's and display's settings, as SRDemoFMX keeps them (use glasses-free 3D, eye separation, look-around, latency, lens mode, full screen), in `LeiaSR.json` in the `Peardox` folder of the user's application data (`%APPDATA%\Peardox` on Windows), shared by every Peardox program |
| `Peardox.LeiaSR.Api` | The bridge's imports, copied from SRDelphiFMX's `SRBridge.Api` (keep them in step), declared on Windows only |
| `Peardox.Storage` | `AppDataFolder` and `TPeardoxJsonSettings` (published properties to and from a JSON file with Neon), from Sprite3D's `Sprite3DStorage` |

### Palette icons

`python3 tools/gen_icons.py` draws `lib/icons/<Class>.ico` (needs Pillow
and `rsvg-convert`); `python3 tools/gen_icon_res.py` packages them into
`lib/Peardox.Reg.dcr` (standard library only). Never edit the `.dcr` by hand.

### Packages and installing

The components are built into two packages, like G3DGames/TSteamAPI's:

| Package | What it is |
|---|---|
| `packages/Peardox` | Runtime: every component unit in `lib`. It requires `rtl`, `fmx` and Gorilla3D's runtime package (`Gorilla3D_Delphi_13_2_0_Florence`). Its DCUs go to Delphi's Dcp folder, `$(BDSCOMMONDIR)\Dcp\<platform>` (`\Dcp` alone for Win32), beside `Peardox.dcp`, which is on the IDE's default Library path, so **a program that uses a Peardox component needs no search path**. Win32, Win64, macOS (x64, ARM64), Linux64, Android (32 and 64-bit), iOS device and simulator; not WinARM64EC, for which Gorilla3D is not installed |
| `packages/PeardoxLeiaSR` | Runtime: the LeiaSR units in `lib` and the Neon units they need. It requires `rtl`, `dbrtl` and `fmx`, not Gorilla3D or Peardox. Its DCUs, Neon's included, go to the same Dcp folders, so a program needs no path to Neon either; a program must then not also compile Neon from source (no `delphi-neon` search path), or the compiler can find two builds of one unit. Same platforms as Peardox |
| `packages/dclPeardox` | Design time: `lib/Peardox.Reg.pas`, which puts the components on the **Peardox** palette page with their icons. Win32 (the 32-bit IDE) and Win64 |

To install, in `StereoGroup.groupproj`:

1. Build **Peardox** and **PeardoxLeiaSR** for every platform you compile
   programs for, and always for **Win32**, which the 32-bit IDE's design
   package needs. Debug and Release write to the same Dcp folder: the last
   build wins.
2. Build **dclPeardox** (Win32) and **Install** it (right-click in the
   Projects window). The Peardox page appears on the palette.
3. Build `StereoModel`. It lists no `lib` unit and has no path to `lib`:
   `Peardox.OrbitalCamera` and `Peardox.LeiaSR` come from the Dcp folder.

After a change in `lib`, rebuild the package holding it (Peardox or
PeardoxLeiaSR) for each platform used before building a program; after a change to `lib/Peardox.Reg.pas` or the icons,
rebuild and reinstall dclPeardox too. A program failing with *F2613 Unit
'Peardox.OrbitalCamera' not found* has not got Peardox built for the
platform it is compiling for (new projects start on Win32).

`python3 tools/gen_packages.py` writes the packages. A new component unit
in `lib` must be added to its list, or the script stops. The `.dpk` files
are always rewritten from it; a `.dproj` only when missing, as the IDE's
re-saved copy then counts (`--force` overwrites it).

## The reference (PasDoc, optional)

`tools\pasdoc.bat` (run from anywhere, Windows) writes the PasDoc reference
as HTML in `docs\html\` and as HTML Help in `docs\chm\`, each with `api\`
(the Peardox components in `lib`, without the design-time `Peardox.Reg`)
and one folder per program (`StereoModel`: its `.dpr`, its forms and the
`lib` units it uses). Programs are found, not listed: every
`src\<program>.dpr` gets its own reference. It needs `pasdoc` on the PATH
(or `PASDOC` set to its full path; releases at
<https://github.com/pasdoc/pasdoc/releases/>), and, for the `.chm` files,
Microsoft HTML Help Workshop's `hhc.exe` (or `HHC` set to its full path).
`docs\html` and `docs\chm` are deleted first, and git ignores both. The view
is Windows 64-bit, Release. `tools/pasdoc-dark.css` (HTML, dark when the
system is) and `tools/pasdoc-chm-dark.css` (`.chm`, always dark) are
appended to PasDoc's own stylesheet; `set PASDOC_DARK=0` leaves them out.
Adapted from peardox/SRDelphiFMX.

## Running the test

Build and run `src/StereoModel.dproj` (after installing the packages,
above). The orbital camera, `PeardoxOrbitalCamera1`, is on the form with
its headlight; once the form is showing it loads
`models/uvcube.glb`, centres it, turns it 180 degrees about X so it stands
upright (glTF's up is +Y, FMX's -Y; Sprite3D does the same) and frames it.
It looks for the model in a `models` folder beside the program, in the
bundle's `Resources` on macOS, in the documents folder on Android and iOS, then in the folders above the program,
which finds the repository's `models` folder when run from the IDE on
Windows. The status line at the bottom says which file it loaded, or every
folder it looked in.

File, Open (desktop) loads another model in place of the one shown. Its
filter lists every format Gorilla3D has a loader for in the program, read
from Gorilla3D's own registry: glTF / GLB, OBJ, FBX, Collada, STL, PLY, USD,
Babylon and Gorilla3D's G3D (one loader unit each, in `StereoModelMain`'s
uses). Not included: the Mayo CAD loaders and SketchUp's, which need
external libraries, and Sketchfab's, which loads from the web.

Mouse: left-drag orbits; right-drag up or down moves the target deeper or
nearer along the line of sight, the camera staying put (orbit afterwards
to see the new centre). The target's depth is the plane that will lie on the
display's glass, so the status line also gives the model centre's Z against
it, along the line of sight: below 0 it is in front of the glass (out of the
screen: drag up, past the model's own depth), above 0 behind it; while
LeiaSR runs, in millimetres too. The wheel zooms
(stopping at the cube's nearest face, never inside it). Each notch moves the
camera along its line of sight by a share of its distance from the model,
not from the target, so the steps stay even wherever the target's depth has
been put; with the target in front of the model the camera stops just short
of it. A click on its own
does nothing. A window resize refits the view, putting the target back on
the cube.

Everything the status line shows is also written, with the time, to
`StereoModel.log` beside the executable (the documents folder on macOS and
mobile), flushed line by line; a run that ended normally finishes with
`Log closed normally`. The first line says whether a debugger was attached
(timings under one are far slower). The previous run's log is kept as
`StereoModel.prev.log`.

At start the program loads `models/SRDemoSceneNoWall.glb` and shows it
from the owner's test view: azimuth 52, inclination 75, roll 0, the camera
42 from the target (`TEST_VIEW_*` in `StereoModelMain`); Home goes back to
it. `models/SRDemoScene.glb` is SRDelphiFMX's demo scene as a model, for
File, Open: the 11 x 11 grid of spheres, coloured by depth (red nearest, white on
the middle row, blue furthest, the centre one green), the two columns of
three cubes, which spin a turn every 8 s (the model's first animation,
started when it loads, if Gorilla3D plays glTF node animations), and the
back wall. `SRDemoSceneNoWall.glb` leaves the wall out, so the framed view
is not made big enough to hold it. `python3 tools/gen_srdemo_scene.py`
writes both (standard library only).

The window's title always shows the view as numbers: the camera's azimuth,
inclination (0 level, +90 above looking down) and roll in degrees, the target
depth and the model centre's Z against the glass (below 0: in front of it),
and each drag writes them to the status line and the log when it ends
(`View: ...`), to note down for a test scene.

A model with animations plays its first once loaded; the box left of
**Stereo** lists them (as Gorilla3D sorts them, as Sprite3D does) and plays
the one chosen, or none; it is hidden for a model without animations.

Glasses-free 3D: where LeiaSR is installed (a Win64 build on a computer
with the LeiaSR runtime) the **Stereo** button is shown. SR starts once the model has loaded, on a
hidden borderless 3D window, with the lens off; the button is enabled once
it has. Pressed, it shows the 3D window full screen on the SR display, on
top, and weaves the view there (the lens comes on); if the main window is on
the SR display it hides until Stereo is off, on any other monitor it stays
(the button shows pressed). **Esc**, the button again, or Alt+F4 on the 3D
window turn Stereo off: the 3D window hides, the lens goes off, and SR stays
running so the next time is quick. While Stereo is on, the viewport is the
size the display weaves each eye at (its recommended view, 1920 x 1080 on
the owner's display), centred and clipped in the main window, and the drags
and wheel work on the 3D window as on the viewport. Once Stereo is on, the
view is woven (first light,
`src/common/StereoModelEyes.pas`, `TPeardoxGorillaEyes`): each frame the
orbital camera's Gorilla3D camera is moved once per eye, sideways and up or
down by the eye's offset from the view's centre times target depth / eye
distance, turned (both alike, from the midpoint between the eyes), rendered
(`RenderManual`) and captured (`MakeScreenshot`); each picture is shifted
sideways by its eye's half of the separation, which is the off-axis frustum
built from Gorilla3D's symmetric one (a thin black strip at the outer
edges), and the pair goes side by side to `TPeardoxLeiaSR.SubmitViews`; the
camera is put back. The target's depth is the plane on the glass. Frames
are drawn whenever the program is idle, paced by the display's vertical
blank. Each eye is woven no wider than the display's recommended view (1920
pixels on the owner's 4K display): a full-screen 3840-wide picture is
halved as it is copied, a quarter of the bytes to copy and upload. Keys
(once per press, however long the key is held; on Windows through a thread keyboard hook, as SRDelphiFMX's SRDemoFMX does, and only while the main window or the 3D window is active) while testing: **S** swaps the eyes (if near things look far),
**T** switches to toe-in (each camera turned to the target, no strip but
mismatched corners) and back, **X** reverses the shift (reversed is now the
default, from the owner's test), **L** steps the weaver's latency (0, SR's
own, then 1 to 4 frames: how far ahead SR predicts the eyes; our frames are
read back through the CPU, so a frame or two behind), **[** and **]** make
the eye separation 5 mm smaller or larger (both saved in the LeiaSR
settings), **Home** puts the view back, **C** turns the bridge's frame cap
on and off (on: it waits for the SR display's vertical blank after each
frame, which cost 8 fps here; off, the default, it does not; vsync stays on,
so no tearing; saved as `FrameCap` in the LeiaSR settings), **P** writes a snapshot to the log
(one block between `=== SNAPSHOT ===` lines, in the same terms as
SRDelphiFMX's SRDemoFMX writes with its own P: the display, the view on it,
the eyes, the settings, the camera, the world-to-mm scale, the frame rate),
for comparing a view that looks right there with this one, **R** switches
`RenderManual` before each screenshot on and off (the log's timings show
whether `MakeScreenshot` renders by itself). The log gives, once a second,
the frame rate, the time each stage takes, the view size and the offsets.
SR's own lines also log,
the SR platform, the display, where the view lies on it, SR's events and
the eyes once a second. The lens is on exactly while Stereo is, so there is
no lens indicator any more; the log still has SR's LensOn and LensOff.
The target's depth stops at the viewport's far plane: further out, single
precision moves the camera. Where LeiaSR is not
installed the button is hidden. `SRBridge.dll` must be beside the
executable (the Win64 build copies it from `SRDelphiFMX\dll`).