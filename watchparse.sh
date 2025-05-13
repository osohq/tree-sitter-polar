#!/bin/bash

if (( $# < 1 )); then
    echo "usage: watchparse.sh <polar-file> [optional tree-sitter parse args]"
    exit 1
fi

polar="$1"; shift
args="$*"

ls grammar.js "$polar" | entr -c sh -c "tree-sitter generate && tree-sitter parse $polar $args"
