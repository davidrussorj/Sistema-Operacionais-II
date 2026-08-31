# Lista 1 - Exercícios sobre lseek, stat, fstat e lstat

Exercícios da disciplina Tópicos Especiais em Sistemas Computacionais I / SO 2.

## Como compilar

Dentro da pasta `lista01/`, rode:

```bash
make
```

Isso compila todos os `.c` e gera um executável para cada exercício (`ex1_tamanho`, `ex2_leitura_parcial`, etc).

Para limpar os binários gerados:

```bash
make clean
```

## Arquivos de teste

A pasta `testes/` já vem com arquivos prontos para rodar todos os exercícios sem precisar criar nada na mão:

| Arquivo | Para que serve |
|---|---|
| `testes/arquivo_teste.txt` | 300 bytes em 4 blocos de 75 (`AAAA...BBBB...CCCC...DDDD...`) — usado nos ex. 1, 2, 3, 5 e 8. Os blocos distintos deixam claro no ex2 que o `lseek()` realmente pulou o trecho do meio. |
| `testes/link_teste.txt` | Link simbólico para `arquivo_teste.txt` — usado nos ex. 4 e 8. |
| `testes/binario_teste.dat` | Arquivo binário de 20 bytes com exatamente **8 bytes nulos** — usado no ex. 6 (o resultado esperado é sempre 8/20). |
| `testes/arquivo_para_truncar.txt` | Arquivo de texto de 54 bytes, modelo para o ex. 7 (que é destrutivo — sempre copie antes de rodar). |
| `testes/subdir_teste/` | Diretório vazio (com um `.gitkeep`), útil para o ex. 8 mostrar o tipo "diretório". |

Todos os comandos abaixo assumem que você está dentro de `lista01/` e os binários já foram gerados com `make`.

## Como rodar cada exercício

### 1. `ex1_tamanho` — tamanho do arquivo com lseek()
```bash
./ex1_tamanho testes/arquivo_teste.txt
```
Abre o arquivo, usa `lseek(fd, 0, SEEK_END)` para ir ao final e imprime a posição (= tamanho em bytes).

**Racional:** `lseek()` retorna a nova posição do cursor após o deslocamento, não o conteúdo do arquivo. Como `SEEK_END` desloca a partir do final e o offset pedido é `0`, o cursor para exatamente na última posição válida — que numericamente é igual ao tamanho do arquivo em bytes. É a forma mais direta de obter o tamanho sem precisar de `stat()`, mas tem uma pegadinha: como efeito colateral, ela também move o cursor de leitura/escrita do arquivo, então se o programa fosse ler algo depois teria que dar `lseek(fd, 0, SEEK_SET)` para voltar ao início.

