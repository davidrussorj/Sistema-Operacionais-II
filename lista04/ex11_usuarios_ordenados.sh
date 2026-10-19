#!/bin/bash
#
# Lista 4 - Exercício 11
#
# Enunciado: "Crie um script para mostrar todos os usuários cadastrados no
# sistema, em ordem alfabética. O comando cat e o arquivo /etc/passwd podem
# lhe ajudar."
#
# Uso:     ./ex11_usuarios_ordenados.sh [arquivo_passwd]
#          sem argumento, usa /etc/passwd; o argumento serve para testar com
#          um arquivo fixo (testes/passwd_exemplo) e ter saída previsível.
#
# Status de saída:
#   0  usuários listados
#   1  arquivo inexistente, vazio, sem leitura ou sem nenhuma linha válida
#   2  uso incorreto (argumentos demais ou nome vazio)
#
# Teoria (Aula 10): pipe - slide 16 | ${var:-padrão} | testes de arquivo -
#                   slide 35

# Formato de uma linha válida do passwd: 7 campos separados por ":"
#   nome:senha:UID:GID:descrição:diretório_pessoal:shell
# A expressão regular aceita "6 vezes (qualquer coisa sem ':' seguida de
# ':')" e depois um último campo sem ':' - ou seja, exatamente 7 campos.
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
# Validações
# ---------------------------------------------------------------------------

[ $# -le 1 ] || uso "informe no máximo um arquivo (recebidos: $#)"

# ${1:-/etc/passwd} usaria o padrão também para um argumento vazio (""),
# escondendo o engano de quem chamou. Por isso o vazio é recusado antes.
if [ $# -eq 1 ] && [ -z "$1" ]; then
    uso "o nome do arquivo não pode ser vazio"
fi

# Sem argumento, o arquivo é o /etc/passwd do sistema.
arquivo="${1:-/etc/passwd}"

[ -e "$arquivo" ] || erro "'$arquivo' não existe"
[ -f "$arquivo" ] || erro "'$arquivo' não é um arquivo comum"
[ -r "$arquivo" ] || erro "sem permissão de leitura em '$arquivo'"
[ -s "$arquivo" ] || erro "'$arquivo' está vazio"

# Linhas fora do formato (sem os 7 campos) não são de usuário. Em vez de
# imprimir lixo, elas são contadas, ignoradas e avisadas no stderr.
# grep -c conta as linhas; -v inverte (conta as que NÃO casam).
mal_formadas=$(grep -cvE "$LINHA_VALIDA" "$arquivo")
if [ "$mal_formadas" -gt 0 ]; then
    echo "Aviso: $mal_formadas linha(s) de '$arquivo' não têm 7 campos e foram ignoradas" >&2
fi

# Se nenhuma linha é válida, o arquivo provavelmente não é um passwd.
grep -qE "$LINHA_VALIDA" "$arquivo" ||
    erro "'$arquivo' não tem nenhuma linha no formato do /etc/passwd"

# ---------------------------------------------------------------------------
# Listagem
# ---------------------------------------------------------------------------

# Pipe de três etapas (slide 16):
#   grep -E   deixa passar só as linhas válidas
#   cut       -d: usa ":" como separador e -f1 pega o 1º campo, o nome
#   sort      ordena em ordem alfabética
# O enunciado sugere "cat /etc/passwd | ...", que dá o mesmo resultado; aqui
# o arquivo vai direto para o primeiro comando, que já sabe ler arquivos (o
# cat só acrescentaria um processo a mais ao pipe).
grep -E "$LINHA_VALIDA" "$arquivo" | cut -d: -f1 | sort
