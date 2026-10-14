# Registro de decisões

Cada decisão de arquitetura fica registrada aqui, com o **porquê**. O objetivo é que daqui a seis meses ninguém refaça o mesmo debate.

- [`0000-registro-inicial.md`](0000-registro-inicial.md): decisões D-01 a D-20, migradas do documento de arquitetura v0.2 (PDF).
- [`em-aberto.md`](em-aberto.md): questões ainda não decididas.
- A partir de `0021`, **uma decisão por arquivo**, no formato abaixo.

## Formato de uma decisão nova

Arquivo `NNNN-titulo-curto.md`, numeração sequencial:

```markdown
# NNNN. Título

- **Status:** aceita | substituída por NNNN | revogada
- **Data:** AAAA-MM-DD

## Contexto
O problema e as forças em jogo. O que torna a decisão necessária agora?

## Decisão
O que foi escolhido, em uma ou duas frases.

## Consequências
O que fica mais fácil, o que fica mais difícil, e o que precisa ser revisitado se mudar.
```

Uma decisão aceita não é editada depois: se mudar, cria-se uma nova que a **substitui**, e a antiga ganha o status "substituída por NNNN". É a mesma regra das migrations.

## Índice

| Nº | Decisão | Status |
|---|---|---|
| D-01 a D-20 | [Registro inicial](0000-registro-inicial.md) | aceitas (D-12 substituída) |
| 0021 | [Docker Desktop no lugar do Podman](0021-docker-no-lugar-do-podman.md) | aceita |
