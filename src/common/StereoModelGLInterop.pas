//** @abstract(Zero copy for Gorilla3D: its OpenGL picture copied into Direct3D 11 eye
//** textures on the GPU, for the bridge to weave.)
//**
//** TPeardoxGLInterop makes two eye textures on the bridge's Direct3D 11 device (srb_GetDevice)
//** and registers them with OpenGL through NVIDIA's WGL_NV_DX_interop2 (also offered by AMD
//** and Intel drivers), each the colour attachment of a framebuffer of its own. After each
//** eye's RenderManual, CopyEye blits the framebuffer Gorilla3D has just drawn into (it is
//** still bound, StereoCam47's probe found) into the eye's texture, turned the right way up
//** (OpenGL's rows run from the bottom) and moved sideways by the eye's shift. The textures
//** then go to TPeardoxLeiaSR.SubmitEyeTextures: no MakeScreenshot, no copy through the
//** CPU, no upload (owner, 7 November 2026: "all the speed we can give them helps them").
//**
//** Everything here needs Gorilla3D's OpenGL context current: call it straight after
//** RenderManual. Windows only; elsewhere Start fails and the screenshot route is used.
unit StereoModelGLInterop;

{
  Zero copy for Gorilla3D: two eye textures on the bridge's D3D11 device,
  registered with OpenGL (WGL_NV_DX_interop2), filled after each eye's
  RenderManual by blitting Gorilla3D's still-bound framebuffer into them,
  flipped and shifted; then TPeardoxLeiaSR.SubmitEyeTextures. Needs
  Gorilla3D's GL context current. Windows only.
}

interface

uses
  System.SysUtils;

type
  //** @abstract(Where TPeardoxGLInterop's lines go.)
  //**
  //** @param(AText The line.)
  TPeardoxGLInteropLog = reference to procedure(const AText: string);

  //** @abstract(Two Direct3D 11 eye textures OpenGL draws into; see the unit.)
  TPeardoxGLInterop = class
  private
    //** @abstract(The bridge's ID3D11Device the textures are on; not owned.)
    FDevice: Pointer;
    //** @abstract(The eye textures (ID3D11Texture2D), left and right.)
    FTex: array[0..1] of IUnknown;
    //** @abstract(Their OpenGL names.)
    FGLTex: array[0..1] of Cardinal;
    //** @abstract(The framebuffers they are attached to.)
    FFBO: array[0..1] of Cardinal;
    //** @abstract(Where a multisampled picture is resolved first (a blit from a multisampled
    //** framebuffer may not flip or move it, nor change its format): a framebuffer with a
    //** texture of the picture's own format; 0 when the picture is not multisampled.)
    FResolveFBO: Cardinal;
    //** @abstract(The texture of FResolveFBO.)
    FResolveTex: Cardinal;
    //** @abstract(The picture's samples per pixel (0 or 1: not multisampled).)
    FSamples: Integer;
    //** @abstract(The framebuffer the picture is copied from, chosen by FindPicture.)
    FSourceFB: Integer;
    //** @abstract(The picture's internal format, as OpenGL gives it.)
    FSourceFormat: Integer;
    //** @abstract(The interop handle of the device (wglDXOpenDeviceNV).)
    FDXDevice: THandle;
    //** @abstract(The interop handles of the textures (wglDXRegisterObjectNV).)
    FDXObj: array[0..1] of THandle;
    //** @abstract(The textures' size in pixels, the same as the picture Gorilla3D draws.)
    FWidth: Integer;
    //** @abstract(See FWidth.)
    FHeight: Integer;
    //** @abstract(True once Start has made everything.)
    FReady: Boolean;
    //** @abstract(The OpenGL context (HGLRC) Start ran in, to make current again to undo it.)
    FGLContext: THandle;
    //** @abstract(The device context (HDC) it ran on.)
    FGLDC: THandle;
    //** @abstract(Where the lines go.)
    FLog: TPeardoxGLInteropLog;
    //** @abstract(True to log a check with the next CopyEye; see CheckNext.)
    FCheckNext: Boolean;
    //** @abstract(See FlipRows.)
    FFlipRows: Boolean;
    //** @abstract(Sends a line to FLog.)
    //**
    //** @param(AText The line.)
    procedure Log(const AText: string);
    //** @abstract(Looks through OpenGL's framebuffers for the finished picture: one whose
    //** colour attachment is a texture of the eye size with something drawn in it (a 3 x 3
    //** grid of pixels read back), the most lit winning; each candidate logged.)
    //**
    //** @param(ABound The framebuffer bound for reading after RenderManual, kept if none is
    //** found lit.)
    //**
    //** @returns(The framebuffer to copy from.)
    function FindPicture(ABound: Integer): Integer;
    //** @abstract(Undoes Start: unregisters and deletes with OpenGL when its context is
    //** current, otherwise only lets go of the Direct3D textures.)
    procedure Release;
  public
    //** @abstract(Makes nothing yet; Start does.)
    //**
    //** @param(ALog Where the lines go.)
    constructor Create(const ALog: TPeardoxGLInteropLog);
    //** @abstract(Releases everything.)
    destructor Destroy; override;
    //** @abstract(The size of the picture in the framebuffer bound for reading, straight after
    //** RenderManual.)
    //**
    //** @param(AWidth Set to its width in pixels.)
    //**
    //** @param(AHeight Set to its height.)
    //**
    //** @returns(False if no context is current, nothing is bound, or its colour attachment is
    //** not a texture.)
    class function SourceSize(out AWidth, AHeight: Integer): Boolean; static;
    //** @abstract(Takes every pending OpenGL error, so none is left for FMX: its next
    //** BeginScene fails on any ("cannot begin rendering scene for TContextOpenGLWindows:
    //** 1282", owner, 7 November 2026). Without a current context it does nothing.)
    //**
    //** @returns(The first error taken, 0 if none.)
    class function TakeErrors: Cardinal; static;
    //** @abstract(Logs, once, every texture and framebuffer OpenGL has with a low name: each
    //** texture's target, size, format and samples, and for 2D ones the middle texel; each
    //** framebuffer's colour attachment. To find where Gorilla3D leaves its picture. A context
    //** must be current; OpenGL 4.5's direct state access is used, so nothing is bound.)
    procedure Survey;
    //** @abstract(Makes the eye textures, AWidth x AHeight, on ADevice and registers them with
    //** OpenGL. Gorilla3D's context must be current.)
    //**
    //** @param(ADevice The bridge's ID3D11Device (TPeardoxLeiaSR.BridgeDevice).)
    //**
    //** @param(AWidth The width in pixels.)
    //**
    //** @param(AHeight The height in pixels.)
    //**
    //** @returns(True if all is ready; False, with the reason logged, otherwise.)
    function Start(ADevice: Pointer; AWidth, AHeight: Integer): Boolean;
    //** @abstract(Copies the picture just drawn into an eye's texture on the GPU, the right
    //** way up, moved AShift pixels right (left if negative), black where it moved from.)
    //**
    //** @param(AEye 0 left, 1 right.)
    //**
    //** @param(AShift The eye's shift in pixels.)
    //**
    //** @returns(False if the picture is not there or not the textures' size.)
    function CopyEye(AEye, AShift: Integer): Boolean;
    //** @abstract(Has the next CopyEye log a check: the state the copy depends on, and the
    //** middle pixel of the picture and of the eye texture (read back, so only now and
    //** then).)
    procedure CheckNext;
    //** @abstract(The left eye's ID3D11Texture2D, for SubmitEyeTextures.)
    //**
    //** @returns(The texture.)
    function LeftTexture: Pointer;
    //** @abstract(The right eye's.)
    //**
    //** @returns(The texture.)
    function RightTexture: Pointer;
    //** @abstract(True once Start has made everything.)
    property Ready: Boolean read FReady;
    //** @abstract(The device the textures are on; nil before Start.)
    property Device: Pointer read FDevice;
    //** @abstract(The textures' width in pixels.)
    property Width: Integer read FWidth;
    //** @abstract(The textures' height in pixels.)
    property Height: Integer read FHeight;
    //** @abstract(True (the default) to turn the rows over in the copy: OpenGL's run from
    //** the bottom, Direct3D's from the top. False copies them as they are, for a picture
    //** drawn upside down already.)
    property FlipRows: Boolean read FFlipRows write FFlipRows;
  end;

