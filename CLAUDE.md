# StereoModel: handover notes for Claude

`README.md` describes the program; this file is for Claude: how the owner
works, the rules for the code, and where the work has got to. Read both.
Keep this file up to date when the rules or the state of the work change.

## Starting a new conversation

1. Clone with submodules:
   `git clone --recurse-submodules https://github.com/peardox/StereoModel.git`
   (branch `main`). The owner's working copy is often ahead of GitHub:
   build on files the owner attaches or pastes.
2. The rules follow Sprite3D's (<https://github.com/peardox/Sprite3D>,
   its `CLAUDE.md`) and G3DGames/TSteamAPI's
   (<https://github.com/G3DGames/TSteamAPI>, the rule sections of its
   `CLAUDE.md`). What is written here takes precedence.
3. References: Gorilla3D 1.5.3 <https://gorilla3d.de/doc/v3/version/v1.5>
   and <https://peardox.com/G3D/>; Neon
   <https://github.com/paolo-rossi/delphi-neon>; FastMM5
   <https://github.com/pleriche/FastMM5>.

## How the owner works

- Delphi 13, FireMonkey, Gorilla3D. Develops on Windows (the 32-bit IDE),
  also builds for macOS, Linux 64-bit, Android and iOS.
- Tests promptly and pastes back logs; make log and status lines say
  exactly what happened.
- **Package rebuilds** (as in TSteamAPI): whenever a delivery changes
  anything a package compiles (`lib/`, `packages/`), say so IN CAPITALS on
  a line of its own, naming the packages and platforms, e.g.
  `====> REBUILD RUNTIME PACKAGE PEARDOX (WIN32 AND WIN64) AND REINSTALL
  DCLPEARDOX <====`, and `====> NO PACKAGE REBUILD <====` when nothing
  needs it.
- **Deliver whole files, never patches**, in a zip of only the new and
  changed files with paths from the repository root; name them, and say
  which earlier zip it replaces or follows. Do not commit or push.
- Do not mention being unable to compile.

## Rules (owner, 7 November 2026)

- **Names**: every type of ours starts with `TPeardox`
  (`TPeardoxOrbitalCamera`, ...); units are `Peardox.<Name>.pas`.
- **Reusable components go in `lib/` at the repository root**, not under
  `src/`; other projects use them. They must not know about this program.
- **Components are registered on the `Peardox` palette page**, with a
  palette icon (`lib/icons`, packaged by `tools/gen_icon_res.py` into
  `lib/Peardox.Reg.dcr`, linked by `lib/Peardox.Reg.pas`).
- **Cross-platform**: Windows, macOS, Linux 64-bit, Android and iOS. No
  platform-specific unit or call without `{$IF}` alternatives, as in
  Sprite3D.
- **Settings are kept in the OS's per-user location** (AppData on Windows,
  Application Support on macOS, `$XDG_CONFIG_HOME` / `~/.config` on Linux,
  the documents folder on mobile), never beside the executable, read and
  written with Neon as in Sprite3D's `TSprite3DJsonSettings`.
- A new component is first made in code to test it; once it works it is
  put on the form in the `.fmx`.
