#!/bin/bash
# Lista 4 - Exercício 12: shells únicos do /etc/passwd

if [ $# -gt 1 ]; then
    echo "Uso: $0 [arquivo_passwd]" >&2
    exit 1
fi

arquivo="${1:-/etc/passwd}"

if [ ! -r "$arquivo" ]; then
    echo "Erro: não foi possível ler '$arquivo'" >&2
    exit 1
fi

cut -d: -f7 "$arquivo" | sort | uniq
