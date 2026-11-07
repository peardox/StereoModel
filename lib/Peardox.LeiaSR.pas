//** @abstract(TPeardoxLeiaSR: starts and stops LeiaSR (Simulated Reality, glasses-free 3D) for
//** a view on a form, and reports the display and the viewer's eyes.)
//**
//** The first of the Peardox LeiaSR components, in the PeardoxLeiaSR package. It does what
//** SRDelphiFMX's TSRStereoRenderer does to get SR going, without drawing anything yet:
//**
//** @unorderedList(
//**   @item(Whether this computer has LeiaSR at all (Installed). Where it has not, Start does
//**     nothing and raises no event: a program can hide everything to do with glasses-free 3D
//**     and run as if it had no SR support.)
//**   @item(Start checks for the SR service and display on a background thread (the bridge's
//**     srb_Probe), so waiting for them never freezes the window, then starts SR on the main
//**     thread (srb_Initialize), with the bridge's own window over Control.)
//**   @item(While running: the display, where Control lies on it in millimetres, the tracked
//**     eye positions and SR's system events, in the log (OnLog) and through OnEyes.)
//**   @item(The user's settings, kept by Settings, shared by every Peardox program.)
//** )
//**
//** Nothing is woven yet: the bridge's window stays hidden and the display's lens off, so
//** Control shows what it always shows. Drawing the two eyes' views comes next, in a component
//** of its own.
//**
//** LeiaSR is Windows 64-bit only. The unit compiles everywhere so the package and the
//** programs using it stay cross-platform; elsewhere Installed is False and Start does nothing.
//** It needs SRBridge.dll (from peardox/SRDelphiFMX) beside the executable. One per program:
//** the bridge drives a single SR view.
unit Peardox.LeiaSR;

{
  TPeardoxLeiaSR: starts and stops LeiaSR (Simulated Reality, glasses-free
  3D) for a view on a form, and reports the display and the viewer's eyes.

  The first of the Peardox LeiaSR components, in the PeardoxLeiaSR package.
  It does what SRDelphiFMX's TSRStereoRenderer does to get SR going,
  without drawing anything yet: whether LeiaSR is installed; a background
  check for the SR service and display, then SR started on the main thread
  with the bridge's window over Control; while running, the display, the
  view's place on it in millimetres, the tracked eyes and SR's events; and
  the user's settings, shared by every Peardox program.

  Nothing is woven yet: the bridge's window stays hidden and the lens off.

  LeiaSR is Windows 64-bit only; the unit compiles everywhere, and
  elsewhere Installed is False and Start does nothing. It needs
  SRBridge.dll (from peardox/SRDelphiFMX) beside the executable.
}

interface

uses
  System.SysUtils, System.Classes, System.Types, System.Math.Vectors,
  {$IFDEF MSWINDOWS}
  Winapi.Windows, Winapi.Messages,
  {$ENDIF}
  FMX.Types, FMX.Controls,
  Peardox.LeiaSR.Api, Peardox.LeiaSR.Settings;

const
  //** @abstract(The platforms the LeiaSR components are offered for in the IDE: all of them,
  //** so a form using one compiles everywhere; SR itself runs on Windows 64-bit only.)
  PEARDOX_LEIASR_PLATFORMS = pidAllPlatforms;
  //** @abstract(Default for TPeardoxLeiaSR.InitTimeout, in seconds, as SRDelphiFMX's.)
  PEARDOX_LEIASR_INIT_TIMEOUT = 5.0;
  //** @abstract(Default for TPeardoxLeiaSR.PollInterval, in milliseconds.)
  PEARDOX_LEIASR_POLL_INTERVAL = 100;
  //** @abstract(Default for TPeardoxLeiaSR.LogInterval, in milliseconds, as SRDelphiFMX's.)
  PEARDOX_LEIASR_LOG_INTERVAL = 1000;

