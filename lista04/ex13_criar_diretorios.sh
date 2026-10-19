#!/bin/bash
#
# Lista 4 - Exercício 13
#
# Enunciado: "Crie um script que utilize um loop para criar 5 diretórios com
# o nome padrão dir<n>, onde n é o número a ser adicionado ao nome do
# diretório. Dentro de cada diretório crie 3 arquivos com o nome padrão
# file<m>, onde m é o número a ser adicionado ao nome do arquivo."
#
# Uso:     ./ex13_criar_diretorios.sh [diretório_base]
#          sem argumento, cria no diretório atual.
#
# Status de saída:
#   0  os 5 diretórios e 15 arquivos existem ao final
#   1  base inválida, sem permissão, ou algum mkdir/touch falhou
#   2  uso incorreto (argumentos demais ou nome vazio)
#
# Teoria (Aula 10): for - slides 36 e 42 | $(comando) como lista do for -
#                   slide 42 | touch - slide 8 | listas E/OU - slides 48-51

# Quantidades pedidas no enunciado.
QTD_DIRETORIOS=5
QTD_ARQUIVOS=3

# uso: mostra como chamar o script e encerra com status 2 (uso incorreto).
uso() {
    if [ $# -gt 0 ]; then
        echo "Erro: $*" >&2
    fi
    echo "Uso: $0 [diretório_base]" >&2
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

[ $# -le 1 ] || uso "informe no máximo um diretório base (recebidos: $#)"
if [ $# -eq 1 ] && [ -z "$1" ]; then
    uso "o nome do diretório base não pode ser vazio"
fi

# Sem argumento, a base é o diretório atual (".").
base="${1:-.}"

# A base pode ainda não existir (o mkdir -p cria), mas se existir precisa
# ser um diretório em que dá para criar coisas (w + x).
if [ -e "$base" ]; then
    [ -d "$base" ] || erro "'$base' existe e não é um diretório"
    if [ ! -w "$base" ] || [ ! -x "$base" ]; then
        erro "sem permissão para criar diretórios em '$base'"
    fi
fi

# ---------------------------------------------------------------------------
# Criação: dois for aninhados (slide 36)
# ---------------------------------------------------------------------------

# A lista de valores do for vem de $(seq 1 5), o mesmo "values = $(command)"
# do slide 42: o seq imprime 1, 2, 3, 4, 5, um por linha.
for n in $(seq 1 "$QTD_DIRETORIOS"); do

    # mkdir -p:
    #  - não dá erro se o diretório já existe, então rodar o script de novo
    #    não falha (é idempotente);
    #  - cria também os diretórios intermediários, inclusive a base.
    # Se dir<n> já existir como ARQUIVO, o mkdir falha e o script para.
    mkdir -p "$base/dir$n" || erro "não foi possível criar '$base/dir$n'"

    for m in $(seq 1 "$QTD_ARQUIVOS"); do
        arquivo="$base/dir$n/file$m"

        # touch cria o arquivo vazio se ele não existe (slide 8: "verifica
        # se existe arquivo, senão cria"); se existe, só atualiza a data.
        touch "$arquivo" || erro "não foi possível criar '$arquivo'"

        # O touch também "dá certo" se file<m> já existir como DIRETÓRIO,
        # então confere que o resultado é mesmo um arquivo comum.
        [ -f "$arquivo" ] || erro "'$arquivo' existe mas não é um arquivo"
    done
done

echo "Criados $QTD_DIRETORIOS diretórios com $QTD_ARQUIVOS arquivos cada em '$base'."
