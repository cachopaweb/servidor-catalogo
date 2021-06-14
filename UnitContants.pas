unit UnitContants;

interface
type
  TConstants = class
    class function BaseURL: string;
    class function Usuario: string;
    class function Senha: string;
  end;

implementation

{ TConstants }

class function TConstants.BaseURL: string;
begin
  Result := 'firebird03-farm1.kinghost.net:/firebird/palazzioculos1.gdb';
end;

class function TConstants.Senha: string;
begin
  Result := 'hwz7925p';
end;

class function TConstants.Usuario: string;
begin
  Result := 'PALAZZIOCULOS1';
end;

end.