type
  //** @abstract(Why glasses-free 3D did not start, as TPeardoxLeiaSR.Problem.)
  TPeardoxLeiaSRProblem = (
    //** @abstract(No problem.)
    lspNone,
    //** @abstract(This computer has no LeiaSR runtime, or this platform has no LeiaSR at all.
    //** Not an error: nothing is said to the user.)
    lspNotInstalled,
    //** @abstract(A 32-bit Windows build: the SR runtime is 64-bit only.)
    lspNotWin64,
    //** @abstract(SRBridge.dll could not be loaded.)
    lspBridgeMissing,
    //** @abstract(The LeiaSR runtime is installed but its service is not running.)
    lspNoService,
    //** @abstract(The SR service is running but no SR display was found.)
    lspNoDisplay,
    //** @abstract(Control is not set, or not on a form that is showing.)
    lspNoForm,
    //** @abstract(SR would not start for another reason; the message says which.)
    lspStartFailed);

  //** @abstract(Where TPeardoxLeiaSR is, as its State.)
  TPeardoxLeiaSRState = (
    //** @abstract(Not running, not starting.)
    lssOff,
    //** @abstract(Waiting for the background check of the SR service and display.)
    lssChecking,
    //** @abstract(SR is running.)
    lssRunning);

  //** @abstract(A line for the log.)
  //**
  //** @param(Sender The TPeardoxLeiaSR.)
  //**
  //** @param(AText The line.)
  TPeardoxLeiaSRLogEvent = procedure(Sender: TObject; const AText: string) of object;

  //** @abstract(Glasses-free 3D could not start, for a reason the user should hear about.)
  //**
  //** @param(Sender The TPeardoxLeiaSR.)
  //**
  //** @param(AProblem What went wrong.)
  //**
  //** @param(AMessage The details, for the user.)
  TPeardoxLeiaSRProblemEvent = procedure(Sender: TObject; AProblem: TPeardoxLeiaSRProblem;
    const AMessage: string) of object;

  //** @abstract(New eye positions from the tracker.)
  //**
  //** @param(Sender The TPeardoxLeiaSR.)
  //**
  //** @param(ALeftMM The left eye, in millimetres from the display's centre: x right, y up, z
  //** towards the viewer.)
  //**
  //** @param(ARightMM The right eye, likewise.)
  TPeardoxLeiaSREyesEvent = procedure(Sender: TObject; const ALeftMM, ARightMM: TPoint3D) of object;

  //** @abstract(Starts and stops LeiaSR for a view on a form, and reports the display and the
  //** viewer's eyes; see the unit description.)
  //**
  //** Create it (in code for now), set Control to the view (the Gorilla3D viewport) and
  //** OnLog, then call Start once the form is showing, and Stop before the form closes.
  [ComponentPlatformsAttribute(PEARDOX_LEIASR_PLATFORMS)]
  TPeardoxLeiaSR = class(TComponent)
  private
    //** @abstract(See Control.)
    FControl: TControl;
    //** @abstract(See Settings.)
    FSettings: TPeardoxLeiaSRSettings;
    //** @abstract(See SettingsStatus.)
    FSettingsStatus: string;
    //** @abstract(See State.)
    FState: TPeardoxLeiaSRState;
    //** @abstract(See Problem.)
    FProblem: TPeardoxLeiaSRProblem;
    //** @abstract(See InitTimeout.)
    FInitTimeout: Single;
    //** @abstract(See PollInterval.)
    FPollInterval: Integer;
    //** @abstract(See LogInterval.)
    FLogInterval: Integer;
    //** @abstract(Polls the bridge while SR runs; made at run time only.)
    FTimer: TTimer;
    //** @abstract(See LeftEyeMM.)
    FLeftEyeMM: TPoint3D;
    //** @abstract(See RightEyeMM.)
    FRightEyeMM: TPoint3D;
    //** @abstract(See EyesTracked.)
    FEyesTracked: Boolean;
    //** @abstract(See WindowCenterMM.)
    FWindowCenterMM: TPointF;
    //** @abstract(See WindowSizeMM.)
    FWindowSizeMM: TSizeF;
    //** @abstract(Control's rectangle last given to the bridge, in physical pixels in the
    //** form's client area; empty until set.)
    FBounds: TRect;
    //** @abstract(When Start was called, for the log's timings (TThread.GetTickCount64).)
    FStartTick: UInt64;
    //** @abstract(When the last periodic log lines were written.)
    FLastLogTick: UInt64;
    //** @abstract(See OnLog.)
    FOnLog: TPeardoxLeiaSRLogEvent;
    //** @abstract(See OnStarted.)
    FOnStarted: TNotifyEvent;
    //** @abstract(See OnStopped.)
    FOnStopped: TNotifyEvent;
    //** @abstract(See OnProblem.)
    FOnProblem: TPeardoxLeiaSRProblemEvent;
    //** @abstract(See OnEyes.)
    FOnEyes: TPeardoxLeiaSREyesEvent;
    {$IFDEF MSWINDOWS}
    //** @abstract(A hidden window the background check posts its answer to: posted messages
    //** come ahead of paints, while a queued call waits until FMX is idle.)
    FMsgWnd: HWND;
    //** @abstract(The form's window, the parent of the bridge's own.)
    FFormWnd: HWND;
    //** @abstract(The background check's thread, kept to wait for it when freed; nil when none
    //** has run.)
    FProbe: TThread;
    {$ENDIF}
    //** @abstract(Sets Control, watching for it being freed.)
    //**
    //** @param(AValue The new view, or nil.)
    procedure SetControl(const AValue: TControl);
    //** @abstract(Sets PollInterval, at least 10 ms.)
    //**
    //** @param(AValue Milliseconds.)
    procedure SetPollInterval(const AValue: Integer);
    //** @abstract(Whether InitTimeout differs from its default and so is written to the .fmx.)
    //**
    //** @returns(True if it is not PEARDOX_LEIASR_INIT_TIMEOUT.)
    function StoreInitTimeout: Boolean;
    //** @abstract(Read by Running.)
    //**
    //** @returns(True while State is lssRunning.)
    function GetRunning: Boolean;
    //** @abstract(FTimer's tick while SR runs: SR's events, Control's place, the eyes, and the
    //** periodic log lines.)
    //**
    //** @param(Sender FTimer.)
    procedure TimerTick(Sender: TObject);
    //** @abstract(Ends a start that failed: State back to lssOff, Problem set, the reason
    //** logged and, when the user should hear of it, OnProblem.)
    //**
    //** @param(AProblem What went wrong.)
    //**
    //** @param(AMessage The details.)
    //**
    //** @param(ATell Whether to raise OnProblem; False for lspNotInstalled.)
    procedure Fail(AProblem: TPeardoxLeiaSRProblem; const AMessage: string; ATell: Boolean);
    {$IFDEF MSWINDOWS}
    //** @abstract(Finds the window of the form Control is on.)
    //**
    //** @param(AWnd Set to the form's window.)
    //**
    //** @param(AWhy Set to why there is none, for the log.)
    //**
    //** @returns(True if Control is on a form that is showing.)
    function FindFormWindow(out AWnd: HWND; out AWhy: string): Boolean;
    //** @abstract(FMsgWnd's window procedure: takes the background check's answer.)
    //**
    //** @param(AMessage The message.)
    procedure MsgWndProc(var AMessage: Winapi.Messages.TMessage);
    //** @abstract(The background check's answer: starts SR if it is there, or fails the start
    //** with the reason.)
    //**
    //** @param(ARC What srb_Probe returned.)
    procedure ProbeDone(ARC: Integer);
    //** @abstract(Starts SR on this thread (srb_Initialize), hides the bridge's window and
    //** turns the lens off, as nothing is woven yet, and starts polling.)
    //**
    //** @returns(True if SR is running.)
    function Initialize: Boolean;
    //** @abstract(Gives the bridge Control's rectangle when it has changed, and logs where it
    //** lies on the SR display whenever that changes.)
    procedure UpdateBounds;
    //** @abstract(Logs every SR system event waiting in the bridge.)
    procedure PollEvents;
    //** @abstract(Reads the tracked eyes, logs when tracking is found or lost, and raises
    //** OnEyes.)
    procedure ReadEyes;
    //** @abstract(Logs the SR platform, the display and the settings once SR has started.)
    procedure LogStartDetails;
    {$ENDIF}
  protected
    //** @abstract(Forgets Control when it is freed, stopping SR first.)
    //**
    //** @param(AComponent The component going or coming.)
    //**
    //** @param(Operation Whether it is being inserted or removed.)
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    //** @abstract(Passes a line to OnLog, unless the component is being destroyed.)
    //**
    //** @param(AText The line.)
    procedure Log(const AText: string);
  public
    //** @abstract(Creates the component and, at run time, reads Settings and makes the timer
    //** and the hidden message window.)
    //**
    //** @param(AOwner The owner, normally the form.)
    constructor Create(AOwner: TComponent); override;
    //** @abstract(Stops SR, waits for a background check still running, and frees everything.)
    destructor Destroy; override;
    //** @abstract(Whether glasses-free 3D can be offered here: a Windows 64-bit build on a
    //** computer with the LeiaSR runtime installed.)
    //**
    //** Quick and safe anywhere: it loads neither the bridge nor the runtime. It says nothing
    //** about whether the SR service is running or a display connected; Start finds that out.
    //**
    //** @returns(True if LeiaSR is installed and this build can use it.)
    class function Installed: Boolean;
    //** @abstract(Starts glasses-free 3D.)
    //**
    //** Returns at once. Where LeiaSR is not installed it does nothing more, raising no event.
    //** Otherwise the SR service and display are checked on a background thread, for up to
    //** InitTimeout seconds; when they are there SR is started (OnStarted), and when not, or if
    //** anything else goes wrong, OnProblem says why. Call it once the form is showing.
    //**
    //** @returns(True if SR is starting or already running; False if it cannot start, with
    //** the reason in Problem and the log.)
    function Start: Boolean;
    //** @abstract(Stops glasses-free 3D (OnStopped if it was running); a background check
    //** still under way is let finish and its answer ignored.)
    procedure Stop;
    //** @abstract(Saves Settings, logging where to or why not.)
    procedure SaveSettings;
    //** @abstract(The SR display's properties, while SR runs.)
    //**
    //** @param(AInfo Set to the display's resolutions, size and recommended view size.)
    //**
    //** @returns(True if SR is running and the bridge answered.)
    function DisplayInfo(out AInfo: TSRBDisplayInfo): Boolean;
    //** @abstract(Where the component is: off, checking or running.)
    property State: TPeardoxLeiaSRState read FState;
    //** @abstract(True while SR is running.)
    property Running: Boolean read GetRunning;
    //** @abstract(Why the last Start did not start SR; lspNone otherwise.)
    property Problem: TPeardoxLeiaSRProblem read FProblem;
    //** @abstract(The left eye, in millimetres from the display's centre (x right, y up, z
    //** towards the viewer), as last read while SR ran.)
    property LeftEyeMM: TPoint3D read FLeftEyeMM;
    //** @abstract(The right eye, likewise.)
    property RightEyeMM: TPoint3D read FRightEyeMM;
    //** @abstract(True while the tracker has the viewer's eyes; False before it finds them,
    //** when SR reports both eyes at one point.)
    property EyesTracked: Boolean read FEyesTracked;
    //** @abstract(Control's centre on the SR display, in millimetres from the display's centre,
    //** x right and y up, as last read while SR ran.)
    property WindowCenterMM: TPointF read FWindowCenterMM;
    //** @abstract(Control's size on the SR display, in millimetres.)
    property WindowSizeMM: TSizeF read FWindowSizeMM;
    //** @abstract(The user's saved LeiaSR settings, read when the component is made at run
    //** time; change them and call SaveSettings.)
    property Settings: TPeardoxLeiaSRSettings read FSettings;
    //** @abstract(What happened when Settings were read, for the program's log: the file read,
    //** or why the defaults are used.)
    property SettingsStatus: string read FSettingsStatus;
  published
    //** @abstract(The view SR is for: the bridge's window is put over it, and its place on the
    //** display is what the eyes will look through. Normally the Gorilla3D viewport.)
    property Control: TControl read FControl write SetControl;
    //** @abstract(Seconds to wait for the SR service and display when starting; default
    //** PEARDOX_LEIASR_INIT_TIMEOUT.)
    property InitTimeout: Single read FInitTimeout write FInitTimeout stored StoreInitTimeout;
    //** @abstract(Milliseconds between polls of the bridge while SR runs; default
    //** PEARDOX_LEIASR_POLL_INTERVAL.)
    property PollInterval: Integer read FPollInterval write SetPollInterval
      default PEARDOX_LEIASR_POLL_INTERVAL;
    //** @abstract(Milliseconds between the periodic log lines (eyes, view) while SR runs; 0
    //** for none. Default PEARDOX_LEIASR_LOG_INTERVAL.)
    property LogInterval: Integer read FLogInterval write FLogInterval
      default PEARDOX_LEIASR_LOG_INTERVAL;
    //** @abstract(Every line of the log: the start, the display, SR's events, the eyes, the
    //** bridge's own lines (prefixed [bridge]) and failures. On the main thread.)
    property OnLog: TPeardoxLeiaSRLogEvent read FOnLog write FOnLog;
    //** @abstract(SR has started.)
    property OnStarted: TNotifyEvent read FOnStarted write FOnStarted;
    //** @abstract(SR has stopped, after running.)
    property OnStopped: TNotifyEvent read FOnStopped write FOnStopped;
    //** @abstract(Glasses-free 3D could not start for a reason the user should hear about;
    //** not raised where LeiaSR is simply not installed.)
    property OnProblem: TPeardoxLeiaSRProblemEvent read FOnProblem write FOnProblem;
    //** @abstract(New eye positions, at every poll while SR runs.)
    property OnEyes: TPeardoxLeiaSREyesEvent read FOnEyes write FOnEyes;
  end;

