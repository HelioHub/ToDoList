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
	NameUsers
	LoginUsers
	PasswordUsers
	StatusUsers (M-Master; N-Normal)
	
	
	ToDoList:
	--------
	idToDoList
	DateRegToDoList
	UserToDoList
	NameToDoList
	TaskToDoList
	DateStartToDoList
	TermToDoList
	DateEndToDoList
	StatusToDoList (P-Pending| S-Started| C-Completed)
	
	Telas: 
	-----
	
		Access:
		-------
			Login:
			Password:
			
		Main:
		-----
			Users (só que manipula é o User Master o demais apenas visualiza)
			To-Do List (acessa apenas as tarefas do Login)
			
		
		Users: (INSERT | UPDATE | DELETE)
		------
			Id | Name | Login | Status
		
		To-Do List: (INSERT | UPDATE | DELETE | REPORT | TRANSFER | CONCLUDE)
		-----------
			Filters:- Status
					- Registration
					- User Name
			Id | Registration | User Name | Task Name | Task | Start | Term | Estimated Completion Date | Completion Date | Task Status 
			
	

## Projeto BackEnd Delphi API Rest usando HORSE 

![## PD](https://github.com/HelioHub/ToDoList/blob/main/Imagens/BackEnd.png)





	
	