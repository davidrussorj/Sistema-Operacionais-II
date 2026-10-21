#!/bin/bash
#
# Lista 4 - Exercício 4
#
# Enunciado: "Escreva um script que recebe um número como parâmetro e o
# diminui até chegar a zero, mostrando na tela cada passo em uma mesma
# linha. Uma possível saída seria:
#     prompt$ ./zerador.sh 5
#     5 4 3 2 1 0
#     prompt$ ./zerador.sh 10
#     10 9 8 7 6 5 4 3 2 1 0"
#
# Uso:     ./ex4_zerador.sh <número inteiro maior ou igual a zero>
#
# Status de saída:
#   0  contagem mostrada
#   1  o argumento não é um inteiro, é negativo ou é grande demais
#   2  uso incorreto (quantidade errada de argumentos ou argumento vazio)
#
# Teoria (Aula 10): while - slide 43 | $(( )) - slides 61-62 (o slide 61 é
#                   um contador com while) | printf - slide 59

# uso: mostra como chamar o script e encerra com status 2 (uso incorreto).
uso() {
    if [ $# -gt 0 ]; then
        echo "Erro: $*" >&2
    fi
    echo "Uso: $0 <número inteiro maior ou igual a zero>" >&2
    exit 2
}

# erro: mostra a mensagem no stderr e encerra com status 1.
erro() {
    echo "Erro: $*" >&2
    exit 1
}

# ---------------------------------------------------------------------------
# Validações
# ---------------------------------------------------------------------------

[ $# -eq 1 ] || uso "informe exatamente um número (recebidos: $#)"
[ -n "$1" ] || uso "o número não pode ser vazio"

# Um negativo é um inteiro válido, mas diminuindo a partir dele nunca se
# chega a zero: o laço não terminaria. Ele ganha uma mensagem própria, antes
# do teste de formato, para não ser tratado como "não é um número".
[[ "$1" =~ ^-[0-9]+$ ]] && erro "'$1' é negativo: diminuindo, ele nunca chega a zero"

# Só dígitos (o [[ =~ ]] compara com uma expressão regular, item 22 do
# material de apoio). Sem isso, "abc" ou "3.5" chegariam ao [ e ele
# imprimiria o próprio erro, "integer expression expected".
[[ "$1" =~ ^[0-9]+$ ]] || erro "'$1' não é um número inteiro"

# Inteiros do shell têm 64 bits. Um número maior que 9223372036854775807
# tem o formato certo, mas o [ recusa, e o $(( )) "dá a volta" sem avisar
# e calcula com um valor errado. "[ x -eq x ]" pergunta ao próprio [ se ele
# aceita o valor (o 2> /dev/null esconde a mensagem de erro dele).
[ "$1" -eq "$1" ] 2> /dev/null || erro "'$1' é grande demais (o limite é 9223372036854775807)"

# ---------------------------------------------------------------------------
# Contagem regressiva
# ---------------------------------------------------------------------------

# Pegadinha do $(( )): um número que começa com 0 é lido em base 8 (octal).
# Sem tratamento, "010" seria 8 e a contagem sairia "010 7 6 5 ...", e
# "08" daria erro ("value too great for base"), porque 8 não é dígito
# octal. O prefixo 10# manda o $(( )) ler o número em base 10.
n=$((10#$1))

# Tudo na mesma linha: o primeiro número sai sozinho e cada passo seguinte
# sai com um espaço ANTES, então a linha não termina com espaço sobrando. O
# printf (slide 59) só quebra a linha quando o formato tem \n; o echo
# quebraria a cada número (seria preciso echo -n).
printf '%d' "$n"

# O laço é o do slide 61 ao contrário: em vez de somar 1 até chegar a 10,
# subtrai 1 enquanto ainda for maior que zero.
while [ "$n" -gt 0 ]; do
    n=$((n - 1))
    printf ' %d' "$n"
done

# Fim da linha.
echo
exit 0
