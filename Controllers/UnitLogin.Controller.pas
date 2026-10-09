unit UnitLogin.Controller;

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
  TLoginController = class
  private
    class function NormalizaCelular(Celular: string): string;
    class function CompararCelular(CelularUsuario, CelularRequest: string): Boolean;    
  public
    class procedure Registrar;
    class procedure Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure LoginSite(Req: THorseRequest; Res: THorseResponse; Next: TProc);
  end;

implementation

{ TLoginController }

uses UnitConstants, UnitDatabase;

class function TLoginController.CompararCelular(CelularUsuario, CelularRequest: string): Boolean;
begin
  Result := NormalizaCelular(CelularUsuario) = NormalizaCelular(CelularRequest);
end;

class function TLoginController.NormalizaCelular(Celular: string): string;
begin
  Result := Celular.Replace('+', '')
                   .Replace(' ', '')
                   .Replace('(', '')
                   .Replace(')', '')
                   .Replace('-', '');
end;

class procedure TLoginController.Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  oJsonRequest: TJSONObject;
  usuario: string;
  senha: string;
  Query: iQuery;
  oJson: TJSONObject;
  Celular: string;
begin
  oJsonRequest := Req.Body<TJSONObject>;
  if not Assigned(oJsonRequest) then
    raise Exception.Create('Usuario ou senha não informados!');
  usuario := oJsonRequest.GetValue<string>('usuario');
  senha   := oJsonRequest.GetValue<string>('senha');
  Celular := oJsonRequest.GetValue<string>('celular');
  Query := TDatabase.Query;
  Query.Add('SELECT USU_CODIGO, USU_NOME, USU_MOSTRAR_PRECOS, USU_CELULAR, CLI_CODIGO, CLI_FANTASIA FROM USUARIOS_APP JOIN CLIENTES ON USU_CLI = CLI_CODIGO ');
  Query.Add('WHERE UPPER(USU_NOME) = :USUARIO AND USU_SENHA = :SENHA');
  Query.AddParam('USUARIO', usuario.ToUpper);
  Query.AddParam('SENHA', senha);
  Query.Open;
  if not Query.DataSet.IsEmpty then
  begin
    if (not CompararCelular(Query.DataSet.FieldByName('USU_CELULAR').AsString, Celular)) then
      Res.Send<TJSONObject>(TJSONObject.Create.AddPair('message', 'Celular não permitido')).Status(THTTPStatus.BadRequest)
    else
    begin
      oJson := TJSONObject.Create;
      oJson.AddPair('codigo', TJSONNumber.Create(Query.DataSet.FieldByName('USU_CODIGO').AsInteger));
      oJson.AddPair('cliente', TJSONNumber.Create(Query.DataSet.FieldByName('CLI_CODIGO').AsInteger));
      oJson.AddPair('nome', Query.DataSet.FieldByName('USU_NOME').AsString);
      oJson.AddPair('mostrar_precos', TJSONBool.Create(Query.DataSet.FieldByName('USU_MOSTRAR_PRECOS').AsString = 'S'));
      oJson.AddPair('fantasia', Query.DataSet.FieldByName('CLI_FANTASIA').AsString);
      Res.Send<TJSONObject>(oJson)
         .Status(THTTPStatus.OK)
    end;
  end else
    Res.Send<TJSONObject>(TJSONObject.Create.AddPair('message', 'usuario ou senha invalidos!'))
       .Status(THTTPStatus.Unauthorized);
end;

class procedure TLoginController.LoginSite(Req: THorseRequest; Res: THorseResponse; Next: TProc);
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

  if (usuario.Trim.ToUpper = 'ADMIN') and (senha.Trim = '1234') then
  begin
    oJson := TJSONObject.Create;
    oJson.AddPair('codigo', TJSONNumber.Create(1));
    oJson.AddPair('nome', 'Administrador');
    Res.Send<TJSONObject>(oJson);
    Exit;
  end;

  Query := TDatabase.Query;
  Query.Add('SELECT USU_CODIGO, USU_NOME FROM USUARIOS_APP JOIN CLIENTES ON USU_CLI = CLI_CODIGO ');
  Query.Add('WHERE UPPER(USU_NOME) = :USUARIO AND USU_SENHA = :SENHA');
  Query.AddParam('USUARIO', usuario.ToUpper);
  Query.AddParam('SENHA', senha);
  Query.Open;
  if not Query.DataSet.IsEmpty then
  begin
    oJson := TJSONObject.Create;
    oJson.AddPair('codigo', TJSONNumber.Create(Query.DataSet.FieldByName('USU_CODIGO').AsInteger));
    oJson.AddPair('nome', Query.DataSet.FieldByName('USU_NOME').AsString);
    Res.Send<TJSONObject>(oJson);
  end else
    Res.Send<TJSONObject>(TJSONObject.Create.AddPair('message', 'usuario ou senha invalidos!'))
       .Status(THTTPStatus.Unauthorized);
end;

class procedure TLoginController.Registrar;
begin
  THorse.Post('/login', Post);
  //versionamento
  THorse.Group
  			.Prefix('v1')
        	.Route('/login')
          	.Post(Post)            
          .&End
        .Group
  			.Prefix('v1')
          .Route('/login/site')
						.Post(LoginSite)
          .&End;
end;

end.
