#!/bin/bash
#
# Lista 4 - Exercício 7
#
# Enunciado: "Faça um script que renomeia todos os arquivos com extensão
# .mpeg3 para .mp3, em um diretório fornecido na linha de comando."
#
# Uso:     ./ex7_renomear_mpeg3.sh <diretório>
#
# ATENÇÃO: o script renomeia de verdade. Para testar, use uma cópia de
# testes/musicas_modelo, nunca o próprio modelo.
#
# Status de saída:
#   0  terminou (mesmo que nenhum arquivo precisasse ser renomeado)
#   1  diretório inválido/sem permissão, ou algum mv falhou
#   2  uso incorreto (quantidade errada de argumentos ou nome vazio)
#
# Teoria (Aula 10): wildcard * - slide 17 | for - slides 36 e 42 |
#                   ${var%sufixo} - apoio, item 8 | $(( )) - slide 61

# uso: mostra como chamar o script e encerra com status 2 (uso incorreto).
uso() {
    if [ $# -gt 0 ]; then
        echo "Erro: $*" >&2
    fi
    echo "Uso: $0 <diretório>" >&2
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

[ $# -eq 1 ] || uso "informe exatamente um diretório (recebidos: $#)"
[ -n "$1" ] || uso "o nome do diretório não pode ser vazio"

# Mensagens diferentes para "não existe" e "existe mas não é diretório",
# para quem chamou saber exatamente o que corrigir.
[ -e "$1" ] || erro "'$1' não existe"
[ -d "$1" ] || erro "'$1' não é um diretório"

# Renomear um arquivo altera o DIRETÓRIO (a lista de nomes), não o arquivo.
# Por isso é preciso permissão de escrita (w) no diretório, e de execução
# (x) para acessar o que está dentro dele.
if [ ! -w "$1" ] || [ ! -x "$1" ]; then
    erro "sem permissão para renomear arquivos em '$1'"
fi

# Remove uma barra final ("musicas/" -> "musicas") só para as mensagens não
# saírem com barra dupla ("musicas//faixa01.mpeg3"). Para "/" o resultado é
# vazio, e "/*.mpeg3" continua sendo o caminho certo.
dir="${1%/}"

# ---------------------------------------------------------------------------
# Renomeação
# ---------------------------------------------------------------------------

renomeados=0   # arquivos renomeados com sucesso
pulados=0      # arquivos não renomeados porque o .mp3 já existia
falhas=0       # mv que deram erro

# Quem gera a lista é a expansão de wildcard do shell (slide 17): cada nome
# encontrado vira UMA palavra, mesmo que tenha espaços ("minha musica.mpeg3").
# Por isso não se usa "for f in $(ls *.mpeg3)" (estilo do slide 42): a saída
# do $(ls) seria quebrada nos espaços e viraria "minha" e "musica.mpeg3".
# As aspas em "$dir" protegem diretórios com espaço no nome.
for arquivo in "$dir"/*.mpeg3; do

    # -f só é verdadeiro para arquivo comum. Isso cobre dois casos:
    #  - quando nada casa com o padrão, o bash deixa o próprio texto
    #    "dir/*.mpeg3" no laço, que não é um arquivo;
    #  - um DIRETÓRIO chamado "algo.mpeg3" não é música e fica como está.
    [ -f "$arquivo" ] || continue

    # ${arquivo%.mpeg3} remove ".mpeg3" SÓ do final do nome (apoio, item 8).
    novo="${arquivo%.mpeg3}.mp3"

    # O mv sobrescreveria sem avisar um .mp3 que já existisse, perdendo o
    # conteúdo dele. Nesse caso o arquivo é pulado, com aviso no stderr.
    if [ -e "$novo" ]; then
        echo "Pulando '$arquivo': '$novo' já existe" >&2
        pulados=$((pulados + 1))
        continue
    fi

    # -- marca o fim das opções do mv: um arquivo chamado "-x.mpeg3" não é
    # confundido com uma opção. Se o mv falhar, ele mesmo imprime o motivo.
    if mv -- "$arquivo" "$novo"; then
        echo "'$arquivo' -> '$novo'"
        renomeados=$((renomeados + 1))
    else
        falhas=$((falhas + 1))
    fi
done

# ---------------------------------------------------------------------------
# Resumo
# ---------------------------------------------------------------------------

echo "$renomeados arquivo(s) renomeado(s), $pulados pulado(s)."

# Se algum mv falhou, o status de saída avisa quem chamou o script.
[ "$falhas" -eq 0 ] || erro "$falhas arquivo(s) não puderam ser renomeados"
