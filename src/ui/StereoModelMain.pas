//** @abstract(Main form of StereoModel: a Gorilla3D viewport seen through the Peardox orbital
//** camera.)
//**
//** For now it tests TPeardoxOrbitalCamera, made in code in FormCreate with its headlight on,
//** before the component is put on the form in the .fmx. Once the form is showing it loads the
//** test model, uvcube.glb from the models folder, into the viewport and frames it so it stays
//** in view at every angle.
//**
//** Mouse, on the viewport: a left drag orbits (Azimuth and PolarAngle), the wheel brings the
//** view nearer or takes it farther, and a right click, or Control-click for a one-button Mac,
//** puts the starting view back. Status and problems are shown in the strip at the bottom and
//** logged with FMX's Log.d.
//**
//** The Stereo button is not wired up yet.
unit StereoModelMain;

{
  Main form of StereoModel: a Gorilla3D viewport seen through the Peardox
  orbital camera.

  For now it tests TPeardoxOrbitalCamera, made in code in FormCreate with
  its headlight on, before the component is put on the form in the .fmx.
  Once the form is showing it loads the test model, uvcube.glb from the
  models folder, into the viewport and frames it so it stays in view at
  every angle.

  Mouse, on the viewport: a left drag orbits (Azimuth and PolarAngle), the
  wheel brings the view nearer or takes it farther, and a right click, or
  Control-click for a one-button Mac, puts the starting view back. Status
  and problems are shown in the strip at the bottom and logged with FMX's
  Log.d.

  The Stereo button is not wired up yet.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.Math, System.Math.Vectors, System.IOUtils,
  FMX.Types, FMX.Types3D, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  Gorilla.Viewport, Gorilla.Model, Gorilla.GLB.Loader,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Menus, FMX.Layouts,
  Peardox.OrbitalCamera;

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
    //** @abstract(Will switch stereo output on and off; not wired up yet.)
    btnStereo: TButton;
    //** @abstract(Holds the viewport inside MainViewLayout.)
    ViewLayout: TLayout;
    //** @abstract(The Gorilla3D viewport, seen through FOrbit's camera.)
    GorillaViewport1: TGorillaViewport;
    //** @abstract(Makes the orbital camera and the status line and hooks up the viewport's
    //** events.)
    //**
    //** @param(Sender The form.)
    procedure FormCreate(Sender: TObject);
    //** @abstract(Queues the test model's load the first time the form is shown, so the
    //** window is drawn first.)
    //**
    //** @param(Sender The form.)
    procedure FormShow(Sender: TObject);
  private
    //** @abstract(The orbital camera component under test, owned by the form.)
    FOrbit: TPeardoxOrbitalCamera;
    //** @abstract(The test model, owned by the viewport; nil until it has loaded.)
    FModel: TGorillaModel;
    //** @abstract(The status line in the control strip.)
    FStatus: TLabel;
    //** @abstract(True once the test model's load has been queued, so FormShow queues it
    //** only once.)
    FLoadQueued: Boolean;
    //** @abstract(True while a left drag is orbiting the camera.)
    FDragging: Boolean;
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
    //** @abstract(Loads the test model into the viewport, stands it upright and frames it.)
    procedure LoadTestModel;
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
    //** @abstract(Viewport OnMouseDown: a left press starts orbiting; a right click or
    //** Control-click resets the view.)
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
    //** @abstract(Viewport OnMouseMove: orbits the camera while the left button is held.)
    //**
    //** @param(Sender The viewport.)
    //**
    //** @param(Shift The keys and buttons held.)
    //**
    //** @param(X The mouse position across the viewport.)
    //**
    //** @param(Y The mouse position down the viewport.)
    procedure ViewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    //** @abstract(Viewport OnMouseUp: letting go of the left button ends the orbit.)
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
  //** @abstract(Padding round the model as a fraction of the view, as in VirtualGamepad.)
  VIEW_MARGIN = 0.08;
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
  FZoom := 1;
  FStatus := TLabel.Create(Self);
  FStatus.Parent := ControlLayout;
  FStatus.Align := TAlignLayout.Client;
  FStatus.Margins.Left := STATUS_LEFT_MARGIN;
  FStatus.Margins.Right := STATUS_RIGHT_MARGIN;
  FStatus.WordWrap := False;
  // The component made in code for the test; once it is proven it goes on
  // the form in the .fmx instead. Setting Viewport at run time makes the
  // camera there at once, and its headlight with it
  FOrbit := TPeardoxOrbitalCamera.Create(Self);
  FOrbit.Headlight := True;
  FOrbit.Viewport := GorillaViewport1;
  if FOrbit.Camera = nil then
    ShowStatus('Orbital camera NOT made: no camera in the viewport')
  else
    ShowStatus(Format('Orbital camera made: FOV %.0f, distance %.2f, headlight %s',
      [FOrbit.FOV, FOrbit.Distance, BoolToStr(FOrbit.Light <> nil, True)]));
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
  begin
    ShowStatus(Format('Model NOT FOUND: %s is in none of: %s', [TEST_MODEL, Tried]));
    Exit;
  end;
  try
    FModel := TGorillaModel.LoadNewModelFromFile(GorillaViewport1, nil, Path, []);
    FModel.Parent := GorillaViewport1;
  except
    on E: Exception do
    begin
      FModel := nil;
      ShowStatus(Format('Model load FAILED: %s: %s: %s', [Path, E.ClassName, E.Message]));
      Exit;
    end;
  end;
  PlaceModel;
  ResetView;
  ShowStatus(Format('Loaded %s; azimuth %.1f, polar %.1f, distance %.2f, headlight %s',
    [Path, FOrbit.Azimuth, FOrbit.PolarAngle, FOrbit.Distance,
     BoolToStr(FOrbit.Light <> nil, True)]));
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
  if not FOrbit.FitToBoundsMax(FModel, VIEW_MARGIN) then
    ShowStatus('Framing FAILED: no camera, an empty model or a viewport with no size')
  else if not SameValue(FZoom, 1) then
    FOrbit.Zoom(FZoom);
end;

procedure TForm2.ResetView;
begin
  FZoom := 1;
  FOrbit.Azimuth := 0;
  FOrbit.PolarAngle := 0;
  FOrbit.Roll := 0;
  FitView;
end;

procedure TForm2.ViewResize(Sender: TObject);
begin
  FitView;
end;

procedure TForm2.ViewMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
  X, Y: Single);
