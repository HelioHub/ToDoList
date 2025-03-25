program PBackEnd;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  Horse,
  Horse.Jhonson,
  Horse.CORS,
  Horse.JWT,
  JOSE.Core.JWT,
  JOSE.Core.Builder,
  FireDAC.Stan.Def,
  FireDAC.Phys.SQLite,
  FireDAC.DApt,
  FireDAC.Stan.Async,
  FireDAC.Comp.Client,
  System.NetEncoding;

// Para decodificar a autenticação básica

var
  Conn: TFDConnection;
  UseBasicAuth: Boolean = False; // True: Define o padrão como Autenticação Básica

// Função para decodificar a autenticação básica
function DecodeBasicAuth(const AuthHeader: string; out Username, Password: string): Boolean;
var
  Decoded: string;
  SplitPos: Integer;
begin
  Result := False;
  if AuthHeader.StartsWith('Basic ', True) then
  begin
    Decoded := TNetEncoding.Base64.Decode(AuthHeader.Substring(6));
    SplitPos := Decoded.IndexOf(':');
    if SplitPos > 0 then
    begin
      Username := Decoded.Substring(0, SplitPos);
      Password := Decoded.Substring(SplitPos + 1);
      Result := True;
    end;
  end;
end;

// Função para verificar as credenciais no banco de dados
function CheckAuth(const Username, Password: string): Boolean;
var
  Query: TFDQuery;
begin
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := Conn;
    Query.SQL.Text := 'SELECT * FROM users WHERE loginuser = :login AND passworduser = :password';
    Query.ParamByName('login').AsString := Username;
    Query.ParamByName('password').AsString := Password;
    Query.Open;
    Result := not Query.Eof;
  finally
    Query.Free;
  end;
end;

