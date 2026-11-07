//** @abstract(A one-off look at OpenGL around Gorilla3D's render, for the zero-copy path.)
//**
//** ProbeGL logs, once per call, what is needed to copy Gorilla3D's picture to the bridge on
//** the GPU (owner, 7 November 2026: "all the speed we can give them helps them if not us"):
//** whether an OpenGL context is current and on which GPU, whether WGL_NV_DX_interop2 is
//** there (OpenGL drawing into Direct3D 11 textures), which framebuffer and texture are bound
//** and what the framebuffer's colour attachment is, and the textures and contexts the
//** viewport keeps in its fields (found by RTTI, private ones too). Nothing is changed.
//**
//** Windows only; elsewhere ProbeGL logs that it does nothing.
unit StereoModelGLProbe;

{
  A one-off look at OpenGL around Gorilla3D's render, for the zero-copy
  path: the context and GPU, WGL_NV_DX_interop2, the bound framebuffer and
  texture, the framebuffer's colour attachment, and the textures and
  contexts in the viewport's fields (RTTI). Nothing is changed. Windows only.
}

interface

type
  //** @abstract(Where ProbeGL's lines go.)
  //**
  //** @param(AText The line.)
  TGLProbeLog = reference to procedure(const AText: string);

//** @abstract(Logs the OpenGL state and the viewport's textures and contexts.)
//**
//** @param(AViewport The Gorilla3D viewport.)
//**
//** @param(AWhen When this is (after RenderManual, say), for the lines.)
//**
//** @param(ALog Where the lines go.)
procedure ProbeGL(AViewport: TObject; const AWhen: string; const ALog: TGLProbeLog);

implementation

uses
  {$IFDEF MSWINDOWS}
  Winapi.Windows, Winapi.OpenGL,
  {$ENDIF}
  System.SysUtils, System.UITypes, System.Rtti, System.TypInfo, FMX.Types, FMX.Types3D;

{$IFDEF MSWINDOWS}
const
  //** @abstract(glGetIntegerv: the framebuffer bound for drawing.)
  GL_DRAW_FRAMEBUFFER_BINDING = $8CA6;
  //** @abstract(glGetIntegerv: the framebuffer bound for reading.)
  GL_READ_FRAMEBUFFER_BINDING = $8CAA;
  //** @abstract(glGetIntegerv: the renderbuffer bound.)
  GL_RENDERBUFFER_BINDING = $8CA7;
  //** @abstract(glGetFramebufferAttachmentParameteriv's target: the read framebuffer.)
  GL_READ_FRAMEBUFFER = $8CA8;
  //** @abstract(The first colour attachment.)
  GL_COLOR_ATTACHMENT0 = $8CE0;
  //** @abstract(Attachment parameter: what is attached (texture, renderbuffer, none).)
  GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE = $8CD0;
  //** @abstract(Attachment parameter: the attached texture's or renderbuffer's name.)
  GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME = $8CD1;
  //** @abstract(Attachment object type: a texture.)
  GL_TEXTURE_OBJ = $1702;
  //** @abstract(Attachment object type: a renderbuffer.)
  GL_RENDERBUFFER_OBJ = $8D41;
  //** @abstract(glGetTexLevelParameteriv: the width.)
  GL_TEXTURE_WIDTH_Q = $1000;
  //** @abstract(glGetTexLevelParameteriv: the height.)
  GL_TEXTURE_HEIGHT_Q = $1001;
  //** @abstract(glGetTexLevelParameteriv: the internal format.)
  GL_TEXTURE_INTERNAL_FORMAT_Q = $1003;
  //** @abstract(glGetTexLevelParameteriv: the samples (multisampled textures).)
  GL_TEXTURE_SAMPLES_Q = $9106;

type
  //** @abstract(glGetFramebufferAttachmentParameteriv.)
  TGetFBAttachParam = procedure(Target, Attachment, PName: Cardinal; Params: PInteger); stdcall;
  //** @abstract(wglGetExtensionsStringARB.)
  TGetExtensionsStringARB = function(DC: HDC): PAnsiChar; stdcall;

