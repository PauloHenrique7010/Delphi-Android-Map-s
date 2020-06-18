unit PrincipalForm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.WebBrowser, FMX.StdCtrls, FMX.Controls.Presentation, FMX.Objects,
  System.Permissions, System.Sensors, System.Sensors.Components, FMX.Edit,
  FMX.Maps, REST.Types, Data.Bind.Components, Data.Bind.ObjectScope, REST.Client,
  FMX.ListView.Types, FMX.ListView.Appearances, FMX.ListView.Adapters.Base,
  FMX.ListView, FMX.ListBox;

type
  TPrincipalFrm = class(TForm)
    MapView1: TMapView;
    edtEndereco: TEdit;
    Panel1: TPanel;
    Label1: TLabel;
    Switch1: TSwitch;
    LocationSensor1: TLocationSensor;
    Panel2: TPanel;
    lblLatitude: TLabel;
    Layout1: TLayout;
    RESTClient1: TRESTClient;
    RESTRequest1: TRESTRequest;
    RESTResponse1: TRESTResponse;
    Button1: TButton;
    pnlCombo: TPanel;
    cmbLista: TComboBox;
    imgPosAtual: TImage;
    procedure LocationSensor1LocationChanged(Sender: TObject; const OldLocation,
      NewLocation: TLocationCoord2D);
    procedure FormCreate(Sender: TObject);
    procedure Panel2Click(Sender: TObject);
    procedure edtEnderecoChange(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure cmbListaChange(Sender: TObject);
    procedure Switch1Click(Sender: TObject);
    procedure MapView1MarkerClick(Marker: TMapMarker);
    procedure MapView1MarkerDoubleClick(Marker: TMapMarker);
  private
    { Private declarations }
    Location: TLocationCoord2D;
    FGeocoder: TGeocoder;
    lLatitude,lLongitude : TStringlist;

    {$IFDEF ANDROID}
     Access_Fine_Location, Access_Coarse_Location : string;
     procedure DisplayRationale(Sender: TObject;
              const APermissions: TArray<string>; const APostRationaleProc: TProc);
     procedure LocationPermissionRequestResult
                (Sender: TObject; const APermissions: TArray<string>;
                const AGrantResults: TArray<TPermissionStatus>);
    {$ENDIF}

    procedure OnGeocodeReverseEvent(const Address: TCivicAddress);

  public
    { Public declarations }
  end;

var
  PrincipalFrm: TPrincipalFrm;

implementation

{$R *.fmx}
uses FMX.DialogService, System.JSON

{$IFDEF ANDROID}
,Androidapi.Helpers, Androidapi.JNI.JavaTypes, Androidapi.JNI.Os
{$ENDIF}

;


procedure TPrincipalFrm.Button1Click(Sender: TObject);
var
  LJsonArr   : TJSONArray;
  i: integer;
  ObjetoJsonLinha      : TJSONObject;
  vagabunda : string;

  jsonObj : TJSONObject;

  sLatitude, sLongitude : string;
  building, rua, bairro, cidade, estado, cep, pais : string;

  string1 : string;
begin
  MapView1.Repaint;


  cmbLista.Clear;
  lLatitude.Clear;
  lLongitude.Clear;


  RESTRequest1.Resource := 'search?q={pesquisa}&format=json&polygon_geojson=0&addressdetails=1';
  RESTRequest1.Params.AddUrlSegment('pesquisa',edtEndereco.Text);
  RESTRequest1.Execute;

  LJsonArr    := TJSONObject.ParseJSONValue(TEncoding.ASCII.GetBytes(RESTRequest1.Response.JSONText),0) as TJSONArray;
  if (LJsonArr.Count > 0) then
  begin
    pnlCombo.Visible := true;

    for I:=0 to LJsonArr.Count  - 1 do
    begin
      ObjetoJsonLinha := LJsonArr.Items[i] as TJSONObject;

      sLatitude := objetojsonlinha.GetValue('lat').value;
      sLongitude := objetojsonlinha.GetValue('lon').value;

      lLatitude.Add(sLatitude);
      lLongitude.Add(sLongitude);

      vagabunda := ObjetoJsonLinha.GetValue('address').ToJSON;


      jsonObj    := TJSONObject.ParseJSONValue(TEncoding.ASCII.GetBytes(vagabunda),0) as TJSONObject;

      building := '';
      if (jsonObj.FindValue('building') <> nil) then
        building  := jsonObj.GetValue('building').ToJSON;

      rua := '';
      if (jsonObj.FindValue('road') <> nil) then
        rua       := jsonObj.GetValue('road').ToJSON;

      bairro := '';
      if (jsonObj.FindValue('suburb') <> nil) then
        bairro    := jsonObj.GetValue('suburb').ToJSON;

      cidade := '';
      if (jsonObj.FindValue('city') <> nil) then
        cidade    := jsonObj.GetValue('city').ToJSON;

      string1 := rua+', '+bairro+', '+cidade;
      string1 := StringReplace(string1,'"','',[rfReplaceAll]);
      cmbLista.Items.Add(string1);
    end;
  end;
end;

procedure TPrincipalFrm.cmbListaChange(Sender: TObject);
var
  marcador : TMapMarkerDescriptor;
  posicao : TMapCoordinate;
  Lat, Long : double;
begin
  //ShowMessage('Você escolheu: '+cmbLista.Items[cmbLista.ItemIndex]);
  //ShowMessage('Lat: '+lLatitude.Strings[cmbLista.ItemIndex]+#13+'Lon: '+lLongitude.Strings[cmbLista.ItemIndex]);
  pnlCombo.Visible := False;


  lat := StrToFloat(StringReplace(lLatitude.Strings[cmbLista.ItemIndex],'.',',',[rfReplaceAll]));
  long := StrToFloat(StringReplace(lLongitude.Strings[cmbLista.ItemIndex],'.',',',[rfReplaceAll]));


  posicao.Latitude := lat;
  posicao.Longitude := Long;

  marcador := TMapMarkerDescriptor.Create(posicao);
  marcador.Snippet := ',teste2';

  marcador.Draggable := false;
  marcador.Title := 'Titulo';
  marcador.Visible := true;
  MapView1.AddMarker(marcador);

  
  MapView1.Location := posicao;


end;

procedure TPrincipalFrm.DisplayRationale(Sender: TObject;
  const APermissions: TArray<string>; const APostRationaleProc: TProc);
var
  I: Integer;
  RationaleMsg: string;
begin
  for I := 0 to High(APermissions) do
  begin
    if (APermissions[I] = Access_Coarse_Location) or (APermissions[I] = Access_Fine_Location) then
      RationaleMsg := 'O app precisa de acesso ao GPS para obter sua localização'
  end;

  TDialogService.ShowMessage(RationaleMsg,
    procedure(const AResult: TModalResult)
    begin
      APostRationaleProc;
    end)
end;

procedure TPrincipalFrm.edtEnderecoChange(Sender: TObject);
begin
  ShowMessage('Change: '+edtEndereco.Text);
end;

procedure TPrincipalFrm.FormCreate(Sender: TObject);
begin
  lLatitude := TStringList.Create;
  lLongitude := TStringList.Create;
  pnlCombo.Visible := false;
        {$IFDEF ANDROID}
        Access_Coarse_Location := JStringToString(TJManifest_permission.JavaClass.ACCESS_COARSE_LOCATION);
        Access_Fine_Location := JStringToString(TJManifest_permission.JavaClass.ACCESS_FINE_LOCATION);
        {$ENDIF}
end;

procedure TPrincipalFrm.LocationPermissionRequestResult(Sender: TObject;
  const APermissions: TArray<string>;
  const AGrantResults: TArray<TPermissionStatus>);
var
         x : integer;
begin
  if (Length(AGrantResults) = 2) and
    (AGrantResults[0] = TPermissionStatus.Granted) and
    (AGrantResults[1] = TPermissionStatus.Granted) then
    PrincipalFrm.LocationSensor1.Active := true
  else
  begin
    Switch1.IsChecked := false;
    TDialogService.ShowMessage
      ('Não é possível acessar o GPS porque o app não possui acesso')
  end;

end;

procedure TPrincipalFrm.LocationSensor1LocationChanged(Sender: TObject;
  const OldLocation, NewLocation: TLocationCoord2D);
var
  lt, lg, url : string;
  marcador : TMapMarkerDescriptor;
  posicao : TMapCoordinate;
begin
  Location := NewLocation;
  lt := StringReplace(Format('%2.6f', [NewLocation.Latitude]), ',', '.', [rfReplaceAll]);
  lg := StringReplace(Format('%2.6f', [NewLocation.Longitude]), ',', '.', [rfReplaceAll]);
  posicao.Latitude := NewLocation.Latitude;//-23.548094;
  posicao.Longitude := NewLocation.Longitude;//-46.635063;
  MapView1.Location := posicao;
  MapView1.Zoom := 16;

  LocationSensor1.Active := false;
  Switch1.IsChecked := false;


  url := 'https://maps.google.com/maps?q=' + lt + ',' + lg;


  marcador := TMapMarkerDescriptor.Create(posicao);

  marcador.Draggable := false;
  marcador.Title := 'Você está aqui';
  marcador.Icon := imgPosAtual.Bitmap;
  marcador.Visible := true;
  MapView1.AddMarker(marcador);


//        WebBrowser.Navigate(url);
end;

procedure TPrincipalFrm.MapView1MarkerClick(Marker: TMapMarker);
begin
  ShowMessage(FloatToStr(Marker.Descriptor.Position.Latitude));
  showMessage(Marker.Descriptor.Position.ToString);
end;

procedure TPrincipalFrm.MapView1MarkerDoubleClick(Marker: TMapMarker);
begin
    Marker.Remove;
end;

procedure TPrincipalFrm.OnGeocodeReverseEvent(const Address: TCivicAddress);
var
        msg : string;
begin
        msg :=  Address.AdminArea + ', ' +
                Address.CountryCode + ', ' +
                Address.CountryName + ', ' +
                Address.FeatureName + ', ' +
                Address.Locality + ', ' +
                Address.PostalCode + ', ' +
                Address.SubAdminArea + ', ' +
                Address.SubLocality + ', ' +
                Address.SubThoroughfare + ', ' +
                Address.Thoroughfare;


        TDialogService.ShowMessage(msg);
end;

procedure TPrincipalFrm.Panel2Click(Sender: TObject);
begin
try
                // Tratando a instancia TGeocoder...
                if not Assigned(FGeocoder) then
                begin
                        if Assigned(TGeocoder.Current) then
                                FGeocoder := TGeocoder.Current.Create;

                        if Assigned(FGeocoder) then
                                FGeocoder.OnGeocodeReverse := OnGeocodeReverseEvent;
                end;

                // Tratar a traducao do endereco...
                if Assigned(FGeocoder) and not FGeocoder.Geocoding then
                        FGeocoder.GeocodeReverse(Location);
        except
                showmessage('Erro no serviço Geocoder');
        end;
end;

procedure TPrincipalFrm.Switch1Click(Sender: TObject);
begin
   if Switch1.IsChecked then
        begin
                {$IFDEF ANDROID}
                PermissionsService.RequestPermissions([Access_Coarse_Location,
                                                       Access_Fine_Location],
                                                       LocationPermissionRequestResult,
                                                       DisplayRationale);
                {$ENDIF}

                {$IFDEF IOS}
                LocationSensor.Active := true;
                {$ENDIF}
        end;
end;

end.
