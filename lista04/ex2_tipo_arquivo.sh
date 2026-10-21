#!/bin/bash
#
# Lista 4 - Exercício 2
#
# Enunciado: "Elaborar um script que pede ao usuário para digitar um nome de
# arquivo e testa se o arquivo existe. Se sim, diz se é um arquivo ou um
# diretório."
#
# Uso:     ./ex2_tipo_arquivo.sh                       (o nome é digitado)
#          echo testes/subdir_teste | ./ex2_tipo_arquivo.sh   (sem digitar)
#
# Status de saída (permite usar o script dentro de um if em outro script):
#   0  o arquivo existe (seja arquivo, diretório ou outro tipo)
#   1  não existe, é um link simbólico quebrado, está num diretório sem
#      permissão de acesso (não dá para saber), o nome digitado é vazio ou
#      a entrada terminou antes do nome
#   2  uso incorreto (foram passados argumentos)
#
# Teoria (Aula 10): read - slide 25 | testes de arquivo -e, -f, -d - slide 35 |
#                   aspas no teste - slide 40 | if/elif - slides 36 e 39

# Os scripts da lista são escritos para o bash (#!/bin/bash), mas o slide 23
# ensina também a "forma fácil", sh script.sh - e aí quem executa é o
# /bin/sh, que no Ubuntu é o dash, não o bash (slide 6: "verificar com
# ls -l /bin/sh"). O dash não tem alguns recursos do bash ([[ =~ ]], 10#...)
# e o echo dele interpreta \ de outro jeito. A variável BASH_VERSION só
# existe dentro do bash: se ela estiver vazia, o exec (slide 59) troca este
# processo por um bash rodando o mesmo script, com os mesmos argumentos e a
# mesma entrada.
[ -n "$BASH_VERSION" ] || exec bash "$0" "$@"

