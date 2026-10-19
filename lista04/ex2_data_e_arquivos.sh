#!/bin/bash
# Lista 4 - Exercício 2: data de hoje e arquivos da conta

echo "Hoje é $(date '+%d/%m/%Y')"
echo
echo "Arquivos da conta ($HOME):"
ls -la "$HOME" || exit 1
