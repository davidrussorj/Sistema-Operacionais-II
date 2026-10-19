#!/bin/bash
#
# Lista 4 - Exercício 5
#
# Enunciado: "Faça um script que imprime quantos processos estão atualmente
# em execução na sua máquina. Não se esqueça de que o seu script também
# entrará na contagem."
#
# Uso:     ./ex5_contar_processos.sh     (não recebe argumentos)
#
# Status de saída:
#   0  sucesso
#   1  /proc indisponível (sistema que não é Linux, ou /proc não montado)
#   2  uso incorreto (foram passados argumentos)
#
# Teoria (Aula 10): wildcard [set] - slide 17 | $(( )) - slide 61 |
#                   vetores e ${#vetor[@]} - apoio, itens 39 a 45

# uso: mostra como chamar o script e encerra com status 2 (uso incorreto).
uso() {
    if [ $# -gt 0 ]; then
        echo "Erro: $*" >&2
    fi
    echo "Uso: $0   (este script não recebe argumentos)" >&2
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

[ $# -eq 0 ] || uso "argumentos inesperados: $*"

# No Linux, cada processo em execução tem um diretório /proc/<PID> (o mesmo
# /proc usado no ex2_przombies da Lista 3; é de lá que o próprio ps lê).
# Em outros sistemas (macOS, por exemplo) o /proc não existe.
[ -d /proc ] || erro "/proc não existe (este script depende do /proc do Linux)"

# ---------------------------------------------------------------------------
# Contagem
# ---------------------------------------------------------------------------

# /proc/[0-9]* casa só as entradas cujo nome começa com dígito, que são os
# diretórios de processo (as outras, como /proc/cpuinfo, não são processos).
#
# Quem expande o padrão é o próprio bash, e o resultado vai para um vetor.
# Isso é o ponto principal: NENHUM processo novo é criado para contar, então
# o único processo "do script" que entra na contagem é o próprio bash que
# está rodando este arquivo - exatamente o aviso do enunciado.
# (Com "ps -e | wc -l" entrariam também o ps, o wc, o subshell do $(...) e
# a linha de cabeçalho do ps.)
#
# nullglob: se nada casar com o padrão, o vetor fica vazio. Sem essa opção,
# o bash deixaria o próprio texto "/proc/[0-9]*" como único elemento, e a
# contagem daria 1 em vez de detectar o problema.
shopt -s nullglob
processos=(/proc/[0-9]*)
shopt -u nullglob

# ${#vetor[@]} é a quantidade de elementos do vetor (apoio, item 45).
total=${#processos[@]}

# Este script está rodando, então pelo menos ele precisa aparecer em /proc.
[ "$total" -ge 1 ] || erro "nenhum processo encontrado em /proc (o /proc está montado?)"

# ---------------------------------------------------------------------------
# Resultado
# ---------------------------------------------------------------------------

# $(( )) faz a conta no próprio shell (slide 61): total - 1 é o número de
# processos sem contar este script.
echo "Processos em execução, contando este script: $total"
echo "Processos em execução, sem contar este script: $((total - 1))"
