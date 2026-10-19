#!/bin/bash
# Lista 4 - Exercício 3: testa se um arquivo existe

if [ $# -ne 1 ]; then
    echo "Uso: $0 <arquivo>" >&2
    exit 1
fi

if [ -e "$1" ]; then
    echo "O arquivo '$1' existe."
elif [ -L "$1" ]; then
    echo "'$1' é um link simbólico quebrado: o link existe, mas o arquivo para onde ele aponta não."
    exit 1
else
    echo "O arquivo '$1' não existe."
    exit 1
fi
