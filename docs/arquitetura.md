# Arquitetura do MyAlbumList

Documento vivo. Ele descreve **como** o sistema é construído. O **porquê** de cada escolha está em [`decisoes/`](decisoes/).

Migrado do *Documento de Arquitetura v0.2* (PDF, 21/08/2026), que foi a última versão em PDF.

---

## 1. Visão do produto

O MyAlbumList é um rastreador de escuta de álbuns no modelo do MyAnimeList: o usuário mantém uma biblioteca pessoal de álbuns classificados por status, dá notas, monta rankings e acompanha o próprio histórico de escuta.

### 1.1 Problema que resolve

Existem sites de nota de álbum (RateYourMusic, Album of the Year) e existem rastreadores de escuta (Last.fm). Não existe um produto que combine a mecânica de status do MyAnimeList (escutando, completo, on hold, dropped, planejo escutar) com controle de progresso no nível da faixa. Esse é o diferencial central e a razão técnica pela qual a fonte de metadados precisa fornecer tracklist completa.

### 1.2 Escopo do v1 (uso pessoal)

- Buscar e importar álbuns de uma base externa, com artista, capa, ano e tracklist.
- Classificar álbuns nos cinco status.
- Registrar em qual faixa a escuta parou.
- Dar nota de 1 a 10 em álbuns.
- Contar relistens.
- Marcar faixas favoritas dentro de um álbum.
- Montar top 10 de álbuns, artistas e faixas.
- Filtrar a biblioteca por gênero.

### 1.3 Fora de escopo no v1

- Cadastro público, login e perfis de outros usuários (planejado para a Fase 4).
- Ranking global de álbuns com média entre usuários.
- Resenhas em texto, comentários, seguir usuários.
- Aplicativo mobile nativo.
- Integração com scrobbling automático (Last.fm, Spotify).

### 1.4 Semântica: álbum não é anime

Os cinco status do MyAnimeList foram desenhados para obras seriadas consumidas ao longo de semanas. Um álbum dura 45 minutos. A adaptação adotada:

| Status | Significado no MyAlbumList |
|---|---|
| `LISTENING` | Na rotação atual: o álbum que você está digerindo nesta semana. Não significa "tocando agora". |
| `COMPLETED` | Ouvido por inteiro pelo menos uma vez, com atenção. |
| `ON_HOLD` | Começou, parou no meio, pretende voltar. |
| `DROPPED` | Começou e não pretende terminar. |
| `PLAN_TO_LISTEN` | Fila de escuta. |

Duas consequências de modelagem que diferenciam o produto de um clone literal do MAL:

- **Relisten é a norma, não a exceção.** Ao contrário de rewatch em anime, reouvir álbum é o comportamento padrão. O contador de relistens é um dado de primeira classe.
- **Faixa favorita > episódio favorito.** Marcar faixas dentro do álbum tem muito mais uso real do que o equivalente em anime. Por isso está no v1.

---

## 2. Arquitetura de módulos

Monolito modular. Um pacote raiz por domínio sob `com.myalbumlist.api`. A regra é: **um módulo só acessa outro pela interface de serviço pública desse outro**, nunca pelo repository nem pela entidade JPA diretamente.

| Módulo | Responsabilidade | Depende de |
|---|---|---|
| `identity` | Usuário e, a partir da Fase 4, autenticação. Expõe `CurrentUserProvider`. | — |
| `catalog` | Artista, álbum, faixa. Leitura pública; escrita apenas pelo `metadata`. | — |
| `metadata` | Clientes de APIs externas, rate limiting, importação e persistência no catálogo. Isolado atrás da interface `MetadataProvider`. | `catalog`, `genre` |
| `genre` | Vocabulário de gêneros, grafo de hierarquia, consulta recursiva de descendentes. | — |
| `library` | Núcleo do produto: entradas do usuário, status, progresso de faixa, relistens, favoritos. | `catalog`, `identity` |
| `rating` | Notas, estatísticas agregadas, ranking bayesiano. | `catalog`, `identity` |

