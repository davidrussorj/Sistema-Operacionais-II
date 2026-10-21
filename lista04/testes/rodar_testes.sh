#!/bin/bash
#
# Lista 4 - Bateria de testes automáticos
#
# Roda cada script da lista com entradas conhecidas e confere duas coisas:
# a saída (stdout/stderr) e o status de saída. Cada conferência imprime OK,
# FALHOU ou PULADO; no final aparece o resumo, e o status do próprio
# testador é 0 só se nada falhou.
#
# Uso:
#   ./testes/rodar_testes.sh           testa todos os exercícios
#   ./testes/rodar_testes.sh 3 4       testa só os exercícios 3 e 4
#   make test                          o mesmo que a primeira forma
#
# Garantias:
#   - os arquivos de testes/ NUNCA são alterados: tudo que os testes criam
#     fica numa pasta temporária, apagada ao final (trap EXIT);
#   - testes que dependem de permissões (que não valem para o root) ou de
#     algo que a máquina não tem aparecem como PULADO em vez de falhar.
#
# Técnica usada no ex1, cuja saída depende da hora, dos discos e de quem está
# logado: comandos date, df e who FALSOS, colocados na frente do PATH, que
# imprimem sempre o mesmo texto. O script chama "date", "df" e "who" sem
# caminho, então usa os falsos sem saber.

set -u

# ---------------------------------------------------------------------------
# Caminhos e pasta temporária
# ---------------------------------------------------------------------------

# Pasta da lista (o pai da pasta onde este arquivo está), em caminho absoluto,
# para o testador funcionar de qualquer diretório.
LISTA=$(cd "$(dirname "$0")/.." && pwd)
MODELOS="$LISTA/testes"

# Tudo que os testes criam fica aqui dentro. O trap roda ao sair (mesmo com
# Ctrl+C): devolve as permissões tiradas nos testes de permissão (senão o rm
# não conseguiria apagar) e apaga a pasta.
TMP=$(mktemp -d)
trap 'chmod -R u+rwx "$TMP" 2> /dev/null; rm -rf "$TMP"' EXIT

# ---------------------------------------------------------------------------
# Contadores e cores
# ---------------------------------------------------------------------------

PASSOU=0
FALHOU=0
PULOU=0

# Cores só quando a saída é um terminal (-t 1); num arquivo ou pipe, os
# códigos de cor virariam lixo no texto.
if [ -t 1 ]; then
    VERDE=$'\e[32m' VERMELHO=$'\e[31m' AMARELO=$'\e[33m' NEGRITO=$'\e[1m' NORMAL=$'\e[0m'
else
    VERDE='' VERMELHO='' AMARELO='' NEGRITO='' NORMAL=''
fi

# Limite de tempo por execução: um script que entre em laço infinito (por
# exemplo, o ex1 perguntando para sempre depois do fim da entrada, ou o ex4
# com um número negativo) é interrompido pelo timeout e vira FALHOU com
# status 124, em vez de travar o testador para sempre.
LIMITE_SEGUNDOS=30
if command -v timeout > /dev/null; then
    COM_LIMITE=(timeout "$LIMITE_SEGUNDOS")
else
    COM_LIMITE=()
fi

# Root ignora permissões de arquivo, então os testes de "sem permissão" não
# fazem sentido para ele.
SOU_ROOT=0
[ "$(id -u)" -eq 0 ] && SOU_ROOT=1

# ---------------------------------------------------------------------------
# Comandos falsos (mocks) para o ex1
# ---------------------------------------------------------------------------

# Cada comando falso imprime o conteúdo de uma variável de ambiente e
# anota o próprio nome no arquivo $REGISTRO (se definido), para os testes
# saberem QUAIS comandos o script chegou a executar. O df falso ainda sai
# com o status de $DF_STATUS, para simular um df que falha.
# Usado como: env PATH="$FALSOS:$PATH" DATA_FALSA="..." script
FALSOS="$TMP/bin_falsos"
mkdir -p "$FALSOS"
cat > "$FALSOS/date" << 'FIM'
#!/bin/bash
echo date >> "${REGISTRO:-/dev/null}"
echo "$DATA_FALSA"
FIM
cat > "$FALSOS/df" << 'FIM'
#!/bin/bash
echo "df $*" >> "${REGISTRO:-/dev/null}"
printf '%s\n' "$DF_FALSO"
exit "${DF_STATUS:-0}"
FIM
cat > "$FALSOS/who" << 'FIM'
#!/bin/bash
echo who >> "${REGISTRO:-/dev/null}"
if [ -n "$WHO_FALSO" ]; then
    printf '%s\n' "$WHO_FALSO"
fi
FIM
chmod +x "$FALSOS/date" "$FALSOS/df" "$FALSOS/who"

# Valores fixos dos comandos falsos.
DATA_FIXA="Wed Oct 21 14:00:00 -03 2026"
DF_FIXO=$'Filesystem      Size  Used Avail Use% Mounted on\n/dev/sda1        50G   20G   28G  42% /'
WHO_FIXO=$'ana      pts/0        2026-10-21 08:00\ncarlos   pts/1        2026-10-21 09:30'

# PATH mínimo: só date e df, sem who - para testar a mensagem de "comando
# não encontrado" sem precisar desinstalar nada.
MINIMO="$TMP/bin_minimo"
mkdir -p "$MINIMO"
for cmd in date df; do
    ln -s "$(command -v "$cmd")" "$MINIMO/$cmd"
done

# ---------------------------------------------------------------------------
# Execução dos scripts
# ---------------------------------------------------------------------------

