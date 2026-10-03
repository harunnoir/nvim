# Keymaps

The authoritative mapping source is `lua/config/keymaps.lua`.

## Discover mappings inside Neovim

```text
<leader>?   open the searchable keymap manual
<leader>fk  open the searchable keymap manual
:KeymapManual
```

The manual reads the mappings currently active in Neovim, including global and
current-buffer mappings. Raw `<Plug>` internals stay hidden. It never creates,
changes, or runs a mapping, and it only opens when you ask for it. Pause after
`<leader>` to let Mini Clue show only the available next keys for that prefix.

The `<leader>d`, `<leader>r`, and `<leader>4` groups exist only when an enabled
language provides a debugger, a REPL, or the 42 norm. They are missing rather
than broken when nothing does.

```text
<leader>a  whole-buffer actions
<leader>b  buffers
<leader>c  code
<leader>d  debug
<leader>f  find and files
<leader>g  Git
<leader>i  explicit AI assistance
<leader>m  editor modes
<leader>p  projects, tasks, sessions
<leader>q  problems and lists
<leader>r  REPL
<leader>t  toggles and learning mode
<leader>u  undo tree
<leader>w  windows and splits
<leader>x  terminal
<leader>4  42-school tools
```

## Undo history

```text
<leader>uu  open the undo tree
```

## Whole buffer

```text
<leader>aa  select the whole buffer
<leader>ay  copy the whole buffer to the system clipboard
<leader>ax  cut the whole buffer to the system clipboard
```

Normal `y`, `d`, and `p` still work for the selected text. Because the config
uses `clipboard=unnamedplus`, ordinary yanks also reach the system clipboard.

## Windows

```text
Ctrl+h/j/k/l       focus a neighboring split
Alt+h/j/k/l        resize the current split
<leader>wh/j/k/l   move the current split
<leader>wv         vertical split
<leader>ws         horizontal split
<leader>wc         close split
<leader>wo         keep only current split
<leader>we         equalize splits
<leader>wm         toggle maximizing the current split
```

Maximizing preserves the complete split layout. Press `<leader>wm` again to
restore it. Slimline shows `MAX` while the current tab contains a maximized split.
Unlike `<leader>wo`, this does not close the other windows.

## Flash and surrounds

```text
s            Flash jump
S            Flash Tree-sitter selection
ys{motion}   add surrounding
ds{char}     delete surrounding
cs{old}{new} replace surrounding
yss          surround current line
gsf / gsF    find surrounding right / left
gsh          highlight surrounding
gsn          set surround search distance
```

Flash keeps its fast single-key jump while Mini Surround uses the familiar
vim-surround-style operations. The two plugins no longer share the `s` prefix.

## Text objects

```text
af / if    around / inside a function
ac / ic    around / inside a class
]f / [f    next / previous function
```

These are Tree-sitter node selections, so they follow the syntax rather than
indentation. They work in Visual mode as a selection and in Operator-pending mode
as an operator: `dif`, `daf`, `cif`.

## Move and restructure

```text
Alt+h/j/k/l  move the visual selection (Normal line moves stay on ]e/[e)
gS           toggle a one-liner and an expanded argument list
```

mini.move only owns the visual-selection moves so Alt stays free for split
resizing in Normal mode. `gS` works as an operator (`gS}`) and in Visual mode.

## Git diff view

```text
<leader>gd  open the working-tree diff for the current files
<leader>gD  history of the current file
<leader>gv  close the diff view
```

diffview.nvim gives a side-by-side diff and a file-history browser; gitsigns
still owns hunk staging, blame, and inline previews. `:diffget` and `:diffput`
work inside either view to pull a change into the buffer or push one out.

## Todo comments

```text
]t           next TODO/FIX/HACK comment
[t           previous TODO/FIX/HACK comment
<leader>qt  browse project TODO comments in a Snacks list
```

`todo-comments.nvim` highlights TODO-style comments; `<leader>qt` fills the
quickfix list with them and opens the Snacks list view.

## Editor modes

```text
<leader>mm  enter minimal mode
<leader>mn  return to normal mode
<leader>mt  toggle minimal mode
```

Minimal mode keeps every split and all coding features active, but hides line
numbers, signs, folds, color columns, whitespace markers, winbars, the tabline,
the statusline, and command chrome. Returning to normal mode restores the exact
global and per-window interface settings from before minimal mode. The same
modes are available as `:ModeMinimal`, `:ModeNormal`, and `:ModeToggle`.

## Learning and assistance

AI actions are manual and scoped. The edit action is available only from an
active visual selection; 99 never receives a whole buffer from these mappings.

```text
Visual <leader>i9v  ask 99 to edit the selected code
Normal <leader>i9s  ask 99 to search and explain code locations
Normal <leader>i9o  open the latest 99 result
Normal <leader>i9m  select the 99 model
Normal <leader>i9x  cancel all active 99 requests
```

```text
<leader>tm  learning mode (syntax colors stay enabled)
<leader>td  diagnostics
<leader>tv  diagnostic virtual text
<leader>tW  warnings
<leader>tl  LSP
<leader>tc  completion
<leader>tf  format on save (off by default)
<leader>th  inlay hints
<leader>tw  line wrapping
<leader>ts  spelling
<leader>tn  relative numbers
```

## Terminal

```text
Ctrl+\      toggle the most recently used terminal
<leader>xt  toggle the most recently used terminal
<leader>xf  floating terminal
<leader>xh  horizontal terminal
<leader>xv  vertical terminal
<leader>xd  terminal in the current file directory
<leader>xp  terminal at the project root
<leader>xn  new named terminal
<leader>xl  select terminal
<leader>xr  restart terminal
<leader>xq  stop terminal
```

The quick toggle restores the same terminal process in its previous float or
split layout. Inside the Python REPL, `Ctrl+\` hides that REPL instead of opening
a separate shell. When no terminal has been used yet, it opens the default bottom
terminal.

## Python REPL

The REPL prefers the active virtual environment or project `.venv` before a
project-aware uv command or global fallback.

```text
<leader>rt  toggle REPL
<leader>rf  focus REPL
<leader>rh  hide REPL
<leader>rr  restart REPL
<leader>rl  send line
<leader>rs  send selection
<leader>rb  send block
<leader>rn  send block and move to the next one
<leader>rp  send paragraph
<leader>ru  send everything through the cursor
<leader>ra  send file
```
