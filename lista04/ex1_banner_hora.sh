#!/bin/bash
# Lista 4 - Exercício 1: banner $(date | cut -c13-20)

if ! command -v banner > /dev/null; then
    echo "Erro: comando banner não encontrado (instale com: sudo apt install sysvbanner)" >&2
    exit 1
fi

echo "         1111111111222222222233333333334"
echo "1234567890123456789012345678901234567890"
date
echo
echo "cut -c13-20 -> '$(date | cut -c13-20)'"
echo

# shellcheck disable=SC2046
banner $(date | cut -c13-20)
