#!/bin/bash
# Lista 4 - Exercício 11: usuários do sistema em ordem alfabética

if [ $# -gt 1 ]; then
    echo "Uso: $0 [arquivo_passwd]" >&2
    exit 1
fi

arquivo="${1:-/etc/passwd}"

if [ ! -r "$arquivo" ]; then
    echo "Erro: não foi possível ler '$arquivo'" >&2
    exit 1
fi

cut -d: -f1 "$arquivo" | sort
