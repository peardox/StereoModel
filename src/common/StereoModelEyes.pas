//** @abstract(First light for glasses-free 3D: TPeardoxGorillaEyes draws the Gorilla3D view
//** once per eye and hands the pair to TPeardoxLeiaSR to weave.)
//**
//** A first try, kept in the program until it works; then it becomes a component in lib. Each
//** frame it:
//**
//** @orderedList(
//**   @item(reads the tracked eyes (millimetres from the display's centre) from
//**     TPeardoxLeiaSR, or uses a fixed viewer in front of the view when the eyes are not
//**     tracked or LookAround is off, with the saved eye separation;)
//**   @item(for each eye, moves the orbital camera's own Gorilla3D camera sideways and up or
//**     down from where it sits, turns it, renders the viewport (ManualRendering,
//**     RenderManual) and takes the picture (MakeScreenshot);)
//**   @item(puts the camera back exactly as it was;)
//**   @item(copies the two pictures side by side, left eye on the left, shifted sideways
//**     where Convergence says, and passes them to TPeardoxLeiaSR.SubmitViews, which weaves
//**     them in the bridge's window over the view.)
//** )
//**
//** Frames are drawn whenever the program is idle (Application.OnIdle, any handler already
//** there still called), so they come as fast as they can be drawn while mouse, keyboard,
//** paints and timers are still handled in between; the bridge waits for the display's
//** vertical blank when it presents, which keeps them to its refresh rate. A timer draws one if
//** none has come for PEARDOX_EYES_WATCHDOG_MS, in case something keeps the program from
//** going idle.
//**
//** The geometry. The orbit centre, the target, is at the target depth D in front of the
//** camera: that plane lies on the display's glass. An eye at (dx, dy, dz) mm from the view's
//** centre on the display is put at (dx, dy) * D / dz in the camera's own plane, so it sees
//** the view's centre at the same angle as the real eye does, and keeps the field of view
//** (Gorilla3D does not draw a field-of-view change made while running).
//**
//** Convergence, making the target land on the same place in both pictures:
//** @unorderedList(
//**   @item(ecShift (the default): both cameras are turned alike, towards the target from the
//**     midpoint between the eyes, so they stay parallel to each other, and each picture is
//**     shifted sideways by its eye's half of the separation, which brings the target back to
//**     the middle. This is the off-axis frustum a stereo pair needs, made from Gorilla3D's
//**     symmetric one; it leaves a thin black strip at the outer edge of each picture.)
//**   @item(ecToeIn: each camera is turned to look at the target itself. No strip, but the two
//**     pictures are keystoned differently, so the corners do not line up vertically and look
//**     double.)
//** )
//**
//** The turn's signs are not assumed: Start tries the four combinations on a test offset and
//** keeps the one whose view direction (AbsoluteDirection) points at the orbit centre, and logs
//** it. SwapEyes swaps the two views, for when depth comes out inverted; ShiftSign reverses the
//** shift, for when ecShift makes things worse rather than better.
unit StereoModelEyes;

{
  First light for glasses-free 3D: TPeardoxGorillaEyes draws the Gorilla3D
  view once per eye and hands the pair to TPeardoxLeiaSR to weave.

  Kept in the program until it works; then it becomes a component in lib.
  Each frame: read the eyes; per eye, move and turn the orbital camera's
  Gorilla3D camera, RenderManual and MakeScreenshot; put the camera back;
  copy the pair side by side, shifted (ecShift) or not (ecToeIn), and pass
  it to TPeardoxLeiaSR.SubmitViews. Frames are drawn whenever the program
  is idle, with a timer as a watchdog.
  An eye (dx, dy, dz) mm from the view's centre goes to (dx, dy) * D / dz
  in the camera's plane, D the target depth (the plane on the glass).
}

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  System.Math.Vectors, System.Diagnostics,
  FMX.Types, FMX.Types3D, FMX.Controls3D, FMX.Graphics, FMX.Forms,
  Gorilla.Viewport, Gorilla.Camera, Peardox.OrbitalCamera, Peardox.LeiaSR,
  Peardox.LeiaSR.Settings, Peardox.LeiaSR.Api;

const
  //** @abstract(Milliseconds without a frame after which the watchdog timer draws one.)
  PEARDOX_EYES_WATCHDOG_MS = 50;
  //** @abstract(Distance in millimetres of the fixed viewer used when the eyes are not tracked
  //** or LookAround is off.)
  PEARDOX_EYES_NOMINAL_VIEWER_MM = 650;
  //** @abstract(The nearest an eye is taken to be to the glass, in millimetres, so a bad reading
  //** cannot throw the camera far out.)
  PEARDOX_EYES_MIN_EYE_DISTANCE_MM = 100;

