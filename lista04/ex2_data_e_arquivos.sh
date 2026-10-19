#!/bin/bash
#
# Lista 4 - Exercício 2
#
# Enunciado: "Escreva um script que mostre a data de hoje e liste todos os
# arquivos da sua conta."
#
# Uso:     ./ex2_data_e_arquivos.sh      (não recebe argumentos)
#
# Status de saída:
#   0  sucesso
#   1  $HOME indefinido, inexistente ou sem permissão de leitura
#   2  uso incorreto (foram passados argumentos)
#
# Teoria (Aula 10): variável de ambiente $HOME - slide 28 |
#                   $(comando) - slide 60 | formatos do date - apoio, item 27

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

# "Arquivos da sua conta" = arquivos do diretório pessoal, que o sistema
# informa na variável de ambiente HOME. Ela pode não existir em ambientes
# como cron ou containers, então é verificada antes de ser usada.
# ${HOME:-} evita erro caso a variável nem esteja definida.
[ -n "${HOME:-}" ] || erro "a variável HOME não está definida"

# O caminho em HOME precisa existir e ser um diretório...
[ -d "$HOME" ] || erro "o diretório pessoal '$HOME' não existe"

# ...e, para listar um diretório, é preciso permissão de leitura (r, ver os
# nomes) e de execução (x, acessar as informações de cada arquivo).
if [ ! -r "$HOME" ] || [ ! -x "$HOME" ]; then
    erro "sem permissão para listar '$HOME'"
fi

# ---------------------------------------------------------------------------
# Data de hoje
# ---------------------------------------------------------------------------

# date com formato explícito (%d dia, %m mês, %Y ano com 4 dígitos) para
# sair no padrão brasileiro em vez do padrão em inglês ("Mon Oct 19 ...").
echo "Hoje é $(date '+%d/%m/%Y')"
echo

# ---------------------------------------------------------------------------
# Arquivos da conta
# ---------------------------------------------------------------------------

# -l: formato longo (permissões, dono, tamanho, data de modificação).
# -a: inclui os arquivos ocultos (os que começam com ponto, como .bashrc e
#     .profile), que o ls esconde por padrão mas também são da conta.
# A listagem não é recursiva (-R) de propósito: numa conta real, listar
# todos os subdiretórios geraria milhares de linhas.
echo "Arquivos da conta ($HOME):"
ls -la "$HOME" || erro "não foi possível listar '$HOME'"
