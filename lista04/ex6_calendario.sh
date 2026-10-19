#!/bin/bash
#
# Lista 4 - Exercício 6
#
# Enunciado: "Crie um script que peça um mês e um ano ao usuário e depois
# apresente o calendário do mês/ano pedido. O comando cal é recomendado
# neste caso."
#
# Uso:     ./ex6_calendario.sh           (pergunta mês e ano no terminal)
#          printf '10\n2026\n' | ./ex6_calendario.sh    (sem digitar)
#
# Status de saída:
#   0  calendário mostrado
#   1  cal não instalado, entrada encerrada, mês ou ano inválido
#   2  uso incorreto (foram passados argumentos)
#
# Teoria (Aula 10): read - slide 25 | case com padrões - slides 45 a 47 |
#                   comparação aritmética - slide 34

# uso: mostra como chamar o script e encerra com status 2 (uso incorreto).
uso() {
    if [ $# -gt 0 ]; then
        echo "Erro: $*" >&2
    fi
    echo "Uso: $0   (o mês e o ano são perguntados depois de iniciar)" >&2
    exit 2
}

# erro: mostra a mensagem no stderr e encerra com status 1.
erro() {
    echo "Erro: $*" >&2
    exit 1
}

# ---------------------------------------------------------------------------
# Validações iniciais
# ---------------------------------------------------------------------------

# O mês e o ano são perguntados, não passados como argumento.
[ $# -eq 0 ] || uso "argumentos inesperados: $*"

# O cal não vem instalado por padrão no Ubuntu/WSL (pacote ncal). Melhor
# avisar antes de fazer as perguntas do que depois.
command -v cal > /dev/null ||
    erro "comando cal não encontrado (instale com: sudo apt install ncal)"

# ---------------------------------------------------------------------------
# Leitura (slide 25)
# ---------------------------------------------------------------------------

# -p: mostra a pergunta antes de ler (só aparece se a entrada for o teclado).
# -r: não deixa a barra invertida \ ser interpretada como escape.
# O read já remove espaços no começo e no fim do que foi digitado.
#
# O read retorna status diferente de 0 quando a entrada acaba (Ctrl+D, ou
# fim do texto enviado por pipe). Mas, se a última linha não tiver \n, ele
# lê o texto E retorna erro - por isso só é erro de verdade quando, além do
# status, a variável ficou vazia.
read -r -p "Mês (1-12): " mes || [ -n "$mes" ] ||
    erro "a entrada terminou antes de o mês ser informado"
read -r -p "Ano (ex.: 2026): " ano || [ -n "$ano" ] ||
    erro "a entrada terminou antes de o ano ser informado"

# ---------------------------------------------------------------------------
# Validação do mês
# ---------------------------------------------------------------------------

# case compara o texto com padrões de wildcard (slides 45-47), na ordem:
#   [1-9]    um dígito de 1 a 9           ("9")
#   0[1-9]   zero seguido de 1 a 9        ("09")
#   1[0-2]   10, 11 ou 12
# Qualquer outra coisa (vazio, 0, 13, letras, "1.5", "-1") cai no *.
case "$mes" in
    [1-9] | 0[1-9] | 1[0-2]) ;;
    *) erro "mês inválido: '$mes' (use um número de 1 a 12)" ;;
esac

# ---------------------------------------------------------------------------
# Validação do ano
# ---------------------------------------------------------------------------

# Primeiro só dígitos: vazio ('') ou qualquer caractere que não seja dígito
# (*[!0-9]*) é recusado, antes de qualquer conta.
case "$ano" in
    '' | *[!0-9]*) erro "ano inválido: '$ano' (use só dígitos, ex.: 2026)" ;;
esac

# Mais de 4 dígitos já está fora do intervalo do cal - e um número gigante
# estouraria o inteiro do test, que daria erro em vez de "falso".
[ ${#ano} -le 4 ] || erro "ano fora do intervalo 1-9999: '$ano'"

# O cal só aceita anos de 1 a 9999 (0 ou 0000 não existe no calendário).
if [ "$ano" -lt 1 ] || [ "$ano" -gt 9999 ]; then
    erro "ano fora do intervalo 1-9999: '$ano'"
fi

# ---------------------------------------------------------------------------
# Calendário
# ---------------------------------------------------------------------------

# Sempre os dois argumentos, nesta ordem: com um argumento só, "cal 10"
# mostraria o ANO 10 inteiro. E o ano é literal: "cal 10 26" é outubro do
# ano 26 d.C., não de 2026 - por isso a pergunta dá o exemplo com 4 dígitos.
cal "$mes" "$ano" || erro "o cal não conseguiu mostrar $mes/$ano"
