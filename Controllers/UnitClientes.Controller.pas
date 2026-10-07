unit UnitClientes.Controller;

interface
uses
  Horse,
  Horse.Commons,
  Classes,
  SysUtils,
  System.Json,
  DB,
  UnitConnection.Model.Interfaces;


type
  TClientesController = class
    class procedure Registrar;
    class procedure GetClientePorCodigo(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure GetClientes(Req: THorseRequest; Res: THorseResponse; Next: TProc);
  end;

implementation

{ TClientesController }

uses UnitConstants, UnitDatabase;

class procedure TClientesController.GetClientePorCodigo(Req: THorseRequest;
  Res: THorseResponse; Next: TProc);
var
  Codigo: Integer;
  Query: iQuery;
  oJson: TJSONObject;
begin
  if not Req.Params.ContainsKey('id') then
    Res.Send<TJSONObject>(TJSONObject.Create.AddPair('message', 'Codigo do cliente não informado')).Status(THTTPStatus.BadRequest);
  Codigo := Req.Params.Items['id'].ToInteger;
  try
    Query := TDatabase.Query;
    Query.Add('SELECT CLI_CODIGO, CLI_NOME NOME, CLI_CPF_CGC FROM CLIENTES WHERE CLI_CODIGO = :CODIGO');
    Query.AddParam('CODIGO', Codigo);
    Query.Open;
    if not Query.DataSet.IsEmpty then
    begin
      oJson := TJSONObject.Create;
      oJson.AddPair('codigo', TJSONNumber.Create(Query.DataSet.FieldByName('CLI_CODIGO').AsInteger));
      oJson.AddPair('nome', Query.DataSet.FieldByName('NOME').AsString);
      oJson.AddPair('cnpj_cpf', Query.DataSet.FieldByName('CLI_CPF_CGC').AsString);
      Res.Send<TJSONObject>(oJson).Status(THTTPStatus.OK);
    end else
      Res.Send<TJSONObject>(TJSONObject.Create.AddPair('message', 'Cliente não encontrado')).Status(THTTPStatus.NotFound);
  except on E: Exception do
    Res.Send<TJSONObject>(TJSONObject.Create.AddPair('message', 'Erro ao buscar cliente.'+sLineBreak+E.Message)).Status(THTTPStatus.BadRequest);
  end;
end;

class procedure TClientesController.GetClientes(Req: THorseRequest;
  Res: THorseResponse; Next: TProc);
var
  Query: iQuery;
  oJson: TJSONObject;
  aJson: TJSONArray;
  Cidade: string;
begin
	if Req.Query.ContainsKey('cidade') then
  	Cidade := Req.Query.Items['cidade'].ToUpper;  	
  try
    Query := TDatabase.Query;
    Query.Add('SELECT CLI_CODIGO, CLI_NOME NOME, CLI_CPF_CGC, CLI_CIDADE FROM CLIENTES ');
    Query.Add('WHERE CLI_SITUACAO = ''ATIVO'' ');
    if not Cidade.IsEmpty then
    begin
    	Query.Add('AND CLI_CIDADE LIKE :CIDADE');
      Query.AddParam('CIDADE', '%'+Cidade+'%');
    end;
    Query.Add('ORDER BY CLI_NOME');
    Query.Open;
    if not Query.DataSet.IsEmpty then
    begin
      aJson := TJSONArray.Create;
      Query.DataSet.First;
      while not Query.DataSet.Eof do
      begin
        oJson := TJSONObject.Create;
        oJson.AddPair('codigo', TJSONNumber.Create(Query.DataSet.FieldByName('CLI_CODIGO').AsInteger));
        oJson.AddPair('nome', Query.DataSet.FieldByName('NOME').AsString);
        oJson.AddPair('cnpj_cpf', Query.DataSet.FieldByName('CLI_CPF_CGC').AsString);
        oJson.AddPair('cidade', Query.DataSet.FieldByName('CLI_CIDADE').AsString);
        aJson.AddElement(oJson);
        Query.DataSet.Next;
      end;
      Res.Send<TJSONArray>(aJson).Status(THTTPStatus.OK);
    end else
      Res.Send<TJSONObject>(TJSONObject.Create.AddPair('message', 'Clientes não encontrados')).Status(THTTPStatus.NotFound);
  except on E: Exception do
    Res.Send<TJSONObject>(TJSONObject.Create.AddPair('message', 'Erro ao buscar clientes.'+sLineBreak+E.Message)).Status(THTTPStatus.BadRequest);
  end;
end;

class procedure TClientesController.Registrar;
begin
  THorse.Get('/clientes', GetClientes);
  THorse.Get('/clientes/:id', GetClientePorCodigo);
  //versionamento
  THorse.Group
  			.Prefix('v1')
        	.Route('/clientes')
          	.Get(GetClientes)
          .&End
        .Group
  			.Prefix('v1')
          .Route('/clientes/:id')
          	.Get(GetClientePorCodigo)
          .&End;
          
end;

end.