implementation

uses
  System.Math, System.StrUtils,
  {$IFDEF MSWINDOWS}
  FMX.Platform.Win,
  {$ENDIF}
  FMX.Forms;

{$IFDEF MSWINDOWS}
const
  //** @abstract(Posted to the hidden window with the background check's answer in WParam.)
  WM_PEARDOX_LEIASR_PROBED = WM_APP + $51;

var
  //** @abstract(The component the bridge's log lines go to; nil when none. The bridge drives
  //** one SR view per process, so there is one.)
  GBridgeLogOwner: TPeardoxLeiaSR = nil;

//** @abstract(Receives the bridge's log lines, on any thread, and passes them to the main
//** thread's log.)
//**
//** @param(Line The line, zero-terminated UTF-8.)
procedure BridgeLogCallback(Line: PAnsiChar); cdecl;
var
  Text: string;
begin
  try
    Text := UTF8ToString(Line);
    TThread.Queue(nil,
      procedure
      begin
        if GBridgeLogOwner <> nil then
          GBridgeLogOwner.Log('[bridge] ' + Text);
      end);
  except
    // Never let an exception back into the bridge's C++
  end;
end;
{$ENDIF}

//** @abstract(A point for the log.)
//**
//** @param(P The point, in millimetres.)
//**
//** @returns(Its coordinates to one place, in brackets.)
function FmtMM(const P: TPoint3D): string;
begin
  Result := Format('(%.1f, %.1f, %.1f)', [P.X, P.Y, P.Z]);
