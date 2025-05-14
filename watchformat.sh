#!/bin/bash

if (( $# < 1 )); then
    echo "usage: watchformat.sh <polar-file> [optional tree-sitter parse args]"
    exit 1
fi

polar="$1"; shift
args="$*"

ls queries/formatter.scm "$polar" | entr -c sh -c "topiary format --configuration topiary-polar.ncl --language polar $args < $polar"
