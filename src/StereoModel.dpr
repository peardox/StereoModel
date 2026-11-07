//** @abstract(StereoModel: shows a 3D model on a glasses-free stereo display.)
//**
//** The model is shown in a Gorilla3D viewport through TPeardoxOrbitalCamera, the Peardox
//** orbital camera component. TForm2, in StereoModelMain, holds the view.
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
  the view.

    src/ui/  the forms
    lib/     the Peardox components, shared with other projects
}

uses
  System.StartUpCopy,
  FMX.Forms,
  Peardox.OrbitalCamera in '..\lib\Peardox.OrbitalCamera.pas',
  StereoModelMain in 'ui\StereoModelMain.pas' {Form2};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.
