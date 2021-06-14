unit UnitPedidos.Controller;

interface
uses
  Horse,
  Horse.Commons,
  Classes,
  SysUtils,
  System.Json,
  DB,
  UnitConexao.Model.Interfaces,
  UnitConexao.FireDAC.Model,
  UnitQuery.FireDAC.Model,
  UnitFactory.Conexao.FireDAC;


type
  TPedidosController = class
    class procedure Registrar;
    class procedure Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
  end;

implementation

{ TControllerPedidos }

uses UnitPedido.Model;

class procedure TPedidosController.Get(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var oJson: TJSONObject;
  Codigo: Integer;
  Pedido: TPedido;
begin
  Pedido := TPedido.Create;
  try
    try
      Codigo := Req.Params['codigo'].ToInteger();
      Pedido := TPedido.Buscar(Codigo);
      if Pedido.Codigo = 0 then
        raise Exception.Create('Pedido não encontrado');
      oJson := TJSONObject.ParseJSONValue(Pedido.ToJson) as TJSONObject;
      Res.Send<TJSONObject>(oJson).Status(THTTPStatus.OK);
    except on E: Exception do
      Res.Send<TJSONObject>(TJSONObject.Create.AddPair('message', E.Message)).Status(THTTPStatus.BadRequest);
    end;
  finally
    Pedido.Free;
  end;
end;

class procedure TPedidosController.Post(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  Pedido: TPedido;
begin
  try
    Pedido := TPedido.FromJsonString(Req.Body<TJSONObject>.ToString);
    Pedido.Inserir;
    Res.Send<TJSONObject>(TJSONObject.Create.AddPair('pedido', TJSONNumber.Create(Pedido.Codigo)));
  except on E: Exception do
    res.Send<TJSONObject>(TJSONObject.Create.AddPair('message', E.Message))
  end;
end;

class procedure TPedidosController.Registrar;
begin
  THorse.Get('/Pedidos/:codigo', Get);
  THorse.Post('/Pedidos', Post);
end;

end.