implementation

{$IFDEF MSWINDOWS}
uses
  Winapi.Windows, Winapi.OpenGL;

const
  //** @abstract(Framebuffer target: both.)
  GL_FRAMEBUFFER_T = $8D40;
  //** @abstract(Framebuffer target: reading.)
  GL_READ_FRAMEBUFFER_T = $8CA8;
  //** @abstract(Framebuffer target: drawing.)
  GL_DRAW_FRAMEBUFFER_T = $8CA9;
  //** @abstract(glGetIntegerv: the framebuffer bound for drawing.)
  GL_DRAW_FRAMEBUFFER_BINDING_Q = $8CA6;
  //** @abstract(glGetIntegerv: the framebuffer bound for reading.)
  GL_READ_FRAMEBUFFER_BINDING_Q = $8CAA;
  //** @abstract(The first colour attachment.)
  GL_COLOR_ATTACHMENT0_T = $8CE0;
  //** @abstract(glGetIntegerv: samples per pixel of the draw framebuffer.)
  GL_SAMPLES_Q = $80A9;
  //** @abstract(glGetTextureLevelParameteriv: the internal format.)
  GL_TEXTURE_INTERNAL_FORMAT_Q = $1003;
  //** @abstract(GL_RGBA8, the resolve texture's format when the picture's is not known.)
  GL_RGBA8_F = $8058;
  //** @abstract(glIsEnabled: sRGB conversion on writes.)
  GL_FRAMEBUFFER_SRGB_Q = $8DB9;
  //** @abstract(glGetIntegerv: the buffer bound for glReadPixels' results.)
  GL_PIXEL_PACK_BUFFER_BINDING_Q = $88ED;
  //** @abstract(glCheckFramebufferStatus: complete.)
  GL_FRAMEBUFFER_COMPLETE_S = $8CD5;
  //** @abstract(Attachment parameter: what is attached.)
  GL_ATTACHMENT_OBJECT_TYPE_Q = $8CD0;
  //** @abstract(Attachment parameter: its name.)
  GL_ATTACHMENT_OBJECT_NAME_Q = $8CD1;
  //** @abstract(Attachment object type: a texture.)
  GL_TEXTURE_OBJ = $1702;
  //** @abstract(glGetTexLevelParameteriv: width.)
  GL_TEXTURE_WIDTH_Q = $1000;
  //** @abstract(glGetTexLevelParameteriv: height.)
  GL_TEXTURE_HEIGHT_Q = $1001;
  //** @abstract(wglDXRegisterObjectNV: OpenGL only writes, all of it.)
  WGL_ACCESS_WRITE_DISCARD_NV = $0002;
  //** @abstract(DXGI_FORMAT_B8G8R8A8_UNORM.)
  DXGI_FORMAT_B8G8R8A8_UNORM_F = 87;
  //** @abstract(D3D11_BIND_SHADER_RESOURCE.)
  D3D11_BIND_SHADER_RESOURCE_F = $8;
  //** @abstract(D3D11_BIND_RENDER_TARGET.)
  D3D11_BIND_RENDER_TARGET_F = $20;

type
  //** @abstract(D3D11_TEXTURE2D_DESC, 44 bytes.)
  TPdxTexture2DDesc = record
    Width: Cardinal;
    Height: Cardinal;
    MipLevels: Cardinal;
    ArraySize: Cardinal;
    Format: Cardinal;
    SampleCount: Cardinal;
    SampleQuality: Cardinal;
    Usage: Cardinal;
    BindFlags: Cardinal;
    CPUAccessFlags: Cardinal;
    MiscFlags: Cardinal;
  end;

  //** @abstract(ID3D11Device, as far as CreateTexture2D: the slots before it are kept only
  //** for their places in the table, so Delphi's own Direct3D headers are not needed.)
  IPdxD3D11Device = interface(IUnknown)
    ['{DB6F6DDB-AC77-4E88-8253-819DF9BBF140}']
    //** @abstract(CreateBuffer's slot; not called.)
    function CreateBuffer(A, B, C: Pointer): HResult; stdcall;
    //** @abstract(CreateTexture1D's slot; not called.)
    function CreateTexture1D(A, B, C: Pointer): HResult; stdcall;
    //** @abstract(Makes a 2D texture.)
    function CreateTexture2D(const Desc: TPdxTexture2DDesc; InitialData: Pointer;
      out Texture: IUnknown): HResult; stdcall;
  end;

  //** @abstract(wglDXOpenDeviceNV.)
  TDXOpenDevice = function(DXDevice: Pointer): THandle; stdcall;
  //** @abstract(wglDXCloseDeviceNV.)
  TDXCloseDevice = function(Device: THandle): BOOL; stdcall;
  //** @abstract(wglDXRegisterObjectNV.)
  TDXRegisterObject = function(Device: THandle; DXObject: Pointer; Name, ObjType,
    Access: Cardinal): THandle; stdcall;
  //** @abstract(wglDXUnregisterObjectNV.)
  TDXUnregisterObject = function(Device, Obj: THandle): BOOL; stdcall;
  //** @abstract(wglDXLockObjectsNV and wglDXUnlockObjectsNV.)
  TDXLockObjects = function(Device: THandle; Count: Integer; Objects: PHandle): BOOL; stdcall;
  //** @abstract(glGenFramebuffers and glDeleteFramebuffers.)
  TGenFramebuffers = procedure(N: Integer; Ids: PCardinal); stdcall;
  //** @abstract(glBindFramebuffer.)
  TBindFramebuffer = procedure(Target, Framebuffer: Cardinal); stdcall;
  //** @abstract(glFramebufferTexture2D.)
  TFramebufferTexture2D = procedure(Target, Attachment, TexTarget, Texture: Cardinal;
    Level: Integer); stdcall;
  //** @abstract(glCheckFramebufferStatus.)
  TCheckFramebufferStatus = function(Target: Cardinal): Cardinal; stdcall;
  //** @abstract(glBlitFramebuffer.)
  TBlitFramebuffer = procedure(SrcX0, SrcY0, SrcX1, SrcY1, DstX0, DstY0, DstX1, DstY1: Integer;
    Mask, Filter: Cardinal); stdcall;
  //** @abstract(glGetFramebufferAttachmentParameteriv.)
  TGetFBAttachParam = procedure(Target, Attachment, PName: Cardinal; Params: PInteger); stdcall;
  //** @abstract(glGetTextureLevelParameteriv (OpenGL 4.5): a texture's size by its name,
  //** without binding it.)
  TGetTextureLevelParam = procedure(Texture: Cardinal; Level: Integer; PName: Cardinal;
    Params: PInteger); stdcall;

