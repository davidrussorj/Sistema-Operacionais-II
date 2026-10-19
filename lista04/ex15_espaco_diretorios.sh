#!/bin/bash
#
# Lista 4 - Exercício 15
#
# Enunciado: "Crie um script que mostre o espaço utilizado pelos arquivos
# dentro de cada diretório da sua conta no sistema, colocando em ordem
# numérica o resultado."
#
# Uso:     ./ex15_espaco_diretorios.sh [diretório_base]
#          sem argumento, usa o $HOME (pode demorar numa conta grande); o
#          argumento serve para testar com testes/conta_exemplo.
#
# Status de saída:
#   0  resultado mostrado (inclusive "nenhum subdiretório")
#   1  base inexistente, que não é diretório, ou sem permissão
#   2  uso incorreto (argumentos demais ou nome vazio)
#
# Teoria (Aula 10): pipe - slide 16 | $HOME - slide 28 | testes de
#                   arquivo - slide 35 | $(comando) - slide 60

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

[ $# -le 1 ] || uso "informe no máximo um diretório (recebidos: $#)"
if [ $# -eq 1 ] && [ -z "$1" ]; then
    uso "o nome do diretório não pode ser vazio"
fi

# "Sua conta" = diretório pessoal ($HOME, slide 28), se nada for informado.
base="${1:-${HOME:-}}"
[ -n "$base" ] || erro "nenhum diretório informado e a variável HOME não está definida"

[ -e "$base" ] || erro "'$base' não existe"
[ -d "$base" ] || erro "'$base' não é um diretório"
if [ ! -r "$base" ] || [ ! -x "$base" ]; then
    erro "sem permissão para ler '$base'"
fi

# ---------------------------------------------------------------------------
# Medição e ordenação
# ---------------------------------------------------------------------------

# find "$base" -mindepth 1 -maxdepth 1 -type d
#     lista os subdiretórios imediatos da base (nem a própria base, nem os
#     níveis mais fundos), INCLUSIVE os ocultos. O atalho "du -sk ~/*" não
#     serviria: o * não casa com nomes que começam com ponto, e os ocultos
#     (.cache, .local, .config...) costumam ser os maiores de uma conta.
#     -type d sem -L também ignora links simbólicos para diretórios, para
#     não contar duas vezes (ou contar algo de fora da conta).
# -exec du -sk {} +
#     entrega os diretórios encontrados ao du: -s soma tudo de cada um num
#     total só, -k mostra em KB. Unidade fixa é o que permite o sort -n: com
#     du -h ("512K", "20M", "1.2G") o sort -n olharia só o número e poria
#     1.2G antes de 20M.
# sort -n
#     ordem numérica (do menor para o maior), pela 1ª coluna, o tamanho.
#
# O resultado vai para uma variável para dar para tratar o caso "vazio".
resultado=$(find "$base" -mindepth 1 -maxdepth 1 -type d -exec du -sk {} + | sort -n)

if [ -z "$resultado" ]; then
    echo "(nenhum subdiretório em '$base')"
    exit 0
fi

# ---------------------------------------------------------------------------
# Resultado
# ---------------------------------------------------------------------------

# Cabeçalho separado por TAB, como as linhas do du.
printf 'KB\tDiretório\n'
printf '%s\n' "$resultado"
