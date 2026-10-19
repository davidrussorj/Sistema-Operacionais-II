# Lista 4 - Shell Script

Exercícios da disciplina Tópicos Especiais em Sistemas Computacionais I / SO 2.

Base teórica: **Aula 10 - Programação em Shell** (slides 9-17, 22-62) e o
material de apoio **"Uso de variáveis e vetores em Shell Script"**, ambos do
Classroom da turma.

Cada script é comentado bloco a bloco: o cabeçalho traz o enunciado, o uso,
os códigos de saída e os slides correspondentes, e cada etapa explica o que
faz e por quê. Todos validam a entrada antes de agir (ver "Convenções dos
scripts"), e a pasta `testes/` tem uma bateria de testes automáticos que
roda os 16 exercícios contra entradas conhecidas (`make test`).

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
exercícios usam recursos dele (vetor no ex5, `read -p` no ex6 e ex8). O
`make` faz o `chmod +x` em todos.

### Redirecionamento e pipe (slides 9-16)

Todo processo nasce com três descritores abertos: `stdin` (0), `stdout` (1)
e `stderr` (2) — o mesmo modelo de *file descriptor* da Aula 06, visto na
Lista 1. Os slides mostram cada operador:

```sh
$ ls -l > lssaida.txt                          # slide 10: > sobrescreve ("CUIDADO!!!")
$ ls >> lista.txt                              # slide 12: >> anexa ao final
$ cat rel.txt > novorel.txt 2> erros.log       # slide 14: 2> manda os erros para outro arquivo
$ more < killout.txt                           # slide 15: < troca a entrada padrão
$ ps | sort | more                             # slide 16: pipe, a saída de um é a entrada do outro
```

O ex16 é literalmente o exemplo do slide 14 (`> arq.txt 2> erros.txt`), o
ex14 depende de usar `>>` e não `>`, o ex9 usa `<` para o `wc` não imprimir
o nome do arquivo, e os ex11, ex12 e ex15 são pipes.

### Expansão de wildcards (slide 17)

`*` (qualquer sequência), `?` (um caractere), `[set]` (um caractere do
conjunto) e `{a,b}` — e o ponto principal do slide: **"A Shell expande
wildcards"**. Quem transforma `*.mpeg3` na lista de arquivos é o próprio
shell, antes de executar o comando. O ex5 usa `[set]` (`/proc/[0-9]*`) e os
ex7/ex8 usam `*` para achar os arquivos a renomear.

### Variáveis, aspas e parâmetros (slides 24-31)

Variáveis são criadas na primeira atribuição e lidas com `$` (slide 24),
`read` lê uma variável do teclado (slide 25), e os slides 27-30 listam as
variáveis especiais:

```
$HOME  diretório pessoal do usuário        $#  número de parâmetros passados
$1, $2 parâmetros dados ao script           $$  process ID da shell script
$*     todos os parâmetros, separados pelo 1º caractere de IFS
$@     variação de $*, que não usa IFS
```

O slide 26 trata de aspas: aspas duplas preservam espaços e ainda expandem
`$var`; aspas simples não expandem nada. O ex2 usa `$HOME`, o ex10 usa `$#`
e `$1`, o ex14 usa `$*`, e os ex6/ex8 usam `read`.

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
aspas (o ex3 mostra o que acontece sem elas). O ex3 usa `-e`, o ex4 usa
`-gt`, os ex7/ex8 usam `-d` e `-e`, o ex9 usa `-f`, `-s` e `-n`, e os
ex11/ex12 usam `-r`.

### Estruturas de controle (slides 36-47)

`if/elif/else`, `for`, `while`, `until` e `case`. Dois exemplos do slide
são usados quase sem mudança:

```sh
for file in $(ls f*.sh); do     # slide 42: $(comando) fornece a lista para o for
foo=$(($foo+1))                 # slide 43: contador num while com $(( ))
[nN]* ) echo "Good afternoon";; # slide 47: padrões com wildcard dentro do case
```

O ex13 é um `for` dentro de outro, alimentado por `$(seq 1 5)`; o ex10 é um
`while` com contador `$(( ))`; o ex6 valida mês e ano com `case`; os ex7/ex8
são um `for` sobre o resultado de um wildcard.

### Listas E/OU (slides 48-51)

`cmd1 && cmd2` só executa `cmd2` se `cmd1` der certo; `cmd1 || cmd2` só
executa `cmd2` se `cmd1` falhar (`[ -f .profile ] && exit 0 || exit 1`, no
slide 51). É o equivalente em shell ao "testar o retorno e chamar
`perror()`" dos programas em C das listas anteriores: os scripts usam
`comando || exit 1` sempre que uma falha deve interromper a execução (ex2,
ex4, ex9, ex13), e `[ -e "$arquivo" ] || continue` nos laços dos ex7/ex8.

### Execução de comandos e aritmética (slides 59-62)

```sh
echo usuario atual eh $(who)    # slide 60: $(comando) captura a SAÍDA do comando (não o status)
x=$(($x+1))                     # slide 61: $(( )) faz a conta no próprio shell (expr cria outro processo)
```

O slide 59 lista os comandos internos (*built-in*), entre eles `shift`,
`read`, `echo`, `exit` e `return`. O ex1 inteiro é sobre `$(...)`; o ex5
usa `$(( ))` para descontar o próprio script; o ex10 usa `shift`.

### Material de apoio: "Uso de variáveis e vetores em Shell Script"

Complementa a aula com itens usados diretamente aqui:

- **item 8** — `${var%.com.br/}` corta um sufixo do final da string → é o
  `${arquivo%.mpeg3}.mp3` dos ex7/ex8.
- **item 11** — `${var/#http/Site}` troca um prefixo → é o
  `${dir/#\~/$HOME}` do ex8.
- **item 23** — `${10}`: a partir do décimo parâmetro são obrigatórias as
  chaves → explica a pegadinha do ex10.
- **itens 39-45** — vetores e `${#DISTROS[@]}` (quantidade de elementos) →
  é como o ex5 conta os processos.
- **item 27** — formatadores do `date` (`%d`, `%m`, `%Y`, `%H`, `%M`) → ex2
  e ex14.

### Exercício × teoria

| Exercício | Parte da teoria |
|---|---|
| 1 - banner da hora | `$(comando)` (slide 60), pipe (slide 16), separação de palavras por IFS (slides 29-30) |
| 2 - data e arquivos | `$HOME` (slide 28), formatadores do `date` (apoio, item 27) |
| 3 - arquivo existe | `[ -e ]` (slide 35), aspas no teste (slide 40) |
| 4 - maior que 100 bytes | comparação aritmética `-gt` (slide 34) |
| 5 - contar processos | wildcard `[set]` (slide 17), vetores (apoio, itens 39-45), `$(( ))` (slide 61) |
| 6 - calendário | `read` (slide 25), `case` (slides 45-47) |
| 7 - renomear .mpeg3 | `for` sobre wildcard (slides 17 e 42), `${var%sufixo}` (apoio, item 8) |
| 8 - renomear interativo | o mesmo do 7 + `read` (slide 25) + `${var/#prefixo/...}` (apoio, item 11) |
| 9 - linhas e palavras | redirecionamento `<` (slide 15), `-f`/`-s` (slide 35) |
| 10 - listar argumentos | `$#`, `$1` (slide 30), `while` (slide 43), `shift` (slide 59), `${10}` (apoio, item 23) |
| 11 - usuários ordenados | pipe (slide 16) |
| 12 - shells únicos | pipe (slide 16) |
| 13 - criar diretórios | `for` com `$(comando)` (slide 42), `touch` (slide 8) |
| 14 - repositório de ideias | `>>` (slide 12), `$*` (slide 30) |
| 15 - espaço por diretório | pipe (slide 16) |
| 16 - find com stdout/stderr separados | `>` e `2>` (slides 13-14) |

## Início rápido

```bash
cd lista04
make                    # dá permissão de execução e verifica a sintaxe dos 16 scripts
make test               # roda os testes automáticos de todos os exercícios
T=$(mktemp -d)          # pasta temporária para os exercícios que criam ou alteram arquivos

./ex1_banner_hora.sh    # precisa do banner (ver "Dependências")
./ex2_data_e_arquivos.sh
./ex3_arquivo_existe.sh testes/texto.txt
./ex3_arquivo_existe.sh testes/link_quebrado
./ex4_maior_que_100.sh testes/tamanho_100.txt
./ex4_maior_que_100.sh testes/tamanho_101.txt
./ex5_contar_processos.sh
printf '10\n2026\n' | ./ex6_calendario.sh    # precisa do cal (ver "Dependências")
cp -r testes/musicas_modelo "$T/ex7" && ./ex7_renomear_mpeg3.sh "$T/ex7"
cp -r testes/musicas_modelo "$T/ex8" && printf '%s\nmpeg3\nogg\n' "$T/ex8" | ./ex8_renomear_interativo.sh
./ex9_linhas_palavras.sh testes/texto.txt
./ex9_linhas_palavras.sh testes/sem_quebra_final.txt
./ex10_listar_argumentos.sh a b c d e f g h i j k "l com espaço"
./ex11_usuarios_ordenados.sh testes/passwd_exemplo
./ex12_shells_unicos.sh testes/passwd_exemplo
./ex13_criar_diretorios.sh "$T/ex13" && find "$T/ex13" -mindepth 1 | sort
IDEIAS="$T/ideias.txt" ./ex14_repositorio_ideias.sh Fazer script para remover usuários
./ex15_espaco_diretorios.sh testes/conta_exemplo
./ex16_buscar_meus_arquivos.sh /etc && head -n 3 erros.txt

rm -rf "$T" && make clean
```

## Como compilar

Shell script não é compilado, mas o `make` faz o papel equivalente: dentro
da pasta `lista04/`, rode

```bash
make
```

Isso dá permissão de execução (`chmod +x`) aos 16 scripts e ao testador,
verifica a sintaxe de cada um com `bash -n` e, se o `shellcheck` estiver
instalado, roda também a análise estática (todos passam sem nenhum aviso).

Para rodar os testes automáticos (ver "Testes automáticos"):

```bash
make test
```

Para apagar os arquivos gerados pelo ex16 (`arq.txt` e `erros.txt`):

```bash
make clean
```

### Dependências

Dois exercícios usam comandos que não vêm instalados por padrão no Ubuntu
(nem no WSL):

```bash
sudo apt install sysvbanner ncal    # banner (ex1) e cal (ex6)
```

Se faltar algum deles, o script avisa qual pacote instalar e sai com erro,
em vez de deixar o shell imprimir `command not found` no meio da saída.

## Convenções dos scripts

Os 16 scripts seguem o mesmo esqueleto, para ficarem fáceis de ler e de
testar:

- **Cabeçalho comentado** com o enunciado, a forma de uso, os códigos de
  saída e os slides da Aula 10 usados.
- **Duas funções auxiliares** (funções: slides 53-57), equivalentes em
  shell ao `perror()` + `exit()` dos programas em C das listas anteriores:
  - `uso` mostra no stderr o motivo e a forma correta de chamar o script, e
    sai com **status 2**;
  - `erro` mostra no stderr o motivo do erro e sai com **status 1**.
- **Validações antes de qualquer ação**, do problema mais básico ao mais
  específico, cada um com sua própria mensagem: quantidade de argumentos,
  argumento vazio (`""`), existência, tipo (arquivo × diretório),
  permissões (`-r`, `-w`, `-x`), fim de entrada nos `read` (Ctrl+D ou pipe
  que acabou) e formato do que foi digitado.
- **Códigos de saída consistentes**:

| Status | Significado |
|---|---|
| 0 | sucesso (no ex3, "o arquivo existe") |
| 1 | erro de execução ou de validação: arquivo inexistente, sem permissão, entrada inválida, comando não instalado (no ex3, "o arquivo não existe") |
| 2 | uso incorreto: quantidade errada de argumentos ou argumento vazio |

Assim dá para usar qualquer script dentro de um `if` em outro script, e os
testes automáticos conferem não só o texto, mas também o status.

## Arquivos de teste

| Arquivo | Para que serve |
|---|---|
| `testes/texto.txt` | Texto com 5 linhas e 24 palavras, incluindo uma linha em branco, vários espaços seguidos e um TAB entre palavras (ex9). Também serve de "arquivo que existe" no ex3. |
| `testes/sem_quebra_final.txt` | 3 linhas e 10 palavras, mas **sem `\n` no final** — o `wc -l` conta só 2 (ex9). |
| `testes/link_quebrado` | Link simbólico para `nao_existe.txt`, que não existe (ex3). |
| `testes/tamanho_100.txt` | Exatamente 100 bytes — o limite, que **não** é "maior que 100" (ex4). |
| `testes/tamanho_101.txt` | Exatamente 101 bytes — o primeiro tamanho maior que 100 (ex4). |
| `testes/musicas_modelo/` | Modelo para os exercícios que renomeiam (ex7, ex8): `faixa01.mpeg3`, `faixa02.mpeg3`, `minha musica.mpeg3` (com espaço), `ja_existe.mpeg3` + `ja_existe.mp3` (colisão), `notas.mpeg3.txt` (`.mpeg3` no meio do nome) e `letra.txt`. **Sempre copie antes de rodar**, os scripts renomeiam de verdade. |
| `testes/passwd_exemplo` | `/etc/passwd` de mentira com 10 usuários fora de ordem e shells repetidos **em linhas não vizinhas** (ex11, ex12), para a saída ser previsível em qualquer máquina. |
| `testes/conta_exemplo/` | "Conta" com cinco diretórios de tamanhos conhecidos: `vazio/`, `pequeno/` (2 KB), `medio/` (20 KB), `.oculto/` (40 KB, diretório oculto) e `grande/` (60 KB) (ex15). |
| `testes/rodar_testes.sh` | Bateria de testes automáticos de todos os exercícios (ver abaixo). |

## Testes automáticos

```bash
make test                       # todos os exercícios
./testes/rodar_testes.sh 7 8    # só os exercícios 7 e 8
```

O testador roda cada script com entradas conhecidas e confere três coisas:
o **texto** da saída (stdout e stderr), o **status de saída** e os
**arquivos** criados ou alterados. Cada conferência aparece como `OK`,
`FALHOU` (com o esperado e o obtido lado a lado) ou `PULADO`, e no final sai
o resumo; o status do testador é 0 só se nada falhou. São cerca de 245
conferências, cobrindo para cada exercício:

- o **caso normal** com os arquivos de `testes/` e a saída exata esperada;
- os **casos de fronteira** (arquivo de exatamente 100 bytes, arquivo vazio,
  última linha sem `\n`, 10º argumento, diretório vazio, rodar duas vezes);
- as **pegadinhas** do Racional (o script não cria um arquivo chamado `100`,
  `*` digitado não vira wildcard, `.oculto` aparece no ex15, `uniq` sem
  `sort` não remove nada, `>>` não apaga as ideias anteriores...);
- **cada validação**: argumentos a mais/a menos, argumento vazio, arquivo
  inexistente, diretório no lugar de arquivo, sem permissão, entrada que
  termina antes da hora — conferindo o status (1 ou 2) e a mensagem.

Técnicas usadas, explicadas nos comentários do testador:

- **Nada em `testes/` é alterado**: o que é destrutivo roda em cópias numa
  pasta temporária, apagada no final por um `trap` (mesmo com Ctrl+C).
- **`date` falso**: para a saída dos ex1 e ex14 não depender da hora, o
  testador põe na frente do `PATH` um `date` que sempre imprime a mesma data.
  Com ele, o ex14 grava exatamente o exemplo do enunciado,
  `30/08/2008 10:21 Fazer script para remover usuários`.
- **`PATH` mínimo**, sem `banner` nem `cal`, para testar a mensagem de
  "comando não instalado" mesmo numa máquina que tem os dois.
- **Limite de 30 s por execução** (`timeout`): um script que entre em laço
  infinito vira `FALHOU` em vez de travar o testador.
- **`PULADO` em vez de falha** quando o teste não se aplica: `banner`/`cal`
  não instalados, testes de permissão rodando como root (o root ignora
  permissões), e a busca completa do ex16 a partir de `/`, que demora.

Para conferir que os testes pegam erros de verdade, foram injetados 20 bugs
nos scripts, um de cada vez (trocar `-gt` por `-ge` no ex4, tirar o `sort`
do ex12, trocar `>>` por `>` no ex14, misturar stderr e stdout no ex16,
`shift 2` no ex10...): todos foram detectados, cada um derrubando de 1 a 9
conferências.

## Como rodar cada exercício

### 1. `ex1_banner_hora.sh` — `banner $(date | cut -c13-20)`
```bash
./ex1_banner_hora.sh
```
Executa a linha pedida no enunciado e, antes dela, mostra uma régua de
colunas sobre a saída do `date` e o trecho exato que o `cut` recortou, para
dar para explicar o resultado. Saída real (C.UTF-8, às 15:49:06):

```
         1111111111222222222233333333334
1234567890123456789012345678901234567890
Mon Oct 19 15:49:06 -03 2026

cut -c13-20 -> '5:49:06 '

#######    #    #        #####     #      ###    #####
#         # #   #    #  #     #   # #    #   #  #     #
#          #    #    #  #     #    #    # #   # #
 #####          #######  ######         #  #  # ######
      #    #         #        #    #    #   # # #     #
#     #   # #        #  #     #   # #    #   #  #     #
 #####     #         #   #####     #      ###    #####
```

**Validações:** recusa argumentos (status 2); confere se o `banner` está
instalado e, se não estiver, diz qual pacote instalar (status 1).

**Racional:** o shell resolve a linha de dentro para fora. Primeiro executa
o que está em `$(...)` (slide 60): `date` imprime algo como
`Mon Oct 19 15:49:06 -03 2026`, e o pipe entrega isso ao `cut -c13-20`, que
guarda só os caracteres das colunas 13 a 20. Pela régua dá para ver que a
hora começa na coluna **12**, não na 13 — então o recorte perde o primeiro
dígito da hora e ainda pega o espaço depois dos segundos: `'5:49:06 '`. Em
seguida o shell substitui `$(...)` por esse texto e, como ele **não está
entre aspas**, separa o resultado em palavras usando o `IFS` (slides 29-30):
o espaço do final some e o `banner` recebe um único argumento, `5:49:06`,
que ele desenha em letras grandes com `#`. Ou seja: a intenção da linha é
mostrar a hora atual em letras grandes, mas recortar por posição fixa é
frágil — depende do formato padrão do `date`, que muda conforme o locale
(`LC_TIME`); em outro idioma a hora fica em outra posição e o recorte pega
outra coisa. A forma robusta é pedir o formato ao próprio `date`:
`banner $(date +%H:%M:%S)`. Detalhe extra: no PDF o comando aparece como
`cut –c13-20`, com um travessão (–) no lugar do hífen (autocorreção do
editor de texto); copiado assim, o `cut` não reconhece a opção e falha com
`cut: you must specify a list of bytes, characters, or fields`. O script
usa o hífen normal. A linha `# shellcheck disable=SC2046` existe porque o
`shellcheck` avisa justamente sobre o `$(...)` sem aspas — aqui ele é
proposital, é a linha do enunciado.

### 2. `ex2_data_e_arquivos.sh` — data de hoje e arquivos da conta
```bash
./ex2_data_e_arquivos.sh
```
Mostra a data de hoje (`Hoje é 19/10/2026`) e lista todos os arquivos do
diretório pessoal, inclusive os ocultos.

**Validações:** recusa argumentos (status 2); confere que `$HOME` está
definida, existe, é um diretório e pode ser listada (permissões `r` e `x`)
(status 1).

**Racional:** "arquivos da sua conta" são os do diretório pessoal, que fica
em `$HOME` (slide 28) — usar a variável em vez de escrever `/home/usuario`
faz o script funcionar para qualquer usuário. O `-a` do `ls` é necessário
porque, sem ele, o `ls` esconde os arquivos que começam com ponto
(`.bashrc`, `.profile`, `.ssh/`...), que são justamente boa parte dos
arquivos de uma conta; o `-l` mostra dono, tamanho e data. A data usa
`date '+%d/%m/%Y'` (formatadores do item 27 do material de apoio) para sair
no formato brasileiro em vez do formato padrão em inglês. A listagem não é
recursiva de propósito: `ls -laR "$HOME"` numa conta real gera milhares de
linhas.

### 3. `ex3_arquivo_existe.sh` — testa se um arquivo existe
```bash
./ex3_arquivo_existe.sh testes/texto.txt        # existe (status 0)
./ex3_arquivo_existe.sh testes/nao_existe.txt   # não existe (status 1)
./ex3_arquivo_existe.sh testes/link_quebrado    # link quebrado (status 1)
```
Informa se o arquivo passado na linha de comando existe. O status de saída
também reflete a resposta (0 = existe), para o script poder ser usado
dentro de um `if` em outro script.

**Validações:** exatamente um argumento, e não vazio (status 2). O status
de saída é a própria resposta: 0 = existe, 1 = não existe ou link quebrado.

**Racional:** o teste é `[ -e "$1" ]` (slide 35). `-e` e não `-f`, porque
`-f` só é verdadeiro para arquivo regular — um diretório existe, mas
falharia no `-f`. As aspas em `"$1"` são obrigatórias, e por dois motivos
diferentes: com um nome com espaço, `[ -e $1 ]` vira `[ -e meu arquivo.txt ]`
e o `[` reclama `binary operator expected`; e com uma variável vazia, pior
ainda, `[ -e $v ]` vira `[ -e ]`, que é **verdadeiro** — com um único
argumento, o `test` só verifica se aquela string não é vazia, e `-e` não é
vazia. É uma variação do problema do slide 40. O caso do link quebrado
mostra outra sutileza: `-e` segue links simbólicos, então para um link que
aponta para um arquivo inexistente ele responde "não existe", mesmo o link
estando lá no diretório. O script usa `-L` (testa o link em si) para
distinguir esse caso.

### 4. `ex4_maior_que_100.sh` — o arquivo tem mais de 100 bytes?
```bash
./ex4_maior_que_100.sh testes/tamanho_100.txt   # 100 bytes: não é maior que 100
./ex4_maior_que_100.sh testes/tamanho_101.txt   # 101 bytes: é maior que 100
```
Se o arquivo existir, mostra o tamanho e diz se ele passa de 100 bytes.

**Validações:** exatamente um argumento, e não vazio (status 2); o arquivo
precisa existir (link quebrado tem mensagem própria) e não pode ser um
diretório, cujo "tamanho" no `stat` não é o do conteúdo; e o valor
devolvido pelo `stat` é conferido como número antes da comparação
(status 1).

**Racional:** o tamanho vem de `stat -L -c %s`, como o enunciado sugere
(`%s` = tamanho em bytes). O `-L` faz o `stat` seguir links simbólicos:
sem ele, o `stat` de um link devolve o tamanho **do link** (a quantidade de
caracteres do caminho para onde ele aponta), não do arquivo — e o teste
`-e` usado antes já segue links, então os dois ficam coerentes. A
comparação tem que ser `-gt` (comparação aritmética, slide 34), nunca `>`:
dentro de `[ ]`, o `>` é um redirecionamento, então `[ $tamanho > 100 ]`
cria um arquivo vazio chamado `100` e o teste vira "a string não é vazia",
que é sempre verdadeiro. Os dois arquivos de teste ficam exatamente na
fronteira: "maior que 100" é estrito, então 100 bytes dá "não" e 101 dá
"sim". A existência é testada antes do `stat` porque o enunciado diz "caso
exista" — e para não deixar o `stat` imprimir o erro dele.

### 5. `ex5_contar_processos.sh` — quantos processos estão rodando
```bash
./ex5_contar_processos.sh
```
Mostra o número de processos em execução contando o próprio script e o
número sem ele.

**Validações:** recusa argumentos (status 2); confere que `/proc` existe
(não existe fora do Linux) e que a contagem achou pelo menos um processo,
o próprio script (status 1). O `shopt -s nullglob` faz um padrão sem
correspondência virar uma lista vazia; sem ele, o bash deixaria o texto
`/proc/[0-9]*` na lista e a contagem daria 1 em vez de acusar o problema.

**Racional:** cada processo em execução tem um diretório `/proc/<PID>`
(o mesmo `/proc` usado no `ex2_przombies` da Lista 3 — e é de lá que o
próprio `ps` lê). O padrão `/proc/[0-9]*` (wildcard `[set]`, slide 17)
casa só esses diretórios numéricos, e quem expande o padrão é o próprio
bash, guardando o resultado num vetor (itens 39-45 do material de apoio);
`${#processos[@]}` dá a quantidade de elementos. A vantagem é que **nenhum
processo novo é criado durante a contagem**: o único processo "do script"
que entra na conta é o próprio bash que roda o script — o aviso do
enunciado —, então basta subtrair 1 com `$(( ))`. A solução ingênua,
`total=$(ps -e | wc -l)` dentro do script, erra de vários jeitos ao mesmo
tempo: conta a linha de cabeçalho do `ps`, e conta também o próprio `ps`,
o `wc` e o subshell criado pelo `$(...)` — processos que só existem porque
o script está contando. Dá para ver o efeito logo depois de rodar o
script: no terminal, `ps -e --no-headers | wc -l` dá 2 a mais que o número
"sem contar este script" (o próprio `ps` e o `wc`), e `ps -e | wc -l`, sem
o `--no-headers`, dá 3 a mais.

### 6. `ex6_calendario.sh` — calendário de um mês/ano
```bash
./ex6_calendario.sh
# Mês (1-12): 10
# Ano (ex.: 2026): 2026
```
Pergunta o mês e o ano e mostra o calendário com o `cal`. Para testar sem
digitar: `printf '10\n2026\n' | ./ex6_calendario.sh`.

**Validações:** recusa argumentos (status 2); confere se o `cal` está
instalado antes de perguntar; acusa a entrada que termina antes do mês ou
do ano (Ctrl+D, ou pipe com menos linhas), mas aceita a última linha sem
`\n`; o mês tem que ser de 1 a 12 (com ou sem zero à esquerda) e o ano só
dígitos, no máximo 4, de 1 a 9999 (todos status 1).

**Racional:** os valores são lidos com `read` (slide 25; `-p` mostra o
texto da pergunta e `-r` não deixa a `\` ser interpretada). Antes de chamar
o `cal`, as entradas são validadas com `case` (slides 45-47): o mês tem que
casar com `[1-9] | 0[1-9] | 1[0-2]` (aceita `9` e `09`) e o ano não pode ser
vazio nem ter caractere que não seja dígito (`'' | *[!0-9]*`), além de
estar entre 1 e 9999 (limite do `cal`). Validar importa por causa de como o
`cal` interpreta os argumentos: com um argumento só, `cal 10` mostra o
**ano 10** inteiro, não outubro; e o ano é sempre literal, então `cal 10 26`
mostra outubro do ano 26 d.C., não de 2026 — por isso a pergunta dá o
exemplo com quatro dígitos. Curiosidade para testar: `cal 9 1752` mostra um
setembro com os dias 3 a 13 faltando, que é quando o calendário gregoriano
foi adotado na Inglaterra e colônias — o `cal` calcula o calendário
histórico de verdade.

### 7. `ex7_renomear_mpeg3.sh` — `.mpeg3` → `.mp3` num diretório
```bash
cp -r testes/musicas_modelo /tmp/musicas    # faça uma cópia, o script renomeia de verdade!
./ex7_renomear_mpeg3.sh /tmp/musicas
ls /tmp/musicas
```
⚠️ Este script **altera o diretório passado** — rode sempre numa cópia de
`testes/musicas_modelo`. Com o modelo, o resultado esperado é: 3 arquivos
renomeados (`faixa01`, `faixa02` e `minha musica`), `ja_existe.mpeg3`
pulado com aviso (porque `ja_existe.mp3` já existe), e `notas.mpeg3.txt` e
`letra.txt` intocados. A última linha da saída é
`3 arquivo(s) renomeado(s), 1 pulado(s).`

**Validações:** exatamente um argumento, e não vazio (status 2); o
diretório precisa existir, ser um diretório e ter permissão de escrita e de
acesso (`w` e `x`), porque renomear altera o diretório, não o arquivo
(status 1). Durante o laço: só arquivos comuns são renomeados (um
diretório chamado `algo.mpeg3` fica como está), um `.mp3` existente nunca é
sobrescrito, e se algum `mv` falhar o script termina com status 1.

**Racional:** o laço é `for arquivo in "$dir"/*.mpeg3` — quem gera a lista
é a expansão de wildcard do shell (slide 17), e cada nome expandido vira
**uma** palavra, mesmo com espaço. É por isso que não dá para usar o
`for file in $(ls ...)` do slide 42 aqui: a saída do `$(ls)` é separada nos
espaços, e `minha musica.mpeg3` viraria duas "palavras", `minha` e
`musica.mpeg3`, nenhuma delas um arquivo. O novo nome é
`${arquivo%.mpeg3}.mp3`: o `%` remove o sufixo **só do final** (item 8 do
material de apoio), então mesmo um nome como `x.mpeg3.mpeg3` só perde a
última extensão. Três detalhes: quando nenhum arquivo casa com o padrão, o
bash deixa o próprio texto `dir/*.mpeg3` no laço, e o
`[ -e "$arquivo" ] || continue` evita tentar renomear um arquivo que não
existe; o `mv` sobrescreveria sem avisar um `.mp3` que já existisse, então
o script testa antes e pula; e o `--` no `mv` impede que um arquivo cujo
nome comece com `-` seja lido como opção.

### 8. `ex8_renomear_interativo.sh` — o mesmo, perguntando tudo
```bash
cp -r testes/musicas_modelo /tmp/musicas8   # de novo: sempre numa cópia
./ex8_renomear_interativo.sh
# Diretório: /tmp/musicas8
# Extensão atual (ex.: mpeg3): mpeg3
# Nova extensão (ex.: mp3): ogg
```
Pergunta o diretório, a extensão atual e a nova, e renomeia como o ex7.
Para testar sem digitar:
`printf '/tmp/musicas8\nmpeg3\nogg\n' | ./ex8_renomear_interativo.sh`
(aqui são 4 renomeados, porque não existe `ja_existe.ogg` para colidir).

**Validações:** recusa argumentos (status 2); acusa a entrada que termina
antes de cada uma das três respostas; o diretório não pode ser vazio e tem
que existir, ser diretório e ter permissão `w` e `x`; as extensões não
podem ser vazias (nem só um ponto) nem conter `/` (todos status 1).
Extensões iguais não são erro: o script avisa que não há o que fazer e sai
com status 0. Durante o laço, as mesmas garantias do ex7.

**Racional:** a lógica de renomear é a mesma do ex7; o que muda é que agora
os três valores vêm do `read`, e texto digitado pelo usuário precisa de
tratamentos que um argumento de linha de comando não precisa. O til: se o
usuário digita `~/musicas`, o `read` entrega o texto literal com `~` — a
expansão do til só acontece quando ele aparece digitado na linha de
comando —, então o script troca o `~` inicial por `$HOME` com
`${dir/#\~/$HOME}` (item 11 do material de apoio). O ponto: `${ext#.}`
remove um ponto inicial, então tanto `mpeg3` quanto `.mpeg3` funcionam. E a
extensão entra no padrão **entre aspas** (`*."$ext_antiga"`): sem aspas, se
o usuário digitasse `*` como extensão, o padrão viraria `*.*` e o script
renomearia todos os arquivos com ponto no nome; com aspas, o `*` digitado é
procurado literalmente e nada acontece. Extensões vazias ou iguais são
recusadas antes do laço.

### 9. `ex9_linhas_palavras.sh` — linhas e palavras de um arquivo
```bash
./ex9_linhas_palavras.sh testes/texto.txt             # Linhas: 5, Palavras: 24
./ex9_linhas_palavras.sh testes/sem_quebra_final.txt  # Linhas: 3, Palavras: 10 (wc -l diria 2)
```
Mostra o número de linhas e de palavras do arquivo.

**Validações:** exatamente um argumento, e não vazio (status 2); o arquivo
precisa existir, ser um arquivo comum (não diretório nem dispositivo) e ter
permissão de leitura, cada caso com sua mensagem (status 1).

**Racional:** a contagem é do `wc`, mas com dois cuidados. Primeiro, o
arquivo é passado com redirecionamento de entrada, `wc -l < arquivo`
(slide 15): assim o `wc` lê do `stdin`, não sabe o nome do arquivo e
imprime só o número — `wc -l arquivo` imprimiria `5 testes/texto.txt` e
seria preciso recortar o nome depois. Segundo, o `wc -l` não conta linhas,
conta caracteres `\n`: se a última linha não terminar com quebra de linha
(comum em arquivos salvos por alguns editores), ela não é contada — o
`sem_quebra_final.txt` tem 3 linhas e o `wc -l` diz 2. O script corrige
isso olhando o último byte com `tail -c 1`: como `$(...)` remove os `\n`
do final da saída, o resultado só é vazio se o último byte for `\n`; se não
for vazio, soma 1. O `-s` evita somar 1 num arquivo vazio. Já o `wc -w`
conta sequências separadas por qualquer espaço em branco, por isso os
vários espaços seguidos e o TAB do `texto.txt` não geram palavras a mais
(e `ordem.`, com o ponto, conta como uma palavra só).

### 10. `ex10_listar_argumentos.sh` — todos os argumentos numerados
```bash
./ex10_listar_argumentos.sh a b c d e f g h i j k "l com espaço"
```
Imprime `1: a`, `2: b`, ..., `10: j`, `11: k`, `12: l com espaço`.

**Validações:** pelo menos um argumento (status 2). Um argumento vazio
(`""`) é aceito e listado como `1: `, porque é um argumento de verdade. A
impressão usa `printf '%d: %s\n'` em vez de `echo`, para cada argumento sair
exatamente como veio (`-n`, `\t` e `$HOME` aparecem literalmente).

**Racional:** o laço é `while [ $# -gt 0 ]` com `shift` (slide 59): cada
`shift` descarta o `$1` e "anda" com os outros (`$2` vira `$1`, `$3` vira
`$2`...), diminuindo o `$#`. Assim o script sempre imprime `$1` e nunca
precisa escrever `$10`. Essa é a pegadinha que o enunciado aponta ao dizer
que acima de 9 o `shift` será necessário: o shell lê `$10` como `$1`
seguido do caractere `0`. Com os mesmos argumentos acima, `$10` daria `a0`,
não `j`. O bash aceita `${10}` com chaves (item 23 do material de apoio),
mas o `shift` funciona em qualquer `sh` e é o que o enunciado pede. O
`"$1"` entre aspas mantém `l com espaço` como um argumento só, e o contador
usa `$(( ))` como no slide 43.

### 11. `ex11_usuarios_ordenados.sh` — usuários em ordem alfabética
```bash
./ex11_usuarios_ordenados.sh                          # usa o /etc/passwd da máquina
./ex11_usuarios_ordenados.sh testes/passwd_exemplo    # arquivo de teste
```
Com o arquivo de teste, a saída esperada é exatamente:
`ana backup beatriz bin carlos daemon marcos root sync www-data` (um por
linha).

**Validações:** no máximo um argumento, e não vazio — um `""` não cai
silenciosamente no `/etc/passwd` (status 2); o arquivo precisa existir,
ser um arquivo comum, legível e não vazio (status 1). Só entram linhas com
exatamente 7 campos: as outras são ignoradas, com um aviso no stderr
dizendo quantas eram, e um arquivo sem nenhuma linha válida é recusado
(status 1).

**Racional:** cada linha do `/etc/passwd` tem 7 campos separados por `:`, e
o primeiro é o nome do usuário. `cut -d: -f1` extrai esse campo e `sort`
ordena, num pipe (slide 16). O enunciado sugere `cat /etc/passwd | ...`,
que dá o mesmo resultado; o script passa o arquivo direto para o `cut`
porque ele já sabe ler arquivos — o `cat` só acrescentaria um processo a
mais no pipe. O argumento opcional existe para testar contra um arquivo
fixo e ter uma saída previsível; sem argumento, usa o `/etc/passwd` real.
(Usuários vindos de rede, como LDAP, não aparecem no `/etc/passwd` — para
incluí-los seria `getent passwd`.)

### 12. `ex12_shells_unicos.sh` — shells sem repetição
```bash
./ex12_shells_unicos.sh                          # usa o /etc/passwd da máquina
./ex12_shells_unicos.sh testes/passwd_exemplo    # arquivo de teste
```
Com o arquivo de teste, a saída esperada é `/bin/bash`, `/bin/sh`,
`/bin/sync`, `/bin/zsh` e `/usr/sbin/nologin`.

**Validações:** as mesmas do ex11. Além disso, um campo de shell vazio
vira `/bin/sh`: pelo manual do passwd (`man 5 passwd`), é esse o shell
usado quando o campo está vazio. Sem esse tratamento, a saída teria uma
linha em branco.

**Racional:** o shell é o 7º campo (`cut -d: -f7`). A pegadinha está na
dica do enunciado: o `uniq` só remove linhas repetidas **vizinhas**. No
`passwd_exemplo` os shells repetidos estão espalhados de propósito, e
`cut -d: -f7 testes/passwd_exemplo | uniq` imprime as 10 linhas, sem
remover nada. É preciso ordenar antes com `sort` para as linhas iguais
ficarem juntas, e só então o `uniq` funciona (`sort -u` faz as duas coisas
de uma vez).

### 13. `ex13_criar_diretorios.sh` — `dir1..dir5` com `file1..file3`
```bash
./ex13_criar_diretorios.sh /tmp/ex13      # sem argumento, cria no diretório atual
find /tmp/ex13 -mindepth 1 | sort
```
Cria `dir1` a `dir5` e, dentro de cada um, `file1` a `file3`: 5 diretórios
e 15 arquivos.

**Validações:** no máximo um argumento, e não vazio (status 2); se a base
já existir, precisa ser um diretório com permissão `w` e `x` (status 1).
Cada `mkdir` e `touch` é conferido, e o script também detecta os conflitos
de nome: um `dir1` que já existe como arquivo, ou um `file1` que já existe
como diretório (o `touch` "daria certo" nesse caso, mas o resultado não
seria um arquivo).

**Racional:** são dois `for` aninhados (slide 36), o de fora para `n` de 1
a 5 e o de dentro para `m` de 1 a 3, com a lista de valores vindo de
`$(seq 1 5)` — o mesmo `values = $(command)` do slide 42. Os diretórios são
criados com `mkdir -p`, que não dá erro se o diretório já existe e cria os
diretórios intermediários (inclusive o diretório-base, se faltar); isso
torna o script idempotente: rodar duas vezes não falha nem duplica nada. O
`touch` cria o arquivo vazio (slide 8: "verifica se existe arquivo, senão
cria"). O diretório-base é um argumento opcional para o teste não espalhar
`dir1`...`dir5` dentro do repositório.

### 14. `ex14_repositorio_ideias.sh` — repositório de ideias em `/ideias.txt`
```bash
IDEIAS=/tmp/ideias.txt ./ex14_repositorio_ideias.sh Fazer script para remover usuários
IDEIAS=/tmp/ideias.txt ./ex14_repositorio_ideias.sh Estudar o comando trap
cat /tmp/ideias.txt
```
Acrescenta a ideia ao arquivo, no formato do enunciado
(`19/10/2026 15:49 Fazer script para remover usuários`). Sem a variável
`IDEIAS`, usa `/ideias.txt`, como pede o enunciado.

**Validações:** pelo menos uma palavra, e a ideia não pode ser só espaços
(status 2). Cada ideia ocupa uma linha só: quebras de linha dentro do texto
viram espaço. O destino não pode ser um diretório, e qualquer falha de
escrita é informada com o motivo do sistema e a forma de liberar o arquivo
(status 1).

**Racional:** três decisões. A gravação usa `>>` (slide 12): com `>`, cada
ideia nova apagaria todas as anteriores (o "CUIDADO!!!" do slide 10). A
ideia é `$*`, todos os parâmetros juntos numa string só (slide 30), então
dá para digitar a frase sem aspas — com `$1`, o exemplo acima gravaria só
`Fazer`. E o formato `date '+%d/%m/%Y %H:%M'` reproduz exatamente o do
exemplo (`30/08/2008 10:21`). A pegadinha do enunciado é o caminho:
`/ideias.txt` fica na raiz do sistema, onde só o root pode criar arquivos,
então para um usuário comum o script falha com `Permission denied` (o
próprio bash imprime o erro, como o `perror()`, e o script acrescenta como
resolver). Há duas saídas: criar o arquivo uma vez como root e passá-lo
para o usuário, `sudo touch /ideias.txt && sudo chown "$USER" /ideias.txt`
— daí em diante o script funciona sem `sudo`, porque acrescentar a um
arquivo só exige permissão de escrita **no arquivo**, não no diretório `/`
—, ou apontar a variável `IDEIAS` para outro arquivo, como nos testes.

### 15. `ex15_espaco_diretorios.sh` — espaço de cada diretório, em ordem
```bash
./ex15_espaco_diretorios.sh                          # usa o $HOME (pode demorar numa conta grande)
./ex15_espaco_diretorios.sh testes/conta_exemplo     # arquivo de teste
```
Saída real com o diretório de teste (ext4):

```
KB	Diretório
4	testes/conta_exemplo/vazio
8	testes/conta_exemplo/pequeno
24	testes/conta_exemplo/medio
44	testes/conta_exemplo/.oculto
64	testes/conta_exemplo/grande
```

**Validações:** no máximo um argumento, e não vazio (status 2); sem
argumento, a variável `HOME` precisa estar definida; a base precisa
existir, ser um diretório e ter permissão `r` e `x` (status 1). Uma base
sem subdiretórios não é erro: o script avisa `(nenhum subdiretório em ...)`
e sai com status 0. Links simbólicos para diretórios não são medidos, para
nada ser contado duas vezes (nem algo de fora da conta).

**Racional:** `du -sk` mede o espaço em disco de cada diretório,
resumido (`-s`, um total por diretório em vez de listar cada
subdiretório) e em KB (`-k`), e `sort -n` ordena numericamente. Usar KB
fixo é o que permite o `sort -n`: com `du -h` os tamanhos saem como
`512K`, `20M`, `1.2G`, e o `sort -n` olha só a parte numérica e coloca
`1.2G` antes de `20M` (seria preciso `sort -h`). A outra pegadinha é como
listar "cada diretório da conta": `du -sk ~/*` ignora os diretórios
ocultos (`.cache`, `.local`, `.config`...), que costumam ser os maiores da
conta, porque o `*` não casa com nomes que começam com ponto. O
`find "$base" -mindepth 1 -maxdepth 1 -type d` lista todos os
subdiretórios imediatos, ocultos inclusive, e o `-exec du -sk {} +` os
entrega ao `du`. No teste, o `.oculto/` aparece entre `medio` e `grande` —
com o `*` ele simplesmente não estaria na lista. Os valores são de espaço
em disco, não de tamanho do conteúdo: o arquivo de 2 KB ocupa um bloco de
4 KB e o próprio diretório ocupa mais 4 KB, por isso `pequeno` dá 8. Em
outro sistema de arquivos os números podem mudar, mas a ordem não.

### 16. `ex16_buscar_meus_arquivos.sh` — `find` com saída e erros separados
```bash
./ex16_buscar_meus_arquivos.sh              # a partir de /, como pede o enunciado (demora)
./ex16_buscar_meus_arquivos.sh /etc         # versão rápida para testar
cat arq.txt erros.txt
make clean                                  # apaga arq.txt e erros.txt
```
Procura, a partir de `/`, os arquivos que pertencem ao usuário, mandando a
lista para `arq.txt` e as mensagens de erro para `erros.txt` (no diretório
atual), e mostra quantas linhas foram para cada um.

Teste verificável, com um diretório sem permissão de leitura:

```bash
mkdir -p /tmp/ex16/aberto /tmp/ex16/fechado && touch /tmp/ex16/aberto/meu.txt
chmod 000 /tmp/ex16/fechado
./ex16_buscar_meus_arquivos.sh /tmp/ex16     # 4 em arq.txt, 1 em erros.txt
cat arq.txt erros.txt
chmod 755 /tmp/ex16/fechado && rm -r /tmp/ex16
```

**Validações:** no máximo um argumento, e não vazio (status 2); o ponto de
partida precisa existir e ser um diretório; e, como `arq.txt` e
`erros.txt` são criados no diretório atual, o script confere antes que dá
para escrever nele e sobrescrever os arquivos de uma execução anterior
(status 1). Os erros de permissão do `find` não são falha do script: eles
são o conteúdo esperado do `erros.txt`.

**Racional:** é o exemplo do slide 14 aplicado ao `find`:
`find "$inicio" -user "$usuario" > arq.txt 2> erros.txt`. O `>` redireciona
o descritor 1 (`stdout`, os caminhos encontrados) e o `2>` redireciona o
descritor 2 (`stderr`, os `Permission denied` dos diretórios de outros
usuários e do sistema), então a tela fica limpa e cada coisa vai para o
seu arquivo. O usuário vem de `id -un`, e não de `$USER`, porque a
variável pode não estar definida em alguns contextos (`cron`, `su`). O
`find` termina com status diferente de 0 quando encontra erros de
permissão, o que aqui é esperado e não é tratado como falha. Duas
observações de quem rodou a partir de `/` de verdade: a busca inclui o
`/proc`, onde cada processo do usuário tem um diretório com dezenas de
arquivos virtuais que pertencem a ele (num teste de 25 segundos, cerca de
38 mil das 47 mil linhas de `arq.txt` eram do `/proc`), e processos que
terminam durante a busca geram erros `No such file or directory` — para
ignorar o `/proc` seria
`find / -path /proc -prune -o -user "$usuario" -print`. E no WSL o `/`
inclui `/mnt/c` (o disco do Windows), cujos arquivos aparecem como sendo
do usuário, o que deixa a busca completa muito longa; por isso o script
aceita um diretório inicial opcional para testes.

## Exemplo rápido de teste

O mesmo roteiro do "Início rápido", com as pegadinhas comentadas acima
lado a lado com a solução:

```bash
cd lista04
make
./testes/rodar_testes.sh 4 12 14    # testes automáticos só de alguns exercícios
T=$(mktemp -d)

./ex1_banner_hora.sh
banner $(date +%H:%M:%S)                                   # forma robusta, sem recorte por posição

./ex3_arquivo_existe.sh testes/link_quebrado
v=""; [ -e $v ] && echo "sem aspas, [ -e ] é verdadeiro!"   # pegadinha das aspas

./ex4_maior_que_100.sh testes/tamanho_100.txt
./ex4_maior_que_100.sh testes/tamanho_101.txt

./ex5_contar_processos.sh; ps -e --no-headers | wc -l       # o ps conta ele mesmo e o wc: 2 a mais

printf '10\n2026\n' | ./ex6_calendario.sh
cal 9 1752                                                 # curiosidade: a troca de calendário

cp -r testes/musicas_modelo "$T/ex7" && ./ex7_renomear_mpeg3.sh "$T/ex7" && ls "$T/ex7"
cp -r testes/musicas_modelo "$T/ex8" && printf '%s\n.mpeg3\nogg\n' "$T/ex8" | ./ex8_renomear_interativo.sh

./ex9_linhas_palavras.sh testes/sem_quebra_final.txt; wc -l < testes/sem_quebra_final.txt

./ex10_listar_argumentos.sh a b c d e f g h i j k "l com espaço"
set -- a b c d e f g h i j; echo "\$10 = $10, \${10} = ${10}"    # a0 vs j

./ex11_usuarios_ordenados.sh testes/passwd_exemplo
./ex12_shells_unicos.sh testes/passwd_exemplo
cut -d: -f7 testes/passwd_exemplo | uniq                    # sem sort: nada é removido

./ex13_criar_diretorios.sh "$T/ex13" && find "$T/ex13" -type f | wc -l    # 15

IDEIAS="$T/ideias.txt" ./ex14_repositorio_ideias.sh Fazer script para remover usuários
IDEIAS="$T/ideias.txt" ./ex14_repositorio_ideias.sh Estudar o comando trap
cat "$T/ideias.txt"
./ex14_repositorio_ideias.sh Testar o /ideias.txt           # Permission denied, até o arquivo ser liberado

./ex15_espaco_diretorios.sh testes/conta_exemplo
du -sk testes/conta_exemplo/*                               # sem o .oculto

./ex16_buscar_meus_arquivos.sh /etc && cat erros.txt

rm -rf "$T" && make clean
```