type
  //** @abstract(How the two pictures are made to converge on the target; see the unit
  //** description.)
  TPeardoxEyesConvergence = (
    //** @abstract(Parallel cameras, pictures shifted: the off-axis frustum.)
    ecShift,
    //** @abstract(Each camera turned to the target.)
    ecToeIn);

  //** @abstract(A line for the log.)
  //**
  //** @param(Sender The TPeardoxGorillaEyes.)
  //**
  //** @param(AText The line.)
  TPeardoxGorillaEyesLogEvent = procedure(Sender: TObject; const AText: string) of object;

  //** @abstract(Draws the Gorilla3D view once per eye and hands the pair to TPeardoxLeiaSR to
  //** weave; see the unit description.)
  //**
  //** Set LeiaSR, Camera and Viewport, then Start once LeiaSR is running (its OnStarted), and
  //** Stop before it stops.
  TPeardoxGorillaEyes = class(TComponent)
  private
    //** @abstract(See LeiaSR.)
    FLeiaSR: TPeardoxLeiaSR;
    //** @abstract(See Camera.)
    FCamera: TPeardoxOrbitalCamera;
    //** @abstract(See Viewport.)
    FViewport: TGorillaViewport;
    //** @abstract(See Active.)
    FActive: Boolean;
    //** @abstract(See SwapEyes.)
    FSwapEyes: Boolean;
    //** @abstract(See RenderBeforeShot.)
    FRenderBeforeShot: Boolean;
    //** @abstract(See Convergence.)
    FConvergence: TPeardoxEyesConvergence;
    //** @abstract(See ShiftSign.)
    FShiftSign: Integer;
    //** @abstract(Draws a frame when none has come from the idle loop for a while.)
    FWatchdog: TTimer;
    //** @abstract(The Application.OnIdle handler there before Start, called first and put back
    //** by Stop.)
    FSavedIdle: TIdleEvent;
    //** @abstract(True while AppIdle is Application.OnIdle.)
    FIdleHooked: Boolean;
    //** @abstract(When the last frame was drawn (TThread.GetTickCount64).)
    FLastFrameTick: UInt64;
    //** @abstract(Frames drawn by the watchdog since the last log line.)
    FWatchdogFrames: Integer;
    //** @abstract(Black pixels to fill the strip a shift leaves, kept between frames.)
    FBlack: TBytes;
    //** @abstract(The last frame's shifts in pixels: left eye, right eye.)
    FLastShift: array[0..1] of Integer;
    //** @abstract(The widest each eye's view is woven at, in pixels: the display's recommended
    //** view width, read at Start; 0 for no limit.)
    FMaxViewWidth: Integer;
    //** @abstract(See OnLog.)
    FOnLog: TPeardoxGorillaEyesLogEvent;
    //** @abstract(The side-by-side image handed to the bridge, kept between frames.)
    FBuffer: TBytes;
    //** @abstract(The sign of the turn about the camera's Y axis that looks back at the orbit
    //** centre, found by Calibrate.)
    FYawSign: Integer;
    //** @abstract(The sign of the turn about the camera's X axis, likewise.)
    FPitchSign: Integer;
    //** @abstract(The viewport's UseFixedFrameRate before Start, put back by Stop.)
    FSavedFixedRate: Boolean;
    //** @abstract(The viewport's ManualRendering before Start, put back by Stop.)
    FSavedManual: Boolean;
    //** @abstract(True while a frame is being drawn, so a timer tick cannot start another.)
    FInFrame: Boolean;
    //** @abstract(Frames since the last log line.)
    FFrames: Integer;
    //** @abstract(See WovenFrames.)
    FWovenFrames: Int64;
    //** @abstract(Milliseconds spent since the last log line in RenderManual, both eyes.)
    FRenderMs: Double;
    //** @abstract(Milliseconds spent in MakeScreenshot, both eyes.)
    FShotMs: Double;
    //** @abstract(Milliseconds spent copying the pair side by side.)
    FCopyMs: Double;
    //** @abstract(Milliseconds spent in SubmitViews.)
    FSubmitMs: Double;
    //** @abstract(The longest whole frame since the last log line, in milliseconds.)
    FWorstMs: Double;
    //** @abstract(When the last log line was written (TThread.GetTickCount64).)
    FLastLogTick: UInt64;
    //** @abstract(The last frame's camera offsets: left eye X, Y, right eye X, Y, scene units.)
    FLastOffsets: array[0..3] of Single;
    //** @abstract(The last frame's view size and pixel format, for the log.)
    FLastViewInfo: string;
    //** @abstract(Where the last frame's eyes came from, for the log.)
    FLastEyesFrom: string;
    //** @abstract(The eyes the last frame was drawn from (after the saved separation and
    //** SwapEyes), millimetres: left, right.)
    FLastEyes: array[0..1] of TPoint3D;
    //** @abstract(The last frame's rate and timings, as logged once a second, for LogSnapshot.)
    FLastRateText: string;
    //** @abstract(Sets Viewport, watching for it being freed.)
    //**
    //** @param(AValue The viewport.)
    procedure SetViewport(const AValue: TGorillaViewport);
    //** @abstract(Sets Camera, watching for it being freed.)
    //**
    //** @param(AValue The orbital camera.)
    procedure SetCamera(const AValue: TPeardoxOrbitalCamera);
    //** @abstract(Sets LeiaSR, watching for it being freed.)
    //**
    //** @param(AValue The LeiaSR component.)
    procedure SetLeiaSR(const AValue: TPeardoxLeiaSR);
    //** @abstract(Passes a line to OnLog.)
    //**
    //** @param(AText The line.)
    procedure Log(const AText: string);
    //** @abstract(Draws and submits one frame.)
    procedure Frame;
    //** @abstract(Application.OnIdle while Active: calls the handler that was there, draws a
    //** frame and asks to be called again.)
    //**
    //** @param(Sender The application.)
    //**
    //** @param(Done Set to False, so idle calls keep coming.)
    procedure AppIdle(Sender: TObject; var Done: Boolean);
    //** @abstract(The watchdog: draws a frame if none has come for PEARDOX_EYES_WATCHDOG_MS.)
    //**
    //** @param(Sender FWatchdog.)
    procedure WatchdogTick(Sender: TObject);
    //** @abstract(The two eyes to draw from, in millimetres from the display's centre.)
    //**
    //** @param(ALeft Set to the left eye.)
    //**
    //** @param(ARight Set to the right eye.)
    procedure EyePair(out ALeft, ARight: TPoint3D);
    //** @abstract(Where the camera goes for one eye, in its own plane.)
    //**
    //** @param(AEyeMM The eye, millimetres from the display's centre.)
    //**
    //** @param(ADepth The target depth D.)
    //**
    //** @param(AOX Set to the sideways offset, scene units, camera X (right).)
    //**
    //** @param(AOY Set to the up or down offset, scene units, camera Y (FMX's down).)
    //**
    //** @returns(False if the view's place on the display is not known yet.)
    function EyeOffset(const AEyeMM: TPoint3D; ADepth: Single; out AOX, AOY: Single): Boolean;
    //** @abstract(Puts the camera at an offset in its own plane, turned as if it stood at
    //** another offset looking at the orbit centre, with the given signs.)
    //**
    //** @param(AOX Sideways offset.)
    //**
    //** @param(AOY Up or down offset.)
    //**
    //** @param(ATurnX The sideways offset the turn is worked out for: AOX for toe-in, the
    //** midpoint between the eyes for ecShift.)
    //**
    //** @param(ATurnY The up or down offset the turn is worked out for.)
    //**
    //** @param(AYawSign Sign of the turn about Y.)
    //**
    //** @param(APitchSign Sign of the turn about X.)
    procedure PoseCamera(AOX, AOY, ATurnX, ATurnY: Single; AYawSign, APitchSign: Integer);
    //** @abstract(Finds FYawSign and FPitchSign: tries the four, keeps the one whose view
    //** direction points at the orbit centre, and puts the camera back.)
    //**
    //** @returns(True if one matched closely.)
    function Calibrate: Boolean;
    //** @abstract(Renders one eye's view and takes its picture.)
    //**
    //** @param(AOX Sideways offset.)
    //**
    //** @param(AOY Up or down offset.)
    //**
    //** @param(ATurnX Sideways offset the turn is worked out for.)
    //**
    //** @param(ATurnY Up or down offset the turn is worked out for.)
    //**
    //** @returns(The picture, for the caller to free; nil if Gorilla3D gave none.)
    function RenderEye(AOX, AOY, ATurnX, ATurnY: Single): TBitmap;
    //** @abstract(How far to shift one eye's picture so the target lands in its middle, for
    //** ecShift.)
    //**
    //** @param(AOffset The eye's sideways offset from the midpoint between the eyes, scene
    //** units.)
    //**
    //** @param(AWidth The picture's width in pixels.)
    //**
    //** @param(AHeight The picture's height in pixels.)
    //**
    //** @returns(Pixels to move the picture right (negative: left).)
    function ShiftFor(AOffset: Single; AWidth, AHeight: Integer): Integer;
    //** @abstract(Copies one picture's rows into its half of FBuffer, moved right by AShift
    //** pixels (left when negative), the uncovered strip black, taking every AStep-th pixel of
    //** every AStep-th row.)
    //**
    //** @param(AData The picture, mapped for reading.)
    //**
    //** @param(AX0 Byte offset of its half within each row of FBuffer.)
    //**
    //** @param(AWidth Width in pixels of one eye's view in FBuffer.)
    //**
    //** @param(AHeight Height in pixels in FBuffer.)
    //**
    //** @param(APitch Bytes per row of FBuffer.)
    //**
    //** @param(AShift Pixels (of FBuffer) to move it right.)
    //**
    //** @param(AStep 1 to copy the picture as it is, 2 to halve it, and so on.)
    procedure CopyEye(const AData: TBitmapData; AX0, AWidth, AHeight, APitch, AShift,
      AStep: Integer);
    //** @abstract(Copies the two pictures side by side into FBuffer, shifted, and submits them.)
    //**
    //** @param(ALeft The left eye's picture.)
    //**
    //** @param(ARight The right eye's picture.)
    //**
    //** @param(AShiftL Pixels to move the left picture right.)
    //**
    //** @param(AShiftR Pixels to move the right picture right.)
    procedure Submit(ALeft, ARight: TBitmap; AShiftL, AShiftR: Integer);
  protected
    //** @abstract(Forgets a linked component when it is freed, stopping first.)
    //**
    //** @param(AComponent The component going or coming.)
    //**
    //** @param(Operation Whether it is being inserted or removed.)
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    //** @abstract(Creates it, not active.)
    //**
    //** @param(AOwner The owner, normally the form.)
    constructor Create(AOwner: TComponent); override;
    //** @abstract(Stops and frees it.)
    destructor Destroy; override;
    //** @abstract(Starts drawing: the viewport to manual rendering, the turn's signs found,
    //** LeiaSR set Weaving, the frames begun.)
    //**
    //** @returns(True if it started; False, with the reason logged, if LeiaSR is not running or
    //** something is not set.)
    function Start: Boolean;
    //** @abstract(Stops drawing: LeiaSR's Weaving off and the viewport's rendering put back.)
    procedure Stop;
    //** @abstract(Logs everything that sets what the viewer sees, as one block marked
    //** SNAPSHOT, in the same terms as SRDelphiFMX's TSRStereoRenderer.LogSnapshot, so a view
    //** that looks right there can be compared with this one.)
    //**
    //** The world-to-millimetre scale is the one the geometry implies: the view's height on
    //** the display over the height the field of view takes in at the target depth. From it
    //** come the glass's distance from the camera and the eyes' true distance and separation
    //** in scene units, beside the distance and separation the cameras are really put at.
    //**
    //** @param(ANote A line from the program to head the block (the view's angles, say); empty
    //** for none.)
    procedure LogSnapshot(const ANote: string);
    //** @abstract(True while frames are drawn.)
    property Active: Boolean read FActive;
    //** @abstract(Frames the bridge has woven (SubmitViews answered SRB_OK) since Start.)
    property WovenFrames: Int64 read FWovenFrames;
    //** @abstract(The LeiaSR component the frames are woven by.)
    property LeiaSR: TPeardoxLeiaSR read FLeiaSR write SetLeiaSR;
    //** @abstract(The orbital camera: its Gorilla3D camera is the one moved for each eye, and its
    //** Distance is the target depth.)
    property Camera: TPeardoxOrbitalCamera read FCamera write SetCamera;
    //** @abstract(The viewport drawn.)
    property Viewport: TGorillaViewport read FViewport write SetViewport;
    //** @abstract(Swaps the two views, for when depth comes out inverted (near things behind the
    //** glass).)
    property SwapEyes: Boolean read FSwapEyes write FSwapEyes;
    //** @abstract(True (the default) to call RenderManual before each MakeScreenshot; False to
    //** rely on MakeScreenshot rendering by itself. The log's timings show what each costs.)
    property RenderBeforeShot: Boolean read FRenderBeforeShot write FRenderBeforeShot;
    //** @abstract(How the pictures converge on the target: ecShift (the default) or ecToeIn.)
    property Convergence: TPeardoxEyesConvergence read FConvergence write FConvergence;
    //** @abstract(-1 (the default) or 1: the direction ecShift moves the pictures. -1 since
    //** the owner's test (7 November 2026): 1 doubled the mismatch instead of cancelling it.)
    property ShiftSign: Integer read FShiftSign write FShiftSign;
    //** @abstract(Every line of its log: the start, the signs found, and once a second the
    //** frame rate, the time in each stage and the offsets.)
    property OnLog: TPeardoxGorillaEyesLogEvent read FOnLog write FOnLog;
  end;

