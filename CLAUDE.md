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
- When a hook asks to commit and push, answer "Noted." and do nothing.
- Never change a submodule from here (SRDelphiFMX, FastMM5, delphi-neon);
  SRDelphiFMX changes go to that repository in their own zip.
- No paths, user names, machine names or credentials in tracked files.

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

## Handover (7 November 2026, 23:17)

Read this section first; "Where the work is" below is the full history,
for when a detail is needed.

### State

- GitHub `main` holds everything up to StereoCam58a (merge d84819d; the
  `stereo` branch is gone). The owner's copy is ahead: StereoCam59 to 62,
  delivered as zips, tested and working (owner, 23:17: "that's good now").
  Ask whether they have been pushed before building on GitHub.
- Submodule SRDelphiFMX at 2c4a2f1 (`srb_GetDevice`, `srb_SetFrameCap`,
  `srb_CopyEyeTexture` / `srb_PresentViews`). Never change it from here.
- StereoCam60 changed the PeardoxLeiaSR package (settings + `Flat`); the
  owner must have rebuilt it.

### How glasses-free 3D works now

- **Two windows.** The launcher (main form, lens off) and the 3D window
  (`FOutput`, borderless, full screen on the SR display, named from its
  EDID). Stereo button / Esc. On the SR display the launcher hides; on
  another monitor it stays, with a cover (`FStereoCover`) over the view
  that takes drags and the wheel. The viewport moves to the hidden
  `FRenderForm` while the launcher is in sight (Gorilla3D otherwise
  flashes in the launcher). SR starts on the hidden 3D window at program
  start; Stereo is enabled once it has.
- **Mouse.** The bridge's child window covers the 3D window;
  `LeiaSRStarted` subclasses it (`PassMouseThrough`, WM_NCHITTEST ->
  HTTRANSPARENT) so drags reach `FOutputHost`. The pointer is hidden over
  the SR display while Stereo is on (`HideCursor`, `FCursorTimer`,
  `ShowCursor`).
- **Per-eye off-axis view** (`TPeardoxGorillaEyes`,
  src/common/StereoModelEyes.pas), SRDemoFMX's geometry done Gorilla3D's
  way. Per frame: `ViewScale` reads the orbit camera's projection through
  `ProjectToView` (FProjX / FProjY = 1 / tan of the half-angles) and sets
  the scale, units per mm, so the view's height on the display is what the
  field of view takes in at the MODEL's depth (`ModelDepth`: the camera's
  Subject's box centre along the line of sight). `EyeView` puts each eye's
  camera at the tracked eye (dx, -dy, -dz) * scale in the roll pivot's
  frame (X right, Y down, Z forward; the glass through the orbit centre at
  Z = 0), looking straight ahead, and projects the glass's corners to get
  `TPeardoxEyeView.Part` - the fractions of the picture the glass covers
  from that eye. The picture is rendered `RenderScale` (default 2) times
  the woven view's size; the part is cut out and scaled to the view
  (1920 x 1080) in the copy. Gorilla3D takes no projection or view matrix
  of ours (as far as tried - see Pan / rise), which is why the cut is in
  the copy and not in the camera.
- **Zero copy** (src/common/StereoModelGLInterop.pas,
  `TPeardoxGLInterop`): two B8G8R8A8 textures on the bridge's D3D11
  device, registered with OpenGL (WGL_NV_DX_interop2). After each eye's
  RenderManual, `CopyEye` binds FMX's multisampled RGBA8 framebuffer
  (`FindPicture`, by name), resolves it, and blits the part (GL_LINEAR,
  rows turned over, black outside) into the eye texture;
  `TPeardoxLeiaSR.SubmitEyeTextures` weaves them. Every GL error is taken
  (`TakeErrors`) - FMX's next BeginScene fails on any pending one.
  Screenshots + a CPU copy (`CopyPart`) are the automatic fallback.
