#!/bin/bash
# Lista 4 - Exercício 8: renomeia extensões de forma interativa

read -r -p "Diretório: " dir
read -r -p "Extensão atual (ex.: mpeg3): " ext_antiga
read -r -p "Nova extensão (ex.: mp3): " ext_nova

dir="${dir/#\~/$HOME}"
ext_antiga="${ext_antiga#.}"
ext_nova="${ext_nova#.}"

if [ ! -d "$dir" ]; then
    echo "Erro: '$dir' não é um diretório" >&2
    exit 1
fi

if [ -z "$ext_antiga" ] || [ -z "$ext_nova" ]; then
    echo "Erro: as duas extensões precisam ser informadas" >&2
    exit 1
fi

if [ "$ext_antiga" = "$ext_nova" ]; then
    echo "As extensões são iguais, nada a fazer."
    exit 0
fi

dir="${dir%/}"
renomeados=0
for arquivo in "$dir"/*."$ext_antiga"; do
    [ -e "$arquivo" ] || continue
    novo="${arquivo%."$ext_antiga"}.$ext_nova"
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
