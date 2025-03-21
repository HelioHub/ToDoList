# Aplicação Simples de Lista de Tarefas 

Criar uma aplicação simples de lista de tarefas (To-Do List) com controle de usuário e armazenamento em SQLite.

## Requisitos Mínimos

1. Autenticação de usuário:
	- Criar um sistema de login e cadastro básico utilizando SQLite como banco de dados.
	- O usuário deve ser autenticado antes de acessar a lista de tarefas.
	
2. Gerenciamento de tarefas:
	- Cada usuário pode criar, visualizar, concluir e excluir suas próprias tarefas.
	- As tarefas devem ser salvas no banco de dados.
	
3. Back-end:
	- Criar uma API simples Delphi para gerenciar usuários e tarefas.
	- O banco de dados SQLite deve armazenar as informações.
	
4. Front-end:
	- Criar componentes reutilizáveis.
	- Utilizar React Hooks (useState, useEffect).
	- Código deve estar comentado.


## GitHub

	git init
	git add README.md
	git commit -m "first commit"
	git branch -M main
	git remote add origin git@github.com:HelioHub/ToDoList.git
	git push -u origin main
	
## Entidades 

	Users:
	-----
	idUsers
	LoginUsers
	PasswordUsers
	
	
	ToDoList:
	--------
	idToDoList
	UserToDoList
	NameToDoList
	TaskToDoList
	
	Telas: 
	-----
	
		Access:
		-------
			Login:
			Senha:
			
		Main:
		-----
			Users (só que manipula é o User Master o demais apenas visualiza)
			To-Do List (acessa apenas as tarefas do Login)
			
		
		Users: (INCLUIR | ALTERAR | DELETAR)
		------
		Id | Nome | Login | Status
		
		To-Do List: (INCLUIR | ALTERAR | DELETAR | RELATÓRIO | TRANSFER | CONCLUIR)
		-----------
		Filters:
			- Status
			- Registration
			- User Name
		Id | Registro | Usuário | Tarefa | Descrição Tarefa | Início | Prazo(dias) | Data Estimada Conclusão | Data de Conclusão | Status 
			
## Projeto BackEnd Delphi API Rest usando HORSE 

    O Horse e middlewares, funcionalidades de Autenticação, Tratamento de JSON e etc: 
	
	https://github.com/HashLoad/horse?tab=readme-ov-file
	https://github.com/HashLoad/horse-basic-auth
	https://github.com/HashLoad/jhonson
	https://github.com/HashLoad/horse-jwt 
	https://github.com/paolo-rossi/delphi-jose-jwt
	https://github.com/HashLoad/horse-cors	
	

