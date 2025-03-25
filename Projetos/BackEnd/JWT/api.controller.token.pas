unit api.controller.token;

interface

uses
  Horse,
  System.StrUtils,
  System.SysUtils,
  System.Classes,
  System.JSON,
  System.Generics.Collections,
  DateUtils,
  JOSE.Core.JWT,
  JOSE.Core.Builder,

  API.Infra.Claims;


const
  C_SECRET_JWT = 'adrianosantostreina2024';

procedure Registry;

implementation

procedure DoGetToken(Req: THorseRequest; Res: THorseResponse);
var
  LToken: TJWT;
  LExpiration: TDateTime;
  LCompactToken: string;
  LCNPJ: string;
  LCodLicenca: string;
  LSerialHD: string;
  LResult: TJSONObject;
  LClaims: TCustomClaims;
begin
  LToken := TJWT.Create(TCustomClaims);
  try
    Req.Body<TJSONobject>.TryGetValue<string>('cnpj', LCNPJ);

    LClaims := TCustomClaims(LToken.Claims);
    LClaims.Issuer := 'Meu nome de Empresa';
    LClaims.CNPJ := LCNPJ;
    LExpiration := IncMinute(Now, 10);
    LClaims.Expiration := LExpiration;

    LCompactToken := TJOSE.SHA256CompactToken(C_SECRET_JWT, LToken);
    LResult := TJSONObject.Create;

    LResult.AddPair('Expiration', FormatDateTime('DD/MM/YYYY hh:mm:ss.nnn',  LExpiration));
    LResult.AddPair('Token', LCompactToken);
    Res.Send<TJSONObject>(LResult);
  finally
    LToken.Free;
  end;
end;

procedure Registry;
begin
  THorse
    .Post('/token', DoGetToken);
end;

initialization
Registry;

end.

