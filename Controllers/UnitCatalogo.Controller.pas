unit UnitCatalogo.Controller;

interface

uses
	System.Generics.Collections,
	Horse,
	Horse.Commons,
	Classes,
	SysUtils,
	System.Json,
	DB,
	UnitConnection.Model.Interfaces;

type
	TCatalogoController = class
	public
		class procedure Registrar;
    class procedure Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
		class procedure GetCatalogo(Req: THorseRequest; Res: THorseResponse; Next: TProc);
	end;

implementation

{ TCatalogoController }

uses
	UnitConstants,
	UnitDatabase;

class procedure TCatalogoController.Get(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  Query: iQuery;
  oJson: TJSONObject;
  aJson: TJSONArray;
  Marca: string;
begin
  Marca := '';
  if Req.Query.Count > 0 then
  begin
    Marca := Req.Query.Items['marca'];
  end;
  Query := TDatabase.Query;
  Query.Add('SELECT PRO_DESCRICAO||''-''||PRO_TAMANHO MODELO, PRO_VALORVS VALOR, PRO_CODIGO, ');
  Query.Add('PRO_NUM_COR||''-''||COR_NOME COR, PRO_NOME, PRO_DESCRICAO||''-''||PRO_NUM_COR DESCRICAO,');
  Query.Add('PRO_NOVO_NO_CATALOGO');
  Query.Add('FROM PRODUTOS JOIN CORES ON PRO_COR = COR_CODIGO');
  Query.Add('WHERE PRO_CATALOGO = ''S'' AND PRO_QUANTIDADEF > 0 ');
  if not Marca.IsEmpty then
  begin
    Query.Add('AND PRO_MARCA = :MARCA');
    Query.AddParam('MARCA', Marca.ToUpper);
  end;
  Query.Add('ORDER BY PRO_ORDEM_CATALOGO');
  Query.Open;
  aJson := TJSONArray.Create;
  Query.DataSet.First;
  while not Query.DataSet.Eof do
  begin
    oJson := TJSONObject.Create;
    oJson.AddPair('codigo', TJSONNumber.Create(Query.DataSet.FieldByName('PRO_CODIGO').AsInteger));
    oJson.AddPair('modelo', Query.DataSet.FieldByName('MODELO').AsString);
    oJson.AddPair('valor', TJSONNumber.Create(Query.DataSet.FieldByName('VALOR').AsCurrency));
    oJson.AddPair('cor', Query.DataSet.FieldByName('COR').AsString);
    oJson.AddPair('nome', Query.DataSet.FieldByName('PRO_NOME').AsString);
    oJson.AddPair('descricao', Query.DataSet.FieldByName('DESCRICAO').AsString);
    oJson.AddPair('novo', TJSONBool.Create(Query.DataSet.FieldByName('PRO_NOVO_NO_CATALOGO').AsString.ToUpper = 'S'));
    aJson.AddElement(oJson);
    Query.DataSet.Next;
  end;
  Res.Send<TJSONArray>(aJson).Status(THTTPStatus.OK);
end;

class procedure TCatalogoController.GetCatalogo(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
	Query  : iQuery;
	oJson  : TJSONObject;
	aJson  : TJSONArray;
	Marca  : string;
begin
	Marca := '';
	if Req.Query.Count > 0 then
	begin
		Marca := Req.Query.Items['marca'];
	end;
	Query := TDatabase.Query;
	Query.Add('SELECT PRO_DESCRICAO||''-''||PRO_TAMANHO MODELO, PRO_VALORVS VALOR, PRO_CODIGO, ');
	Query.Add('PRO_NUM_COR||''-''||COR_NOME COR, PRO_NOME, PRO_DESCRICAO||''-''||PRO_CODGRUPO DESCRICAO,');
	Query.Add('PRO_NOVO_NO_CATALOGO, PRO_ORDEM_CATALOGO ORDENACAO');
	Query.Add('FROM PRODUTOS JOIN CORES ON PRO_COR = COR_CODIGO');
	Query.Add('WHERE PRO_CATALOGO = ''S'' AND PRO_QUANTIDADEF > 0 ');
	if not Marca.IsEmpty then
	begin
		Query.Add('AND PRO_MARCA = :MARCA');
		Query.AddParam('MARCA', Marca.ToUpper);
	end;
	Query.Add('ORDER BY PRO_ORDEM_CATALOGO');
	Query.Open;
	aJson := TJSONArray.Create;
	Query.DataSet.First;
	while not Query.DataSet.Eof do
	begin
		oJson := TJSONObject.Create;
		oJson.AddPair('codigo', TJSONNumber.Create(Query.DataSet.FieldByName('PRO_CODIGO').AsInteger));
		oJson.AddPair('modelo', Query.DataSet.FieldByName('MODELO').AsString);
		oJson.AddPair('valor', TJSONNumber.Create(Query.DataSet.FieldByName('VALOR').AsCurrency));
		oJson.AddPair('cor', Query.DataSet.FieldByName('COR').AsString);
		oJson.AddPair('nome', Query.DataSet.FieldByName('PRO_NOME').AsString);
		oJson.AddPair('descricao', Query.DataSet.FieldByName('DESCRICAO').AsString);
		oJson.AddPair('novo', TJSONBool.Create(Query.DataSet.FieldByName('PRO_NOVO_NO_CATALOGO').AsString.ToUpper = 'S'));
    oJson.AddPair('ordenacao', TJSONNumber.Create(Query.DataSet.FieldByName('ORDENACAO').AsInteger));
		aJson.AddElement(oJson);
		Query.DataSet.Next;
	end;
	Res.Send<TJSONArray>(aJson).Status(THTTPStatus.OK);
end;

class procedure TCatalogoController.Registrar;
begin
	THorse.Get('/Catalogo', Get);
  //versionamento
  THorse.Group
  			.Prefix('v1')  
        	.Route('/catalogo')
          	.Get(GetCatalogo)
          .&End;
        
end;

end.
