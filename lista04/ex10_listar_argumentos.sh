#!/bin/bash
# Lista 4 - Exercício 10: mostra todos os argumentos numerados

if [ $# -eq 0 ]; then
    echo "Uso: $0 <arg1> [arg2 ...]" >&2
    exit 1
fi

i=1
while [ $# -gt 0 ]; do
    echo "$i: $1"
    shift
    i=$((i + 1))
done
