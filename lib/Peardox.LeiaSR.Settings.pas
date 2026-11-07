//** @abstract(The user's saved LeiaSR (glasses-free 3D) settings, shared by every Peardox
//** program.)
//**
//** Kept as LeiaSR.json in the Peardox folder of the user's application data (see
//** AppDataFolder in Peardox.Storage), read and written with Neon. The settings are the
//** viewer's and the display's, not one program's, so every Peardox program on the computer
//** shares them. They are those SRDelphiFMX's SRDemoFMX keeps (its TSRSettings), apart from
//** the demo's own choices; its own file, %APPDATA%\SRDelphiFMX\settings.json, is not
//** touched, since saving a file another program also writes would drop its other members.
unit Peardox.LeiaSR.Settings;

{
  The user's saved LeiaSR (glasses-free 3D) settings, shared by every
  Peardox program.

  Kept as LeiaSR.json in the Peardox folder of the user's application data
  (see AppDataFolder in Peardox.Storage), read and written with Neon. The
  settings are the viewer's and the display's, not one program's, so every
  Peardox program on the computer shares them. They are those SRDelphiFMX's
  SRDemoFMX keeps (its TSRSettings), apart from the demo's own choices; its
  own file, %APPDATA%\SRDelphiFMX\settings.json, is not touched, since
  saving a file another program also writes would drop its other members.
}

interface

uses
  System.SysUtils, System.Classes, Peardox.Storage;

const
  //** @abstract(The folder, in the user's application data, the settings file is kept in.)
  PEARDOX_SETTINGS_FOLDER = 'Peardox';
  //** @abstract(The settings file's name inside PEARDOX_SETTINGS_FOLDER.)
  PEARDOX_LEIASR_SETTINGS_FILE = 'LeiaSR.json';
  //** @abstract(Default for TPeardoxLeiaSRSettings.EyeSeparationMM: the usual adult separation,
  //** as in SRDelphiFMX.)
  PEARDOX_DEFAULT_EYE_SEPARATION_MM = 63.0;
  //** @abstract(Default for TPeardoxLeiaSRSettings.RenderScale: sharp at a normal viewing
  //** distance.)
  PEARDOX_DEFAULT_RENDER_SCALE = 2.0;
  //** @abstract(The smallest TPeardoxLeiaSRSettings.RenderScale a renderer uses.)
  PEARDOX_MIN_RENDER_SCALE = 1.0;
  //** @abstract(The largest TPeardoxLeiaSRSettings.RenderScale a renderer uses.)
  PEARDOX_MAX_RENDER_SCALE = 2.0;

