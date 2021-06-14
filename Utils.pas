unit Utils;

interface

uses
  System.Classes;

function ProcuraArquivosDiretorio(NomePasta: string): TStringList;
function ConvertFileToBase64(const FileName: string): string;

implementation

uses
  System.SysUtils, IdCoderMIME;

function ProcuraArquivosDiretorio(NomePasta: string): TStringList;
var
  i: Integer;
  Rec: TSearchRec;
  j: Integer;
  ArquivoAux: string;
begin
  Result := TStringList.Create;
  if FindFirst(NomePasta + '/*', faArchive, Rec) = 0 then
  begin
    try
      repeat
        Result.Add(rec.Name);
      until FindNext(Rec) <> 0;
    finally

    end;
  end;
end;

function ConvertFileToBase64(const FileName: string): string;
var
  LInput : TFileStream;
  base64: TIdEncoderMIME;
begin
  Result := '';
  if FileName = '' then
    Exit;
  base64 := TIdEncoderMIME.Create(nil);
  LInput := TFileStream.Create(FileName, fmOpenRead);
  try
    LInput.Position := 0;
    Result := TIdEncoderMIME.EncodeStream(LInput);
  finally
    LInput.Free;
  end;
end;

end.
