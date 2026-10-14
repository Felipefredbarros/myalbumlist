# Ambiente de desenvolvimento

## Ferramentas

| Ferramenta | Para quê | Instalação no Windows |
|---|---|---|
| Git | Versionamento | `winget install Git.Git` |
| Eclipse Temurin 21 (JDK) | Compilar e rodar a API | `winget install EclipseAdoptium.Temurin.21.JDK` |
| Docker Desktop (WSL 2) | PostgreSQL em container | `winget install Docker.DockerDesktop` |
| IntelliJ IDEA | IDE (abrir a pasta `api/`) | jetbrains.com/idea |
| DBeaver Community | Ver o banco com interface | `winget install DBeaver.DBeaver.Community` |
| Postman | Testar os endpoints | `winget install Postman.Postman` |

Configuração do Git recomendada no Windows: `git config --global core.autocrlf true`.

## Comandos de toda sessão

```powershell
# 1. Abrir o Docker Desktop e esperar "Engine running"

# 2. Subir o banco (não sobe sozinho depois de reiniciar a máquina)
cd C:\projetos\myalbumlist
docker compose up -d

# 3. Rodar a API (ou pelo botão Run do IntelliJ)
cd api
.\mvnw.cmd spring-boot:run

# 4. Rodar os testes (o Docker precisa estar rodando; não depende do compose)
.\mvnw.cmd verify

# 5. Abrir o banco pelo terminal
docker exec -it mal-postgres psql -U mal -d myalbumlist
#    \dt          lista tabelas
#    \d tabela    descreve colunas, índices e constraints
#    q            sai do paginador
#    \q           sai do psql
```

Conexão no DBeaver: host `localhost`, porta **5433**, banco `myalbumlist`, usuário `mal`, senha `mal_dev`.

## Erros já vistos e o que significam

| Mensagem | Causa |
|---|---|
| `Connection to localhost:5433 refused` | Container parado (`docker compose up -d`), ou ferramenta apontando para a porta errada. |
| `Connection to localhost:5432 refused` | A ferramenta usou a porta padrão do Postgres. O projeto usa **5433**. |
| `Port 8080 was already in use` | Outra instância da API ainda rodando. Ctrl+C no terminal dela, ou `netstat -ano \| findstr :8080` e `taskkill /PID <pid> /F` (confira antes com `tasklist` que é um `java.exe`). |
| `no configuration file provided: not found` | `docker compose` rodado fora da raiz do projeto, onde está o `compose.yaml`. |
| `release version 21 not supported` | `JAVA_HOME` apontando para um JRE sem `javac`, ou para um JDK antigo. Deve apontar para o JDK 21. |
| `Schema-validation: missing column` | A entidade JPA não bate com a tabela. É o `ddl-auto=validate` fazendo o trabalho dele: a correção vai numa migration nova, nunca alterando a anterior. |
| `Validate failed: Migration checksum mismatch` | Uma migration já aplicada foi editada. Desfaça a edição e crie uma migration nova. |

**Como ler stack trace do Spring:** vá até o último `Caused by:` da pilha. Ali está a causa real; tudo acima é o Spring explicando quais beans não nasceram por consequência. Em erro de banco, o SQL State classifica: `08` é falha de conexão, `23` é violação de constraint, `42` é erro de sintaxe ou objeto inexistente.