type
  //** @abstract(The saved LeiaSR settings.)
  //**
  //** Create one with Create, which names the shared file, call Load, and Save after each
  //** change. Every published property is saved, under its camel-case name.
  TPeardoxLeiaSRSettings = class(TPeardoxJsonSettings)
  private
    //** @abstract(See UseGlassesFree3D.)
    FUseGlassesFree3D: Boolean;
    //** @abstract(See EyeSeparationMM.)
    FEyeSeparationMM: Double;
    //** @abstract(See LookAround.)
    FLookAround: Boolean;
    //** @abstract(See LatencyFrames.)
    FLatencyFrames: Integer;
    //** @abstract(See LensMode.)
    FLensMode: Integer;
    //** @abstract(See FullScreen.)
    FFullScreen: Boolean;
    //** @abstract(See FrameCap.)
    FFrameCap: Boolean;
    //** @abstract(See PerEyeView.)
    FPerEyeView: Boolean;
    //** @abstract(See RenderScale.)
    FRenderScale: Double;
    //** @abstract(See HideCursor.)
    FHideCursor: Boolean;
    //** @abstract(See Weave.)
    FWeave: Boolean;
  public
    //** @abstract(Creates the settings with their defaults, for the file DefaultFileName
    //** names.)
    constructor Create; reintroduce; overload;
    //** @abstract(The shared settings file.)
    //**
    //** @returns(LeiaSR.json in the Peardox folder of the user's application data.)
    class function DefaultFileName: string; static;
  published
    //** @abstract(True (the default) to start glasses-free 3D when a program starts, on a
    //** computer with the LeiaSR runtime; False to leave it off until the user turns it on.)
    //**
    //** Ignored where LeiaSR is not installed: there a program behaves as if it had no SR
    //** support.
    property UseGlassesFree3D: Boolean read FUseGlassesFree3D write FUseGlassesFree3D;
    //** @abstract(The eye separation in millimetres used instead of the eye tracker's
    //** measurement, which wanders, keeping the tracked head position; 0 uses the tracked eyes
    //** as they are. Default PEARDOX_DEFAULT_EYE_SEPARATION_MM.)
    property EyeSeparationMM: Double read FEyeSeparationMM write FEyeSeparationMM;
    //** @abstract(True (the default) to draw from where the head is, so the model can be
    //** looked around; False to draw from a fixed viewer in front of the view: depth, but no
    //** motion with the head.)
    property LookAround: Boolean read FLookAround write FLookAround;
    //** @abstract(Frames of rendering latency told to the weaver for its eye prediction; 0
    //** (the default) leaves SR's own.)
    property LatencyFrames: Integer read FLatencyFrames write FLatencyFrames;
    //** @abstract(When the display's lens is on: 0 (the default) off while the pointer is over
    //** anything but the 3D view, 1 always on, 2 always off.)
    property LensMode: Integer read FLensMode write FLensMode;
    //** @abstract(Whether the 3D view was last full screen on the SR display; default False.)
    property FullScreen: Boolean read FFullScreen write FFullScreen;
    //** @abstract(True to have the bridge wait for the SR display's vertical blank after each
    //** frame it presents; False (the default) not to. Vsync stays on either way, so there is
    //** no tearing.)
    //**
    //** With the wait, a renderer whose own work takes over one refresh misses the next blank
    //** and drops to half the refresh rate or below: StereoModel went from 24 to 32 fps with
    //** it off, and looked no different (owner, 7 November 2026).
    property FrameCap: Boolean read FFrameCap write FFrameCap;
    //** @abstract(True (the default) to draw each eye from where it really is, as
    //** SRDelphiFMX's SRDemoFMX does: the per-eye off-axis view, true to the viewer's distance,
    //** with the scene rendered RenderScale times the view's size so the glass's part of it
    //** stays sharp. False for full speed: each eye drawn from the orbit camera's distance in
    //** the direction the real eye is, at the view's size, the depth exaggerated as the viewer
    //** moves back.)
    property PerEyeView: Boolean read FPerEyeView write FPerEyeView;
    //** @abstract(How many times the woven view's size, each way, a renderer draws the scene
    //** at for PerEyeView, from PEARDOX_MIN_RENDER_SCALE (fast, softer) to
    //** PEARDOX_MAX_RENDER_SCALE (sharp); default PEARDOX_DEFAULT_RENDER_SCALE.)
    property RenderScale: Double read FRenderScale write FRenderScale;
    //** @abstract(True (the default) to hide the mouse pointer while it is over the SR display
    //** and the view is woven there.)
    property HideCursor: Boolean read FHideCursor write FHideCursor;
    //** @abstract(True (the default) to weave in glasses-free 3D; False to show one flat view,
    //** drawn from between the tracked eyes, with the lens off. A screen recording cannot catch
    //** the woven picture, but it catches the flat one, and the view still follows the head.)
    property Weave: Boolean read FWeave write FWeave;
  end;

implementation

uses
  System.IOUtils;

{ TPeardoxLeiaSRSettings }

constructor TPeardoxLeiaSRSettings.Create;
begin
  inherited Create(DefaultFileName);
  FUseGlassesFree3D := True;
  FEyeSeparationMM := PEARDOX_DEFAULT_EYE_SEPARATION_MM;
  FLookAround := True;
  FLatencyFrames := 0;
  FLensMode := 0;
  FFullScreen := False;
  FFrameCap := False;
  FPerEyeView := True;
  FRenderScale := PEARDOX_DEFAULT_RENDER_SCALE;
  FHideCursor := True;
  FWeave := True;
end;

class function TPeardoxLeiaSRSettings.DefaultFileName: string;
begin
  Result := TPath.Combine(AppDataFolder(PEARDOX_SETTINGS_FOLDER), PEARDOX_LEIASR_SETTINGS_FILE);
end;

end.
