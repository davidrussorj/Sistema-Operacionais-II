#!/bin/bash
#
# Lista 4 - Bateria de testes automáticos
#
# Roda cada script da lista com entradas conhecidas e confere três coisas:
# a saída (stdout/stderr), o status de saída e os arquivos criados ou
# alterados. Cada conferência imprime OK, FALHOU ou PULADO; no final aparece
# o resumo, e o status do próprio testador é 0 só se nada falhou.
#
# Uso:
#   ./testes/rodar_testes.sh           testa todos os exercícios
#   ./testes/rodar_testes.sh 7 8       testa só os exercícios 7 e 8
#   make test                          o mesmo que a primeira forma
#
# Garantias:
#   - os arquivos de testes/ NUNCA são alterados: tudo que é destrutivo roda
#     em cópias dentro de uma pasta temporária, apagada ao final (trap EXIT);
#   - testes que dependem de comandos opcionais (banner, cal) ou de
#     permissões (que não valem para o root) aparecem como PULADO em vez de
#     falhar.
#
# Técnica usada para saídas que dependem da hora (ex1 e ex14): um "date"
# falso, colocado na frente do PATH, que sempre imprime a mesma data. Os
# scripts chamam "date" sem caminho, então usam o falso sem saber.

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
# exemplo, um shift errado no ex10) é interrompido pelo timeout e vira
# FALHOU com status 124, em vez de travar o testador para sempre.
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
# Comandos falsos (mocks)
# ---------------------------------------------------------------------------

# date falso: imprime o conteúdo da variável DATA_FALSA, ignorando o formato
# pedido. Usado como: env PATH="$FALSOS:$PATH" DATA_FALSA="..." script
FALSOS="$TMP/bin_falsos"
mkdir -p "$FALSOS"
cat > "$FALSOS/date" << 'FIM'
#!/bin/bash
echo "$DATA_FALSA"
FIM
chmod +x "$FALSOS/date"

# PATH mínimo: só cut e date, sem banner nem cal - para testar a mensagem de
# "comando não instalado" mesmo numa máquina que tem esses comandos.
MINIMO="$TMP/bin_minimo"
mkdir -p "$MINIMO"
for cmd in cut date; do
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
#   usam read são testados). \n no TEXTO vira quebra de linha (printf %b).
roda_com_entrada() {
    local entrada="$1"
    shift
    SAIDA=$(printf '%b' "$entrada" | "${COM_LIMITE[@]}" "$@" 2> "$TMP/stderr")
    STATUS=$?
    ERRO=$(< "$TMP/stderr")
}

# roda_em DIRETÓRIO COMANDO...
#   Igual a roda, mas executa dentro de DIRETÓRIO (para scripts que criam
#   arquivos no diretório atual). O cd acontece dentro do $(...), que é um
#   subshell, então o diretório do testador não muda.
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

