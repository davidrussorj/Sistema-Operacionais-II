#!/bin/bash
#
# Lista 4 - Exercício 7
#
# Enunciado: "Escreva um script que mostra o usuário e o nome completo de
# cada usuário do sistema (campos 1 e 5), separados por TAB. Obter as
# informações no arquivo /etc/passwd. Uma possível saída:
#     prompt$ ./users.sh
#     ftp     FTP User
#     nobody  Nobody
#     named   Domain name server
#     ..."
#
# Uso:     ./ex7_usuarios.sh [arquivo_passwd]
#          sem argumento, usa /etc/passwd; o argumento serve para testar com
#          um arquivo fixo (testes/passwd_exemplo) e ter saída previsível.
#
# Status de saída:
#   0  usuários listados
#   1  arquivo inexistente, vazio, sem leitura ou sem nenhuma linha válida
#   2  uso incorreto (argumentos demais ou nome vazio)
#
# Teoria (Aula 10): pipe - slide 16 | testes de arquivo - slide 35 |
#                   lista OU (||) - slides 50-51

# Os scripts da lista são escritos para o bash (#!/bin/bash), mas o slide 23
# ensina também a "forma fácil", sh script.sh - e aí quem executa é o
# /bin/sh, que no Ubuntu é o dash, não o bash (slide 6: "verificar com
# ls -l /bin/sh"). O dash não tem alguns recursos do bash ([[ =~ ]], 10#...)
# e o echo dele interpreta \ de outro jeito. A variável BASH_VERSION só
# existe dentro do bash: se ela estiver vazia, o exec (slide 59) troca este
# processo por um bash rodando o mesmo script, com os mesmos argumentos e a
# mesma entrada.
[ -n "$BASH_VERSION" ] || exec bash "$0" "$@"

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

# Cada problema com sua mensagem (slide 35: -e existe, -f arquivo comum,
# -r pode ser lido, -s não está vazio). "teste || erro" é a lista OU dos
# slides 50-51: o erro só é chamado se o teste falhar.
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

# Pipe de quatro etapas (slide 16):
#   grep -E      deixa passar só as linhas válidas;
#   cut -d: -f1,5
#                -d: usa ":" como separador e -f1,5 pega os campos 1 e 5.
#                O cut mantém o ":" entre os dois: "ana:Ana Souza,Sala 12,,";
#   sed          apaga do primeiro "," até o fim da linha. O campo 5 (GECOS)
#                pode ter várias informações separadas por vírgula - no
#                Debian/Ubuntu, o adduser grava "Nome,Sala,Telefone do
#                trabalho,Telefone de casa" -, e o NOME COMPLETO é só a
#                primeira. Nome de usuário não tem vírgula, então só o campo
#                5 é afetado;
#   tr ':' '\t'  troca o ":" que sobrou por um TAB, o separador pedido. É o
#                mesmo tr da dica do exercício 6, agora traduzindo um
#                caractere em outro em vez de apagar.
# Um usuário com o campo 5 vazio sai como "nome<TAB>", com o nome completo
# em branco: o campo existe, só não foi preenchido.
grep -E "$LINHA_VALIDA" "$arquivo" | cut -d: -f1,5 | sed 's/,.*$//' | tr ':' '\t'