# roda COMANDO...
#   Executa o comando guardando stdout em SAIDA, stderr em ERRO e o status em
#   STATUS, sem interromper o testador se o comando falhar. O stdin vem de
#   /dev/null: um script que tentasse ler do teclado receberia "fim de
#   entrada" na hora, em vez de travar o testador. Todas as variantes rodam
#   o comando com o limite de tempo (COM_LIMITE).
roda() {
    SAIDA=$("${COM_LIMITE[@]}" "$@" < /dev/null 2> "$TMP/stderr")
    STATUS=$?
    ERRO=$(< "$TMP/stderr")
}

# roda_com_entrada TEXTO COMANDO...
#   Igual a roda, mas manda TEXTO para o stdin (é assim que os scripts que
#   usam read são testados). TEXTO vai exatamente como está (printf %s):
#   para ter quebras de linha, use $'...\n'.
roda_com_entrada() {
    local entrada="$1"
    shift
    SAIDA=$(printf '%s' "$entrada" | "${COM_LIMITE[@]}" "$@" 2> "$TMP/stderr")
    STATUS=$?
    ERRO=$(< "$TMP/stderr")
}

# roda_em DIRETÓRIO COMANDO...
#   Igual a roda, mas executa dentro de DIRETÓRIO (para conferir que o
#   script não cria arquivos no diretório atual, ou que um * passado como
#   argumento não é expandido para os arquivos de lá). O cd acontece dentro
#   do $(...), que é um subshell, então o diretório do testador não muda.
roda_em() {
    local dir="$1"
    shift
    SAIDA=$(cd "$dir" && "${COM_LIMITE[@]}" "$@" < /dev/null 2> "$TMP/stderr")
    STATUS=$?
    ERRO=$(< "$TMP/stderr")
}

# ---------------------------------------------------------------------------
# Conferências
# ---------------------------------------------------------------------------

ok() {
    PASSOU=$((PASSOU + 1))
    printf '  %sOK%s      %s\n' "$VERDE" "$NORMAL" "$1"
}

# mostra_valor RÓTULO TEXTO
#   Imprime "RÓTULO texto" alinhando as linhas seguintes embaixo da primeira
#   e cortando textos longos em 8 linhas, para uma saída gigante (ex.: a de
#   um laço infinito) não inundar a tela.
mostra_valor() {
    local total
    total=$(printf '%s\n' "$2" | wc -l)
    {
        printf '%s\n' "$2" | head -n 8
        if [ "$total" -gt 8 ]; then
            printf '... (%d linhas no total)\n' "$total"
        fi
    } | sed "1s/^/          $1 /; 2,\$s/^/                    /"
}

# falha DESCRIÇÃO [ESPERADO OBTIDO]
falha() {
    FALHOU=$((FALHOU + 1))
    printf '  %sFALHOU%s  %s\n' "$VERMELHO" "$NORMAL" "$1"
    if [ $# -ge 3 ]; then
        mostra_valor "esperado:" "$2"
        mostra_valor "obtido:  " "$3"
    fi
    # Status 124 é o código do timeout: a execução foi interrompida.
    if [ "${STATUS:-0}" -eq 124 ] && [ ${#COM_LIMITE[@]} -gt 0 ]; then
        printf '          (a execução passou de %d s e foi interrompida: laço infinito?)\n' "$LIMITE_SEGUNDOS"
    fi
}

pula() {
    PULOU=$((PULOU + 1))
    printf '  %sPULADO%s  %s\n' "$AMARELO" "$NORMAL" "$1"
}

secao() {
    printf '\n%s== %s ==%s\n' "$NEGRITO" "$1" "$NORMAL"
}

# confere_status DESCRIÇÃO ESPERADO     (compara com o STATUS da última execução)
confere_status() {
    if [ "$STATUS" -eq "$2" ]; then
        ok "$1"
    else
        falha "$1" "status $2" "status $STATUS (stderr: $ERRO)"
    fi
}

# confere_igual DESCRIÇÃO ESPERADO OBTIDO
confere_igual() {
    if [ "$2" = "$3" ]; then
        ok "$1"
    else
        falha "$1" "$2" "$3"
    fi
}

# confere_contem DESCRIÇÃO TRECHO TEXTO
confere_contem() {
    case "$3" in
        *"$2"*) ok "$1" ;;
        *) falha "$1" "algo contendo '$2'" "$3" ;;
    esac
}

# confere_nao_contem DESCRIÇÃO TRECHO TEXTO
confere_nao_contem() {
    case "$3" in
        *"$2"*) falha "$1" "nada contendo '$2'" "$3" ;;
        *) ok "$1" ;;
    esac
}

# confere DESCRIÇÃO COMANDO...   (passa se o comando der status 0, ex.: [ -f x ])
confere() {
    local descricao="$1"
    shift
    if "$@"; then
        ok "$descricao"
    else
        falha "$descricao"
    fi
}

# linha_apos LINHA TEXTO
#   Imprime a linha de TEXTO que vem logo depois da primeira linha igual a
#   LINHA (vazio se não houver). Serve para conferir que a saída de um
#   comando aparece logo depois do anúncio dele (ex1).
linha_apos() {
    printf '%s\n' "$2" | awk -v alvo="$1" 'achou { print; exit } $0 == alvo { achou = 1 }'
}

# roda_ex1 ENTRADA [VARIÁVEL=VALOR ...]
#   Roda o ex1 com os comandos falsos e a ENTRADA dada como resposta. As
#   variáveis extras substituem os valores fixos (ex.: WHO_FALSO= para um who
#   que não mostra ninguém). O arquivo $TMP/registro fica com a lista dos
#   comandos que o script executou.
roda_ex1() {
    local entrada="$1"
    shift
    : > "$TMP/registro"
    roda_com_entrada "$entrada" env PATH="$FALSOS:$PATH" REGISTRO="$TMP/registro" \
        DATA_FALSA="$DATA_FIXA" DF_FALSO="$DF_FIXO" WHO_FALSO="$WHO_FIXO" DF_STATUS=0 \
        "$@" "$LISTA/ex1_info_sistema.sh"
}