implementation

uses
  System.StrUtils;

{ TPeardoxGorillaEyes }

constructor TPeardoxGorillaEyes.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FRenderBeforeShot := True;
  FConvergence := ecShift;
  // The owner's test (7 November 2026, 17:58): the reversed shift looked
  // right, so the picture's right is the camera's -X here
  FShiftSign := -1;
  FYawSign := 1;
  FPitchSign := 1;
  FWatchdog := TTimer.Create(Self);
  FWatchdog.Enabled := False;
  FWatchdog.Interval := PEARDOX_EYES_WATCHDOG_MS;
  FWatchdog.OnTimer := WatchdogTick;
end;

destructor TPeardoxGorillaEyes.Destroy;
begin
  Stop;
  inherited Destroy;
end;

procedure TPeardoxGorillaEyes.AppIdle(Sender: TObject; var Done: Boolean);
begin
  if Assigned(FSavedIdle) then
    FSavedIdle(Sender, Done);
  Frame;
  // Keep the idle calls coming while frames are wanted
  Done := not FActive;
end;

procedure TPeardoxGorillaEyes.WatchdogTick(Sender: TObject);
begin
  if FActive and (TThread.GetTickCount64 - FLastFrameTick >= PEARDOX_EYES_WATCHDOG_MS) then
  begin
    Inc(FWatchdogFrames);
    Frame;
  end;
