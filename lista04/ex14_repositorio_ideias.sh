#!/bin/bash
# Lista 4 - Exercício 14: adiciona uma ideia ao repositório de ideias

if [ $# -eq 0 ]; then
    echo "Uso: $0 <ideia>" >&2
    exit 1
fi

arquivo="${IDEIAS:-/ideias.txt}"

if ! echo "$(date '+%d/%m/%Y %H:%M') $*" >> "$arquivo"; then
    echo "Erro: não foi possível escrever em '$arquivo'." >&2
    echo "Para liberar: sudo touch '$arquivo' && sudo chown \"\$USER\" '$arquivo'" >&2
    exit 1
fi

echo "Ideia registrada em $arquivo:"
tail -n 1 "$arquivo"