A separação entre `metadata` e `catalog` é a mais importante do desenho. Ela garante que trocar de fonte externa, ou adicionar uma segunda, não toque em nada além de uma implementação de interface.

### 2.1 Fluxo de importação

**Regra inviolável:** nenhuma chamada a API externa acontece dentro do request do usuário final em caminho quente. O MusicBrainz limita a ~1 requisição por segundo; o Discogs a 60 por minuto.

1. Usuário busca por texto.
2. Sistema consulta o Postgres local primeiro.
3. Se houver resultado suficiente, responde e encerra.
4. Se não, consulta a fonte externa respeitando o rate limiter.
5. Persiste artista, álbum, faixas e gêneros localmente.
6. A partir daí, aquele álbum é local e nunca mais depende da API.

O efeito é que o sistema vira um cache que cresce com o uso: latência baixa, independência de disponibilidade externa, e o volume de chamadas externas cai com o tempo.

### 2.2 O ponto de costura do multiusuário

Single-user é uma decisão de interface, não de modelo de dados (ver [D-07](decisoes/0000-registro-inicial.md#nota-sobre-d-07)). O código consulta o usuário atual por uma interface única, `CurrentUserProvider`, com um método que devolve o `UUID` do usuário corrente:

- Fases 1 a 3: uma implementação fixa, que sempre devolve o UUID do dono, semeado em `app_user`.
- Fase 4: substituída por uma implementação que lê o `SecurityContext`. Nenhum service, repository ou controller precisa mudar.

**Nenhuma camada de serviço recebe `userId` como parâmetro vindo do controller.** Todas consultam o `CurrentUserProvider`. Essa é a regra que torna a Fase 4 barata.

---

## 3. Modelo de dados

Todas as chaves primárias são `uuid`. Nomes de tabela em `snake_case` e singular. `user` é palavra reservada no PostgreSQL, então a tabela se chama `app_user`.

### 3.1 Catálogo (V1, aplicada)

```
artist (id, mbid UK, name, sort_name, image_url, created_at)

album  (id, mbid UK, artist_id FK, title, release_year,
        cover_url, track_count, created_at)
       CHECK album_ano_plausivel: release_year entre 1860 e 2100
       INDEX idx_album_artist em artist_id

track  (id, album_id FK ON DELETE CASCADE, track_number,
        title, duration_ms)
       UNIQUE track_numero_unico (album_id, track_number)
       CHECK track_numero_positivo, track_duracao_positiva
```

O campo `album.mbid` guarda o MBID do **release group**, conforme D-08.

**Índice em chave estrangeira.** O PostgreSQL cria índice automaticamente para `PRIMARY KEY` e `UNIQUE`, mas não para chave estrangeira. Daí o índice explícito em `album.artist_id`. Já `track.album_id` dispensa índice próprio, porque a constraint `UNIQUE (album_id, track_number)` criou um índice cuja coluna da esquerda é justamente `album_id`.

**Sobre `ON DELETE`:** `track → album` usa `CASCADE` (faixa não existe sem álbum). `album → artist` fica no padrão `RESTRICT` (apagar artista com discografia deve ser recusado). O critério é sempre: essa linha faz sentido sozinha?

### 3.2 Gênero (V2, aplicada)

```
genre        (id, mbid UK nullable, name, slug UK, created_at)
             CHECK genre_slug_formato: slug bate ^[a-z0-9]+(-[a-z0-9]+)*$

genre_parent (genre_id FK, parent_id FK,
              PRIMARY KEY (genre_id, parent_id),
              CHECK genre_parent_sem_autorreferencia)
             INDEX idx_genre_parent_pai em parent_id

genre_alias  (id, genre_id FK, external_name, external_source,
              UNIQUE genre_alias_unico (external_source, external_name))
             INDEX idx_genre_alias_genero em genre_id

album_genre  (album_id FK, genre_id FK,
              is_primary boolean DEFAULT false,
              vote_count int DEFAULT 0,
              PRIMARY KEY (album_id, genre_id),
              CHECK album_genre_votos_nao_negativos)
             INDEX idx_album_genre_genero em genre_id
```

**`genre.mbid` aceita `NULL`**, diferente de `album.mbid`. Gênero criado à mão ou vindo do Discogs não tem MBID. No PostgreSQL, `UNIQUE` permite múltiplos `NULL`: nulos são tratados como desconhecidos, e desconhecidos não são iguais entre si. A constraint garante unicidade apenas entre os que têm MBID.

**O `slug` é o mecanismo de deduplicação entre fontes.** "city pop" do MusicBrainz e "City Pop" do Discogs colapsam no mesmo `city-pop`. O `CHECK` com regex impede que um slug malformado fure essa lógica.

**`genre_alias`** permite normalizar vocabulários diferentes para um único gênero interno. Sem essa tabela, adicionar uma segunda fonte de gênero vira retrabalho de código em vez de inserção de linhas.

**Os índices "invertidos".** A chave primária de `genre_parent` responde "quem são os pais de X", mas a pergunta oposta, "quem são os filhos de Y", filtra por `parent_id`, a coluna da direita, que o índice composto não atende. Daí o índice extra. Mesma lógica em `album_genre`: a PK serve "quais gêneros deste álbum", o índice extra serve "quais álbuns deste gênero", que é o filtro da biblioteca.

**`is_primary`** resolve a apresentação: na página do álbum, um ou dois gêneros aparecem em destaque e o resto como secundário. Na importação, os gêneros com `vote_count` alto viram primários.

### 3.3 Biblioteca do usuário (Fase 2, planejada)

```
app_user (id, username UK, email UK, password_hash, created_at)

user_album_entry (
    id, user_id FK, album_id FK,
    status,               -- LISTENING, COMPLETED, ON_HOLD, DROPPED, PLAN_TO_LISTEN
    score,                -- smallint 1..10, nullable (D-14, D-15)
    current_track_id FK,  -- onde a escuta parou, nullable
    listen_count,         -- relistens, default 0
    started_at, finished_at, notes,
    created_at, updated_at,
    UNIQUE (user_id, album_id)
)

user_track_favorite (user_id FK, track_id FK,
                     PRIMARY KEY (user_id, track_id))

user_favorite (id, user_id FK, item_type, item_id, position,
               UNIQUE (user_id, item_type, position))
```

`user_album_entry` carrega praticamente todo o valor do sistema. A constraint `UNIQUE (user_id, album_id)` não é opcional. Índices necessários desde o início: `(user_id, status)` e `(album_id)`.

`user_favorite` usa referência polimórfica (`item_type` + `item_id`) para resolver os três top 10 (álbum, artista e faixa) numa tabela só. O custo é não haver chave estrangeira real. Para uso pessoal a troca compensa; se incomodar, dividir em três tabelas.

### 3.4 Estatísticas de nota (Fase 4, planejada)

```
album_stats (album_id PK FK, rating_count, rating_sum,
             rating_avg, bayesian_score, updated_at)
```

Tabela de agregação, para que o ranking não faça `AVG()` sobre a tabela inteira a cada carregamento. Só ganha uso real na Fase 4.

### 3.5 Consulta recursiva de gênero

```sql
WITH RECURSIVE sub AS (
    SELECT id FROM genre WHERE slug = 'pop'
  UNION
    SELECT gp.genre_id FROM genre_parent gp
      JOIN sub ON gp.parent_id = sub.id
)
SELECT a.* FROM album a
  JOIN album_genre ag ON ag.album_id = a.id
 WHERE ag.genre_id IN (SELECT id FROM sub);
```

**Use `UNION` e não `UNION ALL`.** O `UNION` deduplica e protege contra loop infinito caso surja um ciclo no grafo. Verificado na prática: com um ciclo gravado de propósito, a consulta continua terminando, porque o gênero repetido já está no conjunto e é descartado.

Porém a consulta não quebrar não significa que o dado esteja certo. Com um ciclo, perguntar "quem deriva de City Pop?" passaria a responder "Pop", e o filtro de city pop traria toda a árvore do pop. A consulta não falha; ela mente. Conforme D-19, a defesa é processual: a hierarquia vem de seed curado em migration, revisado antes do commit, e ninguém insere em `genre_parent` pela API.

Se um dia a recursão pesar, o padrão é materializar `genre_ancestor (genre_id, ancestor_id, depth)`, recalculada quando a hierarquia muda.

---

## 4. Regras de negócio

### 4.1 Transições de status

Não há máquina de estados restritiva: qualquer status pode ir para qualquer outro. O que existe são efeitos colaterais:

| Transição | Efeito |
|---|---|
| qualquer → `LISTENING` | Preenche `started_at` se estiver nulo. |
| qualquer → `COMPLETED` | Preenche `finished_at`. Incrementa `listen_count`. Limpa `current_track_id`. A UI oferece o campo de nota, sem exigir (D-14). |
| `COMPLETED` → `LISTENING` | É um relisten: limpa `current_track_id` (D-17). Sem histórico de sessões anteriores. |
| qualquer → `DROPPED` | Preserva `current_track_id`: saber onde desistiu é informação útil. |
| qualquer → `PLAN_TO_LISTEN` | Limpa `current_track_id`, `started_at` e `finished_at`. Preserva `score`. |

### 4.2 Progresso de faixa

`current_track_id` aponta para uma faixa **do mesmo álbum** da entrada. Validar isso no serviço: o banco não consegue garantir sozinho sem trigger. Marcar uma faixa como atual não muda o status automaticamente; a decisão é explícita do usuário.

### 4.3 Nota e ranking global

Nota individual: inteiro de 1 a 10 (D-15), opcional (D-14), por álbum. No banco, `smallint` com `CHECK (score IS NULL OR score BETWEEN 1 AND 10)`; no Java, `@Min(1) @Max(10)` no DTO. Os dois: o banco para garantir, o Java para dar mensagem decente.

O ranking global usa média bayesiana:

```
score = (v / (v + m)) * R + (m / (v + m)) * C

R = média de notas do álbum
v = quantidade de notas do álbum
C = média global de todas as notas do sistema
m = mínimo de votos para peso total (começar com 5 ou 10)
```

Álbuns com poucas notas são puxados na direção da média geral até acumularem volume. Recalcular `album_stats` por `@Scheduled`. No v1 single-user o ranking bayesiano é inútil (só existe um votante); o "ranking" é a sua lista ordenada por nota.

### 4.4 Top 10

Listas ordenadas manualmente, independentes das notas. Três tipos: álbum, artista e faixa. `position` é 1..N com `UNIQUE (user_id, item_type, position)`. Reordenar exige transação, já que envolve várias linhas.

---

## 5. Integrações externas

### 5.1 MusicBrainz (fonte primária)

| | |
|---|---|
| Base | `https://musicbrainz.org/ws/2/` |
| Autenticação | Nenhuma para leitura |
| Rate limit | ~1 req/s; `User-Agent` identificando a aplicação e um contato é obrigatório |
| Formato | JSON com `?fmt=json` |

```
# Buscar álbum
/release-group?query=artist:"Ado" AND releasegroup:"Kyogen"&fmt=json

# Detalhe do álbum, com gêneros
/release-group/{mbid}?inc=artists+genres+url-rels&fmt=json

# Tracklist (vem via release, não via release-group)
/release?release-group={mbid}&inc=recordings&fmt=json
```

**Pegadinha da tracklist:** o release group não carrega faixas. É preciso escolher um release representativo do grupo (em geral o mais antigo, ou o de país mais relevante) e ler as recordings dele. Essa escolha é uma regra de negócio do módulo `metadata` e precisa ser explícita e testada.

**Gêneros** vêm como tags votadas pela comunidade, em lista plana, com `count`. A hierarquia de subgênero existe no banco do MusicBrainz mas não é exposta pela API. Ela precisa ser obtida de outra forma (raspagem única de `/genre/{mbid}`, dump do banco, ou Discogs) e commitada como migration.

### 5.2 Discogs (complemento condicional, Fase 4)

| | |
|---|---|
| Base | `https://api.discogs.com/` |
| Autenticação | Token pessoal ou OAuth |
| Rate limit | 60 req/min autenticado, 25 sem; `User-Agent` obrigatório; tratar 429 |
| Dump offline | `data.discogs.com`, licença CC0 |

Dois papéis: **andaime da hierarquia** (~15 `genres` amplos e ~600 `styles`, dois níveis prontos) e **preenchimento de lacuna** quando o MusicBrainz retorna `genres: []`. O casamento entre as bases usa o relacionamento de URL do release group para o master do Discogs (`inc=url-rels`), sem busca por nome.

**Critério de adoção:** ao fim da Fase 2, medir o percentual de álbuns da biblioteca real sem gênero vindo do MusicBrainz. Se ficar abaixo de 15%, não integrar o Discogs.

---

## 6. Convenções

- **Migrations:** nunca editar uma migration já aplicada. Sempre criar uma nova. (O Flyway guarda o checksum de cada uma em `flyway_schema_history` e recusa subir se o arquivo mudar.)
- **Nomenclatura no banco:** `snake_case`, tabelas no singular, chaves estrangeiras como `{tabela}_id`.
- **Palavras reservadas:** evitar nomes que o PostgreSQL já usa, daí `app_user` e `track_number`, e não `user` e `position`.
- **Constraints nomeadas:** sempre dar nome explícito (`album_ano_plausivel`), nunca deixar o banco gerar. O nome aparece na mensagem de erro e é o que o Java usa para escolher a mensagem ao usuário.
- **Visibilidade:** entidades e repositories são package-private. Só o service e os DTOs do módulo são `public`. É o compilador impondo a fronteira, não a disciplina.
- **Entre módulos:** referência por `UUID`, nunca por objeto. `UserAlbumEntry` tem `albumId`, não `Album`.
- **Fetch:** todo `@ManyToOne` com `fetch = FetchType.LAZY` explícito. O padrão da JPA é `EAGER` e causa N+1.
- **Construtores:** construtor sem argumentos `protected` (exigência da JPA) e construtor real exigindo os campos obrigatórios. Objeto não deve poder nascer inválido.
- **`equals` / `hashCode`:** por `id`, com guarda `id != null`. Sem ela, duas entidades novas e distintas se consideram iguais.
- **API:** prefixo `/api`, substantivos no plural, verbos HTTP semânticos.
- **DTOs:** entidade JPA nunca cruza a fronteira do controller.
- **Segredos:** tokens e senhas por variável de ambiente, nunca no `application.properties` versionado. Exceção consciente: a senha do Postgres local (`mal_dev`), que é descartável.
- **Datas:** `timestamptz` no banco, UTC na aplicação, conversão só na apresentação.
- **Git:** [Conventional Commits](https://www.conventionalcommits.org/); uma branch por issue; PR com squash merge na `main`. Ver [CONTRIBUTING.md](../CONTRIBUTING.md).

---

## 7. Fases

O planejamento detalhado de cada fase (entregas e critério de pronto) vive nas **Milestones e Issues do GitHub**. Resumo:

| Fase | Objetivo | Critério de pronto |
|---|---|---|
| 0. Ambiente | Esqueleto rodando de ponta a ponta. | `./mvnw verify` passando do zero com banco em container. |
| 1. Catálogo e metadados | Buscar um álbum por texto e tê-lo persistido localmente. | 20 álbuns variados (5 obscuros, 5 não-ocidentais) importados corretamente. |
| 2. Biblioteca | O sistema já é útil, ainda que só via Postman. | Biblioteca real com 50+ álbuns em status variados e filtros corretos. |
| 3. Front-end Angular | Interface utilizável no celular. | Uma semana de uso real pelo celular sem abrir o Postman. |
| 4. Multiusuário e social | De "minha planilha" para "site". | Um segundo usuário real cadastra álbuns e o ranking reflete os dois. |
