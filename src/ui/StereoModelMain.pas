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
//** takes it farther, stopping at the model's nearest face. A click on its own does nothing. Status and problems are shown in the strip at the
//** bottom and logged with FMX's Log.d.
//**
//** The Stereo button is not wired up yet.
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
  stopping at the model's nearest face. A click on its own does nothing. Status and problems are shown in the strip at the bottom and
  logged with FMX's Log.d.

  The Stereo button is not wired up yet.
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
  Peardox.OrbitalCamera, FmxLinuxMenu;

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
    //** @abstract(Will switch stereo output on and off; not wired up yet.)
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
  private
    //** @abstract(The model shown, owned by the viewport; nil until one has loaded.)
    FModel: TGorillaModel;
    //** @abstract(The file FModel came from, for the open dialog's starting folder.)
    FModelPath: string;
    //** @abstract(The status line in the control strip.)
    FStatus: TLabel;
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
    //** @abstract(Shows a line in the status strip and logs it.)
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
  //** @abstract(The wheel delta of one notch.)
  WHEEL_NOTCH = 120;
  //** @abstract(Room in the control strip kept clear of the status line for btnStereo.)
  STATUS_RIGHT_MARGIN = 96;
  //** @abstract(Gap at the status line's left, in pixels.)
  STATUS_LEFT_MARGIN = 8;

procedure TForm2.FormCreate(Sender: TObject);
begin
  // FIRST: on desktop Linux the main menu is moved onto an FMX menu bar,
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
  FStatus.Margins.Right := STATUS_RIGHT_MARGIN;
  FStatus.WordWrap := False;
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
end;

procedure TForm2.FormShow(Sender: TObject);
begin
  if FLoadQueued then
    Exit;
  FLoadQueued := True;
  // After this event has finished, so the window is drawn before the load
  TThread.ForceQueue(nil, LoadTestModel);
end;

procedure TForm2.ShowStatus(const AText: string);
begin
  FStatus.Text := AText;
  Log.d(AText);
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
    ShowStatus(Format('Target depth %.3f', [PeardoxOrbitalCamera1.Distance]));
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
  NewZoom, Before: Single;
begin
  Handled := True;
  // Rolling the wheel away (positive) brings the view nearer
  NewZoom := EnsureRange(FZoom * Power(ZOOM_STEP, -WheelDelta / WHEEL_NOTCH), ZOOM_MIN, ZOOM_MAX);
  // Zoom multiplies what is there now, in perspective or orthographic, so
  // only the change is passed on
  Before := PeardoxOrbitalCamera1.Distance;
  PeardoxOrbitalCamera1.Zoom(NewZoom / FZoom);
  // In perspective the camera stops at the model's nearest face, so the
  // zoom is what the distance really changed by; then the first notch
  // back out moves the camera at once, however far the wheel went in
  if (PeardoxOrbitalCamera1.ProjectionMode = TGorillaCameraProjection.cpPerspective) and (Before > 0) then
    FZoom := EnsureRange(FZoom * PeardoxOrbitalCamera1.Distance / Before, ZOOM_MIN, ZOOM_MAX)
  else
    FZoom := NewZoom;
end;

end.
