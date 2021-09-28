# Inteligência Competitiva (INF1803) @ PUC-Rio

Matéria lecionada pela professora Ana Carolina Letichevsky no 2º período de 2021.

# Programas requeridos

* Git LFS >= 2.13.3
* R >= 3.4.4
* SQLite3 >= 3.22.0

# Pacotes R requeridos

* DBI
* RSQLite
* rgdal

# Configuração

Basta rodar o script Bash de configuração. Caso seja necessário, você pode editar variáveis de configuração como o nome do programa SQLite no seu sistema (por padrão, assume-se que se chama `sqlite3`). Para isso, edite a variável `SQLITE` no script Bash.

```sh
$ chmod +x src/setup.sh
$ ./src/setup.sh
Using sqlite3...
Deleting already existing database data/covid.db...
Creating database data/covid.db from script src/dbcreate.sql...
Done in 13.269610434 s.
```