//** @abstract(A string from glGetString, or "(none)".)
//**
//** @param(AName What to get.)
//**
//** @returns(The string.)
function GLStr(AName: Cardinal): string;
var
  P: PAnsiChar;
begin
  P := PAnsiChar(glGetString(AName));
  if P = nil then
    Result := '(none)'
  else
    Result := string(AnsiString(P));
end;

//** @abstract(One integer from glGetIntegerv. Not named GLInt: Delphi names ignore case, and
//** GLint is the type.)
//**
//** @param(AName What to get.)
//**
//** @returns(The value.)
function GLInteger(AName: Cardinal): Integer;
var
  V: array[0..3] of GLint;
begin
  FillChar(V, SizeOf(V), 0);
  glGetIntegerv(AName, @V[0]);
  Result := V[0];
end;

//** @abstract(Logs the textures and contexts an object keeps in its fields, private ones
//** too, as far as RTTI tells.)
//**
//** @param(AObj The object.)
//**
//** @param(ADepth How far to follow contexts: 0 not at all.)
//**
//** @param(ALog Where the lines go.)
procedure ProbeFields(AObj: TObject; ADepth: Integer; const ALog: TGLProbeLog);
var
  Ctx: TRttiContext;
  F: TRttiField;
  V: TValue;
  O: TObject;
  T: TTexture;
  Name: string;
  Found: Integer;
begin
  if AObj = nil then
    Exit;
  Found := 0;
  Ctx := TRttiContext.Create;
  try
    for F in Ctx.GetType(AObj.ClassType).GetFields do
    begin
      if F.FieldType = nil then
        Continue;
      Name := F.Parent.Name + '.' + F.Name;
      try
        if F.FieldType.TypeKind = tkClass then
        begin
          V := F.GetValue(AObj);
          O := V.AsObject;
          if O is TTexture then
          begin
            T := TTexture(O);
            ALog(Format('  GL probe: %s is a %s, %d x %d, handle %d, pixel format %s', [Name,
              T.ClassName, T.Width, T.Height, NativeInt(T.Handle),
              GetEnumName(TypeInfo(TPixelFormat), Ord(T.PixelFormat))]));
            Inc(Found);
          end
          else if O is TContext3D then
          begin
            ALog(Format('  GL probe: %s is a context, %s', [Name, O.ClassName]));
            Inc(Found);
            if ADepth > 0 then
              ProbeFields(O, ADepth - 1, ALog);
          end;
        end
        else if (F.FieldType.TypeKind in [tkInteger, tkInt64]) and
          (Pos('FBO', UpperCase(F.Name)) + Pos('FRAMEBUF', UpperCase(F.Name)) +
          Pos('RENDERBUF', UpperCase(F.Name)) + Pos('TEX', UpperCase(F.Name)) > 0) then
        begin
          ALog(Format('  GL probe: %s = %s', [Name, F.GetValue(AObj).ToString]));
          Inc(Found);
        end;
      except
        on E: Exception do
          ALog(Format('  GL probe: %s not read: %s', [Name, E.Message]));
      end;
    end;
  finally
    Ctx.Free;
  end;
  if Found = 0 then
    ALog(Format('  GL probe: no texture, context or framebuffer field found in %s (RTTI)',
      [AObj.ClassName]));
end;
{$ENDIF}

