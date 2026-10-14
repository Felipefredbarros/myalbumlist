# O que o MyAlbumList faz

Este documento descreve o sistema **do ponto de vista de quem usa**. Como ele é construído está em [`arquitetura.md`](arquitetura.md); quando cada parte fica pronta, em [`fases.md`](fases.md).

## O problema

Existem sites de nota de álbum (RateYourMusic, Album of the Year) e existem rastreadores de escuta (Last.fm). Não existe um produto que combine a mecânica de status do MyAnimeList (escutando, completo, em pausa, abandonado, planejo escutar) com **controle de progresso no nível da faixa**.

O MyAlbumList é isso: uma biblioteca pessoal de álbuns onde você sabe o que está ouvindo, o que já ouviu, onde parou, o que achou e quais são os seus favoritos.

## Os cinco status

Os status do MyAnimeList foram desenhados para obras seriadas, consumidas ao longo de semanas. Um álbum dura 45 minutos, então o significado foi adaptado:

| Status | Significado |
|---|---|
| **Escutando** (`LISTENING`) | Na rotação atual: o álbum que você está digerindo nesta semana. Não significa "tocando agora". |
| **Completo** (`COMPLETED`) | Ouvido por inteiro pelo menos uma vez, com atenção. |
| **Em pausa** (`ON_HOLD`) | Começou, parou no meio, pretende voltar. |
| **Abandonado** (`DROPPED`) | Começou e não pretende terminar. |
| **Planejo escutar** (`PLAN_TO_LISTEN`) | Fila de escuta. |

## Funcionalidades do v1 (uso pessoal)

### Encontrar álbuns
- Como usuário, eu busco um álbum pelo nome ou pelo artista.
- Se o álbum ainda não está no sistema, ele é trazido do MusicBrainz com artista, capa, ano, tracklist completa e gêneros, e fica guardado. Da próxima vez, a busca é instantânea.
- Cada disco aparece **uma vez só**, mesmo que tenha várias edições (japonesa, remaster, vinil).
- Eu abro a página de um álbum e vejo a capa, os dados, a tracklist e os gêneros, com os principais em destaque.

### Organizar a biblioteca
- Eu adiciono um álbum à minha biblioteca com um dos cinco status, e mudo o status quando quiser, para qualquer outro.
- Ao começar a escutar, a data de início é registrada. Ao completar, a data de fim também.
- Eu vejo a biblioteca separada por status, filtro por gênero e ordeno pela minha nota.

### Acompanhar a escuta
- Eu marco **em qual faixa parei**. Se eu abandonar o álbum, o sistema lembra onde desisti.
- Eu marco **faixas favoritas** dentro de cada álbum.
- Quando eu reouço um álbum que já completei, isso conta como **relisten**: o contador sobe e o progresso de faixa recomeça. Reouvir é o comportamento normal com música, então o contador é um dado de primeira classe.

### Avaliar
- Eu dou uma nota de **1 a 10** para cada álbum. A nota é opcional: ao marcar como completo, o sistema oferece o campo, mas não obriga.
- Eu monto três **top 10**: álbuns, artistas e faixas. Eles são listas ordenadas à mão, independentes das notas, e eu reordeno arrastando.

### Usar no celular
- A interface é pensada primeiro para o celular e funciona como um app instalável (PWA), sem precisar de loja de aplicativos.

## Fora do v1

- Cadastro público, login e perfis de outros usuários.
- Ranking global com a média entre usuários.
- Resenhas em texto, comentários, seguir pessoas.
- Aplicativo mobile nativo.
- Registro automático do que você ouve (scrobbling do Last.fm ou Spotify).

## Depois do v1 (Fase 4)

Se o uso pessoal se provar, o sistema vira um site:

- Qualquer pessoa cria uma conta e mantém a própria biblioteca.
- **Ranking global** de álbuns, com média bayesiana: um álbum com uma única nota 10 não passa à frente de um clássico com centenas de notas.
- Perfil público de usuário.
- Filtro por gênero que entende subgêneros: filtrar por "pop" também traz city pop e synth-pop.
