# Lista 4 - Shell Script

Exercícios da disciplina Tópicos Especiais em Sistemas Computacionais I / SO 2.

Enunciado: **"Exercício Prático – Shell Script"** (`enunciado.pdf`, nesta
pasta), com 9 exercícios.

Base teórica: **Aula 10 - Programação em Shell** (slides 9-17 e 22-62) e o
material de apoio **"Uso de variáveis e vetores em Shell Script"**, ambos do
Classroom da turma.

Cada script é comentado bloco a bloco: o cabeçalho traz o enunciado, o uso,
os códigos de saída e os slides correspondentes, e cada etapa explica o que
faz e por quê. Todos validam a entrada antes de agir (ver "Convenções dos
scripts"), e a pasta `testes/` tem uma bateria de testes automáticos que
roda os 9 exercícios contra entradas conhecidas (`make test`).

## Base teórica (Aula 10)

### Script, `#!` e permissão de execução (slides 22-23)

O slide 22 mostra a anatomia de um script: um arquivo texto cuja primeira
linha é o "comentário especial" `#!`, que indica qual programa deve executar
o arquivo, e que termina com `exit 0` ("código de retorno, 0 indica
sucesso"). O slide 23 mostra as duas formas de rodar:

```sh
$ /bin/sh primeiro.sh        # forma fácil: invocar a shell com o nome do arquivo
$ chmod +x primeiro.sh       # forma mais elegante: dar permissão de execução...
$ ./primeiro.sh              # ...e invocar direto
```

e avisa que `primeiro.sh` sozinho "pode não funcionar", porque o diretório
atual normalmente não está no `PATH` — por isso todos os comandos deste
README usam `./`. Os scripts desta lista usam `#!/bin/bash` em vez de
`#!/bin/sh`: o slide 6 lembra que o bash é compatível com POSIX, e alguns
exercícios usam recursos dele (`read -p` no ex1 e ex2, `[[ =~ ]]` e `10#`
no ex3 e ex4). O `make` faz o `chmod +x` em todos.

A "forma fácil" do slide 23 tem uma armadilha: `sh script.sh` executa o
script com o `/bin/sh`, e no Ubuntu o `/bin/sh` é o **dash**, não o bash —
é o que o slide 6 manda conferir com `ls -l /bin/sh`
(`/bin/sh -> dash`). O dash ignora o `#!/bin/bash` (quem lê essa linha é o
sistema, só quando o script é executado direto) e não tem `[[ =~ ]]` nem
`10#`: sem tratamento, `sh ex3_relacao.sh 3 5` respondia
`[[: not found` e `'3' não é um número inteiro`. Por isso todos os scripts
começam com

```sh
[ -n "$BASH_VERSION" ] || exec bash "$0" "$@"
```

A variável `BASH_VERSION` só existe dentro do bash; se ela estiver vazia, o
`exec` (slide 59) troca o processo atual por um bash rodando o mesmo
script, com os mesmos argumentos e a mesma entrada. Assim `./script`,
`bash script` e `sh script` dão exatamente o mesmo resultado.

### Redirecionamento e pipe (slides 9-16)

Todo processo nasce com três descritores abertos: `stdin` (0), `stdout` (1)
e `stderr` (2) — o mesmo modelo de *file descriptor* da Aula 06, visto na
Lista 1. Os slides mostram cada operador:

```sh
$ ls -l > lssaida.txt                          # slide 10: > sobrescreve ("CUIDADO!!!")
$ ls >> lista.txt                              # slide 12: >> anexa ao final
$ cat rel.txt > novorel.txt 2> erros.log       # slide 14: 2> manda os erros para outro arquivo
$ cat rel.txt > novorel.txt 2> /dev/null       # slide 14: /dev/null, o "balde sem fundo"
$ ps | sort | more                             # slide 16: pipe, a saída de um é a entrada do outro
```

Os ex6, ex7 e ex8 são pipes (`... | tr`, `grep | cut | sed | tr`,
`grep | cut | sed | sort | uniq`). Todos os scripts mandam as mensagens de
erro para o `stderr` com `>&2`, e os ex3 e ex4 usam `2> /dev/null` para
esconder o erro do `[` ao testar se um número cabe em 64 bits.

### Expansão de wildcards (slide 17)

`*` (qualquer sequência), `?` (um caractere), `[set]` (um caractere do
conjunto) — e o ponto principal do slide: **"A Shell expande wildcards"**.
O ex5 usa o `*` dentro de um `case` para saber se uma palavra contém a
outra (`*"$1"*`), e a pegadinha é justamente impedir que um `*` ou `?`
**digitado pelo usuário** também seja tratado como wildcard.

### Variáveis, aspas e parâmetros (slides 24-31)

Variáveis são criadas na primeira atribuição e lidas com `$` (slide 24),
`read` lê uma variável do teclado (slide 25), e os slides 27-30 listam as
variáveis especiais:

```
$HOME  diretório pessoal do usuário        $#  número de parâmetros passados
$1, $2 parâmetros dados ao script           $$  process ID da shell script
$*     todos os parâmetros, separados pelo 1º caractere de IFS
$@     variação de $*, que não usa IFS
$IFS   separador de campos de entrada: normalmente espaço, TAB e nova linha
```

O slide 26 trata de aspas: aspas duplas preservam espaços e ainda expandem
`$var`; aspas simples não expandem nada. O ex1 e o ex2 usam `read`, o ex2
usa `$HOME` (para o `~` digitado), o ex6 usa `$*` e o IFS, e os ex3, ex4 e
ex9 usam `$#`, `$1` e `$2`.

### Testes de condição (slides 32-35 e 40)

`test` e `[ ]` são equivalentes ("não esquecer os espaços"), com três
categorias: strings (`=`, `!=`, `-n`, `-z`), aritmética (`-eq`, `-ne`,
`-gt`, `-ge`, `-lt`, `-le`) e características de arquivos (`-e` existe,
`-f` arquivo regular, `-d` diretório, `-s` tamanho não é zero, `-r`, `-w`,
`-x`). O slide 40 mostra o problema clássico de não usar aspas:

```sh
read timeofday                 # usuário só aperta Enter
if [ $timeofday = "yes" ]      # vira: if [ = "yes" ]   -> erro
if [ "$timeofday" = "yes" ]    # vira: if [ "" = "yes" ] -> condição válida
```

Por isso **todo** `$1`/`$variavel` dentro de `[ ]` nesta lista está entre
aspas. O ex3 é o próprio exemplo de `test`/`[ ]` com `-gt` do enunciado,
estendido para `-lt`/`-gt`/igual; o ex4 usa `-gt` como condição do laço; o
ex2 usa `-e`, `-f`, `-d` (e `-L` para links); os ex7/ex8 usam `-e`, `-f`,
`-r` e `-s` para validar o arquivo; e o ex5 usa `-n` para recusar palavra
vazia.

### Estruturas de controle (slides 36-47)

`if/elif/else`, `for`, `while`, `until` e `case`. Três exemplos do slide
são usados quase sem mudança:

```sh
foo=$(($foo+1))                         # slide 43: contador num while com $(( ))
while [ "$x" -ne 10 ]; do ... done      # slide 61: laço controlado por um contador
yes | y | Yes | YES) echo "Good morning";;   # slide 46: vários padrões num case
```

O ex4 é o `while` com contador do slide 61, só que descendo até zero; o ex9
é um `while` com contador e `shift`; o ex1 usa o `case` com padrões
agrupados do slide 46 para reconhecer "sim"/"não"; o ex5 usa um `case` com
wildcard como o `n*`/`N*` do slide 46; e o ex3 depende do `elif` (slide 39)
para ter três respostas.

### Listas E/OU (slides 48-51)

`cmd1 && cmd2` só executa `cmd2` se `cmd1` der certo; `cmd1 || cmd2` só
executa `cmd2` se `cmd1` falhar (`[ -f .profile ] && exit 0 || exit 1`, no
slide 51). É o equivalente em shell ao "testar o retorno e chamar
`perror()`" dos programas em C das listas anteriores: os scripts usam
`[ teste ] || erro "mensagem"` em todas as validações.

### Funções (slides 53-57)

Funções precisam ser declaradas antes de usadas (slide 54), recebem
parâmetros em `$1`, `$2`... (slide 55) e devolvem um valor numérico com
`return` (0 = verdadeiro, 1 = falso). O exemplo dos slides 56-57 é uma
função `sim_ou_nao` que pergunta até receber uma resposta válida:

```sh
sim_ou_nao () {
    while true; do
        echo -n "Entre sim ou não: "
        read x
        case "$x" in
            s | sim ) return 0 ;;
            n | não ) return 1 ;;
            * )       echo "Responda sim ou não"
        esac
    done
}
if sim_ou_nao "$1"; then ...
```

É exatamente a função `confirma` do ex1 (item c), com um cuidado a mais: o
laço do slide pergunta para sempre se a entrada acabar (Ctrl+D ou pipe), e
o `confirma` para. Todos os scripts usam também as funções `uso` e `erro`
(ver "Convenções dos scripts").

### Execução de comandos e aritmética (slides 59-62)

```sh
echo usuario atual eh $(who)    # slide 60: $(comando) captura a SAÍDA do comando (não o status)
x=$(($x+1))                     # slide 61: $(( )) faz a conta no próprio shell (expr cria outro processo)
```

O slide 59 lista os comandos internos (*built-in*), entre eles `shift`,
`read`, `printf`, `echo`, `exit` e `return`. O slide 60 usa justamente o
`who` do ex1; o ex1 também usa `$(...)` para capturar a saída de cada
comando, e o ex6 para guardar o resultado do `tr`; o ex4 e o ex9 usam
`$(( ))` e `printf`; o ex9 usa `shift`.

### Material de apoio: "Uso de variáveis e vetores em Shell Script"

Complementa a aula com itens usados diretamente aqui:

- **item 22** — `[[ ... ]]`, a versão estendida do `test` do bash → é onde
  fica o `=~` (comparação com expressão regular) que os ex3 e ex4 usam
  para conferir se o argumento é um número inteiro.
- **item 23** — `${10}`: a partir do décimo parâmetro são obrigatórias as
  chaves; `$*` é "todos os parâmetros, como uma string única" e `$@`
  "como várias strings protegidas" → explica a pegadinha do ex9 e o `"$*"`
  do ex6.
- **item 7** — `${var#http://}` corta um prefixo do início da string → é o
  `${nome#\~}` do ex2.

### Exercício × teoria

| Exercício | Parte da teoria |
|---|---|
| 1 - informações do sistema | `read` (slide 25), `case` (slides 45-47), funções e `return` (slides 53-57), `$(comando)` e `who` (slide 60) |
| 2 - arquivo ou diretório | `read` (slide 25), `-e`/`-f`/`-d` (slide 35), aspas no teste (slide 40), `if/elif` (slide 39) |
| 3 - relação entre números | `test`/`[ ]` (slide 32), `-lt`/`-gt` (slide 34), `$1`/`$2` (slide 30), `elif` (slide 39) |
| 4 - zerador | `while` (slide 43), `$(( ))` (slides 61-62), `printf` (slide 59) |
| 5 - substring | `case` com wildcard (slides 17 e 46), `-n` (slide 33) |
| 6 - parâmetros grudados | `$*` e `IFS` (slides 29-30), pipe (slide 16) |
| 7 - usuário e nome completo | pipe (slide 16), testes de arquivo (slide 35) |
| 8 - shells sem repetição | pipe (slide 16) |
| 9 - parâmetros contados | `$#`, `$1` (slide 30), `while` (slide 43), `shift` (slide 59), `${10}` (apoio, item 23) |

## Início rápido

```bash
cd lista04
make                    # dá permissão de execução e verifica a sintaxe dos 9 scripts
make test               # roda os testes automáticos de todos os exercícios

printf 's\n' | ./ex1_info_sistema.sh             # o "s" responde à confirmação
echo testes/arquivo_teste.txt | ./ex2_tipo_arquivo.sh
echo testes/subdir_teste | ./ex2_tipo_arquivo.sh
./ex3_relacao.sh 3 5
./ex3_relacao.sh 5 3
./ex3_relacao.sh 5 5
./ex4_zerador.sh 5
./ex4_zerador.sh 10
./ex5_substring.sh ana banana
./ex5_substring.sh banana maria
./ex6_juntaparms.sh a b c d e f verde azul
./ex7_usuarios.sh testes/passwd_exemplo
./ex8_shells.sh testes/passwd_exemplo
./ex9_parametros.sh a b c d e f
```

## Como compilar

Shell script não é compilado, mas o `make` faz o papel equivalente: dentro
da pasta `lista04/`, rode

```bash
make
```

Isso dá permissão de execução (`chmod +x`) aos 9 scripts e ao testador,
verifica a sintaxe de cada um com `bash -n` e, se o `shellcheck` estiver
instalado, roda também a análise estática.

Para rodar os testes automáticos (ver "Testes automáticos"):

```bash
make test
```

Nenhum script gera arquivos, então não há `make clean`. Também não há
dependências além do bash e dos comandos básicos do sistema (`date`, `df`,
`who`, `grep`, `cut`, `sed`, `tr`, `sort`, `uniq`), que vêm instalados no
Ubuntu e no WSL.

## Convenções dos scripts

Os 9 scripts seguem o mesmo esqueleto, para ficarem fáceis de ler e de
testar:

- **Cabeçalho comentado** com o enunciado, a forma de uso, os códigos de
  saída e os slides da Aula 10 usados.
- **Funcionam também com `sh script.sh`**: a primeira linha de código volta
  para o bash se o script tiver sido chamado pelo dash (ver "Script, `#!` e
  permissão de execução", acima).
- **Duas funções auxiliares** (funções: slides 53-57), equivalentes em
  shell ao `perror()` + `exit()` dos programas em C das listas anteriores:
  - `uso` mostra no stderr o motivo e a forma correta de chamar o script, e
    sai com **status 2**;
  - `erro` mostra no stderr o motivo do erro e sai com **status 1**.
- **Validações antes de qualquer ação**, do problema mais básico ao mais
  específico, cada um com sua própria mensagem: quantidade de argumentos,
  argumento vazio (`""`), formato (número inteiro, negativo, grande demais
  para 64 bits), existência e tipo do arquivo, permissões, e fim de entrada
  nos `read` (Ctrl+D ou pipe que acabou).
- **Códigos de saída consistentes**:

| Status | Significado |
|---|---|
| 0 | sucesso (no ex2, "o arquivo existe"; no ex5, "está contida") |
| 1 | erro de execução ou de validação: número inválido, arquivo inexistente, sem permissão, entrada que terminou, confirmação negada (no ex2, "não existe"; no ex5, "não está contida") |
| 2 | uso incorreto: quantidade errada de argumentos ou argumento vazio |

A única exceção é o **ex5**: o exemplo do enunciado mostra que, com uma
palavra só ou nenhuma, o script não imprime nada. Por isso ele não mostra a
mensagem de uso — só sai com status 2, como o `grep -q`, que também
responde só pelo status.

Assim dá para usar qualquer script dentro de um `if` em outro script, e os
testes automáticos conferem não só o texto, mas também o status.

## Arquivos de teste

| Arquivo | Para que serve |
|---|---|
| `testes/arquivo_teste.txt` | Arquivo comum (ex2). |
| `testes/nome com espaço.txt` | Arquivo com espaço no nome: só é encontrado se o nome estiver entre aspas em todos os testes (ex2). |
| `testes/subdir_teste/` | Diretório (ex2). Tem só um `.gitkeep`, porque o git não versiona diretório vazio. |
| `testes/link_teste.txt` | Link simbólico para `arquivo_teste.txt` (ex2: "link simbólico para um arquivo comum"). |
| `testes/link_quebrado` | Link simbólico para `nao_existe.txt`, que não existe (ex2: o `-e` diz "não existe" mesmo o link estando ali). |
| `testes/passwd_exemplo` | `/etc/passwd` de mentira com 13 usuários (ex7, ex8), para a saída ser previsível em qualquer máquina. Montado para reproduzir **exatamente** os exemplos do enunciado: o ex7 mostra as linhas `ftp FTP User` ... `mysql MySQL server` e o ex8 mostra os 5 shells do PDF. Os shells repetidos estão **em linhas não vizinhas** (a pegadinha do `uniq`), o usuário `ana` tem o campo 5 no formato do Ubuntu (`Ana Souza,Sala 12,2222-0000,`) e o `carlos` tem o campo 5 vazio. |
| `testes/rodar_testes.sh` | Bateria de testes automáticos de todos os exercícios (ver abaixo). |

## Testes automáticos

```bash
make test                       # todos os exercícios
./testes/rodar_testes.sh 3 4    # só os exercícios 3 e 4
```

O testador roda cada script com entradas conhecidas e confere o **texto**
da saída (stdout e stderr) e o **status de saída**. Cada conferência
aparece como `OK`, `FALHOU` (com o esperado e o obtido lado a lado) ou
`PULADO`, e no final sai o resumo; o status do testador é 0 só se nada
falhou. São 253 conferências, cobrindo para cada exercício:

- os **exemplos do próprio enunciado**, com a saída exata (`3 é menor que
  5`, `5 4 3 2 1 0`, `ana está contida em banana`, `abcdefverdeazul`, os 5
  shells, `Parâmetro 1: a`...);
- os **casos de fronteira** (zero, números iguais, negativos, zeros à
  esquerda, o maior inteiro de 64 bits, 10º parâmetro, 100 parâmetros,
  última linha da entrada sem `\n`, campo vazio no passwd);
- as **pegadinhas** do Racional (`10 10` não é "menor", `10 9` não compara
  como texto, `010` não vira oito, `?` e `*` digitados não viram wildcard,
  `uniq` sem `sort` não remove nada, nome com espaço no `[ ]`...);
- **rodar com `sh`** (o dash do Ubuntu), dando a mesma saída de `./script`;
- **cada validação**: argumentos a mais/a menos, argumento vazio, número
  inválido, arquivo inexistente, diretório no lugar de arquivo, sem
  permissão, entrada que termina antes da hora — conferindo o status (1 ou
  2) e a mensagem.

Técnicas usadas, explicadas nos comentários do testador:

- **Nada em `testes/` é alterado**: o que os testes criam (links, FIFO,
  arquivos sem permissão, passwd com linhas inválidas) fica numa pasta
  temporária, apagada no final por um `trap` (mesmo com Ctrl+C).
- **`date`, `df` e `who` falsos** no ex1: para a saída não depender da
  hora, dos discos nem de quem está logado, o testador põe na frente do
  `PATH` versões que imprimem sempre o mesmo texto e anotam num arquivo que
  foram chamadas. Assim dá para conferir que, respondendo "não", **nenhum**
  comando foi executado; simular um `who` sem ninguém logado; e simular um
  `df` que falha.
- **`PATH` mínimo**, sem `who`, para testar a mensagem de "comando não
  encontrado".
- **Limite de 30 s por execução** (`timeout`): um script que entre em laço
  infinito (o ex1 perguntando para sempre depois do fim da entrada, o ex4
  com um negativo) vira `FALHOU` em vez de travar o testador.
- **`PULADO` em vez de falha** quando o teste não se aplica: testes de
  permissão rodando como root (o root ignora permissões), máquina sem
  `/dev/null` ou sem `mkfifo`.

Para conferir que os testes pegam erros de verdade, foram injetados 36 bugs
nos scripts, um de cada vez (tirar o `elif` do ex3 como no exemplo do
enunciado, tirar o `10#` do ex4, tirar as aspas do padrão do ex5, `tr -d ' '`
no ex6, espaço no lugar do TAB no ex7, tirar o `sort` do ex8, `shift 2` no
ex9, pular a confirmação no ex1, tirar a volta para o bash...): todos
foram detectados, cada um derrubando de 1 a 23 conferências.

## Como rodar cada exercício

### 1. `ex1_info_sistema.sh` — horário, disco e usuários logados
```bash
./ex1_info_sistema.sh                       # pergunta antes de executar
printf 's\n' | ./ex1_info_sistema.sh        # responde "sim" sem digitar
```
Mostra o que vai executar, pede confirmação e então roda `date`, `df -h` e
`who`, anunciando cada um antes. Saída real (com o `df` encurtado):

```
Informações do sistema

Este script vai executar:
    date     horário atual
    df -h    ocupação do disco
    who      usuários logados

Deseja continuar? [s/N] s

==> Horário atual
    $ date
Wed Oct 21 14:17:33 -03 2026

==> Ocupação do disco
    $ df -h
Filesystem           Size  Used Avail Use% Mounted on
/dev/sdd            1007G   49G  908G   6% /
C:\                  953G  309G  645G  33% /mnt/c
...

==> Usuários logados
    $ who
davidcubric pts/1        2026-10-21 11:40

Pronto: os 3 comandos foram executados.
```

O exercício tem quatro itens, e o script entregue é a versão final (item
d), com cada trecho marcado no código com o item correspondente. A
evolução:

```sh
# a) só os comandos
date
df -h
who

# b) anunciando cada comando antes
echo "Horário atual:";     date
echo "Ocupação do disco:"; df -h
echo "Usuários logados:";  who

# c) pedindo confirmação antes
echo "Deseja continuar? (s/n)"
read resposta
if [ "$resposta" = "s" ]; then
    ...os comandos do item b...
fi

# d) organizado e comentado: ex1_info_sistema.sh
```

**Validações:** recusa argumentos (status 2); confere que `date`, `df` e
`who` existem antes de perguntar (status 1); resposta não reconhecida faz a
pergunta de novo; a entrada que termina sem resposta (Ctrl+D, ou pipe que
acabou) cancela em vez de entrar em laço infinito; "não" ou só Enter
cancela sem executar nada (status 1); e se algum comando falhar, os outros
rodam mesmo assim e o script termina com status 1 dizendo quantos falharam.

**Racional:** o item d pede código "visivelmente mais agradável" e fácil de
manter, e é isso que as duas funções resolvem. A confirmação (item c) é a
função `confirma`, que é a `sim_ou_nao` dos slides 56-57: pergunta com
`read`, reconhece a resposta com um `case` de padrões agrupados
(`s | S | sim | Sim | SIM`, como o `yes | y | Yes | YES` do slide 46) e
devolve 0 ou 1 com `return`, para ser usada direto no `if`. Dois cuidados
que o slide não tem: o `"$resposta"` entre aspas no `case` faz o Enter
(resposta vazia) ser um caso válido — o "não" padrão, indicado pelo `N`
maiúsculo em `[s/N]` —, em vez do erro do slide 40; e quando o `read`
falha por fim de entrada, a função devolve "não" em vez de perguntar para
sempre, o que travaria o script num pipe. O anúncio (item b) é a função
`executa`, que imprime a descrição e a linha exata do comando antes de
rodá-lo: assim a lista de comandos fica num lugar só, e acrescentar um
quarto comando é uma linha. Ela também captura a saída com `$(...)` (slide
60) para tratar o caso em que o comando não imprime nada: o `who` só mostra
sessões registradas no sistema, e no WSL ou num contêiner é comum ele não
mostrar ninguém — sem tratamento, a seção ficaria em branco. Detalhe: o
`read -p` só mostra a pergunta quando a entrada é o teclado; rodando com
`printf 's\n' |`, a pergunta não aparece e a resposta vem do pipe.

### 2. `ex2_tipo_arquivo.sh` — o arquivo existe? É arquivo ou diretório?
```bash
./ex2_tipo_arquivo.sh
# Nome do arquivo: testes/subdir_teste
# 'testes/subdir_teste' existe e é um diretório.

echo testes/arquivo_teste.txt | ./ex2_tipo_arquivo.sh      # é um arquivo comum
echo "testes/nome com espaço.txt" | ./ex2_tipo_arquivo.sh  # é um arquivo comum
echo testes/link_teste.txt | ./ex2_tipo_arquivo.sh         # link simbólico para um arquivo comum
echo testes/link_quebrado | ./ex2_tipo_arquivo.sh          # link simbólico quebrado (status 1)
echo testes/nao_existe.txt | ./ex2_tipo_arquivo.sh         # não existe (status 1)
```
Pede o nome do arquivo, diz se ele existe e, se existir, se é um arquivo
comum ou um diretório.

**Validações:** recusa argumentos, porque o enunciado pede que o nome seja
digitado (status 2); acusa a entrada que termina antes do nome, mas aceita
a última linha sem `\n`; recusa nome vazio (só Enter) (status 1). O status
é a própria resposta: 0 = existe, 1 = não existe ou link quebrado. Um
arquivo dentro de um diretório sem permissão de acesso (para um usuário
comum, `/root/.bashrc`) não é dado como "não existe": o script avisa que
não tem como saber (status 1). E quando o arquivo não é achado por um
engano comum de digitação, a resposta vem com uma dica: `$HOME` digitado
(o `read` não expande variáveis) ou um espaço sem querer no fim do nome.

**Racional:** o nome vem de `IFS= read -r` (slide 25). O `-r` impede que
uma `\` digitada seja interpretada, e o `IFS=` vazio só para esse `read`
impede que ele apague espaços no começo e no fim — o comportamento normal
do `read`, que tornaria um arquivo chamado `"nota.txt "` impossível de
achar. Depois vêm os testes de arquivo do slide 35: `-e` para existir e
`-d`/`-f` para o tipo. O `-e` vem antes porque `-d` e `-f` falsos não
querem dizer "não existe": `/dev/null` existe e não é nem arquivo comum nem
diretório (é um dispositivo), e o script tem uma descrição para cada tipo
especial em vez de chamá-lo de "arquivo". Todos os `"$nome"` estão entre
aspas (slide 40): sem aspas, um nome com espaço vira várias palavras e
`[ -e testes/nome com espaço.txt ]` dá erro; pior, para um nome com espaço
que **não existe**, o erro do `[` conta como "falso", o `if [ ! -e ... ]`
é pulado e o script seguiria como se o arquivo existisse. Duas sutilezas de links: `-e`, `-f` e `-d`
seguem links simbólicos, então para um link eles descrevem o arquivo
apontado — o script usa `-L` (que testa o próprio link) para dizer "é um
link simbólico para um arquivo comum"; e um link quebrado dá `-e` falso
mesmo estando no diretório, e ganha uma mensagem própria dizendo para onde
ele aponta. Uma terceira sutileza é de permissão: para saber se um arquivo
existe, o sistema precisa entrar no diretório dele (permissão `x`), então
dentro de um diretório fechado o `-e` dá falso mesmo o arquivo existindo.
Quando o `-e` falha, o script sobe pelo caminho com `dirname` até o
diretório mais fundo que consegue ver e, se esse diretório não tem `x`,
responde "sem permissão para entrar em '/root': não dá para saber" em vez
de "não existe". Por fim, o `~`: na linha de comando o shell troca `~` pelo
diretório pessoal, mas o `read` entrega o texto literal, então o script faz
essa troca para `~` e `~/...` usando `$HOME` (slide 28).

### 3. `ex3_relacao.sh` — relação entre dois números
```bash
./ex3_relacao.sh 3 5     # 3 é menor que 5
./ex3_relacao.sh 5 3     # 5 é maior que 3
./ex3_relacao.sh 5 5     # 5 é igual a 5
./ex3_relacao.sh -3 -10  # -3 é maior que -10
```
Mostra se o primeiro número é menor, maior ou igual ao segundo, no formato
do enunciado.

**Validações:** exatamente dois argumentos, nenhum vazio (status 2); cada
um tem que ser um inteiro (`-` opcional e dígitos: `3.5`, `abc` e `" 5"`
são recusados) e caber em 64 bits (status 1). Sem essas validações, o `[`
imprimiria o próprio erro, `integer expression expected`, no meio da saída.

**Racional:** o enunciado dá o exemplo com `test`/`[ ]` e `-gt` (slides 32
e 34), mas com uma pegadinha: só `if/else`, então quando o número é
**igual** a 10 cai no `else` e o script diz "é menor que 10". Com dois
números são três casos, e por isso a solução é `if -lt / elif -gt / else`
(slide 39): se não é menor nem maior, é igual. A comparação tem que ser com
`-lt`/`-gt` (aritmética, slide 34), e os outros jeitos que parecem
funcionar estão errados: `[ "$1" > "$2" ]` não compara nada — dentro do `[`
o `>` é redirecionamento, que cria um arquivo com o nome do segundo número,
e o teste vira "a string não é vazia", sempre verdadeiro; e `[ "$1" \< "$2" ]`
compara como **texto**, caractere a caractere, e diz que `10` vem antes de
`9` (porque `'1' < '9'`). O teste do formato usa `[[ $1 =~ ^-?[0-9]+$ ]]`
(item 22 do material de apoio), e o do tamanho usa um truque clássico:
`[ "$1" -eq "$1" ]` só dá certo se o próprio `[` aceitar o número, então
ele responde se o valor cabe nos 64 bits (até 9223372036854775807). Os
números são mostrados como foram digitados: `007 7` dá `007 é igual a 7`.

### 4. `ex4_zerador.sh` — contagem regressiva até zero
```bash
./ex4_zerador.sh 5     # 5 4 3 2 1 0
./ex4_zerador.sh 10    # 10 9 8 7 6 5 4 3 2 1 0
./ex4_zerador.sh 0     # 0
```
Mostra o número e cada passo até zero, todos na mesma linha.

**Validações:** exatamente um argumento, não vazio (status 2); um negativo
tem mensagem própria, porque diminuindo a partir dele nunca se chega a zero
(o laço não terminaria); depois, só dígitos (`2.5` e `abc` são recusados) e
no máximo 9223372036854775807 (status 1).

**Racional:** é o laço do slide 61 ao contrário: em vez de somar 1 até 10,
`while [ "$n" -gt 0 ]` subtrai 1 com `$(( ))` enquanto ainda for maior que
zero. Para ficar tudo numa linha, a saída é feita com `printf` (slide 59),
que só quebra a linha quando o formato tem `\n` — o `echo` quebraria a cada
número. O primeiro número sai sozinho e cada passo seguinte sai com o
espaço **antes** (`printf ' %d'`), para a linha não terminar com um espaço
sobrando; um `echo` no final fecha a linha. A pegadinha está no `$(( ))`:
um número que começa com `0` é lido em **octal**, então sem tratamento
`010` valeria 8 (a contagem sairia `010 7 6 5 ...`) e `08` daria erro
(`value too great for base`, porque 8 não é dígito octal). O prefixo `10#`
em `$((10#$1))` manda ler em base 10. O limite de 64 bits é conferido antes
porque o `$(( ))` não avisa quando passa dele: `$((99999999999999999999))`
dá `7766279631452241919` sem nenhum erro. (Uma alternativa de uma linha só
seria `seq -s ' ' "$1" -1 0`, mas o exercício é sobre o laço.)

### 5. `ex5_substring.sh` — a primeira palavra está contida na segunda?
```bash
./ex5_substring.sh ana banana         # ana está contida em banana
./ex5_substring.sh banana maria       # (nada; status 1)
./ex5_substring.sh banana             # (nada; status 2)
./ex5_substring.sh                    # (nada; status 2)
```
Se a primeira palavra aparece dentro da segunda, mostra a mensagem; senão,
não mostra nada.

**Validações:** exatamente duas palavras, nenhuma vazia (status 2) — mas,
como no exemplo do enunciado, **sem mensagem de uso**: em todos os casos de
"não", o script fica em silêncio e quem precisar saber o motivo olha o
status (`echo $?`): 0 = contida, 1 = não contida, 2 = uso incorreto. Uma
palavra vazia é recusada porque, pela lógica de "estar contida", o texto
vazio estaria contido em qualquer outro.

**Racional:** a verificação é um `case` com o padrão `*"$1"*` — "qualquer
coisa, a primeira palavra, qualquer coisa" —, o mesmo wildcard `*` do slide
17 usado dentro do `case` como o `n*` do slide 46. As aspas em volta do
`$1` são o ponto principal: dentro delas, os caracteres da palavra valem
literalmente. Sem aspas (`*$1*`), uma palavra com `*`, `?` ou `[...]`
viraria parte do padrão, e `./ex5_substring.sh '?' banana` diria que `?`
está contida em `banana` (porque `?` casa com qualquer caractere). A
solução com `echo "$2" | grep "$1"` tem o mesmo problema em outra forma:
para o `grep` a palavra é uma **expressão regular**, então `.` casaria com
qualquer letra (seria preciso `grep -F`). A comparação diferencia
maiúsculas de minúsculas: `Ana` não está contida em `banana`.

### 6. `ex6_juntaparms.sh` — todos os parâmetros "grudados"
```bash
./ex6_juntaparms.sh a b c d e f verde azul    # abcdefverdeazul
./ex6_juntaparms.sh "verde claro" azul        # verdeclaroazul
```
Mostra todos os parâmetros juntos, como uma única palavra.

**Validações:** pelo menos um parâmetro (status 2); se todos forem vazios
ou só espaços, não sobra nada para mostrar e o script avisa em vez de
imprimir uma linha em branco (status 1).

**Racional:** é a dica do enunciado em duas etapas. Primeiro, `"$*"` junta
todos os parâmetros numa string só, separados pelo primeiro caractere do
`IFS` (slide 30) — normalmente o espaço (slide 29): `a b c ... azul`.
Depois, o pipe entrega essa string ao `tr -d`, que **apaga** os caracteres
do conjunto; o conjunto é `[:space:]` (espaço, TAB e quebra de linha), e
não só `' '`, para que também um TAB ou uma quebra de linha *dentro* de um
parâmetro não quebre a "única palavra". Pelo mesmo motivo, o espaço dentro
de um parâmetro (`"verde claro"`) também some. Se a intenção fosse grudar
os parâmetros mas manter os espaços internos, a solução seria outra, sem
`tr`: `IFS=''; echo "$*"` (com o `IFS` vazio, o `$*` junta sem separador)
ou `printf '%s' "$@"`. O `printf '%s'` também é usado no lugar do `echo`
por um detalhe: com o único parâmetro `-n`, `echo "$*"` leria `-n` como
opção e não imprimiria nada. O `tr` trabalha byte a byte, e os bytes dos
caracteres acentuados em UTF-8 nunca coincidem com os de espaço, então
`ação é` vira `açãoé` sem estragar os acentos.

### 7. `ex7_usuarios.sh` — usuário e nome completo, separados por TAB
```bash
./ex7_usuarios.sh                          # usa o /etc/passwd da máquina
./ex7_usuarios.sh testes/passwd_exemplo    # arquivo de teste
```
Com o arquivo de teste, a saída tem as 5 linhas do exemplo do enunciado
(`ftp`→`FTP User` ... `mysql`→`MySQL server`) e, entre outras,
`ana<TAB>Ana Souza` e `carlos<TAB>` (nome em branco). Para ver os TABs:
`./ex7_usuarios.sh testes/passwd_exemplo | cat -A` (o TAB aparece como `^I`).

**Validações:** no máximo um argumento, e não vazio — um `""` não cai
silenciosamente no `/etc/passwd` (status 2); o arquivo precisa existir, ser
um arquivo comum, legível e não vazio (status 1). Só entram linhas com
exatamente 7 campos: as outras são ignoradas, com um aviso no stderr
dizendo quantas eram, e um arquivo sem nenhuma linha válida é recusado
(status 1).

**Racional:** cada linha do `/etc/passwd` tem 7 campos separados por `:`
(`nome:senha:UID:GID:descrição:diretório:shell`). O pipe (slide 16) tem
quatro etapas: `grep -E` deixa só as linhas válidas; `cut -d: -f1,5` pega
os campos 1 e 5, mantendo o `:` entre eles (`ana:Ana Souza,Sala 12,...`);
`sed 's/,.*$//'` apaga do primeiro `,` até o fim; e `tr ':' '\t'` troca o
`:` que sobrou pelo TAB pedido — o mesmo `tr` do ex6, agora traduzindo um
caractere em outro em vez de apagar. O `sed` é o detalhe que o exemplo do
enunciado não mostra: o campo 5 (chamado GECOS) pode ter várias
informações separadas por vírgula, e no Debian/Ubuntu o `adduser` grava
`Nome,Sala,Telefone do trabalho,Telefone de casa` — no `/etc/passwd` real
desta máquina, por exemplo, o usuário criado na instalação tem o campo 5
igual a `,,,`. O **nome completo** é só a primeira parte; sem o `sed`, a
saída teria `Ana Souza,Sala 12,2222-0000,`. (O `cut` também aceita
`--output-delimiter=$'\t'`, que faria o papel do `tr`.) O argumento
opcional existe para testar contra um arquivo fixo e ter uma saída
previsível; sem argumento, usa o `/etc/passwd` real.

### 8. `ex8_shells.sh` — shells sem repetição
```bash
./ex8_shells.sh                          # usa o /etc/passwd da máquina
./ex8_shells.sh testes/passwd_exemplo    # arquivo de teste
```
Com o arquivo de teste, a saída é exatamente a do enunciado: `/bin/bash`,
`/bin/false`, `/bin/sync`, `/sbin/halt` e `/sbin/shutdown`.

**Validações:** as mesmas do ex7. Além disso, um campo de shell vazio vira
`/bin/sh`: pelo manual do passwd (`man 5 passwd`), é esse o shell usado
quando o campo está vazio. Sem esse tratamento, a saída teria uma linha em
branco. E um arquivo salvo no Windows (linhas terminadas em `\r\n`) tem o
`\r` apagado: sem isso, `/bin/bash\r` e `/bin/bash` seriam linhas
diferentes para o `uniq`, e num arquivo com os dois tipos de linha o mesmo
shell apareceria duas vezes — idênticos na tela.

**Racional:** o shell é o 7º (e último) campo, `cut -d: -f7`. A pegadinha
está na dica do enunciado: o `uniq` só remove linhas repetidas
**vizinhas**. No `passwd_exemplo` o `/bin/bash` aparece na primeira linha e
de novo no fim, e o `/bin/false` em dois blocos separados, então
`cut -d: -f7 testes/passwd_exemplo | uniq` mostra 7 linhas, com repetições.
É preciso ordenar antes com `sort`, para as linhas iguais ficarem juntas, e
só então o `uniq` funciona (`sort -u` faz as duas coisas de uma vez). A
ordenação também é o que deixa a saída na mesma ordem do exemplo do
enunciado.

### 9. `ex9_parametros.sh` — todos os parâmetros, contados
```bash
./ex9_parametros.sh a b c d e f
./ex9_parametros.sh a b c d e f g h i j k "verde claro"
```
Imprime `Parâmetro 1: a`, `Parâmetro 2: b`, ..., como no enunciado; no
segundo exemplo, vai até `Parâmetro 10: j`, `Parâmetro 11: k` e
`Parâmetro 12: verde claro`.

**Validações:** pelo menos um parâmetro (status 2). Um parâmetro vazio
(`""`) é aceito e listado como `Parâmetro 1: `, porque é um parâmetro de
verdade. A impressão usa `printf 'Parâmetro %d: %s\n'` em vez de `echo`,
para cada parâmetro sair exatamente como veio (`-n` e `\t` aparecem
literalmente).

**Racional:** o laço é `while [ $# -gt 0 ]` com `shift` (slide 59): cada
`shift` descarta o `$1` e "anda" com os outros (`$2` vira `$1`, `$3` vira
`$2`...), diminuindo o `$#`. Assim o script sempre imprime `$1`, e um
contador com `$(( ))` (slide 43) dá o número. A alternativa óbvia — um
contador `i` e imprimir `$1`, `$2`, ... — esbarra numa pegadinha: o shell
lê `$10` como `$1` seguido do caractere `0`, então com os parâmetros
`a b c d e f g h i j`, `$10` dá `a0`, não `j`. O bash aceita `${10}` com
chaves (item 23 do material de apoio), mas o `shift` funciona em qualquer
`sh` e não depende de quantos parâmetros vierem. O `"$1"` entre aspas
mantém `verde claro` como um parâmetro só.

## Exemplo rápido de teste

O mesmo do "Início rápido", mais os casos que mostram as pegadinhas de cada
exercício:

```bash
cd lista04
make && make test

./ex1_info_sistema.sh                                # interativo: responda s, n, ou outra coisa
printf 'talvez\nn\n' | ./ex1_info_sistema.sh         # resposta inválida, depois "não": nada é executado

echo "testes/nome com espaço.txt" | ./ex2_tipo_arquivo.sh
echo testes/link_teste.txt | ./ex2_tipo_arquivo.sh
echo testes/link_quebrado | ./ex2_tipo_arquivo.sh
echo '~' | ./ex2_tipo_arquivo.sh                     # o ~ digitado vira o $HOME
echo /root/.bashrc | ./ex2_tipo_arquivo.sh           # sem permissão: não dá para saber

./ex3_relacao.sh 10 10                               # o if/else do enunciado diria "menor"
./ex3_relacao.sh 10 9
[ 10 \< 9 ] && echo "como texto, 10 vem antes de 9"  # por isso -lt/-gt, e não \< e \>
ls -l /bin/sh; sh ex3_relacao.sh 3 5                 # com o dash (slides 6 e 23): mesma resposta

./ex4_zerador.sh 010
echo $((010))                                        # 8: sem o 10#, o $(( )) lê em octal

./ex5_substring.sh ana banana
./ex5_substring.sh '?' banana; echo "status: $?"     # 1: o ? digitado não vira wildcard
./ex5_substring.sh banana; echo "status: $?"         # 2: uso incorreto, mas em silêncio

./ex6_juntaparms.sh a b c d e f verde azul
./ex6_juntaparms.sh "verde claro" azul

./ex7_usuarios.sh testes/passwd_exemplo | cat -A     # ^I é o TAB
./ex7_usuarios.sh | head -5                          # o /etc/passwd real

./ex8_shells.sh testes/passwd_exemplo
cut -d: -f7 testes/passwd_exemplo | uniq             # sem sort: repetições
./ex8_shells.sh

./ex9_parametros.sh a b c d e f g h i j k "verde claro"
set -- a b c d e f g h i j; echo "\$10 = $10, \${10} = ${10}"    # a0 vs j
```
