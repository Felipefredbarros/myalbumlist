# MyAlbumList

Um rastreador de escuta de álbuns no estilo MyAnimeList. Você mantém uma biblioteca pessoal de álbuns classificados por status (escutando, completo, em pausa, abandonado, planejo escutar), dá notas de 1 a 10, conta relistens e monta seus top 10.

O diferencial é o **progresso no nível da faixa**: o sistema guarda em qual faixa a escuta parou e quais faixas são suas favoritas dentro de cada álbum. Os metadados (artista, capa, ano, tracklist e gêneros) vêm do [MusicBrainz](https://musicbrainz.org/) e ficam guardados localmente depois da primeira busca.

> Projeto pessoal em desenvolvimento ativo. Veja o [status](#status).

## Stack

| Camada | Tecnologia |
|---|---|
| Backend | Java 21, Spring Boot 4.1.1 (Web MVC, Data JPA, Validation) |
| Banco de dados | PostgreSQL 16 |
| Schema | Flyway (migrations versionadas, `ddl-auto=validate`) |
| Ambiente local | Docker Compose |
| Front-end | Angular (planejado, Fase 3) |

## Pré-requisitos

- **JDK 21**: precisa ser o JDK, não só o JRE, porque o Maven precisa do `javac`. Testado com Eclipse Temurin 21.
- **Docker** com Compose. No Windows: Docker Desktop com backend WSL 2.
- **Git**

Não precisa instalar o Maven: o projeto usa o Maven Wrapper (`mvnw` / `mvnw.cmd`).

## Como rodar

```bash
# 1. Clonar
git clone https://github.com/Felipefredbarros/myalbumlist.git
cd myalbumlist

# 2. Subir o PostgreSQL
docker compose up -d

# 3. Rodar a API
cd api
./mvnw spring-boot:run        # Linux/macOS
.\mvnw.cmd spring-boot:run    # Windows
```

A API sobe em `http://localhost:8080`. Na primeira execução, o Flyway cria todas as tabelas a partir das migrations em `api/src/main/resources/db/migration`. Não é preciso nenhum script manual.

### Observações

- O Postgres é exposto na porta **5433** (e não na 5432) para não conflitar com outra instância local. Credenciais de desenvolvimento: usuário `mal`, senha `mal_dev`, banco `myalbumlist`.
- O container não sobe sozinho depois de reiniciar a máquina. Rode `docker compose up -d` no início de cada sessão.
- Para abrir o banco pelo terminal:
  ```bash
  docker exec -it mal-postgres psql -U mal -d myalbumlist
  ```

## Estrutura

```
myalbumlist/
├── compose.yaml          # PostgreSQL 16 para desenvolvimento
└── api/                  # Spring Boot
    └── src/main/
        ├── java/com/myalbumlist/api/
        │   └── catalog/  # módulo de catálogo (artista, álbum, faixa)
        └── resources/db/migration/   # migrations Flyway
```

A API é um **monolito modular**: um pacote por domínio (`catalog`, `genre`, `library`, `metadata`, `rating`, `identity`). Entidades e repositories são package-private, e um módulo só fala com outro pela interface de serviço pública. A fronteira é imposta pelo compilador, não por convenção.

## Decisões de design

Algumas escolhas que valem destacar (o registro completo está em [docs/decisoes](docs/decisoes/README.md)):

- **O banco é dono do schema.** O Flyway versiona cada mudança e o Hibernate só valida (`ddl-auto=validate`). Assim, o schema nunca diverge silenciosamente do código.
- **Gênero é um grafo, não uma árvore.** City pop deriva de pop, funk e AOR ao mesmo tempo. A hierarquia fica numa tabela de ligação (`genre_parent`) e é consultada com CTE recursiva.
- **Álbum = release group do MusicBrainz.** Edições, remasters e vinis do mesmo disco não aparecem duplicados.
- **Local primeiro.** A busca consulta o Postgres antes da API externa. Cada álbum importado passa a ser local, e o sistema vira um cache que cresce com o uso.
- **Schema multiusuário desde o início**, mesmo com o v1 sendo de uso pessoal.

## Documentação

- [Arquitetura](docs/arquitetura.md): módulos, modelo de dados, regras de negócio e integrações.
- [Decisões](docs/decisoes/README.md): o porquê de cada escolha.
- [Ambiente](docs/ambiente.md): ferramentas, comandos de toda sessão e erros comuns.
- [Fluxo de trabalho](CONTRIBUTING.md): issues, branches, commits e PRs.

## Status

- [x] **Fase 0**: ambiente, Flyway e esqueleto da aplicação
- [ ] **Fase 1**: catálogo e importação do MusicBrainz *(em andamento)*
- [ ] **Fase 2**: biblioteca do usuário (status, notas, progresso de faixa, top 10)
- [ ] **Fase 3**: front-end Angular, mobile-first
- [ ] **Fase 4**: multiusuário, ranking global e deploy

Commits seguem [Conventional Commits](https://www.conventionalcommits.org/).
