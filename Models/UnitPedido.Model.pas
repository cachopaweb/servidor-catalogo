unit UnitPedido.Model;

interface

uses System.Json,
  SysUtils,
  DB,
  UnitConexao.Model.Interfaces,
  UnitConexao.FireDAC.Model,
  UnitQuery.FireDAC.Model,
  UnitFactory.Conexao.FireDAC;

type
  TItem = class
  private
    FCodigo: integer;
    FProduto: integer;
    FQuantidade: double;
  public
    property Codigo: integer read FCodigo write FCodigo;
    property Produto: integer read FProduto write FProduto;
    property Quantidade: double read FQuantidade write FQuantidade;
  end;

  TPedido = class
  private
    FCodigo: integer;
    FCliente: integer;
    FData: string;
    FNumVenda: integer;
    FItens: TArray<TItem>;
  public
    class function FromJsonString(Json: string): TPedido;
    function ToJson: string;
    procedure Inserir;
    class function Buscar(Codigo: integer): TPedido;
    property Codigo: integer read FCodigo write FCodigo;
    property Cliente: integer read FCliente write FCliente;
    property Data: string read FData write FData;
    property Itens: TArray<TItem> read FItens write FItens;
  end;

implementation

uses Rest.Json, UnitContants;

{ TPedido }

class function TPedido.Buscar(Codigo: integer): TPedido;
var
  Query: iQuery;
  Contador: integer;
  Item: TItem;
  Itens: TArray<TItem>;
begin
  Result := TPedido.Create;
  Query  := TFactoryConexaoFireDAC.New(TConstants.BaseURL, TConstants.Usuario, TConstants.Senha).Query;
  Query.Add('SELECT PED_CODIGO, PED_CLI, PED_DATA, PAI_CODIGO, PAI_PRO, PAI_QUANTIDADE');
  Query.Add('FROM PEDIDOS_APP JOIN PEDIDOS_APP_ITENS ON PED_CODIGO = PAI_PED');
  Query.Add('WHERE PED_CODIGO = :CODIGO');
  Query.Add('ORDER BY PAI_CODIGO');
  Query.AddParam('CODIGO', Codigo);
  Query.Open();
  if not Query.DataSet.IsEmpty then
  begin
    Query.DataSet.First;
    Result.Codigo   := Query.DataSet.FieldByName('PED_CODIGO').AsInteger;
    Result.Cliente  := Query.DataSet.FieldByName('PED_CLI').AsInteger;
    Result.Data     := FormatDateTime('dd/mm/yyyy', Query.DataSet.FieldByName('PED_DATA').AsDateTime);
    Itens := [];
    Contador := 1;
    while not Query.DataSet.Eof do
    begin
      SetLength(Itens, Contador);
      Item               := TItem.Create;
      Item.Codigo        := Query.DataSet.FieldByName('PAI_CODIGO').AsInteger;
      Item.Produto       := Query.DataSet.FieldByName('PAI_PRO').AsInteger;
      Item.quantidade    := Query.DataSet.FieldByName('PAI_QUANTIDADE').AsFloat;
      Query.DataSet.Next;
      Itens[Contador-1] := Item;
      Inc(Contador);
    end;
    Result.Itens := Itens;
  end;
end;

class function TPedido.FromJsonString(Json: string): TPedido;
begin
  Result := TJson.JsonToObject<TPedido>(Json);
end;

procedure TPedido.Inserir;
var
  Query: iQuery;
  i: integer;
  ID: Integer;
begin
  try
    Query := TFactoryConexaoFireDAC.New(TConstants.BaseURL, TConstants.Usuario, TConstants.Senha).Query;
    Query.Add('SELECT MAX(PED_CODIGO) CODIGO FROM PEDIDOS_APP').Open;
    Codigo := Query.DataSet.FieldByName('CODIGO').AsInteger+1;
    ////
    Query.Clear;
    Query.Add('INSERT INTO PEDIDOS_APP (PED_CODIGO, PED_CLI, PED_DATA)');
    Query.Add('VALUES (:CODIGO, :CLI, :DATA)');
    Query.AddParam('CODIGO', Codigo);
    Query.AddParam('CLI', Cliente);
    Query.AddParam('DATA', Now);
    Query.ExecSQL;
    if Codigo > 0 then
    begin
      for i := Low(Itens) to High(Itens) do
      begin
        Query.Clear;
        Query.Add('SELECT MAX(PAI_CODIGO) CODIGO FROM PEDIDOS_APP_ITENS').Open;
        ID := Query.DataSet.FieldByName('CODIGO').AsInteger+1;
        Query.Clear;
        Query.Add('INSERT INTO PEDIDOS_APP_ITENS (PAI_CODIGO, PAI_PED, PAI_PRO, PAI_QUANTIDADE)');
        Query.Add('VALUES (:CODIGO, :PED, :PRO, :QUANTIDADE)');
        Query.AddParam('CODIGO', ID);
        Query.AddParam('PED', Codigo);
        Query.AddParam('PRO', Itens[i].Produto);
        Query.AddParam('QUANTIDADE', Itens[i].quantidade);
        Query.ExecSQL;
      end;
    end;
  except
    on E: Exception do
      raise Exception.Create('Erro ao inserir pedido!' + sLineBreak + E.Message);
  end;
end;

function TPedido.ToJson: string;
begin
  Result := TJson.ObjectToJsonString(Self);
end;

end.