end;

{ TPeardoxLeiaSR }

constructor TPeardoxLeiaSR.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FInitTimeout := PEARDOX_LEIASR_INIT_TIMEOUT;
  FPollInterval := PEARDOX_LEIASR_POLL_INTERVAL;
  FLogInterval := PEARDOX_LEIASR_LOG_INTERVAL;
  FSettings := TPeardoxLeiaSRSettings.Create;
  if csDesigning in ComponentState then
    Exit;
  if FSettings.Load then
    FSettingsStatus := 'LeiaSR settings read from ' + FSettings.FileName
  else
    FSettingsStatus := Format('LeiaSR settings: %s, defaults used (%s)',
      [FSettings.LastError, FSettings.FileName]);
  FTimer := TTimer.Create(Self);
  FTimer.Enabled := False;
  FTimer.Interval := FPollInterval;
  FTimer.OnTimer := TimerTick;
  {$IFDEF MSWINDOWS}
  FMsgWnd := AllocateHWnd(MsgWndProc);
  {$ENDIF}
end;

destructor TPeardoxLeiaSR.Destroy;
begin
  {$IFDEF MSWINDOWS}
  // The bridge's lines from here on go nowhere: the owner may be half gone
  if GBridgeLogOwner = Self then
    GBridgeLogOwner := nil;
  {$ENDIF}
  Stop;
  {$IFDEF MSWINDOWS}
  // A check still under way must finish before the bridge is unloaded
  if FProbe <> nil then
  begin
    FProbe.WaitFor;
    FreeAndNil(FProbe);
  end;
  if FMsgWnd <> 0 then
    DeallocateHWnd(FMsgWnd);
  {$ENDIF}
  FSettings.Free;
  inherited Destroy;
