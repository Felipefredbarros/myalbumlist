# Questões em aberto

Quando uma destas for decidida, ela vira um arquivo numerado em `decisoes/` e sai desta lista.

| ID | Questão | Situação |
|---|---|---|
| A-01 | Método de autenticação na Fase 4 | Candidatos: JWT stateless, sessão com cookie, OAuth via provedor externo. |
| A-02 | Onde hospedar | Candidatos: VPS própria, Railway, Fly.io, Oracle Cloud free tier. Decidir na Fase 4. |
| A-07 | Descritores no estilo RYM (melancólico, atmosférico, lo-fi) | Barato de adicionar junto com gênero: duas tabelas espelhando `genre` e `album_genre`, sem hierarquia. Incluir ou não no v1? |
| A-08 | Importar biblioteca existente (CSV, Last.fm, Spotify) | Avaliar na Fase 2. Pode economizar horas de cadastro manual no início. |
| A-09 | Biblioteca de estilo do front | Tailwind ou Angular Material. Decidir na Fase 3. |
| A-10 | Busca textual no catálogo local | Provável necessidade de `pg_trgm` ou `tsvector` para busca por título/artista. Definir na Fase 1, ao implementar `/api/albums/search`. |
