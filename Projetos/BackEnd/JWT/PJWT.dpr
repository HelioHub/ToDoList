program PJWT;

{$APPTYPE CONSOLE}

{$R *.res}

uses Horse,
  Horse.Jhonson, Horse.CORS,
  System.JSON,
  JOSE.Core.JWT,
  JOSE.Core.Builder,
  System.SysUtils;

Const
  keysecret = 'your-secret-key';

procedure ConfigureCORS;
begin
end;

begin
  THorse.Post('/login',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      LToken: TJWT;
      LCompactToken: string;
      Body: TJSONObject;
      Login, Password: string;
    begin
      LToken := TJWT.Create;
      try
        // Token claims
        LToken.Claims.Issuer := 'WiRL REST Library';
        LToken.Claims.Subject := 'Helio Marques';
        LToken.Claims.Expiration := Now + 1;

        Body := TJSONObject.ParseJSONValue(Req.Body) as TJSONObject;
        if not Assigned(Body) then
        begin
          Res.Status(THTTPStatus.BadRequest).Send('Invalid JSON');
          Exit;
        end;


        // Extrai login e password do JSON
        Login := Body.GetValue<string>('login');
        Password := Body.GetValue<string>('password');

        Writeln(Format('Tentativa de login: login=%s, password=%s', [Login, Password])); // Log para depura��o


        // Outros claims
        LToken.Claims.SetClaimOfType<string>('usuario',Login);
        LToken.Claims.SetClaimOfType<string>('senha',Password);

        // Signing and Compact format creation
        LCompactToken := TJOSE.SHA256CompactToken(keysecret, LToken);

        Res.RawWebResponse.SetCustomHeader('Access-Control-Allow-Origin', 'http://localhost:3000');
        Res.RawWebResponse.SetCustomHeader('Access-Control-Allow-Methods', 'POST, GET, OPTIONS');
        Res.RawWebResponse.SetCustomHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

        Res.Send(LCompactToken)
      finally
        LToken.Free;
      end;
      end);

  Writeln('API Gera Token JWT...');
  Writeln('Porta 9001.');
  THorse.Listen(9001);
end.
