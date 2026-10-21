#!/bin/bash
#
# Lista 4 - Exercício 6
#
# Enunciado: "Escreva um script que mostra na tela todos os parâmetros
# recebidos na linha de comando "grudados", ou seja, como uma única palavra.
# Dica: investigue o comando tr, que traduz uma cadeia de caracteres em
# outra (translate). Um exemplo de saída seria:
#     prompt$ ./juntaparms.sh a b c d e f verde azul
#     abcdefverdeazul"
#
# Uso:     ./ex6_juntaparms.sh <parâmetro1> [parâmetro2 ...]
#
# Status de saída:
#   0  parâmetros mostrados grudados
#   1  os parâmetros só têm espaços: não sobra nada para mostrar
#   2  uso incorreto (nenhum parâmetro)
#
# Teoria (Aula 10): $* e o IFS - slides 29-30 | pipe - slide 16 |
#                   $(comando) - slide 60

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

# erro: mostra a mensagem no stderr e encerra com status 1.
erro() {
    echo "Erro: $*" >&2
    exit 1
}

# ---------------------------------------------------------------------------
# Validação
# ---------------------------------------------------------------------------

[ $# -ge 1 ] || uso "informe pelo menos um parâmetro"

# ---------------------------------------------------------------------------
# Junção
# ---------------------------------------------------------------------------

# 1. "$*" junta todos os parâmetros numa string só, separados pelo primeiro
#    caractere do IFS (slide 30), que normalmente é o espaço (slide 29):
#    a b c verde azul  ->  "a b c verde azul".
# 2. O pipe (slide 16) entrega essa string ao tr, que com -d apaga os
#    caracteres do conjunto. [:space:] é a classe de "espaços em branco":
#    espaço, TAB e quebra de linha. Com isso some tanto o espaço que o $*
#    colocou entre os parâmetros quanto um espaço que já estivesse DENTRO de
#    um parâmetro ("verde claro" vira "verdeclaro") - o resultado é sempre
#    uma única palavra, como pede o enunciado.
# printf '%s' em vez de echo: o echo acrescentaria um \n (que o tr apagaria
# de qualquer jeito) e, se o único parâmetro fosse "-n", o leria como opção
# e não imprimiria nada.
# O resultado vai para uma variável com $(...) (slide 60) para ser
# conferido antes de imprimir.
resultado=$(printf '%s' "$*" | tr -d '[:space:]')

# Se todos os parâmetros eram só espaços (ou vazios, como ""), não sobrou
# nada: em vez de imprimir uma linha em branco, avisa.
[ -n "$resultado" ] || erro "os parâmetros só têm espaços: não sobra nada para juntar"

# Agora sim com quebra de linha no final, para o prompt voltar na linha de
# baixo.
printf '%s\n' "$resultado"
exit 0