- PasDoc on everything (`//**` comments, private members too), ASCII-only
  sources, two-space indent, as in Sprite3D. Check changed files with
  Sprite3D's checker: `python3 <Sprite3D>/tools/pasdoc_check.py <files>`.
  It looks for @link targets in Sprite3D's own sources only, so here run a
  copy with ROOT set to this repository and its project files taken from
  lib, src/common, src/ui and src/*.dpr, or every @link is reported.
- A new unit goes in both the `.dpr` and the `.dproj` (UTF-8 with BOM).

## Where the work is

- `TPeardoxOrbitalCamera` (`lib/Peardox.OrbitalCamera.pas`): a non-visual
  component wrapping Sprite3D's orbit camera (renamed
  `TPeardoxOrbitalGorillaCamera`), with `Headlight`, the projection
  properties, fits and `Subject`. Registration unit and icon done.
- Packages (StereoCam8, owner 7 November 2026, as TSteamAPI does them):
  `packages/Peardox` (runtime; DCUs to `$(BDSCOMMONDIR)\Dcp\$(Platform)`,
  `\Dcp` for Win32, so programs need no paths) and `packages/dclPeardox`
  (design; Win32 + Win64), written by `tools/gen_packages.py`. Peardox
  requires Gorilla3D's runtime package `Gorilla3D_Delphi_13_2_0_Florence`
  (the name from StereoModel's DCC_UsePackage; it has no WinARM64EC entry,
  so neither has Peardox). StereoGroup.groupproj shows StereoModel,
  Peardox, dclPeardox and builds Peardox, dclPeardox, StereoModel, with
  Dependencies; check they survive the IDE's re-saves (TSteamAPI's group
  lost its Dependencies three times). NOT YET BUILT.
- `src/ui/StereoModelMain` (StereoCam8): the component is on the form,
  `PeardoxOrbitalCamera1` in the `.fmx` with `Viewport = GorillaViewport1`
  (last in the file, so the viewport has loaded first); the `.dpr` /
  `.dproj` no longer list `lib` or search it. The program's WinARM64EC
  target cannot link Gorilla3D or Peardox (no packages there).
- StereoCam8 first install (owner): TPeardoxOrbitalCamera greyed out on
  the palette - no ComponentPlatformsAttribute; StereoCam9 adds it.
- Picture placement (owner, 7 November 2026): tried and REMOVED. Truck /
  pedestal (StereoCam10) moved the camera, so the view changed; a lens
  shift through a GetProjectionMatrix override (StereoCam13) drew nothing,
  because Gorilla3D's context builds the projection from
  GetProjectionSettings, a record of Kind, OrthoHeight and OrthoWidth only;
  moving the viewport control (StereoCam14) was rejected ("it just moves
  the VP"), and so was rendering larger and cropping. StereoCam15 removes
  it all. A true lens shift needs Gorilla3D: TO ASK ITS AUTHOR (owner
  relays) an offset in TGorillaProjectionSettings (OffsetX / OffsetY in
  normalised device units, applied in ToMatrix by adding Offset times the
  w column to the x and y columns), or a way for a camera to supply its
  own matrix. The stereo pair needs the same (off-axis frustum per eye for
  convergence without toe-in). Terms: shift and rise/fall (view camera);
  pan/tilt turn the camera; truck/pedestal move it.
- Dolly zoom: tried and REMOVED (StereoCam15 to 17, owner, 14:54: "take
  that out too - earlier was better"). The arithmetic was right (the
  owner's log: Distance * tan(FOV / 2) held at 2.00 from 45 degrees to 10),
  and FOV and FMX's AngleOfView both changed on the camera, but Gorilla3D
  1.5.3 did not draw with the new lens: first plain zooming (distance
  only), then, with ProjectionChanged called, a slow zoom. Changing the
  field of view at run time does not behave in Gorilla3D as expected -
  ask its author before trying again. StereoCam18 puts the component back
  to StereoCam9's file exactly, and the test form to left-drag orbit, wheel
  zoom, no click resets, right button unused; the test hallway went with
  it.
- StereoCam19 (owner, 15:03): `SetTargetDepth` moves the orbit centre
  along the line of sight with the camera fixed (Distance becomes the
  depth; for the SR display's convergence plane later); test form:
  right-drag vertical, 1.01 per pixel, up deeper. Fit overloads on the
  component for the target space: `FitToBounds` / `FitToBoundsMax` with a
  model, an array of models (union of GetAbsoluteBoundingBox), a box in
  the scene's space, or a box in an object's space (part of a model);
  each sets target and distance from the current angles, FOV and
  projection.
- StereoCam20 (owner, 15:12): File, Open. The filter is built from
  TGorillaLoader.FileTypes (a dictionary keyed by extension, filled by each
  loader unit linked in), so it lists exactly what loads; loaders in
  StereoModelMain's uses: GLB, GLTF, OBJ, FBX, DAE, STL, PLY, USD (owner:
  USD is fine now; Sprite3D left it out for a problem in an earlier
  Gorilla3D), Babylon, G3D. Left out: Gorilla.Mayo.* and Gorilla.SKP
  (external libraries, as far as known) and Gorilla.Sketchfab (web). A new
  model replaces the old only once it has loaded. File menu hidden on
  Android / iOS. src/common/FmxLinuxMenu.pas: an UNCHANGED copy of
  TSteamAPI's (identical in its demos) - never edit it here, re-copy;
  its comments are TSteamAPI's PasDoc style, not ours, so pasdoc_check is
  not run on it. ReplaceMainMenu(Self, MainMenu1) is first in FormCreate.
- StereoCam21 (owner, 15:27, Mage.glb shown with its feet in the middle):
  fits now frame as Sprite3D does (FitCameraToSweep): FitToBounds = the
  box's corners through the inner camera's FitPointsOnAxis, centred, target
  on the turning axis (ASpace's Y through the centre of rotation);
  FitToBoundsMax = the ball round the corners centred ON THAT AXIS halfway
  up (not on RotationCenter itself, which was the cause: Mage's is at his
  feet), every angle safe. Boxes and groups take an optional rotation
  centre (TPoint3D overloads); without it a box or group turns about its
  middle, a box in an object's space about that object's RotationCenter.
- MEMORY LEAK opening several models (owner, 15:27, FastMM5 log): ALL in
  Gorilla3D 1.5.3, none of ours - the FBX loader's parse tree is never
  freed (6848 TFBXNode, 16036 TFBXProperty, 3709 + 6848 TObjectList, 6848
  TDictionary<string, TObjectList<TFBXNode>>, for the FBX files of that
  run), one Gorilla.Imaging.TGA.TTargaFileFormat, and two TStringList
  holding shader source (vertPos, return vec4). For Gorilla3D's author,
  with the projection-offset and field-of-view questions.
- Glasses-free 3D (owner, 7 November 2026, 15:53): the target is LeiaSR,
  through peardox/SRDelphiFMX's bridge. Step 0 (StereoCam22): a NEW
  PACKAGE, PeardoxLeiaSR, separate from the camera package (requires rtl,
  dbrtl, fmx; not Gorilla3D, not Peardox), for "a few" LeiaSR components,
  made in code first and put on forms soon after (then they get a design
  package and icons). Persistent data as SRDemoFMX keeps it, with Neon.
  Units: Peardox.Storage (Sprite3D's Sprite3DStorage, renamed:
  AppDataFolder, TPeardoxJsonSettings), Peardox.LeiaSR.Settings
  (TPeardoxLeiaSRSettings: UseGlassesFree3D, EyeSeparationMM, LookAround,
  LatencyFrames, LensMode, FullScreen; %APPDATA%\Peardox\LeiaSR.json,
  shared by all Peardox programs; SRDelphiFMX's own settings.json is NOT
  shared, as saving it would drop its other members), Peardox.LeiaSR.Api
  (SRDelphiFMX's SRBridge.Api at 9530011, comments as //**, imports under
  {$IFDEF MSWINDOWS} so it compiles everywhere, srb_RenderScene left out;
  keeps the bridge's C names srb_*/TSRB*, like Winapi - keep in step with
  SRDelphiFMX), Peardox.LeiaSR (TPeardoxLeiaSR: Installed, Start with
  srb_Probe on a thread and the answer posted to an AllocateHWnd window,
  srb_Initialize with the bridge's own DX11 device (Gorilla3D is OpenGL,
  so no zero copy), bridge window hidden and lens off since nothing is
  woven yet, then a TTimer polls events, bounds, window mm and eyes, logs
  once a second; Stop; OnLog/OnStarted/OnStopped/OnProblem/OnEyes).
  Neon's 7 units the settings need are compiled into PeardoxLeiaSR (so
  their DCUs are in the Dcp folders), and StereoModel's search path no
  longer has delphi-neon (two builds of one unit otherwise). ONLY ONE
  PACKAGE MAY CONTAIN NEON: if the camera package ever needs settings,
  move Peardox.Storage and Neon into a shared base package. SRDelphiFMX is
  a submodule at the root (the owner adds it:
  `git submodule add https://github.com/peardox/SRDelphiFMX SRDelphiFMX`),
  for its dll\SRBridge.dll, copied beside StereoModel's Win64 exe by its
  post-build step; never change it here. Test form: FLeiaSR made in
  FormCreate (Control = GorillaViewport1), Stereo button (StaysPressed)
  hidden unless Installed, pressed = Start, released = Stop, choice saved;
  auto-start after the first model load when UseGlassesFree3D; Stop in
  FormClose. NOT YET BUILT. To see in the owner's log: whether eye
  positions and SR events come while nothing is presented.
