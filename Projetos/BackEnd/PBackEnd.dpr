program PBackEnd;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  Horse,
  FireDAC.Stan.Def, // Adiciona suporte ao FireDAC
  FireDAC.Phys.SQLite, // Driver do SQLite
  FireDAC.DApt, // Suporte para consultas SQL
  FireDAC.Stan.Async, // Suporte a operações assíncronas
  FireDAC.Comp.Client, // Componentes do FireDAC (TFDConnection, TFDQuery, etc.)
  Horse.JWT, // Middleware JWT
  JOSE.Core.JWT, // Para criar tokens JWT
  JOSE.Core.Builder; // Para gerar tokens JWT

var
  Conn: TFDConnection;


// Método para autenticar o usuário e gerar um token JWT
procedure OnAuthenticateUser(Req: THorseRequest; Res: THorseResponse);
var
  Query: TFDQuery;
  Body: TJSONObject;
  Login, Password: string;
  Token: TJWT;
begin
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

    // Verifica as credenciais no banco de dados
    Query := TFDQuery.Create(nil);
    try
      Query.Connection := Conn; // Usa a conexão já configurada
      Query.SQL.Text := 'SELECT * FROM users WHERE loginuser = :login AND passworduser = :password';
      Query.ParamByName('login').AsString := Login;
      Query.ParamByName('password').AsString := Password;
      Query.Open;

      if Query.Eof then
      begin
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
      Query.Free;
    end;
  finally
    Body.Free;
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

begin
  try
    // Configura a conexão com o SQLite
    SetupConnection;

    // Rota de autenticação
    THorse.Post('/login', OnAuthenticateUser);

    // Middleware JWT para proteger rotas
    // THorse.Use(HorseJWT('your-secret-key'));

    // Rota protegida
    THorse.Get('/protected-route',
      procedure(Req: THorseRequest; Res: THorseResponse)
      begin
        try
          Res.Send('Esta é uma rota protegida!');
        except
          on E: Exception do
          begin
            Res.Status(THTTPStatus.InternalServerError).Send('Internal Server Error: ' + E.Message);
          end;
        end;
      end);


    { Rota protegida (exige autenticação JWT)
    THorse.Get('/protected-route', HorseJWT('your-secret-key'),
      procedure(Req: THorseRequest; Res: THorseResponse)
      begin
        try
          Res.Send('Esta é uma rota protegida!');
        except
          on E: Exception do
          begin
            Res.Status(THTTPStatus.InternalServerError).Send('Internal Server Error: ' + E.Message);
          end;
        end;
      end);
     }


    // Rotas para usuários
    THorse.Get('/users', OnGetUsers);
    THorse.Get('/users/:id', OnGetUserById);
    THorse.Post('/users', OnCreateUser);
    THorse.Put('/users/:id', OnUpdateUser);
    THorse.Delete('/users/:id', OnDeleteUser);

    // Rotas para tarefas
    THorse.Get('/todolist', OnGetTodoList);
    THorse.Get('/todolist/:id', OnGetTodoById);
    THorse.Post('/todolist', OnCreateTodo);
    THorse.Put('/todolist/:id', OnUpdateTodo);
    THorse.Delete('/todolist/:id', OnDeleteTodo);
    THorse.Get('/ping',
      procedure(Req: THorseRequest; Res: THorseResponse)
      begin
        Res.Send('pong');
      end);

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

