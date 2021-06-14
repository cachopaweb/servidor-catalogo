unit UnitProdutos.Controller;

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
  UnitFactory.Conexao.FireDAC,
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

uses Utils, UnitContants;

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
  Fabrica: iFactoryConexao;
  Query  : iQuery;
  Dados  : TDataSource;
  oJson  : TJSONObject;
  Codigo: Integer;
begin
  if Req.Params.Count > 0 then
  begin
    Codigo := Req.Params.Items['codigo'].ToInteger;
    Fabrica := TFactoryConexaoFireDAC.New(TConstants.BaseURL, TConstants.Usuario, TConstants.Senha);
    Dados   := TDataSource.Create(nil);
    Query   := Fabrica.Query;
    Query.Clear;
    Query.Add('SELECT PRO_DESCRICAO||''-''||PRO_TAMANHO MOD1, PRO_CODFORNECEDOR MOD2, FOR_NOME FORN, PRO_NOME NOME, PRO_VALORCM VL1, PRO_VALORC VL2,');
    Query.Add('PRO_QUANTRESERVA RES, PRO_QUANTIDADEF QTD, PRO_DATAUC COMPRA');
    Query.Add('FROM PRODUTOS JOIN FORNECEDORES ON PRO_NFOR = FOR_NFORNECEDOR WHERE PRO_CODIGO = :CODIGO');
    Query.AddParam('CODIGO', Codigo);
    Query.Open;
    Dados.DataSet := Query.DataSet;
    if not Dados.DataSet.IsEmpty then
    begin
      Res.Send<TJSONObject>(Dados.DataSet.ToJSONObject);
    end else
      Res.Status(THTTPStatus.NotFound).Send<TJSONObject>(TJSONObject.Create.AddPair('error', 'Produto não encontrados!'));
  end
  else
    Res.Status(THTTPStatus.BadRequest).Send<TJSONObject>(TJSONObject.Create.AddPair('error', 'Codigo não informado'));
end;

class procedure TProdutoController.GetProdutos(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Fabrica: iFactoryConexao;
  Query  : iQuery;
  Dados  : TDataSource;
  aJson  : TJSONArray;
  oJson  : TJSONObject;
begin
  Fabrica := TFactoryConexaoFireDAC.New('firebird03-farm1.kinghost.net:/firebird/palazzioculos1.gdb', 'PALAZZIOCULOS1', 'hwz7925p');
  Dados   := TDataSource.Create(nil);
  Query   := Fabrica.Query;
  Query.Clear;
  Query.Add('SELECT PRO_CODIGO CODIGO, PRO_DESCRICAO||''-''||PRO_TAMANHO MODELO, PRO_NOME NOME, PRO_VALORVS VALOR, PRO_VALORC CUSTO, PRO_QUANTIDADEF QTD ');
  Query.Add('FROM PRODUTOS WHERE PRO_ESTADO = ''ATIVO''');
  Query.Open;
  Dados.DataSet := Query.DataSet;
  if not Dados.DataSet.IsEmpty then
  begin
    aJson := TJSONArray.Create;
    Dados.DataSet.First;
    while not Dados.DataSet.Eof do
    begin
      oJson := TJSONObject.Create;
      oJson.AddPair('codigo', TJSONNumber.Create(Dados.DataSet.FieldByName('CODIGO').AsInteger));
      oJson.AddPair('modelo', Dados.DataSet.FieldByName('MODELO').AsString);
      oJson.AddPair('nome', Dados.DataSet.FieldByName('NOME').AsString);
      oJson.AddPair('valor', TJSONNumber.Create(Dados.DataSet.FieldByName('VALOR').AsFloat));
      oJson.AddPair('custo', TJSONNumber.Create(Dados.DataSet.FieldByName('CUSTO').AsFloat));
      oJson.AddPair('qtd', TJSONNumber.Create(Dados.DataSet.FieldByName('QTD').AsFloat));
      aJson.AddElement(oJson);
      Dados.DataSet.Next;
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
end;

end.