end;

procedure TPeardoxLeiaSR.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FControl) then
  begin
    if FState <> lssOff then
    begin
      Log('Control is being freed: stopping LeiaSR');
      Stop;
    end;
    FControl := nil;
  end;
end;

procedure TPeardoxLeiaSR.SetControl(const AValue: TControl);
begin
  if AValue = FControl then
    Exit;
  if FControl <> nil then
    FControl.RemoveFreeNotification(Self);
  FControl := AValue;
  if FControl <> nil then
    FControl.FreeNotification(Self);
  FBounds := TRect.Empty;
end;

procedure TPeardoxLeiaSR.SetPollInterval(const AValue: Integer);
begin
  FPollInterval := Max(10, AValue);
  if FTimer <> nil then
    FTimer.Interval := FPollInterval;
end;

function TPeardoxLeiaSR.StoreInitTimeout: Boolean;
begin
  Result := not SameValue(FInitTimeout, PEARDOX_LEIASR_INIT_TIMEOUT);
end;

function TPeardoxLeiaSR.GetRunning: Boolean;
begin
  Result := FState = lssRunning;
end;

procedure TPeardoxLeiaSR.Log(const AText: string);
begin
  if Assigned(FOnLog) and not (csDestroying in ComponentState) then
    FOnLog(Self, AText);
end;

class function TPeardoxLeiaSR.Installed: Boolean;
begin
  {$IFDEF WIN64}
  Result := SRRuntimeInstalled;
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

procedure TPeardoxLeiaSR.Fail(AProblem: TPeardoxLeiaSRProblem; const AMessage: string;
  ATell: Boolean);
begin
  FState := lssOff;
  FProblem := AProblem;
  Log('Glasses-free 3D not started: ' + AMessage);
  if ATell and Assigned(FOnProblem) then
    FOnProblem(Self, AProblem, AMessage);
end;

function TPeardoxLeiaSR.Start: Boolean;
{$IFDEF WIN64}
var
  Wnd, PostTo: HWND;
  Why: string;
  Timeout: Integer;
{$ENDIF}
begin
  Result := False;
  if csDesigning in ComponentState then
    Exit;
  if FState <> lssOff then
    Exit(True);
  FProblem := lspNone;
  {$IF not DEFINED(MSWINDOWS)}
  Fail(lspNotInstalled, 'LeiaSR (glasses-free 3D) is available on Windows only', False);
  {$ELSEIF not DEFINED(WIN64)}
  Fail(lspNotWin64, SRBridgeLastError, True);
  {$ELSE}
  if not SRRuntimeInstalled then
  begin
    Fail(lspNotInstalled, 'the LeiaSR runtime is not installed (SimulatedRealityCore, ' +
      'Displays and DirectX .dll not found); nothing shown to the user', False);
    Exit;
  end;
  if not SRBridgeAvailable then
  begin
    Fail(lspBridgeMissing, SRBridgeLastError, True);
    Exit;
  end;
  if not FindFormWindow(Wnd, Why) then
  begin
    Fail(lspNoForm, Why, True);
    Exit;
  end;
  FFormWnd := Wnd;
  FStartTick := TThread.GetTickCount64;
  // A check from an earlier start has long finished: its answer was posted
  if FProbe <> nil then
  begin
    FProbe.WaitFor;
    FreeAndNil(FProbe);
  end;
  if not SRBridgeHasExport('srb_Probe') then
  begin
    Log('This SRBridge.dll has no srb_Probe (it is older than 5 November 2026): starting ' +
      'on this thread, which can freeze the window for up to InitTimeout');
    Exit(Initialize);
  end;
  // The wait for SR (a service starting, a display) happens on a background
  // thread: srb_Initialize would wait on this one, with the window frozen
  FState := lssChecking;
  Timeout := Max(0, Round(FInitTimeout * 1000));
  PostTo := FMsgWnd;
  Log(Format('Checking for the LeiaSR service and display on a background thread (up to %d ms)',
    [Timeout]));
  FProbe := TThread.CreateAnonymousThread(
    procedure
    var
      RC: Integer;
    begin
      RC := srb_Probe(Timeout);
      // If the component has gone, its window has too and this fails
      // harmlessly
      PostMessage(PostTo, WM_PEARDOX_LEIASR_PROBED, WPARAM(RC), 0);
    end);
  FProbe.FreeOnTerminate := False;
  FProbe.Start;
  Result := True;
  {$ENDIF}