# uso: mostra como chamar o script e encerra com status 2 (uso incorreto).
uso() {
    if [ $# -gt 0 ]; then
        echo "Erro: $*" >&2
    fi
    echo "Uso: $0   (o nome do arquivo é pedido pelo teclado)" >&2
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

# O enunciado pede que o nome seja DIGITADO (read), não passado na linha de
# comando. Um argumento indica que quem chamou esperava outro uso.
[ $# -eq 0 ] || uso "o nome do arquivo não é um argumento: rode sem nada e digite o nome"

# ---------------------------------------------------------------------------
# Leitura do nome (slide 25)
# ---------------------------------------------------------------------------

# -p  mostra a pergunta (só quando a entrada é o teclado);
# -r  não interpreta a \ (sem ele, "a\b" viraria "ab");
# IFS= (vazio só para este read) faz o nome ser guardado exatamente como foi
#     digitado. Sem isso, o read apagaria espaços no começo e no fim, e um
#     arquivo chamado " nota.txt" nunca seria encontrado.
# O read falha quando a entrada acaba sem nenhuma linha (Ctrl+D, pipe
# vazio). Se a linha veio sem \n no final, ele "falha" mas o nome foi lido,
# por isso o teste também olha se o nome ficou vazio.
if ! IFS= read -r -p "Nome do arquivo: " nome && [ -z "$nome" ]; then
    erro "a entrada terminou antes do nome do arquivo"
fi

# Só Enter: não há o que testar. Sem esta checagem, [ -e "" ] diria "não
# existe", o que é verdade mas esconde que nada foi digitado.
[ -n "$nome" ] || erro "o nome do arquivo não pode ser vazio"

# Quem digita ~/algo espera o diretório pessoal, mas o til só é expandido
# quando escrito na linha de comando: o read entrega o "~" literal. Aqui ele
# é trocado por $HOME (slide 28). Só "~" e "~/..." são tratados; "~ana" (o
# home de outro usuário) fica como foi digitado.
case "$nome" in
    "~" | "~/"*) nome="$HOME${nome#\~}" ;;
esac

# ---------------------------------------------------------------------------
# Existe?
# ---------------------------------------------------------------------------

# Todos os testes usam "$nome" entre aspas (slide 40): com um nome com
# espaço, [ -e nome com espaço.txt ] tem argumentos demais e o [ dá erro
# ("binary operator expected").

# -e segue links simbólicos: para um link que aponta para um arquivo que não
# existe mais, -e é falso, mesmo o link estando ali. -L testa o próprio link
# (sem seguir), e assim esse caso ganha uma mensagem própria.
if [ -L "$nome" ] && [ ! -e "$nome" ]; then
    echo "'$nome' é um link simbólico quebrado: aponta para '$(readlink -- "$nome")', que não existe."
    exit 1
fi

# -e: existe, de qualquer tipo (slide 35).
if [ ! -e "$nome" ]; then
    # -e também é falso quando o arquivo existe, mas está dentro de um
    # diretório em que não temos permissão de entrar (permissão x): o
    # sistema não deixa nem consultar se ele está lá. Exemplo, para um
    # usuário comum: /root/.bashrc. Nesse caso não dá para dizer "não
    # existe". Para descobrir, o laço sobe pelo caminho com dirname até
    # achar o diretório mais fundo que dá para ver, e testa o -x dele. O
    # laço para também em "/" e "." (que o dirname devolve no fim do
    # caminho), para não repetir para sempre.
    dir="$nome"
    while :; do
        dir=$(dirname -- "$dir")
        if [ -d "$dir" ] || [ "$dir" = / ] || [ "$dir" = . ]; then
            break
        fi
    done
    if [ -d "$dir" ] && [ ! -x "$dir" ]; then
        erro "sem permissão para entrar em '$dir': não dá para saber se '$nome' existe"
    fi

    echo "'$nome' não existe."

    # Dicas para dois enganos comuns ao digitar, que fazem um arquivo que
    # existe parecer que não existe:
    #   - o read guarda o texto literal: $HOME digitado continua sendo o
    #     texto "$HOME" (só a linha de comando expande variáveis);
    #   - o IFS= mantém um espaço digitado sem querer no fim do nome.
    #     ${nome%"${nome##*[! ]}"} é o nome sem os espaços do fim: o
    #     ${nome##*[! ]} pega os espaços finais, e o % os corta.
    case "$nome" in
        *'$'*)
            echo "(o read não expande variáveis como \$HOME: digite o caminho completo, ou ~ no começo)"
            ;;
        *' ')
            if [ -e "${nome%"${nome##*[! ]}"}" ]; then
                echo "(atenção: o nome digitado termina com espaço; sem esse espaço, o arquivo existe)"
            fi
            ;;
    esac
    exit 1
fi

# ---------------------------------------------------------------------------
# Arquivo ou diretório?
# ---------------------------------------------------------------------------

# -d diretório, -f arquivo comum (slide 35). Existe ainda o que não é nenhum
# dos dois - dispositivos (/dev/null), pipes nomeados e sockets -, e dizer
# "é um arquivo" para eles seria errado, então cada um tem sua descrição.
if [ -d "$nome" ]; then
    tipo="um diretório"
elif [ -f "$nome" ]; then
    tipo="um arquivo comum"
elif [ -b "$nome" ] || [ -c "$nome" ]; then
    tipo="um arquivo especial de dispositivo"
elif [ -p "$nome" ]; then
    tipo="um pipe nomeado (FIFO)"
elif [ -S "$nome" ]; then
    tipo="um socket"
else
    tipo="um arquivo de tipo desconhecido"
fi

# Os testes acima seguem o link, então descrevem o arquivo apontado. Para um
# link, a resposta diz as duas coisas.
if [ -L "$nome" ]; then
    echo "'$nome' existe e é um link simbólico para $tipo."
else
    echo "'$nome' existe e é $tipo."
fi
exit 0