// Middleware para autenticação básica
procedure BasicAuthMiddleware(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Username, Password: string;
begin
  if UseBasicAuth then
  begin
    if not DecodeBasicAuth(Req.Headers['Authorization'], Username, Password) then
    begin
      Res.Status(THTTPStatus.Unauthorized).Send('Autenticação básica necessária');
      Exit;
    end;

    // Verifica as credenciais no banco de dados
    if not CheckAuth(Username, Password) then
    begin
      Res.Status(THTTPStatus.Unauthorized).Send('Credenciais inválidas');
      Exit;
    end;
  end;
  Next();
end;

// Método para autenticar o usuário e gerar um token JWT
procedure OnAuthenticateUser(Req: THorseRequest; Res: THorseResponse);
var
  Query: TFDQuery;
  Body: TJSONObject;
  Login, Password: string;
  Token: TJWT;
begin
  Writeln('Requisição recebida em /login'); // Log para depuração
  try
    // Lê o corpo da requisição (JSON com login e password)
    Body := TJSONObject.ParseJSONValue(Req.Body) as TJSONObject;
    if not Assigned(Body) then
    begin
      Res.Status(THTTPStatus.BadRequest).Send('Invalid JSON');
      Exit;
    end;

    try
      // Extrai login e password do JSON
      Login := Body.GetValue<string>('login');
      Password := Body.GetValue<string>('password');

      Writeln(Format('Tentativa de login: login=%s, password=%s', [Login, Password])); // Log para depuração

      // Verifica as credenciais no banco de dados
      if not CheckAuth(Login, Password) then
      begin
        Writeln('Credenciais inválidas'); // Log para depuração
        Res.Status(THTTPStatus.Unauthorized).Send('Invalid login or password');
        Exit;
      end;

      // Cria um token JWT
      Token := TJWT.Create;
      try
        Token.Claims.SetClaimOfType<string>('user_id', Query.FieldByName('iduser').AsString);
        Token.Claims.SetClaimOfType<string>('login', Query.FieldByName('loginuser').AsString);

        // Gera o token
        Res.Send(TJOSE.SHA256CompactToken('your-secret-key', Token));
      finally
        Token.Free;
      end;
    finally
      Body.Free;
    end;
  except
    on E: Exception do
    begin
      Writeln('Erro durante a autenticação: ', E.ClassName, ' - ', E.Message); // Log para depuração
      Res.Status(THTTPStatus.InternalServerError).Send('Internal Server Error: ' + E.Message);
    end;
  end;
end;

// Configura a conexão com o SQLite
procedure SetupConnection;
begin
  Conn := TFDConnection.Create(nil);
  try
    // Define o driver SQLite
    FDManager.AddConnectionDef('SQLite_Def', 'SQLite');

    // Configura a conexão
    Conn.Params.DriverID := 'SQLite';
    Conn.Params.Database := 'C:\ToDoList\DB\dbtodolist.db'; // Altere para o caminho do seu banco de dados
    Conn.Connected := True;

    Writeln('Connected to SQLite database!');
  except
    on E: Exception do
    begin
      Writeln('Error connecting to database: ', E.Message);
      raise;
    end;
  end;
end;

// Retorna todos os usuários
procedure OnGetUsers(Req: THorseRequest; Res: THorseResponse);
var
  Query: TFDQuery;
  Users: TJSONArray;
  User: TJSONObject;
begin
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := Conn;
    Query.SQL.Text := 'SELECT * FROM users';
    Query.Open;

    Users := TJSONArray.Create;
    while not Query.Eof do
    begin
      User := TJSONObject.Create;
      User.AddPair('id', Query.FieldByName('iduser').AsInteger);
      User.AddPair('login', Query.FieldByName('loginuser').AsString);
      User.AddPair('password', Query.FieldByName('passworduser').AsString);
      Users.AddElement(User);
      Query.Next;
    end;

    Res.Send(Users.ToString);
  finally
    Query.Free;
  end;
end;

// Retorna um usuário por ID
procedure OnGetUserById(Req: THorseRequest; Res: THorseResponse);
var
  Query: TFDQuery;
  User: TJSONObject;
begin
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := Conn;
    Query.SQL.Text := 'SELECT * FROM users WHERE iduser = :id';
    Query.ParamByName('id').AsInteger := Req.Params['id'].ToInteger;
    Query.Open;

    if Query.Eof then
    begin
      Res.Status(THTTPStatus.NotFound).Send('User not found');
      Exit;
    end;

    User := TJSONObject.Create;
    User.AddPair('id', Query.FieldByName('iduser').AsInteger);
    User.AddPair('login', Query.FieldByName('loginuser').AsString);
    User.AddPair('password', Query.FieldByName('passworduser').AsString);

    Res.Send(User.ToString);
  finally
    Query.Free;
  end;
end;

// Cria um novo usuário
procedure OnCreateUser(Req: THorseRequest; Res: THorseResponse);
var
  Query: TFDQuery;
  Body: TJSONObject;
begin
  Body := TJSONObject.ParseJSONValue(Req.Body) as TJSONObject;
  if not Assigned(Body) then
  begin
    Res.Status(THTTPStatus.BadRequest).Send('Invalid JSON');
    Exit;
  end;

  Query := TFDQuery.Create(nil);
  try
    Query.Connection := Conn;
    Query.SQL.Text := 'INSERT INTO users (loginuser, passworduser) VALUES (:login, :password)';
    Query.ParamByName('login').AsString := Body.GetValue<string>('login');
    Query.ParamByName('password').AsString := Body.GetValue<string>('password');
    Query.ExecSQL;

    Res.Status(THTTPStatus.Created).Send('User created');
  finally
    Query.Free;
    Body.Free;
  end;
end;

// Atualiza um usuário
procedure OnUpdateUser(Req: THorseRequest; Res: THorseResponse);
var
  Query: TFDQuery;
  Body: TJSONObject;
begin
  Body := TJSONObject.ParseJSONValue(Req.Body) as TJSONObject;
  if not Assigned(Body) then
  begin
    Res.Status(THTTPStatus.BadRequest).Send('Invalid JSON');
    Exit;
  end;

  Query := TFDQuery.Create(nil);
  try
    Query.Connection := Conn;
    Query.SQL.Text := 'UPDATE users SET loginuser = :login, passworduser = :password WHERE iduser = :id';
    Query.ParamByName('login').AsString := Body.GetValue<string>('login');
    Query.ParamByName('password').AsString := Body.GetValue<string>('password');
    Query.ParamByName('id').AsInteger := Req.Params['id'].ToInteger;
    Query.ExecSQL;

    Res.Send('User updated');
  finally
    Query.Free;
    Body.Free;
  end;
end;

// Exclui um usuário
procedure OnDeleteUser(Req: THorseRequest; Res: THorseResponse);
var
  Query: TFDQuery;
begin
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := Conn;
    Query.SQL.Text := 'DELETE FROM users WHERE iduser = :id';
    Query.ParamByName('id').AsInteger := Req.Params['id'].ToInteger;
    Query.ExecSQL;

    Res.Send('User deleted');
  finally
    Query.Free;
  end;
end;

// Retorna todas as tarefas
procedure OnGetTodoList(Req: THorseRequest; Res: THorseResponse);
var
  Query: TFDQuery;
  Tasks: TJSONArray;
  Task: TJSONObject;
begin
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := Conn;
    Query.SQL.Text := 'SELECT * FROM todolist';
    Query.Open;

    Tasks := TJSONArray.Create;
    while not Query.Eof do
    begin
      Task := TJSONObject.Create;
      Task.AddPair('id', Query.FieldByName('idtodolist').AsInteger);
      Task.AddPair('name', Query.FieldByName('nametodolist').AsString);
      Task.AddPair('task', Query.FieldByName('tasktolist').AsString);
      Task.AddPair('user', Query.FieldByName('usertodolist').AsInteger);
      Task.AddPair('status', Query.FieldByName('statustodolist').AsInteger);
      Tasks.AddElement(Task);
      Query.Next;
    end;

    Res.Send(Tasks.ToString);
  finally
    Query.Free;
  end;
end;

// Retorna uma tarefa por ID
procedure OnGetTodoById(Req: THorseRequest; Res: THorseResponse);
var
  Query: TFDQuery;
  Task: TJSONObject;
begin
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := Conn;
    Query.SQL.Text := 'SELECT * FROM todolist WHERE idtodolist = :id';
    Query.ParamByName('id').AsInteger := Req.Params['id'].ToInteger;
    Query.Open;

    if Query.Eof then
    begin
      Res.Status(THTTPStatus.NotFound).Send('Task not found');
      Exit;
    end;

    Task := TJSONObject.Create;
    Task.AddPair('id', Query.FieldByName('idtodolist').AsInteger);
    Task.AddPair('name', Query.FieldByName('nametodolist').AsString);
    Task.AddPair('task', Query.FieldByName('tasktolist').AsString);
    Task.AddPair('user', Query.FieldByName('usertodolist').AsInteger);
    Task.AddPair('status', Query.FieldByName('statustodolist').AsInteger);

    Res.Send(Task.ToString);
  finally
    Query.Free;
  end;
end;

// Cria uma nova tarefa
procedure OnCreateTodo(Req: THorseRequest; Res: THorseResponse);
var
  Query: TFDQuery;
  Body: TJSONObject;
begin
  Body := TJSONObject.ParseJSONValue(Req.Body) as TJSONObject;
  if not Assigned(Body) then
  begin
    Res.Status(THTTPStatus.BadRequest).Send('Invalid JSON');
    Exit;
  end;

  Query := TFDQuery.Create(nil);
  try
    Query.Connection := Conn;
    Query.SQL.Text := 'INSERT INTO todolist (nametodolist, tasktolist, usertodolist, statustodolist) ' +
                      'VALUES (:name, :task, :user, :status)';
    Query.ParamByName('name').AsString := Body.GetValue<string>('name');
    Query.ParamByName('task').AsString := Body.GetValue<string>('task');
    Query.ParamByName('user').AsInteger := Body.GetValue<Integer>('user');
    Query.ParamByName('status').AsInteger := Body.GetValue<Integer>('status');
    Query.ExecSQL;

    Res.Status(THTTPStatus.Created).Send('Task created');
  finally
    Query.Free;
    Body.Free;
  end;
end;

// Atualiza uma tarefa
procedure OnUpdateTodo(Req: THorseRequest; Res: THorseResponse);
var
  Query: TFDQuery;
  Body: TJSONObject;
begin
  Body := TJSONObject.ParseJSONValue(Req.Body) as TJSONObject;
  if not Assigned(Body) then
  begin
    Res.Status(THTTPStatus.BadRequest).Send('Invalid JSON');
    Exit;
  end;

  Query := TFDQuery.Create(nil);
  try
    Query.Connection := Conn;
    Query.SQL.Text := 'UPDATE todolist SET nametodolist = :name, tasktolist = :task, ' +
                      'usertodolist = :user, statustodolist = :status WHERE idtodolist = :id';
    Query.ParamByName('name').AsString := Body.GetValue<string>('name');
    Query.ParamByName('task').AsString := Body.GetValue<string>('task');
    Query.ParamByName('user').AsInteger := Body.GetValue<Integer>('user');
    Query.ParamByName('status').AsInteger := Body.GetValue<Integer>('status');
    Query.ParamByName('id').AsInteger := Req.Params['id'].ToInteger;
    Query.ExecSQL;

    Res.Send('Task updated');
  finally
    Query.Free;
    Body.Free;
  end;
end;

// Exclui uma tarefa
procedure OnDeleteTodo(Req: THorseRequest; Res: THorseResponse);
var
  Query: TFDQuery;
begin
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := Conn;
    Query.SQL.Text := 'DELETE FROM todolist WHERE idtodolist = :id';
    Query.ParamByName('id').AsInteger := Req.Params['id'].ToInteger;
    Query.ExecSQL;

    Res.Send('Task deleted');
  finally
    Query.Free;
  end;
end;

// Configura as rotas protegidas com base na diretiva UseBasicAuth
procedure SetupProtectedRoutes;
begin
  if UseBasicAuth then
  begin
    Writeln('Configurando rotas protegidas com Autenticação Básica.');
    // Aplica apenas o middleware de autenticação básica
    THorse
      .Use(BasicAuthMiddleware)
      .Get('/protected-route',
        procedure(Req: THorseRequest; Res: THorseResponse)
        begin
          Res.Send('Esta é uma rota protegida por Autenticação Básica!');
        end);

    // Rotas para usuários (protegidas por Autenticação Básica)
    THorse
      .Use(BasicAuthMiddleware)
      .Get('/users', OnGetUsers);

    THorse
      .Use(BasicAuthMiddleware)
      .Get('/users/:id', OnGetUserById);

    THorse
      .Use(BasicAuthMiddleware)
      .Post('/users', OnCreateUser);

    THorse
      .Use(BasicAuthMiddleware)
      .Put('/users/:id', OnUpdateUser);

    THorse
      .Use(BasicAuthMiddleware)
      .Delete('/users/:id', OnDeleteUser);

    // Rotas para tarefas (protegidas por Autenticação Básica)
    THorse
      .Use(BasicAuthMiddleware)
      .Get('/todolist', OnGetTodoList);

    THorse
      .Use(BasicAuthMiddleware)
      .Get('/todolist/:id', OnGetTodoById);

    THorse
      .Use(BasicAuthMiddleware)
      .Post('/todolist', OnCreateTodo);

    THorse
      .Use(BasicAuthMiddleware)
      .Put('/todolist/:id', OnUpdateTodo);

    THorse
      .Use(BasicAuthMiddleware)
      .Delete('/todolist/:id', OnDeleteTodo);
  end
  else
  begin
    Writeln('Configurando rotas protegidas com Autenticação JWT.');
    // Aplica apenas o middleware JWT
    THorse
      .Use(HorseJWT('your-secret-key'))
      .Get('/protected-route',
        procedure(Req: THorseRequest; Res: THorseResponse)
        begin
          Res.Send('Esta é uma rota protegida por Autenticação JWT!');
        end);

    // Rotas para usuários (protegidas por JWT)
    THorse
      .Use(HorseJWT('your-secret-key'))
      .Get('/users', OnGetUsers);

    THorse
      .Use(HorseJWT('your-secret-key'))
      .Get('/users/:id', OnGetUserById);

    THorse
      .Use(HorseJWT('your-secret-key'))
      .Post('/users', OnCreateUser);

    THorse
      .Use(HorseJWT('your-secret-key'))
      .Put('/users/:id', OnUpdateUser);

    THorse
      .Use(HorseJWT('your-secret-key'))
      .Delete('/users/:id', OnDeleteUser);

    // Rotas para tarefas (protegidas por JWT)
    THorse
      .Use(HorseJWT('your-secret-key'))
      .Get('/todolist', OnGetTodoList);

    THorse
      .Use(HorseJWT('your-secret-key'))
      .Get('/todolist/:id', OnGetTodoById);

    THorse
      .Use(HorseJWT('your-secret-key'))
      .Post('/todolist', OnCreateTodo);

    THorse
      .Use(HorseJWT('your-secret-key'))
      .Put('/todolist/:id', OnUpdateTodo);

    THorse
      .Use(HorseJWT('your-secret-key'))
      .Delete('/todolist/:id', OnDeleteTodo);
  end;
end;

begin
  try
    if not UseBasicAuth then
    begin
      // Aplica o middleware CORS
      THorse.Use(CORS);

      // Middleware personalizado para depuração
      THorse.Use(
        procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
        begin
          Writeln('Middleware CORS aplicado'); // Log para depuração
          Next();
        end);

       // Rota de autenticação (pública)
       THorse.Post('/login',
        procedure(Req: THorseRequest; Res: THorseResponse)
              var
                LToken: TJWT;
                LCompactToken: string;
              begin
                LToken := TJWT.Create;
                try
                  // Token claims
                  LToken.Claims.Issuer := 'WiRL REST Library';
                  LToken.Claims.Subject := 'Paolo Rossi';
                  LToken.Claims.Expiration := Now + 1;

                  // Outros claims
                  LToken.Claims.SetClaimOfType<string>('usuario','helio');
                  LToken.Claims.SetClaimOfType<string>('senha','123');

                  // Signing and Compact format creation
                  LCompactToken := TJOSE.SHA256CompactToken('your-secret-key', LToken);
                  Res.Send(LCompactToken)
                finally
                  LToken.Free;
                end;
        end);
    end;

    // Configura a conexão com o SQLite
    SetupConnection;

    // Rota de teste (pública)
    THorse.Get('/ping',
      procedure(Req: THorseRequest; Res: THorseResponse)
      begin
        Res.Send('pong');
      end);

    // Configura as rotas protegidas com base na diretiva UseBasicAuth
    if UseBasicAuth then
    begin
      Writeln('Usando Autenticação Básica como padrão.');
      THorse.Use(BasicAuthMiddleware); // Aplica o middleware de autenticação básica
    end
    else
    begin
      Writeln('Usando Autenticação JWT.');
      THorse.Use(HorseJWT('your-secret-key')); // Aplica o middleware JWT
    end;

    // Configura as rotas protegidas
    SetupProtectedRoutes;

    // Inicia o servidor na porta 9000
    THorse.Listen(9000,
      procedure
      begin
        WriteLn(Format('Servidor Ativo na Porta %d', [THorse.Port]));
        WriteLn('Na Escuta...');
        Readln; // Mantém o console aberto
      end);

  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
