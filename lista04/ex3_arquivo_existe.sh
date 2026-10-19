#!/bin/bash
#
# Lista 4 - Exercício 3
#
# Enunciado: "Escreva um script que testa se determinado arquivo existe ou
# não. O nome do arquivo será passado na linha de comando."
#
# Uso:     ./ex3_arquivo_existe.sh <arquivo>
#
# Status de saída (permite usar o script dentro de um if em outro script):
#   0  o arquivo existe
#   1  o arquivo não existe (ou é um link simbólico quebrado)
#   2  uso incorreto (quantidade errada de argumentos ou nome vazio)
#
# Teoria (Aula 10): teste de arquivos -e - slide 35 | aspas no teste -
#                   slide 40 | parâmetros $1 e $# - slide 30

# uso: mostra como chamar o script e encerra com status 2 (uso incorreto).
uso() {
    if [ $# -gt 0 ]; then
        echo "Erro: $*" >&2
    fi
    echo "Uso: $0 <arquivo>" >&2
    exit 2
}

# ---------------------------------------------------------------------------
# Validações
# ---------------------------------------------------------------------------

# Exatamente um argumento: o nome do arquivo ($# = número de parâmetros).
[ $# -eq 1 ] || uso "informe exatamente um arquivo (recebidos: $#)"

# Um nome vazio ("") não é um arquivo. Sem esta checagem, o teste abaixo
# ficaria [ -e "" ], que dá "não existe" - correto, mas esconde o fato de
# que quem chamou passou um argumento inválido.
[ -n "$1" ] || uso "o nome do arquivo não pode ser vazio"

# ---------------------------------------------------------------------------
# Teste de existência
# ---------------------------------------------------------------------------

# -e: verdadeiro se o arquivo existe, de qualquer tipo (arquivo comum,
#     diretório, dispositivo...). -f seria verdadeiro só para arquivo
#     comum, e um diretório também "existe".
# As aspas em "$1" são obrigatórias (slide 40):
#   - com um nome com espaço, [ -e meu arquivo.txt ] tem argumentos demais
#     e o [ reclama "binary operator expected";
#   - com uma variável vazia, [ -e ] (sem aspas) é VERDADEIRO, porque com
#     um único argumento o test só verifica se aquela palavra não é vazia.
if [ -e "$1" ]; then
    echo "O arquivo '$1' existe."
    exit 0
fi

# Se chegou aqui, -e deu falso. Mas -e segue links simbólicos: para um link
# que aponta para um arquivo inexistente, -e é falso mesmo o link estando no
# diretório. -L testa o link em si, sem segui-lo, e separa esse caso.
if [ -L "$1" ]; then
    echo "'$1' é um link simbólico quebrado: o link existe, mas o arquivo para onde ele aponta não."
    exit 1
fi

echo "O arquivo '$1' não existe."
exit 1
