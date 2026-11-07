# StereoModel
Test 3D model in Glasses-free

StereoModel shows a 3D model in a Gorilla3D viewport through the Peardox
orbital camera, as the first step towards showing it on a glasses-free
(autostereoscopic) display. Delphi 13, FireMonkey, Gorilla3D 1.5.3.

## Layout

| Folder | What is in it |
|---|---|
| `src/` | The program: `StereoModel.dpr` / `.dproj`, forms in `src/ui/` |
| `lib/` | The Peardox components, kept apart because other projects reuse them |
| `lib/icons/` | Their palette icons (`.ico`, and the `.svg` sources in `svg/`) |
| `models/` | Test models: `uvcube.glb` (a cube with a UV test texture) and `Mage.glb` |
| `tools/` | Scripts: the palette icons, and the PasDoc reference |
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

Methods: `FitToBounds(Model)` frames a model for the current angles,
`FitToBoundsMax(Model)` for every angle (orbit freely afterwards),
`Orbit`, `Zoom` (works in every projection), `LookAt` and `MoveCenterTo`.
`Camera` gives the camera itself (`TPeardoxOrbitalGorillaCamera`) for
anything else, and `Light` the headlight.

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

The runtime and design packages are still to come; until then the
component is created in code.

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

Build and run `src/StereoModel.dproj`. The form makes the orbital camera
in code, with its headlight, and once it is showing loads
`models/uvcube.glb`, centres it, turns it 180 degrees about X so it stands
upright (glTF's up is +Y, FMX's -Y; Sprite3D does the same) and frames it.
It looks for the model in a `models` folder beside the program, in the bundle's `Resources` on macOS, in the
documents folder on Android and iOS, then in the folders above the program,
which finds the repository's `models` folder when run from the IDE on
Windows. The status line at the bottom says which file it loaded, or every
folder it looked in.

Mouse: left-drag orbits, the wheel zooms, right-click (or Control-click)
goes back to the starting view.