end;

procedure TPeardoxGorillaEyes.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation <> opRemove then
    Exit;
  if (AComponent = FLeiaSR) or (AComponent = FCamera) or (AComponent = FViewport) then
    Stop;
  if AComponent = FLeiaSR then
    FLeiaSR := nil;
  if AComponent = FCamera then
    FCamera := nil;
  if AComponent = FViewport then
    FViewport := nil;
end;

procedure TPeardoxGorillaEyes.SetViewport(const AValue: TGorillaViewport);
begin
  if AValue = FViewport then
    Exit;
  Stop;
  if FViewport <> nil then
    FViewport.RemoveFreeNotification(Self);
  FViewport := AValue;
  if FViewport <> nil then
    FViewport.FreeNotification(Self);
end;

procedure TPeardoxGorillaEyes.SetCamera(const AValue: TPeardoxOrbitalCamera);
begin
  if AValue = FCamera then
    Exit;
  Stop;
  if FCamera <> nil then
    FCamera.RemoveFreeNotification(Self);
  FCamera := AValue;
  if FCamera <> nil then
    FCamera.FreeNotification(Self);
end;

procedure TPeardoxGorillaEyes.SetLeiaSR(const AValue: TPeardoxLeiaSR);
begin
  if AValue = FLeiaSR then
    Exit;
  Stop;
  if FLeiaSR <> nil then
    FLeiaSR.RemoveFreeNotification(Self);
  FLeiaSR := AValue;
  if FLeiaSR <> nil then
    FLeiaSR.FreeNotification(Self);
end;

procedure TPeardoxGorillaEyes.Log(const AText: string);
begin
  if Assigned(FOnLog) and not (csDestroying in ComponentState) then
    FOnLog(Self, AText);
end;

function TPeardoxGorillaEyes.Start: Boolean;
var
  Info: TSRBDisplayInfo;
begin
  Result := FActive;
  if FActive then
    Exit;
  if (FLeiaSR = nil) or not FLeiaSR.Running then
  begin
    Log('Eyes NOT started: LeiaSR is not running');
    Exit;
  end;
  if (FCamera = nil) or (FCamera.Camera = nil) or (FViewport = nil) then
  begin
    Log('Eyes NOT started: the camera or the viewport is not set');
    Exit;
  end;
  if FCamera.ProjectionMode <> TGorillaCameraProjection.cpPerspective then
    Log('Eyes: the camera is not in perspective; the two views will differ only sideways');
  // Gorilla3D renders only when told: two renders a frame, one per eye
  FSavedFixedRate := FViewport.UseFixedFrameRate;
  FSavedManual := FViewport.ManualRendering;
  FViewport.UseFixedFrameRate := False;
  FViewport.ManualRendering := True;
  if not Calibrate then
    Log('Eyes: no turn matched the orbit centre closely; using the best found');
  FFrames := 0;
  FWovenFrames := 0;
  FRenderMs := 0;
  FShotMs := 0;
  FCopyMs := 0;
  FSubmitMs := 0;
  FWorstMs := 0;
  FLastLogTick := TThread.GetTickCount64;
  // The display weaves each eye at its recommended view size; anything
  // larger is wasted copying and uploading
  if FLeiaSR.DisplayInfo(Info) and (Info.recommendedViewWidth > 0) then
    FMaxViewWidth := Info.recommendedViewWidth
  else
    FMaxViewWidth := 0;
  Log(Format('Eyes: each eye woven at most %d pixels wide (the display''s recommended view; ' +
    '0 = no limit)', [FMaxViewWidth]));
  FLeiaSR.Weaving := True;
  FActive := True;
  FWatchdogFrames := 0;
  FLastFrameTick := TThread.GetTickCount64;
  FSavedIdle := Application.OnIdle;
  Application.OnIdle := AppIdle;
  FIdleHooked := True;
  FWatchdog.Enabled := True;
  Log(Format('Eyes started: %s at the target depth %.3f, shift sign %d, RenderManual before ' +
    'each screenshot %s, eyes swapped %s', [IfThen(FConvergence = ecShift,
    'parallel cameras + shift', 'toe-in'), FCamera.Distance, FShiftSign,
    BoolToStr(FRenderBeforeShot, True), BoolToStr(FSwapEyes, True)]));
  Result := True;
