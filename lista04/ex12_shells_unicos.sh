#!/bin/bash
#
# Lista 4 - Exercício 12
#
# Enunciado: "Um dos parâmetros de cada linha do arquivo /etc/passwd é o
# shell usado pelo usuário (7º campo). Escreva um script capaz de listar
# todos os shells únicos existentes neste arquivo. O comando uniq pode ser
# útil."
#
# Uso:     ./ex12_shells_unicos.sh [arquivo_passwd]
#          sem argumento, usa /etc/passwd; o argumento serve para testar com
#          um arquivo fixo (testes/passwd_exemplo) e ter saída previsível.
#
# Status de saída:
#   0  shells listados
#   1  arquivo inexistente, vazio, sem leitura ou sem nenhuma linha válida
#   2  uso incorreto (argumentos demais ou nome vazio)
#
# Teoria (Aula 10): pipe - slide 16 | testes de arquivo - slide 35

# Linha válida do passwd: exatamente 7 campos separados por ":" (ver ex11).
LINHA_VALIDA='^([^:]*:){6}[^:]*$'

# uso: mostra como chamar o script e encerra com status 2 (uso incorreto).
uso() {
    if [ $# -gt 0 ]; then
        echo "Erro: $*" >&2
    fi
    echo "Uso: $0 [arquivo_passwd]" >&2
    exit 2
}

# erro: mostra a mensagem no stderr e encerra com status 1.
erro() {
    echo "Erro: $*" >&2
    exit 1
}

# ---------------------------------------------------------------------------
# Validações (as mesmas do ex11)
# ---------------------------------------------------------------------------

[ $# -le 1 ] || uso "informe no máximo um arquivo (recebidos: $#)"
if [ $# -eq 1 ] && [ -z "$1" ]; then
    uso "o nome do arquivo não pode ser vazio"
fi

arquivo="${1:-/etc/passwd}"

[ -e "$arquivo" ] || erro "'$arquivo' não existe"
[ -f "$arquivo" ] || erro "'$arquivo' não é um arquivo comum"
[ -r "$arquivo" ] || erro "sem permissão de leitura em '$arquivo'"
[ -s "$arquivo" ] || erro "'$arquivo' está vazio"

mal_formadas=$(grep -cvE "$LINHA_VALIDA" "$arquivo")
if [ "$mal_formadas" -gt 0 ]; then
    echo "Aviso: $mal_formadas linha(s) de '$arquivo' não têm 7 campos e foram ignoradas" >&2
fi

grep -qE "$LINHA_VALIDA" "$arquivo" ||
    erro "'$arquivo' não tem nenhuma linha no formato do /etc/passwd"

# ---------------------------------------------------------------------------
# Listagem
# ---------------------------------------------------------------------------

# Pipe (slide 16):
#   grep -E   só as linhas válidas
#   cut -f7   o 7º campo, o shell
#   sed       campo vazio vira /bin/sh: pelo manual do passwd (man 5
#             passwd), shell vazio significa /bin/sh. Sem isso, apareceria
#             uma linha em branco na saída.
#   sort      ordena, deixando as linhas iguais JUNTAS
#   uniq      remove as repetições
#
# A ordem sort -> uniq é a pegadinha da dica do enunciado: o uniq só remove
# linhas repetidas VIZINHAS. No testes/passwd_exemplo os shells repetidos
# estão espalhados, e "cut -d: -f7 | uniq" sem o sort não remove nada.
grep -E "$LINHA_VALIDA" "$arquivo" | cut -d: -f7 | sed 's|^$|/bin/sh|' | sort | uniq