- Next, step 1: first light - Gorilla3D renders each eye (off-axis in the
  view matrix as SRDelphiFMX does, else toe-in), pixels read back and
  uploaded with srb_SubmitViews; convergence = the camera's target depth
  (SetTargetDepth). Later: an OpenGL weaver path in the bridge
  (SR::CreateGLWeaver) for zero copy.
- FastMM5 (submodule, owner 7 November 2026) is the memory manager on
  Windows, first in the `.dpr`; Debug builds report leaks, in full, to
  `StereoModel_MemoryManager_EventLog.txt` beside the executable.
- First Win64 run (owner, 7 November 2026): camera made, uvcube.glb loaded
  and framed (distance 4.84), headlight on; then an ACCESS VIOLATION ON
  EXIT, still there with StereoCam3. The FastMM5 leak dump of that run
  located it (see Lessons); StereoCam4 fixes it. The model also came up
  upside down: StereoCam4 turns it 180 degrees about X as Sprite3D does.
  Owner's re-test (push 5aea8b7): upright, horizontal drag reversed as
  asked (StereoCam6), no word of the exit crash since StereoCam4. Then:
  the wheel could take the camera inside the model. StereoCam7 adds
  `Subject` (a TGorillaModel): every move made through the component keeps
  the camera beyond the face nearest it (ray from the orbit centre through
  the model's box, plus twice the viewport's near plane). The box, not the
  mesh: a model that does not fill its box stops short.
