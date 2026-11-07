//** @abstract(Main form of StereoModel: a Gorilla3D viewport seen through the Peardox orbital
//** camera.)
//**
//** The view is a TPeardoxOrbitalCamera on the form, from the Peardox package, with its
//** headlight on. Once the form is showing it loads the test model, uvcube.glb from the models
//** folder, into the viewport and frames it so it stays in view at every angle.
//**
//** Mouse, on the viewport: a left drag orbits (Azimuth and PolarAngle); a right drag up or
//** down moves the target, the point the camera orbits, deeper or nearer along the line of
//** sight without moving the camera (SetTargetDepth); the wheel brings the view nearer or
//** takes it farther, stopping at the model's nearest face. A click on its own does nothing.
//** Status and problems are shown in the strip at the bottom, logged with FMX's Log.d and
//** written to StereoModel.log (StereoModelLog), beside the executable on Windows.
//**
//** Glasses-free 3D (step 0): a TPeardoxLeiaSR, from the PeardoxLeiaSR package, made in code
//** for now. Where LeiaSR is installed the Stereo button turns it on and off, and the choice
//** is saved in the shared LeiaSR settings; it starts by itself when the settings say so.
//** Nothing is woven yet: it only starts SR and logs the display and the eyes. Where LeiaSR
//** is not installed the button is hidden.
unit StereoModelMain;