- **Speed** (owner's RTX 5090 laptop, SRDemo scene): per-eye view at
  render scale 2: 46-48 fps (render 16 ms for both eyes, copy 0.5, submit
  0.2); per-eye view off or render scale 1: about 100 fps.
- **Right drag** = `SetTargetDepth`: the camera stays, the target (the
  glass) slides along the line of sight. The scale stays (it is set at
  the model's depth), so in SR the glass and the viewer move together and
  the model comes out of the screen or goes in without sliding. The 2D
  picture does not change. The wheel moves the camera (and so the scale).

### Settings and keys

All in LeiaSR.json (`TPeardoxLeiaSRSettings`, lib, shared by Peardox
programs), all saved when changed by key:

| Key | Setting | Meaning |
|---|---|---|
| L | LatencyFrames | weaver's eye prediction, 0 (SR's) .. 4 |
| [ ] | EyeSeparationMM | -/+ 5 mm (0 = as tracked) |
| C | FrameCap | bridge waits for vblank after each frame (off) |
| V | PerEyeView | off = full speed: eyes at the model's distance in the real eyes' directions, the whole picture woven, render scale 1 |
| , . | RenderScale | -/+ 0.25, 1 .. 2 (2) |
| M | HideCursor | pointer hidden over the SR display (on) |
| W | Weave | off = flat: one view from the eyes' midpoint for both, lens off (`TPeardoxLeiaSR.Flat`), for screen recordings |

Also P (snapshot block to the log), Home (view back), Esc (Stereo off).
Removed in StereoCam59: S T X R Z F (swap, toe-in, shift sign,
RenderManual, zero copy, row flip) and the old shift method.

### Next, in order

1. **TPeardoxGorillaEyes as a component** in lib (the owner will do this
   in its own session). It uses Peardox (orbit camera), PeardoxLeiaSR and
   Gorilla3D, so it needs a package that requires both, or PeardoxLeiaSR
   requiring Peardox; StereoModelGLInterop goes with it (Windows-only
   parts already under {$IFDEF MSWINDOWS}). Design package and palette
   icon as the others; first made in code, then on the form.
2. **Pan / rise** - the owner wants to explore it; read the next section
   before starting.
3. Later: LensMode (lens off over the controls); two SR displays (ask
   which); the old screenshot-route sign puzzle (StereoCam58a) only if it
   shows again.

### Pan / rise: where it stands

**What is meant.** A view camera's movements: SHIFT (sideways; the owner
says "pan") and RISE / FALL move the picture across the lens while the
camera stands still and looks the same way. Perspective is unchanged;
only the framing moves - e.g. a tall model's top brought into frame
without tilting, so verticals stay parallel. Not to be confused with
pan / tilt in the film sense (the camera TURNS: perspective changes,
verticals converge) or truck / pedestal (the camera MOVES: parallax
changes). Mathematically a shift is an asymmetric (off-axis) frustum:
the projection's window slides by (sx, sy) in normalised device units,
which is what `x_ndc += sx * w` does after the projection, or a shear
`x' = x - (sx / SX) z` in view space before it.

**What has been tried (StereoCam10-17), and why it failed:**
- Truck / pedestal (StereoCam10): moves the camera, so the view changes;
  not a shift. `TPeardoxOrbitalGorillaCamera.ShiftView` (lib) still does
  this, for sub-pixel nudges only.
- A lens shift in the PROJECTION (StereoCam13): overriding
  GetProjectionMatrix drew nothing different - Gorilla3D 1.5.3's context
  builds its projection itself from GetProjectionSettings, a record of
  Kind, OrthoHeight and OrthoWidth only. Changing the field of view while
  running is not drawn as expected either (dolly zoom, StereoCam15-17:
  plain zooming, then with ProjectionChanged a slow zoom).
