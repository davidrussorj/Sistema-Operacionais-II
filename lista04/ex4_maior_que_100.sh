#!/bin/bash
# Lista 4 - Exercício 4: informa se o arquivo tem mais de 100 bytes

if [ $# -ne 1 ]; then
    echo "Uso: $0 <arquivo>" >&2
    exit 1
fi

if [ ! -e "$1" ]; then
    echo "O arquivo '$1' não existe." >&2
    exit 1
fi

tamanho=$(stat -L -c %s -- "$1") || exit 1

if [ "$tamanho" -gt 100 ]; then
    echo "'$1' tem $tamanho bytes: é maior que 100 bytes."
else
    echo "'$1' tem $tamanho bytes: não é maior que 100 bytes."
fi