{
  Main form of StereoModel: a Gorilla3D viewport seen through the Peardox
  orbital camera.

  The view is a TPeardoxOrbitalCamera on the form, from the Peardox
  package, with its headlight on. Once the form is showing it loads the
  test model, uvcube.glb from the models folder, into the viewport and
  frames it so it stays in view at every angle.

  Mouse, on the viewport: a left drag orbits (Azimuth and PolarAngle); a
  right drag up or down moves the target, the point the camera orbits,
  deeper or nearer along the line of sight without moving the camera
  (SetTargetDepth); the wheel brings the view nearer or takes it farther,
  stopping at the model's nearest face. A click on its own does nothing.
  Status and problems are shown in the strip at the bottom, logged with
  FMX's Log.d and written to StereoModel.log (StereoModelLog), beside the
  executable on Windows.

  Glasses-free 3D (step 0): a TPeardoxLeiaSR, made in code for now. Where
  LeiaSR is installed the Stereo button turns it on and off, and the
  choice is saved in the shared LeiaSR settings; it starts by itself when
  the settings say so. Nothing is woven yet: it only starts SR and logs
  the display and the eyes. Where LeiaSR is not installed the button is
  hidden.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.Math, System.Math.Vectors, System.IOUtils, System.Generics.Collections,
  FMX.Types, FMX.Types3D, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  Gorilla.Viewport, Gorilla.Camera, Gorilla.Model, Gorilla.Loader,
  // One unit per model format: each registers its file types with
  // TGorillaLoader when linked in, and File, Open offers what is registered.
  // USD was left out of Sprite3D for a problem in an earlier Gorilla3D, now
  // gone (owner, 7 November 2026). Not here: the Mayo CAD loaders and
  // SketchUp's (external libraries) and Sketchfab's (loads from the web)
  Gorilla.GLB.Loader, Gorilla.GLTF.Loader, Gorilla.OBJ.Loader, Gorilla.FBX.Loader,
  Gorilla.DAE.Loader, Gorilla.STL.Loader, Gorilla.PLY.Loader, Gorilla.USD.Loader,
  Gorilla.Babylon.Loader, Gorilla.G3D.Loader,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Menus, FMX.Layouts,
  Peardox.OrbitalCamera, Peardox.LeiaSR, Peardox.LeiaSR.Settings, FmxLinuxMenu, StereoModelLog;

type
  //** @abstract(The main form: the 3D view and the control strip below it.)
  //**
  //** @seealso(TPeardoxOrbitalCamera)
  TForm2 = class(TForm)
    //** @abstract(Holds the view; fills the form above ControlLayout.)
    MainViewLayout: TLayout;
    //** @abstract(The strip of controls along the bottom of the form.)
    ControlLayout: TLayout;
    //** @abstract(The main menu; empty for now.)
    MainMenu1: TMainMenu;
    //** @abstract(The File menu.)
    FileMenuItem: TMenuItem;
    //** @abstract(File, Open: picks a model file and loads it in place of the one shown;
    //** desktop only.)
    OpenMenuItem: TMenuItem;
    //** @abstract(Turns glasses-free 3D on (pressed) and off; hidden where LeiaSR is not
    //** installed.)
    btnStereo: TButton;
    //** @abstract(Holds the viewport inside MainViewLayout.)
    ViewLayout: TLayout;
    //** @abstract(The Gorilla3D viewport, seen through PeardoxOrbitalCamera1's camera.)
    GorillaViewport1: TGorillaViewport;
    //** @abstract(The orbital camera, on the form: it makes its camera and headlight in
    //** GorillaViewport1 as the form loads.)
    PeardoxOrbitalCamera1: TPeardoxOrbitalCamera;
    //** @abstract(Makes the status line, reports the orbital camera and hooks up the
    //** viewport's events.)
    //**
    //** @param(Sender The form.)
    procedure FormCreate(Sender: TObject);
    //** @abstract(Queues the test model's load the first time the form is shown, so the
    //** window is drawn first.)
    //**
    //** @param(Sender The form.)
    procedure FormShow(Sender: TObject);
    //** @abstract(File, Open: shows an open dialog for every model format Gorilla3D has a
    //** loader for here, and loads the file chosen.)
    //**
    //** @param(Sender OpenMenuItem.)
    procedure OpenMenuItemClick(Sender: TObject);
    //** @abstract(Stops glasses-free 3D while the window still exists, and closes the log.)
    //**
    //** @param(Sender The form.)
    //**
    //** @param(Action Left as it is: the form closes.)
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    //** @abstract(The Stereo button: starts glasses-free 3D when pressed, stops it when
    //** released, and saves the choice.)
    //**
    //** @param(Sender btnStereo.)
    procedure btnStereoClick(Sender: TObject);
  private
    //** @abstract(The model shown, owned by the viewport; nil until one has loaded.)
    FModel: TGorillaModel;
    //** @abstract(The file FModel came from, for the open dialog's starting folder.)
    FModelPath: string;
    //** @abstract(The status line in the control strip.)
    FStatus: TLabel;
    //** @abstract(The lens indicator, left of btnStereo: LENS ON in red while the display's
    //** lens is on, Lens off in grey, nothing while SR is not running.)
    FLensLabel: TLabel;
    //** @abstract(True once the test model's load has been queued, so FormShow queues it
    //** only once.)
    FLoadQueued: Boolean;
    //** @abstract(True while a drag is going on: a left one orbits, a right one moves the
    //** target's depth.)
    FDragging: Boolean;
    //** @abstract(True while the drag is a right one: it moves the target's depth instead of
    //** orbiting.)
    FDepthDrag: Boolean;
    //** @abstract(The mouse position at the last step of the drag, in viewport coordinates.)
    FDragLast: TPointF;
    //** @abstract(How far the wheel has zoomed from the fitted view: 1 is the fit, below 1
    //** nearer; kept between ZOOM_MIN and ZOOM_MAX.)
    FZoom: Single;
    //** @abstract(Glasses-free 3D: LeiaSR for GorillaViewport1, made in code for now; owned by
    //** the form.)
    FLeiaSR: TPeardoxLeiaSR;
    //** @abstract(Shows a line in the status strip, and logs it with Log.d and in
    //** StereoModel.log.)
    //**
    //** @param(AText The line.)
    procedure ShowStatus(const AText: string);
    //** @abstract(Finds the test model in the places it can be on each platform.)
    //**
    //** Looks in a models folder beside the executable (a deployed Windows or Linux build), in
    //** the bundle's Resources (macOS), in the documents folder (Android and iOS, where
    //** System.StartUpCopy puts deployed files), then in each folder above the executable, which
    //** finds the repository's models folder when run from the IDE's output folder.
    //**
    //** @param(ATried Set to the folders looked in, for the message when it is not found.)
    //**
    //** @returns(The model's full path, or an empty string if it is in none of them.)
    function FindTestModel(out ATried: string): string;
    //** @abstract(Finds the test model and loads it; see LoadModel.)
    procedure LoadTestModel;
    //** @abstract(Runs once the form is first showing: loads the test model, then starts
    //** glasses-free 3D if LeiaSR is installed and the settings ask for it.)
    procedure FirstShown;
    //** @abstract(Makes FLeiaSR, hooks up its events and shows or hides btnStereo.)
    procedure CreateLeiaSR;
    //** @abstract(FLeiaSR's log: every line to the status strip and Log.d.)
    //**
    //** @param(Sender FLeiaSR.)
    //**
    //** @param(AText The line.)
    procedure LeiaSRLog(Sender: TObject; const AText: string);
    //** @abstract(FLeiaSR has started: btnStereo shows pressed.)
    //**
    //** @param(Sender FLeiaSR.)
    procedure LeiaSRStarted(Sender: TObject);
    //** @abstract(FLeiaSR has stopped: btnStereo shows released.)
    //**
    //** @param(Sender FLeiaSR.)
    procedure LeiaSRStopped(Sender: TObject);
    //** @abstract(Glasses-free 3D could not start: btnStereo is released, without changing
    //** the saved choice, and the reason goes to the status strip.)
    //**
    //** @param(Sender FLeiaSR.)
    //**
    //** @param(AProblem What went wrong.)
    //**
    //** @param(AMessage The details.)
    procedure LeiaSRProblem(Sender: TObject; AProblem: TPeardoxLeiaSRProblem;
      const AMessage: string);
    //** @abstract(FLeiaSR's lens has come on or gone off: FLensLabel shows it.)
    //**
    //** @param(Sender FLeiaSR.)
    procedure LeiaSRLensChange(Sender: TObject);
    //** @abstract(Loads a model file into the viewport in place of the one shown, stands it
    //** upright and frames it.)
    //**
    //** Gorilla3D picks the loader by the file's extension. The new model is loaded first and
    //** the old one freed only once it has loaded, so a file that fails leaves the view as it
    //** was. The new model becomes the camera's Subject.
    //**
    //** @param(APath The model file, with its full path.)
    //**
    //** @returns(True if it loaded; False, with the reason in the status line, otherwise.)
    function LoadModel(const APath: string): Boolean;
    //** @abstract(Builds the open dialog's filter from the file types Gorilla3D's loaders have
    //** registered.)
    //**
    //** TGorillaLoader.FileTypes holds one entry per extension a linked-in loader opens, so the
    //** filter offers exactly what can be loaded: all of them together first, then each on its
    //** own, then all files.
    //**
    //** @returns(The filter, in TOpenDialog's "description|pattern|..." form.)
    function ModelFilter: string;
    //** @abstract(Centres the model on its bounds and turns it upright, as Sprite3D's
    //** PlaceModel does.)
    //**
    //** glTF's up is +Y and FMX's is -Y, so a model comes in upside down until it is turned
    //** MODEL_TURN_X degrees about X.
    procedure PlaceModel;
    //** @abstract(Frames the model for every angle, then puts the wheel's zoom back on top.)
    procedure FitView;
    //** @abstract(Puts the starting view back: all three angles 0, the fitted size.)
    procedure ResetView;
    //** @abstract(The status line for a right drag: the target's depth, and where the model
    //** lies against the glass.)
    //**
    //** The target's depth is the plane that will lie on the display's glass. The model's
    //** centre, measured along the line of sight, is then that much in front of the glass
    //** (out of the screen, Z below 0) or behind it (Z above 0): Z = model depth - target
    //** depth. While LeiaSR runs it is also given in millimetres, at the scale that puts the
    //** view's height in the camera's field of view at the target's depth onto the view's height
    //** on the display.
    //**
    //** @returns(The line.)
    function DepthStatus: string;
    //** @abstract(Viewport OnResize: refits, as the fit depends on the view's shape.)
    //**
    //** @param(Sender The viewport.)
    procedure ViewResize(Sender: TObject);
    //** @abstract(Viewport OnMouseDown: a left press starts orbiting, a right press starts
    //** moving the target's depth.)
    //**
    //** @param(Sender The viewport.)
    //**
    //** @param(Button The button pressed.)
    //**
    //** @param(Shift The keys and buttons held.)
    //**
    //** @param(X The mouse position across the viewport.)
    //**
    //** @param(Y The mouse position down the viewport.)
    procedure ViewMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Single);
    //** @abstract(Viewport OnMouseMove: orbits the camera while the left button is held, or
    //** moves the target's depth while the right one is.)
    //**
    //** @param(Sender The viewport.)
    //**
    //** @param(Shift The keys and buttons held.)
    //**
    //** @param(X The mouse position across the viewport.)
    //**
    //** @param(Y The mouse position down the viewport.)
    procedure ViewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    //** @abstract(Viewport OnMouseUp: letting go of the button that started the drag ends it.)
    //**
    //** @param(Sender The viewport.)
    //**
    //** @param(Button The button let go.)
    //**
    //** @param(Shift The keys and buttons held.)
    //**
    //** @param(X The mouse position across the viewport.)
    //**
    //** @param(Y The mouse position down the viewport.)
    procedure ViewMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Single);
    //** @abstract(Viewport OnMouseWheel: brings the view nearer or takes it farther.)
    //**
    //** In perspective each notch moves the camera along its line of sight by a share of its
    //** distance from the model, so the steps stay the same size wherever the target's depth
    //** has been put; orthographic views are scaled instead.
    //**
    //** @param(Sender The viewport.)
    //**
    //** @param(Shift The keys and buttons held.)
    //**
    //** @param(WheelDelta How far the wheel turned; WHEEL_NOTCH a notch, positive away from the
    //** user.)
    //**
    //** @param(Handled Set to True, so the form does not scroll as well.)
    procedure ViewMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer;
      var Handled: Boolean);
  public
  end;

