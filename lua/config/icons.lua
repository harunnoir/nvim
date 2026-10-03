--[[
Nerd Font glyphs this config owns: state, tooling, and the titles of focused
windows. Deliberately NOT here:

  * file and LSP-kind icons  -> mini.icons
  * picker and status labels  -> Snacks and Mini Clue keep their own

That split exists so this table never has to be kept in sync with a plugin's
defaults. Add a glyph only when it names a state this config decides, not when
it merely decorates something.
]]
return {
    terminal = '',
    repl = '',
    cwd = '󰉋',
    toggle_on = '',
    toggle_off = '',
    learning = '󰗚',
    maximize = '󰁌',
    recording = '󰑋',
    format = '󰉼',
    success = '',
    pending = '',
    error = '',
    warn = '',
    info = '',
    hint = '',
    breakpoint = '',
    stopped = '',
    bug = '',
    todo = '',
    hack = '',
    perf = '',
    note = '',
    test = '󰙨',
    fold_open = '',
    fold_closed = '',
}
