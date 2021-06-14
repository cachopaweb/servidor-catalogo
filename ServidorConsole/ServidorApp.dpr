program ServidorApp;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  UnitConexao.Model.Interfaces,
  UnitFactory.Conexao.FireDAC,
  Data.DB,
  System.Json,
  Horse.Jhonson,
  Horse.Commons,
  Horse.CORS,
  Horse.Etag,
  Horse.Paginate,
  Horse,
  Horse.ServerStatic,
  Utils in '..\Utils.pas',
  UnitCatalogo.Controller in '..\Controllers\UnitCatalogo.Controller.pas',
  UnitLogin.Controller in '..\Controllers\UnitLogin.Controller.pas',
  UnitProdutos.Controller in '..\Controllers\UnitProdutos.Controller.pas',
  UnitContants in '..\UnitContants.pas',
  UnitPedidos.Controller in '..\Controllers\UnitPedidos.Controller.pas',
  UnitPedido.Model in '..\Models\UnitPedido.Model.pas';

begin
  THorse.Use(CORS)
        .Use(Jhonson)
        .Use(ETag)
        .Use(ServerStatic('Catalogo'));

  TProdutoController.Registrar;
  TCatalogoController.Registrar;
  TLoginController.Registrar;
  TPedidosController.Registrar;

  THorse.Listen(9002,
  procedure(App: THorse)
  begin
     Writeln('Servidor rodando na porta '+App.Port.ToString);
     Readln;
     App.StopListen;
  end);
end.