var
  //** @abstract(The main form, made by the .dpr.)
  Form2: TForm2;

implementation

{$R *.fmx}

const
  //** @abstract(The folder the test models are in, beside the executable or at the
  //** repository's root.)
  MODEL_FOLDER = 'models';
  //** @abstract(The model loaded to test the camera: a cube with a UV test texture, so every
  //** face and its way up can be told apart.)
  TEST_MODEL = 'uvcube.glb';
  //** @abstract(How many folders above the executable FindTestModel looks in for MODEL_FOLDER.)
  FOLDERS_UP = 6;
  //** @abstract(The turn about X, in degrees, that stands a loaded model upright, as
  //** Sprite3D's MODEL_ROTATION does: glTF's up is +Y, FMX's is -Y.)
  MODEL_TURN_X = 180;
  //** @abstract(The open dialog's first entry: every model type together; Format arguments
  //** are the pattern list, twice.)
  MODEL_FILTER_ALL = 'All models (%s)|%s';
  //** @abstract(One model type's entry in the open dialog; Format arguments are its name and
  //** its extension, twice.)
  MODEL_FILTER_ONE = '|%s (*.%s)|*.%s';
  //** @abstract(The open dialog's last entry.)
  MODEL_FILTER_ANY = '|All files (*.*)|*.*';
  //** @abstract(Padding round the model as a fraction of the view, as in VirtualGamepad.)
  VIEW_MARGIN = 0.08;
  //** @abstract(Factor the target's depth changes by per pixel of a right drag up: deeper
  //** going up, nearer going down, in proportion, so it suits any scale.)
  DEPTH_STEP_PER_PIXEL = 1.01;
  //** @abstract(Degrees the camera orbits per pixel of mouse movement, as in Sprite3D.)
  ORBIT_DEGREES_PER_PIXEL = 0.5;
  //** @abstract(Zoom factor per wheel notch: rolling away brings the view nearer.)
  ZOOM_STEP = 1.1;
  //** @abstract(The nearest the wheel can bring the view, as a fraction of the fit.)
  ZOOM_MIN = 0.2;
  //** @abstract(The farthest the wheel can take the view, as a multiple of the fit.)
  ZOOM_MAX = 10.0;
  //** @abstract(The nearest the wheel takes the camera to the target, as a share of its
  //** distance before the notch, when the target is in front of the model.)
  MIN_TARGET_SHARE = 0.05;
  //** @abstract(The wheel delta of one notch.)
  WHEEL_NOTCH = 120;
  //** @abstract(Room at the right of the control strip kept for btnStereo, right of the lens
  //** indicator.)
  STATUS_RIGHT_MARGIN = 96;
  //** @abstract(The lens indicator's width, in pixels.)
  LENS_LABEL_WIDTH = 80;
  //** @abstract(Gap at the status line's left, in pixels.)
  STATUS_LEFT_MARGIN = 8;

