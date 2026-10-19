#!/bin/bash
# Lista 4 - Exercício 5: quantos processos estão em execução

processos=(/proc/[0-9]*)
total=${#processos[@]}

echo "Processos em execução, contando este script: $total"
echo "Processos em execução, sem contar este script: $((total - 1))"
