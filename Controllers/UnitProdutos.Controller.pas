unit UnitProdutos.Controller;

interface

uses
  Horse,
  Horse.Commons,
  Classes,
  SysUtils,
  System.Json,
  DB,
  UnitConnection.Model.Interfaces,
  DataSet.Serialize;

type
  TProdutoController = class
    class procedure Registrar;
    class procedure GetProdutos(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure GetProdutoPorCodigo(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure GetCatalogo(Req: THorseRequest; Res: THorseResponse; Next: TProc);
  end;

implementation

{ TProdutoController }

uses Utils, 
     UnitDatabase,
     UnitConstants;

class procedure TProdutoController.GetCatalogo(Req: THorseRequest;
  Res: THorseResponse; Next: TProc);
var
  Json: TJSONObject;
  ListaArquivos: TJSONArray;
  ArquivosBuscados: TStringList;
  i: integer;
begin
  ListaArquivos := TJSONArray.Create;
  ArquivosBuscados := ProcuraArquivosDiretorio(ExtractFilePath(ParamStr(0))+'\Catalogo');
  for i := 0 to Pred(ArquivosBuscados.Count) do
  begin
    Json := TJSONObject.Create;
    Json.AddPair('img', ArquivosBuscados[i]);
    ListaArquivos.AddElement(Json);
  end;
  Res.Send<TJSONArray>(ListaArquivos);
end;

class procedure TProdutoController.GetProdutoPorCodigo(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Query  : iQuery;
  oJson  : TJSONObject;
  Codigo: Integer;
begin
  if Req.Params.Count > 0 then
  begin
    Codigo := Req.Params.Items['codigo'].ToInteger;
    Query   := TDatabase.Query;
    Query.Clear;
    Query.Add('SELECT PRO_DESCRICAO||''-''||PRO_TAMANHO MOD1, PRO_CODFORNECEDOR MOD2, FOR_NOME FORN, PRO_NOME NOME, PRO_VALORCM VL1, PRO_VALORC VL2,');
    Query.Add('PRO_QUANTRESERVA RES, PRO_QUANTIDADEF QTD, PRO_DATAUC COMPRA, PRO_DATAUV ULTVENDA');
    Query.Add('FROM PRODUTOS LEFT JOIN FORNECEDORES ON PRO_NFOR = FOR_NFORNECEDOR WHERE PRO_CODIGO = :CODIGO');
    Query.AddParam('CODIGO', Codigo);
    Query.Open;
    if not Query.DataSet.IsEmpty then
    begin
      Res.Send<TJSONObject>(Query.DataSet.ToJSONObject);
    end else
      Res.Status(THTTPStatus.NotFound).Send<TJSONObject>(TJSONObject.Create.AddPair('error', 'Produto não encontrados!'));
  end
  else
    Res.Status(THTTPStatus.BadRequest).Send<TJSONObject>(TJSONObject.Create.AddPair('error', 'Codigo não informado'));
end;

class procedure TProdutoController.GetProdutos(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Query  : iQuery;
  aJson  : TJSONArray;
  oJson  : TJSONObject;
begin
  Query   := TDatabase.Query;
  Query.Clear;
  Query.Add('SELECT PRO_CODIGO CODIGO, PRO_DESCRICAO||''-''||PRO_TAMANHO MODELO, PRO_CODFORNECEDOR MOD2, PRO_NOME NOME, ');
  Query.Add('PRO_VALORVS VALOR, PRO_VALORC CUSTO, PRO_QUANTIDADEF QTD, PRO_DATAUV ULTVENDA ');
  Query.Add('FROM PRODUTOS WHERE PRO_ESTADO = ''ATIVO''');
  Query.Open;
  if not Query.DataSet.IsEmpty then
  begin
    aJson := TJSONArray.Create;
    Query.DataSet.First;
    while not Query.DataSet.Eof do
    begin
      oJson := TJSONObject.Create;
      oJson.AddPair('codigo', TJSONNumber.Create(Query.DataSet.FieldByName('CODIGO').AsInteger));
      oJson.AddPair('modelo', Query.DataSet.FieldByName('MODELO').AsString);
      oJson.AddPair('mod2', Trim(Query.DataSet.FieldByName('MOD2').AsString));
      oJson.AddPair('nome', Query.DataSet.FieldByName('NOME').AsString);
      oJson.AddPair('valor', TJSONNumber.Create(Query.DataSet.FieldByName('VALOR').AsFloat));
      oJson.AddPair('custo', TJSONNumber.Create(Query.DataSet.FieldByName('CUSTO').AsFloat));
      oJson.AddPair('qtd', TJSONNumber.Create(Query.DataSet.FieldByName('QTD').AsFloat));
      oJson.AddPair('ultvenda', FormatDateTime('yyyy-mm-dd', Query.DataSet.FieldByName('ULTVENDA').AsDateTime));
      aJson.AddElement(oJson);
      Query.DataSet.Next;
    end;
    Res.Send<TJSONArray>(aJson);
  end
  else
    Res.Status(THTTPStatus.NotFound).Send<TJSONObject>(TJSONObject.Create.AddPair('error', 'Produtos não encontrados!'));
end;

class procedure TProdutoController.Registrar;
begin
  THorse.Get('/produtos', GetProdutos);
  THorse.Get('/produtos/:codigo', GetProdutoPorCodigo);
  THorse.Get('/imagens', GetCatalogo);
  //versionamento
  THorse.Group
  			.Prefix('v1')
        	.Route('/produtos')
          	.Get(GetProdutos)
          .&End
        .Group
        .Prefix('v1')
          .Route('/produtos/:codigo')
          	.Get(GetProdutoPorCodigo)
          .&End
        .Group        
        .Prefix('v1')
          .Route('/imagens')
          	.Get(GetCatalogo)
          .&End;
  
end;

end.
