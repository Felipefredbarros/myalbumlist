# Fluxo de trabalho

Projeto solo, mas desenvolvido com o fluxo de um time.

## Do planejamento ao merge

1. **Milestone** = uma fase do projeto (ver [arquitetura, seção 7](docs/arquitetura.md#7-fases)).
2. **Issue** = uma entrega da fase, com o critério de pronto escrito nela. Cada issue deve caber em uma sessão de trabalho (2 a 4 horas). Se não couber, vira duas.
3. **Branch** a partir da `main` atualizada, com o tipo e o assunto da issue:
   ```
   git switch main
   git pull
   git switch -c feat/catalog-album-track
   ```
4. **Commits pequenos** em [Conventional Commits](https://www.conventionalcommits.org/):
   ```
   feat(catalog): entidade Album com relacionamento LAZY para Artist
   test(catalog): valida UNIQUE de track_number por álbum
   ```
   Tipos: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `ci`. O escopo é o módulo (`catalog`, `genre`, `library`, `metadata`, `rating`, `identity`, `db`).
5. **Pull request** para a `main`, com `Closes #N` na descrição para fechar a issue no merge.
6. **Squash merge.** A `main` fica com um commit por entrega, com o título do PR em Conventional Commits; o histórico detalhado fica no PR.

## Regras

- A `main` está sempre funcionando. Nada é commitado direto nela.
- PR só entra na `main` com o CI verde (`./mvnw verify` no GitHub Actions).
- Migration aplicada nunca é editada (ver [convenções](docs/arquitetura.md#6-convenções)).
- Toda decisão de arquitetura nova vira um arquivo em [`docs/decisoes/`](docs/decisoes/README.md), no mesmo PR que a implementa.