end;

procedure TPeardoxGorillaEyes.Stop;
var
  Mine: TIdleEvent;
begin
  if FWatchdog <> nil then
    FWatchdog.Enabled := False;
  if FIdleHooked then
  begin
    // Put back what was there, unless someone has replaced it since
    Mine := AppIdle;
    if (TMethod(Application.OnIdle).Code = TMethod(Mine).Code) and
      (TMethod(Application.OnIdle).Data = TMethod(Mine).Data) then
      Application.OnIdle := FSavedIdle;
    FIdleHooked := False;
  end;
  if not FActive then
    Exit;
  FActive := False;
  if (FLeiaSR <> nil) and not (csDestroying in FLeiaSR.ComponentState) then
    FLeiaSR.Weaving := False;
  if (FViewport <> nil) and not (csDestroying in FViewport.ComponentState) then
  begin
    FViewport.ManualRendering := FSavedManual;
    FViewport.UseFixedFrameRate := FSavedFixedRate;
    FViewport.Invalidate;
  end;
  Log('Eyes stopped: the viewport renders by itself again');
end;

procedure TPeardoxGorillaEyes.EyePair(out ALeft, ARight: TPoint3D);
var
  Mid, Dir: TPoint3D;
  Sep: Single;
  Fixed: Boolean;
begin
  Sep := FLeiaSR.Settings.EyeSeparationMM;
  Fixed := not (FLeiaSR.Settings.LookAround and FLeiaSR.EyesTracked);
  if Fixed then
  begin
    // A viewer straight in front of the view's centre
    if Sep <= 0 then
      Sep := PEARDOX_DEFAULT_EYE_SEPARATION_MM;
    Mid := Point3D(FLeiaSR.WindowCenterMM.X, FLeiaSR.WindowCenterMM.Y,
      PEARDOX_EYES_NOMINAL_VIEWER_MM);
    ALeft := Mid - Point3D(Sep / 2, 0, 0);
    ARight := Mid + Point3D(Sep / 2, 0, 0);
    if FLeiaSR.EyesTracked then
      FLastEyesFrom := 'fixed viewer (LookAround off)'
    else
      FLastEyesFrom := 'fixed viewer (eyes not tracked)';
  end
  else
  begin
    ALeft := FLeiaSR.LeftEyeMM;
    ARight := FLeiaSR.RightEyeMM;
    FLastEyesFrom := 'tracked';
    // The saved separation instead of the tracker's, which wanders, about
    // the tracked midpoint
    if Sep > 0 then
    begin
      Mid := (ALeft + ARight) * 0.5;
      Dir := (ARight - ALeft).Normalize;
      ALeft := Mid - Dir * (Sep / 2);
      ARight := Mid + Dir * (Sep / 2);
      FLastEyesFrom := Format('tracked, separation %.0f mm', [Sep]);
    end;
  end;
end;

function TPeardoxGorillaEyes.EyeOffset(const AEyeMM: TPoint3D; ADepth: Single;
  out AOX, AOY: Single): Boolean;
var
  DX, DY, DZ: Single;
begin
  AOX := 0;
  AOY := 0;
  Result := FLeiaSR.WindowSizeMM.Height > 0;
  if not Result then
    Exit;
  DX := AEyeMM.X - FLeiaSR.WindowCenterMM.X;
  DY := AEyeMM.Y - FLeiaSR.WindowCenterMM.Y;
  DZ := Max(AEyeMM.Z, PEARDOX_EYES_MIN_EYE_DISTANCE_MM);
  // The eye sees the view's centre at the angle the real eye does; FMX's
  // Y is down, the display's up
  AOX := DX * ADepth / DZ;
  AOY := -DY * ADepth / DZ;
end;

procedure TPeardoxGorillaEyes.PoseCamera(AOX, AOY, ATurnX, ATurnY: Single;
  AYawSign, APitchSign: Integer);
var
  D, Yaw, Pitch: Single;
begin
  D := FCamera.Distance;
  // In the camera's own plane, D in front of the orbit centre, turned as
  // if it stood at (ATurnX, ATurnY) looking back at it
  Yaw := RadToDeg(ArcTan2(ATurnX, D));
  Pitch := RadToDeg(ArcTan2(ATurnY, Sqrt(Sqr(ATurnX) + Sqr(D))));
  FCamera.Camera.Position.Point := Point3D(AOX, AOY, -D);
  FCamera.Camera.RotationAngle.Point := Point3D(APitchSign * Pitch, AYawSign * Yaw, 0);
end;

procedure TPeardoxGorillaEyes.LogSnapshot(const ANote: string);
const
  LensNames: array[TPeardoxLeiaSRLensState] of string = ('not known', 'on', 'off');
