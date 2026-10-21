#!/bin/bash
#
# Lista 4 - Exercício 3
#
# Enunciado: "Escreva um script que, dados dois números como parâmetro,
# mostra a relação entre eles. Uma possível saída seria:
#     prompt$ ./relacao.sh 3 5
#     3 é menor que 5
#     prompt$ ./relacao.sh 5 3
#     5 é maior que 3
#     prompt$ ./relacao.sh 5 5
#     5 é igual a 5"
#
# Uso:     ./ex3_relacao.sh <número1> <número2>    (inteiros; podem ser negativos)
#
# Status de saída:
#   0  relação mostrada
#   1  algum dos argumentos não é um número inteiro, ou é grande demais
#   2  uso incorreto (quantidade errada de argumentos ou argumento vazio)
#
# Teoria (Aula 10): test e [ ] - slide 32 | -lt, -gt - slide 34 |
#                   $1, $2 e $# - slide 30 | if/elif/else - slides 36 e 39

# uso: mostra como chamar o script e encerra com status 2 (uso incorreto).
uso() {
    if [ $# -gt 0 ]; then
        echo "Erro: $*" >&2
    fi
    echo "Uso: $0 <número1> <número2>" >&2
    exit 2
}

# erro: mostra a mensagem no stderr e encerra com status 1.
erro() {
    echo "Erro: $*" >&2
    exit 1
}

# valida_inteiro VALOR
#   Encerra com erro se VALOR não for um número inteiro que o [ ] consiga
#   comparar. Duas etapas:
#   1. o formato: um "-" opcional seguido de um ou mais dígitos. O [[ =~ ]]
#      do bash (item 22 do material de apoio) compara com uma expressão
#      regular. Sem isso, "3.5" e "abc" chegariam ao [ e ele imprimiria o
#      próprio erro, "integer expression expected", no meio da saída;
#   2. o tamanho: o [ trabalha com inteiros de 64 bits (até
#      9223372036854775807). Um número maior tem o formato certo, mas o [
#      recusa. "[ x -eq x ]" é o jeito clássico de perguntar ao próprio [
#      se ele aceita o valor; o 2> /dev/null (slide 14) esconde o erro dele.
valida_inteiro() {
    [[ "$1" =~ ^-?[0-9]+$ ]] || erro "'$1' não é um número inteiro"
    [ "$1" -eq "$1" ] 2> /dev/null || erro "'$1' é grande demais (o limite é 9223372036854775807)"
}

# ---------------------------------------------------------------------------
# Validações
# ---------------------------------------------------------------------------

# Exatamente dois números ($# = quantidade de parâmetros, slide 30).
[ $# -eq 2 ] || uso "informe exatamente dois números (recebidos: $#)"

# Um argumento vazio ("") é engano de quem chamou, não "um número inválido".
[ -n "$1" ] || uso "o primeiro número não pode ser vazio"
[ -n "$2" ] || uso "o segundo número não pode ser vazio"

valida_inteiro "$1"
valida_inteiro "$2"

# ---------------------------------------------------------------------------
# Comparação
# ---------------------------------------------------------------------------

# A pegadinha do exemplo do enunciado: ele usa só if/else com -gt, então
# quando o número é IGUAL a 10 cai no else e imprime "é menor que 10". Com
# dois números são três casos possíveis, e por isso é preciso o elif
# (slide 39): menor, maior e, se não é nenhum dos dois, igual.
#
# -lt e -gt comparam como NÚMEROS (slide 34). Os outros jeitos que parecem
# funcionar estão errados:
#   [ "$1" > "$2" ]   dentro do [ o > é redirecionamento: cria um arquivo
#                     com o nome do 2º número e o teste é sempre verdadeiro;
#   [ "$1" \< "$2" ]  compara como TEXTO, caractere a caractere: "10" vem
#                     antes de "9" (porque '1' < '9'), então 10 seria
#                     "menor" que 9.
# As aspas mantêm o teste válido mesmo se algo escapasse da validação.
if [ "$1" -lt "$2" ]; then
    echo "$1 é menor que $2"
elif [ "$1" -gt "$2" ]; then
    echo "$1 é maior que $2"
else
    echo "$1 é igual a $2"
fi
exit 0