# ---------------------------------------------------------------------------
# Exercício 1
# ---------------------------------------------------------------------------

testa_ex1() {
    secao "Exercício 1 - informações do sistema"
    local s="$LISTA/ex1_info_sistema.sh"
    local anuncios resposta

    roda "$s" argumento_a_mais
    confere_status "recusa argumentos (status 2)" 2
    confere_contem "mostra a mensagem de uso" "Uso:" "$ERRO"

    roda env PATH="$MINIMO" "$s"
    confere_status "sem o comando who: status 1" 1
    confere_contem "sem o who: diz qual comando falta" "comando who não encontrado" "$ERRO"

    # Caso normal: responde "s".
    roda_ex1 $'s\n'
    confere_status "respondendo s: status 0" 0
    confere_contem "[c] mostra o que vai executar antes de perguntar" "Este script vai executar:" "$SAIDA"
    anuncios=$(printf '%s\n' "$SAIDA" | grep '^==> ')
    confere_igual "[b] anuncia os três comandos, na ordem" \
        $'==> Horário atual\n==> Ocupação do disco\n==> Usuários logados' "$anuncios"
    confere_igual "[a] horário: a saída do date vem logo depois do anúncio" \
        "$DATA_FIXA" "$(linha_apos '    $ date' "$SAIDA")"
    confere_igual "[a] disco: a saída do df -h vem logo depois do anúncio" \
        "${DF_FIXO%%$'\n'*}" "$(linha_apos '    $ df -h' "$SAIDA")"
    confere_contem "[a] usuários: a saída do who aparece inteira" "$WHO_FIXO" "$SAIDA"
    confere_igual "executou date, df -h e who, nessa ordem" \
        $'date\ndf -h\nwho' "$(cat "$TMP/registro")"
    confere_contem "termina com a mensagem de sucesso" "os 3 comandos foram executados" "$SAIDA"
    confere_igual "nada no stderr" "" "$ERRO"

    # Todas as formas de "sim" do case (slide 46), e com espaços em volta.
    for resposta in S sim Sim SIM "  s  "; do
        roda_ex1 "$resposta"$'\n'
        confere_status "resposta '$resposta' conta como sim (status 0)" 0
    done

    # Todas as formas de "não", inclusive só Enter.
    for resposta in n N não Não NÃO nao NAO ""; do
        roda_ex1 "$resposta"$'\n'
        confere_status "resposta '$resposta' conta como não (status 1)" 1
        confere_igual "resposta '$resposta': nenhum comando foi executado" "" "$(cat "$TMP/registro")"
    done
    confere_contem "ao cancelar, avisa que nada foi executado" "nenhum comando foi executado" "$SAIDA"
    roda_ex1 $'\ns\n'
    confere_status "Enter já é a resposta 'não' (não pergunta de novo)" 1

    # Resposta inválida: pergunta de novo.
    roda_ex1 $'talvez\nx\ns\n'
    confere_status "duas respostas inválidas e depois s: status 0" 0
    confere_contem "resposta inválida: explica o que responder" \
        "Resposta 'talvez' não reconhecida" "$SAIDA"
    confere_igual "só executa depois da resposta válida" $'date\ndf -h\nwho' "$(cat "$TMP/registro")"

    # Fim de entrada: não pode perguntar para sempre.
    roda_ex1 $'talvez\n'
    confere_status "resposta inválida e depois fim da entrada: status 1 (sem laço infinito)" 1
    confere_contem "fim da entrada: explica o erro" "a entrada terminou sem resposta" "$ERRO"
    roda_ex1 ""
    confere_status "entrada vazia (Ctrl+D direto): status 1" 1
    confere_igual "entrada vazia: nenhum comando foi executado" "" "$(cat "$TMP/registro")"
    roda_ex1 "s"
    confere_status "'s' sem \\n no final (última linha do pipe): vale como sim" 0

    # who sem ninguém logado (comum no WSL e em contêineres).
    roda_ex1 $'s\n' WHO_FALSO=
    confere_status "who sem ninguém: status 0" 0
    confere_igual "who sem ninguém: a seção avisa em vez de ficar em branco" \
        "(o comando não mostrou nada)" "$(linha_apos '    $ who' "$SAIDA")"

    # Um comando que falha não interrompe os outros, mas muda o status.
    roda_ex1 $'s\n' DF_STATUS=1
    confere_status "df falhando: status 1" 1
    confere_contem "df falhando: diz quantos falharam" "1 comando(s) falharam" "$ERRO"
    confere_igual "df falhando: o who é executado mesmo assim" $'date\ndf -h\nwho' "$(cat "$TMP/registro")"

    # Com os comandos de verdade.
    roda_com_entrada $'s\n' "$s"
    confere_status "com os comandos reais (date, df, who): status 0" 0
    confere_contem "com o df real: aparece o cabeçalho do df" "Use%" "$SAIDA"

    roda_com_entrada $'s\n' sh "$s"
    confere_status "rodando com sh (dash, slide 23): status 0" 0
    confere_contem "rodando com sh: executa os comandos" "os 3 comandos foram executados" "$SAIDA"
}

# ---------------------------------------------------------------------------
# Exercício 2
# ---------------------------------------------------------------------------