var
  //** @abstract(The functions, found once a context is current (Load).)
  DXOpenDevice: TDXOpenDevice;
  //** @abstract(See DXOpenDevice.)
  DXCloseDevice: TDXCloseDevice;
  //** @abstract(See DXOpenDevice.)
  DXRegisterObject: TDXRegisterObject;
  //** @abstract(See DXOpenDevice.)
  DXUnregisterObject: TDXUnregisterObject;
  //** @abstract(See DXOpenDevice.)
  DXLockObjects: TDXLockObjects;
  //** @abstract(See DXOpenDevice.)
  DXUnlockObjects: TDXLockObjects;
  //** @abstract(See DXOpenDevice.)
  GenFramebuffers: TGenFramebuffers;
  //** @abstract(See DXOpenDevice.)
  DeleteFramebuffers: TGenFramebuffers;
  //** @abstract(See DXOpenDevice.)
  BindFramebuffer: TBindFramebuffer;
  //** @abstract(See DXOpenDevice.)
  FramebufferTexture2D: TFramebufferTexture2D;
  //** @abstract(See DXOpenDevice.)
  CheckFramebufferStatus: TCheckFramebufferStatus;
  //** @abstract(See DXOpenDevice.)
  BlitFramebuffer: TBlitFramebuffer;
  //** @abstract(See DXOpenDevice.)
  GetFBAttachParam: TGetFBAttachParam;
  //** @abstract(See DXOpenDevice; nil before OpenGL 4.5, when the texture is bound instead.)
  GetTextureLevelParam: TGetTextureLevelParam;
  //** @abstract(glIsFramebuffer, optional.)
  IsFramebufferFn: function(Name: Cardinal): Byte; stdcall;
  //** @abstract(glGetTextureParameteriv (OpenGL 4.5), optional.)
  GetTextureParamFn: procedure(Texture, PName: Cardinal; Params: PInteger); stdcall;
  //** @abstract(glGetNamedFramebufferAttachmentParameteriv (OpenGL 4.5), optional.)
  GetNamedFBAttachFn: procedure(Framebuffer, Attachment, PName: Cardinal;
    Params: PInteger); stdcall;

//** @abstract(Finds the functions; a context must be current.)
//**
//** @param(AMissing Set to the first one not found.)
//**
//** @returns(True if all were found.)
function Load(out AMissing: string): Boolean;

  //** @abstract(Looks one up.)
  //**
  //** @param(AName Its name.)
  //**
  //** @returns(Its address, or nil.)
  function Get(const AName: AnsiString): Pointer;
  begin
    Result := wglGetProcAddress(PAnsiChar(AName));
    if (Result = nil) and (AMissing = '') then
      AMissing := string(AName);
  end;

begin
  AMissing := '';
  @DXOpenDevice := Get('wglDXOpenDeviceNV');
  @DXCloseDevice := Get('wglDXCloseDeviceNV');
  @DXRegisterObject := Get('wglDXRegisterObjectNV');
  @DXUnregisterObject := Get('wglDXUnregisterObjectNV');
  @DXLockObjects := Get('wglDXLockObjectsNV');
  @DXUnlockObjects := Get('wglDXUnlockObjectsNV');
  @GenFramebuffers := Get('glGenFramebuffers');
  @DeleteFramebuffers := Get('glDeleteFramebuffers');
  @BindFramebuffer := Get('glBindFramebuffer');
  @FramebufferTexture2D := Get('glFramebufferTexture2D');
  @CheckFramebufferStatus := Get('glCheckFramebufferStatus');
  @BlitFramebuffer := Get('glBlitFramebuffer');
  @GetFBAttachParam := Get('glGetFramebufferAttachmentParameteriv');
  Result := AMissing = '';
  // Optional: not counted as missing
  @GetTextureLevelParam := wglGetProcAddress('glGetTextureLevelParameteriv');
  @IsFramebufferFn := wglGetProcAddress('glIsFramebuffer');
  @GetTextureParamFn := wglGetProcAddress('glGetTextureParameteriv');
  @GetNamedFBAttachFn := wglGetProcAddress('glGetNamedFramebufferAttachmentParameteriv');
end;
{$ENDIF}

{$IFDEF MSWINDOWS}
//** @abstract(Picks one of two strings.)
//**
//** @param(ACondition Which to pick.)
//**
//** @param(AWhenTrue The string for True.)
//**
//** @param(AWhenFalse The string for False.)
//**
//** @returns(The chosen string.)
function IfThenText(ACondition: Boolean; const AWhenTrue, AWhenFalse: string): string;
begin
  if ACondition then
    Result := AWhenTrue
  else
    Result := AWhenFalse;
end;
{$ENDIF}

{ TPeardoxGLInterop }

constructor TPeardoxGLInterop.Create(const ALog: TPeardoxGLInteropLog);
begin
  inherited Create;
  FLog := ALog;
end;

destructor TPeardoxGLInterop.Destroy;
begin
  Release;
  inherited Destroy;
end;

procedure TPeardoxGLInterop.Log(const AText: string);
begin
  if Assigned(FLog) then
    FLog(AText);
end;

