# ⌨️ `Atalhos` <!-- omit in toc -->
> Read in [English](KEYBINDINGS.md).

Todos os atalhos disponíveis no `atomic.nvf`, agrupados por contexto. `<leader>` é a **barra de espaço**.
Pressione `<leader>` e aguarde: o `which-key` mostra a mesma lista em um popup.

- [Geral e janelas](#geral-e-janelas)
- [Clipboard](#clipboard)
- [Buffers (bufferline)](#buffers-bufferline)
- [Explorador de arquivos (Neo-tree)](#explorador-de-arquivos-neo-tree)
  - [Abrindo a árvore](#abrindo-a-árvore)
  - [Criando arquivos e pastas](#criando-arquivos-e-pastas)
  - [Dentro da janela do Neo-tree](#dentro-da-janela-do-neo-tree)
- [Terminal (toggleterm)](#terminal-toggleterm)
- [IA / LLMs (CodeCompanion)](#ia--llms-codecompanion)
  - [Dentro do buffer de chat](#dentro-do-buffer-de-chat)
  - [Revisando alterações propostas pela LLM](#revisando-alterações-propostas-pela-llm)
- [Busca (Telescope)](#busca-telescope)
- [LSP](#lsp)
- [Depuração (DAP)](#depuração-dap)
- [Temas](#temas)
- [Atalhos nativos do Neovim que valem conhecer](#atalhos-nativos-do-neovim-que-valem-conhecer)

Legenda de modos: **n** normal · **v** visual · **i** inserção · **t** terminal.

## Geral e janelas

| Teclas | Modo | Ação |
| :--- | :--- | :--- |
| `<C-h>` | n, t | Ir para a janela da esquerda |
| `<C-j>` | n, t | Ir para a janela de baixo |
| `<C-k>` | n, t | Ir para a janela de cima |
| `<C-l>` | n, t | Ir para a janela da direita |
| `<leader>` | n | Mostrar os atalhos disponíveis (which-key) |

> `<C-h/j/k/l>` também funcionam **de dentro do terminal**, então dá para pular entre terminal, buffers, Neo-tree e o chat de IA sem sair do modo terminal antes.

## Clipboard

O registrador padrão é o **clipboard do sistema** (`clipboard=unnamedplus`, usando `wl-copy` no Wayland e `xclip` no X11). Tudo que você copiar com `y` — inclusive texto dentro do terminal — pode ser colado em qualquer outro programa, e tudo que for copiado fora pode ser colado com `p`. Via SSH (sem servidor gráfico) cai para OSC 52, e o texto chega ao clipboard do emulador de terminal local.

| Teclas | Modo | Ação |
| :--- | :--- | :--- |
| `y` / `yy` / `p` | n, v | Copiar / colar usando o clipboard do sistema |
| `<leader>y` | n, v | Copiar para o clipboard do sistema (`"+y` explícito) |
| `<leader>Y` | n | Copiar até o fim da linha para o clipboard do sistema |
| `<C-S-c>` | v | Copiar a seleção para o clipboard do sistema |
| `<C-S-v>` | t | Colar o clipboard do sistema no terminal |

## Buffers (bufferline)

| Teclas | Modo | Ação |
| :--- | :--- | :--- |
| `<Tab>` | n | Próximo buffer |
| `<S-Tab>` | n | Buffer anterior |
| `<leader>x` | n | Fechar o buffer atual (fecha a Neo-tree junto) |
| `<leader>bp` | n | Escolher um buffer interativamente |
| `<leader>>` | n | Mover buffer para a direita |
| `<leader><` | n | Mover buffer para a esquerda |
| `<leader>bsd` | n | Ordenar buffers por diretório |
| `<leader>bse` | n | Ordenar buffers por extensão |
| `<leader>bsi` | n | Ordenar buffers por ID |

## Explorador de arquivos (Neo-tree)

A Neo-tree fecha automaticamente sempre que um buffer de arquivo é fechado (`<leader>x`, `:bd`, o `x` da bufferline…) e também quando ela é a última janela aberta.

### Abrindo a árvore

| Teclas | Modo | Ação |
| :--- | :--- | :--- |
| `<leader>tn` | n | Abrir/fechar a Neo-tree |
| `<leader>te` | n | Revelar o arquivo atual na Neo-tree |

### Criando arquivos e pastas

Novas entradas são criadas **dentro do diretório sob o cursor** (ou ao lado do arquivo sob o cursor).

| Teclas | Ação | Exemplo de entrada |
| :--- | :--- | :--- |
| `a` | Criar um **arquivo**. Termine o nome com `/` para criar uma **pasta**. Pastas intermediárias são criadas automaticamente. | `utils.py` · `docs/` · `src/api/routes.ts` |
| `A` | Criar uma **pasta** | `assets` · `assets/icons` |

Os números de linha ficam ligados dentro da árvore (absoluto na linha do cursor, relativo no resto), então dá para pular numa árvore grande com `12j` / `5k`, ou `:30<CR>` / `30G`.

### Dentro da janela do Neo-tree

| Teclas | Ação |
| :--- | :--- |
| `<CR>` / duplo clique | Abrir arquivo / expandir pasta |
| `<Space>` | Expandir / recolher nó |
| `<BS>` | Subir um diretório |
| `.` | Definir o diretório sob o cursor como raiz |
| `C` | Fechar nó |
| `z` | Fechar todos os nós |
| `S` / `s` / `t` | Abrir em split horizontal / split vertical / nova aba |
| `w` | Abrir escolhendo a janela (aparece uma letra grande em cada janela candidata) |
| `P` | Alternar pré-visualização flutuante |
| `l` | Focar a janela de pré-visualização |
| `<C-f>` / `<C-b>` | Rolar a pré-visualização |
| `a` | Criar arquivo (ou pasta, se terminar com `/`) |
| `A` | Criar pasta |
| `r` | Renomear |
| `b` | Renomear apenas o nome base |
| `d` | Excluir |
| `T` | Mover para a lixeira |
| `u` | Desfazer a última ida para a lixeira |
| `U` | Restaurar da lixeira |
| `c` | Copiar para um caminho (pede o destino) |
| `m` | Mover para um caminho (pede o destino) |
| `y` | Copiar para o clipboard da Neo-tree |
| `x` | Recortar para o clipboard da Neo-tree |
| `p` | Colar do clipboard da Neo-tree |
| `<C-r>` | Limpar o clipboard da Neo-tree |
| `Y` | Copiar o caminho absoluto para o clipboard **do sistema** |
| `i` | Mostrar detalhes do arquivo |
| `H` | Mostrar/ocultar arquivos ocultos |
| `/` | Busca fuzzy |
| `D` | Busca fuzzy (apenas diretórios) |
| `#` | Ordenação fuzzy |
| `f` | Filtrar ao confirmar |
| `<C-x>` | Limpar filtro |
| `[g` / `]g` | Arquivo modificado no git anterior / próximo |
| `o` + `c`/`d`/`g`/`m`/`n`/`s`/`t` | Ordenar por criação / diagnósticos / status git / modificação / nome / tamanho / tipo |
| `e` | Alternar largura automática |
| `R` | Atualizar |
| `<` / `>` | Fonte anterior / próxima (arquivos, buffers, git status) |
| `<Esc>` | Cancelar pré-visualização / fechar árvore flutuante |
| `q` | Fechar a Neo-tree |
| `?` | Ajuda com todos os atalhos |

## Terminal (toggleterm)

O `<Esc>` sai do modo terminal, então você pode rolar, buscar e copiar a saída como em um buffer comum. Aperte `i` (ou simplesmente volte para a janela) para digitar no shell de novo.

| Teclas | Modo | Ação |
| :--- | :--- | :--- |
| `<C-t>` | n, t | Mostrar/esconder o terminal |
| `<leader>tv` | n | Terminal embaixo (horizontal) |
| `<leader>ts` | n | Terminal na lateral (vertical) |
| `<leader>tf` | n | Terminal flutuante |
| `<leader>ta` | n | Alternar todos os terminais |
| `<leader>tl` | v | Enviar as linhas selecionadas ao terminal |
| `<Esc>` | t | Sair do modo terminal (vai para o modo normal) |
| `<A-Esc>` | t | Enviar um `Esc` literal ao programa (vi-mode, htop…) |
| `<C-h/j/k/l>` | t | Ir para outra janela direto do terminal |
| `<C-S-v>` | t | Colar o clipboard do sistema |
| `i` / `a` | n (buffer do terminal) | Voltar ao modo terminal |
| `y` / `yy` | n (buffer do terminal) | Copiar a saída do terminal para o clipboard do sistema |
| `p` | n (buffer do terminal) | Colar o clipboard do sistema no shell |

> O `<Esc>` não é remapeado em terminais do `lazygit`/`fzf`, então essas ferramentas continuam funcionando normalmente.

## IA / LLMs (CodeCompanion)

Veja a [seção LLMs / CodeCompanion do README](../README.pt-br.md#-llms--codecompanion) para configurar os tokens.

| Teclas | Modo | Ação |
| :--- | :--- | :--- |
| `<leader>ac` | n, v | Abrir/fechar o chat (adaptador padrão: Gemini) |
| `<leader>ag` | n | Novo chat com o **Gemini** |
| `<leader>al` | n | Novo chat com o **Claude Code** |
| `<leader>aa` | n, v | Paleta de ações (biblioteca de prompts, explicar, corrigir, testes…) |
| `<leader>ai` | n, v | Prompt inline (`:CodeCompanion <prompt>`) — edita o buffer/seleção |
| `<leader>ad` | v | Adicionar a seleção ao chat atual |

### Dentro do buffer de chat

| Teclas | Modo | Ação |
| :--- | :--- | :--- |
| `<CR>` / `<C-s>` | n / i | Enviar a mensagem |
| `q` | n | Parar a requisição atual |
| `<C-c>` | n, i | Fechar o chat |
| `ga` | n | Trocar adaptador e modelo |
| `gr` | n | Gerar a última resposta de novo |
| `gx` | n | Limpar o chat |
| `gy` | n | Copiar o último bloco de código |
| `gc` | n | Inserir um bloco de código vazio |
| `gf` | n | Recolher todos os blocos de código |
| `gR` | n | Abrir o arquivo do caminho sob o cursor |
| `gs` | n | Ligar/desligar o system prompt |
| `gty` | n | Ligar/desligar aprovação automática de ferramentas (YOLO) |
| `gtx` | n | Resetar aprovações de ferramentas em cache |
| `gba` / `gbd` | n | Sincronização total / por diff dos buffers fixados |
| `gd` | n | Informações de debug |
| `{` / `}` | n | Chat anterior / próximo |
| `[[` / `]]` | n | Cabeçalho anterior / próximo |
| `<C-_>` | i | Menu de completação (comandos `/`, contexto `#`, ferramentas `@`) |
| `?` | n | Mostrar todos os atalhos do chat |

### Revisando alterações propostas pela LLM

| Teclas | Ação |
| :--- | :--- |
| `gv` | Ver o diff proposto |
| `g1` | Sempre aceitar alterações neste buffer |
| `g2` | Aceitar a alteração |
| `g3` | Rejeitar a alteração |
| `g4` | Cancelar todas as chamadas de ferramenta pendentes |
| `{` / `}` | Trecho (hunk) anterior / próximo |

## Git (em buffers, sem terminal)

O `gitsigns` marca as linhas alteradas na coluna lateral de todo arquivo; o `diffview` traz o `git diff` / `git log` completo dentro de buffers.

| Teclas | Modo | Ação |
| :--- | :--- | :--- |
| `<leader>gd` | n | **Abre/fecha** o git diff da árvore de trabalho inteira (lista de arquivos + diff lado a lado) |
| `<leader>gD` | n | O mesmo, mas contra o commit anterior (`HEAD~1`) |
| `<leader>gh` | n | Abre/fecha o git log do repositório, navegável em buffer |
| `<leader>gf` | n | Abre/fecha o git log do arquivo atual |
| `<leader>gf` | v | Git log apenas das linhas selecionadas |
| `<leader>gq` | n | Fecha qualquer Diffview aberto, de qualquer aba |

Os quatro atalhos fecham a view esteja você em qualquer aba — não precisa voltar até a aba do diff antes.

Dentro do Diffview: `<Tab>` / `<S-Tab>` próximo/anterior arquivo, `g?` para a ajuda completa, `<leader>e` foca o painel de arquivos, `-` dá stage/unstage no arquivo sob o cursor.

### Hunks (gitsigns)

| Teclas | Modo | Ação |
| :--- | :--- | :--- |
| `]c` / `[c` | n | Hunk seguinte / anterior |
| `<leader>hP` | n | Pré-visualizar o hunk numa janela flutuante |
| `<leader>hd` | n | Diff do arquivo atual em split |
| `<leader>hD` | n | Diff do projeto inteiro |
| `<leader>hs` / `<leader>hr` | n | Stage / reset do hunk |
| `<leader>hS` / `<leader>hR` | n | Stage / reset do buffer inteiro |
| `<leader>hu` | n | Desfazer o stage do hunk |
| `<leader>hb` | n | Blame da linha atual |
| `<leader>hB` | n | Ligar/desligar o blame inline em todas as linhas |
| `<leader>hx` | n | Mostrar/ocultar linhas deletadas |

## Preview de Markdown

Mesma ideia do preview lateral do VS Code: uma página renderizada ao vivo no seu navegador, sincronizada com o cursor e atualizada enquanto você digita.

| Teclas | Modo | Ação |
| :--- | :--- | :--- |
| `<leader>mp` | n | Abrir/fechar o preview de Markdown no navegador |

O preview continua aberto quando você sai do buffer `.md` — só o `<leader>mp` derruba. E uma aba só do navegador serve todos os arquivos: ao abrir outro `.md`, a mesma aba passa a mostrar ele, em vez de acumular abas.

## Busca (Telescope)

| Teclas | Modo | Ação |
| :--- | :--- | :--- |
| `<leader>.` | n | Procurar arquivos |
| `<leader>ff` | n | Procurar arquivos |
| `<leader>fg` | n | Live grep (procurar texto nos arquivos) |
| `<leader>fb` | n | Buffers abertos |
| `<leader>fh` | n | Tags de ajuda |
| `<leader>fr` | n | Retomar a última busca |
| `<leader>fs` | n | Símbolos do Treesitter |
| `<leader>ft` | n | Abrir o Telescope (todos os pickers) |
| `<leader>fvf` | n | Arquivos do git |
| `<leader>fvs` | n | Status do git |
| `<leader>fvb` | n | Branches do git |
| `<leader>fvcw` | n | Commits do git |
| `<leader>fvcb` | n | Commits do buffer atual |
| `<leader>fvx` | n | Git stash |
| `<leader>flr` | n | Referências (LSP) |
| `<leader>flD` | n | Definições (LSP) |
| `<leader>fli` | n | Implementações (LSP) |
| `<leader>flt` | n | Definições de tipo (LSP) |
| `<leader>flsb` | n | Símbolos do documento (LSP) |
| `<leader>flsw` | n | Símbolos do workspace (LSP) |
| `<leader>fld` | n | Diagnósticos |

> **Dica:** dentro de *qualquer* picker do Telescope, aperte `<C-/>` para abrir uma lista flutuante com todas as teclas mapeadas naquele picker (mover, rolar preview, abrir em split/aba, enviar pra quickfix...). É um recurso nativo do próprio Telescope, então funciona em todo picker — inclusive os que outros plugins adicionarem depois.

## LSP

Disponíveis em qualquer buffer com um servidor de linguagem anexado (Nix, Python, Rust, TypeScript/JavaScript).

| Teclas | Modo | Ação |
| :--- | :--- | :--- |
| `K` / `<leader>lh` | n | Documentação (hover) |
| `<leader>lgd` | n | Ir para a definição |
| `<leader>lgD` | n | Ir para a declaração |
| `<leader>lgt` | n | Ir para a definição de tipo |
| `<leader>lgi` | n | Listar implementações |
| `<leader>lgr` | n | Listar referências |
| `<leader>lgn` / `<leader>lgp` | n | Próximo / anterior diagnóstico |
| `<leader>le` | n | Diagnóstico em janela flutuante |
| `<leader>la` | n | Code action |
| `<leader>ln` | n | Renomear símbolo |
| `<leader>lf` | n | Formatar |
| `<leader>ltf` | n | Ligar/desligar formatação ao salvar |
| `<leader>ls` | n | Ajuda de assinatura |
| `<leader>lH` | n | Destacar ocorrências no documento |
| `<leader>lS` | n | Símbolos do documento |
| `<leader>lws` | n | Símbolos do workspace |
| `<leader>lwa` / `<leader>lwr` / `<leader>lwl` | n | Adicionar / remover / listar pastas do workspace |

## Depuração (DAP)

| Teclas | Modo | Ação |
| :--- | :--- | :--- |
| `<leader>db` | n | Alternar breakpoint |
| `<leader>dc` | n | Continuar |
| `<leader>dgc` | n | Continuar até o cursor |
| `<leader>dgj` | n | Próximo passo (step over) |
| `<leader>dgi` | n | Entrar na função (step into) |
| `<leader>dgo` | n | Sair da função (step out) |
| `<leader>dgk` | n | Voltar um passo |
| `<leader>dvi` / `<leader>dvo` | n | Descer / subir na stack trace |
| `<leader>dh` | n | Hover |
| `<leader>dr` | n | Abrir/fechar o REPL |
| `<leader>d.` | n | Repetir a última sessão de debug |
| `<leader>dR` | n | Reiniciar |
| `<leader>dq` | n | Encerrar |

## Temas

| Teclas | Modo | Ação |
| :--- | :--- | :--- |
| `<leader>th` | n | Seletor de temas (pré-visualização ao vivo, a escolha é salva) |
| `<leader>tr` | n | Voltar ao tema padrão |
| `<leader>td` | n | Mostrar onde a configuração do tema é salva |

## Atalhos nativos do Neovim que valem conhecer

| Teclas | Modo | Ação |
| :--- | :--- | :--- |
| `gcc` / `gc` | n / v | Comentar / descomentar |
| `grn` / `gra` / `grr` / `gri` / `grt` | n | LSP: renomear / code action / referências / implementação / definição de tipo |
| `gO` | n | LSP: símbolos do documento |
| `[d` / `]d` | n | Diagnóstico anterior / próximo |
| `<C-w>d` | n | Diagnósticos sob o cursor |
| `[b` / `]b` | n | Buffer anterior / próximo |
| `[q` / `]q` | n | Item anterior / próximo da quickfix |
| `gx` | n, v | Abrir caminho/URL sob o cursor com o programa padrão do sistema |