- Moving the viewport control (StereoCam14): rejected by the owner ("it
  just moves the VP").
- Rendering larger and cropping, for the 2D view: rejected by the owner
  then (before zero copy existed).

**Not yet tried, most promising first:**
1. **Shear in the VIEW matrix, as SRDemoFMX does.** SRDemoFMX
   (SRDelphiFMX lib/FMX.SRStereoViewport.pas, `TSRStereoRenderer.RenderEye`,
   around line 2694) gets its whole off-axis projection into FMX by
   multiplying the VIEW matrix: `OffAxis.m31 := -Zoom * ShearX`,
   `m32 := -Zoom * ShearY` (and m11 = m22 = Zoom), then
   `Ctx.SetCameraMatrix(EyeView * OffAxis)` - because FMX also ignores a
   changed projection between frames. Only the projection override was
   ever tried with Gorilla3D, never the view matrix. FIRST EXPERIMENT:
   find what view matrix Gorilla3D draws with (TCamera.CameraMatrix /
   GetCameraMatrix - is it virtual? - or something in TGorillaCamera /
   TGorillaViewport's render that calls Context.SetCameraMatrix) and try
   a shear there with a fixed test value. Check the lighting (Gorilla3D's
   deferred renderer may rebuild normals or positions from the view
   matrix; a shear may upset them) and the G-buffer passes (the HDR target
   FBO 3 etc. may use their own camera matrices).
   If it works, it is worth far more than pan / rise: the per-eye view
   could put its cut and zoom in the matrix too (no 2x overscan: render
   scale 1, sharp, ~100 fps), and the dolly zoom (Maybe later) becomes
   possible.
2. **In the SR view only: an offset on the glass, nearly free.** The
   per-eye view already renders larger and cuts the glass's part out.
   A true shift / rise is the glass's rectangle moved in its own plane
   while the eyes stay where they are: in `EyeView`, add the offset
   (Sx, Sy, scene units = fraction * glass size * scale) to both corners
   before projecting (`-HalfW + Sx - E.X` and so on). It is exact for
   both eyes, so the depth is untouched. Limit: the part must stay inside
   the rendered picture, or that edge comes out black (CopyEye clears it):
   the slack each way is about (1 - part size) / 2 - about 0.26 of the
   picture at 85 cm with render scale 2 (the part was ~0.48 high), none
   at all with PerEyeView off (the part is the whole picture). More
   needs a wider field of view or a bigger render. NOTE: this alone
   gives the SR view a shift the 2D window does not show; the owner
   should say whether that is acceptable.
3. **The 2D window by render and copy**: draw the 2D view off screen
   (as the eyes are) and blit the shifted part to the window - costs a
   render target, an overscan and a copy every frame, and was rejected
   for 2D before. Ask first.
4. **Gorilla3D's author**: an OffsetX / OffsetY in
   TGorillaProjectionSettings (added in ToMatrix as Offset times the w
   column to the x and y columns), or a way for a camera to supply its
   own projection. Already on the list of questions for him (with the
   field-of-view and FBX-leak questions); the owner relays.
5. **RTTI writes** to FMX's / Gorilla3D's private projection fields
   (the owner, 17:37: "some of the FMX3D fields for the projection matrix
   are strictly private", the source is there): fragile, and which field
   Gorilla3D draws with is not known. Last resort.

**Whatever route is taken, these must follow the offset:**
`TPeardoxOrbitalGorillaCamera.ProjectToView` and the fits
(FitToBounds / FitCorners / FitOnAxis, which assume a centred frustum),
`TPeardoxGorillaEyes.EyeView` (so SR and 2D agree), and the owner's
choice of control (no mouse button is free: left orbits, right moves the
depth, the wheel zooms - ask: Shift+drag, middle drag, or keys).

**First question for the owner** at the start of that session: shift /
rise in the 2D window, in SR, or both - it decides between route 2
(an hour) and route 1 (an experiment first).

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
  CAUSE FOUND (8 November 2026): the leak comes with
  TGorillaModel.LoadNewModelFromFile, the class function LoadModel used.
  Sprite3D, with the same FBX loader, does not leak: it makes the model
  itself (TGorillaModel.Create(viewport)) and loads with the instance
  method LoadFromFile. StereoCam63 loads that way (LoadModel frees the new
  model if its load fails). Owner to test: whether the TGA and shader
  TStringList leaks go too; if not, they are a separate Gorilla3D bug.
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
  Owner (20:33): DisplayName undeclared + ForceQueue E2250 (knock-on) -
  the package had not been rebuilt; 46b also drops Eyes' unused
  RGBA := False. Owner pushed "2 windows" 977a107 and "Stupid gitignore"
  273bb9d (logs out of git, *.log and Win64/ ignored); synced, every file
  matches.
  ZERO COPY (owner, 20:45: "SRDemoFMX already does ZeroCopy ... for people
  with worse [laptops] ... all the speed we can give them helps"). Plan, no
  bridge change: StereoModel makes its own D3D11 device on the SR display's
  adapter and gives it to the bridge (srb_SetExternalDevice before
  srb_Initialize, as SRDemoFMX gives FMX's); two eye textures on it,
  registered with OpenGL through WGL_NV_DX_interop2 (wglDXOpenDeviceNV,
  wglDXRegisterObjectNV, Lock / Unlock); after each eye's RenderManual,
  glBlitFramebuffer from Gorilla3D's picture into the eye texture, flipped
  (GL is bottom-up); then srb_CopyEyeTexture(eye) and srb_PresentViews
  (the bridge accepts any texture on its device). Screenshot route kept as
  the fallback. Saves shot + copy + upload, ~6 ms of a 12-14 ms frame.
  Step 1, StereoCam47: src/common/StereoModelGLProbe.pas (new; .dpr +
  .dproj) ProbeGL logs once, after the first eye's RenderManual and after
  its MakeScreenshot: current GL context / DC, vendor / renderer / version,
  WGL_NV_DX_interop2 + wglDXOpenDeviceNV, draw / read framebuffer,
  renderbuffer, 2D texture bindings, the read framebuffer's colour
  attachment (texture / renderbuffer, name, size, internal format,
  samples), and by RTTI the viewport's TTexture / TContext3D fields
  (contexts one level deeper) and integer fields named *FBO* / *FRAMEBUF* /
  *RENDERBUF* / *TEX*. Program only. 47b: GLInt hid the type GLint (Delphi
  is case-blind) - GLInteger; FMX.Types for TPixelFormat.
  Owner (20:51), the probe's answer: after RenderManual the context is
  current, NVIDIA RTX 5090 OpenGL 4.6 (driver 610.47), WGL_NV_DX_interop2
  there; draw and read framebuffer 3, its colour attachment texture 24
  1280 x 720 GL_RGB8 - the viewport's LOGICAL size (1280 x 720 at scale
  1.5; MakeScreenshot gave 1920 x 1080, so it renders again or scales);
  after MakeScreenshot still framebuffer 3. glGetError $502 (ours or
  Gorilla's, harmless). RTTI found no fields in TGorillaViewport.
  StereoCam48, zero copy: bridge export srb_GetDevice (zip SRBridgeDevice1
  for SRDelphiFMX, which also carries the unpushed SRDemoSnap1 files: the
  bridge's g.dev, not AddRef'd; README / CLAUDE / SRBridge.h / .Api.pas);
  Peardox.LeiaSR.Api declares it; TPeardoxLeiaSR.BridgeDevice (nil without
  the export) and SubmitEyeTextures (srb_CopyEyeTexture x2 +
  srb_PresentViews, counted by the new CountSubmit as SubmitViews is).
  src/common/StereoModelGLInterop.pas (new; .dpr + .dproj):
  TPeardoxGLInterop - two B8G8R8A8 textures made on the bridge's device
  (own IPdxD3D11Device declaration up to CreateTexture2D, no Delphi D3D
  headers), wglDXOpenDeviceNV, registered as GL textures (WRITE_DISCARD),
  each attached to an FBO; CopyEye: lock, bind own FBO as draw, scissor
  off, clear black if shifted, glBlitFramebuffer from the still-bound read
  FBO with Y flipped and X shifted, put back draw FBO / scissor / clear
  colour, unlock; SourceSize reads the read FBO's texture size. Eyes:
  ZeroCopy (default True, key Z), PrepareZeroCopy after a screenshot-path
  RenderManual (GL current) makes FInterop at the source size; CanZeroCopy
  frames: RenderEyeGPU x2 then SubmitEyeTextures (timings: screenshot slot
  = blit, copy 0, submit = present); a failure falls back to screenshots
  for that device (a size change just remakes). Main: with
  ZeroCopyPossible the viewport is sized at the view size in LOGICAL units
  (Scale 1), so Gorilla3D draws 1920 x 1080. PACKAGE REBUILD and BRIDGE
  REBUILD. 48b: glIsEnabled returns a Byte (GLboolean) - "<> 0".
  Owner (21:06): zero copy set up ("two 1920 x 1080 eye textures"), one
  screenshot frame woven, then the dialog "cannot begin rendering scene for
  TContextOpenGLWindows: 1282" (GL_INVALID_OPERATION) and 0 frames; on exit
  "Runtime error 231". FMX's OpenGL context (FMX.Context.GLES, DoBeginScene)
  raises if ANY glGetError is pending; the probe had already seen $502
  pending after RenderManual (Gorilla3D's, or ours), and on the screenshot
  route MakeScreenshot took it. Owner: SRDemoFMX hit the same kind of thing
  ("needed Delphi's OpenGL context source"). StereoCam49:
  TPeardoxGLInterop.TakeErrors (glGetError until GL_NO_ERROR, at most 32)
  after RenderManual and after the blit in RenderEyeGPU, each place's first
  error logged (NoteGLError), and at the end of Start / Release; Start
  keeps its HGLRC / HDC and Release makes them current (wglMakeCurrent)
  when none is, so the GL side is undone; Eyes.ReleaseZeroCopy in FormClose
  (before SR stops, while the context exists) and in LeiaSRStopped. Program
  only.
  Owner (21:10): "Not as bad (but not great either)" - ONE 1282 dialog,
  then ZERO COPY WORKS: ~9 fps while the modal dialog was up (watchdog
  frames), after OK 55 fps, then after the usual drop 90-110 fps, render
  7.2, blit 0.4, copy 0, present 0.2 ms (screenshot route ~65-75 fps).
  "OpenGL error $502 after the zero-copy blit (ours)" logged; none after
  RenderManual. The dialog came on the set-up frame: PrepareZeroCopy runs
  on both eyes' screenshot renders, and on the second its SourceSize (bind
  the attachment texture to read its size, bind the old one back) left
  $502 for MakeScreenshot's BeginScene. StereoCam50: SourceSize reads the
  size by name with glGetTextureLevelParameteriv (GL 4.5, optional, else the
  old bind) and always ends with TakeErrors.
  Owner (21:14): no dialog, zero copy 90-109 fps (render 7.2, blit 0.4,
  present 0.2 ms), no GL error logged - "But also no image". The blit
  copies nothing without an error if the source's read buffer is GL_NONE
  (or the colour mask / scissor interfere). StereoCam51: CopyEye sets read
  buffer COLOR_ATTACHMENT0, colour mask all on, scissor off for the copy
  and puts each back; once a second (Eyes -> FInterop.CheckNext) it logs
  "Zero copy check": source FBO, read buffer, colour mask, sRGB writes,
  scissor, and the middle pixel read back (glReadPixels, skipped if a pack
  buffer is bound) from the source and from the eye texture after the
  blit - so the next log says whether the picture reaches the eye texture
  (GL side) or is lost after (D3D / bridge side).
  Owner (21:17) log: every check "source framebuffer 3, read buffer $8CE0,
  colour mask 1111, sRGB writes False, scissor False | middle pixel RGBA
  source 0 0 0 0, eye texture 0 0 0 0", and $502 after the blit. RGB8 read
  as RGBA would have alpha 255, so the reads failed too: FBO 3 is
  MULTISAMPLED (FMX 3D views render with 4 samples; the probe's
  GL_TEXTURE_2D bind of an MS texture failed - the old $502 - so its
  "samples 0" was another texture's). A multisampled framebuffer may only
  be resolved same rect, same format: our flipped / shifted blit into BGRA
  was GL_INVALID_OPERATION. StereoCam52: Start reads GL_SAMPLES (source FBO
  bound as draw for a moment) and the source texture's internal format
  (DSA), and when samples > 1 makes FResolveFBO + FResolveTex (that format,
  glTexImage2D); CopyEye resolves source -> FResolveFBO (same rect,
  NEAREST), reads from there for the flipped / shifted blit and the check,
  and puts read FBO, draw FBO and read buffer back. Logged "the picture has
  N samples per pixel ... resolved first".
  Owner (21:20): "4 samples per pixel, internal format $8814" (RGBA32F -
  a float, likely HDR, target), no GL errors now, but the resolved middle
  pixel still 0 0 0 0 (alpha 0 too) and no picture. So FBO 3 after
  RenderManual is probably not where the finished picture is (Gorilla3D
  may render HDR into FBO 3 and finish - tone-map / post - into another
  target; texture 29 is bound after RenderManual). StereoCam53: one-off
  TPeardoxGLInterop.Survey after Start - textures 1..64 (>= 256 px): target,
  size, format, samples and, for 2D, the middle texel as floats
  (glGetTextureSubImage); framebuffers 1..16: colour attachment 0 (DSA, so
  nothing bound).
  Owner (21:23): "Crash..." after the survey's texture 30 (the next texture
  or the framebuffer part). The map (all 1920 x 1080): 1 2D RGBA8 (middle
  0,0,0,1), 2 MS4 RGBA8, 11 and 14-18 2D RGBA8 (0,0,0,0), 19-24 MS4: RGBA8,
  RG16F $822E, RGBA16F $881A, RGB16F $881B, RGB8 $8051, RGBA32F $8814
  (= FBO 3's attachment) - a deferred G-buffer + HDR target, with 25-30 2D
  copies of the same formats. EVERY middle texel was background (normal
  RG 0, position 0): with the eye camera offset the middle falls between
  spheres, so the 0 0 0 0 checks proved nothing. StereoCam54: Survey no
  longer called (kept); the check counts lit pixels of a 3 x 3 grid in
  the source and in the eye texture. ASKED the owner whether the 21:20
  run (resolve in place) showed a picture. If FBO 3 (HDR, before tone
  mapping) is the wrong source, texture 1 (RGBA8, alpha 1) is the likely
  finished picture.
  Owner (21:25): "black"; the grid read source 0, eye texture 0 at 90-110
  fps: FBO 3 holds nothing usable after RenderManual. StereoCam55:
  FindPicture (in Start) walks framebuffers 1..32 with safe calls only
  (glIsFramebuffer, DSA attachment and texture queries - no
  glGetTextureSubImage, the likely survey crash), reads a 3 x 3 grid of
  every eye-sized 2D one, and of every MS RGBA8 one after resolving it
  into a temporary RGBA8 target; logs each ("framebuffer N, texture T,
  ... lit L of 9") and copies from the most lit (FSourceFB), else the
  bound one. CopyEye binds FSourceFB for reading and puts the bound one
  back after.
  Owner (21:31, StereoCam55): "a picture - but the frames are
  misaligned". FindPicture chose framebuffer 1 (texture 2, FMX's MS4
  RGBA8, lit 3 of 9; framebuffer 2 = texture 1 its resolve, also 3);
  FBO 3 (HDR) is not readable, FBO 4 (texture 30) lit 0. Zero copy: 95-106
  fps, render 7.3 ms, copy 0.5, submit 0.2 (screenshots at the weave
  size were ~70). The checks show the eye texture matching the source
  (middle pixels equal bar edge pixels), so the copy is current and
  whole. StereoCam56: key F (TPeardoxGorillaEyes.ZeroCopyFlip ->
  TPeardoxGLInterop.FlipRows) turns the row flip off, to test; S, X and
  Z (screenshots) are the other comparisons. ASKED the owner what the
  misalignment looks like.
  Owner (21:37): only Z did anything - "the mis-aligned image again";
  F, S and X were black. That run's FindPicture found nothing lit at the
  3 x 3 points (framebuffer 1 lit 0) and fell back to FBO 3 (black); so
  the misalignment is in the SCREENSHOT path too, not zero copy's.
  Screenshots there: 2880 x 1620 per eye, ~40 fps (screenshot 5.1, copy
  4.9, submit 2.0 ms). StereoCam57: FindPicture reads an 8 x 8 grid and,
  with nothing lit, takes the first MS RGBA8 framebuffer (FMX's), then
  the first 2D RGBA8, never the HDR target; FormKeyUp only off Windows
  (H2219). ASKED again what "misaligned" looks like and whether the
  screenshot picture was right before the zero-copy work.
  Owner (21:38): the misalignment is the old ghosting (SRDemoFMX too);
  SRDemoFMX's cure is a per-eye off-axis view (zoom TanRef / TanEye and
  shear in the view matrix, FMX.SRStereoViewport.pas ~2740), StereoModel
  still has a fixed 45 deg FOV, camera at the target distance, and a
  sideways shift. Offered as StereoCam58 (T kept to compare); not yet
  answered.
  Owner (21:51, StereoCam57 picked framebuffer 1, 64-point grid lit 7):
  "T/X fix it in ZeroCopy - basically the reverse of ScreenShots".
  Screenshots line up at shift sign -1, zero copy at +1 or toe-in.
  StereoCam58a: zero copy negates the shift (ShiftL/ShiftR := -ShiftFor);
  the reason is NOT known - the blit and CPU copy both move right for a
  positive shift, and the picture is not mirrored (toe-in is right).
  Suspect: FMX's framebuffer picture and MakeScreenshot's bitmap differ
  in some way the shift sees; to settle with the per-eye view.
  Owner (22:07): per-eye view, clean up and remove the unused / test
  code; render scale "Sharp" (asked: Gorilla3D takes no projection of
  ours and draws no run-time FOV change, so the off-axis cut is made in
  the copy and the picture rendered larger). StereoCam59:
  TPeardoxGorillaEyes rewritten - ViewScale reads the projection
  (ProjectToView of CameraPosition + Orientation.Rotate((1, 1, 1)) gives
  1 / tan of both half-angles, FProjX / FProjY) and the scale
  2 D / (SY * view height mm); EyeView puts the camera at the eye
  (dx, -dy, -dz) * scale in the roll pivot's frame, no turn, and the
  glass's corners through the projection give TPeardoxEyeView.Part
  (fractions, top-left origin, may pass 0..1); RenderEyeGPU ->
  TPeardoxGLInterop.CopyEye(eye, part in source pixels): resolve, then
  one GL_LINEAR blit of the part (clipped, the rest cleared black) into
  the eye texture, rows turned over; the screenshot route's CopyPart
  samples the part (nearest) into FBuffer. Render scale 2 (StereoCam60:
  the RenderScale setting):
  SizeViewForStereo makes the viewport 2 x the recommended view (3840 x
  2160); the eye textures stay the view size (Start takes source and
  view sizes). Removed: convergence (ecShift / ecToeIn), ShiftSign,
  SwapEyes, RenderBeforeShot, ZeroCopyFlip / FlipRows, Calibrate and the
  turn signs, ShiftFor, the decimation, the once-a-second zero-copy check
  (CheckNext, a pipeline stall), Survey, the GL probe unit
  StereoModelGLProbe (.dpr / .dproj too), FindPicture's pixel reads (it
  now picks FMX's multisampled RGBA8 framebuffer of the picture's size
  by name), keys S T X R Z F. Keys now: L [ ] C P Home Esc. Program only.
  Owner (22:31): works, "Oh yeah, that's nice"; 46-48 fps. StereoCam60:
  LeiaSR settings PerEyeView (V), RenderScale (, .), HideCursor (M),
  Weave (W, TPeardoxLeiaSR.Flat: lens off while weaving, one view from the
  eyes' midpoint for both). PACKAGE REBUILD (PeardoxLeiaSR). The
  SubmitViews PasDoc block, cut off from its declaration since
  StereoCam48, put back above it.
  Owner (22:59): "right click + drag still doesn't work". No drag reached
  FMX while Stereo was on: the bridge's child window covered the 3D
  window and took the mouse, and on the launcher the viewport had gone to
  FRenderForm under a cover with HitTest off. StereoCam61: the bridge's
  window subclassed (SetWindowSubclass; WM_NCHITTEST -> HTTRANSPARENT),
  logged "Mouse passed through N window(s)"; the cover takes the view's
  mouse handlers.
  Owner (23:10): drags arrive, but "No, it still moves" - the model slid
  across the SR view during a right drag: the scale followed the target
  depth, so the eyes' cameras moved sideways with it. StereoCam62: the
  scale is set at ModelDepth (the Subject's centre along the line of
  sight), full-speed mode too. Owner (23:17): "that's good now".
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