- `tools/pasdoc.bat` (+ the two dark .css files), adapted from
  peardox/SRDelphiFMX: programs are `src\<program>.dpr`, the api run is
  `lib` without `*.Reg`. Not yet run.
- `MainMenu1` is on the form: once it has items, desktop Linux needs
  Sprite3D's `UseFmxMenuBar` swap (see Sprite3D's `CLAUDE.md`, Menus).

## Maybe later (owner, 7 November 2026)

Not to start unless the owner asks for one.

- **Dolly zoom**: tried in StereoCam15 to 17 and removed - Gorilla3D did
  not draw a field-of-view change made while running (see Where the work
  is). Needs Gorilla3D's author first.
- **Convergence pull**, once the stereo pair exists: convergence (the
  depth that sits on the screen surface) and eye separation will be rig
  properties anyway; a pull is changing convergence smoothly during a
  view, bringing the model out of the screen or back behind it.
- **Focus pull**: advised AGAINST. It needs depth-of-field blur from the
  renderer (not checked whether Gorilla3D has one), and on a glasses-free
  display blur fights the depth cues and tires the viewer.

## Lessons learned

- **Gorilla3D teardown**: let the viewport free what is in it. The camera
  and light are owned by the viewport, as in Sprite3D and VirtualGamepad.
  The viewport sends its free notification BEFORE it frees the children
  and owned components it holds: FastMM5's dump of the leaked component
  showed FViewport nil, FLight nil, but FCamera still set, so the
  component's destructor later called into a dead camera. On the
  viewport's notice the component now lets go of the camera and light at
  once and never touches them again.
- **Palette greyed out**: a component class needs
  `[ComponentPlatformsAttribute(...)]` (here `PEARDOX_COMPONENT_PLATFORMS`,
  `pidAllPlatforms` as Gorilla3D's components use); without it the IDE
  takes it as Win32-only and greys it out while the project's active
  platform is Win64 (owner, 7 November 2026). Every new Peardox component
  carries the attribute.
- **Reading a FastMM5 leak dump**: when an exception aborts shut-down,
  TApplication, TPlatformWin, the form and its registry entries all show
  as leaks; they are a symptom. The leaked object of our own class is the
  clue, and its memory dump gives its fields (64-bit TComponent: VMT at
  0, FOwner at 8, FFreeNotifies at $28, interface slots at $68 and $70,
  the class's own fields from $78).
