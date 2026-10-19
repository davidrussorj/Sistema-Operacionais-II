#!/bin/bash
# Lista 4 - Exercício 9: número de linhas e de palavras de um arquivo

if [ $# -ne 1 ]; then
    echo "Uso: $0 <arquivo>" >&2
    exit 1
fi

if [ ! -f "$1" ]; then
    echo "Erro: '$1' não existe ou não é um arquivo regular" >&2
    exit 1
fi

linhas=$(wc -l < "$1") || exit 1
palavras=$(wc -w < "$1") || exit 1

if [ -s "$1" ] && [ -n "$(tail -c 1 "$1")" ]; then
    linhas=$((linhas + 1))
fi

echo "Linhas: $linhas"
echo "Palavras: $palavras"
