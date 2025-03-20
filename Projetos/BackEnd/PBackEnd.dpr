program PBackEnd;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Horse;

begin
  THorse.Get('/ping',
    procedure(Req: THorseRequest; Res: THorseResponse)
    begin
      Res.Send('pong');
    end);

  THorse.Listen(9000,
    procedure
    begin
      WriteLn(Format('Servidor Ativo na Porta %d', [THorse.Port]));
      WriteLn('Na Escuta...');
    end);
end.
