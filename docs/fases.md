# Fases do projeto

O guia de execução. Cada fase tem objetivo, entregas e critério de pronto explícito. **Nenhuma fase começa antes da anterior atender o seu critério.**

No GitHub, cada fase é uma **milestone**, e cada entrega abaixo vira uma **issue** com o número indicado. As Fases 3 e 4 ganham issues quando a Fase 2 estiver perto do fim.

---

## Fase 0: Preparo do ambiente

**Objetivo:** ter o esqueleto rodando de ponta a ponta, sem nenhuma regra de negócio.

**Concluída em 14/10/2026.** Entregas:
- `compose.yaml` subindo PostgreSQL 16 na porta 5433, com volume `mal-pgdata`.
- Projeto Spring Boot 4.1.1 em `api/`.
- Flyway no comando do schema, `ddl-auto=validate`.
- Aplicação subindo e conectando ao banco.
- Repositório git em Conventional Commits, publicado no GitHub.
- README e documentação no repositório (#1).
- Testcontainers e `./mvnw verify` passando do zero (#2).
- CI com GitHub Actions (#3).

**Pronto quando:** `./mvnw verify` passa do zero, com banco em container, local e no CI.

---

## Fase 1: Catálogo e metadados

**Objetivo:** buscar um álbum por texto e tê-lo persistido localmente com artista, capa, ano, tracklist e gêneros. É a fase que mais decide o sucesso do projeto.

**Já entregue:**
- Migrations de `artist`, `album`, `track` (V1).
- Migrations de `genre`, `genre_parent`, `genre_alias`, `album_genre` (V2).
- Entidade `Artist` e `ArtistRepository`, package-private.

**Entregas:**
1. Entidades `Album` e `Track` com `@ManyToOne(fetch = LAZY)` (#5).
2. `CatalogService`, a única porta pública do módulo (#6).
3. Interface `MetadataProvider` e `MusicBrainzProvider`, com rate limiter de 1 req/s e `User-Agent` (#7).
4. Regra explícita de escolha do release representativo para a tracklist (#8).
5. Importação idempotente, ancorada no `UNIQUE (mbid)`, incluindo gêneros (#9).
6. Decisão sobre busca textual local, `pg_trgm` ou `tsvector` (#10).
7. `GET /api/albums/search?q=` com estratégia local-primeiro (#11).
8. `GET /api/albums/{id}` com tracklist e gêneros (#12).
9. Testes do provider com MockWebServer e respostas reais gravadas (#13).

**Pronto quando:** buscar 20 álbuns variados pelo Postman, incluindo pelo menos cinco obscuros e cinco não-ocidentais, e verificar no banco que artista, ano, capa e tracklist completa foram gravados corretamente em todos (#14).

---

## Fase 2: Biblioteca

**Objetivo:** o sistema já é útil, ainda que só via Postman. É onde o produto passa a existir.

**Entregas:**
1. `app_user` e `CurrentUserProvider` com implementação single-user (#15).
2. Migrations de `user_album_entry`, `user_track_favorite`, `user_favorite` (#16).
3. CRUD de entradas: criar, mudar status, dar nota (#17).
4. Efeitos colaterais de transição de status, conforme [arquitetura, 4.1](arquitetura.md#41-transições-de-status) (#18).
5. Faixa atual, com validação de que pertence ao álbum da entrada, e faixas favoritas (#19).
6. Listagem da biblioteca com filtro por status e gênero e ordenação por nota (#20).
7. Top 10 com reordenação transacional (#21).
8. Medição da cobertura de gênero para decidir sobre o Discogs (D-06) (#22).

**Pronto quando:** sua biblioteca real cadastrada, com pelo menos 50 álbuns em status variados, e as consultas de filtro retornando corretamente (#23).

---

## Fase 3: Front-end Angular

**Objetivo:** interface utilizável no celular. A partir daqui você para de usar o Postman.

**Entregas:**
- Projeto Angular em `web/`, com standalone components e signals; CORS configurado no backend.
- Decidir a biblioteca de estilo, Tailwind ou Angular Material (A-09).
- Tela de busca com resultados e ação de adicionar à biblioteca.
- Página do álbum: capa, metadados, tracklist com marcação de faixa atual e favoritas.
- Página da biblioteca com abas por status.
- Componente de nota.
- Página de top 10 com reordenação por arrastar.
- Filtro por gênero.
- Layout mobile-first, testado em tela estreita desde o primeiro componente.

**Pronto quando:** uma semana inteira de uso real pelo celular sem precisar abrir o Postman uma vez.

---

## Fase 4: Multiusuário e social

**Objetivo:** transformar "minha planilha" em "site". Só começa se as fases anteriores estiverem em uso de verdade.

**Entregas:**
- Decidir o método de autenticação (A-01). Spring Security; cadastro, login, hash de senha.
- `CurrentUserProvider` passa a ler o `SecurityContext`, sem tocar em services.
- `album_stats` e job agendado de recálculo bayesiano.
- Ranking global e perfil público de usuário.
- Seed do grafo de hierarquia de gênero (150 a 300 gêneros curados).
- Consulta recursiva de gênero ligada ao filtro da biblioteca.
- Integração Discogs, condicionada ao critério da [arquitetura, 5.2](arquitetura.md#52-discogs-complemento-condicional-fase-4).
- PWA: manifest e service worker.
- Decidir a hospedagem (A-02) e fazer o deploy.

**Pronto quando:** um segundo usuário real cria conta, cadastra álbuns e o ranking global reflete as notas dos dois.
