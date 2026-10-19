#!/bin/bash
#
# Lista 4 - Exercício 14
#
# Enunciado: "Escreva um script capaz de adicionar ideias em um repositório
# de ideias, situado em /ideias.txt. O programa deve ser executado com a
# ideia como parâmetro da linha de comando e deve fazer entradas que
# comecem com a data/hora do dia, como no exemplo abaixo:
#     30/08/2008 10:21 Fazer script para remover usuários"
#
# Uso:     ./ex14_repositorio_ideias.sh <ideia, pode ser sem aspas>
#          IDEIAS=/outro/arquivo.txt ./ex14_repositorio_ideias.sh <ideia>
#
# /ideias.txt fica na raiz do sistema, onde só o root cria arquivos. Para
# usá-lo como usuário comum, libere-o uma vez:
#     sudo touch /ideias.txt && sudo chown "$USER" /ideias.txt
# ou aponte a variável IDEIAS para outro arquivo.
#
# Status de saída:
#   0  ideia registrada
#   1  não foi possível escrever no arquivo (permissão, é diretório...)
#   2  uso incorreto (nenhuma ideia, ou só espaços)
#
# Teoria (Aula 10): >> (append) - slide 12 | $* - slide 30 |
#                   formatos do date - apoio, item 27

# uso: mostra como chamar o script e encerra com status 2 (uso incorreto).
uso() {
    if [ $# -gt 0 ]; then
        echo "Erro: $*" >&2
    fi
    echo "Uso: $0 <ideia>" >&2
    exit 2
}

# erro: mostra a mensagem no stderr e encerra com status 1.
erro() {
    echo "Erro: $*" >&2
    exit 1
}

# ---------------------------------------------------------------------------
# Validações da ideia
# ---------------------------------------------------------------------------

[ $# -ge 1 ] || uso "informe a ideia"

# $* junta todos os parâmetros numa string só, separados por espaço
# (slide 30). Assim dá para digitar a frase sem aspas; com $1, o exemplo
# do enunciado gravaria só "Fazer".
ideia="$*"

# Cada ideia ocupa UMA linha do repositório. Se o texto vier com quebras de
# linha (possível com aspas), elas viram espaços.
ideia="${ideia//$'\n'/ }"

# ${ideia//[[:space:]]/} é a ideia sem nenhum espaço/TAB; se isso for vazio,
# a ideia era só espaços (ex.: ./ex14 "   ").
[ -n "${ideia//[[:space:]]/}" ] || uso "a ideia não pode ser vazia"

# ---------------------------------------------------------------------------
# Validações do arquivo
# ---------------------------------------------------------------------------

# ${IDEIAS:-/ideias.txt}: usa a variável IDEIAS se ela existir e não for
# vazia; senão, o caminho pedido no enunciado.
arquivo="${IDEIAS:-/ideias.txt}"

# Um diretório com esse nome faria o >> falhar com uma mensagem confusa.
[ ! -d "$arquivo" ] || erro "'$arquivo' é um diretório, não um arquivo"

# ---------------------------------------------------------------------------
# Registro
# ---------------------------------------------------------------------------

# date '+%d/%m/%Y %H:%M' reproduz exatamente o formato do exemplo
# ("30/08/2008 10:21"). >> ACRESCENTA ao final do arquivo (slide 12): com >
# cada ideia nova apagaria todas as anteriores (o "CUIDADO!!!" do slide 10).
#
# Se o >> falhar (sem permissão, diretório inexistente...), o próprio bash
# imprime o motivo no stderr - como o perror() - e o if mostra como
# resolver. O >> só precisa de permissão de escrita NO ARQUIVO; por isso,
# depois do chown, o script funciona sem sudo, mesmo com o arquivo em "/".
if ! echo "$(date '+%d/%m/%Y %H:%M') $ideia" >> "$arquivo"; then
    echo "Erro: não foi possível escrever em '$arquivo'." >&2
    echo "Para liberar: sudo touch '$arquivo' && sudo chown \"\$USER\" '$arquivo'" >&2
    exit 1
fi

# Mostra a linha que acabou de ser gravada (a última do arquivo).
echo "Ideia registrada em $arquivo:"
tail -n 1 "$arquivo"
