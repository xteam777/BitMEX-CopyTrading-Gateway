program MCGateway;

uses
  FastMM4,
  Vcl.Forms,
  uMain in 'uMain.pas' {fGateway};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfGateway, fGateway);
  Application.Run;
end.
