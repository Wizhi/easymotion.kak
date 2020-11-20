declare-option -hidden range-specs easymotion_ranges # for ranges
declare-option -hidden str easymotion_lua %sh{printf "%s" "${kak_source%.kak}.lua"}
declare-option -hidden str easymotion_window # for window content
declare-option -hidden str easymotion_keys # XXX for on-key magic
declare-option -hidden str easymotion_jump # store the counter for operations

declare-option str easymotion_chars 'jfkdlsahgurieowpqzt'

provide-module easymotion %§

hook -group easymotion global ModeChange push:normal:next-key\[on-key\] %{
    try %{ add-highlighter window/easymotion replace-ranges 'easymotion_ranges' }
}

hook -group easymotion global ModeChange pop:next-key\[on-key\]:normal %{
    remove-highlighter window/easymotion
}

define-command -hidden -params 1 easymotion-forward %{
    evaluate-commands -draft %{
        execute-keys <space> <semicolon> Gb Gl
        evaluate-commands %{
            #echo -debug "kak_selection: %val{selection}"
            set-option window easymotion_window %val{selection}
        }
    }
    easymotion-worker %arg{@} 1
}

define-command -hidden -params 1 easymotion-backward %{
    evaluate-commands -draft %{
        execute-keys <space> <semicolon> Gt Gh
        evaluate-commands %{
            #echo -debug "kak_selection: %val{selection}"
            set-option window easymotion_window %val{selection}
        }
    }
    easymotion-worker %arg{@} -1
}

define-command -hidden -params 2 easymotion-worker %{
    evaluate-commands %sh{
        # NOTE: comments below are intentional to make kakoune export them
        # easymotion_chars
        printf %s "$kak_opt_easymotion_window" |lua "$kak_opt_easymotion_lua" "$kak_timestamp" "$kak_cursor_line" "$kak_cursor_column" "$1" "$2"
    }
    # XXX: this should be a hook
    try %{ add-highlighter window/easymotion replace-ranges 'easymotion_ranges' }
}

define-command -hidden -params 0 easymotion-getKeys %{
    on-key %{
        set-option window easymotion_keys %val{key}
    }
    hook -once -group easymotion window NormalIdle .* %{
        on-key %{
            set-option -add window easymotion_keys %val{key}
        }
    }
}

define-command easymotion-j -params 0 %{
    easymotion-forward lines
}

define-command easymotion-w -params 0 %{
    easymotion-forward words
}



declare-user-mode easymotion

map global easymotion -docstring %{easymotion line down} <j> ": easymotion-j<ret>"
map global easymotion -docstring %{easymotion line up} <k> ": easymotion-k<ret>"
map global easymotion -docstring %{easymotion word forward} <w> ": easymotion-w<ret>"
map global easymotion -docstring %{easymotion word backward} <b> ": easymotion-b<ret>"

# Remove these lines before release

map global normal <ű> ': enter-user-mode easymotion'

§