testa_ex2() {
    secao "Exercício 2 - arquivo ou diretório?"
    local s="$LISTA/ex2_tipo_arquivo.sh"
    local d="$TMP/ex2"

    mkdir -p "$d/casa"
    touch "$d/casa/nota.txt" "$d/fim com espaço " "$d/barra\\invertida"
    ln -s "$MODELOS/subdir_teste" "$d/link_dir"

    roda_com_entrada "$MODELOS/arquivo_teste.txt"$'\n' "$s"
    confere_status "arquivo comum: status 0" 0
    confere_contem "arquivo comum: diz que é arquivo" "existe e é um arquivo comum." "$SAIDA"

    roda_com_entrada "$MODELOS/subdir_teste"$'\n' "$s"
    confere_status "diretório: status 0" 0
    confere_contem "diretório: diz que é diretório" "existe e é um diretório." "$SAIDA"

    roda_com_entrada "$MODELOS/nome com espaço.txt"$'\n' "$s"
    confere_status "nome com espaço: status 0 (aspas em \"\$nome\")" 0
    confere_contem "nome com espaço: diz que é arquivo" "um arquivo comum" "$SAIDA"

    roda_com_entrada "$d/não existe com espaço.txt"$'\n' "$s"
    confere_status "nome com espaço que não existe: status 1" 1
    confere_contem "nome com espaço que não existe: diz que não existe" "não existe." "$SAIDA"
    confere_igual "nome com espaço: nenhum erro do [ no stderr" "" "$ERRO"

    roda_com_entrada "$d/fim com espaço "$'\n' "$s"
    confere_contem "espaço no FIM do nome é mantido (IFS= no read)" "um arquivo comum" "$SAIDA"

    roda_com_entrada "$d/barra\\invertida"$'\n' "$s"
    confere_contem "barra invertida no nome é mantida (read -r)" "um arquivo comum" "$SAIDA"

    roda_com_entrada "$MODELOS/link_teste.txt"$'\n' "$s"
    confere_status "link para arquivo: status 0" 0
    confere_contem "link para arquivo: diz as duas coisas" "link simbólico para um arquivo comum" "$SAIDA"

    roda_com_entrada "$d/link_dir"$'\n' "$s"
    confere_contem "link para diretório: diz as duas coisas" "link simbólico para um diretório" "$SAIDA"

    roda_com_entrada "$MODELOS/link_quebrado"$'\n' "$s"
    confere_status "link quebrado: status 1" 1
    confere_contem "link quebrado: identificado como link" "link simbólico quebrado" "$SAIDA"
    confere_contem "link quebrado: diz para onde ele aponta" "nao_existe.txt" "$SAIDA"

    roda_com_entrada "$MODELOS/nao_existe.txt"$'\n' "$s"
    confere_status "inexistente: status 1" 1
    confere_contem "inexistente: diz que não existe" "não existe." "$SAIDA"

    if [ -c /dev/null ]; then
        roda_com_entrada $'/dev/null\n' "$s"
        confere_status "/dev/null existe: status 0" 0
        confere_contem "/dev/null não é chamado de arquivo comum" "dispositivo" "$SAIDA"
    else
        pula "/dev/null (não é um dispositivo nesta máquina)"
    fi

    if command -v mkfifo > /dev/null && mkfifo "$d/fifo" 2> /dev/null; then
        roda_com_entrada "$d/fifo"$'\n' "$s"
        confere_contem "pipe nomeado (FIFO) é identificado" "pipe nomeado" "$SAIDA"
    else
        pula "pipe nomeado (mkfifo indisponível)"
    fi

    roda_com_entrada $'~\n' env HOME="$d/casa" "$s"
    confere_contem "~ vira o \$HOME" "'$d/casa' existe e é um diretório." "$SAIDA"
    roda_com_entrada $'~/nota.txt\n' env HOME="$d/casa" "$s"
    confere_contem "~/arquivo vira \$HOME/arquivo" "'$d/casa/nota.txt' existe e é um arquivo comum." "$SAIDA"
    roda_com_entrada $'~ninguem_aqui\n' env HOME="$d/casa" "$s"
    confere_contem "~usuario não é trocado por \$HOME" "'~ninguem_aqui' não existe." "$SAIDA"

    if [ "$SOU_ROOT" -eq 1 ]; then
        pula "arquivo dentro de diretório sem permissão (rodando como root)"
    else
        mkdir -p "$d/fechado/sub"
        touch "$d/fechado/dentro.txt"
        chmod 000 "$d/fechado"
        roda_com_entrada "$d/fechado/dentro.txt"$'\n' "$s"
        confere_status "dentro de diretório sem permissão: status 1" 1
        confere_contem "sem permissão: não afirma que não existe" \
            "sem permissão para entrar em '$d/fechado'" "$ERRO"
        confere_nao_contem "sem permissão: a resposta 'não existe' não aparece" "não existe." "$SAIDA"
        roda_com_entrada "$d/fechado/sub/x.txt"$'\n' "$s"
        confere_contem "sem permissão dois níveis acima: acha o diretório fechado" \
            "sem permissão para entrar em '$d/fechado'" "$ERRO"
        chmod 755 "$d/fechado"
    fi

    roda_com_entrada $'$HOME/x.txt\n' "$s"
    confere_status "\$HOME digitado: status 1 (o read não expande)" 1
    confere_contem "\$HOME digitado: explica por que não achou" "não expande variáveis" "$SAIDA"
    roda_com_entrada "$MODELOS/arquivo_teste.txt "$'\n' "$s"
    confere_status "espaço digitado sem querer no fim: status 1" 1
    confere_contem "espaço sem querer no fim: avisa" "termina com espaço" "$SAIDA"
    roda_com_entrada "$d/nada aqui "$'\n' "$s"
    confere_nao_contem "espaço no fim de um nome que não existe de jeito nenhum: sem aviso" \
        "termina com espaço" "$SAIDA"

    roda_com_entrada "$MODELOS/subdir_teste"$'\n' sh "$s"
    confere_contem "rodando com sh (dash): mesma resposta" "existe e é um diretório." "$SAIDA"

    roda_com_entrada "$MODELOS/arquivo_teste.txt" "$s"
    confere_status "última linha sem \\n: o nome é lido mesmo assim" 0

    roda_com_entrada $'\n' "$s"
    confere_status "só Enter (nome vazio): status 1" 1
    confere_contem "nome vazio: explica o erro" "não pode ser vazio" "$ERRO"

    roda "$s"
    confere_status "entrada termina antes do nome: status 1" 1
    confere_contem "entrada termina antes do nome: explica o erro" "a entrada terminou" "$ERRO"

    roda "$s" "$MODELOS/arquivo_teste.txt"
    confere_status "nome como argumento em vez de digitado: status 2" 2
    confere_contem "argumento: mostra a mensagem de uso" "Uso:" "$ERRO"
}

