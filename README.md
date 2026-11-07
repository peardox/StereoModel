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
| `models/` | Test models: `uvcube.glb` (a cube with a UV test texture) and `Mage.glb` |
| `packages/` | The Peardox packages: `Peardox` (runtime) and `dclPeardox` (design time) |
| `tools/` | Scripts: the packages, the palette icons, and the PasDoc reference |
| `delphi-neon/` | Neon, the JSON library (submodule) |
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

### Palette icons

`python3 tools/gen_icons.py` draws `lib/icons/<Class>.ico` (needs Pillow
and `rsvg-convert`); `python3 tools/gen_icon_res.py` packages them into
`lib/Peardox.Reg.dcr` (standard library only). Never edit the `.dcr` by hand.

### Packages and installing

The components are built into two packages, like G3DGames/TSteamAPI's:

| Package | What it is |
|---|---|
| `packages/Peardox` | Runtime: every component unit in `lib`. It requires `rtl`, `fmx` and Gorilla3D's runtime package (`Gorilla3D_Delphi_13_2_0_Florence`). Its DCUs go to Delphi's Dcp folder, `$(BDSCOMMONDIR)\Dcp\<platform>` (`\Dcp` alone for Win32), beside `Peardox.dcp`, which is on the IDE's default Library path, so **a program that uses a Peardox component needs no search path**. Win32, Win64, macOS (x64, ARM64), Linux64, Android (32 and 64-bit), iOS device and simulator; not WinARM64EC, for which Gorilla3D is not installed |
| `packages/dclPeardox` | Design time: `lib/Peardox.Reg.pas`, which puts the components on the **Peardox** palette page with their icons. Win32 (the 32-bit IDE) and Win64 |

To install, in `StereoGroup.groupproj`:

1. Build **Peardox** for every platform you compile programs for, and
   always for **Win32**, which the 32-bit IDE's design package needs.
   Debug and Release write to the same Dcp folder: the last build wins.
2. Build **dclPeardox** (Win32) and **Install** it (right-click in the
   Projects window). The Peardox page appears on the palette.
3. Build `StereoModel`. It lists no `lib` unit and has no path to `lib`:
   `Peardox.OrbitalCamera` comes from the Dcp folder.

After a change in `lib`, rebuild Peardox for each platform used before
building a program; after a change to `lib/Peardox.Reg.pas` or the icons,
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
nearer along the line of sight, the camera staying put (the status line
shows the depth; orbit afterwards to see the new centre); the wheel zooms
(stopping at the cube's nearest face, never inside it). A click on its own
does nothing. A window resize refits the view, putting the target back on
the cube.