procedure TPeardoxGLInterop.Survey;
{$IFDEF MSWINDOWS}
type
  TIsObject = function(Name: Cardinal): Byte; stdcall;
  TGetTexParam = procedure(Texture, PName: Cardinal; Params: PInteger); stdcall;
  TGetTexSubImage = procedure(Texture: Cardinal; Level, X, Y, Z, W, H, D: Integer;
    Format, PixType: Cardinal; BufSize: Integer; Pixels: Pointer); stdcall;
  TGetNamedFBAttach = procedure(Framebuffer, Attachment, PName: Cardinal;
    Params: PInteger); stdcall;
const
  GL_TEXTURE_TARGET_Q = $1006;
  GL_TEXTURE_SAMPLES_Q = $9106;
  GL_FLOAT_T = $1406;
var
  IsFramebuffer: TIsObject;
  GetTexParam: TGetTexParam;
  GetTexSubImage: TGetTexSubImage;
  GetNamedFBAttach: TGetNamedFBAttach;
  N: Cardinal;
  Target, W, H, Fmt, Samples, ObjType, ObjName: Integer;
  Px: array[0..3] of Single;
  Texel: string;
{$ENDIF}
begin
  {$IFDEF MSWINDOWS}
  if wglGetCurrentContext = 0 then
    Exit;
  @IsFramebuffer := wglGetProcAddress('glIsFramebuffer');
  @GetTexParam := wglGetProcAddress('glGetTextureParameteriv');
  @GetTexSubImage := wglGetProcAddress('glGetTextureSubImage');
  @GetNamedFBAttach := wglGetProcAddress('glGetNamedFramebufferAttachmentParameteriv');
  if not Assigned(GetTexParam) or not Assigned(GetTextureLevelParam) then
  begin
    Log('GL survey: no OpenGL 4.5 direct state access');
    Exit;
  end;
  TakeErrors;
  for N := 1 to 64 do
  begin
    if glIsTexture(N) = 0 then
      Continue;
    Target := 0;
    W := 0;
    H := 0;
    Fmt := 0;
    Samples := 0;
    GetTexParam(N, GL_TEXTURE_TARGET_Q, @Target);
    GetTextureLevelParam(N, 0, GL_TEXTURE_WIDTH_Q, @W);
    GetTextureLevelParam(N, 0, GL_TEXTURE_HEIGHT_Q, @H);
    GetTextureLevelParam(N, 0, GL_TEXTURE_INTERNAL_FORMAT_Q, @Fmt);
    GetTextureLevelParam(N, 0, GL_TEXTURE_SAMPLES_Q, @Samples);
    TakeErrors;
    if (W < 256) or (H < 256) then
      Continue;
    Texel := '';
    if (Target = GL_TEXTURE_2D) and Assigned(GetTexSubImage) then
    begin
      FillChar(Px, SizeOf(Px), 0);
      GetTexSubImage(N, 0, W div 2, H div 2, 0, 1, 1, 1, GL_RGBA, GL_FLOAT_T, SizeOf(Px),
        @Px[0]);
      if TakeErrors = 0 then
        Texel := Format(', middle texel RGBA %.3f %.3f %.3f %.3f', [Px[0], Px[1], Px[2], Px[3]])
      else
        Texel := ', middle texel not read';
    end;
    Log(Format('GL survey: texture %d, target $%x, %d x %d, format $%x, %d samples%s',
      [N, Target, W, H, Fmt, Samples, Texel]));
  end;
  if Assigned(IsFramebuffer) and Assigned(GetNamedFBAttach) then
    for N := 1 to 16 do
    begin
      if IsFramebuffer(N) = 0 then
        Continue;
      ObjType := 0;
      ObjName := 0;
      GetNamedFBAttach(N, GL_COLOR_ATTACHMENT0_T, GL_ATTACHMENT_OBJECT_TYPE_Q, @ObjType);
      GetNamedFBAttach(N, GL_COLOR_ATTACHMENT0_T, GL_ATTACHMENT_OBJECT_NAME_Q, @ObjName);
      TakeErrors;
      Log(Format('GL survey: framebuffer %d, colour attachment 0: type $%x, name %d',
        [N, ObjType, ObjName]));
    end;
  TakeErrors;
  {$ENDIF}
end;

class function TPeardoxGLInterop.TakeErrors: Cardinal;
{$IFDEF MSWINDOWS}
var
  E: Cardinal;
  N: Integer;
{$ENDIF}
begin
  Result := 0;
  {$IFDEF MSWINDOWS}
  if wglGetCurrentContext = 0 then
    Exit;
  // glGetError gives one flag at a time; a lost context keeps giving one,
  // so not forever
  for N := 1 to 32 do
  begin
    E := glGetError;
    if E = GL_NO_ERROR then
      Break;
    if Result = 0 then
      Result := E;
  end;
  {$ENDIF}
end;

class function TPeardoxGLInterop.SourceSize(out AWidth, AHeight: Integer): Boolean;
{$IFDEF MSWINDOWS}
var
  FB, ObjType, Tex, Bound: Integer;
  Missing: string;
{$ENDIF}
begin
  AWidth := 0;
  AHeight := 0;
  Result := False;
  {$IFDEF MSWINDOWS}
  if wglGetCurrentContext = 0 then
    Exit;
  if not Assigned(GetFBAttachParam) and not Load(Missing) then
    Exit;
  FB := 0;
  glGetIntegerv(GL_READ_FRAMEBUFFER_BINDING_Q, @FB);
  if FB = 0 then
    Exit;
  ObjType := 0;
  Tex := 0;
  GetFBAttachParam(GL_READ_FRAMEBUFFER_T, GL_COLOR_ATTACHMENT0_T, GL_ATTACHMENT_OBJECT_TYPE_Q,
    @ObjType);
  GetFBAttachParam(GL_READ_FRAMEBUFFER_T, GL_COLOR_ATTACHMENT0_T, GL_ATTACHMENT_OBJECT_NAME_Q,
    @Tex);
  if (ObjType = GL_TEXTURE_OBJ) and (Tex <> 0) then
  begin
    if Assigned(GetTextureLevelParam) then
    begin
      // By name: nothing bound, nothing to put back
      GetTextureLevelParam(Tex, 0, GL_TEXTURE_WIDTH_Q, @AWidth);
      GetTextureLevelParam(Tex, 0, GL_TEXTURE_HEIGHT_Q, @AHeight);
    end
    else
    begin
      // Bound for a moment and the binding put back
      Bound := 0;
      glGetIntegerv(GL_TEXTURE_BINDING_2D, @Bound);
      glBindTexture(GL_TEXTURE_2D, Tex);
      glGetTexLevelParameteriv(GL_TEXTURE_2D, 0, GL_TEXTURE_WIDTH_Q, @AWidth);
      glGetTexLevelParameteriv(GL_TEXTURE_2D, 0, GL_TEXTURE_HEIGHT_Q, @AHeight);
      glBindTexture(GL_TEXTURE_2D, Bound);
    end;
  end;
  // Owner (21:10): the one "cannot begin rendering scene ... 1282" came on
  // the set-up frame, where this ran with nothing after it to take an error
  // before MakeScreenshot's BeginScene; the zero-copy frames' "$502 after
  // the blit" was very likely this too (binding the texture back)
  TakeErrors;
  Result := (AWidth > 0) and (AHeight > 0);
  {$ENDIF}
