#!/bin/bash
# Lista 4 - Exercício 16: busca a partir de / os arquivos do usuário

if [ $# -gt 1 ]; then
    echo "Uso: $0 [diretório_inicial]" >&2
    exit 1
fi

inicio="${1:-/}"
usuario=$(id -un)

find "$inicio" -user "$usuario" > arq.txt 2> erros.txt

echo "Arquivos de $usuario encontrados a partir de $inicio: $(wc -l < arq.txt) (lista em arq.txt)"
echo "Mensagens de erro: $(wc -l < erros.txt) (em erros.txt)"