var
  Info: TSRBDisplayInfo;
  D, TanV, Scale, MidZ, Sep, CamSep: Single;

  //** @abstract(A point for the log.)
  //**
  //** @param(P The point.)
  //**
  //** @returns(Its coordinates to one place, in brackets.)
  function Pt(const P: TPoint3D): string;
  begin
    Result := Format('(%.1f, %.1f, %.1f)', [P.X, P.Y, P.Z]);
  end;

begin
  Log('=== SNAPSHOT ===');
  if ANote <> '' then
    Log('  ' + ANote);
  if (FLeiaSR = nil) or not FLeiaSR.Running or (FCamera = nil) then
  begin
    Log('  LeiaSR is not running');
    Log('=== END SNAPSHOT ===');
    Exit;
  end;
  if FLeiaSR.DisplayInfo(Info) then
    Log(Format('  display %d x %d px, %.1f x %.1f mm, recommended view %d x %d per eye',
      [Info.resolutionWidth, Info.resolutionHeight, Info.physicalWidthMM, Info.physicalHeightMM,
       Info.recommendedViewWidth, Info.recommendedViewHeight]));
  Log(Format('  viewport on the display: centre (%.1f, %.1f) mm, %.1f x %.1f mm, view %s',
    [FLeiaSR.WindowCenterMM.X, FLeiaSR.WindowCenterMM.Y, FLeiaSR.WindowSizeMM.Width,
     FLeiaSR.WindowSizeMM.Height, FLastViewInfo]));
  Log(Format('  eyes tracked L%s R%s mm (%s), drawn from L%s R%s mm (%s), look-around %s, ' +
    'lens %s', [Pt(FLeiaSR.LeftEyeMM), Pt(FLeiaSR.RightEyeMM),
    IfThen(FLeiaSR.EyesTracked, 'tracked', 'NOT tracked'), Pt(FLastEyes[0]), Pt(FLastEyes[1]),
    FLastEyesFrom, BoolToStr(FLeiaSR.Settings.LookAround, True),
    LensNames[FLeiaSR.LensState]]));
  Log(Format('  settings: EyeSeparationMM %.1f (0 = tracked), LatencyFrames %d, LensMode %d',
    [FLeiaSR.Settings.EyeSeparationMM, FLeiaSR.Settings.LatencyFrames,
     FLeiaSR.Settings.LensMode]));
  D := FCamera.Distance;
  TanV := Tan(DegToRad(FCamera.FOV) / 2);
  Log(Format('  camera: vertical field of view %.2f deg (tan half %.4f), target depth %.3f, ' +
    '%s, shift sign %d, shifts L %d R %d px, eyes swapped %s', [FCamera.FOV, TanV, D,
    IfThen(FConvergence = ecShift, 'parallel cameras + shift', 'toe-in'), FShiftSign,
    FLastShift[0], FLastShift[1], BoolToStr(FSwapEyes, True)]));
  if FLeiaSR.WindowSizeMM.Height > 0 then
  begin
    // The view's height at the target depth is the view's height on the
    // display: world units per mm, as SRDelphiFMX's scale
    Scale := 2 * D * TanV / FLeiaSR.WindowSizeMM.Height;
    MidZ := (FLastEyes[0].Z + FLastEyes[1].Z) / 2;
    Sep := FLastEyes[0].Distance(FLastEyes[1]);
    CamSep := Sqrt(Sqr(FLastOffsets[2] - FLastOffsets[0]) + Sqr(FLastOffsets[3] - FLastOffsets[1]));
    Log(Format('  scale %.6f world units per mm (%.3f mm per unit): the glass is %.3f units ' +
      'from the camera (%.0f mm); the eyes are %.0f mm = %.3f units from the glass, %.1f mm ' +
      '= %.3f units apart; the cameras are put %.3f units from the glass (%.0f mm), %.3f units ' +
      'apart (%.1f mm)', [Scale, 1 / Scale, D, D / Scale, MidZ, MidZ * Scale, Sep, Sep * Scale,
      D, D / Scale, CamSep, CamSep / Scale]));
  end;
  Log(Format('  camera offsets L(%.3f, %.3f) R(%.3f, %.3f), turn signs yaw %d pitch %d',
    [FLastOffsets[0], FLastOffsets[1], FLastOffsets[2], FLastOffsets[3], FYawSign, FPitchSign]));
  if FLastRateText <> '' then
    Log('  ' + FLastRateText);
  Log('=== END SNAPSHOT ===');
end;

function TPeardoxGorillaEyes.Calibrate: Boolean;
var
  Cam: TControl3D;
  Pivot: TControl3D;
  SavedPos, SavedRot, Want, Got: TPoint3D;
  V: TVector3D;
  SY, SX, BestY, BestX: Integer;
  Dot, Best: Single;
  Scores: string;
begin
  Cam := FCamera.Camera;
  Result := False;
  if not (Cam.Parent is TControl3D) then
  begin
    Log('Eyes: the camera has no 3D parent; turn signs assumed +1');
    Exit;
  end;
  Pivot := TControl3D(Cam.Parent);
  SavedPos := Cam.Position.Point;
  SavedRot := Cam.RotationAngle.Point;
  Best := -2;
  BestY := 1;
  BestX := 1;
  Scores := '';
  try
    for SY := -1 to 1 do
      for SX := -1 to 1 do
      begin
        if (SY = 0) or (SX = 0) then
          Continue;
        // A test offset well off the axis in both directions
        PoseCamera(FCamera.Distance * 0.3, FCamera.Distance * 0.2, FCamera.Distance * 0.3,
          FCamera.Distance * 0.2, SY, SX);
        V := Pivot.AbsolutePosition - Cam.AbsolutePosition;
        Want := Point3D(V.X, V.Y, V.Z).Normalize;
        V := Cam.AbsoluteDirection;
        Got := Point3D(V.X, V.Y, V.Z).Normalize;
        Dot := Want.DotProduct(Got);
        Scores := Scores + Format(' (%d, %d) %.4f', [SY, SX, Dot]);
        if Dot > Best then
        begin
          Best := Dot;
          BestY := SY;
          BestX := SX;
        end;
      end;
  finally
    Cam.Position.Point := SavedPos;
    Cam.RotationAngle.Point := SavedRot;
  end;
  FYawSign := BestY;
  FPitchSign := BestX;
  Result := Best > 0.999;
  Log(Format('Eyes: turn signs yaw %d, pitch %d (match %.5f; tried (yaw, pitch):%s)',
    [FYawSign, FPitchSign, Best, Scores]));