![## PD](https://github.com/HelioHub/ToDoList/blob/main/Imagens/BackEnd.png)


## Banco de Dados SQLite e DB Browser

	https://www.sqlite.org/download.html
	SQLite version 3.49.1.
	
	https://sqlitebrowser.org/blog/version-3-13-1-released/

## Scheme do Banco de Dados 

![## PD](https://github.com/HelioHub/ToDoList/blob/main/Imagens/DBBrowser.png)

	C:\ToDoList\DBToDoList.db
	
	BEGIN TRANSACTION;
	CREATE TABLE IF NOT EXISTS "todolist" (
		"idtodolist"	INTEGER,
		"nametodolist"	TEXT,
		"tasktolist"	TEXT,
		"usertodolist"	INTEGER,
		"statustodolist"	INTEGER,
		PRIMARY KEY("idtodolist" AUTOINCREMENT),
		CONSTRAINT "fk_user_id" FOREIGN KEY("usertodolist") REFERENCES "users"("iduser")
	);
	CREATE TABLE IF NOT EXISTS "users" (
		"iduser"	INTEGER,
		"loginuser"	TEXT,
		"passworduser"	TEXT,
		PRIMARY KEY("iduser" AUTOINCREMENT)
	);
	COMMIT;
	
	
	SELECT * FROM users;

	SELECT a.idtodolist as id, 
		   b.loginuser as usuario, 
		   a.nametodolist as nometarefa, 
		   a.tasktolist as tarefa, 
		   a.statustodolist as status  
	FROM todolist a 
	INNER JOIN users b ON b.iduser = a.usertodolist;	
	
	
## Estrutura do Projeto API Rest Horse: EndPoints definindo as rotas

![## PD](https://github.com/HelioHub/ToDoList/blob/main/Imagens/EndPoints.png)

	Conexão com o Banco de Dados:
		Configurar a conexão com o SQLite usando o FireDAC.

	Rotas da API:
		Listar todos os usuários (GET /users).
		Buscar um usuário por ID (GET /users/:id).
		Criar um novo usuário (POST /users).
		Atualizar um usuário (PUT /users/:id).
		Excluir um usuário (DELETE /users/:id).
		Listar todas as tarefas (GET /todolist).
		Buscar uma tarefa por ID (GET /todolist/:id).
		Criar uma nova tarefa (POST /todolist).
		Atualizar uma tarefa (PUT /todolist/:id).
		Excluir uma tarefa (DELETE /todolist/:id).

	Retorno em JSON:
		Todas as respostas serão em formato JSON.	
		
		
## Implementação da autenticação JWT usando a tabela USERS na API com Horse

	Install horse-jwt
	https://github.com/HashLoad/horse-jwt 
	
## FrontEnd usando HTML, CSS, JavaScript e React para consumir a API. 

	Estrutura do projeto em componentes reutilizáveis e utilização React Hooks (useState, useEffect) 
	para gerenciar o estado e os efeitos colaterais.	
	
	------------------------
	--Estrutura do Projeto--
	------------------------
		Páginas:
			Home: Página de login.
			Dashboard: Página principal após o login, com opções para acessar o cadastro de usuários e tarefas.
			Cadastro de Usuários: Página para gerenciar o CRUD de usuários.
			Cadastro de Tarefas: Página para gerenciar o CRUD de tarefas.

		Componentes Reutilizáveis:
			Header: Cabeçalho da aplicação.
			Footer: Rodapé da aplicação.
			Grid: Componente para exibir dados em uma tabela.
			Form: Componente para formulários de cadastro e edição.

		React Hooks:
			useState: Para gerenciar o estado dos componentes.
			useEffect: Para carregar dados da API quando o componente for montado.	
		
	---------------------------------
	--Configuração do Projeto React--
	---------------------------------
	Instalação do Node.js: https://nodejs.org/.
	Node.js v22.14.0
	
	Criar projeto React:
		npx create-react-app frontend
		cd frontend
		
	Instale as dependências necessárias:
		npm install axios react-router-dom
			axios: Para fazer requisições HTTP à API.
			react-router-dom: Para gerenciar as rotas da aplicação.

	Inicie o servidor de desenvolvimento:
		npm start
		
	---------------------------------
	--Estrutura de Pastas--
	---------------------------------
	Na pasta src, estrutura de pastas e arquivos:
		src/
		├── components/ 
		│   ├── Header.js
		│   ├── Footer.js
		│   ├── Grid.js
		│   ├── Form.js
		├── pages/
		│   ├── Home.js
		│   ├── Dashboard.js
		│   ├── Users.js
		│   ├── Tasks.js
		├── App.js
		├── index.js
			
	O FrontEnd consome a API criada e implementa um CRUD completo para usuários e tarefas.

	Os componentes são reutilizáveis e o estado é gerenciado com React Hooks.	
	
## 2(duas) Autenticações conforme Variável UseBasicAuth no Back-end:

	Uso da Variável UseBasicAuth:
		A variável UseBasicAuth controla qual middleware de autenticação será aplicado globalmente:

		Se UseBasicAuth for True, o middleware de autenticação básica (BasicAuthMiddleware) será aplicado.
			Todas as rotas protegidas usarão autenticação básica.
			
		Se UseBasicAuth for False, o middleware JWT (HorseJWT) será aplicado.
			Todas as rotas protegidas usarão autenticação JWT.
		

## Login, Painel, Views e CRUDs criados dos Users (Usuários) e ToDoList (Lista de Tarefas): 

	----Login----

![## PD](https://github.com/HelioHub/ToDoList/blob/main/Imagens/Login.png)

	----Painel----
		Cadastro de Usuários
		Cadastro de Tarefas

![## PD](https://github.com/HelioHub/ToDoList/blob/main/Imagens/Dashboard.png)

	----Cadastro_de_Usuários----

![## PD](https://github.com/HelioHub/ToDoList/blob/main/Imagens/Users.png)
		
	----Cadastro_de_Tarefas----

![## PD](https://github.com/HelioHub/ToDoList/blob/main/Imagens/Tasks.png)
		
		
		