procedure TForm2.FormCreate(Sender: TObject);
begin
  // The log first, so it has everything
  LogOpen;
  // Then: on desktop Linux the main menu is moved onto an FMX menu bar,
  // as GTK's native bar shows only first letters (FmxLinuxMenu, from
  // TSteamAPI); it does nothing elsewhere
  ReplaceMainMenu(Self, MainMenu1);
  {$IF DEFINED(ANDROID) or DEFINED(IOS)}
  // FMX's open dialog is desktop only
  FileMenuItem.Visible := False;
  {$ENDIF}
  FZoom := 1;
  FStatus := TLabel.Create(Self);
  FStatus.Parent := ControlLayout;
  FStatus.Align := TAlignLayout.Client;
  FStatus.Margins.Left := STATUS_LEFT_MARGIN;
  FStatus.Margins.Right := STATUS_LEFT_MARGIN;
  FStatus.WordWrap := False;
  // The lens indicator sits between the status line and btnStereo; its
  // colour and weight are its own, not the style's
  FLensLabel := TLabel.Create(Self);
  FLensLabel.Parent := ControlLayout;
  FLensLabel.Align := TAlignLayout.Right;
  FLensLabel.Width := LENS_LABEL_WIDTH;
  FLensLabel.Margins.Right := STATUS_RIGHT_MARGIN;
  FLensLabel.WordWrap := False;
  FLensLabel.TextSettings.HorzAlign := TTextAlign.Trailing;
  FLensLabel.StyledSettings := FLensLabel.StyledSettings -
    [TStyledSetting.FontColor, TStyledSetting.Style];
  FLensLabel.Text := '';
  // The component is on the form: by now it has made its camera, and its
  // headlight, in the viewport, as the form loaded
  if PeardoxOrbitalCamera1.Camera = nil then
    ShowStatus('Orbital camera NOT made: no camera in the viewport')
  else
    ShowStatus(Format('Orbital camera made: FOV %.0f, distance %.2f, headlight %s',
      [PeardoxOrbitalCamera1.FOV, PeardoxOrbitalCamera1.Distance,
       BoolToStr(PeardoxOrbitalCamera1.Light <> nil, True)]));
  GorillaViewport1.OnResize := ViewResize;
  GorillaViewport1.OnMouseDown := ViewMouseDown;
  GorillaViewport1.OnMouseMove := ViewMouseMove;
  GorillaViewport1.OnMouseUp := ViewMouseUp;
  GorillaViewport1.OnMouseWheel := ViewMouseWheel;
  CreateLeiaSR;