end;

procedure TPeardoxLeiaSR.Stop;
var
  WasRunning: Boolean;
begin
  if FTimer <> nil then
    FTimer.Enabled := False;
  WasRunning := FState = lssRunning;
  if FState = lssChecking then
    Log('Glasses-free 3D turned off during the LeiaSR check: its answer will be ignored');
  FState := lssOff;
  FEyesTracked := False;
  if not WasRunning then
    Exit;
  {$IFDEF MSWINDOWS}
  srb_Finalize;
  srb_SetLogCallback(nil);
  {$ENDIF}
  Log('LeiaSR stopped');
  if Assigned(FOnStopped) and not (csDestroying in ComponentState) then
    FOnStopped(Self);
end;

procedure TPeardoxLeiaSR.SaveSettings;
begin
  try
    FSettings.Save;
    Log('LeiaSR settings saved to ' + FSettings.FileName);
  except
    on E: Exception do
      Log(Format('LeiaSR settings NOT saved to %s: %s: %s',
        [FSettings.FileName, E.ClassName, E.Message]));
  end;
end;

function TPeardoxLeiaSR.DisplayInfo(out AInfo: TSRBDisplayInfo): Boolean;
begin
  FillChar(AInfo, SizeOf(AInfo), 0);
  {$IFDEF MSWINDOWS}
  Result := Running and (srb_GetDisplayInfo(@AInfo) = SRB_OK);
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

procedure TPeardoxLeiaSR.TimerTick(Sender: TObject);
{$IFDEF MSWINDOWS}
var
  NowTick: UInt64;
{$ENDIF}
begin
  if FState <> lssRunning then
    Exit;
  {$IFDEF MSWINDOWS}
  PollEvents;
  UpdateBounds;
  ReadEyes;
  NowTick := TThread.GetTickCount64;
  if (FLogInterval > 0) and (NowTick - FLastLogTick >= UInt64(FLogInterval)) then
  begin
    FLastLogTick := NowTick;
    Log(Format('Eyes L%s R%s mm, separation %.1f mm%s | view centre (%.1f, %.1f) mm, ' +
      '%.1f x %.1f mm', [FmtMM(FLeftEyeMM), FmtMM(FRightEyeMM),
      FLeftEyeMM.Distance(FRightEyeMM), IfThen(FEyesTracked, '', ' NOT TRACKED'),
      FWindowCenterMM.X, FWindowCenterMM.Y, FWindowSizeMM.Width, FWindowSizeMM.Height]));
  end;
  {$ENDIF}
end;

{$IFDEF MSWINDOWS}

function TPeardoxLeiaSR.FindFormWindow(out AWnd: HWND; out AWhy: string): Boolean;
var
  Form: TCommonCustomForm;
begin
  AWnd := 0;
  Result := False;
  if FControl = nil then
  begin
    AWhy := 'Control is not set: nothing to show glasses-free 3D in';
    Exit;
  end;
  if (FControl.Root = nil) or not (FControl.Root.GetObject is TCommonCustomForm) then
  begin
    AWhy := Format('%s is not on a form', [FControl.Name]);
    Exit;
  end;
  Form := TCommonCustomForm(FControl.Root.GetObject);
  if (Form.Handle = nil) or not Form.Visible then
  begin
    AWhy := Format('the form %s is not showing yet', [Form.Name]);
    Exit;
  end;
  AWnd := FormToHWND(Form);
  if AWnd = 0 then
  begin
    AWhy := Format('the form %s has no window', [Form.Name]);
    Exit;
  end;
  AWhy := '';
  Result := True;
end;

