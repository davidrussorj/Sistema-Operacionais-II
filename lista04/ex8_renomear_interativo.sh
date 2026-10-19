#!/bin/bash
#
# Lista 4 - Exercício 8
#
# Enunciado: "Repita o exercício anterior de forma interativa, perguntando o
# diretório desejado e as extensões."
#
# Uso:     ./ex8_renomear_interativo.sh  (pergunta diretório e extensões)
#          printf '/tmp/musicas\nmpeg3\nogg\n' | ./ex8_renomear_interativo.sh
#
# ATENÇÃO: o script renomeia de verdade. Para testar, use uma cópia de
# testes/musicas_modelo, nunca o próprio modelo.
#
# Status de saída:
#   0  terminou (inclusive quando as extensões são iguais e não há o que fazer)
#   1  entrada encerrada, diretório/extensão inválidos, ou algum mv falhou
#   2  uso incorreto (foram passados argumentos)
#
# Teoria (Aula 10): read - slide 25 | wildcard * - slide 17 | for - slide 42
#                   ${var#prefixo}, ${var%sufixo}, ${var/#a/b} - apoio,
#                   itens 7, 8 e 11

# uso: mostra como chamar o script e encerra com status 2 (uso incorreto).
uso() {
    if [ $# -gt 0 ]; then
        echo "Erro: $*" >&2
    fi
    echo "Uso: $0   (o diretório e as extensões são perguntados depois de iniciar)" >&2
    exit 2
}

# erro: mostra a mensagem no stderr e encerra com status 1.
erro() {
    echo "Erro: $*" >&2
    exit 1
}

# valida_extensao: confere uma extensão já sem o ponto inicial.
#   $1 = a extensão     $2 = qual delas é ("atual" ou "nova"), para a mensagem
valida_extensao() {
    # Extensão vazia: renomear "x.mp3" para "x." ou procurar "*." não faz
    # sentido.
    [ -n "$1" ] || erro "a extensão $2 não pode ser vazia"

    # Uma barra faria o "novo nome" apontar para outro diretório.
    case "$1" in
        */*) erro "a extensão $2 não pode conter '/': '$1'" ;;
    esac
}

[ $# -eq 0 ] || uso "argumentos inesperados: $*"

# ---------------------------------------------------------------------------
# Leitura (slide 25)
# ---------------------------------------------------------------------------

# Mesmo esquema do ex6: -r para não interpretar \, -p para a pergunta, e o
# read só é considerado falho se a entrada acabou E nada foi lido.
read -r -p "Diretório: " dir || [ -n "$dir" ] ||
    erro "a entrada terminou antes de o diretório ser informado"
read -r -p "Extensão atual (ex.: mpeg3): " ext_antiga || [ -n "$ext_antiga" ] ||
    erro "a entrada terminou antes de a extensão atual ser informada"
read -r -p "Nova extensão (ex.: mp3): " ext_nova || [ -n "$ext_nova" ] ||
    erro "a entrada terminou antes de a nova extensão ser informada"

# ---------------------------------------------------------------------------
# Tratamento do que foi digitado
# ---------------------------------------------------------------------------

# Til: digitado na linha de comando, ~ vira o diretório pessoal. Mas o read
# devolve o texto literal "~/musicas", que não existe. ${dir/#\~/$HOME}
# troca um ~ no INÍCIO do texto por $HOME (apoio, item 11).
dir="${dir/#\~/$HOME}"

# Ponto inicial: aceita tanto "mpeg3" quanto ".mpeg3". ${var#.} remove um
# ponto do começo, se houver (apoio, item 7).
ext_antiga="${ext_antiga#.}"
ext_nova="${ext_nova#.}"

# ---------------------------------------------------------------------------
# Validações
# ---------------------------------------------------------------------------

[ -n "$dir" ] || erro "nenhum diretório foi informado"
[ -e "$dir" ] || erro "'$dir' não existe"
[ -d "$dir" ] || erro "'$dir' não é um diretório"
if [ ! -w "$dir" ] || [ ! -x "$dir" ]; then
    erro "sem permissão para renomear arquivos em '$dir'"
fi

valida_extensao "$ext_antiga" "atual"
valida_extensao "$ext_nova" "nova"

# Extensões iguais: não é erro, só não há o que fazer.
if [ "$ext_antiga" = "$ext_nova" ]; then
    echo "As extensões são iguais, nada a fazer."
    exit 0
fi

# Sem barra final, só para as mensagens não saírem com "//".
dir="${dir%/}"

# ---------------------------------------------------------------------------
# Renomeação (mesma lógica do ex7, comentada em detalhe lá)
# ---------------------------------------------------------------------------

renomeados=0
pulados=0
falhas=0

# A extensão entra no padrão ENTRE ASPAS: *."$ext_antiga". Assim, se o
# usuário digitar "*" como extensão, ela é procurada literalmente (um arquivo
# terminado em ".*") em vez de virar o padrão "*.*", que renomearia todos os
# arquivos com ponto no nome.
for arquivo in "$dir"/*."$ext_antiga"; do
    [ -f "$arquivo" ] || continue

    # Remove ".<ext_antiga>" do final e acrescenta ".<ext_nova>". As aspas
    # internas fazem a extensão ser removida literalmente, sem wildcard.
    novo="${arquivo%."$ext_antiga"}.$ext_nova"

    if [ -e "$novo" ]; then
        echo "Pulando '$arquivo': '$novo' já existe" >&2
        pulados=$((pulados + 1))
        continue
    fi

    if mv -- "$arquivo" "$novo"; then
        echo "'$arquivo' -> '$novo'"
        renomeados=$((renomeados + 1))
    else
        falhas=$((falhas + 1))
    fi
done

echo "$renomeados arquivo(s) renomeado(s), $pulados pulado(s)."
[ "$falhas" -eq 0 ] || erro "$falhas arquivo(s) não puderam ser renomeados"
