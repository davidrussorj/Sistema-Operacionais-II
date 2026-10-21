#!/bin/bash
#
# Lista 4 - Exercício 8
#
# Enunciado: "Escreva um script que mostra os shells de cada usuário do
# sistema (último campo), não apresentando linhas repetidas. Obter as
# informações no arquivo /etc/passwd. Dica: utilize o comando uniq. Uma
# possível saída:
#     prompt$ ./shells.sh
#     /bin/bash
#     /bin/false
#     /bin/sync
#     /sbin/halt
#     /sbin/shutdown"
#
# Uso:     ./ex8_shells.sh [arquivo_passwd]
#          sem argumento, usa /etc/passwd; o argumento serve para testar com
#          um arquivo fixo (testes/passwd_exemplo) e ter saída previsível.
#
# Status de saída:
#   0  shells listados
#   1  arquivo inexistente, vazio, sem leitura ou sem nenhuma linha válida
#   2  uso incorreto (argumentos demais ou nome vazio)
#
# Teoria (Aula 10): pipe - slide 16 | testes de arquivo - slide 35

# Os scripts da lista são escritos para o bash (#!/bin/bash), mas o slide 23
# ensina também a "forma fácil", sh script.sh - e aí quem executa é o
# /bin/sh, que no Ubuntu é o dash, não o bash (slide 6: "verificar com
# ls -l /bin/sh"). O dash não tem alguns recursos do bash ([[ =~ ]], 10#...)
# e o echo dele interpreta \ de outro jeito. A variável BASH_VERSION só
# existe dentro do bash: se ela estiver vazia, o exec (slide 59) troca este
# processo por um bash rodando o mesmo script, com os mesmos argumentos e a
# mesma entrada.
[ -n "$BASH_VERSION" ] || exec bash "$0" "$@"

# Linha válida do passwd: exatamente 7 campos separados por ":" (ver ex7).
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
# Validações (as mesmas do ex7)
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
#   cut -f7   o 7º campo (o último), o shell
#   sed       dois ajustes no shell, separados por ";":
#             s/\r$//  apaga o \r do fim da linha, que aparece quando o
#                      arquivo foi salvo no Windows (linhas terminadas em
#                      \r\n). Sem isso, "/bin/bash\r" e "/bin/bash" seriam
#                      linhas diferentes para o uniq, e o mesmo shell
#                      apareceria duas vezes - na tela, idênticos;
#             s|^$|/bin/sh|  campo vazio vira /bin/sh: pelo manual do
#                      passwd (man 5 passwd), shell vazio significa
#                      /bin/sh. Sem isso, sairia uma linha em branco.
#   sort      ordena, deixando as linhas iguais JUNTAS
#   uniq      remove as repetições
#
# A ordem sort -> uniq é a pegadinha da dica do enunciado: o uniq só remove
# linhas repetidas VIZINHAS. No testes/passwd_exemplo os shells repetidos
# estão espalhados (o /bin/bash aparece na 1ª linha e de novo no fim), e
# "cut -d: -f7 | uniq" sem o sort mostra 7 linhas, com /bin/bash e
# /bin/false repetidos.
grep -E "$LINHA_VALIDA" "$arquivo" | cut -d: -f7 | sed 's/\r$//; s|^$|/bin/sh|' | sort | uniq
