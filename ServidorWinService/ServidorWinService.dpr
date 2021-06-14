program ServidorWinService;

uses
  Vcl.SvcMgr,
  UnitPrincipal in 'UnitPrincipal.pas' {ServicePalazzi: TService},
  UnitProdutos.Controller in '..\Controllers\UnitProdutos.Controller.pas',
  Utils in '..\Utils.pas',
  UnitCatalogo.Controller in '..\Controllers\UnitCatalogo.Controller.pas',
  UnitContants in '..\UnitContants.pas',
  UnitLogin.Controller in '..\Controllers\UnitLogin.Controller.pas',
  UnitPedido.Model in '..\Models\UnitPedido.Model.pas',
  UnitPedidos.Controller in '..\Controllers\UnitPedidos.Controller.pas';

{$R *.RES}

begin
  // Windows 2003 Server requires StartServiceCtrlDispatcher to be
  // called before CoRegisterClassObject, which can be called indirectly
  // by Application.Initialize. TServiceApplication.DelayInitialize allows
  // Application.Initialize to be called from TService.Main (after
  // StartServiceCtrlDispatcher has been called).
  //
  // Delayed initialization of the Application object may affect
  // events which then occur prior to initialization, such as
  // TService.OnCreate. It is only recommended if the ServiceApplication
  // registers a class object with OLE and is intended for use with
  // Windows 2003 Server.
  //
  // Application.DelayInitialize := True;
  //
  if not Application.DelayInitialize or Application.Installing then
    Application.Initialize;
  Application.CreateForm(TServicePalazzi, ServicePalazzi);
  Application.Run;
end.
