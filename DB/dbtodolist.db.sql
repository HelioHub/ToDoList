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
	
