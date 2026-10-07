unit UnitConstants;

interface
uses System.SysUtils;

type
  TConstants = class
    class function BaseURL: string;
    class function Usuario: string;
    class function Senha: string;
  end;

implementation
const BancoTeste = 'D:\PROJETOS\Roberto\Dados\PRINICIPAL.FDB';
const BancoProducao = 'firebird03-farm1.kinghost.net:/firebird/palazzioculos1.gdb';
const UsuarioTeste = 'SYSDBA';
const UsuarioProducao = 'PALAZZIOCULOS1';
const SenhaTeste = 'masterkey';
const SenhaProducao = 'hwz7925p';

{ TConstants }

class function TConstants.BaseURL: string;
begin
//  Result := GetEnvironmentVariable('BD');
  Result := BancoProducao;
end;

class function TConstants.Senha: string;
begin
//  Result := GetEnvironmentVariable('SENHA');
  Result := SenhaProducao;
end;

class function TConstants.Usuario: string;
begin
//  Result := GetEnvironmentVariable('USUARIO');
  Result := UsuarioProducao;
end;

end.
