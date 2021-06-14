unit UnitPrincipal;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.SvcMgr,
  Vcl.Dialogs,
  Data.DB,
  System.Json,
  Horse.Jhonson,
  Horse.Commons,
  Horse.CORS,
  Horse.Paginate,
  Horse.Etag,
  Horse,
  Horse.HandleException,
  Horse.ServerStatic;

type
  TServicePalazzi = class(TService)
    procedure ServiceStart(Sender: TService; var Started: Boolean);
    procedure ServiceStop(Sender: TService; var Stopped: Boolean);
    procedure ServiceCreate(Sender: TObject);
  private
    { Private declarations }
  public
    function GetServiceController: TServiceController; override;
    { Public declarations }
  end;

var
  ServicePalazzi: TServicePalazzi;

implementation

{$R *.dfm}

uses UnitProdutos.Controller,
     UnitCatalogo.Controller,
     UnitLogin.Controller,
     UnitPedidos.Controller;

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  ServicePalazzi.Controller(CtrlCode);
end;

function TServicePalazzi.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure TServicePalazzi.ServiceCreate(Sender: TObject);
begin
  THorse
        .Use(CORS)
        .Use(Jhonson)
        .Use(ETag)
        .Use(HandleException)
        .Use(ServerStatic(ExtractFilePath(ParamStr(0))+'\Catalogo'));

  TProdutoController.Registrar;
  TCatalogoController.Registrar;
  TLoginController.Registrar;
  TPedidosController.Registrar;
end;

procedure TServicePalazzi.ServiceStart(Sender: TService; var Started: Boolean);
begin
  THorse.Listen(9002);
  Started := true;
end;

procedure TServicePalazzi.ServiceStop(Sender: TService; var Stopped: Boolean);
begin
  THorse.StopListen;
  Stopped := true;
end;

end.