### 2. `ex2_leitura_parcial` — ler partes específicas do arquivo
```bash
./ex2_leitura_parcial testes/arquivo_teste.txt
```
Lê os primeiros 100 bytes, pula para o byte 200 com `lseek()` e lê mais 50 bytes. Com `arquivo_teste.txt`, os primeiros 100 bytes saem como `AAAA...BBBB` (75 A's + 25 B's) e os 50 bytes a partir do byte 200 saem como `CCCC...DDDD` (25 C's + 25 D's) — deixando visível que o trecho do meio (o resto dos B's) foi pulado.

**Racional:** o ponto do exercício é mostrar que `read()` sempre lê a partir da posição atual do cursor, e `lseek(fd, 200, SEEK_SET)` reposiciona esse cursor de forma absoluta (a partir do início do arquivo) sem precisar ler e descartar os bytes 100–199 no meio do caminho — diferente de simular o pulo com várias chamadas de `read()` até chegar lá. Isso é o que torna `lseek()` eficiente para acesso aleatório em arquivos: o custo é O(1), não depende da distância pulada. Os buffers têm tamanho `+1` (`buf1[101]`, `buf2[51]`) só para caber o `\0` de terminação de string ao usar `printf("%s", ...)`.

### 3. `ex3_stat` — informações do arquivo com stat()
```bash
./ex3_stat testes/arquivo_teste.txt
```
Mostra tamanho, número de links, UID do dono, permissões (rwx) e data/hora da última modificação.

**Racional:** `stat()` recebe um *caminho* (não um fd) e preenche uma `struct stat` com metadados que o sistema de arquivos guarda no inode — nada disso exige abrir o arquivo. As permissões (`st_mode`) vêm como uma máscara de bits; por isso a função `imprime_permissoes()` testa cada bit individualmente com `&` contra as constantes `S_IRUSR`, `S_IWUSR`, `S_IXUSR`, etc., montando a string `rwxrwxrwx` posição por posição — é o mesmo princípio usado pelo `ls -l` internamente. Para a data, `st_mtime` é um `time_t` (segundos desde a epoch), então precisa passar por `localtime()` + `strftime()` para virar uma data legível; usar o valor bruto não faria sentido para quem lê a saída.

### 4. `ex4_stat_lstat` — stat() vs lstat() em um link simbólico
```bash
./ex4_stat_lstat testes/link_teste.txt
```
`testes/link_teste.txt` já é um link simbólico pronto (aponta para `arquivo_teste.txt`). Mostra que `stat()` segue o link (retorna dados do arquivo real, 300 bytes) e `lstat()` retorna dados do link em si (17 bytes, tamanho do caminho `"arquivo_teste.txt"`).

**Racional:** a diferença entre as duas chamadas está em *o que* cada uma resolve. `stat()` segue (`dereference`) o link simbólico automaticamente — se o alvo também fosse outro link, `stat()` seguiria a cadeia inteira até achar o arquivo real — e por isso retorna o tamanho do arquivo apontado (`arquivo.txt`, no exemplo). Já `lstat()` para no próprio link: não segue nada, e o `st_size` retornado é o número de bytes do *caminho* armazenado dentro do link (o texto `"arquivo.txt"`, por exemplo, tem 11 caracteres). Essa distinção existe porque, sem `lstat()`, não haveria como inspecionar metadados do link em si (por exemplo, para detectar se algo é um link antes de decidir segui-lo, evitando loops de links simbólicos apontando um para o outro).

### 5. `ex5_fstat` — fstat() em um arquivo já aberto
```bash
./ex5_fstat testes/arquivo_teste.txt
```
Abre o arquivo, usa `fstat(fd, &buf)`, identifica o tipo (regular/diretório/link/etc) e compara com o resultado de `stat()` no mesmo caminho.

**Racional:** `fstat()` é essencialmente o mesmo `stat()`, mas opera sobre um *file descriptor* já aberto em vez de um caminho no sistema de arquivos. Isso importa em dois cenários que `stat()` sozinho não cobre bem: (1) evitar uma *race condition* conhecida como TOCTOU (time-of-check to time-of-use), onde o arquivo poderia ser trocado/removido entre um `stat()` no caminho e uma abertura posterior — com `fstat()` a consulta é sobre o arquivo que já está de fato aberto, garantido pelo próprio kernel; (2) quando o programa só tem o fd em mãos (por exemplo, recebido via `dup()` ou herdado de outro processo) e não tem mais o caminho original disponível. O tipo do arquivo é identificado com as macros `S_ISREG`, `S_ISDIR`, `S_ISLNK` etc., que testam bits específicos de `st_mode` — a mesma máscara usada nas permissões, mas em outra faixa de bits. Como `open()` sem `O_NOFOLLOW` segue links por padrão, o fd nunca aponta para um link em si, por isso `fstat()` e `stat()` batem (mesmo inode) neste exercício.

### 6. `ex6_bytes_nulos` — contar bytes `\0` com lseek()
```bash
./ex6_bytes_nulos testes/binario_teste.dat
```
Percorre o arquivo byte a byte usando `lseek()` + `read()` (sem carregar tudo de uma vez) e conta quantos bytes nulos existem. Com `binario_teste.dat` o resultado esperado é **8 bytes nulos em 20 bytes totais** (pode conferir com `od -An -tx1 testes/binario_teste.dat`).

**Racional:** o enunciado pede para percorrer "sem `read()` tradicional", ou seja, sem ler o arquivo inteiro de uma vez num buffer grande. A solução usa `lseek(fd, 0, SEEK_END)` primeiro só para descobrir o tamanho total (mesma ideia do exercício 1), e depois entra num laço que faz `lseek(fd, pos, SEEK_SET)` seguido de `read()` de exatamente 1 byte a cada iteração, incrementando `pos`. Isso é deliberadamente ineficiente em I/O (uma chamada de sistema por byte) — o ganho aqui não é performance, é demonstrar o uso de `lseek()` para navegação explícita e controlada dentro do arquivo, byte a byte, em vez de depender do cursor avançar implicitamente como acontece em leituras sequenciais normais.

### 7. `ex7_truncar` — cortar um arquivo com lseek() + ftruncate()
```bash
cp testes/arquivo_para_truncar.txt /tmp/copia.txt   # faça uma cópia, o programa modifica o arquivo!
./ex7_truncar /tmp/copia.txt
cat /tmp/copia.txt
```
⚠️ Este programa **modifica o arquivo passado como argumento** — nunca rode direto em cima de `testes/arquivo_para_truncar.txt`, sempre em uma cópia. Ele pula para o byte 20 com `lseek()`, escreve `"FIM\n"` e usa `ftruncate()` para cortar tudo que vinha depois (lseek() sozinho não trunca, só reposiciona o cursor). Com o arquivo de teste, o resultado esperado é o arquivo virar `Linha 1 de teste XYZFIM\n` (24 bytes).

**Racional:** este é o exercício onde o enunciado tem uma armadilha conceitual proposital. `lseek()` nunca altera o conteúdo ou o tamanho do arquivo — ele só move um ponteiro interno. Escrever `"FIM\n"` na posição 20 apenas *sobrescreve* os 4 bytes que já estavam ali; tudo que vinha depois do byte 24 continuaria existindo no arquivo, só que agora "escondido" depois do que foi escrito. Para de fato cortar o arquivo (reduzir seu tamanho para que nada sobre depois do que foi escrito), é necessário chamar `ftruncate(fd, tamanho)` explicitamente, passando como `tamanho` a posição atual do cursor após a escrita (`lseek(fd, 0, SEEK_CUR)`, que dá a posição sem mover nada — só para consultar onde o cursor parou). Por isso o programa some as duas chamadas: `write()` para colocar o conteúdo novo, `ftruncate()` para eliminar o restante.

### 8. `ex8_multiplos_arquivos` — stat em vários arquivos de uma vez
```bash
./ex8_multiplos_arquivos testes/arquivo_teste.txt testes/link_teste.txt testes/binario_teste.dat testes/subdir_teste
```
Para cada argumento, mostra tamanho, tipo (regular, diretório, link simbólico, etc — usa `lstat()` para não seguir links) e permissões.

**Racional:** o enunciado pede para exibir o tipo do arquivo incluindo "link simbólico" como uma opção possível — mas se o programa usasse `stat()` (que segue links), um link simbólico *nunca* apareceria como link, porque `stat()` reportaria o tipo do arquivo apontado, não do link em si (mesma lógica do exercício 4). Por isso o programa usa `lstat()`: cada arquivo passado como argumento é inspecionado sem seguir eventuais links, permitindo distinguir de fato um link simbólico de um arquivo regular. O laço simplesmente itera sobre `argv[1..argc-1]`, chama `lstat()` em cada um, e trata falhas individualmente com `perror()` + `continue` — assim um caminho inválido não derruba a análise dos demais arquivos da lista.

## Exemplo rápido de teste (rodando tudo de uma vez)

```bash
make
./ex1_tamanho testes/arquivo_teste.txt
./ex2_leitura_parcial testes/arquivo_teste.txt
./ex3_stat testes/arquivo_teste.txt
./ex4_stat_lstat testes/link_teste.txt
./ex5_fstat testes/arquivo_teste.txt
./ex6_bytes_nulos testes/binario_teste.dat
cp testes/arquivo_para_truncar.txt /tmp/copia.txt && ./ex7_truncar /tmp/copia.txt && cat /tmp/copia.txt
./ex8_multiplos_arquivos testes/arquivo_teste.txt testes/link_teste.txt testes/binario_teste.dat testes/subdir_teste
```
