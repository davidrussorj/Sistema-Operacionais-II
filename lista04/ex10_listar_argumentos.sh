#!/bin/bash
#
# Lista 4 - Exercício 10
#
# Enunciado: "Mostre na tela todos os argumentos recebidos na linha de
# comando, imprimindo-os como abaixo. Se forem mais do que 9, o comando
# shift será necessário.
#     1: parâmetro 1
#     2: parâmetro 2
#     ..."
#
# Uso:     ./ex10_listar_argumentos.sh <arg1> [arg2 ...]
#
# Status de saída:
#   0  argumentos listados
#   2  uso incorreto (nenhum argumento)
#
# Teoria (Aula 10): $# e $1 - slide 30 | while - slide 43 | shift - slide 59
#                   $(( )) - slide 61 | ${10} - apoio, item 23

# uso: mostra como chamar o script e encerra com status 2 (uso incorreto).
uso() {
    if [ $# -gt 0 ]; then
        echo "Erro: $*" >&2
    fi
    echo "Uso: $0 <arg1> [arg2 ...]" >&2
    exit 2
}

# ---------------------------------------------------------------------------
# Validação
# ---------------------------------------------------------------------------

# Sem argumentos não há o que listar. Um argumento vazio ("") é aceito: ele
# é um argumento de verdade e aparece como "1: ".
[ $# -ge 1 ] || uso "informe pelo menos um argumento"

# ---------------------------------------------------------------------------
# Listagem
# ---------------------------------------------------------------------------

# Pegadinha que o enunciado aponta: o shell lê $10 como $1 seguido do
# caractere "0" (com os argumentos "a b c ... j", $10 dá "a0", não "j").
# O bash aceita ${10}, mas a solução pedida é o shift, que funciona em
# qualquer sh: cada shift descarta o $1 e "anda" com os demais ($2 vira $1,
# $3 vira $2...), diminuindo o $#. Assim o laço só precisa ler $1.
i=1
while [ $# -gt 0 ]; do
    # printf em vez de echo: o texto é impresso exatamente como veio, sem
    # risco de algum argumento ser interpretado (barras invertidas, -n...).
    # "$1" entre aspas mantém "l com espaço" como um argumento só.
    printf '%d: %s\n' "$i" "$1"
    shift
    i=$((i + 1))
done
