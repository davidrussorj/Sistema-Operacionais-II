# Lista 3 - Processos e comandos afins

Exercícios da disciplina Tópicos Especiais em Sistemas Computacionais I / SO 2.

Base teórica: **Aula 08 - Processos** (slides 26-43 e 45-59).

## Base teórica (Aula 08)

### fork() — criação de processos (slides 26-31)

```c
#include <sys/types.h>
#include <unistd.h>
pid_t fork(void);
```

`fork()` cria um processo filho que é uma cópia do pai (mesmo código, memória
duplicada, arquivos abertos preservados). A chamada retorna **duas vezes**:
`0` no filho e o PID do filho no pai (ou `-1` se falhar). O padrão de uso é
sempre o mesmo switch mostrado no slide:

```c
pid_t newpid = fork();
switch (newpid) {
    case -1: /* fork falhou */ break;
    case 0:  /* código do filho */ break;
    default: /* código do pai, newpid = PID do filho */ break;
}
```

O `ex1_gerador_zumbis` usa exatamente esse padrão duas vezes: um primeiro
`fork()` para passar para background (o pai original sai com `exit(0)`), e
depois um `fork()` por zumbi a ser criado.

### exit, wait e o processo zumbie (slides 35-38)

Quando um processo termina (`exit`), ele **não desaparece imediatamente**: o
kernel mantém seu código de saída guardado até que o processo pai chame
`wait()` e o colete. Nesse intervalo o processo morto vira um **zombie**
(zumbie) — não consome CPU nem memória de dados, mas ainda ocupa uma entrada
na tabela de processos, com PID e PPID visíveis. O slide 38 resume isso: "o
filho não está mais ativo, processo zombie. Seu código de saída está
armazenado e pode ser usado pelo pai num wait posterior."

É exatamente essa situação que o `ex1_gerador_zumbis` provoca de propósito:
os filhos chamam `exit(0)` e o processo pai (que continua vivo, preso num
laço `pause()`) nunca chama `wait()` — por isso os filhos ficam para sempre
como zumbies até o pai morrer ou o sistema ser reiniciado.

### signal / sigaction — capturando e ignorando sinais (slides 45-59)

```c
#include <signal.h>
void (*signal(int sig, void (*func)(int)))(int);
int sigaction(int sig, const struct sigaction *act, struct sigaction *oact);
```

Um sinal pode ser capturado (executa uma função handler), ignorado
(`SIG_IGN`) ou deixado no comportamento padrão (`SIG_DFL`). O slide 48 é
explícito: recebendo `SIGKILL` o processo termina **sempre**, sem poder
capturar ou ignorar — é o único sinal para o qual não existe proteção
possível. Todos os demais sinais catalogados nos slides 47-49 (`SIGHUP`,
`SIGINT`, `SIGQUIT`, `SIGUSR1`, `SIGUSR2` etc.) podem ser ignorados com
`SIG_IGN`.

O `ex2_przombies` usa isso diretamente: instala um handler próprio só para
`SIGTERM` (que escreve no log e termina o daemon de forma controlada) e
ignora (`SIG_IGN`) todos os demais sinais que podem ser ignorados, deixando
o processo "invulnerável" a qualquer coisa que não seja `SIGKILL`, exatamente
como pede o enunciado.

### /proc — inspecionando processos sem usar ps (mencionado no enunciado)

O enunciado sugere duas formas de achar zumbies: rodar `ps` como filho via
pipe, ou varrer `/proc` com `opendir`/`readdir`/`closedir` (já vistos na
Aula 06) e ler o arquivo `status` de cada subdiretório numérico (`/proc/<pid>/status`),
que traz `Name`, `State` e `PPid` em texto simples. O `ex2_przombies` usa a
segunda abordagem, por não depender de criar um processo filho (`ps`) nem de
`popen`/pipe a cada varredura.

## Início rápido

