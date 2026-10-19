#!/bin/bash
#
# Lista 4 - Exercício 4
#
# Enunciado: "Faça um script que informa se o arquivo passado pela linha de
# comando, caso exista, é maior que 100 bytes. O comando stat pode ajudar na
# determinação do tamanho."
#
# Uso:     ./ex4_maior_que_100.sh <arquivo>
#
# Status de saída:
#   0  o tamanho foi verificado (seja maior ou não que 100 bytes)
#   1  o arquivo não existe, é um diretório ou o stat falhou
#   2  uso incorreto (quantidade errada de argumentos ou nome vazio)
#
# Teoria (Aula 10): comparação aritmética -gt - slide 34 | testes de
#                   arquivo -e, -d, -L - slide 35 | $(comando) - slide 60

# Limite pedido no enunciado, num lugar só para não virar "número mágico".
LIMITE=100

# uso: mostra como chamar o script e encerra com status 2 (uso incorreto).
uso() {
    if [ $# -gt 0 ]; then
        echo "Erro: $*" >&2
    fi
    echo "Uso: $0 <arquivo>" >&2
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

[ $# -eq 1 ] || uso "informe exatamente um arquivo (recebidos: $#)"
[ -n "$1" ] || uso "o nome do arquivo não pode ser vazio"

# "Caso exista": o enunciado só pede o tamanho de arquivos existentes. A
# checagem vem antes do stat para não deixar o stat imprimir o erro dele.
# Um link quebrado tem mensagem própria, porque o link em si existe.
if [ ! -e "$1" ]; then
    if [ -L "$1" ]; then
        erro "'$1' é um link simbólico quebrado"
    fi
    erro "o arquivo '$1' não existe"
fi

# Diretórios também têm "tamanho" no stat (normalmente 4096 bytes, o espaço
# da lista de nomes), mas esse número não é o tamanho do conteúdo e só
# confundiria a resposta. Por isso só arquivos são aceitos.
[ ! -d "$1" ] || erro "'$1' é um diretório; informe um arquivo"

# ---------------------------------------------------------------------------
# Tamanho em bytes
# ---------------------------------------------------------------------------

# stat -c %s imprime só o tamanho em bytes.
# -L faz o stat seguir links simbólicos: sem ele, o stat de um link mostra o
#    tamanho DO LINK (quantos caracteres tem o caminho para onde ele aponta),
#    não do arquivo. O -e usado acima já segue links, então os dois ficam
#    coerentes.
# -- marca o fim das opções, para um nome que comece com "-" não ser lido
#    como opção do stat.
tamanho=$(stat -L -c %s -- "$1") || erro "não foi possível obter o tamanho de '$1'"

# Confere que o stat devolveu mesmo um número antes de compará-lo: um texto
# vazio ou com letras faria o [ ... -gt ... ] dar erro de sintaxe.
case "$tamanho" in
    '' | *[!0-9]*) erro "o stat devolveu um tamanho inválido: '$tamanho'" ;;
esac

# ---------------------------------------------------------------------------
# Comparação
# ---------------------------------------------------------------------------

# -gt é a comparação aritmética "maior que" (slide 34). NUNCA usar > aqui:
# dentro de [ ], o > é redirecionamento - [ $tamanho > 100 ] criaria um
# arquivo vazio chamado "100" e o teste seria sempre verdadeiro.
# "Maior que 100" é estrito: um arquivo de exatamente 100 bytes não passa.
if [ "$tamanho" -gt "$LIMITE" ]; then
    echo "'$1' tem $tamanho bytes: é maior que $LIMITE bytes."
else
    echo "'$1' tem $tamanho bytes: não é maior que $LIMITE bytes."
fi
