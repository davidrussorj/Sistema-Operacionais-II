#!/bin/bash
#
# Lista 4 - Exercício 1
#
# Enunciado: "Faça um script com a linha de comando abaixo e tente explicar
# o resultado apresentado na tela:   banner $(date | cut -c13-20)"
#
# Uso:     ./ex1_banner_hora.sh          (não recebe argumentos)
#
# Status de saída:
#   0  sucesso
#   1  o comando banner não está instalado
#   2  uso incorreto (foram passados argumentos)
#
# Teoria (Aula 10): $(comando) - slide 60 | pipe - slide 16 |
#                   separação de palavras pelo IFS - slides 29 e 30

# ---------------------------------------------------------------------------
# Funções auxiliares (slides 53-57: funções precisam ser declaradas antes
# de serem usadas)
# ---------------------------------------------------------------------------

# uso: mostra como chamar o script (e, se recebeu, o motivo do erro) no
# stderr e encerra com status 2, o código convencional de "uso incorreto".
uso() {
    if [ $# -gt 0 ]; then
        echo "Erro: $*" >&2
    fi
    echo "Uso: $0   (este script não recebe argumentos)" >&2
    exit 2
}

# erro: mostra a mensagem no stderr (descritor 2, slide 13) e encerra com
# status 1. É o equivalente em shell ao perror() + exit() dos programas em C.
erro() {
    echo "Erro: $*" >&2
    exit 1
}

# ---------------------------------------------------------------------------
# Validações
# ---------------------------------------------------------------------------

# O exercício não usa argumentos. Se vierem argumentos, provavelmente quem
# chamou se enganou de script, então é melhor avisar do que ignorar.
[ $# -eq 0 ] || uso "argumentos inesperados: $*"

# O banner não vem instalado no Ubuntu nem no WSL. "command -v" procura o
# comando no PATH sem executá-lo; sem essa checagem, o shell só imprimiria
# "banner: command not found" no fim da saída, sem dizer o que fazer.
command -v banner > /dev/null ||
    erro "comando banner não encontrado (instale com: sudo apt install sysvbanner)"

# ---------------------------------------------------------------------------
# Explicação visual do que a linha do enunciado faz
# ---------------------------------------------------------------------------

# Régua de colunas: a linha de cima é a dezena e a de baixo a unidade. Lidas
# juntas, mostram em qual coluna cai cada caractere da saída do date.
echo "         1111111111222222222233333333334"
echo "1234567890123456789012345678901234567890"

# Saída padrão do date, por exemplo "Mon Oct 19 15:49:06 -03 2026". Pela
# régua dá para ver que a hora começa na coluna 12, não na 13.
agora=$(date)
echo "$agora"
echo

# O pedaço que o cut recorta (colunas 13 a 20), entre apóstrofos para o
# espaço do final ficar visível: "5:49:06 " (o 1º dígito da hora se perde).
echo "cut -c13-20 -> '$(echo "$agora" | cut -c13-20)'"
echo

# ---------------------------------------------------------------------------
# A linha pedida no enunciado, exatamente como foi escrita
# ---------------------------------------------------------------------------

# 1. O shell executa primeiro o que está dentro de $(...): date | cut.
# 2. Troca o $(...) pelo texto que o comando imprimiu ("5:49:06 ").
# 3. Como o $(...) NÃO está entre aspas, separa esse texto em palavras
#    usando o IFS: o espaço do final some e sobra uma palavra, "5:49:06".
# 4. O banner recebe essa única palavra e a desenha em letras grandes.
# O shellcheck avisa sobre o $(...) sem aspas (SC2046); aqui é proposital,
# porque é a linha do enunciado.
# shellcheck disable=SC2046
banner $(date | cut -c13-20)
