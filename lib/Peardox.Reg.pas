//** @abstract(Registers the Peardox components on the Peardox page of the IDE's palette.)
//**
//** Design-time only: it goes in the design package, never in a program. The palette icons
//** come from Peardox.Reg.dcr beside it, made from lib/icons by tools/gen_icon_res.py; never
//** edit the .dcr by hand.
//**
//** The components need FireMonkey and Gorilla3D, so they are grouped with TFmxObject and
//** show on the palette only while an FMX form or frame is being designed.
unit Peardox.Reg;

{
  Registers the Peardox components on the Peardox page of the IDE's palette.

  Design-time only: it goes in the design package, never in a program. The
  palette icons come from Peardox.Reg.dcr beside it, made from lib/icons by
  tools/gen_icon_res.py; never edit the .dcr by hand.

  The components need FireMonkey and Gorilla3D, so they are grouped with
  TFmxObject and show on the palette only while an FMX form or frame is
  being designed.
}

interface

//** @abstract(Called by the IDE when the design package is installed: puts every Peardox
//** component on the Peardox page.)
procedure Register;

implementation

{$R Peardox.Reg.dcr}

uses
  System.Classes, FMX.Types,
  Peardox.OrbitalCamera, Peardox.Projection;

const
  //** @abstract(The palette page, the component group, the components appear on.)
  PEARDOX_PALETTE_PAGE = 'Peardox';

procedure Register;
begin
  // FMX-only: hidden from the palette while a VCL form is designed
  GroupDescendentsWith(TPeardoxOrbitalCamera, TFmxObject);
  GroupDescendentsWith(TPeardoxProjection, TFmxObject);
  RegisterComponents(PEARDOX_PALETTE_PAGE, [TPeardoxOrbitalCamera, TPeardoxProjection]);
end;

end.