end;

procedure TForm2.CreateLeiaSR;
begin
  // Made in code for now (owner, 7 November 2026); a component on the form
  // later
  FLeiaSR := TPeardoxLeiaSR.Create(Self);
  FLeiaSR.Control := GorillaViewport1;
  FLeiaSR.OnLog := LeiaSRLog;
  FLeiaSR.OnStarted := LeiaSRStarted;
  FLeiaSR.OnStopped := LeiaSRStopped;
  FLeiaSR.OnProblem := LeiaSRProblem;
  FLeiaSR.OnLensChange := LeiaSRLensChange;
  ShowStatus(FLeiaSR.SettingsStatus);
  // No LeiaSR here: nothing about glasses-free 3D is shown
  btnStereo.Visible := TPeardoxLeiaSR.Installed;
  btnStereo.IsPressed := False;
  if not btnStereo.Visible then
    ShowStatus('LeiaSR not installed (or not a Windows 64-bit build): Stereo hidden')
  else if FLeiaSR.Settings.UseGlassesFree3D then
    ShowStatus('LeiaSR installed; glasses-free 3D is on in the settings')
  else
    ShowStatus('LeiaSR installed; glasses-free 3D is off in the settings');
end;

procedure TForm2.FirstShown;
begin
  LoadTestModel;
  if TPeardoxLeiaSR.Installed and FLeiaSR.Settings.UseGlassesFree3D then
  begin
    btnStereo.IsPressed := True;
    if not FLeiaSR.Start then
      btnStereo.IsPressed := False;
  end;
end;

procedure TForm2.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  // While the form's window, the parent of the bridge's, still exists
  FLeiaSR.Stop;
  LogClose;
end;

procedure TForm2.btnStereoClick(Sender: TObject);
begin
  if btnStereo.IsPressed then
  begin
    if not FLeiaSR.Start then
      btnStereo.IsPressed := False;
  end
  else
    FLeiaSR.Stop;
  // The user's choice, kept even when the start fails (as in SRDelphiFMX)
  if FLeiaSR.Settings.UseGlassesFree3D <> btnStereo.IsPressed then
  begin
    FLeiaSR.Settings.UseGlassesFree3D := btnStereo.IsPressed;
    FLeiaSR.SaveSettings;
  end;
end;

procedure TForm2.LeiaSRLog(Sender: TObject; const AText: string);
begin
  ShowStatus(AText);
end;

procedure TForm2.LeiaSRStarted(Sender: TObject);
begin
  btnStereo.IsPressed := True;
end;

procedure TForm2.LeiaSRStopped(Sender: TObject);
begin
  btnStereo.IsPressed := False;
end;

procedure TForm2.LeiaSRLensChange(Sender: TObject);
begin
  case FLeiaSR.LensState of
    lslOn:
      begin
        FLensLabel.Text := 'LENS ON';
        FLensLabel.TextSettings.FontColor := TAlphaColors.Red;
        FLensLabel.TextSettings.Font.Style := [TFontStyle.fsBold];
      end;
    lslOff:
      begin
        FLensLabel.Text := 'Lens off';
        FLensLabel.TextSettings.FontColor := TAlphaColors.Gray;
        FLensLabel.TextSettings.Font.Style := [];
      end;
  else
    FLensLabel.Text := '';
  end;
