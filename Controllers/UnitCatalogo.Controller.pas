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
  UnitConexao.Model.Interfaces,
  UnitConexao.FireDAC.Model,
  UnitQuery.FireDAC.Model,
  UnitFactory.Conexao.FireDAC;

type
  TProduto = record
    Codigo: integer;
    Cor: string;
  end;

  TModelo = class
    Modelo: string;
    Valor: Currency;
    Produtos: TList<TProduto>;
    constructor Create;
  end;

type
  TCatalogoController = class
  private
    class function MontaArrayProdutosPorModelo(ListaProdutos: TList<TProduto>): TJSONArray;
  public
    class procedure Registrar;
    class procedure Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
  end;

implementation

{ TCatalogoController }

uses UnitContants;

class function TCatalogoController.MontaArrayProdutosPorModelo(ListaProdutos: TList<TProduto>): TJSONArray;
var
  oJson: TJSONObject;
  i: Integer;
begin
  Result := TJSONArray.Create;
  if ListaProdutos.Count > 0 then
  begin
    for i := 0 to Pred(ListaProdutos.Count) do
    begin
      oJson := TJSONObject.Create;
      oJson.AddPair('codigo', TJSONNumber.Create(ListaProdutos[i].Codigo));
      oJson.AddPair('cor', ListaProdutos[i].Cor);
      Result.AddElement(oJson);
    end;
  end;
end;

class procedure TCatalogoController.Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Query: iQuery;
  oJson: TJSONObject;
  aJson: TJSONArray;
  Lista: TDictionary<string, TModelo>;
  Produto: TProduto;
  ModeloStr: string;
  Modelo: TModelo;
  ModeloFinal: TModelo;
begin
  Query := TFactoryConexaoFireDAC.New(TConstants.BaseURL, TConstants.Usuario, TConstants.Senha).Query;
  Query.Add('SELECT PRO_DESCRICAO||''-''||PRO_TAMANHO MODELO, PRO_VALORVS VALOR, PRO_CODIGO, COR_NOME');
  Query.Add('FROM PRODUTOS JOIN CORES ON PRO_COR = COR_CODIGO');
  Query.Add('WHERE PRO_CATALOGO = ''S'' ORDER BY PRO_ORDEM_CATALOGO');
  Query.Open;
  Lista := TDictionary <string, TModelo>.Create();
  Query.DataSet.First;
  while not Query.DataSet.Eof do
  begin
    Lista.TryGetValue(Query.DataSet.FieldByName('MODELO').AsString, Modelo);
    if not Assigned(Modelo) then
      Modelo := TModelo.Create;
    Modelo.Modelo  := Query.DataSet.FieldByName('MODELO').AsString;
    Modelo.Valor   := Query.DataSet.FieldByName('VALOR').AsCurrency;
    Produto.Codigo := Query.DataSet.FieldByName('PRO_CODIGO').AsInteger;
    Produto.Cor    := Query.DataSet.FieldByName('COR_NOME').AsString;
    Modelo.Produtos.Add(Produto);
    Lista.AddOrSetValue(Modelo.Modelo, Modelo);
    Query.DataSet.Next;
  end;
  aJson := TJSONArray.Create;
  for ModeloStr in Lista.Keys do
  begin
    Lista.TryGetValue(ModeloStr, ModeloFinal);
    oJson := TJSONObject.Create;
    oJson.AddPair('modelo', ModeloFinal.Modelo);
    oJson.AddPair('valor', TJSONNumber.Create(ModeloFinal.Valor));
    oJson.AddPair('produtos', MontaArrayProdutosPorModelo(ModeloFinal.Produtos));
    aJson.AddElement(oJson);
  end;
  Res.Send<TJSONArray>(aJson).Status(THTTPStatus.OK);
end;

class procedure TCatalogoController.Registrar;
begin
  THorse.Get('/Modelos', Get);
end;

{ TModelo }

constructor TModelo.Create;
begin
  Produtos := TList<TProduto>.Create;
end;

end.
