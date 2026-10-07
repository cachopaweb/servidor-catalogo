unit UnitDatabase;

interface

uses
  UnitConnection.Model.Interfaces;

type
  TDatabase = class
    class function Query: iQuery;
  end;

implementation

uses
  UnitFactory.Connection.Firedac,
  UnitConstants;

{ TDatabase }

class function TDatabase.Query: iQuery;
begin
  Result := TFactoryConnectionFiredac.New(TConstants.BaseURL, TConstants.Usuario, TConstants.Senha).Query;
end;

end.
