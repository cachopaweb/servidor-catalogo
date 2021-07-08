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
  Result := '';
end;

class function TConstants.Senha: string;
begin
  Result := '';
end;

class function TConstants.Usuario: string;
begin
  Result := '';
end;

end.
