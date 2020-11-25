# Warning

`easymotion.kak` is alpha quality. There are _real_ bugs in it :-(

# About

`easymotion.kak` is a Kakoune plugin inspired by vim-easymotion
plugin. It that does not ring a bell it makes buffer movement easier.

This plugin provides a couple of commands to make line and word based
jumps predictable (by providing two character long keystrokes), so You
do not have to calculate `count` numbers or hammer `j`, `k` or `w`, `b`.

# Features

The plugin does not change Kakoune defaults at all. It does not provide
any defaults, but You can find some advice regarding setting up in
`easymotion.asciidoc`.
 - Every movement is done with Kakoune commands.
 - Features a line-based and a word-based mode. (No `f` and `t` movements. I made
`quickscope.kak` for that.)
 - Line mode use `j` and `k` keys with proper `count` values. You can use this
method instead of relative line numbering.
 - Word mode moves with `w` and `b` keys. This plugin just highlights movement points.
 - Provide easymotion user mode for better discover-ability.

# Installing and Using

See `easymotion.asciidoc` file.

# Ideas
 - [vim-easymotion](https://github.com/easymotion/vim-easymotion)

# Similar Kakoune plugins
 - [kakoune-easymotion](https://github.com/danr/kakoune-easymotion)
 - [quickscope.kak](https://git.sr.ht/~voroskoi/quickscope.kak)