procedure ProbeGL(AViewport: TObject; const AWhen: string; const ALog: TGLProbeLog);
{$IFDEF MSWINDOWS}
var
  RC: HGLRC;
  DC: HDC;
  Exts: string;
  GetExts: TGetExtensionsStringARB;
  GetAttach: TGetFBAttachParam;
  ReadFB, ObjType, ObjName, W, H, Fmt, Samples: Integer;
{$ENDIF}
begin
  {$IFDEF MSWINDOWS}
  try
    RC := wglGetCurrentContext;
    DC := wglGetCurrentDC;
    ALog(Format('GL probe (%s): context %p, DC %p, viewport %s', [AWhen, Pointer(RC),
      Pointer(DC), AViewport.ClassName]));
    if RC <> 0 then
    begin
      ALog(Format('  GL probe: %s | %s | %s', [GLStr(GL_VENDOR), GLStr(GL_RENDERER),
        GLStr(GL_VERSION)]));
      Exts := '';
      @GetExts := wglGetProcAddress('wglGetExtensionsStringARB');
      if Assigned(GetExts) and (DC <> 0) then
        Exts := string(AnsiString(GetExts(DC)));
      ALog(Format('  GL probe: WGL_NV_DX_interop2 %s, wglDXOpenDeviceNV %s', [
        BoolToStr(Pos('WGL_NV_DX_interop2', Exts) > 0, True),
        BoolToStr(wglGetProcAddress('wglDXOpenDeviceNV') <> nil, True)]));
      ReadFB := GLInteger(GL_READ_FRAMEBUFFER_BINDING);
      ALog(Format('  GL probe: draw framebuffer %d, read framebuffer %d, renderbuffer %d, ' +
        'texture 2D %d', [GLInteger(GL_DRAW_FRAMEBUFFER_BINDING), ReadFB,
        GLInteger(GL_RENDERBUFFER_BINDING), GLInteger(GL_TEXTURE_BINDING_2D)]));
      if ReadFB <> 0 then
      begin
        @GetAttach := wglGetProcAddress('glGetFramebufferAttachmentParameteriv');
        if Assigned(GetAttach) then
        begin
          ObjType := 0;
          ObjName := 0;
          GetAttach(GL_READ_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
            GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE, @ObjType);
          GetAttach(GL_READ_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
            GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME, @ObjName);
          case ObjType of
            GL_TEXTURE_OBJ:
              begin
                // Its size and format, with it bound for a moment
                W := 0;
                H := 0;
                Fmt := 0;
                Samples := 0;
                glBindTexture(GL_TEXTURE_2D, ObjName);
                glGetTexLevelParameteriv(GL_TEXTURE_2D, 0, GL_TEXTURE_WIDTH_Q, @W);
                glGetTexLevelParameteriv(GL_TEXTURE_2D, 0, GL_TEXTURE_HEIGHT_Q, @H);
                glGetTexLevelParameteriv(GL_TEXTURE_2D, 0, GL_TEXTURE_INTERNAL_FORMAT_Q, @Fmt);
                glGetTexLevelParameteriv(GL_TEXTURE_2D, 0, GL_TEXTURE_SAMPLES_Q, @Samples);
                glBindTexture(GL_TEXTURE_2D, 0);
                ALog(Format('  GL probe: colour attachment 0 is texture %d, %d x %d, ' +
                  'internal format $%x, samples %d (a 2D texture; 0 x 0 if it is not one)',
                  [ObjName, W, H, Fmt, Samples]));
              end;
            GL_RENDERBUFFER_OBJ:
              ALog(Format('  GL probe: colour attachment 0 is renderbuffer %d', [ObjName]));
          else
            ALog(Format('  GL probe: colour attachment 0: type $%x, name %d', [ObjType,
              ObjName]));
          end;
        end
        else
          ALog('  GL probe: no glGetFramebufferAttachmentParameteriv');
      end;
      ALog(Format('  GL probe: glGetError $%x', [glGetError]));
    end
    else
      ALog('  GL probe: no OpenGL context current here');
    ProbeFields(AViewport, 1, ALog);
  except
    on E: Exception do
      ALog(Format('GL probe (%s) failed: %s: %s', [AWhen, E.ClassName, E.Message]));
  end;
  {$ELSE}
  ALog('GL probe: Windows only');
  {$ENDIF}
end;

end.
