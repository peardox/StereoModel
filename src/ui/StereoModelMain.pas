unit StereoModelMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  Gorilla.Viewport, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Menus,
  FMX.Layouts;

type
  TForm2 = class(TForm)
    MainViewLayout: TLayout;
    ControlLayout: TLayout;
    MainMenu1: TMainMenu;
    btnStereo: TButton;
    ViewLayout: TLayout;
    GorillaViewport1: TGorillaViewport;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

implementation

{$R *.fmx}

end.