procedure TPeardoxLeiaSR.MsgWndProc(var AMessage: Winapi.Messages.TMessage);
begin
  if AMessage.Msg = WM_PEARDOX_LEIASR_PROBED then
  begin
    AMessage.Result := 0;
    ProbeDone(Integer(AMessage.WParam));
  end
  else
    AMessage.Result := DefWindowProc(FMsgWnd, AMessage.Msg, AMessage.WParam, AMessage.LParam);
end;

procedure TPeardoxLeiaSR.ProbeDone(ARC: Integer);
var
  Ms: UInt64;
begin
  Ms := TThread.GetTickCount64 - FStartTick;
  if FState <> lssChecking then
  begin
    Log(Format('LeiaSR check answered %d after %d ms, no longer wanted', [ARC, Int64(Ms)]));
    Exit;
  end;
  case ARC of
    SRB_OK:
      begin
        Log(Format('LeiaSR check: service running and SR display found, after %d ms', [Int64(Ms)]));
        Initialize;
      end;
    SRB_E_SR_DLL_MISSING:
      Fail(lspNotInstalled, 'the bridge could not load the LeiaSR runtime: ' +
        SRBridgeLastError, False);
    SRB_E_NO_SERVICE:
      Fail(lspNoService, 'The LeiaSR (Simulated Reality) service is not running. It normally ' +
        'starts with Windows: restarting the SR software, or the computer, starts it again.', True);
    SRB_E_NO_DISPLAY:
      Fail(lspNoDisplay, 'No SR display was found. Check that it is switched on and connected ' +
        '(video cable and USB), and set to its native resolution.', True);
  else
    begin
      Log(Format('LeiaSR check: unexpected answer %d after %d ms (%s); starting anyway',
        [ARC, Int64(Ms), SRBridgeLastError]));
      Initialize;
    end;
  end;
end;

function TPeardoxLeiaSR.Initialize: Boolean;
var
  Wnd: HWND;
  Why: string;
  RC: Integer;
  T0: UInt64;
begin
  Result := False;
  // The form may have gone while the check ran
  if not FindFormWindow(Wnd, Why) then
  begin
    Fail(lspNoForm, Why, True);
    Exit;
  end;
  FFormWnd := Wnd;
  GBridgeLogOwner := Self;
  srb_SetLogCallback(BridgeLogCallback);
  // Gorilla3D does not draw through FMX's Direct3D 11 device, so there is
  // nothing to share: the bridge makes its own device on the GPU that drives
  // the SR display, and the views will be uploaded to it
  if SRBridgeHasExport('srb_SetExternalDevice') then
    srb_SetExternalDevice(nil);
  Log(Format('Starting LeiaSR (srb_Initialize, timeout %.1f s); the bridge uses a Direct3D 11 ' +
    'device of its own', [FInitTimeout]));
  T0 := TThread.GetTickCount64;
  RC := srb_Initialize(Pointer(FFormWnd), FInitTimeout);
  Log(Format('srb_Initialize returned %d after %d ms (%d ms after Start)',
    [RC, Int64(TThread.GetTickCount64 - T0), Int64(TThread.GetTickCount64 - FStartTick)]));
  if RC <> SRB_OK then
  begin
    srb_SetLogCallback(nil);
    case RC of
      SRB_E_NO_SERVICE:
        Fail(lspNoService, 'LeiaSR would not start: ' + SRBridgeLastError, True);
      SRB_E_NO_DISPLAY:
        Fail(lspNoDisplay, 'LeiaSR would not start: ' + SRBridgeLastError, True);
    else
      Fail(lspStartFailed, Format('LeiaSR would not start (%d): %s', [RC, SRBridgeLastError]), True);
    end;
    Exit;
  end;
  // Nothing is woven yet, so the bridge's window stays hidden (Control shows
  // as Gorilla3D draws it) and the lens off (it would blur the whole panel)
  srb_SetVisible(0);
  srb_SetLens(0);
  if FSettings.LatencyFrames > 0 then
    srb_SetLatencyInFrames(FSettings.LatencyFrames);
  FState := lssRunning;
  FBounds := TRect.Empty;
  FEyesTracked := False;
  FWindowCenterMM := PointF(0, 0);
  FWindowSizeMM := TSizeF.Create(0, 0);
  LogStartDetails;
  UpdateBounds;
  FLastLogTick := TThread.GetTickCount64;
  FTimer.Interval := FPollInterval;
  FTimer.Enabled := True;
  Result := True;
  if Assigned(FOnStarted) then
    FOnStarted(Self);
end;

procedure TPeardoxLeiaSR.LogStartDetails;
var
  Info: TSRBDisplayInfo;
  DR: TSRBRect;
  Shown: TRect;
  Centre: TPoint;
