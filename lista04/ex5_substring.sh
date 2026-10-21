#!/bin/bash
#
# Lista 4 - Exercício 5
#
# Enunciado: "Escreva um script que receba duas palavras como parâmetro e
# verifica se a primeira palavra está contida na segunda. O script mostra
# uma mensagem informativa em caso de sucesso, caso contrário não exibe
# nada. Um exemplo de saída seria:
#     prompt$ ./substring.sh ana banana
#     ana está contida em banana
#     prompt$ ./substring.sh banana maria
#     prompt$ ./substring.sh banana
#     prompt$ ./substring.sh
#     prompt$"
#
# Uso:     ./ex5_substring.sh <palavra> <outra_palavra>
#
# O exemplo do enunciado mostra que, com um argumento só ou nenhum, o script
# também não imprime nada. Por isso este é o único script da lista que NÃO
# mostra a mensagem de uso: quem precisar saber o que aconteceu olha o
# status de saída ($?), como no grep -q.
#
# Status de saída:
#   0  a primeira palavra está contida na segunda (e a mensagem é mostrada)
#   1  não está contida (nada é mostrado)
#   2  uso incorreto: quantidade de palavras diferente de 2, ou alguma
#      palavra vazia (nada é mostrado)
#
# Teoria (Aula 10): case - slides 45-47 | wildcard * - slide 17 |
#                   -z / -n - slide 33 | $1, $2 e $# - slide 30

# ---------------------------------------------------------------------------
# Validações (silenciosas, como pede o exemplo)
# ---------------------------------------------------------------------------

# Exatamente duas palavras.
[ $# -eq 2 ] || exit 2

# Uma palavra vazia ("") não é uma palavra. E, pela lógica de "estar
# contida", o texto vazio estaria contido em qualquer outro, então
# ./ex5_substring.sh "" banana diria que "está contida" - um resultado sem
# sentido para quem pediu para comparar palavras.
[ -n "$1" ] || exit 2
[ -n "$2" ] || exit 2

# ---------------------------------------------------------------------------
# Verificação
# ---------------------------------------------------------------------------

# O case compara a segunda palavra com o padrão *"$1"*: "qualquer coisa
# (inclusive nada), a primeira palavra, qualquer coisa" - o * é o mesmo
# wildcard do slide 17, usado dentro do case como no slide 46 (n*, N*).
# Assim, "ana" casa com "banana" (b + ana + na) e "banana" casa consigo
# mesma (as duas sobras vazias).
#
# As aspas em "$1" são o ponto principal: dentro das aspas, os caracteres
# da palavra valem literalmente. Sem elas (*$1*), uma palavra com * ou ?
# viraria parte do padrão: ./ex5_substring.sh '?' banana casaria (? = um
# caractere qualquer) e diria que "?" está contida em "banana".
#
# A comparação diferencia maiúsculas de minúsculas: "Ana" não está contida
# em "banana".
case "$2" in
    *"$1"*)
        # printf '%s' imprime cada palavra exatamente como veio. Com echo,
        # uma palavra com \ (ex.: 'a\tb') poderia virar um TAB: o echo do
        # sh do Ubuntu (dash) sempre interpreta essas sequências.
        printf '%s está contida em %s\n' "$1" "$2"
        exit 0
        ;;
esac

# Não está contida: não mostra nada, só o status.
exit 1