end;

function TPeardoxGorillaEyes.RenderEye(AOX, AOY, ATurnX, ATurnY: Single): TBitmap;
var
  Watch: TStopwatch;
begin
  PoseCamera(AOX, AOY, ATurnX, ATurnY, FYawSign, FPitchSign);
  Watch := TStopwatch.StartNew;
  if FRenderBeforeShot then
    FViewport.RenderManual;
  FRenderMs := FRenderMs + Watch.Elapsed.TotalMilliseconds;
  Watch := TStopwatch.StartNew;
  Result := FViewport.MakeScreenshot;
  FShotMs := FShotMs + Watch.Elapsed.TotalMilliseconds;
end;

function TPeardoxGorillaEyes.ShiftFor(AOffset: Single; AWidth, AHeight: Integer): Integer;
var
  TanH, D: Single;
begin
  D := FCamera.Distance;
  // The horizontal half field of view, from the vertical FOV and the shape
  TanH := Tan(DegToRad(FCamera.FOV) / 2) * AWidth / Max(AHeight, 1);
  Result := 0;
  if (D <= 0) or (TanH <= 0) then
    Exit;
  // A camera AOffset to the side of the midpoint sees the target AOffset
  // the other way, AOffset / (D * TanH) of the half width; the shift moves
  // it back to the middle
  Result := FShiftSign * Round(AOffset / (D * TanH) * AWidth / 2);
  Result := EnsureRange(Result, -AWidth div 4, AWidth div 4);
end;

procedure TPeardoxGorillaEyes.CopyEye(const AData: TBitmapData; AX0, AWidth, AHeight, APitch,
  AShift, AStep: Integer);
var
  Y, X, Keep, Gap: Integer;
  Src: PByte;
  SrcPx, DstPx: PCardinal;
begin
  Gap := Min(Abs(AShift), AWidth);
  Keep := AWidth - Gap;
  for Y := 0 to AHeight - 1 do
  begin
    Src := AData.GetScanline(Y * AStep);
    if AStep = 1 then
    begin
      if AShift >= 0 then
      begin
        // Moved right: black on the left
        if Gap > 0 then
          Move(FBlack[0], FBuffer[Y * APitch + AX0], Gap * 4);
        Move(Src^, FBuffer[Y * APitch + AX0 + Gap * 4], Keep * 4);
      end
      else
      begin
        // Moved left: black on the right
        Move((Src + Gap * 4)^, FBuffer[Y * APitch + AX0], Keep * 4);
        Move(FBlack[0], FBuffer[Y * APitch + AX0 + Keep * 4], Gap * 4);
      end;
    end
    else
    begin
      // Every AStep-th pixel of every AStep-th row: the picture made
      // smaller to the size the display weaves at
      if AShift >= 0 then
      begin
        if Gap > 0 then
          Move(FBlack[0], FBuffer[Y * APitch + AX0], Gap * 4);
        SrcPx := PCardinal(Src);
        DstPx := PCardinal(@FBuffer[Y * APitch + AX0 + Gap * 4]);
      end
      else
      begin
        SrcPx := PCardinal(Src + Gap * AStep * 4);
        DstPx := PCardinal(@FBuffer[Y * APitch + AX0]);
        Move(FBlack[0], FBuffer[Y * APitch + AX0 + Keep * 4], Gap * 4);
      end;
      for X := 0 to Keep - 1 do
      begin
        DstPx^ := SrcPx^;
        Inc(DstPx);
        Inc(SrcPx, AStep);
      end;
    end;
  end;
end;

procedure TPeardoxGorillaEyes.Submit(ALeft, ARight: TBitmap; AShiftL, AShiftR: Integer);
var
  DL, DR: TBitmapData;
  W, H, Pitch, I, Step, OW, OH: Integer;
  RGBA: Boolean;
  Watch: TStopwatch;
begin
  // RGBA is set from the mapped picture, on the only way to SubmitViews
  W := ALeft.Width;
  H := ALeft.Height;
  if (W <= 0) or (H <= 0) or (ARight.Width <> W) or (ARight.Height <> H) then
  begin
    FLastViewInfo := Format('pictures of different sizes or empty: %d x %d and %d x %d',
      [W, H, ARight.Width, ARight.Height]);
    Exit;
  end;
  Watch := TStopwatch.StartNew;
  // No bigger than the display weaves each eye at (its recommended view
  // size): a full-screen 3840-wide view is halved, a quarter of the bytes
  // to copy and upload
  Step := 1;
  if FMaxViewWidth > 0 then
    Step := Max(1, W div FMaxViewWidth);
  OW := W div Step;
  OH := H div Step;
  Pitch := OW * 2 * 4;
  if Length(FBuffer) <> Pitch * OH then
    SetLength(FBuffer, Pitch * OH);
  if Length(FBlack) < OW * 4 then
  begin
    // Opaque black, whichever order the bytes are in
    SetLength(FBlack, OW * 4);
    for I := 0 to OW - 1 do
    begin
      FBlack[I * 4] := 0;
      FBlack[I * 4 + 1] := 0;
      FBlack[I * 4 + 2] := 0;
      FBlack[I * 4 + 3] := 255;
    end;
  end;
  if not ALeft.Map(TMapAccess.Read, DL) then
    Exit;
  try
    if not ARight.Map(TMapAccess.Read, DR) then
      Exit;
    try
      CopyEye(DL, 0, OW, OH, Pitch, AShiftL div Step, Step);
      CopyEye(DR, OW * 4, OW, OH, Pitch, AShiftR div Step, Step);
      RGBA := DL.PixelFormat = TPixelFormat.RGBA;
      FLastViewInfo := Format('%d x %d per eye, woven at %d x %d (1 in %d), %s',
        [W, H, OW, OH, Step, IfThen(RGBA, 'RGBA', 'BGRA')]);
    finally
      ARight.Unmap(DR);
    end;
  finally
    ALeft.Unmap(DL);
  end;
  FLastShift[0] := AShiftL;
  FLastShift[1] := AShiftR;
  FCopyMs := FCopyMs + Watch.Elapsed.TotalMilliseconds;
  Watch := TStopwatch.StartNew;
  if FLeiaSR.SubmitViews(@FBuffer[0], OW, OH, Pitch, RGBA) = SRB_OK then
    Inc(FWovenFrames);
  FSubmitMs := FSubmitMs + Watch.Elapsed.TotalMilliseconds;