```bash
cd lista03
make                        # compila os dois programas
./ex2_przombies 2 &         # nao precisa do "&": o proprio programa daemoniza-se
./ex1_gerador_zumbis 3      # cria 3 zumbies para o daemon detectar
sleep 5
cat przombies.log           # ve os zumbies logados
kill -TERM $(pgrep -f '^\./ex2_przombies 2$')   # finaliza o daemon
cat przombies.log           # ve a mensagem final de SIGTERM
```

## Como compilar

Dentro da pasta `lista03/`, rode:

```bash
make
```

Isso gera `ex1_gerador_zumbis` e `ex2_przombies`.

Para limpar os binários gerados:

```bash
make clean
```

## Arquivos de teste

Esse exercício não depende de arquivos de entrada estáticos (o "dado de
teste" são processos zumbies, criados em tempo de execução). Por isso
`testes/` traz um script que automatiza a demonstração ponta a ponta:

| Arquivo | Para que serve |
|---|---|
| `testes/rodar_teste.sh` | Sobe o `ex2_przombies`, gera zumbies com `ex1_gerador_zumbis`, espera dois ciclos de varredura, mostra o log, envia `SIGTERM` no daemon e mostra o log final (com a mensagem de finalização). |

## Como rodar cada exercício

### 1. `ex1_gerador_zumbis` — programa auxiliar para criar zumbies
```bash
./ex1_gerador_zumbis 3
```
Cria 3 processos zumbies de propósito, para servir de teste ao `ex2_przombies`. É o programa de exemplo dado no próprio enunciado da lista.

**Racional:** o programa faz `fork()` duas vezes: o primeiro só para passar para background (o processo original sai com `exit(0)` e devolve o prompt ao shell); o segundo, dentro de um laço `while (n-- > 0)`, cria `n` filhos que morrem imediatamente com `exit(0)`. O processo intermediário (que ficou em background) nunca chama `wait()` — só fica preso num `for (;;) pause();` — então cada filho morto vira um zumbie e permanece assim indefinidamente, esperando um `wait()` que nunca vem. É esse comportamento proposital que dá ao `ex2_przombies` algo para detectar.

### 2. `ex2_przombies` — daemon que loga processos zumbies
```bash
./ex2_przombies 2
```
Vira um daemon (faz `fork()` e o processo original sai, devolvendo o prompt), e a cada `N` segundos (aqui, 2) varre `/proc`, identifica processos com `State: Z` e grava `PID PPID Nome` em `przombies.log`, no diretório onde o programa foi iniciado.

**Racional:** a varredura usa `opendir("/proc")` + `readdir()` para listar as entradas, filtrando as que são só dígitos (subdiretórios de PID). Para cada PID candidato, abre `/proc/<pid>/status` e lê os campos `Name`, `State` e `PPid` linha a linha — essa é a alternativa sugerida no próprio enunciado ao invés de rodar `ps` como filho via pipe, porque evita criar um processo novo a cada ciclo de varredura só para obter a informação. Um processo é considerado zumbie quando o campo `State` começa com `Z`. Para o `SIGTERM`, o handler (`trata_sigterm`) usa só `write()`, `close()` e `_exit()` — funções assíncronas seguras para uso dentro de um signal handler — em vez de `fprintf`/`exit()`, que não são seguras nesse contexto (podem corromper buffers de stdio se o sinal chegar no meio de outra chamada de I/O). Para todos os demais sinais que podem ser ignorados (todos exceto `SIGKILL` e `SIGSTOP`, que o próprio sistema nunca deixa capturar ou ignorar), o programa instala `SIG_IGN` num laço, tornando o daemon "invulnerável" como pede o enunciado — por exemplo, um `SIGHUP` disparado ao fechar o terminal que iniciou o daemon não o derruba.

## Exemplo rápido de teste (rodando tudo de uma vez)

```bash
make
./testes/rodar_teste.sh
```
