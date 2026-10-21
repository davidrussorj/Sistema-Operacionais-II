#!/bin/bash
#
# Lista 4 - Exercício 1
#
# Enunciado: "Escreva um script Shell para:
#   a) Saber informações a respeito do sistema, tais como: horário, ocupação
#      do disco e os usuários que estão "logados".
#   b) Melhore o script anterior, exibindo mensagens na tela para anunciar
#      cada comando antes de executá-lo.
#   c) Para o script ficar mais completo, introduzir uma interação mínima com
#      o usuário, pedindo uma confirmação antes de executar os comandos.
#   d) Para facilitar manutenções futuras, deixe o código visivelmente mais
#      agradável e coloque comentários que esclareçam as atividades a serem
#      efetuadas."
#
# Este arquivo é a versão final (item d), que já contém os itens a, b e c.
# Cada trecho está marcado com o item a que corresponde, e o README mostra a
# evolução do item a até o d.
#
# Uso:     ./ex1_info_sistema.sh                   (pergunta antes de executar)
#          printf 's\n' | ./ex1_info_sistema.sh    (responde "sim" sem digitar)
#
# Status de saída:
#   0  os três comandos foram executados
#   1  o usuário não confirmou, a entrada terminou sem resposta, falta algum
#      dos comandos ou algum deles falhou
#   2  uso incorreto (foram passados argumentos)
#
# Teoria (Aula 10): read - slide 25 | case com vários padrões - slides 45-47 |
#                   funções e return - slides 53-57 (a função confirma é a
#                   sim_ou_nao do slide 56) | $(comando) e who - slide 60

# Os scripts da lista são escritos para o bash (#!/bin/bash), mas o slide 23
# ensina também a "forma fácil", sh script.sh - e aí quem executa é o
# /bin/sh, que no Ubuntu é o dash, não o bash (slide 6: "verificar com
# ls -l /bin/sh"). O dash não tem alguns recursos do bash ([[ =~ ]], 10#...)
# e o echo dele interpreta \ de outro jeito. A variável BASH_VERSION só
# existe dentro do bash: se ela estiver vazia, o exec (slide 59) troca este
# processo por um bash rodando o mesmo script, com os mesmos argumentos e a
# mesma entrada.
[ -n "$BASH_VERSION" ] || exec bash "$0" "$@"

# ---------------------------------------------------------------------------
# Funções auxiliares (slide 54: precisam ser declaradas antes de usadas)
# ---------------------------------------------------------------------------

# uso: mostra como chamar o script (e, se recebeu, o motivo do erro) no
# stderr e encerra com status 2, o código convencional de "uso incorreto".
uso() {
    if [ $# -gt 0 ]; then
        echo "Erro: $*" >&2
    fi
    echo "Uso: $0   (este script não recebe argumentos)" >&2
    exit 2
}

# erro: mostra a mensagem no stderr (descritor 2, slide 13) e encerra com
# status 1. É o equivalente em shell ao perror() + exit() dos programas em C.
erro() {
    echo "Erro: $*" >&2
    exit 1
}

# confirma PERGUNTA
#   [item c] Faz a pergunta e lê a resposta até receber uma resposta válida.
#   É a função sim_ou_nao do slide 56: devolve 0 (verdadeiro) para "sim" e
#   1 (falso) para "não", então pode ser usada direto num if.
confirma() {
    local resposta

    while true; do
        # read -p mostra a pergunta (só quando a entrada é o teclado; num
        # pipe ela não aparece) e -r não deixa a \ ser interpretada.
        # O read falha quando a entrada acaba (Ctrl+D, ou um pipe que já
        # terminou). Se nada foi lido, não há resposta a esperar: sem este
        # teste o laço perguntaria para sempre. Se a última linha veio sem
        # \n, o read também "falha", mas a resposta foi lida e vale.
        if ! read -r -p "$1 [s/N] " resposta && [ -z "$resposta" ]; then
            echo "Erro: a entrada terminou sem resposta" >&2
            return 1
        fi

        # Os padrões agrupados com | são os do slide 46. A variável está
        # entre aspas (slide 40): se o usuário só aperta Enter, ela fica
        # vazia e o case compara com "", que aqui significa "não" (é o
        # padrão indicado pelo N maiúsculo da pergunta).
        case "$resposta" in
            s | S | sim | Sim | SIM)
                return 0
                ;;
            "" | n | N | não | Não | NÃO | nao | Nao | NAO)
                return 1
                ;;
            *)
                echo "Resposta '$resposta' não reconhecida. Responda s (sim) ou n (não)."
                ;;
        esac
    done
}

# executa DESCRIÇÃO COMANDO [ARGUMENTOS...]
#   [item b] Anuncia o que vai ser executado (a descrição e a linha exata do
#   comando) e só depois executa. Devolve o status do próprio comando, para
#   o programa principal saber se algo falhou.
executa() {
    local descricao="$1" saida status
    shift

    echo
    echo "==> $descricao"
    echo "    \$ $*"

    # "$@" executa o comando com cada argumento exatamente como veio. A
    # saída é capturada com $(...) (slide 60) só para tratar o caso de o
    # comando não imprimir nada - o who, por exemplo, não mostra ninguém
    # quando não há sessões registradas (comum no WSL e em contêineres) -,
    # e assim a seção não fica em branco sem explicação.
    saida=$("$@")
    status=$?

    if [ -n "$saida" ]; then
        echo "$saida"
    else
        echo "(o comando não mostrou nada)"
    fi

    return "$status"
}

# ---------------------------------------------------------------------------
# Validações
# ---------------------------------------------------------------------------

# O exercício não usa argumentos. Se vierem argumentos, provavelmente quem
# chamou se enganou de script, então é melhor avisar do que ignorar.
[ $# -eq 0 ] || uso "argumentos inesperados: $*"

# Os três comandos precisam existir. "command -v" procura no PATH sem
# executar; sem essa checagem, a falta de um deles só apareceria depois da
# confirmação, como "command not found" no meio da saída.
for comando in date df who; do
    command -v "$comando" > /dev/null || erro "comando $comando não encontrado"
done

# ---------------------------------------------------------------------------
# [item c] Confirmação antes de executar
# ---------------------------------------------------------------------------

echo "Informações do sistema"
echo
echo "Este script vai executar:"
echo "    date     horário atual"
echo "    df -h    ocupação do disco"
echo "    who      usuários logados"
echo

if ! confirma "Deseja continuar?"; then
    echo "Operação cancelada: nenhum comando foi executado."
    exit 1
fi

# ---------------------------------------------------------------------------
# [itens a e b] Os comandos, cada um anunciado antes de executar
# ---------------------------------------------------------------------------

# O item a é só a sequência "date; df -h; who". A função executa acrescenta
# o anúncio de cada um (item b). Um comando que falha não interrompe os
# outros: as falhas são contadas e informadas no final.
falhas=0

# date: data e hora atuais (no formato do idioma configurado no sistema).
executa "Horário atual" date || falhas=$((falhas + 1))

# df -h: espaço total, usado e livre de cada sistema de arquivos montado;
# -h ("human-readable") mostra em K, M e G em vez de blocos de 1 KB.
executa "Ocupação do disco" df -h || falhas=$((falhas + 1))

# who: quem está logado, em qual terminal e desde quando.
executa "Usuários logados" who || falhas=$((falhas + 1))

# ---------------------------------------------------------------------------
# Resultado
# ---------------------------------------------------------------------------

echo
[ "$falhas" -eq 0 ] || erro "$falhas comando(s) falharam (ver as mensagens acima)"
echo "Pronto: os 3 comandos foram executados."
exit 0