begin
  // A Control-click counts as a right click (one-button Mac), as in Sprite3D
  if (Button = TMouseButton.mbRight) or ((Button = TMouseButton.mbLeft) and (ssCtrl in Shift)) then
  begin
    FDragging := False;
    ResetView;
  end
  else if Button = TMouseButton.mbLeft then
  begin
    FDragging := True;
    FDragLast := PointF(X, Y);
  end;
end;

procedure TForm2.ViewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
  if not FDragging then
    Exit;
  // A button let go outside the view sends no mouse-up, so the first move
  // without it ends the orbit (as in Sprite3D)
  if not (ssLeft in Shift) then
  begin
    FDragging := False;
    Exit;
  end;
  // Dragging right turns the camera right round the centre (owner, 7
  // November 2026: the other way round felt reversed); dragging down
  // raises the camera
  FOrbit.Orbit((X - FDragLast.X) * ORBIT_DEGREES_PER_PIXEL,
    (Y - FDragLast.Y) * ORBIT_DEGREES_PER_PIXEL);
  FDragLast := PointF(X, Y);
end;

procedure TForm2.ViewMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
  X, Y: Single);
begin
  if Button = TMouseButton.mbLeft then
    FDragging := False;
end;

procedure TForm2.ViewMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer;
  var Handled: Boolean);
var
  NewZoom: Single;
begin
  Handled := True;
  // Rolling the wheel away (positive) brings the view nearer
  NewZoom := EnsureRange(FZoom * Power(ZOOM_STEP, -WheelDelta / WHEEL_NOTCH), ZOOM_MIN, ZOOM_MAX);
  // Zoom multiplies what is there now, in perspective or orthographic, so
  // only the change is passed on
  FOrbit.Zoom(NewZoom / FZoom);
  FZoom := NewZoom;
end;

end.
