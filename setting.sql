-- CREATE DATABASE if not exists app with OWNER = postgres;
CREATE TABLE if not exists memos ( id serial not null primary key, content text );
