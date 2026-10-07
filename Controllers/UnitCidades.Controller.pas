unit UnitCidades.Controller;

interface
uses
  Horse,
  Classes,
  SysUtils,
  System.Json,
  UnitConnection.Model.Interfaces;

type
  TCidadesController = class
    class procedure Registrar;
    class procedure Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
  end;

implementation

uses
  UnitDatabase;

{ TControllerCidades }

class procedure TCidadesController.Get(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  Query: iQuery;
  aJson: TJSONArray;
  oJson: TJSONObject;
  Nome: string;
begin
	if Req.Query.ContainsKey('nome') then
  	Nome := Req.Query.Items['nome'].ToUpper;
	aJson := TJSONArray.Create;
	Query := TDatabase.Query;
  Query.Add('SELECT DISTINCT CLI_CIDADE FROM CLIENTES WHERE CLI_CIDADE IS NOT NULL ');
  if not Nome.IsEmpty then
  begin
  	Query.Add('AND CAST(LEFT(CLI_CIDADE, 40) AS VARCHAR(40) CHARACTER SET ISO8859_1) COLLATE PT_BR LIKE :NOME');
    Query.AddParam('NOME', '%'+Nome+'%');
  end;
  Query.Add('ORDER BY CLI_CIDADE');
  Query.Open();
  Query.DataSet.First;
  while not Query.DataSet.Eof do
  begin
  	oJson := TJSONObject.Create;
    oJson.AddPair('cidade', Query.DataSet.FieldByName('CLI_CIDADE').AsString);
    aJson.AddElement(oJson);
    Query.DataSet.Next;
  end;
  Res.Send<TJSONArray>(aJson);  
end;

class procedure TCidadesController.Registrar;
begin
	THorse.Get('/cidades', Get);
  //versionamento
  THorse.Group
  			.Prefix('v1')
  				.Route('/cidades')
          	.Get(Get)
          .&End;
end;

end.
