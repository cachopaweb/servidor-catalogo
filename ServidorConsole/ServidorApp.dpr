program ServidorApp;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Data.DB,
  System.Json,
  Horse.Jhonson,
  Horse.Commons,
  Horse.CORS,
  Horse.Etag,
  Horse.Paginate,
  Horse,
  Horse.ServerStatic,
  Horse.BasicAuthentication,
  Horse.Logger,
  Horse.Logger.Provider.Console,
  Utils in '..\Utils.pas',
  UnitConstants in '..\UnitConstants.pas',
  UnitPedido.Model in '..\Models\UnitPedido.Model.pas',
  UnitCatalogo.Controller in '..\Controllers\UnitCatalogo.Controller.pas',
  UnitCidades.Controller in '..\Controllers\UnitCidades.Controller.pas',
  UnitClientes.Controller in '..\Controllers\UnitClientes.Controller.pas',
  UnitLogin.Controller in '..\Controllers\UnitLogin.Controller.pas',
  UnitPedidos.Controller in '..\Controllers\UnitPedidos.Controller.pas',
  UnitProdutos.Controller in '..\Controllers\UnitProdutos.Controller.pas',
  UnitUsuarios.Controller in '..\Controllers\UnitUsuarios.Controller.pas',
  UnitDatabase in '..\Database\UnitDatabase.pas';

var
	LLogFileConfig: THorseLoggerConsoleConfig;
  Porta: integer;
begin
	// ReportMemoryLeaksOnShutdown := True;
	LLogFileConfig := THorseLoggerConsoleConfig.New.SetLogFormat('${request_clientip} [${time}] ${response_status}');
	try
		THorseLoggerManager.RegisterProvider(THorseLoggerProviderConsole.New());

    THorse.Use(CORS)
          .Use(Jhonson)
          .Use(ETag)
          .Use(THorseLoggerManager.HorseCallback)
          .Use(ServerStatic('Catalogo'));

    TProdutoController.Registrar;
    TCatalogoController.Registrar;
    TLoginController.Registrar;
    TPedidosController.Registrar;
    TUsuariosController.Registrar; 
    TClientesController.Registrar;
    TCidadesController.Registrar;

    if GetEnvironmentVariable('PORT').IsEmpty then
      Porta := 9002
    else	
      Porta := GetEnvironmentVariable('PORT').ToInteger;
    THorse.Listen(Porta,
    procedure
    begin
       Writeln('Servidor rodando na porta '+THorse.Port.ToString);     
    end);
  finally
		LLogFileConfig.Free;
	end;
end.