end;

function TPeardoxGLInterop.FindPicture(ABound: Integer): Integer;
{$IFDEF MSWINDOWS}
const
  GL_TEXTURE_TARGET_Q = $1006;
  GL_TEXTURE_SAMPLES_Q = $9106;
  GL_TEXTURE_2D_MS_Q = $9100;
  PICK_GRID = 8;
var
  FB, ObjType, Tex, Target, W, H, Fmt, Samples, Lit, BestLit, GX, GY, PackBuf: Integer;
  FirstMS8, First2D8: Integer;
  PrevDraw, BoundTex: Integer;
  TestTex, TestFBO: Cardinal;
  Px: array[0..3] of Byte;
{$ENDIF}
begin
  Result := ABound;
  {$IFDEF MSWINDOWS}
  if not Assigned(IsFramebufferFn) or not Assigned(GetNamedFBAttachFn) or
    not Assigned(GetTextureParamFn) or not Assigned(GetTextureLevelParam) then
  begin
    Log('Zero copy: no OpenGL 4.5 direct state access to look for the picture; the bound ' +
      'framebuffer is used');
    Exit;
  end;
  PackBuf := 0;
  glGetIntegerv(GL_PIXEL_PACK_BUFFER_BINDING_Q, @PackBuf);
  PrevDraw := 0;
  glGetIntegerv(GL_DRAW_FRAMEBUFFER_BINDING_Q, @PrevDraw);
  BestLit := 0;
  FirstMS8 := 0;
  First2D8 := 0;
  TakeErrors;
  // An 8-bit test target: a multisampled 8-bit candidate (FMX's own
  // multisampled buffer, say) is resolved into it to be read
  TestTex := 0;
  TestFBO := 0;
  BoundTex := 0;
  glGetIntegerv(GL_TEXTURE_BINDING_2D, @BoundTex);
  glGenTextures(1, @TestTex);
  glBindTexture(GL_TEXTURE_2D, TestTex);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8_F, FWidth, FHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE,
    nil);
  glBindTexture(GL_TEXTURE_2D, BoundTex);
  GenFramebuffers(1, @TestFBO);
  BindFramebuffer(GL_DRAW_FRAMEBUFFER_T, TestFBO);
  FramebufferTexture2D(GL_DRAW_FRAMEBUFFER_T, GL_COLOR_ATTACHMENT0_T, GL_TEXTURE_2D,
    TestTex, 0);
  if CheckFramebufferStatus(GL_DRAW_FRAMEBUFFER_T) <> GL_FRAMEBUFFER_COMPLETE_S then
  begin
    BindFramebuffer(GL_DRAW_FRAMEBUFFER_T, PrevDraw);
    if Assigned(DeleteFramebuffers) then
      DeleteFramebuffers(1, @TestFBO);
    TestFBO := 0;
  end;
  BindFramebuffer(GL_DRAW_FRAMEBUFFER_T, PrevDraw);
  TakeErrors;
  try
    for FB := 1 to 32 do
    begin
      if IsFramebufferFn(FB) = 0 then
        Continue;
      ObjType := 0;
      Tex := 0;
      GetNamedFBAttachFn(FB, GL_COLOR_ATTACHMENT0_T, GL_ATTACHMENT_OBJECT_TYPE_Q, @ObjType);
      GetNamedFBAttachFn(FB, GL_COLOR_ATTACHMENT0_T, GL_ATTACHMENT_OBJECT_NAME_Q, @Tex);
      if TakeErrors <> 0 then
        Continue;
      if (ObjType <> GL_TEXTURE_OBJ) or (Tex = 0) then
        Continue;
      Target := 0;
      W := 0;
      H := 0;
      Fmt := 0;
      Samples := 0;
      GetTextureParamFn(Tex, GL_TEXTURE_TARGET_Q, @Target);
      GetTextureLevelParam(Tex, 0, GL_TEXTURE_WIDTH_Q, @W);
      GetTextureLevelParam(Tex, 0, GL_TEXTURE_HEIGHT_Q, @H);
      GetTextureLevelParam(Tex, 0, GL_TEXTURE_INTERNAL_FORMAT_Q, @Fmt);
      GetTextureLevelParam(Tex, 0, GL_TEXTURE_SAMPLES_Q, @Samples);
      TakeErrors;
      if (W <> FWidth) or (H <> FHeight) then
        Continue;
      // Something drawn? A 2D one is read as it is, a multisampled 8-bit one
      // after resolving into the test target; others are only logged
      Lit := -1;
      if (PackBuf = 0) and ((Target = GL_TEXTURE_2D) or ((Target = GL_TEXTURE_2D_MS_Q) and
        (Fmt = GL_RGBA8_F) and (TestFBO <> 0))) then
      begin
        Lit := 0;
        BindFramebuffer(GL_READ_FRAMEBUFFER_T, FB);
        if Target = GL_TEXTURE_2D_MS_Q then
        begin
          BindFramebuffer(GL_DRAW_FRAMEBUFFER_T, TestFBO);
          BlitFramebuffer(0, 0, FWidth, FHeight, 0, 0, FWidth, FHeight, GL_COLOR_BUFFER_BIT,
            GL_NEAREST);
          BindFramebuffer(GL_DRAW_FRAMEBUFFER_T, PrevDraw);
          BindFramebuffer(GL_READ_FRAMEBUFFER_T, TestFBO);
        end;
        // An 8 x 8 grid: owner (21:37), a 3 x 3 one found nothing lit in
        // FMX's picture one run in two (the points fell between the shapes)
        for GY := 1 to PICK_GRID do
          for GX := 1 to PICK_GRID do
          begin
            FillChar(Px, SizeOf(Px), 0);
            glReadPixels(FWidth * GX div (PICK_GRID + 1), FHeight * GY div (PICK_GRID + 1), 1, 1,
              GL_RGBA,
              GL_UNSIGNED_BYTE, @Px[0]);
            if Px[0] or Px[1] or Px[2] <> 0 then
              Inc(Lit);
          end;
        if TakeErrors <> 0 then
          Lit := -1;
      end;
      Log(Format('Zero copy: framebuffer %d, texture %d, target $%x, format $%x, %d samples, ' +
        'lit %d of %d%s', [FB, Tex, Target, Fmt, Samples, Lit, PICK_GRID * PICK_GRID,
        IfThenText(FB = ABound, ' (bound after RenderManual)', '')]));
      // 8-bit ones in case none is lit: FMX's own (multisampled) first
      if Fmt = GL_RGBA8_F then
      begin
        if (Target = GL_TEXTURE_2D_MS_Q) and (FirstMS8 = 0) then
          FirstMS8 := FB
        else if (Target = GL_TEXTURE_2D) and (First2D8 = 0) then
          First2D8 := FB;
      end;
      if Lit > BestLit then
      begin
        BestLit := Lit;
        Result := FB;
      end;
    end;
  finally
    BindFramebuffer(GL_READ_FRAMEBUFFER_T, ABound);
    BindFramebuffer(GL_DRAW_FRAMEBUFFER_T, PrevDraw);
    if (TestFBO <> 0) and Assigned(DeleteFramebuffers) then
      DeleteFramebuffers(1, @TestFBO);
    if TestTex <> 0 then
      glDeleteTextures(1, @TestTex);
    TakeErrors;
  end;
  if BestLit = 0 then
  begin
    // Nothing lit (an empty first frame, or every point on the background):
    // FMX's own 8-bit picture rather than Gorilla3D's HDR target, which
    // gave black (owner, 21:25 and 21:37)
    if FirstMS8 <> 0 then
      Result := FirstMS8
    else if First2D8 <> 0 then
      Result := First2D8;
    Log(Format('Zero copy: nothing lit in any; framebuffer %d chosen by its kind', [Result]));
  end;
  Log(Format('Zero copy: the picture is taken from framebuffer %d', [Result]));
  {$ENDIF}
