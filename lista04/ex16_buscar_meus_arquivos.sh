#!/bin/bash
#
# Lista 4 - Exercício 16
#
# Enunciado: "Utilizando o comando find, busque os arquivos que pertencem ao
# seu usuário, a partir do '/', redirecionando a saída para o arquivo
# 'arq.txt' e os erros para 'erros.txt'."
#
# Uso:     ./ex16_buscar_meus_arquivos.sh [diretório_inicial]
#          sem argumento, busca a partir de / (pode demorar bastante; no
#          WSL inclui o disco do Windows em /mnt/c). arq.txt e erros.txt são
#          criados no diretório ATUAL.
#
# Status de saída:
#   0  busca feita (mesmo que o find tenha encontrado erros de permissão,
#      que são esperados e vão para erros.txt)
#   1  diretório inicial inválido, ou sem permissão para criar os arquivos
#   2  uso incorreto (argumentos demais ou nome vazio)
#
# Teoria (Aula 10): redirecionamento > e 2> - slides 10, 13 e 14 |
#                   descritores 0, 1 e 2 - slide 9 | $(comando) - slide 60

# Nomes pedidos no enunciado.
SAIDA="arq.txt"
ERROS="erros.txt"

# uso: mostra como chamar o script e encerra com status 2 (uso incorreto).
uso() {
    if [ $# -gt 0 ]; then
        echo "Erro: $*" >&2
    fi
    echo "Uso: $0 [diretório_inicial]" >&2
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

[ $# -le 1 ] || uso "informe no máximo um diretório inicial (recebidos: $#)"
if [ $# -eq 1 ] && [ -z "$1" ]; then
    uso "o nome do diretório inicial não pode ser vazio"
fi

# Sem argumento, a busca começa na raiz, como pede o enunciado.
inicio="${1:-/}"
[ -e "$inicio" ] || erro "'$inicio' não existe"
[ -d "$inicio" ] || erro "'$inicio' não é um diretório"

# Os dois arquivos de resultado são criados no diretório atual: é preciso
# poder escrever nele...
[ -w . ] || erro "sem permissão de escrita no diretório atual ($PWD) para criar $SAIDA e $ERROS"

# ...e, se eles já existirem de uma execução anterior, poder sobrescrevê-los.
for f in "$SAIDA" "$ERROS"; do
    if [ -e "$f" ] && [ ! -w "$f" ]; then
        erro "'$PWD/$f' já existe e não pode ser sobrescrito"
    fi
done

# O usuário vem de "id -un" (nome do usuário que está executando) e não da
# variável $USER, que pode não estar definida em alguns contextos (cron, su).
usuario=$(id -un) || erro "não foi possível descobrir o nome do usuário"

# ---------------------------------------------------------------------------
# Busca
# ---------------------------------------------------------------------------

# É o exemplo do slide 14 ("cat rel.txt >novorel.txt 2> erros.log")
# aplicado ao find:
#   >  arq.txt     redireciona o descritor 1 (stdout): os caminhos achados
#   2> erros.txt   redireciona o descritor 2 (stderr): as mensagens de erro,
#                  como "Permission denied" de diretórios de outros usuários
# A tela fica limpa e cada coisa vai para o seu arquivo. O > SOBRESCREVE os
# arquivos de uma execução anterior (slide 10), em vez de acumular.
#
# O find termina com status 1 quando encontra diretórios sem permissão, o
# que aqui é esperado; por isso o status dele não é tratado como falha.
find "$inicio" -user "$usuario" > "$SAIDA" 2> "$ERROS"

# ---------------------------------------------------------------------------
# Resumo na tela
# ---------------------------------------------------------------------------

# wc -l < arquivo (slide 15) imprime só a quantidade de linhas.
echo "Arquivos de $usuario encontrados a partir de $inicio: $(wc -l < "$SAIDA") (lista em $SAIDA)"
echo "Mensagens de erro: $(wc -l < "$ERROS") (em $ERROS)"