# ---------------------------------------------------------------------------
# Exercício 3
# ---------------------------------------------------------------------------

testa_ex3() {
    secao "Exercício 3 - relação entre dois números"
    local s="$LISTA/ex3_relacao.sh"
    local d="$TMP/ex3"

    mkdir -p "$d"

    # Os três exemplos do enunciado, com a saída exata.
    roda "$s" 3 5
    confere_igual "3 5 -> exemplo do enunciado" "3 é menor que 5" "$SAIDA"
    confere_status "3 5: status 0" 0
    roda "$s" 5 3
    confere_igual "5 3 -> exemplo do enunciado" "5 é maior que 3" "$SAIDA"
    roda "$s" 5 5
    confere_igual "5 5 -> exemplo do enunciado" "5 é igual a 5" "$SAIDA"

    roda "$s" 10 10
    confere_igual "10 10 é igual (o if/else do enunciado diria 'menor')" "10 é igual a 10" "$SAIDA"
    roda "$s" 10 9
    confere_igual "10 9: compara como número, não como texto" "10 é maior que 9" "$SAIDA"
    roda "$s" 9 10
    confere_igual "9 10: compara como número, não como texto" "9 é menor que 10" "$SAIDA"
    roda "$s" -3 -10
    confere_igual "negativos: -3 é maior que -10" "-3 é maior que -10" "$SAIDA"
    roda "$s" -5 3
    confere_igual "negativo e positivo" "-5 é menor que 3" "$SAIDA"
    roda "$s" 007 7
    confere_igual "zeros à esquerda: 007 é igual a 7" "007 é igual a 7" "$SAIDA"
    roda "$s" 9223372036854775807 9223372036854775806
    confere_igual "limite de 64 bits ainda funciona" \
        "9223372036854775807 é maior que 9223372036854775806" "$SAIDA"

    roda_em "$d" "$s" 3 5
    confere_igual "não cria arquivos no diretório atual (não usa > no teste)" "" "$(ls -A "$d")"

    roda sh "$s" 3 5
    confere_igual "rodando com sh (dash, que não tem [[ =~ ]]): mesma saída" "3 é menor que 5" "$SAIDA"
    confere_igual "rodando com sh: nada no stderr" "" "$ERRO"

    roda "$s" 3.5 2
    confere_status "3.5: status 1" 1
    confere_contem "3.5: explica o erro" "'3.5' não é um número inteiro" "$ERRO"
    roda "$s" 2 abc
    confere_status "abc: status 1" 1
    confere_nao_contem "abc: o erro do [ não aparece" "integer expression expected" "$ERRO"
    roda "$s" " 5" 3
    confere_status "' 5' (com espaço): status 1" 1
    roda "$s" 99999999999999999999 1
    confere_status "número grande demais: status 1" 1
    confere_contem "número grande demais: explica o erro" "grande demais" "$ERRO"

    roda "$s"
    confere_status "sem argumentos: status 2" 2
    roda "$s" 5
    confere_status "um argumento: status 2" 2
    confere_contem "um argumento: mostra a mensagem de uso" "Uso:" "$ERRO"
    roda "$s" 1 2 3
    confere_status "três argumentos: status 2" 2
    roda "$s" "" 1
    confere_status "primeiro vazio: status 2" 2
    roda "$s" 1 ""
    confere_status "segundo vazio: status 2" 2
}

# ---------------------------------------------------------------------------
# Exercício 4
# ---------------------------------------------------------------------------

testa_ex4() {
    secao "Exercício 4 - zerador"
    local s="$LISTA/ex4_zerador.sh"
    local palavras

    roda "$s" 5
    confere_igual "5 -> exemplo do enunciado" "5 4 3 2 1 0" "$SAIDA"
    confere_status "5: status 0" 0
    roda "$s" 10
    confere_igual "10 -> exemplo do enunciado" "10 9 8 7 6 5 4 3 2 1 0" "$SAIDA"
    roda "$s" 0
    confere_igual "0: só o zero" "0" "$SAIDA"
    roda "$s" 1
    confere_igual "1: um passo" "1 0" "$SAIDA"

    confere_igual "tudo numa linha só, terminada com \\n" "1" "$("$s" 10 | wc -l)"
    roda "$s" 3
    confere "sem espaço sobrando no fim da linha" [ "${SAIDA% }" = "$SAIDA" ]

    roda "$s" 010
    confere_igual "010 é dez, não oito (o \$(( )) leria em octal)" "10 9 8 7 6 5 4 3 2 1 0" "$SAIDA"
    roda "$s" 08
    confere_status "08: status 0 (sem 'value too great for base')" 0
    confere_igual "08 vale oito" "8 7 6 5 4 3 2 1 0" "$SAIDA"
    roda sh "$s" 010
    confere_igual "rodando com sh (dash, que não tem 10#): mesma saída" "10 9 8 7 6 5 4 3 2 1 0" "$SAIDA"
    confere_igual "rodando com sh: nada no stderr" "" "$ERRO"

    roda "$s" 100
    palavras=$(printf '%s\n' "$SAIDA" | wc -w)
    confere_igual "100: mostra 101 passos (de 100 até 0)" "101" "$palavras"
    confere_contem "100: começa em 100 e termina em 0" "100 99 98" "$SAIDA"

    roda "$s" -3
    confere_status "negativo: status 1 (sem laço infinito)" 1
    confere_contem "negativo: explica o erro" "negativo" "$ERRO"
    roda "$s" 2.5
    confere_status "2.5: status 1" 1
    confere_contem "2.5: explica o erro" "não é um número inteiro" "$ERRO"
    roda "$s" abc
    confere_status "abc: status 1" 1
    confere_nao_contem "abc: o erro do [ não aparece" "integer expression expected" "$ERRO"
    roda "$s" 99999999999999999999
    confere_status "número grande demais: status 1" 1
    confere_contem "número grande demais: explica o erro" "grande demais" "$ERRO"

    roda "$s"
    confere_status "sem argumento: status 2" 2
    roda "$s" 5 3
    confere_status "dois argumentos: status 2" 2
    roda "$s" ""
    confere_status "argumento vazio: status 2" 2
}