end;

function TPeardoxGLInterop.Start(ADevice: Pointer; AWidth, AHeight: Integer): Boolean;
{$IFDEF MSWINDOWS}
var
  Missing: string;
  Dev: IPdxD3D11Device;
  Desc: TPdxTexture2DDesc;
  HR: HResult;
  I, PrevDraw, ReadFB, SrcTex, Bound: Integer;
  Status: Cardinal;
{$ENDIF}
begin
  Release;
  Result := False;
  {$IFDEF MSWINDOWS}
  if wglGetCurrentContext = 0 then
  begin
    Log('Zero copy: no OpenGL context current');
    Exit;
  end;
  if not Load(Missing) then
  begin
    Log('Zero copy: OpenGL has no ' + Missing + ' (WGL_NV_DX_interop2 needed)');
    Exit;
  end;
  if (ADevice = nil) or not Supports(IUnknown(ADevice), IPdxD3D11Device, Dev) then
  begin
    Log('Zero copy: no Direct3D 11 device from the bridge');
    Exit;
  end;
  FDevice := ADevice;
  FGLContext := wglGetCurrentContext;
  FGLDC := wglGetCurrentDC;
  FWidth := AWidth;
  FHeight := AHeight;
  FillChar(Desc, SizeOf(Desc), 0);
  Desc.Width := AWidth;
  Desc.Height := AHeight;
  Desc.MipLevels := 1;
  Desc.ArraySize := 1;
  Desc.Format := DXGI_FORMAT_B8G8R8A8_UNORM_F;
  Desc.SampleCount := 1;
  Desc.BindFlags := D3D11_BIND_SHADER_RESOURCE_F or D3D11_BIND_RENDER_TARGET_F;
  for I := 0 to 1 do
  begin
    HR := Dev.CreateTexture2D(Desc, nil, FTex[I]);
    if Failed(HR) then
    begin
      Log(Format('Zero copy: CreateTexture2D %d x %d failed, $%x', [AWidth, AHeight, HR]));
      Release;
      Exit;
    end;
  end;
  FDXDevice := DXOpenDevice(ADevice);
  if FDXDevice = 0 then
  begin
    Log(Format('Zero copy: wglDXOpenDeviceNV failed (%d)', [GetLastError]));
    Release;
    Exit;
  end;
  PrevDraw := 0;
  glGetIntegerv(GL_DRAW_FRAMEBUFFER_BINDING_Q, @PrevDraw);
  // The picture Gorilla3D drew: multisampled (FMX's 3D views are, four
  // samples by default) and its format. Owner (21:17): the picture read back
  // 0 0 0 0 and the eye textures stayed black, with $502 after the blit -
  // a multisampled framebuffer cannot be blitted flipped, moved or into
  // another format, only resolved as it is
  ReadFB := 0;
  glGetIntegerv(GL_READ_FRAMEBUFFER_BINDING_Q, @ReadFB);
  // Owner (21:25): the framebuffer left bound after RenderManual (Gorilla3D's
  // multisampled HDR target) read black at all nine points even resolved:
  // the finished picture is elsewhere, so it is looked for
  FSourceFB := FindPicture(ReadFB);
  FSamples := 0;
  FSourceFormat := 0;
  if FSourceFB <> 0 then
  begin
    BindFramebuffer(GL_DRAW_FRAMEBUFFER_T, FSourceFB);
    glGetIntegerv(GL_SAMPLES_Q, @FSamples);
    BindFramebuffer(GL_DRAW_FRAMEBUFFER_T, PrevDraw);
    BindFramebuffer(GL_READ_FRAMEBUFFER_T, FSourceFB);
    SrcTex := 0;
    GetFBAttachParam(GL_READ_FRAMEBUFFER_T, GL_COLOR_ATTACHMENT0_T,
      GL_ATTACHMENT_OBJECT_NAME_Q, @SrcTex);
    BindFramebuffer(GL_READ_FRAMEBUFFER_T, ReadFB);
    if (SrcTex <> 0) and Assigned(GetTextureLevelParam) then
      GetTextureLevelParam(SrcTex, 0, GL_TEXTURE_INTERNAL_FORMAT_Q, @FSourceFormat);
  end;
  TakeErrors;
  glGenTextures(2, @FGLTex[0]);
  GenFramebuffers(2, @FFBO[0]);
  if FSamples > 1 then
  begin
    // The resolve target: the picture's own format and size
    if FSourceFormat = 0 then
      FSourceFormat := GL_RGBA8_F;
    Bound := 0;
    glGetIntegerv(GL_TEXTURE_BINDING_2D, @Bound);
    glGenTextures(1, @FResolveTex);
    glBindTexture(GL_TEXTURE_2D, FResolveTex);
    glTexImage2D(GL_TEXTURE_2D, 0, FSourceFormat, AWidth, AHeight, 0, GL_RGBA,
      GL_UNSIGNED_BYTE, nil);
    glBindTexture(GL_TEXTURE_2D, Bound);
    GenFramebuffers(1, @FResolveFBO);
    BindFramebuffer(GL_DRAW_FRAMEBUFFER_T, FResolveFBO);
    FramebufferTexture2D(GL_DRAW_FRAMEBUFFER_T, GL_COLOR_ATTACHMENT0_T, GL_TEXTURE_2D,
      FResolveTex, 0);
    Status := CheckFramebufferStatus(GL_DRAW_FRAMEBUFFER_T);
    BindFramebuffer(GL_DRAW_FRAMEBUFFER_T, PrevDraw);
    if Status <> GL_FRAMEBUFFER_COMPLETE_S then
    begin
      Log(Format('Zero copy: the resolve framebuffer is not complete ($%x)', [Status]));
      Release;
      Exit;
    end;
  end;
  try
    for I := 0 to 1 do
    begin
      FDXObj[I] := DXRegisterObject(FDXDevice, Pointer(FTex[I]), FGLTex[I], GL_TEXTURE_2D,
        WGL_ACCESS_WRITE_DISCARD_NV);
      if FDXObj[I] = 0 then
      begin
        Log(Format('Zero copy: wglDXRegisterObjectNV failed (%d)', [GetLastError]));
        Release;
        Exit;
      end;
      DXLockObjects(FDXDevice, 1, @FDXObj[I]);
      try
        BindFramebuffer(GL_DRAW_FRAMEBUFFER_T, FFBO[I]);
        FramebufferTexture2D(GL_DRAW_FRAMEBUFFER_T, GL_COLOR_ATTACHMENT0_T, GL_TEXTURE_2D,
          FGLTex[I], 0);
        Status := CheckFramebufferStatus(GL_DRAW_FRAMEBUFFER_T);
      finally
        DXUnlockObjects(FDXDevice, 1, @FDXObj[I]);
      end;
      if Status <> GL_FRAMEBUFFER_COMPLETE_S then
      begin
        Log(Format('Zero copy: the eye framebuffer is not complete ($%x)', [Status]));
        Release;
        Exit;
      end;
    end;
  finally
    BindFramebuffer(GL_DRAW_FRAMEBUFFER_T, PrevDraw);
  end;
  // Nothing of ours left for FMX's next BeginScene
  Status := TakeErrors;
  if Status <> 0 then
    Log(Format('Zero copy: OpenGL error $%x while making the eye textures', [Status]));
  FReady := True;
  Result := True;
  if FSamples > 1 then
    Log(Format('Zero copy: the picture has %d samples per pixel, internal format $%x: ' +
      'resolved first, then copied', [FSamples, FSourceFormat]))
  else
    Log(Format('Zero copy: the picture is not multisampled, internal format $%x: copied ' +
      'directly', [FSourceFormat]));
  Log(Format('Zero copy: two %d x %d eye textures on the bridge''s Direct3D 11 device, drawn ' +
    'into by OpenGL (WGL_NV_DX_interop2); no screenshot, copy or upload', [AWidth, AHeight]));
  {$ELSE}
  Log('Zero copy: Windows only');
  {$ENDIF}
