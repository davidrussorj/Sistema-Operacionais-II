#!/bin/bash
# Lista 4 - Exercício 15: espaço usado por cada diretório da conta, em ordem numérica

if [ $# -gt 1 ]; then
    echo "Uso: $0 [diretório_base]" >&2
    exit 1
fi

base="${1:-$HOME}"

if [ ! -d "$base" ]; then
    echo "Erro: '$base' não é um diretório" >&2
    exit 1
fi

printf 'KB\tDiretório\n'
find "$base" -mindepth 1 -maxdepth 1 -type d -exec du -sk {} + | sort -n
