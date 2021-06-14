unit UnitLogin.Controller;

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
  TLoginController = class
    class procedure Registrar;
    class procedure Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
  end;

implementation

{ TLoginController }

uses UnitContants;

class procedure TLoginController.Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  oJsonRequest: TJSONObject;
  usuario: string;
  senha: string;
  Query: iQuery;
  oJson: TJSONObject;
begin
  oJsonRequest := Req.Body<TJSONObject>;
  if not Assigned(oJsonRequest) then
    raise Exception.Create('Usuario ou senha não informados!');
  usuario := oJsonRequest.GetValue<string>('usuario');
  senha   := oJsonRequest.GetValue<string>('senha');
  Query := TFactoryConexaoFireDAC.New(TConstants.BaseURL, TConstants.Usuario, TConstants.Senha).Query;
  Query.Add('SELECT CLI_CODIGO, CLI_FANTASIA FROM CLIENTES WHERE UPPER(CLI_LOGIN_SITE) = :USUARIO AND CLI_SENHA_SITE = :SENHA');
  Query.AddParam('USUARIO', usuario.ToUpper);
  Query.AddParam('SENHA', senha);
  Query.Open;
  if not Query.DataSet.IsEmpty then
  begin
    oJson := TJSONObject.Create;
    oJson.AddPair('codigo', TJSONNumber.Create(Query.DataSet.FieldByName('CLI_CODIGO').AsInteger));
    oJson.AddPair('fantasia', Query.DataSet.FieldByName('CLI_FANTASIA').AsString);
    Res.Send<TJSONObject>(oJson)
       .Status(THTTPStatus.OK)
  end else
    Res.Send<TJSONObject>(TJSONObject.Create.AddPair('message', 'usuario ou senha invalidos!'))
       .Status(THTTPStatus.Unauthorized);
end;

class procedure TLoginController.Registrar;
begin
  THorse.Post('/login', Post);
end;

end.