end;

function TPeardoxGLInterop.CopyEye(AEye, AShift: Integer): Boolean;
{$IFDEF MSWINDOWS}
var
  ReadFB, PrevDraw, ReadBuf, PackBuf: Integer;
  Scissor, SRGB: Boolean;
  Clear: array[0..3] of Single;
  Mask: array[0..3] of Byte;
  Src, Dst: array[0..3] of Byte;
  SrcLit, DstLit, GX, GY, PX, PY: Integer;
  Grid: array[0..3] of Byte;
  Checked: Boolean;
{$ENDIF}
begin
  Result := False;
  {$IFDEF MSWINDOWS}
  if not FReady or (AEye < 0) or (AEye > 1) then
    Exit;
  ReadFB := 0;
  glGetIntegerv(GL_READ_FRAMEBUFFER_BINDING_Q, @ReadFB);
  if FSourceFB = 0 then
    Exit;
  PrevDraw := 0;
  glGetIntegerv(GL_DRAW_FRAMEBUFFER_BINDING_Q, @PrevDraw);
  // The picture's framebuffer for reading (FindPicture's choice); the one
  // bound now is put back after
  BindFramebuffer(GL_READ_FRAMEBUFFER_T, FSourceFB);
  // State the blit and the clear depend on, set for them and put back
  // after: the scissor, the colour mask, the clear colour (Gorilla3D's), and
  // the source's read buffer (a blit from GL_NONE copies nothing, without an
  // error: owner, 21:14, zero copy ran at 100 fps and showed no picture).
  // GLboolean is a Byte in Winapi.OpenGL
  Scissor := glIsEnabled(GL_SCISSOR_TEST) <> 0;
  SRGB := glIsEnabled(GL_FRAMEBUFFER_SRGB_Q) <> 0;
  glGetFloatv(GL_COLOR_CLEAR_VALUE, @Clear[0]);
  glGetBooleanv(GL_COLOR_WRITEMASK, @Mask[0]);
  ReadBuf := 0;
  glGetIntegerv(GL_READ_BUFFER, @ReadBuf);
  Checked := FCheckNext;
  FCheckNext := False;
  if not DXLockObjects(FDXDevice, 1, @FDXObj[AEye]) then
  begin
    BindFramebuffer(GL_READ_FRAMEBUFFER_T, ReadFB);
    Exit;
  end;
  try
    if Scissor then
      glDisable(GL_SCISSOR_TEST);
    glColorMask(1, 1, 1, 1);
    if ReadBuf <> GL_COLOR_ATTACHMENT0_T then
      glReadBuffer(GL_COLOR_ATTACHMENT0_T);
    if FResolveFBO <> 0 then
    begin
      // Multisampled: resolved as it is, then copied from there
      BindFramebuffer(GL_DRAW_FRAMEBUFFER_T, FResolveFBO);
      BlitFramebuffer(0, 0, FWidth, FHeight, 0, 0, FWidth, FHeight, GL_COLOR_BUFFER_BIT,
        GL_NEAREST);
      BindFramebuffer(GL_READ_FRAMEBUFFER_T, FResolveFBO);
    end;
    SrcLit := 0;
    if Checked then
    begin
      // Once in a while: nine pixels of the picture (a 3 x 3 grid), before
      // the copy - the middle one alone can fall between the spheres
      // (owner, 21:23: every texture's middle texel was the background)
      PackBuf := 0;
      glGetIntegerv(GL_PIXEL_PACK_BUFFER_BINDING_Q, @PackBuf);
      Checked := PackBuf = 0;
      FillChar(Src, SizeOf(Src), 0);
      if Checked then
      begin
        glReadPixels(FWidth div 2, FHeight div 2, 1, 1, GL_RGBA, GL_UNSIGNED_BYTE, @Src[0]);
        for GY := 1 to 3 do
          for GX := 1 to 3 do
          begin
            glReadPixels(FWidth * GX div 4, FHeight * GY div 4, 1, 1, GL_RGBA,
              GL_UNSIGNED_BYTE, @Grid[0]);
            if Grid[0] or Grid[1] or Grid[2] <> 0 then
              Inc(SrcLit);
          end;
      end;
    end;
    BindFramebuffer(GL_DRAW_FRAMEBUFFER_T, FFBO[AEye]);
    if AShift <> 0 then
    begin
      // Black where the picture moved away from
      glClearColor(0, 0, 0, 1);
      glClear(GL_COLOR_BUFFER_BIT);
    end;
    // OpenGL's rows run from the bottom, Direct3D's from the top: drawn
    // upside down here, the texture is the right way up
    if FFlipRows then
      BlitFramebuffer(0, 0, FWidth, FHeight, AShift, FHeight, FWidth + AShift, 0,
        GL_COLOR_BUFFER_BIT, GL_NEAREST)
    else
      BlitFramebuffer(0, 0, FWidth, FHeight, AShift, 0, FWidth + AShift, FHeight,
        GL_COLOR_BUFFER_BIT, GL_NEAREST);
    if Checked then
    begin
      // The same pixel in the eye texture (rows turned over, so the middle
      // row of the other half; near enough to see whether anything arrived)
      FillChar(Dst, SizeOf(Dst), 0);
      BindFramebuffer(GL_READ_FRAMEBUFFER_T, FFBO[AEye]);
      glReadPixels(FWidth div 2 + AShift, FHeight div 2, 1, 1, GL_RGBA, GL_UNSIGNED_BYTE,
        @Dst[0]);
      // The same grid in the eye texture: turned over and shifted, so the
      // rows and columns map back as the blit put them
      DstLit := 0;
      for GY := 1 to 3 do
        for GX := 1 to 3 do
        begin
          PX := FWidth * GX div 4 + AShift;
          PY := FHeight * GY div 4;
          if FFlipRows then
            PY := FHeight - 1 - PY;
          if (PX < 0) or (PX >= FWidth) then
            Continue;
          glReadPixels(PX, PY, 1, 1, GL_RGBA, GL_UNSIGNED_BYTE, @Grid[0]);
          if Grid[0] or Grid[1] or Grid[2] <> 0 then
            Inc(DstLit);
        end;
      Log(Format('Zero copy check (eye %d): source framebuffer %d (%d samples), read buffer ' +
        '$%x, colour mask %d%d%d%d, sRGB writes %s, scissor %s | middle pixel RGBA source ' +
        '%d %d %d %d, eye texture %d %d %d %d | of a 3 x 3 grid, not black: source %d, eye ' +
        'texture %d', [AEye, FSourceFB, FSamples, ReadBuf, Mask[0], Mask[1], Mask[2], Mask[3],
        BoolToStr(SRGB, True), BoolToStr(Scissor, True), Src[0], Src[1], Src[2], Src[3], Dst[0],
        Dst[1], Dst[2], Dst[3], SrcLit, DstLit]));
    end;
    Result := True;
  finally
    // The source's read buffer as it was, then the framebuffers bound before
    BindFramebuffer(GL_READ_FRAMEBUFFER_T, FSourceFB);
    if ReadBuf <> GL_COLOR_ATTACHMENT0_T then
      glReadBuffer(ReadBuf);
    BindFramebuffer(GL_READ_FRAMEBUFFER_T, ReadFB);
    BindFramebuffer(GL_DRAW_FRAMEBUFFER_T, PrevDraw);
    glColorMask(Mask[0], Mask[1], Mask[2], Mask[3]);
    if Scissor then
      glEnable(GL_SCISSOR_TEST);
    glClearColor(Clear[0], Clear[1], Clear[2], Clear[3]);
    DXUnlockObjects(FDXDevice, 1, @FDXObj[AEye]);
  end;
  {$ENDIF}
