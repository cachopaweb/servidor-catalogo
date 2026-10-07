unit UnitUsuarios.Controller;

interface
uses
  Horse,
  Horse.Commons,
  Classes,
  SysUtils,
  System.StrUtils,
  System.Json,
  DB,
  UnitConnection.Model.Interfaces;


type
  TUsuariosController = class
    class procedure Registrar;
    class procedure GetUsers(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure CreateUsers(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure DeleteUser(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure UpdateUser(Req: THorseRequest; Res: THorseResponse; Next: TProc);
  end;

implementation

{ TUsuariosController }

uses UnitConstants, UnitDatabase;

class procedure TUsuariosController.DeleteUser(Req: THorseRequest;
  Res: THorseResponse; Next: TProc);
var
  Codigo: Integer;
  Query: iQuery;
begin
  if Req.Params.ContainsKey('id') then
    Res.Send<TJSONObject>(TJSONObject.Create.AddPair('message', 'Código do usuário não informado')).Status(THTTPStatus.BadRequest);
  try
    Codigo := Req.Params.Items['id'].ToInteger;
    Query := TDatabase.Query;
    Query.Add('DELETE FROM USUARIOS_APP WHERE USU_CODIGO = :CODIGO');
    Query.AddParam('CODIGO', Codigo);
    Query.ExecSQL;
    Res.Send<TJSONObject>(TJSONObject.Create.AddPair('message', 'usuario excluido com sucesso')).Status(THTTPStatus.OK);
  except on E: Exception do
    Res.Send<TJSONObject>(TJSONObject.Create.AddPair('message', 'falha ao excluir usuario'+sLineBreak+E.Message)).Status(THTTPStatus.BadRequest)
  end;
end;

class procedure TUsuariosController.GetUsers(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  Query: iQuery;
  aJson: TJSONArray;
  oJson: TJSONObject;
begin
  Query := TDatabase.Query;
  Query.Add('SELECT USU_CODIGO, USU_CLI, USU_NOME, USU_MOSTRAR_PRECOS, USU_CELULAR, USU_SENHA, CLI_FANTASIA, CLI_CIDADE, CLI_UF');
  Query.Add('FROM USUARIOS_APP JOIN CLIENTES ON USU_CLI = CLI_CODIGO');
  Query.Add('ORDER BY CLI_UF, CLI_CIDADE, CLI_FANTASIA');
  Query.Open();
  if not Query.DataSet.IsEmpty then
  begin
    aJson := TJSONArray.Create;
    Query.DataSet.First;
    while not Query.DataSet.Eof do
    begin
      oJson := TJSONObject.Create;
      oJson.AddPair('codigo', TJSONNumber.Create(Query.DataSet.FieldByName('USU_CODIGO').AsInteger));
      oJson.AddPair('cli', TJSONNumber.Create(Query.DataSet.FieldByName('USU_CLI').AsInteger));
      oJson.AddPair('nome', Query.DataSet.FieldByName('USU_NOME').AsString);
      oJson.AddPair('mostrar_precos', TJSONBool.Create(Query.DataSet.FieldByName('USU_MOSTRAR_PRECOS').AsString = 'S'));
      oJson.AddPair('celular', Query.DataSet.FieldByName('USU_CELULAR').AsString);
      oJson.AddPair('senha', Query.DataSet.FieldByName('USU_SENHA').AsString);
      oJson.AddPair('fantasia', Query.DataSet.FieldByName('CLI_FANTASIA').AsString);
      oJson.AddPair('cidade', Query.DataSet.FieldByName('CLI_CIDADE').AsString);
      oJson.AddPair('uf', Query.DataSet.FieldByName('CLI_UF').AsString);
      aJson.AddElement(oJson);
      Query.DataSet.Next;
    end;
    Res.Send<TJSONArray>(aJson).Status(THTTPStatus.OK);
  end else
    Res.Send<TJSONObject>(TJSONObject.Create.AddPair('message', 'usuarios não encontrados')).Status(THTTPStatus.NotFound);
end;

class procedure TUsuariosController.CreateUsers(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var oUsuarioJson: TJSONObject;
  Query: iQuery;
  CodigoIniciar: Integer;
  Codigo: Integer;
begin
  if Req.Body = '' then
    Res.Send<TJSONObject>(TJSONObject.Create.AddPair('message', 'Usuario não informado')).Status(THTTPStatus.BadRequest);
  try
    oUsuarioJson := Req.Body<TJSONObject>;
    if Assigned(oUsuarioJson) then
    begin
      CodigoIniciar := 1001;
      Query := TDatabase.Query;
      Query.Add('SELECT MAX(USU_CODIGO) CODIGO FROM USUARIOS_APP').Open;
      if Query.DataSet.FieldByName('CODIGO').AsInteger > 0 then
      begin
        Codigo := Query.DataSet.FieldByName('CODIGO').AsInteger+1;
      end;
      if Codigo < CodigoIniciar  then
        Codigo := CodigoIniciar;
      Query := TDatabase.Query;
      Query.Add('UPDATE OR INSERT INTO USUARIOS_APP (USU_CODIGO, USU_CLI, USU_NOME, USU_SENHA, USU_MOSTRAR_PRECOS, USU_CELULAR)');
      Query.Add('VALUES (:USU_CODIGO, :USU_CLI, :USU_NOME, :USU_SENHA, :USU_MOSTRAR_PRECOS, :USU_CELULAR)');
      Query.Add('MATCHING (USU_CODIGO)');
      Query.AddParam('USU_CODIGO', codigo);
      Query.AddParam('USU_CLI', oUsuarioJson.GetValue<Integer>('cli'));
      Query.AddParam('USU_NOME', oUsuarioJson.GetValue<string>('nome'));
      Query.AddParam('USU_SENHA', oUsuarioJson.GetValue<string>('senha'));
      Query.AddParam('USU_MOSTRAR_PRECOS', IfThen(oUsuarioJson.GetValue<Boolean>('mostrar_precos'), 'S', 'N'));
      Query.AddParam('USU_CELULAR', oUsuarioJson.GetValue<string>('celular'));
      Query.ExecSQL;
      Res.Send<TJSONObject>(TJSONObject.Create.AddPair('codigo', Codigo.ToString)).Status(THTTPStatus.OK);
    end
  except on E: Exception do
    Res.Send<TJSONObject>(TJSONObject.Create.AddPair('message', 'Dados inválidos'+sLineBreak+E.Message)).Status(THTTPStatus.BadRequest);
  end;
end;

class procedure TUsuariosController.UpdateUser(Req: THorseRequest;
  Res: THorseResponse; Next: TProc);
var oUsuarioJson: TJSONObject;
  Query: iQuery;
  Codigo: Integer;
begin
  if Req.Params.Count = 0 then
    Res.Send<TJSONObject>(TJSONObject.Create.AddPair('message', 'Código do Usuario não informado')).Status(THTTPStatus.BadRequest);
  if Req.Body = '' then
    Res.Send<TJSONObject>(TJSONObject.Create.AddPair('message', 'Usuario não informado')).Status(THTTPStatus.BadRequest);
  try
    Codigo := Req.Params.Items['id'].ToInteger;
    oUsuarioJson := Req.Body<TJSONObject>;
    if Assigned(oUsuarioJson) then
    begin
      Query := TDatabase.Query;
      Query.Add('UPDATE OR INSERT INTO USUARIOS_APP (USU_CODIGO, USU_CLI, USU_NOME, USU_SENHA, USU_MOSTRAR_PRECOS, USU_CELULAR)');
      Query.Add('VALUES (:USU_CODIGO, :USU_CLI, :USU_NOME, :USU_SENHA, :USU_MOSTRAR_PRECOS, :USU_CELULAR)');
      Query.Add('MATCHING (USU_CODIGO)');
      Query.AddParam('USU_CODIGO', codigo);
      Query.AddParam('USU_CLI', oUsuarioJson.GetValue<Integer>('cli'));
      Query.AddParam('USU_NOME', oUsuarioJson.GetValue<string>('nome'));
      Query.AddParam('USU_SENHA', oUsuarioJson.GetValue<string>('senha'));
      Query.AddParam('USU_MOSTRAR_PRECOS', IfThen(oUsuarioJson.GetValue<Boolean>('mostrar_precos'), 'S', 'N'));
      Query.AddParam('USU_CELULAR', oUsuarioJson.GetValue<string>('celular'));
      Query.ExecSQL;
      Res.Send<TJSONObject>(TJSONObject.Create.AddPair('codigo', Codigo.ToString)).Status(THTTPStatus.OK);
    end
  except on E: Exception do
    Res.Send<TJSONObject>(TJSONObject.Create.AddPair('message', 'Dados inválidos'+sLineBreak+E.Message)).Status(THTTPStatus.BadRequest);
  end;
end;


class procedure TUsuariosController.Registrar;
begin
  THorse.Get('/usuarios', GetUsers);
  THorse.Post('/usuarios', CreateUsers);
  THorse.Put('/usuarios/:id', UpdateUser);
  THorse.Delete('/usuarios/:id', DeleteUser);
  //versionamento
  THorse.Group
  			.Prefix('v1')
        	.Route('/usuarios')
          	.Get(GetUsers)
            .Post(CreateUsers)
          .&End
        .Group
  			.Prefix('v1')
         	.Route('/usuarios/:id')
          	.Put(UpdateUser)
            .Delete(DeleteUser)
          .&End;
  	
end;

end.
