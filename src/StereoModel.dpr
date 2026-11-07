//** @abstract(StereoModel: shows a 3D model on a glasses-free stereo display.)
//**
//** The model is shown in a Gorilla3D viewport through TPeardoxOrbitalCamera, the Peardox
//** orbital camera component, which comes from the Peardox runtime package's DCUs in Delphi's
//** Dcp folder, so the program lists no lib unit and needs no path to it; TPeardoxLeiaSR
//** (glasses-free 3D) comes the same way from PeardoxLeiaSR's. TForm2, in
//** StereoModelMain, holds the view. Leaks still
//** allocated at shut-down are reported, as ReportMemoryLeaksOnShutdown is set in Debug
//** builds. On Windows FastMM5 is the memory manager and also writes them, in full, to
//** StereoModel_MemoryManager_EventLog.txt beside the executable.
//**
//** @preformatted(
//** src/ui/      the forms
//** src/common/  helpers: FmxLinuxMenu (from TSteamAPI, shared), StereoModelLog (the log file),
//**              StereoModelEyes (first light: the two eyes drawn for LeiaSR)
//** lib/         the Peardox components' sources, built by packages/Peardox.dpk and
//**              packages/PeardoxLeiaSR.dpk (LeiaSR, glasses-free 3D)
//** )
program StereoModel;

{
  StereoModel: shows a 3D model on a glasses-free stereo display.

  The model is shown in a Gorilla3D viewport through TPeardoxOrbitalCamera,
  the Peardox orbital camera component, which comes from the Peardox
  runtime package's DCUs in Delphi's Dcp folder, so the program lists no
  lib unit and needs no path to it. TForm2, in StereoModelMain, holds the
  view. Leaks still allocated at shut-down are reported, as
  ReportMemoryLeaksOnShutdown is set in Debug builds. On Windows FastMM5 is
  the memory manager and also writes them, in full, to
  StereoModel_MemoryManager_EventLog.txt beside the executable.

    src/ui/      the forms
    src/common/  helpers: FmxLinuxMenu (from TSteamAPI, shared), StereoModelLog (the log file),
                 StereoModelEyes (first light: the two eyes drawn for LeiaSR)
    lib/         the Peardox components' sources, built by packages/Peardox.dpk and
                 packages/PeardoxLeiaSR.dpk (LeiaSR, glasses-free 3D)
}

uses
  // On Windows FastMM5 is the memory manager, so it must come first; it
  // writes the full leak report to a file beside the executable
  {$IFDEF MSWINDOWS}
  FastMM5,
  {$ENDIF}
  System.StartUpCopy,
  FMX.Forms,
  FmxLinuxMenu in 'common\FmxLinuxMenu.pas',
  StereoModelLog in 'common\StereoModelLog.pas',
  StereoModelGLProbe in 'common\StereoModelGLProbe.pas',
  StereoModelGLInterop in 'common\StereoModelGLInterop.pas',
  StereoModelEyes in 'common\StereoModelEyes.pas',
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