end;

procedure TPeardoxGLInterop.CheckNext;
begin
  FCheckNext := True;
end;

function TPeardoxGLInterop.LeftTexture: Pointer;
begin
  Result := Pointer(FTex[0]);
end;

function TPeardoxGLInterop.RightTexture: Pointer;
begin
  Result := Pointer(FTex[1]);
end;

procedure TPeardoxGLInterop.Release;
{$IFDEF MSWINDOWS}
var
  I: Integer;
  Current, MadeCurrent: Boolean;
{$ENDIF}
begin
  {$IFDEF MSWINDOWS}
  // OpenGL's side can only be undone with its context current: Start's is
  // made current for it if none is (FormClose, SR stopping), and let go of
  // after; if that cannot be done its few names are left
  Current := wglGetCurrentContext <> 0;
  MadeCurrent := False;
  if not Current and (FGLContext <> 0) and (FGLDC <> 0) and
    ((FDXDevice <> 0) or (FGLTex[0] <> 0)) then
  begin
    MadeCurrent := wglMakeCurrent(FGLDC, FGLContext);
    Current := MadeCurrent;
  end;
  for I := 0 to 1 do
  begin
    if Current and (FDXObj[I] <> 0) and Assigned(DXUnregisterObject) then
      DXUnregisterObject(FDXDevice, FDXObj[I]);
    FDXObj[I] := 0;
  end;
  if Current then
  begin
    if (FGLTex[0] <> 0) or (FGLTex[1] <> 0) then
      glDeleteTextures(2, @FGLTex[0]);
    if ((FFBO[0] <> 0) or (FFBO[1] <> 0)) and Assigned(DeleteFramebuffers) then
      DeleteFramebuffers(2, @FFBO[0]);
    if (FResolveFBO <> 0) and Assigned(DeleteFramebuffers) then
      DeleteFramebuffers(1, @FResolveFBO);
    if FResolveTex <> 0 then
      glDeleteTextures(1, @FResolveTex);
    if (FDXDevice <> 0) and Assigned(DXCloseDevice) then
      DXCloseDevice(FDXDevice);
  end;
  if Current then
    TakeErrors;
  if MadeCurrent then
    wglMakeCurrent(0, 0);
  FGLTex[0] := 0;
  FGLTex[1] := 0;
  FFBO[0] := 0;
  FFBO[1] := 0;
  FResolveFBO := 0;
  FResolveTex := 0;
  FSourceFB := 0;
  FFlipRows := True;
  FDXDevice := 0;
  FGLContext := 0;
  FGLDC := 0;
  {$ENDIF}
  FTex[0] := nil;
  FTex[1] := nil;
  FDevice := nil;
  FReady := False;
end;

end.
