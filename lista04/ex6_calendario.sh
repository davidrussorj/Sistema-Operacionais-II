#!/bin/bash
# Lista 4 - Exercício 6: calendário de um mês/ano pedido ao usuário

if ! command -v cal > /dev/null; then
    echo "Erro: comando cal não encontrado (instale com: sudo apt install ncal)" >&2
    exit 1
fi

read -r -p "Mês (1-12): " mes
read -r -p "Ano (ex.: 2026): " ano

case "$mes" in
    [1-9] | 0[1-9] | 1[0-2]) ;;
    *)
        echo "Mês inválido: '$mes'" >&2
        exit 1
        ;;
esac

case "$ano" in
    '' | *[!0-9]*)
        echo "Ano inválido: '$ano'" >&2
        exit 1
        ;;
esac

if [ "$ano" -lt 1 ] || [ "$ano" -gt 9999 ]; then
    echo "Ano fora do intervalo 1-9999: '$ano'" >&2
    exit 1
fi

cal "$mes" "$ano"
