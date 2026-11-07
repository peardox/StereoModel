//** @abstract(Per-user storage for the Peardox components: where to keep files, and JSON
//** settings.)
//**
//** AppDataFolder gives the folder each platform expects an application to keep its own
//** files in, kept between sessions and private to the user. TPeardoxJsonSettings is a base
//** class for settings: a descendant declares its settings as published properties, and Load
//** and Save read and write them as a JSON file with the Neon library.
//**
//** Copied from Sprite3D's Sprite3DStorage (TSprite3DJsonSettings), without its OSPaths and
//** JsonText helpers. Neon is compiled into the PeardoxLeiaSR package, so a program using
//** this unit needs no path to it.
//**
//** @preformatted(
//** Windows   %APPDATA%\<AppName>
//** macOS     ~/Library/Application Support/<AppName>
//** Linux     $XDG_CONFIG_HOME/<AppName>, or ~/.config/<AppName>
//** Android   the app's private files folder
//** iOS       the app's Library/Application Support folder
//** )
unit Peardox.Storage;

{
  Per-user storage for the Peardox components: where to keep files, and
  JSON settings.

  AppDataFolder gives the folder each platform expects an application to
  keep its own files in, kept between sessions and private to the user.
  TPeardoxJsonSettings is a base class for settings: a descendant declares
  its settings as published properties, and Load and Save read and write
  them as a JSON file with the Neon library.

  Copied from Sprite3D's Sprite3DStorage (TSprite3DJsonSettings), without
  its OSPaths and JsonText helpers. Neon is compiled into the PeardoxLeiaSR
  package, so a program using this unit needs no path to it.

    Windows   %APPDATA%\<AppName>
    macOS     ~/Library/Application Support/<AppName>
    Linux     $XDG_CONFIG_HOME/<AppName>, or ~/.config/<AppName>
    Android   the app's private files folder
    iOS       the app's Library/Application Support folder
}

interface

uses
  System.SysUtils, System.Classes;

//** @abstract(The per-user folder an application should keep its own files in.)
//**
//** Chosen by platform, as in the unit description, and not created; TPeardoxJsonSettings.Save
//** creates it when it first writes there. On Android and iOS the folder already belongs to
//** the app, so AAppName is only added on the desktop platforms.
//**
//** @param(AAppName The folder's name on the desktop; a valid file name on every platform.)
//**
//** @returns(The folder's full path, without a trailing path delimiter.)
function AppDataFolder(const AAppName: string): string;

type
  //** @abstract(Base class for settings kept as a JSON file.)
  //**
  //** Declare each setting as a published property of a descendant, with its default set in
  //** the constructor; Load fills them from the file and Save writes them all back. The JSON
  //** member names are the property names in camel case, such as @code(eyeSeparationMM) for
  //** EyeSeparationMM. Only published properties are stored. Settings missing from the file
  //** keep their defaults and members no property matches are ignored, so an older or newer
  //** file still loads.
  //**
  //** Not thread-safe; use one object from one thread, normally the main thread.
  TPeardoxJsonSettings = class(TPersistent)
  private
    //** @abstract(See FileName.)
    FFileName: string;
    //** @abstract(See LastError.)
    FLastError: string;
  public
    //** @abstract(Creates the settings with their defaults, for the given file.)
    //**
    //** Nothing is read until Load, and neither the file nor its folder is made until Save.
    //**
    //** @param(AFileName The JSON file's full path.)
    constructor Create(const AFileName: string); virtual;
    //** @abstract(Reads the settings from FileName.)
    //**
    //** A missing file, normal on the first run, or one that cannot be read or parsed leaves
    //** the settings as they were and raises nothing; LastError says why, and a damaged file
    //** is replaced at the next Save.
    //**
    //** @returns(True if the file was read; False if it was missing or unusable.)
    function Load: Boolean;
    //** @abstract(Writes every setting to FileName, making its folder if needed.)
    //**
    //** The JSON goes to a temporary file beside FileName, which then replaces it, so a failure
    //** part-way leaves the previous file whole.
    //**
    //** @raises(Exception If the folder or the file cannot be written; the class depends on
    //** the cause.)
    procedure Save;
    //** @abstract(The JSON file's full path, as given to Create.)
    property FileName: string read FFileName;
    //** @abstract(Why the last Load returned False: "no file yet", or the error; empty after a
    //** Load that worked.)
    property LastError: string read FLastError;
  end;

implementation

uses
  System.IOUtils, System.TypInfo,
  Neon.Core.Persistence, Neon.Core.Persistence.JSON;

function AppDataFolder(const AAppName: string): string;
{$IF DEFINED(LINUX)}
var
  ConfigHome: string;
{$ENDIF}
begin
  {$IF DEFINED(MSWINDOWS)}
  // TPath.GetHomePath is %APPDATA% on Windows
  Result := TPath.Combine(TPath.GetHomePath, AAppName);
  {$ELSEIF DEFINED(IOS)}
  // The app's own sandbox: Library/Application Support
  Result := TPath.Combine(TPath.GetLibraryPath, 'Application Support');
  {$ELSEIF DEFINED(MACOS)}
  Result := TPath.Combine(TPath.Combine(TPath.Combine(TPath.GetHomePath,
    'Library'), 'Application Support'), AAppName);
  {$ELSEIF DEFINED(ANDROID)}
  // The app's private files folder
  Result := TPath.GetDocumentsPath;
  {$ELSE}
  // Linux: the XDG base directory rules
  ConfigHome := GetEnvironmentVariable('XDG_CONFIG_HOME');
  if ConfigHome = '' then
    ConfigHome := TPath.Combine(TPath.GetHomePath, '.config');
  Result := TPath.Combine(ConfigHome, AAppName);
  {$ENDIF}
  Result := ExcludeTrailingPathDelimiter(Result);
end;

//** @abstract(The Neon configuration for both reading and writing, so the two always agree.)
//**
//** @returns(Camel-case names, published properties only, laid out for people to read.)
function JsonConfig: INeonConfiguration;
begin
  Result := TNeonConfiguration.Camel
    .SetVisibility([mvPublished])
    .SetPrettyPrint(True);
end;

{ TPeardoxJsonSettings }

constructor TPeardoxJsonSettings.Create(const AFileName: string);
begin
  inherited Create;
  FFileName := AFileName;
end;

function TPeardoxJsonSettings.Load: Boolean;
var
  Json: string;
begin
  Result := False;
  if not TFile.Exists(FFileName) then
  begin
    FLastError := 'no file yet';
    Exit;
  end;
  try
    Json := TFile.ReadAllText(FFileName, TEncoding.UTF8);
    TNeon.JSONToObject(Self, Json, JsonConfig);
    FLastError := '';
    Result := True;
  except
    // Unreadable or damaged: keep the current values; Save replaces it
    on E: Exception do
      FLastError := E.ClassName + ': ' + E.Message;
  end;
end;

procedure TPeardoxJsonSettings.Save;
var
  Json, TempName: string;
begin
  ForceDirectories(ExtractFileDir(FFileName));
  Json := TNeon.ObjectToJSONString(Self, JsonConfig);
  TempName := FFileName + '.tmp';
  // UTF-8 without a byte order mark, as JSON files normally are
  TFile.WriteAllBytes(TempName, TEncoding.UTF8.GetBytes(Json));
  if TFile.Exists(FFileName) then
    TFile.Delete(FFileName);
  TFile.Move(TempName, FFileName);
end;

end.
