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
  FormClose. Owner's first run (branch `stereo`, push 0c89b44, 16:21,
  under the debugger): works - background check 937 ms, then
  srb_Initialize 9.2 s on the main thread (window frozen; SRDemoFMX
  measured ~0.2 s without the debugger and ~20 s to first frame under F9,
  so probably the debugger and NVIDIA's DLL loads: judge without it), SR
  1.36.4, display 3840 x 2160, 596.7 x 335.7 mm, view mm follows the
  window (maximise / restore), UserLost / UserFound / LensOff events
  arrive and the EYES TRACK (separation 63-72 mm) with nothing presented;
  Stop / Start again fine. No 3D, as expected. StereoCam23 (owner: "Log
  to file please"): src/common/StereoModelLog.pas, StereoModel.log beside
  the exe (documents folder on macOS / mobile), the previous run's kept
  as StereoModel.prev.log, every ShowStatus line timed and flushed, ends
  "Log closed normally"; opened first in FormCreate, closed in FormClose.
  Owner's Release run (16:26, still from the IDE: its Event Log shows the
  debugger attached): srb_Initialize again 9.2 s, and the UI was BLURRED -
  the bridge creates its lens hint inside srb_Initialize in the state last
  set with srb_SetLens, which starts as ON (bridge g.lensOn = true), so the
  lens was on through the whole start until our srb_SetLens(0) after it.
  StereoCam23 also calls srb_SetLens(0) before srb_Initialize.
  Owner (16:29): without the debugger "much faster". StereoCam23's log
  (16:31, Debug build, debugger not known): no blur reported; start
  8.9 s (D3D11 device 3.4 s, weaver 4.4 s), and srb_Finalize took 9.3 s
  (7 s of it AFTER "SR context deleted": the bridge releasing its D3D
  objects / child window) - the window freezes for both; to look at if
  it holds without the debugger. A second start was stopped at once
  (clicks queued during the freeze). StereoCam24 (owner, 16:35: "Need
  some indicator to inform when Lens is on"): TPeardoxLeiaSR.LensState
  (lslUnknown / lslOn / lslOff, from the SR LensOn / LensOff events,
  SRB_EVENT_LENS_ON = 14 / _OFF = 15 in the Api unit; unknown after
  Stop) and OnLensChange; the form's FLensLabel left of btnStereo: LENS
  ON red bold, Lens off grey, blank while not running. The log's first
  line now says whether a debugger is attached (IsDebuggerPresent).
  Owner's build of 24 failed (E2003 OnLensChange, LensState, lslOn) only
  because PeardoxLeiaSR had not been rebuilt - the program takes the
  package's DCUs from the Dcp folder. StereoCam25 (owner, 16:40: "Changing
  the depth with RightDrag made wheel zoom behave badly in big jumps"):
  Zoom scales Distance, the distance to the TARGET, so after a deep
  SetTargetDepth (the log had 1186) a notch moved the camera ~110 units.
  The test form's wheel now steps by a share of the camera's distance to
  the MODEL's box centre, moving along the line of sight (Distance minus
  the change), at least MIN_TARGET_SHARE (5%) of Distance left when the
  target is in front of the model; FZoom tracks the model distance. Form
  only, the component's Zoom is unchanged.
  StereoCam26 (owner, 16:47: wants the model to pop out, "a Z of < 0 but
  right drag won't permit this"): the target depth is a distance from the
  camera, always > 0; pop-out is the TARGET DEEPER THAN THE MODEL (drag
  up), which right-drag already allows (the log went to 1186). The status
  line now says it: DepthStatus gives the model centre's Z against the
  glass, Z = depth along the line of sight - target depth (< 0 in front,
  out of the screen), and in mm while LeiaSR runs, at mm per unit =
  view height mm / (2 * target depth * tan(FOV / 2)), FOV taken as
  vertical. Nothing shows on the display until step 1 weaves.
  Owner's log (16:54, debugger attached): (1) the indicator never went
  red - only one LensOff event came (after srb_Initialize), never LensOn,
  yet the owner says the lens WAS on whenever it showed blank (unknown:
  during the start and after Stop). Events only tell of changes once the
  bridge's listener exists, so the start's state and the state after
  srb_Finalize are not seen. The SDK has isLensEnabled(lensHint) and
  newSRContextLensPreference(bool) (SRDelphiFMX's SimulatedReality.Api),
  but the bridge exposes neither: OFFERED, NOT DONE - a bridge export
  srb_GetLensState and creating the context with the lens preference
  (owner's MSVC rebuild of SRDelphiFMX). (2) "a sudden jump and the
  target appeared to move vertically": right drag took the target depth
  to 7 362 159; the camera position is the target less Distance in
  SINGLE precision, so the camera drifted (model depth 4.837 -> 13.479)
  and stayed moved. StereoCam27: SetTargetDepth clamps to the viewport's
  FarPlane (PEARDOX_ORBITAL_MAX_TARGET_DEPTH 10000 without one; drift was
  0.002 at 7000), the status line says AT THE LIMIT there; the lens
  indicator shows "Lens ?" (orange) when unknown instead of blank, and
  is hidden with the button where LeiaSR is not installed.
  Bridge (owner, 16:59: "give me the bridge. I'll build and push"):
  zip SRBridgeLens1 for peardox/SRDelphiFMX - NewContext() makes the SR
  context with newSRContextLensPreference(g.lensOn) (optional export) for
  srb_Initialize and srb_Probe, and a new export srb_GetLensState (SR's
  isLensEnabled; 1 / 0 / -1); SRDelphiFMX's SRBridge.Api, README and
  CLAUDE.md say so; its demos unchanged (they ask for the lens on).
  StereoCam28 here: Peardox.LeiaSR.Api declares srb_GetLensState;
  TPeardoxLeiaSR reads it right after srb_Initialize and at every poll
  (ReadLens, when SRBridgeHasExport says the bridge has it), the events
  still followed too. The submodule SRDelphiFMX must be updated to the
  owner's push for the new dll\SRBridge.dll.
  Owner (17:11) saw "Lens ? in red": that run never started SR (the
  saved choice was off, Stereo not pressed), so unknown was right, but
  dark orange read as red. StereoCam29: LENS ON red bold, Lens off
  green, Lens ? grey. The bridge lens reading is still to be seen.
  Owner's log 17:17: bridge lens reading WORKS ("Lens off (read from
  SR)", context made lens off), tracking with nothing presented.
  Owner (17:20): "Lets move on to doing some drawing" (start timings left
  for a Release run without the debugger).
- STEP 1, first light (StereoCam30): TPeardoxLeiaSR gains Weaving (shows
  the bridge's window, srb_SetVisible, and asks the lens on; cleared by
  Stop), SubmitViews (srb_SubmitViews, BGRA or RGBA, results counted and
  logged once a second) and UpdateEyes. src/common/StereoModelEyes.pas
  (program unit until it works, then lib): TPeardoxGorillaEyes - timer
  16 ms; per eye moves the orbital camera's inner Gorilla camera (child of
  RollPivot, normally at (0, 0, -Distance), no rotation) to
  (OX, OY, -D), OX = dx * D / dz, OY = -dy * D / dz (dx, dy, dz eye mm
  from the view centre; FMX Y down), turned by RotationAngle (pitch, yaw)
  to look at the orbit centre - signs found by Calibrate (four tries
  against AbsoluteDirection vs pivot - camera, logged) - then
  RenderManual (viewport UseFixedFrameRate False, ManualRendering True
  while active, restored by Stop) and MakeScreenshot; camera put back;
  rows copied side by side into FBuffer, SubmitViews. Eyes: tracked with
  LookAround, the saved EyeSeparationMM rebuilt about the midpoint;
  else a fixed viewer 650 mm in front of the view centre. Form: started
  in LeiaSRStarted, stopped in LeiaSRStopped / FormClose; keys S (swap
  eyes) and R (RenderManual before the screenshot or not). UNKNOWNS to
  read from the first log: whether RenderManual / MakeScreenshot work as
  hoped with Gorilla3D's ManualRendering, whether RotationAngle on the
  inner camera is honoured (the calibration scores), the frame rate.
  Owner's first light (17:33, debug + debugger): "Glasses free but not
  nearly as good as demo"; asked: LAG / JUDDER and DOUBLE IMAGES. Log:
  calibration yaw -1 pitch 1 matched 0.99985 (RotationAngle honoured),
  every frame woven; 35 fps windowed (960 x 634: render 2.9, shot 1.8,
  copy 0.8, submit 9 ms - the 16 ms TTimer quantised it), 20-23 fps full
  screen (3840 x 1968: render 7, shot 8.7, copy 7.7, submit 10 ms).
  StereoCam31: frames from Application.OnIdle (Done := False, the old
  handler chained, a 50 ms watchdog timer; NOT TThread.ForceQueue, whose
  posted messages would starve timers, paints and input), paced by the
  bridge's vblank wait; Convergence ecShift (default): both cameras turned
  alike from the eyes' midpoint (parallel to each other), each picture
  shifted by ShiftFor = sign * offset / (D * tan(FOV/2) * W/H) * W/2 px
  (FOV taken as vertical), black strip at the edge - the off-axis frustum,
  removes toe-in's vertical mismatch at the corners; ecToeIn kept. Keys T
  (toggle), X (ShiftSign), S, R. Owner (17:37): "some of the FMX3D fields
  for the projection matrix are strictly private" but the Delphi source is
  there - RTTI can write private fields (TRttiField.SetValue) if we know
  which one Gorilla3D draws with; the shift already gives the off-axis
  pair, a real projection offset would add the eye's own field of view and
  lose the strip.
  Owner (17:47-17:58): X (shift sign -1) "marginally better", T (toe-in)
  "not bad either", still leaning to X; keys reacted too quickly (a held
  key's repeated key-down toggled again). StereoCam32: ShiftSign default
  -1; keys on OnKeyUp by virtual key code (vkS, vkT, vkX, vkR), once a
  press. Eye separation explained: 63 mm (LeiaSR.json default), rebuilt
  about the tracked midpoint; near the glass the on-screen disparity
  matches real 63 mm eyes whatever the window size.
  Log 17:50 (debug + debugger): idle loop 44 fps windowed, 22 fps full
  screen (render 7.2, shot 8.9, copy 8.2, submit 9.5 ms); shifts +-79 px
  at depth 3.0. SUSPICION: X "better" may mean the camera's +X is the
  picture's LEFT - then the eye placement is mirrored too (each eye drawn
  from the other's side: depth inverted, pseudo-stereo) and S+X is the
  right pair; ASKED the owner to test (pop the cube out with right-drag
  up: in front or behind?). StereoCam32 also: each eye decimated to the
  display's recommended view width (DisplayInfo.recommendedViewWidth,
  1920; Step = W div it, every Step-th pixel / row), so full screen copies
  and uploads a quarter.
  StereoCam33 (owner, 18:03: "construct a model Gorilla3D can load from
  the scene in SRDemoFMX ... The cubes are the real show-off"):
  tools/gen_srdemo_scene.py (stdlib) writes models/SRDemoScene.glb and
  SRDemoSceneNoWall.glb from SRDemoFMX/ui/MainForm.pas's numbers: 121
  spheres (d 1.4, step 3, colours per depth row, centre lime green), 6
  cubes (3 units, Y +-4.5/9/13.5, #E8A33D), wall 60 x 40 at Z 18
  (#35507A, two-sided); FMX (x, y, z) written as glTF (x, -y, -z), as the
  program turns models 180 about X; sRGB colours made linear; animation
  "CubeSpin": each cube's rotation about Y keyed every quarter turn over
  8 s. LoadModel now plays the first animation
  (AnimationManager.PlayNextAnimation, TryGetCurrentAnimation logged) -
  untested whether Gorilla3D plays glTF node animations, and whether it
  loops.
  StereoCam34 (owner, 18:09: "display the azimuth and inclination so I
  can work out the proper angles for a definitive test scene"): the form's
  Caption shows ViewText (azimuth, inclination = PolarAngle, roll, target
  depth, model centre Z) after every orbit / depth drag step, wheel notch
  and fit; each drag's end logs "View: ..." (ShowStatus). ModelDepth split
  out of DepthStatus.
  Owner (18:23): the test view - inclination 75, depth 42, azimuth 52,
  roll 0, NoWall - "the 3D really pops out", make it the default; "a LOT
  of ghosting on the balls"; the owner has a cataract in the right eye
  (glasses for this screen), so judging is harder. StereoCam35: TEST_MODEL
  = SRDemoSceneNoWall.glb, TestView after it loads (angles, FitView, then
  Distance := 42, FZoom kept; "depth 42" taken as the camera 42 from the
  target on the scene's axis - CHECK with the owner if it was a moved
  target); Home = TestView for it, ResetView otherwise. For the
  ghosting: TPeardoxLeiaSR.SetLatencyFrames (live srb_SetLatencyInFrames,
  not 0) and keys L (latency 0..4, saved) and [ / ] (eye separation +-5 mm,
  20..90, saved). Ghosting suspects: latency (our frames read back through
  the CPU, 20-40 fps in Debug), big disparities (lenticular crosstalk
  grows with them; white balls on dark show it most), the point-sampled
  halving (shimmer, not ghosting).
  Owner (18:30): "The settings from SRDemoFMX were excellent ... log what
  the settings were ... we may be able to improve this version". Zip
  SRDemoSnap1 for SRDelphiFMX (synced to its push db0a459 first):
  TSRStereoRenderer.LogSnapshot(Note) + SRDemoFMX key P. StereoCam36
  here: TPeardoxGorillaEyes.LogSnapshot(Note) + key P, the same
  quantities: display, view mm / px, eyes tracked and drawn from,
  settings, FOV, target depth, convergence, shifts, the IMPLIED scale
  (2 * D * tan(FOV/2) / view height mm) and with it the glass's distance
  in mm and the eyes' true distance / separation in units beside where
  the cameras really go (D and sep * D / dz), fps. Also the owner: "Your
  RightClick Drag may not be working as I desired. I think the axis it
  moves in should be that from the camera to the viewpoint not any given
  named Axis" - SetTargetDepth already moves along Orientation.Rotate(0,
  0, 1), the camera-to-target line; ASKED what he sees (at inclination 75
  that line is steep, so the target goes mostly up / down in the world;
  while weaving, the eyes' offsets scale with D, so the picture's depth
  and the look-around change).
  Owner (18:45): SRDemoFMX's Release snapshot - 60.0 fps locked (worst
  17-19 ms), every frame woven, eyes 3840 x 2160 each copied on the GPU
  (no decimation), weaver latency 31.7 ms, per-eye off-axis frustum at the
  real eye distance (zoom ~2.14, FOV ~22 deg, shear L -0.26 R -0.19 with
  the viewer ~20 cm left at ~87 cm), scale 0.04936 units/mm, glass 20 units
  from the reference camera; tilt 78 roll 10 scene spans 69 mm out to
  69 mm in.
  Owner (18:52): StereoModel's Release log, no debugger. Small window
  (960 x 634): render 11-12, shot 1.6-2.2, copy 0.8, submit 7.6-9.6 ms,
  29-37 fps. Maximised (3840 x 1968, woven at 1920): render 9.4-15.5,
  shot 8.7, copy 6.8, submit 7-9 ms, 20-25 fps. So shot + copy scale with
  size (option 2, render at the weave size, saves ~11 ms), but render
  (~10 ms for two eyes, Gorilla's per-object cost?) and submit (~8 ms:
  the bridge's frame cap, WaitForVBlank after Present) do not; 8 ms wait +
  25 ms work misses the next blank, so <= 30 fps. StereoCam37: key C
  toggles srb_SetFrameCap (form field FFrameCapOff, re-applied in
  LeiaSRStarted, not saved). Also from the owner: StereoModel is not
  display aware (SRDemoFMX moves its window onto the SR display); this
  run's log did say "The form is on the SR display". The lens state is
  the SR display's own, so LENS ON was true even with our window
  elsewhere - we just never check where the view is before weaving.
  PLAN (owner, 18:52 + 19:04), StereoCam38+: a 2D "launcher" form with
  the controls, and a borderless full-screen output form on the SR
  display hosting the bridge's window, with the Gorilla viewport hidden
  under it at the recommended view (1920 x 1080 = option 2). Two
  monitors: both shown, wherever the user puts the launcher. One
  monitor (or by choice): the launcher hides while the output shows full
  screen, and Esc closes the output and restores the launcher - works
  whatever monitors there are; the user may want either. Weave only while
  the output is on the SR display, else flat with the lens off. Two SR
  displays: ask which (not yet). Owner (19:04): "The purpose of the Stereo
  button has, since the start, to switch into full screen on SR" - so
  btnStereo opens the output form full screen on the SR display (and
  starts weaving); Esc / btnStereo again closes it.
  Owner (19:21): "The cubes don't spin in StereoModel" (so Gorilla3D does
  not drive the glTF node animation, or not visibly); C pressed twice,
  nothing logged - the only frame cap line was the bridge's own. No key
  line (P included) has been logged since keys moved to OnKeyUp at
  StereoCam33: FMX's OnKeyUp never fired here. StereoCam38 (replacing the
  key part of 37): a thread keyboard hook (WH_KEYBOARD, as SRDemoFMX's
  InstallKeyHook / HookKey), local user32 externals (no Winapi.Windows,
  its names hide FMX's), acting on key-down, repeats (lParam bit 30)
  dropped but swallowed, only while GetActiveWindow = the form (not in the
  open dialog), the action queued (ForceQueue, once) to HandleKey.
  IsTestKey lists the keys. Non-Windows keeps OnKeyUp. RemoveKeyHook in
  FormClose and finalization. The render drop (~15.5 -> ~9.4 ms) came at
  17.7, 17.6, 20.8 (Debug) and 14.0 s after the model loaded - not a fixed
  time, and the cubes don't spin, so not the animation's length; cause
  unknown (clocks ramping? Gorilla warming up?).
  Owner (19:27, Release, C pressed 4x): frame cap on - submit 7-9.7 ms,
  23-25 fps, worst 40-43 ms; off - submit 0.9-1.0 ms, 31-32.5 fps, worst
  27-30 ms; repeatable both ways. Off: render 9.2 + shot 8.4 + copy 6.7 +
  submit 0.9 = ~25 ms of a ~31 ms frame (~6 ms outside the four: poses,
  FMX's idle loop). Owner (19:30): "No difference visually". StereoCam39:
  TPeardoxLeiaSRSettings.FrameCap (published, default False, so old
  LeiaSR.json files get off), TPeardoxLeiaSR.SetFrameCap(AOn) (live, logs;
  not saved), srb_SetFrameCap(Ord(FrameCap)) after srb_Initialize, the
  start's settings line shows it; key C = SetFrameCap(not ...) +
  SaveSettings; the form's FFrameCapOff and its Peardox.LeiaSR.Api use
  gone. PACKAGE REBUILD (PeardoxLeiaSR). Next: the two-window layout
  (output form on the SR display, view hidden at the recommended view
  1920 x 1080: shot + copy ~15 -> ~4 ms, so ~50 fps), and time the ~6 ms
  outside the four steps.
  Owner (19:37 log: StereoCam39 works, "frame cap off" after init).
  Owner (19:43), the two-window spec: the window starts with the lens
  off; Stereo = full screen on the SR display, lens on, scene there; Esc
  or the button again stops it (the button has state); started on the SR
  display, the main window hides until Stereo is off; on another screen it
  stays, button pressed; the lens indicator is now useless; Stereo is
  disabled until SR is available, so switching is quick. StereoCam40:
  FOutput (TForm.CreateNew, borderless, black, OnClose = caHide + Leave)
  with FOutputHost (TLayout client, HitTest, the view's mouse handlers) =
  FLeiaSR.Control; SR starts in FirstShown on the HIDDEN FOutput (lib:
  FindFormWindow needs a Handle, no longer Visible; LogStartDetails says
  "hidden for now"), UseGlassesFree3D no longer used by StereoModel;
  OnStarted enables btnStereo, OnStopped / OnProblem disable it.
  EnterStereo: DisplayRect (new lib TPeardoxLeiaSR.DisplayRect), main
  hidden if its centre is on the SR rect, SizeViewForStereo (viewport
  Align None, recommended view in physical px / scene scale, centred,
  ViewLayout clipped; FResizing stops ViewResize's refit both ways),
  FOutput.Show + PlaceOutput (SetWindowPos HWND_TOPMOST to the SR rect,
  again once queued after the DPI change, logged), FEyes.Start.
  LeaveStereo: FEyes.Stop, hide FOutput, Align Client, show main. Key hook
  takes keys while either window is active; Esc = LeaveStereo while on.
  The viewport stays on the main form (not reparented): rendered by
  RenderManual even with the main form hidden - CHECK the eyes are not
  black then. FLensLabel and LeiaSRLensChange gone. PACKAGE REBUILD.
  Owner (19:53): started on the SR display, Stereo -> full screen,
  "completely black image". Log: one frame submitted, then 0 fps (EyePair
  needs WindowSizeMM > 0), and the bridge's window measured "centre
  (-298.4, 167.8) mm, 0.0 x 0.0 mm" = a zero rect at screen (0, 0), what
  GetClientRect / ClientToScreen give for a window that no longer exists:
  FMX had made FOutput's window again at its first Show, destroying the
  bridge's child (srb_Initialize had parent $6D1042). StereoCam41: FSRParent
  = FormToHWND(FOutput) in LeiaSRStarted; EnterStereo logs both handles and,
  if they differ, restarts SR on the shown form (FRestarting keeps
  OnStopped from leaving Stereo; LeiaSRStarted then FEyes.Start while
  FStereoOn); LeiaSRProblem leaves Stereo. Program only, no rebuild. NEXT
  LOG: does the handle change only at the first Show (then later toggles
  are quick) or every time; are the eyes still black with the main form
  hidden.
  Owner (20:02), two logs: started on the SR display - handle changed at
  the first Show only ($551040 -> $561040), SR restarted (0.3 s), then 65-74
  fps, render 5.7, shot 2.5, copy 2.2, submit 1.0 ms; later toggles quick,
  no restart. Started on the widescreen - same restart, 47-56 fps, render
  7.9 ms, and "screen flashes horribly in the launcher window" (FMX painting
  the visible viewport while the eyes move its camera). Also: "The stereo
  button becomes enabled extremely quickly. Is it possible to click before
  SR is ready (first time the screen hung - had to task-manager kill)" - no
  log of the hang. StereoCam42: viewport Visible False while Stereo (FMX
  does not draw it; the eyes' RenderManual + MakeScreenshot still do - CHECK
  not black), FStereoNote label in its place; FirstShown shows FOutput once
  off-screen (-32000) and hides it before FLeiaSR.Start so FMX's re-make
  happens first (restart check kept as a fallback); FStereoWatch: if
  FEyes.WovenFrames (new, SubmitViews = SRB_OK since Start) is still 0
  STEREO_WATCH_MS = 3000 after weaving starts (StartWeaving), Stereo is
  turned off - a black topmost full-screen window can no longer trap the
  user. btnStereo is enabled only from OnStarted, after srb_Initialize has
  returned: it cannot be clicked before SR is ready. Program only.
  Owner (20:10): "black screen... how about a 1x1 gorilla render window for
  2-screen mode?" Log: no restart ($3D0FDA both - the off-screen first
  Show worked), 104-130 fps but render 0.2-0.3 ms: Gorilla3D renders
  nothing for an invisible viewport. A 1x1 viewport would give 1x1 eyes
  (MakeScreenshot is the viewport's size). StereoCam43: viewport stays
  Visible, FStereoCover (TRectangle, Align Contents, opaque $FF202428,
  HitTest False, BringToFront) with FStereoNote (white) over it while
  Stereo is on. If FMX's painting of the covered viewport still costs
  (~7.9 vs 5.7 ms render), next: reparent the viewport onto FOutput under
  the bridge's window, or ask Gorilla's author for an offscreen render
  target.
  Owner (20:13): compile E2003 Combine / GetDocumentsPath - FMX.Objects'
  TPath (the shape) hid System.IOUtils.TPath; qualified in full (43b).
  Owner (20:15): "Still flashes", and render 14 ms, 37 fps: Gorilla3D's
  render shows in the window the viewport is on, cover or not. StereoCam44:
  FRenderForm (TForm.CreateNew, borderless, shown once off-screen and
  hidden in FirstShown like FOutput); while Stereo is on and the main form
  stays in sight, GorillaViewport1.Parent := FRenderForm (Align None, the
  recommended view in its physical px, the form's client sized to it), the
  cover with its note over the empty ViewLayout; back to ViewLayout on
  leave. With the main form hidden (on the SR display) the viewport stays
  put - the proven 70 fps case. CHECK: reparenting a Gorilla viewport
  between forms keeps its context; not black; render ~5.7 ms.
  Owner (20:20): "Good" - StereoCam44 works from the widescreen: SRDemo
  scene 40 fps then 64 fps after the usual drop (render 6.2 ms), Mage.glb
  with its animation 75-84 fps (render 4.2 ms). "Loader needs way to select
  animation if there are any - see sprite3d for examples." StereoCam45:
  FAnimationBox (TComboBox, control strip, Align Right left of btnStereo,
  hidden without animations): (none) + AnimationManager.GetSortedAnimations
  Ids (as Sprite3D's Helpers list them); FillAnimations after a load picks
  the first and plays it; OnChange -> AnimationManager.PlayAnimation(Id), or
  Current.Stop for (none). Sprite3D's frame-exact player (TSprite3D
  AnimationPlayer) not needed here.
  Owner (20:24): "This functionality will eventually be merged into
  Sprite3D so nothing complicated is required" - RULE: keep StereoModel's
  copies of what Sprite3D does (animation choice and the like) minimal.
  Owner (20:29): "can we name [the SR display] when in SR mode". The bridge
  has no name export, but Windows has the EDID name: StereoCam46, lib
  TPeardoxLeiaSR.DisplayName (PEARDOX_LEIASR_DISPLAY_NAME 'the SR display'
  until known), set in LogStartDetails by MonitorNameAt(centre of the SR
  rect): MonitorFromPoint + GetMonitorInfoW (\\.\DISPLAYn), then
  QueryDisplayConfig's active paths, DisplayConfigGetDeviceInfo source name
  to match, target name -> monitorFriendlyDeviceName, the EDID maker code
  (SAM...) decoded and put in front if the name lacks it (MakerName, a small
  table). Own declarations (TPdxDC* records sized as in wingdi.h: path 72,
  source name 84, target name 420 bytes), user32 externals renamed Pdx*.
  Logged "The SR display is ..."; StereoModel's note and Stereo-on status
  use it. PACKAGE REBUILD. Check whether the bridge's child window
  passes mouse messages through (drag on the output vs on the launcher).
- Later: TPeardoxGorillaEyes into lib as a component (with a design
  package); the true off-axis frustum (Gorilla3D's author: projection
  offset); LensMode (lens off over the controls); an OpenGL weaver path
  in the bridge (SR::CreateGLWeaver) for zero copy.
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