# ---------------------------------------------------------------------------
# Exercício 5
# ---------------------------------------------------------------------------

testa_ex5() {
    secao "Exercício 5 - substring"
    local s="$LISTA/ex5_substring.sh"

    # Os quatro exemplos do enunciado: saída exata e nada no stderr.
    roda "$s" ana banana
    confere_igual "ana banana -> exemplo do enunciado" "ana está contida em banana" "$SAIDA"
    confere_status "ana banana: status 0" 0
    roda "$s" banana maria
    confere_igual "banana maria: não mostra nada" "" "$SAIDA$ERRO"
    confere_status "banana maria: status 1" 1
    roda "$s" banana
    confere_igual "uma palavra só: não mostra nada (nem mensagem de uso)" "" "$SAIDA$ERRO"
    confere_status "uma palavra só: status 2" 2
    roda "$s"
    confere_igual "sem palavras: não mostra nada" "" "$SAIDA$ERRO"
    confere_status "sem palavras: status 2" 2

    roda "$s" banana banana
    confere_status "palavra igual à outra está contida (status 0)" 0
    roda "$s" ban banana
    confere_status "no começo (ban em banana): status 0" 0
    roda "$s" nana banana
    confere_status "no fim (nana em banana): status 0" 0
    roda "$s" 'a b' 'casa bela'
    confere_igual "palavra com espaço" "a b está contida em casa bela" "$SAIDA"

    roda "$s" Ana banana
    confere_status "diferencia maiúsculas: Ana não está em banana (status 1)" 1

    roda "$s" '?' banana
    confere_status "'?' não vira wildcard (aspas no padrão do case)" 1
    roda "$s" '*' banana
    confere_status "'*' não vira wildcard" 1
    roda "$s" '[ab]' banana
    confere_status "'[ab]' não vira conjunto [set]" 1
    roda "$s" '[ab]' 'x[ab]y'
    confere_status "'[ab]' literal é encontrado em 'x[ab]y'" 0
    roda "$s" . banana
    confere_status "'.' não vira expressão regular (não usa grep)" 1

    roda "$s" -n x-ny
    confere_igual "palavra '-n' sai na mensagem" "-n está contida em x-ny" "$SAIDA"
    roda "$s" 'a\tb' 'xa\tby'
    confere_igual "barra invertida sai literal" 'a\tb está contida em xa\tby' "$SAIDA"
    roda sh "$s" ana banana
    confere_igual "rodando com sh (dash): mesma saída" "ana está contida em banana" "$SAIDA"

    roda "$s" "" banana
    confere_status "primeira palavra vazia: status 2" 2
    confere_igual "primeira palavra vazia: não mostra nada" "" "$SAIDA$ERRO"
    roda "$s" ana ""
    confere_status "segunda palavra vazia: status 2" 2
    roda "$s" a b c
    confere_status "três palavras: status 2" 2
    confere_igual "três palavras: não mostra nada" "" "$SAIDA$ERRO"
}

# ---------------------------------------------------------------------------
# Exercício 6
# ---------------------------------------------------------------------------

testa_ex6() {
    secao "Exercício 6 - parâmetros grudados"
    local s="$LISTA/ex6_juntaparms.sh"
    local d="$TMP/ex6"

    mkdir -p "$d"
    touch "$d/arquivo1" "$d/arquivo2"

    roda "$s" a b c d e f verde azul
    confere_igual "exemplo do enunciado" "abcdefverdeazul" "$SAIDA"
    confere_status "exemplo do enunciado: status 0" 0
    confere_igual "tudo numa linha só" "1" "$("$s" a b c | wc -l)"

    roda "$s" abc
    confere_igual "um parâmetro só sai como veio" "abc" "$SAIDA"
    roda "$s" "verde claro" azul
    confere_igual "espaço DENTRO de um parâmetro também some (uma única palavra)" "verdeclaroazul" "$SAIDA"
    roda "$s" $'a\tb' $'c\nd'
    confere_igual "TAB e quebra de linha dentro dos parâmetros também somem" "abcd" "$SAIDA"
    roda "$s" "" a "" b
    confere_igual "parâmetros vazios não atrapalham" "ab" "$SAIDA"
    roda "$s" ação é
    confere_igual "acentos (UTF-8) passam intactos pelo tr" "açãoé" "$SAIDA"
    roda "$s" -n
    confere_igual "'-n' sozinho é impresso (não vira opção do echo)" "-n" "$SAIDA"
    roda_em "$d" "$s" '*' x
    confere_igual "'*' não é expandido para os arquivos do diretório" "*x" "$SAIDA"
    roda sh "$s" a b c d e f verde azul
    confere_igual "rodando com sh (dash): mesma saída" "abcdefverdeazul" "$SAIDA"

    roda "$s" " " ""
    confere_status "só espaços: status 1" 1
    confere_contem "só espaços: explica o erro" "só têm espaços" "$ERRO"
    roda "$s"
    confere_status "sem parâmetros: status 2" 2
    confere_contem "sem parâmetros: mostra a mensagem de uso" "Uso:" "$ERRO"
}