begin
  Log('SR platform ' + UTF8ToString(srb_GetPlatformVersion));
  if srb_GetDisplayInfo(@Info) = SRB_OK then
    Log(Format('SR display %d x %d px (panel %d x %d), %.1f x %.1f mm, recommended view ' +
      '%d x %d per eye', [Info.resolutionWidth, Info.resolutionHeight,
      Info.physicalResolutionWidth, Info.physicalResolutionHeight, Info.physicalWidthMM,
      Info.physicalHeightMM, Info.recommendedViewWidth, Info.recommendedViewHeight]))
  else
    Log('SR display properties not available: ' + SRBridgeLastError);
  if srb_GetDisplayRect(DR) = SRB_OK then
  begin
    Log(Format('SR display on the desktop at (%d, %d)-(%d, %d)', [DR[0], DR[1], DR[2], DR[3]]));
    if GetWindowRect(FFormWnd, Shown) then
    begin
      Centre := Shown.CenterPoint;
      if TRect.Create(DR[0], DR[1], DR[2], DR[3]).Contains(Centre) then
        Log('The form is on the SR display')
      else
        Log(Format('The form''s centre (%d, %d) is NOT on the SR display: move it there for ' +
          'glasses-free 3D', [Centre.X, Centre.Y]));
    end;
  end
  else
    Log('SR display''s place on the desktop not known');
  Log(Format('Settings: eye separation %.1f mm (0 = tracked), look-around %s, latency %d ' +
    'frames (0 = SR''s), lens mode %d (0 off over controls, 1 on, 2 off), full screen %s',
    [FSettings.EyeSeparationMM, BoolToStr(FSettings.LookAround, True), FSettings.LatencyFrames,
     FSettings.LensMode, BoolToStr(FSettings.FullScreen, True)]));
  Log('Nothing is woven yet: the bridge''s window is hidden and the lens off');
end;

procedure TPeardoxLeiaSR.UpdateBounds;
var
  Scale: Single;
  P: TPointF;
  R: TRect;
  Cx, Cy, W, H: Double;
begin
  if (FControl = nil) or (FControl.Scene = nil) then
    Exit;
  // The bridge wants physical pixels in the form's client area
  Scale := FControl.Scene.GetSceneScale;
  P := FControl.LocalToAbsolute(PointF(0, 0));
  R := TRect.Create(Round(P.X * Scale), Round(P.Y * Scale),
    Round((P.X + FControl.Width) * Scale), Round((P.Y + FControl.Height) * Scale));
  if (R.Width <= 0) or (R.Height <= 0) then
    Exit;
  if R <> FBounds then
  begin
    if srb_SetBounds(R.Left, R.Top, R.Width, R.Height) <> SRB_OK then
    begin
      Log('srb_SetBounds failed: ' + SRBridgeLastError);
      Exit;
    end;
    Log(Format('View at (%d, %d), %d x %d physical pixels (scale %.2f)',
      [R.Left, R.Top, R.Width, R.Height, Scale]));
    FBounds := R;
  end;
  // Moving the form moves the view on the display without changing R
  if srb_GetWindowRectMM(Cx, Cy, W, H) = SRB_OK then
    if (Abs(Cx - FWindowCenterMM.X) > 0.5) or (Abs(Cy - FWindowCenterMM.Y) > 0.5) or
      (Abs(W - FWindowSizeMM.Width) > 0.5) or (Abs(H - FWindowSizeMM.Height) > 0.5) then
    begin
      FWindowCenterMM := PointF(Cx, Cy);
      FWindowSizeMM := TSizeF.Create(W, H);
      Log(Format('View on the SR display: centre (%.1f, %.1f) mm, %.1f x %.1f mm',
        [Cx, Cy, W, H]));
    end;
end;

procedure TPeardoxLeiaSR.PollEvents;
var
  Ev: TSRBSystemEvent;
begin
  while srb_PollSystemEvent(@Ev) = 1 do
    Log(Format('SR event %s: %s', [SREventTypeName(Ev.eventType),
      UTF8ToString(PAnsiChar(@Ev.message[0]))]));
end;

procedure TPeardoxLeiaSR.ReadEyes;
var
  L, R: TSRBVec3;
  Tracked: Boolean;
begin
  if srb_GetEyePositions(L, R) <> SRB_OK then
    Exit;
  FLeftEyeMM := Point3D(L[0], L[1], L[2]);
  FRightEyeMM := Point3D(R[0], R[1], R[2]);
  // Before the tracker finds the viewer SR reports both eyes at one point
  Tracked := FLeftEyeMM.Distance(FRightEyeMM) > 1;
  if Tracked <> FEyesTracked then
  begin
    FEyesTracked := Tracked;
    if Tracked then
      Log(Format('Eyes found: L%s R%s mm', [FmtMM(FLeftEyeMM), FmtMM(FRightEyeMM)]))
    else
      Log(Format('Eyes NOT tracked: both at %s mm', [FmtMM(FLeftEyeMM)]));
  end;
  if Assigned(FOnEyes) then
    FOnEyes(Self, FLeftEyeMM, FRightEyeMM);
end;

{$ENDIF}

end.