end;

procedure TForm2.LeiaSRProblem(Sender: TObject; AProblem: TPeardoxLeiaSRProblem;
  const AMessage: string);
begin
  btnStereo.IsPressed := False;
  ShowStatus('Glasses-free 3D not started: ' + AMessage);
end;

procedure TForm2.FormShow(Sender: TObject);
begin
  if FLoadQueued then
    Exit;
  FLoadQueued := True;
  // After this event has finished, so the window is drawn before the load
  // and before glasses-free 3D starts
  TThread.ForceQueue(nil, FirstShown);
end;

procedure TForm2.ShowStatus(const AText: string);
begin
  FStatus.Text := AText;
  Log.d(AText);
  LogLine(AText);
end;

function TForm2.FindTestModel(out ATried: string): string;
var
  Folders: TStringList;
  Dir, UpDir: string;
  I: Integer;
begin
  Result := '';
  Folders := TStringList.Create;
  try
    Dir := ExtractFileDir(ExpandFileName(ParamStr(0)));
    // A deployed build: models beside the executable (Windows, Linux) or
    // in the bundle's Resources (macOS: the executable is in Contents/MacOS)
    Folders.Add(TPath.Combine(Dir, MODEL_FOLDER));
    Folders.Add(TPath.Combine(TPath.Combine(ExtractFileDir(Dir), 'Resources'), MODEL_FOLDER));
    // Android and iOS: System.StartUpCopy copies deployed files here
    Folders.Add(TPath.Combine(TPath.GetDocumentsPath, MODEL_FOLDER));
    // Run from the IDE's output folder: the repository's models folder is
    // some way above it (src/<platform>/<config> on Windows)
    for I := 1 to FOLDERS_UP do
    begin
      UpDir := ExtractFileDir(Dir);
      if (UpDir = '') or (UpDir = Dir) then
        Break;
      Dir := UpDir;
      Folders.Add(TPath.Combine(Dir, MODEL_FOLDER));
    end;
    for I := 0 to Folders.Count - 1 do
      if TFile.Exists(TPath.Combine(Folders[I], TEST_MODEL)) then
        Exit(TPath.Combine(Folders[I], TEST_MODEL));
    ATried := string.Join('; ', Folders.ToStringArray);
  finally
    Folders.Free;
  end;
end;

procedure TForm2.LoadTestModel;
var
  Path, Tried: string;
begin
  Path := FindTestModel(Tried);
  if Path = '' then
    ShowStatus(Format('Model NOT FOUND: %s is in none of: %s', [TEST_MODEL, Tried]))
  else
    LoadModel(Path);
end;

function TForm2.LoadModel(const APath: string): Boolean;
var
  NewModel: TGorillaModel;
begin
  Result := False;
  try
    // Gorilla3D chooses the loader by the extension
    NewModel := TGorillaModel.LoadNewModelFromFile(GorillaViewport1, nil, APath, []);
    NewModel.Parent := GorillaViewport1;
  except
    on E: Exception do
    begin
      ShowStatus(Format('Model load FAILED: %s: %s: %s', [APath, E.ClassName, E.Message]));
      Exit;
    end;
  end;
  // Only now the old one goes; the camera lets go of it as its Subject
  // when it is freed
  FModel.Free;
  FModel := NewModel;
  FModelPath := APath;
  PlaceModel;
  // The camera may not go inside the model: the wheel and orbits stop at
  // the face nearest the camera
  PeardoxOrbitalCamera1.Subject := FModel;
  ResetView;
  ShowStatus(Format('Loaded %s; azimuth %.1f, polar %.1f, distance %.2f, headlight %s',
    [APath, PeardoxOrbitalCamera1.Azimuth, PeardoxOrbitalCamera1.PolarAngle,
     PeardoxOrbitalCamera1.Distance, BoolToStr(PeardoxOrbitalCamera1.Light <> nil, True)]));
  Result := True;
end;

function TForm2.ModelFilter: string;
var
  Exts: TStringList;
  Key, Ext, All: string;
  I: Integer;