# ---------------------------------------------------------------------------
# Validações comuns aos exercícios 7 e 8 (os dois leem um passwd)
# ---------------------------------------------------------------------------

# testa_validacoes_passwd SCRIPT PREFIXO
testa_validacoes_passwd() {
    local s="$1" d="$TMP/$2"

    mkdir -p "$d/pasta"
    : > "$d/vazio"
    printf 'isto não é um passwd\nnem isto\n' > "$d/lixo"

    roda "$s" "$d/nao_existe"
    confere_status "arquivo inexistente: status 1" 1
    confere_contem "arquivo inexistente: explica o erro" "não existe" "$ERRO"
    roda "$s" "$d/pasta"
    confere_status "diretório no lugar do arquivo: status 1" 1
    confere_contem "diretório: explica o erro" "não é um arquivo comum" "$ERRO"
    roda "$s" "$d/vazio"
    confere_status "arquivo vazio: status 1" 1
    confere_contem "arquivo vazio: explica o erro" "está vazio" "$ERRO"
    roda "$s" "$d/lixo"
    confere_status "nenhuma linha no formato do passwd: status 1" 1
    confere_contem "nenhuma linha válida: explica o erro" "nenhuma linha no formato" "$ERRO"

    if [ "$SOU_ROOT" -eq 1 ]; then
        pula "arquivo sem permissão de leitura (rodando como root)"
    else
        cp "$MODELOS/passwd_exemplo" "$d/fechado"
        chmod 000 "$d/fechado"
        roda "$s" "$d/fechado"
        confere_status "sem permissão de leitura: status 1" 1
        confere_contem "sem permissão: explica o erro" "sem permissão de leitura" "$ERRO"
        chmod 644 "$d/fechado"
    fi

    roda "$s" ""
    confere_status "nome vazio: status 2 (não cai no /etc/passwd)" 2
    roda "$s" a b
    confere_status "dois argumentos: status 2" 2
    confere_contem "dois argumentos: mostra a mensagem de uso" "Uso:" "$ERRO"
}

# ---------------------------------------------------------------------------
# Exercício 7
# ---------------------------------------------------------------------------

testa_ex7() {
    secao "Exercício 7 - usuário e nome completo"
    local s="$LISTA/ex7_usuarios.sh"
    local d="$TMP/ex7" esperado validas

    mkdir -p "$d"

    esperado=$(printf '%s\t%s\n' \
        root root bin bin daemon daemon sync sync shutdown shutdown halt halt \
        ftp "FTP User" nobody Nobody named "Domain name server" xfs "X Font Server" \
        mysql "MySQL server" ana "Ana Souza" carlos "")

    roda "$s" "$MODELOS/passwd_exemplo"
    confere_status "passwd_exemplo: status 0" 0
    confere_igual "passwd_exemplo: saída completa esperada" "$esperado" "$SAIDA"
    confere_contem "contém o trecho do exemplo do enunciado" \
        "$(printf '%s\t%s\n' ftp "FTP User" nobody Nobody named "Domain name server" xfs "X Font Server" mysql "MySQL server")" \
        "$SAIDA"
    confere_contem "o separador é um TAB" "ftp"$'\t'"FTP User" "$SAIDA"
    confere_nao_contem "o ':' do passwd não aparece" ":" "$SAIDA"
    confere_contem "nome completo = 1ª parte do campo 5, antes da vírgula" "ana"$'\t'"Ana Souza" "$SAIDA"
    confere_nao_contem "o resto do campo 5 (sala, telefone) não aparece" "Sala 12" "$SAIDA"
    confere_igual "campo 5 vazio: usuário, TAB e nada mais" "carlos"$'\t' "${SAIDA##*$'\n'}"
    confere_igual "nada no stderr" "" "$ERRO"
    roda sh "$s" "$MODELOS/passwd_exemplo"
    confere_igual "rodando com sh (dash): mesma saída" "$esperado" "$SAIDA"

    printf '%s\n' "ana:x:1:1:Ana:/home/ana:/bin/bash" "linha sem dois pontos" \
        "bia:x:2:2:Bia:/home/bia:/bin/bash" "a:b:c" > "$d/misturado"
    roda "$s" "$d/misturado"
    confere_status "linhas fora do formato: status 0 (as válidas são listadas)" 0
    confere_igual "linhas fora do formato: só as válidas na saída" \
        "$(printf '%s\t%s\n' ana Ana bia Bia)" "$SAIDA"
    confere_contem "linhas fora do formato: aviso no stderr com a contagem" "2 linha(s)" "$ERRO"

    if [ -r /etc/passwd ]; then
        roda "$s"
        validas=$(grep -cE '^([^:]*:){6}[^:]*$' /etc/passwd)
        confere_status "sem argumento usa o /etc/passwd: status 0" 0
        confere_igual "/etc/passwd: uma linha por usuário" "$validas" "$(printf '%s\n' "$SAIDA" | wc -l)"
    else
        pula "/etc/passwd (não pode ser lido nesta máquina)"
    fi

    testa_validacoes_passwd "$s" ex7_validacoes
}

# ---------------------------------------------------------------------------
# Exercício 8
# ---------------------------------------------------------------------------

