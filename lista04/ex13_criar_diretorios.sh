#!/bin/bash
# Lista 4 - Exercício 13: cria dir1..dir5, cada um com file1..file3

if [ $# -gt 1 ]; then
    echo "Uso: $0 [diretório_base]" >&2
    exit 1
fi

base="${1:-.}"

for n in $(seq 1 5); do
    mkdir -p "$base/dir$n" || exit 1
    for m in $(seq 1 3); do
        touch "$base/dir$n/file$m" || exit 1
    done
done

echo "Criados 5 diretórios com 3 arquivos cada em '$base'."