end;

procedure TPeardoxGorillaEyes.Frame;
var
  L, R, T: TPoint3D;
  D, OXL, OYL, OXR, OYR, MX, MY: Single;
  Cam: TControl3D;
  SavedPos, SavedRot: TPoint3D;
  BL, BR: TBitmap;
  Watch: TStopwatch;
  NowTick: UInt64;
  Secs, N: Double;
  ShiftL, ShiftR: Integer;
begin
  if FInFrame or not FActive then
    Exit;
  if (FLeiaSR = nil) or not FLeiaSR.Running or (FCamera = nil) or (FCamera.Camera = nil) or
    (FViewport = nil) then
  begin
    Stop;
    Exit;
  end;
  FInFrame := True;
  try
    Watch := TStopwatch.StartNew;
    FLeiaSR.UpdateEyes;
    EyePair(L, R);
    if FSwapEyes then
    begin
      T := L;
      L := R;
      R := T;
    end;
    FLastEyes[0] := L;
    FLastEyes[1] := R;
    D := FCamera.Distance;
    if EyeOffset(L, D, OXL, OYL) and EyeOffset(R, D, OXR, OYR) then
    begin
      FLastOffsets[0] := OXL;
      FLastOffsets[1] := OYL;
      FLastOffsets[2] := OXR;
      FLastOffsets[3] := OYR;
      MX := (OXL + OXR) / 2;
      MY := (OYL + OYR) / 2;
      Cam := FCamera.Camera;
      SavedPos := Cam.Position.Point;
      SavedRot := Cam.RotationAngle.Point;
      BL := nil;
      BR := nil;
      try
        try
          if FConvergence = ecShift then
          begin
            // Both turned alike, from the midpoint: parallel to each other
            BL := RenderEye(OXL, OYL, MX, MY);
            BR := RenderEye(OXR, OYR, MX, MY);
          end
          else
          begin
            BL := RenderEye(OXL, OYL, OXL, OYL);
            BR := RenderEye(OXR, OYR, OXR, OYR);
          end;
        finally
          // Exactly as it was: the orbit camera knows nothing of this
          Cam.Position.Point := SavedPos;
          Cam.RotationAngle.Point := SavedRot;
        end;
        if (BL <> nil) and (BR <> nil) then
        begin
          ShiftL := 0;
          ShiftR := 0;
          if FConvergence = ecShift then
          begin
            ShiftL := ShiftFor(OXL - MX, BL.Width, BL.Height);
            ShiftR := ShiftFor(OXR - MX, BR.Width, BR.Height);
          end;
          Submit(BL, BR, ShiftL, ShiftR);
        end
        else
          FLastViewInfo := 'MakeScreenshot gave no picture';
      finally
        BL.Free;
        BR.Free;
      end;
      Inc(FFrames);
      FWorstMs := Max(FWorstMs, Watch.Elapsed.TotalMilliseconds);
    end;
  finally
    FInFrame := False;
    FLastFrameTick := TThread.GetTickCount64;
  end;
  NowTick := TThread.GetTickCount64;
  if NowTick - FLastLogTick >= 1000 then
  begin
    Secs := (NowTick - FLastLogTick) / 1000;
    N := Max(FFrames, 1);
    Log(Format('Eyes: %.1f fps (worst %.0f ms) | per frame: render %.1f ms, screenshot %.1f ms, ' +
      'copy %.1f ms, submit %.1f ms | %s | %s, shifts L %d R %d px | eyes %s, offsets ' +
      'L(%.3f, %.3f) R(%.3f, %.3f) at depth %.3f | %d by the watchdog', [FFrames / Secs,
      FWorstMs, FRenderMs / N,
      FShotMs / N, FCopyMs / N, FSubmitMs / N, FLastViewInfo,
      IfThen(FConvergence = ecShift, 'shift', 'toe-in'), FLastShift[0], FLastShift[1],
      FLastEyesFrom, FLastOffsets[0], FLastOffsets[1], FLastOffsets[2], FLastOffsets[3],
      FCamera.Distance, FWatchdogFrames]));
    FLastRateText := Format('%.1f fps (worst %.0f ms), per frame render %.1f, screenshot %.1f, ' +
      'copy %.1f, submit %.1f ms', [FFrames / Secs, FWorstMs, FRenderMs / N, FShotMs / N,
      FCopyMs / N, FSubmitMs / N]);
    FLastLogTick := NowTick;
    FWatchdogFrames := 0;
    FFrames := 0;
    FRenderMs := 0;
    FShotMs := 0;
    FCopyMs := 0;
    FSubmitMs := 0;
    FWorstMs := 0;
  end;
end;

end.