testa_ex8() {
    secao "Exercício 8 - shells sem repetição"
    local s="$LISTA/ex8_shells.sh"
    local d="$TMP/ex8" esperado

    mkdir -p "$d"
    esperado=$(printf '%s\n' /bin/bash /bin/false /bin/sync /sbin/halt /sbin/shutdown)

    roda "$s" "$MODELOS/passwd_exemplo"
    confere_status "passwd_exemplo: status 0" 0
    confere_igual "passwd_exemplo: exatamente a saída do enunciado" "$esperado" "$SAIDA"
    confere_igual "nenhuma linha repetida" "" "$(printf '%s\n' "$SAIDA" | sort | uniq -d)"
    confere_igual "a pegadinha está no arquivo: sem o sort, o uniq deixa 7 linhas" \
        "7" "$(cut -d: -f7 "$MODELOS/passwd_exemplo" | uniq | wc -l)"

    printf '%s\n' "a:x:1:1::/:/bin/zsh" "b:x:2:2::/:" "c:x:3:3::/:/bin/zsh" "d:x:4:4::/:/bin/sh" > "$d/shell_vazio"
    roda "$s" "$d/shell_vazio"
    confere_igual "shell vazio vira /bin/sh e não sai linha em branco" \
        "$(printf '%s\n' /bin/sh /bin/zsh)" "$SAIDA"

    # Linhas com \r\n (arquivo salvo no Windows) misturadas com linhas \n.
    printf 'a:x:1:1::/:/bin/bash\r\nb:x:2:2::/:/bin/bash\nc:x:3:3::/:\r\n' > "$d/windows"
    roda "$s" "$d/windows"
    confere_igual "arquivo do Windows (\\r\\n): sem \\r e sem shell repetido" \
        "$(printf '%s\n' /bin/bash /bin/sh)" "$SAIDA"

    roda sh "$s" "$MODELOS/passwd_exemplo"
    confere_igual "rodando com sh (dash): mesma saída" "$esperado" "$SAIDA"

    printf '%s\n' "a:x:1:1::/:/bin/bash" "lixo" "b:x:2:2::/:/bin/bash" > "$d/misturado"
    roda "$s" "$d/misturado"
    confere_igual "linhas fora do formato: ignoradas" "/bin/bash" "$SAIDA"
    confere_contem "linhas fora do formato: aviso no stderr" "1 linha(s)" "$ERRO"

    if [ -r /etc/passwd ]; then
        roda "$s"
        confere_status "sem argumento usa o /etc/passwd: status 0" 0
        confere_igual "/etc/passwd: mesmos shells que o sort -u" \
            "$(grep -E '^([^:]*:){6}[^:]*$' /etc/passwd | cut -d: -f7 | sed 's|^$|/bin/sh|' | sort -u)" "$SAIDA"
    else
        pula "/etc/passwd (não pode ser lido nesta máquina)"
    fi

    testa_validacoes_passwd "$s" ex8_validacoes
}

# ---------------------------------------------------------------------------
# Exercício 9
# ---------------------------------------------------------------------------

testa_ex9() {
    secao "Exercício 9 - parâmetros contados"
    local s="$LISTA/ex9_parametros.sh"
    local d="$TMP/ex9" esperado

    mkdir -p "$d"
    touch "$d/arquivo1"

    # O printf repete o formato para cada par de valores.
    esperado=$(printf 'Parâmetro %d: %s\n' 1 a 2 b 3 c 4 d 5 e 6 f)
    roda "$s" a b c d e f
    confere_status "exemplo do enunciado: status 0" 0
    confere_igual "exemplo do enunciado: saída exata" "$esperado" "$SAIDA"

    roda "$s" a b c d e f g h i j k
    confere_contem "10º parâmetro é 'j' (e não '\$1' + '0' = 'a0')" "Parâmetro 10: j" "$SAIDA"
    confere_contem "11º parâmetro" "Parâmetro 11: k" "$SAIDA"

    roda "$s" "verde claro" azul
    confere_igual "parâmetro com espaço é um só" \
        "$(printf '%s\n' 'Parâmetro 1: verde claro' 'Parâmetro 2: azul')" "$SAIDA"
    roda "$s" "" x
    confere_contem "parâmetro vazio é listado" "Parâmetro 1: " "${SAIDA%%$'\n'*}"
    roda "$s" -n 'a\tb'
    confere_igual "'-n' e barra invertida saem literais" \
        "$(printf '%s\n' 'Parâmetro 1: -n' 'Parâmetro 2: a\tb')" "$SAIDA"
    roda_em "$d" "$s" '*'
    confere_igual "'*' não é expandido" "Parâmetro 1: *" "$SAIDA"
    roda sh "$s" a b c d e f
    confere_igual "rodando com sh (dash): mesma saída" "$esperado" "$SAIDA"

    # Sem aspas de propósito: cada número do seq vira um parâmetro.
    # shellcheck disable=SC2046
    roda "$s" $(seq 1 100)
    confere_igual "100 parâmetros: 100 linhas" "100" "$(printf '%s\n' "$SAIDA" | wc -l)"
    confere_igual "100 parâmetros: a última é a 100" "Parâmetro 100: 100" "${SAIDA##*$'\n'}"

    roda "$s"
    confere_status "sem parâmetros: status 2" 2
    confere_contem "sem parâmetros: mostra a mensagem de uso" "Uso:" "$ERRO"
}

# ---------------------------------------------------------------------------
# Programa principal
# ---------------------------------------------------------------------------

# Sem argumentos, testa todos; com argumentos, só os exercícios pedidos.
if [ $# -eq 0 ]; then
    set -- {1..9}
fi

for n in "$@"; do
    case "$n" in
        [1-9]) "testa_ex$n" ;;
        *)
            echo "Exercício inválido: '$n' (use números de 1 a 9)" >&2
            exit 2
            ;;
    esac
done

printf '\n%sResultado:%s %s%d OK%s, %s%d falharam%s, %s%d pulados%s\n' \
    "$NEGRITO" "$NORMAL" "$VERDE" "$PASSOU" "$NORMAL" \
    "$VERMELHO" "$FALHOU" "$NORMAL" "$AMARELO" "$PULOU" "$NORMAL"

# Status do testador: 0 só se nenhuma conferência falhou.
[ "$FALHOU" -eq 0 ]