begin
  Exts := TStringList.Create;
  try
    Exts.Sorted := True;
    Exts.Duplicates := TDuplicates.dupIgnore;
    // The keys are the extensions; take them with or without the dot, in
    // any case
    for Key in TGorillaLoader.FileTypes.Keys do
    begin
      Ext := LowerCase(Key.Trim);
      if Ext.StartsWith('.') then
        Ext := Ext.Substring(1);
      if Ext <> '' then
        Exts.Add(Ext);
    end;
    All := '';
    for I := 0 to Exts.Count - 1 do
    begin
      if All <> '' then
        All := All + ';';
      All := All + '*.' + Exts[I];
    end;
    Result := '';
    if All <> '' then
      Result := Format(MODEL_FILTER_ALL, [All, All]);
    for I := 0 to Exts.Count - 1 do
      Result := Result + Format(MODEL_FILTER_ONE, [UpperCase(Exts[I]), Exts[I], Exts[I]]);
    Result := Result + MODEL_FILTER_ANY;
  finally
    Exts.Free;
  end;
end;

procedure TForm2.OpenMenuItemClick(Sender: TObject);
var
  Dialog: TOpenDialog;
begin
  Dialog := TOpenDialog.Create(nil);
  try
    Dialog.Filter := ModelFilter;
    Dialog.FilterIndex := 1;
    if FModelPath <> '' then
      Dialog.InitialDir := ExtractFileDir(FModelPath);
    Dialog.Options := Dialog.Options + [TOpenOption.ofFileMustExist];
    if Dialog.Execute then
      LoadModel(Dialog.FileName);
  finally
    Dialog.Free;
  end;
end;

procedure TForm2.PlaceModel;
var
  Box: TBoundingBox;
begin
  // As Sprite3D's PlaceModel: the model's own bounds, taken before it is
  // moved or turned, give its position; then the turn that stands it up
  Box := FModel.GetBoundingBox;
  FModel.Position.Point := Point3D(Box.TopLeftNear.X + (Box.Width / 2),
                                   Box.TopLeftNear.Y + (Box.Height / 2),
                                   Box.TopLeftNear.Z + (Box.Depth / 2));
  FModel.RotationAngle.X := MODEL_TURN_X;
  FModel.RotationAngle.Y := 0;
  FModel.RotationAngle.Z := 0;
end;

procedure TForm2.FitView;
begin
  if FModel = nil then
    Exit;
  // For every angle, so orbiting never needs a refit; only the view's
  // shape does. The wheel's zoom is then put back on top of the fit
  if not PeardoxOrbitalCamera1.FitToBoundsMax(FModel, VIEW_MARGIN) then
    ShowStatus('Framing FAILED: no camera, an empty model or a viewport with no size')
  else if not SameValue(FZoom, 1) then
    PeardoxOrbitalCamera1.Zoom(FZoom);
end;

procedure TForm2.ResetView;
begin
  FZoom := 1;
  PeardoxOrbitalCamera1.Azimuth := 0;
  PeardoxOrbitalCamera1.PolarAngle := 0;
  PeardoxOrbitalCamera1.Roll := 0;
  FitView;
end;

function TForm2.DepthStatus: string;
var
  Cam: TPeardoxOrbitalCamera;
  Eye, Forward, Centre: TPoint3D;
  Box: TBoundingBox;
  Depth, Z, MMPerUnit: Single;
  Where: string;
begin
  Cam := PeardoxOrbitalCamera1;
  Result := Format('Target depth %.3f', [Cam.Distance]);
  if (FModel = nil) or (Cam.Camera = nil) or (Cam.Distance <= 0) then
    Exit;
  Eye := Cam.Camera.CameraPosition;
  Forward := (Cam.Camera.OrbitCenter.Point - Eye).Normalize;
  Box := FModel.GetAbsoluteBoundingBox;
  Centre := Point3D(Box.TopLeftNear.X + (Box.Width / 2), Box.TopLeftNear.Y + (Box.Height / 2),
    Box.TopLeftNear.Z + (Box.Depth / 2));
  // Along the line of sight, as the glass is square to it
  Depth := (Centre - Eye).DotProduct(Forward);
  Z := Depth - Cam.Distance;
  if Z < 0 then
    Where := 'in front of the glass (out of the screen)'
  else
    Where := 'behind the glass';
  Result := Format('%s | model centre at depth %.3f: Z %.3f, %s',
    [Result, Depth, Z, Where]);
  // The view's height at the target's depth is the view's height on the
  // display; FOV is the vertical field of view
  if FLeiaSR.Running and (FLeiaSR.WindowSizeMM.Height > 0) then
  begin
    MMPerUnit := FLeiaSR.WindowSizeMM.Height /
      (2 * Cam.Distance * Tan(DegToRad(Cam.FOV) / 2));
    Result := Result + Format(', %.0f mm', [Z * MMPerUnit]);
  end;
end;

procedure TForm2.ViewResize(Sender: TObject);
begin
  FitView;
end;

procedure TForm2.ViewMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
  X, Y: Single);
