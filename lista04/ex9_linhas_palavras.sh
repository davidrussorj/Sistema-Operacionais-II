#!/bin/bash
#
# Lista 4 - Exercício 9
#
# Enunciado: "Escreva um script que informa o número de linhas e de palavras
# de um arquivo passado na linha de comando."
#
# Uso:     ./ex9_linhas_palavras.sh <arquivo>
#
# Status de saída:
#   0  contagem mostrada
#   1  arquivo inexistente, que não é arquivo comum, ou sem leitura
#   2  uso incorreto (quantidade errada de argumentos ou nome vazio)
#
# Teoria (Aula 10): redirecionamento < - slide 15 | testes -e, -f, -r, -s -
#                   slide 35 | $(comando) - slide 60 | $(( )) - slide 61

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

# Uma mensagem para cada problema possível, do mais básico ao mais
# específico: não existe -> não é arquivo comum -> não dá para ler.
[ -e "$1" ] || erro "'$1' não existe"
[ -f "$1" ] || erro "'$1' não é um arquivo comum (é um diretório ou dispositivo?)"
[ -r "$1" ] || erro "sem permissão de leitura em '$1'"

# ---------------------------------------------------------------------------
# Contagem
# ---------------------------------------------------------------------------

# O arquivo entra pelo stdin com < (slide 15). Assim o wc não sabe o nome do
# arquivo e imprime SÓ o número; "wc -l arquivo" imprimiria "5 arquivo" e
# seria preciso recortar o nome depois.
linhas=$(wc -l < "$1") || erro "não foi possível contar as linhas de '$1'"

# wc -w conta sequências de caracteres separadas por espaço, TAB ou quebra
# de linha; vários espaços seguidos não criam palavras vazias.
palavras=$(wc -w < "$1") || erro "não foi possível contar as palavras de '$1'"

# Pegadinha do wc -l: ele não conta linhas, conta caracteres \n. Se a
# última linha não terminar com \n, ela fica de fora (um arquivo "a\nb" tem
# 2 linhas, mas wc -l diz 1). Correção:
#   - tail -c 1 pega o último byte do arquivo;
#   - $(...) remove os \n do final do que captura, então o resultado só é
#     vazio quando esse último byte é \n;
#   - se não for vazio, a última linha não tinha \n e é somada.
# -s (tamanho maior que zero) evita somar 1 num arquivo vazio.
if [ -s "$1" ] && [ -n "$(tail -c 1 "$1")" ]; then
    linhas=$((linhas + 1))
fi

# ---------------------------------------------------------------------------
# Resultado
# ---------------------------------------------------------------------------

echo "Linhas: $linhas"
echo "Palavras: $palavras"
