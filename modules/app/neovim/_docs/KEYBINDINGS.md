# ⌨️ `Keybindings` <!-- omit in toc -->
> Leia em [português do Brasil](KEYBINDINGS.pt-br.md).

Every keybinding available in `atomic.nvf`, grouped by context. `<leader>` is the **space bar**.
Press `<leader>` and wait: `which-key` shows the same list in a popup.

- [General \& windows](#general--windows)
- [Clipboard](#clipboard)
- [Buffers (bufferline)](#buffers-bufferline)
- [File explorer (Neo-tree)](#file-explorer-neo-tree)
  - [Opening the tree](#opening-the-tree)
  - [Creating files and folders](#creating-files-and-folders)
  - [Inside the Neo-tree window](#inside-the-neo-tree-window)
- [Terminal (toggleterm)](#terminal-toggleterm)
- [AI / LLMs (CodeCompanion)](#ai--llms-codecompanion)
  - [Inside the chat buffer](#inside-the-chat-buffer)
  - [Reviewing changes proposed by the LLM](#reviewing-changes-proposed-by-the-llm)
- [Search (Telescope)](#search-telescope)
- [LSP](#lsp)
- [Debugging (DAP)](#debugging-dap)
- [Themes](#themes)
- [Built-in Neovim mappings worth knowing](#built-in-neovim-mappings-worth-knowing)

Mode legend: **n** normal · **v** visual · **i** insert · **t** terminal.

## General & windows

| Keys | Mode | Action |
| :--- | :--- | :--- |
| `<C-h>` | n, t | Go to the window on the left |
| `<C-j>` | n, t | Go to the window below |
| `<C-k>` | n, t | Go to the window above |
| `<C-l>` | n, t | Go to the window on the right |
| `<leader>` | n | Show available keybindings (which-key) |

> `<C-h/j/k/l>` also work **from inside the terminal**, so you can jump between the terminal, your buffers, Neo-tree and the AI chat without leaving terminal mode first.

## Clipboard

The unnamed register is the **system clipboard** (`clipboard=unnamedplus`, using `wl-copy` on Wayland and `xclip` on X11). Anything you yank with `y` — including text inside the terminal — can be pasted in any other application, and anything copied outside can be pasted with `p`. Over SSH (no display server) it falls back to OSC 52, so the text reaches the clipboard of your local terminal emulator.

| Keys | Mode | Action |
| :--- | :--- | :--- |
| `y` / `yy` / `p` | n, v | Yank / paste using the system clipboard |
| `<leader>y` | n, v | Yank to the system clipboard (explicit `"+y`) |
| `<leader>Y` | n | Yank to the end of the line into the system clipboard |
| `<C-S-c>` | v | Copy the selection to the system clipboard |
| `<C-S-v>` | t | Paste the system clipboard into the terminal |

## Buffers (bufferline)

| Keys | Mode | Action |
| :--- | :--- | :--- |
| `<Tab>` | n | Next buffer |
| `<S-Tab>` | n | Previous buffer |
| `<leader>x` | n | Close the current buffer (also closes Neo-tree) |
| `<leader>bp` | n | Pick a buffer interactively |
| `<leader>>` | n | Move buffer to the right |
| `<leader><` | n | Move buffer to the left |
| `<leader>bsd` | n | Sort buffers by directory |
| `<leader>bse` | n | Sort buffers by extension |
| `<leader>bsi` | n | Sort buffers by ID |

## File explorer (Neo-tree)

Neo-tree closes automatically whenever a file buffer is closed (`<leader>x`, `:bd`, the `x` on the bufferline…) and also when it is the last window left.

### Opening the tree

| Keys | Mode | Action |
| :--- | :--- | :--- |
| `<leader>tn` | n | Toggle Neo-tree |
| `<leader>te` | n | Reveal the current file in Neo-tree |

### Creating files and folders

New entries are created **inside the directory under the cursor** (or next to the file under the cursor).

| Keys | Action | Example input |
| :--- | :--- | :--- |
| `a` | Add a **file**. End the name with `/` to create a **folder** instead. Intermediate folders are created automatically. | `utils.py` · `docs/` · `src/api/routes.ts` |
| `A` | Add a **folder** | `assets` · `assets/icons` |

Line numbers are on inside the tree (absolute on the cursor line, relative elsewhere), so you can jump around a long tree with `12j` / `5k`, or `:30<CR>` / `30G`.

### Inside the Neo-tree window

| Keys | Action |
| :--- | :--- |
| `<CR>` / double click | Open file / expand folder |
| `<Space>` | Expand / collapse node |
| `<BS>` | Go up one directory |
| `.` | Set the directory under the cursor as root |
| `C` | Close node |
| `z` | Close all nodes |
| `S` / `s` / `t` | Open in horizontal split / vertical split / new tab |
| `w` | Open using the window picker (big letter shown on each candidate window) |
| `P` | Toggle floating preview |
| `l` | Focus the preview window |
| `<C-f>` / `<C-b>` | Scroll the preview |
| `a` | Add file (or folder when ending with `/`) |
| `A` | Add folder |
| `r` | Rename |
| `b` | Rename only the base name |
| `d` | Delete |
| `T` | Move to trash |
| `u` | Undo the last trash operation |
| `U` | Restore from trash |
| `c` | Copy to a path (prompts for the destination) |
| `m` | Move to a path (prompts for the destination) |
| `y` | Copy to Neo-tree's clipboard |
| `x` | Cut to Neo-tree's clipboard |
| `p` | Paste from Neo-tree's clipboard |
| `<C-r>` | Clear Neo-tree's clipboard |
| `Y` | Copy the absolute path to the **system** clipboard |
| `i` | Show file details |
| `H` | Toggle hidden files |
| `/` | Fuzzy finder |
| `D` | Fuzzy finder (directories only) |
| `#` | Fuzzy sorter |
| `f` | Filter on submit |
| `<C-x>` | Clear filter |
| `[g` / `]g` | Previous / next git-modified file |
| `o` + `c`/`d`/`g`/`m`/`n`/`s`/`t` | Order by created / diagnostics / git status / modified / name / size / type |
| `e` | Toggle auto-expand width |
| `R` | Refresh |
| `<` / `>` | Previous / next source (filesystem, buffers, git status) |
| `<Esc>` | Cancel preview / close floating tree |
| `q` | Close Neo-tree |
| `?` | Show help with every mapping |

## Terminal (toggleterm)

`<Esc>` leaves terminal mode, so you can scroll, search and yank the output like a regular buffer. Press `i` (or just move back into the window) to type in the shell again.

| Keys | Mode | Action |
| :--- | :--- | :--- |
| `<C-t>` | n, t | Toggle (show/hide) the terminal |
| `<leader>tv` | n | Toggle terminal at the bottom (horizontal) |
| `<leader>ts` | n | Toggle terminal on the side (vertical) |
| `<leader>tf` | n | Toggle floating terminal |
| `<leader>ta` | n | Toggle all terminals |
| `<leader>tl` | v | Send the selected lines to the terminal |
| `<Esc>` | t | Exit terminal mode (go to normal mode) |
| `<A-Esc>` | t | Send a literal `Esc` to the running program (vi-mode, htop…) |
| `<C-h/j/k/l>` | t | Jump to another window straight from the terminal |
| `<C-S-v>` | t | Paste the system clipboard |
| `i` / `a` | n (terminal buffer) | Back to terminal mode |
| `y` / `yy` | n (terminal buffer) | Copy terminal output to the system clipboard |
| `p` | n (terminal buffer) | Paste the system clipboard into the shell |

> `<Esc>` is not remapped inside `lazygit`/`fzf` terminals, so those tools keep working normally.

## AI / LLMs (CodeCompanion)

See the [LLMs / CodeCompanion section of the README](../README.md#-llms--codecompanion) to configure the tokens.

| Keys | Mode | Action |
| :--- | :--- | :--- |
| `<leader>ac` | n, v | Toggle the chat (default adapter: Gemini) |
| `<leader>ag` | n | New chat with **Gemini** |
| `<leader>al` | n | New chat with **Claude Code** |
| `<leader>aa` | n, v | Action palette (prompt library, explain, fix, tests…) |
| `<leader>ai` | n, v | Inline prompt (`:CodeCompanion <prompt>`) — edits the buffer/selection |
| `<leader>ad` | v | Add the selection to the current chat |

### Inside the chat buffer

| Keys | Mode | Action |
| :--- | :--- | :--- |
| `<CR>` / `<C-s>` | n / i | Send the message |
| `q` | n | Stop the current request |
| `<C-c>` | n, i | Close the chat |
| `ga` | n | Change adapter and model |
| `gr` | n | Regenerate the last response |
| `gx` | n | Clear the chat |
| `gy` | n | Yank the last code block |
| `gc` | n | Insert an empty code block |
| `gf` | n | Fold all code blocks |
| `gR` | n | Open the file path under the cursor |
| `gs` | n | Toggle the system prompt |
| `gty` | n | Toggle auto-approval of tool calls (YOLO) |
| `gtx` | n | Reset cached tool approvals |
| `gba` / `gbd` | n | Toggle live-sync / diff-sync of pinned buffers |
| `gd` | n | Show debug info |
| `{` / `}` | n | Previous / next chat |
| `[[` / `]]` | n | Previous / next header |
| `<C-_>` | i | Open the completion menu (`/` commands, `#` context, `@` tools) |
| `?` | n | Show every chat keymap |

### Reviewing changes proposed by the LLM

| Keys | Action |
| :--- | :--- |
| `gv` | View the proposed diff |
| `g1` | Always accept changes in this buffer |
| `g2` | Accept the change |
| `g3` | Reject the change |
| `g4` | Cancel all pending tool calls |
| `{` / `}` | Previous / next hunk |

## Git (in buffers, no terminal needed)

`gitsigns` marks changed lines in the sign column of every file; `diffview` gives you the full `git diff` / `git log` experience inside buffers.

| Keys | Mode | Action |
| :--- | :--- | :--- |
| `<leader>gd` | n | **Toggle** the git diff of the whole working tree (file list + side-by-side diff) |
| `<leader>gD` | n | Toggle the same, but against the previous commit (`HEAD~1`) |
| `<leader>gh` | n | Toggle the git log of the repository, browsable in a buffer |
| `<leader>gf` | n | Toggle the git log of the current file |
| `<leader>gf` | v | Git log of the selected lines only |
| `<leader>gq` | n | Close any open Diffview, from any tab |

All four toggles close the view no matter which tab you are in — you don't have to walk back to the diff tab first.

Inside Diffview: `<Tab>` / `<S-Tab>` next/previous file, `g?` for the full help, `<leader>e` focus the file panel, `-` stage/unstage the file under the cursor.

### Hunks (gitsigns)

| Keys | Mode | Action |
| :--- | :--- | :--- |
| `]c` / `[c` | n | Next / previous hunk |
| `<leader>hP` | n | Preview the hunk in a floating window |
| `<leader>hd` | n | Diff the current file in a split |
| `<leader>hD` | n | Diff the whole project |
| `<leader>hs` / `<leader>hr` | n | Stage / reset hunk |
| `<leader>hS` / `<leader>hR` | n | Stage / reset the whole buffer |
| `<leader>hu` | n | Undo stage hunk |
| `<leader>hb` | n | Blame the current line |
| `<leader>hB` | n | Toggle inline blame for every line |
| `<leader>hx` | n | Toggle showing deleted lines |

## Markdown preview

Same idea as VS Code's side preview: a live-rendered page in your browser, synced with the cursor and updated as you type.

| Keys | Mode | Action |
| :--- | :--- | :--- |
| `<leader>mp` | n | Toggle Markdown preview in the browser |

The preview stays open when you leave the `.md` buffer — only `<leader>mp` shuts it down. One browser tab is reused for every Markdown file: open another `.md` and the same tab switches to it instead of piling up tabs.

## Search (Telescope)

| Keys | Mode | Action |
| :--- | :--- | :--- |
| `<leader>.` | n | Find files |
| `<leader>ff` | n | Find files |
| `<leader>fg` | n | Live grep (search text in files) |
| `<leader>fb` | n | Open buffers |
| `<leader>fh` | n | Help tags |
| `<leader>fr` | n | Resume the last search |
| `<leader>fs` | n | Treesitter symbols |
| `<leader>ft` | n | Open Telescope (all pickers) |
| `<leader>fvf` | n | Git files |
| `<leader>fvs` | n | Git status |
| `<leader>fvb` | n | Git branches |
| `<leader>fvcw` | n | Git commits |
| `<leader>fvcb` | n | Git commits of the current buffer |
| `<leader>fvx` | n | Git stash |
| `<leader>flr` | n | LSP references |
| `<leader>flD` | n | LSP definitions |
| `<leader>fli` | n | LSP implementations |
| `<leader>flt` | n | LSP type definitions |
| `<leader>flsb` | n | LSP document symbols |
| `<leader>flsw` | n | LSP workspace symbols |
| `<leader>fld` | n | Diagnostics |

> **Tip:** inside *any* Telescope picker, press `<C-/>` to open a floating list of every key mapped in that picker (move, preview scroll, open in split/tab, send to quickfix...). It's built into Telescope itself, so it works for every picker — including ones added later by other plugins.

## LSP

Available in any buffer with an attached language server (Nix, Python, Rust, TypeScript/JavaScript).

| Keys | Mode | Action |
| :--- | :--- | :--- |
| `K` / `<leader>lh` | n | Hover documentation |
| `<leader>lgd` | n | Go to definition |
| `<leader>lgD` | n | Go to declaration |
| `<leader>lgt` | n | Go to type definition |
| `<leader>lgi` | n | List implementations |
| `<leader>lgr` | n | List references |
| `<leader>lgn` / `<leader>lgp` | n | Next / previous diagnostic |
| `<leader>le` | n | Diagnostic float |
| `<leader>la` | n | Code action |
| `<leader>ln` | n | Rename symbol |
| `<leader>lf` | n | Format |
| `<leader>ltf` | n | Toggle format on save |
| `<leader>ls` | n | Signature help |
| `<leader>lH` | n | Document highlight |
| `<leader>lS` | n | Document symbols |
| `<leader>lws` | n | Workspace symbols |
| `<leader>lwa` / `<leader>lwr` / `<leader>lwl` | n | Add / remove / list workspace folders |

## Debugging (DAP)

| Keys | Mode | Action |
| :--- | :--- | :--- |
| `<leader>db` | n | Toggle breakpoint |
| `<leader>dc` | n | Continue |
| `<leader>dgc` | n | Continue to the cursor |
| `<leader>dgj` | n | Step over (next) |
| `<leader>dgi` | n | Step into |
| `<leader>dgo` | n | Step out |
| `<leader>dgk` | n | Step back |
| `<leader>dvi` / `<leader>dvo` | n | Go down / up the stack trace |
| `<leader>dh` | n | Hover |
| `<leader>dr` | n | Toggle REPL |
| `<leader>d.` | n | Re-run the last debug session |
| `<leader>dR` | n | Restart |
| `<leader>dq` | n | Terminate |

## Themes

| Keys | Mode | Action |
| :--- | :--- | :--- |
| `<leader>th` | n | Theme picker (live preview, choice is persisted) |
| `<leader>tr` | n | Reset theme to default |
| `<leader>td` | n | Show where the theme config is stored |

## Built-in Neovim mappings worth knowing

| Keys | Mode | Action |
| :--- | :--- | :--- |
| `gcc` / `gc` | n / v | Toggle comment |
| `grn` / `gra` / `grr` / `gri` / `grt` | n | LSP rename / code action / references / implementation / type definition |
| `gO` | n | LSP document symbols |
| `[d` / `]d` | n | Previous / next diagnostic |
| `<C-w>d` | n | Diagnostics under the cursor |
| `[b` / `]b` | n | Previous / next buffer |
| `[q` / `]q` | n | Previous / next quickfix item |
| `gx` | n, v | Open path/URL under the cursor with the system handler |
