# 0022. Testcontainers para testes de integração com o banco

- **Status:** aceita
- **Data:** 2026-10-14

## Contexto

Até aqui o projeto não tinha nenhum teste automatizado: o `ApiApplicationTests` gerado pelo Initializr estava vazio, e erros de mapeamento ou de migration só apareciam ao subir a aplicação na mão.

Testar com um banco em memória (H2) não serve para este projeto. O schema já depende de recursos do PostgreSQL que o H2 não reproduz, ou reproduz de outro jeito:

- `gen_random_uuid()` como default das chaves primárias;
- o `CHECK` com expressão regular (`~`) que valida o `slug` de gênero;
- `timestamptz`;
- mais adiante, a CTE recursiva da hierarquia de gênero e, provavelmente, `pg_trgm` ou `tsvector` para busca textual.

Um teste que passa no H2 e falha no Postgres não prova nada; pior, dá falsa confiança.

## Decisão

Usar **Testcontainers** (versão 2) com `@ServiceConnection` do Spring Boot. Os testes de integração sobem um PostgreSQL real em container, descartável, com a imagem fixada em **`postgres:16`**, a mesma major version do `compose.yaml`.

O container é declarado uma vez, em `TestcontainersConfiguration` (pacote raiz dos testes, pública), e cada teste de banco o importa com `@Import`.

## Consequências

- O Flyway aplica todas as migrations do zero em cada execução, então uma migration quebrada é detectada no teste, não em produção.
- O `ddl-auto=validate` é exercitado nos testes: uma entidade que não bate com a tabela derruba o build.
- Os testes não dependem do banco de desenvolvimento (porta 5433), nem do `docker compose` estar de pé.
- **Custo:** o Docker precisa estar rodando para executar os testes, local e no CI.
- **Custo:** a primeira execução baixa as imagens (`postgres:16` e `testcontainers/ryuk`), e cada execução leva alguns segundos para subir o container.
- Ao atualizar a versão do Postgres, trocar a imagem nos dois lugares: `compose.yaml` e `TestcontainersConfiguration`.
