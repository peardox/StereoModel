//** @abstract(StereoModel: shows a 3D model on a glasses-free stereo display.)
//**
//** The model is shown in a Gorilla3D viewport through TPeardoxOrbitalCamera, the Peardox
//** orbital camera component. TForm2, in StereoModelMain, holds the view. Leaks still
//** allocated at shut-down are reported, as ReportMemoryLeaksOnShutdown is set in Debug
//** builds. On Windows FastMM5 is the memory manager and also writes them, in full, to
//** StereoModel_MemoryManager_EventLog.txt beside the executable.
//**
//** @preformatted(
//** src/ui/  the forms
//** lib/     the Peardox components, shared with other projects
//** )
program StereoModel;

{
  StereoModel: shows a 3D model on a glasses-free stereo display.

  The model is shown in a Gorilla3D viewport through TPeardoxOrbitalCamera,
  the Peardox orbital camera component. TForm2, in StereoModelMain, holds
  the view. Leaks still allocated at shut-down are reported, as
  ReportMemoryLeaksOnShutdown is set in Debug builds. On Windows FastMM5 is
  the memory manager and also writes them, in full, to
  StereoModel_MemoryManager_EventLog.txt beside the executable.

    src/ui/  the forms
    lib/     the Peardox components, shared with other projects
}

uses
  // On Windows FastMM5 is the memory manager, so it must come first; it
  // writes the full leak report to a file beside the executable
  {$IFDEF MSWINDOWS}
  FastMM5,
  {$ENDIF}
  System.StartUpCopy,
  FMX.Forms,
  Peardox.OrbitalCamera in '..\lib\Peardox.OrbitalCamera.pas',
  StereoModelMain in 'ui\StereoModelMain.pas' {Form2};

{$R *.res}

begin
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
  {$IFDEF MSWINDOWS}
  // FastMM5 also writes every leak, in full, to
  // StereoModel_MemoryManager_EventLog.txt in the executable's folder, its
  // default place. It adds to that file each run, so the last run's is
  // deleted first, leaving this run's alone in it
  FastMM_DeleteEventLogFile;
  FastMM_LogToFileEvents := FastMM_LogToFileEvents +
    [mmetUnexpectedMemoryLeakSummary, mmetUnexpectedMemoryLeakDetail];
  {$ENDIF}
  {$ENDIF}
  Application.Initialize;
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.
