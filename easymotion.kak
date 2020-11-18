declare-option -hidden range-specs easymotion_ranges
declare-option -hidden str easymotion_lua %sh{printf "%s" "${kak_source%.kak}.lua"}
declare-option -hidden str easymotion_window
declare-option -hidden str easymotion_keys
declare-option -hidden str-to-str-map easymotion_map

declare-option str easymotion_chars 'jfkdlsahgurieowpqzt'

provide-module easymotion %§

hook -group easymotion global ModeChange push:normal:next-key\[on-key\] %{
    try %{ add-highlighter window/easymotion replace-ranges 'easymotion_ranges' }
}

hook -group easymotion global ModeChange pop:next-key\[on-key\]:normal %{
    remove-highlighter window/easymotion
}

define-command -hidden -params 0 easymotion-forward %{
    evaluate-commands -draft %{
        execute-keys <semicolon> Gb Gl
        evaluate-commands %{
            #echo -debug "kak_selection: %val{selection}"
            set-option window easymotion_window %val{selection}
        }
    }
    easymotion-worker 1
}

define-command -hidden -params 0 easymotion-backward %{
    evaluate-commands -draft %{
        execute-keys <semicolon> Gt Gh
        evaluate-commands %{
            #echo -debug "kak_selection: %val{selection}"
            set-option window easymotion_window %val{selection}
        }
    }
    easymotion-worker -1
}

define-command -hidden -params 1 easymotion-worker %{
    evaluate-commands %sh{
        # NOTE: comments below are intentional to make kakoune export them
        # kak_session
        # kak_easymotion_chars
        printf %s "$kak_opt_easymotion_window" |lua "$kak_opt_easymotion_lua" "$kak_timestamp" "$kak_cursor_line" "$kak_cursor_column" "$kak_bufname" "$1"  >/dev/null 2>&1
    }
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
    easymotion-forward
    easymotion-getKeys
    echo -debug %opt{easymotion_keys}
}

declare-user-mode easymotion

map global easymotion -docstring %{easymotion line down} <j> ": easymotion-j<ret>"

§

