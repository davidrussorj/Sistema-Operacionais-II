#!/bin/bash
# Lista 4 - Exercício 7: renomeia *.mpeg3 para *.mp3 em um diretório

if [ $# -ne 1 ]; then
    echo "Uso: $0 <diretório>" >&2
    exit 1
fi

if [ ! -d "$1" ]; then
    echo "Erro: '$1' não é um diretório" >&2
    exit 1
fi

dir="${1%/}"
renomeados=0
for arquivo in "$dir"/*.mpeg3; do
    [ -e "$arquivo" ] || continue
    novo="${arquivo%.mpeg3}.mp3"
    if [ -e "$novo" ]; then
        echo "Pulando '$arquivo': '$novo' já existe" >&2
        continue
    fi
    if mv -- "$arquivo" "$novo"; then
        echo "'$arquivo' -> '$novo'"
        renomeados=$((renomeados + 1))
    fi
done

echo "$renomeados arquivo(s) renomeado(s)."
