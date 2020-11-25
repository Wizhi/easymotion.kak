declare-option -hidden range-specs easymotion_ranges # for ranges
declare-option -hidden str easymotion_lua %sh{printf "%s" "${kak_source%.kak}.lua"}
declare-option -hidden str easymotion_window # for window content
declare-option -hidden str easymotion_keys # XXX for on-key magic
declare-option -hidden str easymotion_jump # store the counter for operations

#declare-option str easymotion_chars 'jfkdlsahgurieowpqzt'

provide-module easymotion %§

hook -group easymotion global ModeChange pop:prompt:normal %{
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
        # kak_opt_easymotion_chars
        # kak_opt_extra_word_chars
        printf %s "$kak_opt_easymotion_window" |lua "$kak_opt_easymotion_lua" "$kak_timestamp" "$kak_cursor_line" "$kak_cursor_column" "$1" "$2"
    }
    # It can not be a hook as it would be triggered on every prompt command
    try %{ add-highlighter window/easymotion replace-ranges 'easymotion_ranges' }
}

define-command -hidden -params 1 easymotion-doJump %{
    # XXX: -on-change: autojump: jump when 2 keys pressed
    # XXX: -on-change: limit highlights based on input
    prompt -on-change 'echo -debug %val{text}' 'easymotion: ' %{
        echo -debug %val{text}
        evaluate-commands %sh{
            # NOTE: comments below are intentional to make kakoune export them
            # kak_opt_easymotion_chars
            printf "set-option window easymotion_jump %s\n" $(lua "$kak_opt_easymotion_lua" "$kak_text")
        }
        execute-keys %opt{easymotion_jump} %arg{1}
    }
}

define-command easymotion-j -params 0 %{
    easymotion-forward lines
    easymotion-doJump j
}

define-command easymotion-k -params 0 %{
    easymotion-backward lines
    easymotion-doJump k
}

define-command easymotion-w -params 0 %{
    easymotion-forward words
    easymotion-doJump w
}

define-command easymotion-b -params 0 %{
    easymotion-backward words
    easymotion-doJump b
}

declare-user-mode easymotion

map global easymotion -docstring %{easymotion line ↓} <j> ": easymotion-j<ret>"
map global easymotion -docstring %{easymotion line ↑} <k> ": easymotion-k<ret>"
map global easymotion -docstring %{easymotion word →} <w> ": easymotion-w<ret>"
map global easymotion -docstring %{easymotion word ←} <b> ": easymotion-b<ret>"

# XXX Remove these lines before release

map global normal <ű> ': enter-user-mode easymotion<ret>'

§