# confere_regex DESCRIÇÃO EXPRESSÃO_REGULAR TEXTO
confere_regex() {
    if [[ "$3" =~ $2 ]]; then
        ok "$1"
    else
        falha "$1" "texto casando com /$2/" "$3"
    fi
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

# tem_comando NOME   (o comando está instalado?)
tem_comando() {
    command -v "$1" > /dev/null
}

# lista_dir DIRETÓRIO   (nomes do diretório, um por linha, em ordem fixa)
# find -printf '%f\n' imprime só o nome de cada entrada (inclusive ocultas),
# e LC_ALL=C deixa a ordem igual em qualquer máquina, independente do idioma.
lista_dir() {
    find "$1" -mindepth 1 -maxdepth 1 -printf '%f\n' | LC_ALL=C sort
}

# ---------------------------------------------------------------------------
# Exercício 1
# ---------------------------------------------------------------------------

testa_ex1() {
    secao "Exercício 1 - banner \$(date | cut -c13-20)"
    local s="$LISTA/ex1_banner_hora.sh"

    roda "$s" argumento_a_mais
    confere_status "recusa argumentos (status 2)" 2
    confere_contem "mostra a mensagem de uso" "Uso:" "$ERRO"

    roda env PATH="$MINIMO" "$s"
    confere_status "sem banner instalado: status 1" 1
    confere_contem "sem banner: diz qual pacote instalar" "sysvbanner" "$ERRO"

    if ! tem_comando banner; then
        pula "demais testes do ex1 (instale o banner: sudo apt install sysvbanner)"
        return
    fi

    roda env PATH="$FALSOS:$PATH" DATA_FALSA="Mon Oct 19 15:49:06 -03 2026" "$s"
    confere_status "com data fixa: status 0" 0
    confere_contem "mostra a régua de colunas" "1234567890123456789012345678901234567890" "$SAIDA"
    confere_contem "mostra a saída do date" "Mon Oct 19 15:49:06 -03 2026" "$SAIDA"
    confere_contem "o recorte 13-20 perde o 1º dígito da hora e pega um espaço" \
        "cut -c13-20 -> '5:49:06 '" "$SAIDA"
    confere_contem "o banner desenha exatamente '5:49:06'" "$(banner 5:49:06)" "$SAIDA"

    roda env PATH="$FALSOS:$PATH" DATA_FALSA="Mon Oct  5 09:03:00 -03 2026" "$s"
    confere_contem "dia com 1 dígito (date completa com espaço): mesmo recorte" \
        "cut -c13-20 -> '9:03:00 '" "$SAIDA"

    roda "$s"
    confere_status "com a data real: status 0" 0
}

# ---------------------------------------------------------------------------
# Exercício 2
# ---------------------------------------------------------------------------

testa_ex2() {
    secao "Exercício 2 - data de hoje e arquivos da conta"
    local s="$LISTA/ex2_data_e_arquivos.sh"
    local casa="$TMP/ex2_casa"

    mkdir -p "$casa"
    touch "$casa/visivel.txt" "$casa/.oculto"

    roda env HOME="$casa" "$s"
    confere_status "com HOME válido: status 0" 0
    confere_igual "1ª linha é a data de hoje em dd/mm/aaaa" \
        "Hoje é $(date '+%d/%m/%Y')" "${SAIDA%%$'\n'*}"
    confere_contem "lista arquivo comum" "visivel.txt" "$SAIDA"
    confere_contem "lista arquivo oculto (ls -a)" ".oculto" "$SAIDA"
    confere_contem "usa o formato longo (ls -l)" "total" "$SAIDA"

    roda "$s" x
    confere_status "recusa argumentos (status 2)" 2

    roda env HOME="$TMP/nao_existe" "$s"
    confere_status "HOME inexistente: status 1" 1
    confere_contem "HOME inexistente: explica o erro" "não existe" "$ERRO"

    roda env HOME= "$s"
    confere_status "HOME vazio: status 1" 1
    confere_contem "HOME vazio: explica o erro" "HOME" "$ERRO"

    if [ "$SOU_ROOT" -eq 1 ]; then
        pula "HOME sem permissão (rodando como root)"
    else
        mkdir -p "$TMP/ex2_fechado"
        chmod 000 "$TMP/ex2_fechado"
        roda env HOME="$TMP/ex2_fechado" "$s"
        confere_status "HOME sem permissão: status 1" 1
        chmod 755 "$TMP/ex2_fechado"
    fi
}

# ---------------------------------------------------------------------------
# Exercício 3
# ---------------------------------------------------------------------------

testa_ex3() {
    secao "Exercício 3 - arquivo existe?"
    local s="$LISTA/ex3_arquivo_existe.sh"

    mkdir -p "$TMP/ex3"
    touch "$TMP/ex3/com espaço.txt"

    roda "$s" "$MODELOS/texto.txt"
    confere_status "arquivo existente: status 0" 0
    confere_contem "arquivo existente: diz que existe" "existe." "$SAIDA"

    roda "$s" "$MODELOS/musicas_modelo"
    confere_status "diretório também existe: status 0" 0

    roda "$s" "$TMP/ex3/com espaço.txt"
    confere_status "nome com espaço: status 0 (aspas em \"\$1\")" 0

    roda "$s" "$MODELOS/nao_existe.txt"
    confere_status "arquivo inexistente: status 1" 1
    confere_contem "arquivo inexistente: diz que não existe" "não existe" "$SAIDA"

    roda "$s" "$MODELOS/link_quebrado"
    confere_status "link quebrado: status 1" 1
    confere_contem "link quebrado: identificado como link" "link simbólico quebrado" "$SAIDA"

    roda "$s"
    confere_status "sem argumento: status 2" 2
    roda "$s" a b
    confere_status "dois argumentos: status 2" 2
    roda "$s" ""
    confere_status "nome vazio: status 2" 2
    confere_contem "nome vazio: explica o erro" "vazio" "$ERRO"
}

# ---------------------------------------------------------------------------
# Exercício 4
# ---------------------------------------------------------------------------

testa_ex4() {
    secao "Exercício 4 - maior que 100 bytes?"
    local s="$LISTA/ex4_maior_que_100.sh"
    local d="$TMP/ex4"

    mkdir -p "$d"
    : > "$d/vazio.txt"
    ln -s "$MODELOS/tamanho_101.txt" "$d/link_101"
    ln -s "$d/nao_existe" "$d/link_quebrado"

    roda "$s" "$MODELOS/tamanho_100.txt"
    confere_status "100 bytes: status 0" 0
    confere_contem "100 bytes: NÃO é maior (limite estrito)" "tem 100 bytes: não é maior que 100" "$SAIDA"

    roda "$s" "$MODELOS/tamanho_101.txt"
    confere_contem "101 bytes: é maior" "tem 101 bytes: é maior que 100" "$SAIDA"

    roda "$s" "$d/vazio.txt"
    confere_contem "arquivo vazio: 0 bytes, não é maior" "tem 0 bytes: não é maior" "$SAIDA"

    roda "$s" "$d/link_101"
    confere_contem "link: mede o arquivo apontado (stat -L), não o link" "tem 101 bytes" "$SAIDA"

    roda_em "$d" "$s" "$MODELOS/tamanho_101.txt"
    confere "não cria um arquivo chamado '100' (não usa > no teste)" [ ! -e "$d/100" ]

    roda "$s" "$d/nao_existe.txt"
    confere_status "inexistente: status 1" 1
    confere_contem "inexistente: explica o erro" "não existe" "$ERRO"

    roda "$s" "$d/link_quebrado"
    confere_status "link quebrado: status 1" 1
    confere_contem "link quebrado: identificado como link" "link simbólico quebrado" "$ERRO"

    roda "$s" "$d"
    confere_status "diretório: status 1" 1
    confere_contem "diretório: explica o erro" "diretório" "$ERRO"

    roda "$s"
    confere_status "sem argumento: status 2" 2
    roda "$s" ""
    confere_status "nome vazio: status 2" 2
}

# ---------------------------------------------------------------------------
# Exercício 5
# ---------------------------------------------------------------------------

testa_ex5() {
    secao "Exercício 5 - contar processos"
    local s="$LISTA/ex5_contar_processos.sh"
    local linha1 linha2 total sem referencia diferenca

    roda "$s"
    confere_status "status 0" 0

    linha1=$(sed -n 1p <<< "$SAIDA")
    linha2=$(sed -n 2p <<< "$SAIDA")
    confere_regex "1ª linha: total contando o script" \
        '^Processos em execução, contando este script: [0-9]+$' "$linha1"
    confere_regex "2ª linha: total sem o script" \
        '^Processos em execução, sem contar este script: [0-9]+$' "$linha2"

    total=${linha1##*: }
    sem=${linha2##*: }
    confere "\"sem o script\" é exatamente o total - 1" [ "$sem" -eq $((total - 1)) ]
    confere "conta pelo menos 1 processo (o próprio script)" [ "$total" -ge 1 ]

    # A quantidade de processos muda o tempo todo, então a comparação com
    # uma contagem feita aqui aceita uma pequena diferença.
    referencia=$(find /proc -mindepth 1 -maxdepth 1 -name '[0-9]*' | wc -l)
    diferenca=$((total - referencia))
    diferenca=${diferenca#-}
    confere "total próximo da contagem de /proc feita pelo testador (±20)" [ "$diferenca" -le 20 ]

    roda "$s" x
    confere_status "recusa argumentos (status 2)" 2
}

# ---------------------------------------------------------------------------
# Exercício 6
# ---------------------------------------------------------------------------

testa_ex6() {
    secao "Exercício 6 - calendário"
    local s="$LISTA/ex6_calendario.sh"
    local mes ano

    roda "$s" 10 2026
    confere_status "recusa argumentos (mês e ano são perguntados): status 2" 2

    roda_com_entrada '10\n2026\n' env PATH="$MINIMO" "$s"
    confere_status "sem cal instalado: status 1" 1
    confere_contem "sem cal: diz qual pacote instalar" "ncal" "$ERRO"

    if ! tem_comando cal; then
        pula "demais testes do ex6 (instale o cal: sudo apt install ncal)"
        return
    fi

    roda_com_entrada '10\n2026\n' "$s"
    confere_status "10/2026: status 0" 0
    confere_igual "10/2026: saída idêntica a 'cal 10 2026'" "$(cal 10 2026)" "$SAIDA"

    roda_com_entrada '09\n2026\n' "$s"
    confere_igual "mês com zero à esquerda (09) aceito" "$(cal 9 2026)" "$SAIDA"

    roda_com_entrada '2\n2024\n' "$s"
    confere_contem "fevereiro de ano bissexto tem dia 29" "29" "$SAIDA"

    roda_com_entrada '  10  \n  2026  \n' "$s"
    confere_status "espaços em volta são ignorados pelo read: status 0" 0

    roda_com_entrada '10\n2026' "$s"
    confere_status "última linha sem \\n ainda é aceita: status 0" 0

    for mes in 13 0 00 abc '' 1.5 -1; do
        roda_com_entrada "$mes\n2026\n" "$s"
        confere_status "mês inválido '$mes': status 1" 1
    done
    confere_contem "mês inválido: explica o erro" "mês inválido" "$ERRO"

    for ano in abc 0 0000 10000 20a6 99999999999999999999; do
        roda_com_entrada "10\n$ano\n" "$s"
        confere_status "ano inválido '$ano': status 1" 1
    done

    roda_com_entrada '10\n\n' "$s"
    confere_status "ano em branco: status 1" 1

    roda_com_entrada '' "$s"
    confere_status "entrada vazia (EOF antes do mês): status 1" 1
    confere_contem "EOF: explica o erro" "entrada terminou" "$ERRO"

    roda_com_entrada '10\n' "$s"
    confere_status "EOF antes do ano: status 1" 1
    confere_contem "EOF antes do ano: diz que faltou o ano" "ano" "$ERRO"
}

# ---------------------------------------------------------------------------
# Exercício 7
# ---------------------------------------------------------------------------

testa_ex7() {
    secao "Exercício 7 - renomear .mpeg3 para .mp3"
    local s="$LISTA/ex7_renomear_mpeg3.sh"
    local d="$TMP/ex7"
    local esperado

    cp -r "$MODELOS/musicas_modelo" "$d"
    esperado=$(printf '%s\n' faixa01.mp3 faixa02.mp3 ja_existe.mp3 ja_existe.mpeg3 \
        letra.txt "minha musica.mp3" notas.mpeg3.txt)

    roda "$s" "$d"
    confere_status "cópia do modelo: status 0" 0
    confere_contem "resumo: 3 renomeados, 1 pulado" "3 arquivo(s) renomeado(s), 1 pulado(s)." "$SAIDA"
    confere_igual "arquivos resultantes (com espaço no nome, sem mexer em .mpeg3.txt)" \
        "$esperado" "$(lista_dir "$d")"
    confere_contem "avisa no stderr o arquivo pulado" "ja_existe.mpeg3" "$ERRO"
    confere_igual "NÃO sobrescreveu o ja_existe.mp3 que já existia" \
        "conteudo de teste: ja_existe.mp3" "$(cat "$d/ja_existe.mp3")"
    confere_igual "conteúdo preservado ao renomear" \
        "conteudo de teste: faixa01.mpeg3" "$(cat "$d/faixa01.mp3")"
    confere "o modelo em testes/ continua intacto" [ -f "$MODELOS/musicas_modelo/faixa01.mpeg3" ]

    roda "$s" "$d"
    confere_contem "rodar de novo: nada a renomear" "0 arquivo(s) renomeado(s), 1 pulado(s)." "$SAIDA"

    cp -r "$MODELOS/musicas_modelo" "$TMP/ex7_barra"
    roda "$s" "$TMP/ex7_barra/"
    confere_contem "diretório com barra final: funciona" "3 arquivo(s) renomeado(s)" "$SAIDA"
    confere_nao_contem "diretório com barra final: mensagens sem '//'" "//" "$SAIDA"

    mkdir -p "$TMP/pasta com espaço"
    touch "$TMP/pasta com espaço/a.mpeg3"
    roda "$s" "$TMP/pasta com espaço"
    confere "diretório com espaço no nome: renomeado" [ -f "$TMP/pasta com espaço/a.mp3" ]

    mkdir -p "$TMP/ex7_especiais/pasta.mpeg3"
    touch "$TMP/ex7_especiais/-traco.mpeg3"
    roda "$s" "$TMP/ex7_especiais"
    confere "nome começando com '-' renomeado (mv --)" [ -f "$TMP/ex7_especiais/-traco.mp3" ]
    confere "diretório chamado pasta.mpeg3 NÃO é renomeado" [ -d "$TMP/ex7_especiais/pasta.mpeg3" ]

    mkdir -p "$TMP/ex7_vazio"
    roda "$s" "$TMP/ex7_vazio"
    confere_status "diretório vazio: status 0" 0
    confere_contem "diretório vazio: 0 renomeados" "0 arquivo(s) renomeado(s), 0 pulado(s)." "$SAIDA"

    roda "$s"
    confere_status "sem argumento: status 2" 2
    roda "$s" a b
    confere_status "dois argumentos: status 2" 2
    roda "$s" ""
    confere_status "nome vazio: status 2" 2
    roda "$s" "$TMP/nao_existe"
    confere_status "diretório inexistente: status 1" 1
    roda "$s" "$MODELOS/texto.txt"
    confere_status "arquivo no lugar de diretório: status 1" 1
    confere_contem "arquivo no lugar de diretório: explica o erro" "não é um diretório" "$ERRO"

    if [ "$SOU_ROOT" -eq 1 ]; then
        pula "diretório sem permissão de escrita (rodando como root)"
    else
        cp -r "$MODELOS/musicas_modelo" "$TMP/ex7_somente_leitura"
        chmod 555 "$TMP/ex7_somente_leitura"
        roda "$s" "$TMP/ex7_somente_leitura"
        confere_status "diretório sem permissão de escrita: status 1" 1
        confere "diretório sem permissão: nada foi renomeado" \
            [ -f "$TMP/ex7_somente_leitura/faixa01.mpeg3" ]
        chmod 755 "$TMP/ex7_somente_leitura"
    fi
}

# ---------------------------------------------------------------------------
# Exercício 8
# ---------------------------------------------------------------------------

testa_ex8() {
    secao "Exercício 8 - renomear de forma interativa"
    local s="$LISTA/ex8_renomear_interativo.sh"
    local d="$TMP/ex8"

    cp -r "$MODELOS/musicas_modelo" "$d"
    roda_com_entrada "$d\nmpeg3\nogg\n" "$s"
    confere_status "mpeg3 -> ogg: status 0" 0
    confere_contem "mpeg3 -> ogg: 4 renomeados (nenhum .ogg colide)" \
        "4 arquivo(s) renomeado(s), 0 pulado(s)." "$SAIDA"
    confere "minha musica.ogg existe" [ -f "$d/minha musica.ogg" ]
    confere "ja_existe.mp3 não foi tocado" [ -f "$d/ja_existe.mp3" ]
    confere "notas.mpeg3.txt não foi tocado" [ -f "$d/notas.mpeg3.txt" ]

    cp -r "$MODELOS/musicas_modelo" "$TMP/ex8_ponto"
    roda_com_entrada "$TMP/ex8_ponto\n.mpeg3\n.mp3\n" "$s"
    confere_contem "extensões digitadas com ponto (.mpeg3 -> .mp3)" \
        "3 arquivo(s) renomeado(s), 1 pulado(s)." "$SAIDA"

    mkdir -p "$TMP/ex8_casa/musicas"
    touch "$TMP/ex8_casa/musicas/a.txt"
    # O ~ entre apóstrofos é proposital: simula o usuário DIGITANDO o til.
    # shellcheck disable=SC2088
    roda_com_entrada '~/musicas\ntxt\nmd\n' env HOME="$TMP/ex8_casa" "$s"
    confere "~ digitado é expandido para o \$HOME" [ -f "$TMP/ex8_casa/musicas/a.md" ]

    cp -r "$MODELOS/musicas_modelo" "$TMP/ex8_glob"
    roda_com_entrada "$TMP/ex8_glob\n*\nzz\n" "$s"
    confere_contem "extensão '*' é literal: nada renomeado" "0 arquivo(s) renomeado(s)" "$SAIDA"
    confere_igual "extensão '*': diretório igual ao modelo" \
        "$(lista_dir "$MODELOS/musicas_modelo")" "$(lista_dir "$TMP/ex8_glob")"

    roda_com_entrada "$d\nogg\nogg\n" "$s"
    confere_status "extensões iguais: status 0" 0
    confere_contem "extensões iguais: avisa que não há o que fazer" "iguais" "$SAIDA"

    roda_com_entrada "$d\n\nmp3\n" "$s"
    confere_status "extensão atual vazia: status 1" 1
    roda_com_entrada "$d\nogg\n.\n" "$s"
    confere_status "nova extensão só com ponto (vazia): status 1" 1
    roda_com_entrada "$d\nogg\na/b\n" "$s"
    confere_status "extensão com '/': status 1" 1
    roda_com_entrada "$TMP/nao_existe\nmpeg3\nmp3\n" "$s"
    confere_status "diretório inexistente: status 1" 1
    roda_com_entrada "\nmpeg3\nmp3\n" "$s"
    confere_status "diretório em branco: status 1" 1
    roda_com_entrada "$MODELOS/texto.txt\nmpeg3\nmp3\n" "$s"
    confere_status "arquivo no lugar de diretório: status 1" 1

    roda_com_entrada '' "$s"
    confere_status "entrada vazia (EOF): status 1" 1
    confere_contem "EOF: explica o erro" "entrada terminou" "$ERRO"
    roda_com_entrada "$d\nmpeg3\n" "$s"
    confere_status "EOF antes da nova extensão: status 1" 1

    roda "$s" x
    confere_status "recusa argumentos: status 2" 2
}

# ---------------------------------------------------------------------------
# Exercício 9
# ---------------------------------------------------------------------------

testa_ex9() {
    secao "Exercício 9 - linhas e palavras"
    local s="$LISTA/ex9_linhas_palavras.sh"
    local d="$TMP/ex9"

    mkdir -p "$d"
    : > "$d/vazio.txt"
    printf '\n' > "$d/so_quebra.txt"
    printf 'abc' > "$d/sem_quebra.txt"
    printf 'a\n\nb\n' > "$d/linha_em_branco.txt"
    printf '  um \t dois   tres  \n' > "$d/espacos.txt"

    roda "$s" "$MODELOS/texto.txt"
    confere_status "texto.txt: status 0" 0
    confere_igual "texto.txt: 5 linhas e 24 palavras" $'Linhas: 5\nPalavras: 24' "$SAIDA"

    roda "$s" "$MODELOS/sem_quebra_final.txt"
    confere_igual "sem \\n no final: 3 linhas (não 2) e 10 palavras" $'Linhas: 3\nPalavras: 10' "$SAIDA"
    confere_igual "(pegadinha confirmada: wc -l sozinho diz 2)" "2" "$(wc -l < "$MODELOS/sem_quebra_final.txt")"

    roda "$s" "$d/vazio.txt"
    confere_igual "arquivo vazio: 0 e 0" $'Linhas: 0\nPalavras: 0' "$SAIDA"
    roda "$s" "$d/so_quebra.txt"
    confere_igual "só uma quebra de linha: 1 linha, 0 palavras" $'Linhas: 1\nPalavras: 0' "$SAIDA"
    roda "$s" "$d/sem_quebra.txt"
    confere_igual "'abc' sem \\n: 1 linha, 1 palavra" $'Linhas: 1\nPalavras: 1' "$SAIDA"
    roda "$s" "$d/linha_em_branco.txt"
    confere_igual "linha em branco conta como linha" $'Linhas: 3\nPalavras: 2' "$SAIDA"
    roda "$s" "$d/espacos.txt"
    confere_igual "vários espaços e TAB não criam palavras" $'Linhas: 1\nPalavras: 3' "$SAIDA"

    roda "$s" "$d"
    confere_status "diretório: status 1" 1
    roda "$s" "$d/nao_existe.txt"
    confere_status "inexistente: status 1" 1
    roda "$s"
    confere_status "sem argumento: status 2" 2
    roda "$s" a b
    confere_status "dois argumentos: status 2" 2
    roda "$s" ""
    confere_status "nome vazio: status 2" 2

    if [ "$SOU_ROOT" -eq 1 ]; then
        pula "arquivo sem permissão de leitura (rodando como root)"
    else
        printf 'segredo\n' > "$d/fechado.txt"
        chmod 000 "$d/fechado.txt"
        roda "$s" "$d/fechado.txt"
        confere_status "arquivo sem permissão de leitura: status 1" 1
        confere_contem "sem leitura: explica o erro" "permissão de leitura" "$ERRO"
    fi
}

# ---------------------------------------------------------------------------
# Exercício 10
# ---------------------------------------------------------------------------

testa_ex10() {
    secao "Exercício 10 - listar argumentos"
    local s="$LISTA/ex10_listar_argumentos.sh"
    local esperado

    esperado=$(printf '%s\n' "1: a" "2: b" "3: c" "4: d" "5: e" "6: f" "7: g" "8: h" \
        "9: i" "10: j" "11: k" "12: l com espaço")
    roda "$s" a b c d e f g h i j k "l com espaço"
    confere_status "12 argumentos: status 0" 0
    confere_igual "12 argumentos: 10º é 'j' (não 'a0') e o 12º mantém os espaços" "$esperado" "$SAIDA"

    roda "$s" único
    confere_igual "um argumento" "1: único" "$SAIDA"

    roda "$s" "" x
    confere_igual "argumento vazio é listado" $'1: \n2: x' "$SAIDA"

    roda_em "$MODELOS" "$s" "*"
    confere_igual "'*' sai literal, sem expandir para nomes de arquivos" "1: *" "$SAIDA"

    # '$HOME' entre apóstrofos é proposital: o script deve recebê-lo literal.
    # shellcheck disable=SC2016
    roda "$s" -n '\t' '$HOME'
    confere_igual "-n, \\t e \$HOME saem literais" $'1: -n\n2: \\t\n3: $HOME' "$SAIDA"

    roda "$s"
    confere_status "sem argumentos: status 2" 2
    confere_contem "sem argumentos: mostra o uso" "Uso:" "$ERRO"
}

# ---------------------------------------------------------------------------
# Exercício 11
# ---------------------------------------------------------------------------

testa_ex11() {
    secao "Exercício 11 - usuários em ordem alfabética"
    local s="$LISTA/ex11_usuarios_ordenados.sh"
    local d="$TMP/ex11"

    mkdir -p "$d"

    roda "$s" "$MODELOS/passwd_exemplo"
    confere_status "passwd_exemplo: status 0" 0
    confere_igual "passwd_exemplo: os 10 usuários em ordem" \
        "$(printf '%s\n' ana backup beatriz bin carlos daemon marcos root sync www-data)" "$SAIDA"

    roda "$s"
    confere_status "/etc/passwd real: status 0" 0
    confere_igual "/etc/passwd real: igual a cut -d: -f1 | sort" \
        "$(cut -d: -f1 /etc/passwd | sort)" "$SAIDA"

    printf 'zeca:x:1:1::/h:/bin/sh\nlinha quebrada\nana:x:2:2::/h:/bin/bash\n' > "$d/com_lixo"
    roda "$s" "$d/com_lixo"
    confere_status "linha mal formada: status 0 (as válidas são listadas)" 0
    confere_igual "linha mal formada: ignorada na saída" $'ana\nzeca' "$SAIDA"
    confere_contem "linha mal formada: aviso no stderr" "1 linha(s)" "$ERRO"

    printf 'isto nao e um passwd\n' > "$d/lixo"
    roda "$s" "$d/lixo"
    confere_status "nenhuma linha válida: status 1" 1

    : > "$d/vazio"
    roda "$s" "$d/vazio"
    confere_status "arquivo vazio: status 1" 1
    confere_contem "arquivo vazio: explica o erro" "vazio" "$ERRO"

    roda "$s" "$d/nao_existe"
    confere_status "inexistente: status 1" 1
    roda "$s" "$d"
    confere_status "diretório: status 1" 1
    roda "$s" a b
    confere_status "dois argumentos: status 2" 2
    roda "$s" ""
    confere_status "nome vazio: status 2 (não cai no /etc/passwd)" 2
}

# ---------------------------------------------------------------------------
# Exercício 12
# ---------------------------------------------------------------------------

testa_ex12() {
    secao "Exercício 12 - shells únicos"
    local s="$LISTA/ex12_shells_unicos.sh"
    local d="$TMP/ex12"

    mkdir -p "$d"

    roda "$s" "$MODELOS/passwd_exemplo"
    confere_status "passwd_exemplo: status 0" 0
    confere_igual "passwd_exemplo: os 5 shells, sem repetição" \
        "$(printf '%s\n' /bin/bash /bin/sh /bin/sync /bin/zsh /usr/sbin/nologin)" "$SAIDA"
    # sort antes do uniq -d: a própria conferência cairia na pegadinha do
    # exercício se procurasse repetições sem ordenar antes.
    confere_igual "nenhuma linha repetida (sort | uniq -d vazio)" "" "$(sort <<< "$SAIDA" | uniq -d)"
    confere_igual "(pegadinha confirmada: uniq sem sort não remove nada, 10 linhas)" \
        "10" "$(cut -d: -f7 "$MODELOS/passwd_exemplo" | uniq | wc -l)"

    roda "$s"
    confere_igual "/etc/passwd real: igual a cut -d: -f7 | sort -u" \
        "$(cut -d: -f7 /etc/passwd | sed 's|^$|/bin/sh|' | sort -u)" "$SAIDA"

    printf 'a:x:1:1::/h:\nb:x:2:2::/h:/bin/bash\n' > "$d/shell_vazio"
    roda "$s" "$d/shell_vazio"
    confere_igual "shell vazio vira /bin/sh (sem linha em branco)" $'/bin/bash\n/bin/sh' "$SAIDA"

    printf 'a:x:1:1::/h:/bin/sh\nquebrada\n' > "$d/com_lixo"
    roda "$s" "$d/com_lixo"
    confere_igual "linha mal formada: ignorada" "/bin/sh" "$SAIDA"
    confere_contem "linha mal formada: aviso no stderr" "1 linha(s)" "$ERRO"

    : > "$d/vazio"
    roda "$s" "$d/vazio"
    confere_status "arquivo vazio: status 1" 1
    roda "$s" "$d/nao_existe"
    confere_status "inexistente: status 1" 1
    roda "$s" a b
    confere_status "dois argumentos: status 2" 2
    roda "$s" ""
    confere_status "nome vazio: status 2" 2
}

# ---------------------------------------------------------------------------
# Exercício 13
# ---------------------------------------------------------------------------

testa_ex13() {
    secao "Exercício 13 - criar dir1..dir5 com file1..file3"
    local s="$LISTA/ex13_criar_diretorios.sh"
    local d="$TMP/ex13"
    local esperado n m

    esperado=$(for n in 1 2 3 4 5; do
        echo "dir$n"
        for m in 1 2 3; do echo "dir$n/file$m"; done
    done | LC_ALL=C sort)

    roda "$s" "$d"
    confere_status "base nova: status 0" 0
    confere_igual "exatamente dir1..dir5, cada um com file1..file3" \
        "$esperado" "$(cd "$d" && find . -mindepth 1 | sed 's|^\./||' | LC_ALL=C sort)"
    confere_igual "5 diretórios" "5" "$(find "$d" -mindepth 1 -type d | wc -l)"
    confere_igual "15 arquivos" "15" "$(find "$d" -type f | wc -l)"
    confere_igual "arquivos vazios (touch)" "0" "$(find "$d" -type f -size +0 | wc -l)"

    roda "$s" "$d"
    confere_status "rodar de novo (idempotente): status 0" 0
    confere_igual "rodar de novo: continua com 15 arquivos" "15" "$(find "$d" -type f | wc -l)"

    roda "$s" "$TMP/ex13_a/b/c"
    confere "base com diretórios intermediários inexistentes: criada" [ -f "$TMP/ex13_a/b/c/dir5/file3" ]

    roda "$s" "$TMP/ex13 com espaço"
    confere "base com espaço no nome" [ -f "$TMP/ex13 com espaço/dir1/file1" ]

    mkdir -p "$TMP/ex13_cwd"
    roda_em "$TMP/ex13_cwd" "$s"
    confere "sem argumento: cria no diretório atual" [ -f "$TMP/ex13_cwd/dir3/file2" ]

    touch "$TMP/ex13_arquivo"
    roda "$s" "$TMP/ex13_arquivo"
    confere_status "base é um arquivo: status 1" 1

    mkdir -p "$TMP/ex13_conflito"
    touch "$TMP/ex13_conflito/dir1"
    roda "$s" "$TMP/ex13_conflito"
    confere_status "dir1 já existe como arquivo: status 1" 1

    mkdir -p "$TMP/ex13_conflito2/dir1/file1"
    roda "$s" "$TMP/ex13_conflito2"
    confere_status "file1 já existe como diretório: status 1" 1

    roda "$s" a b
    confere_status "dois argumentos: status 2" 2
    roda "$s" ""
    confere_status "nome vazio: status 2" 2

    if [ "$SOU_ROOT" -eq 1 ]; then
        pula "base sem permissão de escrita (rodando como root)"
    else
        mkdir -p "$TMP/ex13_fechado"
        chmod 555 "$TMP/ex13_fechado"
        roda "$s" "$TMP/ex13_fechado"
        confere_status "base sem permissão de escrita: status 1" 1
        chmod 755 "$TMP/ex13_fechado"
    fi
}

# ---------------------------------------------------------------------------
# Exercício 14
# ---------------------------------------------------------------------------

testa_ex14() {
    secao "Exercício 14 - repositório de ideias"
    local s="$LISTA/ex14_repositorio_ideias.sh"
    local f="$TMP/ex14_ideias.txt"

    roda env IDEIAS="$f" PATH="$FALSOS:$PATH" DATA_FALSA="30/08/2008 10:21" \
        "$s" Fazer script para remover usuários
    confere_status "1ª ideia: status 0" 0
    confere_igual "grava exatamente o exemplo do enunciado" \
        "30/08/2008 10:21 Fazer script para remover usuários" "$(cat "$f")"

    roda env IDEIAS="$f" PATH="$FALSOS:$PATH" DATA_FALSA="31/08/2008 09:00" \
        "$s" "Estudar o comando trap"
    confere_igual "2ª ideia (entre aspas): acrescentada no final (>>)" "2" "$(wc -l < "$f")"
    confere_igual "a 1ª ideia continua lá" \
        "30/08/2008 10:21 Fazer script para remover usuários" "$(head -n 1 "$f")"
    confere_contem "mostra a linha registrada" "31/08/2008 09:00 Estudar o comando trap" "$SAIDA"

    roda env IDEIAS="$f" "$s" Com a data real
    confere_regex "com o date real: formato dd/mm/aaaa hh:mm" \
        '^[0-9]{2}/[0-9]{2}/[0-9]{4} [0-9]{2}:[0-9]{2} Com a data real$' "$(tail -n 1 "$f")"

    roda env IDEIAS="$f" "$s" $'linha1\nlinha2'
    confere_igual "ideia com quebra de linha vira uma linha só" "4" "$(wc -l < "$f")"
    confere_contem "quebra de linha vira espaço" "linha1 linha2" "$(tail -n 1 "$f")"

    roda env IDEIAS="$f" "$s"
    confere_status "sem ideia: status 2" 2
    roda env IDEIAS="$f" "$s" "   "
    confere_status "ideia só com espaços: status 2" 2
    confere_igual "ideias inválidas não gravam nada" "4" "$(wc -l < "$f")"

    mkdir -p "$TMP/ex14_dir"
    roda env IDEIAS="$TMP/ex14_dir" "$s" teste
    confere_status "IDEIAS aponta para um diretório: status 1" 1

    roda env IDEIAS="$TMP/nao_existe/ideias.txt" "$s" teste
    confere_status "diretório do arquivo não existe: status 1" 1

    if [ "$SOU_ROOT" -eq 1 ]; then
        pula "arquivo sem permissão de escrita (rodando como root)"
    else
        mkdir -p "$TMP/ex14_fechado"
        chmod 555 "$TMP/ex14_fechado"
        roda env IDEIAS="$TMP/ex14_fechado/ideias.txt" "$s" teste
        confere_status "sem permissão de escrita: status 1" 1
        confere_contem "sem permissão: mostra o erro do sistema" "Permission denied" "$ERRO"
        confere_contem "sem permissão: mostra como liberar" "Para liberar" "$ERRO"
        chmod 755 "$TMP/ex14_fechado"
    fi

    # O padrão /ideias.txt só é testado se o usuário NÃO puder escrever lá,
    # para o teste nunca gravar lixo no repositório de ideias de verdade.
    if [ "$SOU_ROOT" -eq 0 ] && [ ! -w / ] && { [ ! -e /ideias.txt ] || [ ! -w /ideias.txt ]; }; then
        roda env -u IDEIAS "$s" teste
        confere_status "padrão /ideias.txt sem permissão: status 1" 1
        confere_contem "padrão: o arquivo é /ideias.txt" "/ideias.txt" "$ERRO"
    else
        pula "padrão /ideias.txt (o arquivo já foi liberado para escrita)"
    fi
}

# ---------------------------------------------------------------------------
# Exercício 15
# ---------------------------------------------------------------------------

testa_ex15() {
    secao "Exercício 15 - espaço por diretório"
    local s="$LISTA/ex15_espaco_diretorios.sh"
    local base="$MODELOS/conta_exemplo"
    local esperado

    esperado=$(printf '%s\n' "$base/vazio" "$base/pequeno" "$base/medio" "$base/.oculto" "$base/grande")

    roda "$s" "$base"
    confere_status "conta_exemplo: status 0" 0
    confere_igual "cabeçalho" $'KB\tDiretório' "${SAIDA%%$'\n'*}"
    confere_igual "ordem do menor para o maior, incluindo o .oculto" \
        "$esperado" "$(sed 1d <<< "$SAIDA" | cut -f2)"
    confere "tamanhos em ordem numérica (sort -n -c)" \
        sort -n -c <<< "$(sed 1d <<< "$SAIDA" | cut -f1)"
    confere_igual "(pegadinha confirmada: du -sk dir/* não vê o .oculto)" "4" \
        "$(du -sk "$base"/* | wc -l)"

    mkdir -p "$TMP/ex15/com espaço" "$TMP/ex15/real"
    head -c 8192 /dev/zero > "$TMP/ex15/real/dados"
    ln -s "$TMP/ex15/real" "$TMP/ex15/link_para_real"
    roda "$s" "$TMP/ex15"
    confere_contem "subdiretório com espaço no nome" "$TMP/ex15/com espaço" "$SAIDA"
    confere_nao_contem "link para diretório não é contado de novo" "link_para_real" "$SAIDA"

    mkdir -p "$TMP/ex15_vazia"
    touch "$TMP/ex15_vazia/so_arquivo.txt"
    roda "$s" "$TMP/ex15_vazia"
    confere_status "sem subdiretórios: status 0" 0
    confere_contem "sem subdiretórios: avisa" "nenhum subdiretório" "$SAIDA"

    roda env HOME="$TMP/ex15" "$s"
    confere_contem "sem argumento: usa o \$HOME" "$TMP/ex15/real" "$SAIDA"

    roda "$s" "$MODELOS/texto.txt"
    confere_status "arquivo no lugar de diretório: status 1" 1
    roda "$s" "$TMP/nao_existe"
    confere_status "inexistente: status 1" 1
    roda "$s" a b
    confere_status "dois argumentos: status 2" 2
    roda "$s" ""
    confere_status "nome vazio: status 2" 2

    if [ "$SOU_ROOT" -eq 1 ]; then
        pula "diretório sem permissão de leitura (rodando como root)"
    else
        mkdir -p "$TMP/ex15_fechado"
        chmod 000 "$TMP/ex15_fechado"
        roda "$s" "$TMP/ex15_fechado"
        confere_status "diretório sem permissão de leitura: status 1" 1
        chmod 755 "$TMP/ex15_fechado"
    fi
}

# ---------------------------------------------------------------------------
# Exercício 16
# ---------------------------------------------------------------------------

testa_ex16() {
    secao "Exercício 16 - find com saída e erros separados"
    local s="$LISTA/ex16_buscar_meus_arquivos.sh"
    local b="$TMP/ex16_busca"
    local out="$TMP/ex16_saida"
    local esperado

    mkdir -p "$b/aberto" "$b/fechado" "$out"
    touch "$b/aberto/meu.txt" "$b/fechado/escondido.txt"
    esperado=$(printf '%s\n' "$b" "$b/aberto" "$b/aberto/meu.txt" "$b/fechado" | LC_ALL=C sort)

    if [ "$SOU_ROOT" -eq 1 ]; then
        pula "busca com diretório sem permissão (rodando como root)"
    else
        chmod 000 "$b/fechado"
        echo "lixo de uma execução anterior" > "$out/arq.txt"

        roda_em "$out" "$s" "$b"
        confere_status "busca com um diretório fechado: status 0" 0
        confere "arq.txt criado no diretório atual" [ -f "$out/arq.txt" ]
        confere "erros.txt criado no diretório atual" [ -f "$out/erros.txt" ]
        confere_igual "arq.txt tem exatamente os 4 caminhos acessíveis" \
            "$esperado" "$(LC_ALL=C sort "$out/arq.txt")"
        confere_nao_contem "arq.txt foi sobrescrito (>), não acumulado" "lixo" "$(cat "$out/arq.txt")"
        confere_nao_contem "arq.txt não tem mensagens de erro" "Permission denied" "$(cat "$out/arq.txt")"
        confere_igual "erros.txt tem 1 linha" "1" "$(wc -l < "$out/erros.txt")"
        confere_contem "erros.txt tem o Permission denied do fechado" "Permission denied" "$(cat "$out/erros.txt")"
        confere_contem "resumo na tela: 4 arquivos" "4 (lista em arq.txt)" "$SAIDA"
        confere_contem "resumo na tela: 1 erro" "1 (em erros.txt)" "$SAIDA"
        confere_igual "nada de erro vazou para a tela (stderr vazio)" "" "$ERRO"

        chmod 755 "$b/fechado"
    fi

    roda_em "$out" "$s" "$b/aberto"
    confere_igual "só arquivos do usuário: a pasta 'aberto' e o meu.txt" \
        "$(printf '%s\n' "$b/aberto" "$b/aberto/meu.txt")" "$(LC_ALL=C sort "$out/arq.txt")"
    confere_igual "sem erros: erros.txt vazio" "0" "$(wc -l < "$out/erros.txt")"

    roda_em "$out" "$s" "$TMP/nao_existe"
    confere_status "início inexistente: status 1" 1
    roda_em "$out" "$s" "$MODELOS/texto.txt"
    confere_status "início é um arquivo: status 1" 1
    roda_em "$out" "$s" a b
    confere_status "dois argumentos: status 2" 2
    roda_em "$out" "$s" ""
    confere_status "nome vazio: status 2" 2

    if [ "$SOU_ROOT" -eq 1 ]; then
        pula "diretório atual sem permissão de escrita (rodando como root)"
    else
        mkdir -p "$TMP/ex16_cwd_fechado"
        chmod 555 "$TMP/ex16_cwd_fechado"
        roda_em "$TMP/ex16_cwd_fechado" "$s" "$b/aberto"
        confere_status "diretório atual sem escrita: status 1" 1
        confere_contem "diretório atual sem escrita: explica o erro" "diretório atual" "$ERRO"
        chmod 755 "$TMP/ex16_cwd_fechado"
    fi

    pula "busca completa a partir de / (demora; rode ./ex16_buscar_meus_arquivos.sh à mão)"
}

# ---------------------------------------------------------------------------
# Programa principal
# ---------------------------------------------------------------------------

# Sem argumentos, testa todos; com argumentos, só os exercícios pedidos.
if [ $# -eq 0 ]; then
    set -- {1..16}
fi

for n in "$@"; do
    case "$n" in
        [1-9] | 1[0-6]) "testa_ex$n" ;;
        *)
            echo "Exercício inválido: '$n' (use números de 1 a 16)" >&2
            exit 2
            ;;
    esac
done

printf '\n%sResultado:%s %s%d OK%s, %s%d falharam%s, %s%d pulados%s\n' \
    "$NEGRITO" "$NORMAL" "$VERDE" "$PASSOU" "$NORMAL" \
    "$VERMELHO" "$FALHOU" "$NORMAL" "$AMARELO" "$PULOU" "$NORMAL"

# Status do testador: 0 só se nenhuma conferência falhou.
[ "$FALHOU" -eq 0 ]
