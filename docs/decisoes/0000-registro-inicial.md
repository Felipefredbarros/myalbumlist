# 0000. Registro inicial (D-01 a D-20)

- **Status:** aceitas, exceto D-12, substituída por [0021](0021-docker-no-lugar-do-podman.md)
- **Data:** 2026-08-21 (documento de arquitetura v0.2)

Decisões tomadas antes da migração para Markdown, mantidas com a numeração original para não quebrar referências.

| ID | Decisão | Escolha | Justificativa |
|---|---|---|---|
| D-01 | Linguagem e framework do backend | Java 21 / Spring Boot 4.1.1 | Stack já dominada. O domínio é CRUD relacional com agregação, exatamente onde Spring Data JPA é forte. O Boot 4 exige Java 21 como mínimo e renomeou starters (`webmvc` no lugar de `web`, `spring-boot-starter-flyway` obrigatório). Atenção: quase todo tutorial disponível ainda é de Boot 3. |
| D-02 | Framework do front-end | Angular (v20+) | Casa bem com o perfil de backend Java. Usar standalone components e signals; evitar NgModules. |
| D-03 | Banco de dados | PostgreSQL 16 | Precisa de CTE recursiva (hierarquia de gênero), agregação e índices de texto. |
| D-04 | Versionamento de schema | Flyway | Migrations versionadas desde a primeira tabela, sem exceção. O banco é dono do schema; o Hibernate só valida (`ddl-auto=validate`), o que impede o schema de divergir em silêncio. |
| D-05 | Fonte primária de metadados | MusicBrainz | Única fonte aberta que fornece tracklist completa e IDs canônicos (MBID) sem contrato comercial. Sem tracklist, o diferencial do produto não existe. |
| D-06 | Fonte complementar de gênero | Discogs (condicional, Fase 4) | Fornece hierarquia de dois níveis pronta e cobre lacunas do MusicBrainz. Adiado até haver evidência de que a cobertura do MB é insuficiente. |
| D-07 | Multiusuário no v1 | Não, single-user | Porém o schema nasce multiusuário (ver nota abaixo). Autenticação entra na Fase 4. |
| D-08 | Unidade de catálogo | Release group | Usar o release group do MusicBrainz como "álbum", ignorando releases individuais (edição japonesa, remaster, vinil). Caso contrário o mesmo disco aparece dezenas de vezes no ranking. |
| D-09 | Estrutura de gênero | Grafo dirigido (DAG) | Gênero musical não é árvore: city pop deriva de pop, funk e AOR simultaneamente. Tabela de ligação `genre_parent`, nunca `parent_id`. |
| D-10 | Fórmula do ranking global | Média bayesiana | Média simples faz um álbum obscuro com uma nota 10 superar clássicos. |
| D-11 | Arquitetura do backend | Monolito modular | Um pacote por domínio, comunicação entre pacotes só por interface de serviço. Microsserviços seriam custo puro nessa escala. |
| D-12 | Ambiente local | ~~Podman + compose~~ | **Substituída por [0021](0021-docker-no-lugar-do-podman.md).** Postgres em container, também como aprendizado de containers. |
| D-13 | Mobile | PWA, não nativo | Angular responsivo + manifest + service worker entrega ~95% do valor de um app nativo. Reavaliar só com usuários reais reclamando. |
| D-14 | Nota obrigatória para `COMPLETED`? | Não, mas a UI pergunta | A coluna `score` permanece `NULL`-ável e sem `CHECK` condicional. É regra de interface, não de banco. |
| D-15 | Escala de nota | Inteiro de 1 a 10 | Igual ao MyAnimeList. `smallint` com `CHECK (score BETWEEN 1 AND 10)`. Meio ponto descartado por simplicidade de UI. |
| D-16 | Limite de itens em `LISTENING` | Sem limite | Se a lista inchar na prática, revisitar como aviso de UI, nunca como bloqueio. |
| D-17 | Relisten e progresso de faixa | Zera o progresso | `COMPLETED → LISTENING` limpa `current_track_id`. Sem tabela de histórico de sessões: `listen_count` é um contador simples, não uma soma derivada. |
| D-18 | Organização do repositório | Monorepo | Um repositório com `api/` (Spring) e futuramente `web/` (Angular), mais o `compose.yaml`. Dois repositórios exigiriam sincronizar versões manualmente sem ganho em projeto solo. |
| D-19 | Proteção contra ciclo no grafo de gênero | Nenhuma, só o `UNION` | A hierarquia não é dado de usuário: vem de seed curado em migration, revisado antes do commit. O `UNION` na CTE já impede loop infinito. Trigger seria complexidade contra ameaça inexistente. Revisitar se a hierarquia virar editável pela API. |
| D-20 | Padrão de mensagem de commit | Conventional Commits | `feat(modulo):`, `fix:`, `chore:`, `refactor:`, `docs:`, `test:`. Histórico legível e é o que empresa espera ver em portfólio. |

## Nota sobre D-07

**Single-user é uma decisão de interface, não de modelo de dados.** O schema contém `user_id` em todas as tabelas de biblioteca desde a primeira migration, com uma única linha semeada em `app_user`. Se o v1 nascesse com schema single-user (sem `user_id`), a migração para multiusuário viraria reescrita de todas as queries, todos os índices e todos os endpoints.

O ponto de costura no código é a interface `CurrentUserProvider` (ver [arquitetura, seção 2.2](../arquitetura.md#22-o-ponto-de-costura-do-multiusuário)). Nenhum service recebe `userId` vindo do controller.
