program PorpsIndica;

uses
  System.StartUpCopy,
  FMX.Forms,
  PrincipalForm in 'PrincipalForm.pas' {PrincipalFrm},
  ConexaoData in 'ConexaoData.pas' {ConexaoDtm: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.FormFactor.Orientations := [TFormOrientation.Portrait];
  Application.CreateForm(TPrincipalFrm, PrincipalFrm);
  Application.CreateForm(TConexaoDtm, ConexaoDtm);
  Application.Run;
end.