begin
  // Left drags orbit, right drags move the target's depth; a click on its
  // own does nothing (owner, 7 November 2026: no click resets the view)
  if Button in [TMouseButton.mbLeft, TMouseButton.mbRight] then
  begin
    FDragging := True;
    FDepthDrag := Button = TMouseButton.mbRight;
    FDragLast := PointF(X, Y);
  end;
end;

procedure TForm2.ViewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
  if not FDragging then
    Exit;
  // A button let go outside the view sends no mouse-up, so the first move
  // without it ends the drag (as in Sprite3D)
  if (FDepthDrag and not (ssRight in Shift)) or (not FDepthDrag and not (ssLeft in Shift)) then
  begin
    FDragging := False;
    Exit;
  end;
  if FDepthDrag then
  begin
    // Up (Y falling) pushes the target deeper, down pulls it nearer; the
    // camera and the picture stay as they are (owner, 7 November 2026: the
    // depth will matter for the SR display). Across is not used
    PeardoxOrbitalCamera1.SetTargetDepth(PeardoxOrbitalCamera1.Distance
      * Power(DEPTH_STEP_PER_PIXEL, FDragLast.Y - Y));
    ShowStatus(DepthStatus);
  end
  else
    // Dragging right turns the camera right round the centre (owner, 7
    // November 2026: the other way round felt reversed); dragging down
    // raises the camera
    PeardoxOrbitalCamera1.Orbit((X - FDragLast.X) * ORBIT_DEGREES_PER_PIXEL,
      (Y - FDragLast.Y) * ORBIT_DEGREES_PER_PIXEL);
  FDragLast := PointF(X, Y);
end;

procedure TForm2.ViewMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
  X, Y: Single);
begin
  if (Button = TMouseButton.mbLeft) and not FDepthDrag then
    FDragging := False
  else if (Button = TMouseButton.mbRight) and FDepthDrag then
    FDragging := False;
end;

procedure TForm2.ViewMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer;
  var Handled: Boolean);
var
  Cam: TPeardoxOrbitalCamera;
  NewZoom, Before, ToModel, NewToModel, NewDistance: Single;
  Box: TBoundingBox;
  Centre: TPoint3D;
begin
  Handled := True;
  Cam := PeardoxOrbitalCamera1;
  // Rolling the wheel away (positive) brings the view nearer
  NewZoom := EnsureRange(FZoom * Power(ZOOM_STEP, -WheelDelta / WHEEL_NOTCH), ZOOM_MIN, ZOOM_MAX);
  if (FModel = nil) or (Cam.Camera = nil) or
    (Cam.ProjectionMode <> TGorillaCameraProjection.cpPerspective) then
  begin
    // Orthographic: Zoom scales the view's size, which is how big things
    // look, so only the change is passed on
    Cam.Zoom(NewZoom / FZoom);
    FZoom := NewZoom;
    Exit;
  end;
  // Perspective: the step is a share of the camera's distance from the
  // MODEL, not from the target. Once a right drag has put the target far
  // deeper (or nearer) than the model, a share of the target's distance
  // made each notch a huge jump (owner, 16:40). The camera still moves
  // along its line of sight, towards or away from the target, by that step
  Box := FModel.GetAbsoluteBoundingBox;
  Centre := Point3D(Box.TopLeftNear.X + (Box.Width / 2), Box.TopLeftNear.Y + (Box.Height / 2),
    Box.TopLeftNear.Z + (Box.Depth / 2));
  ToModel := Cam.Camera.CameraPosition.Distance(Centre);
  Before := Cam.Distance;
  if (ToModel <= 0) or (Before <= 0) then
    Exit;
  NewToModel := ToModel * NewZoom / FZoom;
  NewDistance := Before - (ToModel - NewToModel);
  // With the target nearer than the model the camera cannot pass it: it
  // stops just short (a right drag down moves the target deeper again)
  if NewDistance < Before * MIN_TARGET_SHARE then
  begin
    NewDistance := Before * MIN_TARGET_SHARE;
    ShowStatus(Format('Zoom stopped: the target (depth %.3f) is in front of the model; ' +
      'right-drag up to move it deeper', [Before]));
  end;
  // The camera also stops at the model's nearest face (Subject)
  Cam.Zoom(NewDistance / Before);
  // What the distance to the model really became, so the first notch back
  // out moves the camera at once however far the wheel went in
  FZoom := EnsureRange(FZoom * Cam.Camera.CameraPosition.Distance(Centre) / ToModel,
    ZOOM_MIN, ZOOM_MAX);
end;

end.
