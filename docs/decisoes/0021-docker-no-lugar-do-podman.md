# 0021. Docker Desktop no lugar do Podman

- **Status:** aceita (substitui D-12)
- **Data:** 2026-10-14

## Contexto

O desenvolvimento saiu do Fedora e passou para o Windows 11. No Windows, o Podman roda os containers numa máquina Linux dentro do WSL2. Nessa máquina, dois problemas apareceram em sequência:

1. O container não iniciava (`crun: controller pids is not available`): a máquina WSL do Podman roda sem systemd e não delega o controlador `pids` do cgroup. Contornado desligando o limite de processos (`pids_limit=0`).
2. Mesmo com o container saudável, a porta 5433 nunca chegou ao Windows: nada escutando no host, nem em modo rootful, nem com user-mode networking.

O `compose.yaml` e o `application.properties` não tinham nada de errado; o problema era a camada de rede da máquina Podman no WSL.

## Decisão

Usar **Docker Desktop** (backend WSL 2) como ambiente local de containers. O `compose.yaml` continua o mesmo; muda só o comando (`docker compose` em vez de `podman compose`).

## Consequências

- O ambiente sobe com a configuração padrão, sem ajustes manuais na máquina virtual.
- Os comandos do README passam a usar `docker`.
- O objetivo de aprendizado de containers da D-12 continua valendo: imagens, compose e comandos são os mesmos nas duas ferramentas.
- O Docker Desktop é gratuito para uso pessoal e educacional; se o projeto virar algo comercial, revisitar a licença.
- No Linux, o Podman continua funcionando com o mesmo `compose.yaml` para quem preferir.
