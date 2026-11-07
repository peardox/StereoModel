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
- A new unit goes in both the `.dpr` and the `.dproj` (UTF-8 with BOM).

## Where the work is

- `TPeardoxOrbitalCamera` (`lib/Peardox.OrbitalCamera.pas`): a non-visual
  component wrapping Sprite3D's orbit camera (renamed
  `TPeardoxOrbitalGorillaCamera`), with `Headlight`, the projection
  properties and fits. Registration unit and icon done. Packages
  (runtime + design) not yet made.
- `src/ui/StereoModelMain.pas` makes it in code, loads `models/uvcube.glb`
  and frames it, for the owner's first test. Next after that test: put the
  component on the form in the `.fmx`, then the packages, then the stereo
  rendering (target display still to be named by the owner).
- FastMM5 (submodule, owner 7 November 2026) is the memory manager on
  Windows, first in the `.dpr`; Debug builds report leaks, in full, to
  `StereoModel_MemoryManager_EventLog.txt` beside the executable.
- First Win64 run (owner, 7 November 2026): camera made, uvcube.glb loaded
  and framed (distance 4.84), headlight on; then an ACCESS VIOLATION ON
  EXIT, still there with StereoCam3. The FastMM5 leak dump of that run
  located it (see Lessons); StereoCam4 fixes it. The model also came up
  upside down: StereoCam4 turns it 180 degrees about X as Sprite3D does.
  Awaiting the owner's re-test.
- `tools/pasdoc.bat` (+ the two dark .css files), adapted from
  peardox/SRDelphiFMX: programs are `src\<program>.dpr`, the api run is
  `lib` without `*.Reg`. Not yet run.
- peardox/SRDelphiFMX is LeiaSR (Simulated Reality) glasses-free 3D from
  Delphi; ask the owner whether that is the target display before the
  stereo work starts.
- `MainMenu1` is on the form: once it has items, desktop Linux needs
  Sprite3D's `UseFmxMenuBar` swap (see Sprite3D's `CLAUDE.md`, Menus).

## Lessons learned

- **Gorilla3D teardown**: let the viewport free what is in it. The camera
  and light are owned by the viewport, as in Sprite3D and VirtualGamepad.
  The viewport sends its free notification BEFORE it frees the children
  and owned components it holds: FastMM5's dump of the leaked component
  showed FViewport nil, FLight nil, but FCamera still set, so the
  component's destructor later called into a dead camera. On the
  viewport's notice the component now lets go of the camera and light at
  once and never touches them again.
- **Reading a FastMM5 leak dump**: when an exception aborts shut-down,
  TApplication, TPlatformWin, the form and its registry entries all show
  as leaks; they are a symptom. The leaked object of our own class is the
  clue, and its memory dump gives its fields (64-bit TComponent: VMT at
  0, FOwner at 8, FFreeNotifies at $28, interface slots at $68 and $70,
  the class's own fields from $78).
