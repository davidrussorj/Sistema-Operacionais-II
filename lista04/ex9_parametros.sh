#!/bin/bash
#
# Lista 4 - Exercício 9
#
# Enunciado: "Escreva um script que mostra todos os parâmetros recebidos na
# linha de comando, contando-os. Uma possível saída:
#     prompt$ ./parametros.sh a b c d e f
#     Parâmetro 1: a
#     Parâmetro 2: b
#     ...
#     Parâmetro 6: f"
#
# Uso:     ./ex9_parametros.sh <parâmetro1> [parâmetro2 ...]
#
# Status de saída:
#   0  parâmetros listados
#   2  uso incorreto (nenhum parâmetro)
#
# Teoria (Aula 10): $# e $1 - slide 30 | while - slide 43 | shift - slide 59 |
#                   $(( )) - slide 61 | ${10} - apoio, item 23

# Os scripts da lista são escritos para o bash (#!/bin/bash), mas o slide 23
# ensina também a "forma fácil", sh script.sh - e aí quem executa é o
# /bin/sh, que no Ubuntu é o dash, não o bash (slide 6: "verificar com
# ls -l /bin/sh"). O dash não tem alguns recursos do bash ([[ =~ ]], 10#...)
# e o echo dele interpreta \ de outro jeito. A variável BASH_VERSION só
# existe dentro do bash: se ela estiver vazia, o exec (slide 59) troca este
# processo por um bash rodando o mesmo script, com os mesmos argumentos e a
# mesma entrada.
[ -n "$BASH_VERSION" ] || exec bash "$0" "$@"

# uso: mostra como chamar o script e encerra com status 2 (uso incorreto).
uso() {
    if [ $# -gt 0 ]; then
        echo "Erro: $*" >&2
    fi
    echo "Uso: $0 <parâmetro1> [parâmetro2 ...]" >&2
    exit 2
}

# ---------------------------------------------------------------------------
# Validação
# ---------------------------------------------------------------------------

# Sem parâmetros não há o que listar. Um parâmetro vazio ("") é aceito: ele
# é um parâmetro de verdade e aparece como "Parâmetro 1: ".
[ $# -ge 1 ] || uso "informe pelo menos um parâmetro"

# ---------------------------------------------------------------------------
# Listagem
# ---------------------------------------------------------------------------

# Pegadinha: o jeito óbvio seria escrever $1, $2, ... com um contador, mas
# o shell lê $10 como $1 seguido do caractere "0" (com os parâmetros
# "a b c ... j", $10 dá "a0", não "j"). O bash aceita ${10} com chaves
# (item 23 do material de apoio), mas o shift funciona em qualquer sh: cada
# shift (slide 59) descarta o $1 e "anda" com os demais ($2 vira $1, $3 vira
# $2...), diminuindo o $#. Assim o laço só precisa ler $1, e para quando
# não sobra nenhum ($# = 0).
i=1
while [ $# -gt 0 ]; do
    # printf em vez de echo: o texto sai exatamente como veio, sem risco de
    # algum parâmetro ser interpretado (barras invertidas, -n...).
    # "$1" entre aspas mantém "verde claro" como um parâmetro só.
    printf 'Parâmetro %d: %s\n' "$i" "$1"
    shift
    # O contador é o do slide 43: i=$(($i+1)).
    i=$((i + 1))
done
exit 0
