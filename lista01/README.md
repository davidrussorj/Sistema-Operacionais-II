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

## Como rodar cada exercício

### 1. `ex1_tamanho` — tamanho do arquivo com lseek()
```bash
./ex1_tamanho <arquivo>
```
Abre o arquivo, usa `lseek(fd, 0, SEEK_END)` para ir ao final e imprime a posição (= tamanho em bytes).

**Racional:** `lseek()` retorna a nova posição do cursor após o deslocamento, não o conteúdo do arquivo. Como `SEEK_END` desloca a partir do final e o offset pedido é `0`, o cursor para exatamente na última posição válida — que numericamente é igual ao tamanho do arquivo em bytes. É a forma mais direta de obter o tamanho sem precisar de `stat()`, mas tem uma pegadinha: como efeito colateral, ela também move o cursor de leitura/escrita do arquivo, então se o programa fosse ler algo depois teria que dar `lseek(fd, 0, SEEK_SET)` para voltar ao início.

### 2. `ex2_leitura_parcial` — ler partes específicas do arquivo
```bash
./ex2_leitura_parcial <arquivo>
```
Lê os primeiros 100 bytes, pula para o byte 200 com `lseek()` e lê mais 50 bytes. Funciona melhor em arquivos de texto com pelo menos 250 bytes.

**Racional:** o ponto do exercício é mostrar que `read()` sempre lê a partir da posição atual do cursor, e `lseek(fd, 200, SEEK_SET)` reposiciona esse cursor de forma absoluta (a partir do início do arquivo) sem precisar ler e descartar os bytes 100–199 no meio do caminho — diferente de simular o pulo com várias chamadas de `read()` até chegar lá. Isso é o que torna `lseek()` eficiente para acesso aleatório em arquivos: o custo é O(1), não depende da distância pulada. Os buffers têm tamanho `+1` (`buf1[101]`, `buf2[51]`) só para caber o `\0` de terminação de string ao usar `printf("%s", ...)`.

### 3. `ex3_stat` — informações do arquivo com stat()
```bash
./ex3_stat <arquivo>
```
Mostra tamanho, número de links, UID do dono, permissões (rwx) e data/hora da última modificação.

**Racional:** `stat()` recebe um *caminho* (não um fd) e preenche uma `struct stat` com metadados que o sistema de arquivos guarda no inode — nada disso exige abrir o arquivo. As permissões (`st_mode`) vêm como uma máscara de bits; por isso a função `imprime_permissoes()` testa cada bit individualmente com `&` contra as constantes `S_IRUSR`, `S_IWUSR`, `S_IXUSR`, etc., montando a string `rwxrwxrwx` posição por posição — é o mesmo princípio usado pelo `ls -l` internamente. Para a data, `st_mtime` é um `time_t` (segundos desde a epoch), então precisa passar por `localtime()` + `strftime()` para virar uma data legível; usar o valor bruto não faria sentido para quem lê a saída.

### 4. `ex4_stat_lstat` — stat() vs lstat() em um link simbólico
```bash
ln -s arquivo.txt link.txt
./ex4_stat_lstat link.txt
```
Precisa criar o link simbólico antes de rodar. Mostra que `stat()` segue o link (retorna dados do arquivo real) e `lstat()` retorna dados do link em si.

**Racional:** a diferença entre as duas chamadas está em *o que* cada uma resolve. `stat()` segue (`dereference`) o link simbólico automaticamente — se o alvo também fosse outro link, `stat()` seguiria a cadeia inteira até achar o arquivo real — e por isso retorna o tamanho do arquivo apontado (`arquivo.txt`, no exemplo). Já `lstat()` para no próprio link: não segue nada, e o `st_size` retornado é o número de bytes do *caminho* armazenado dentro do link (o texto `"arquivo.txt"`, por exemplo, tem 11 caracteres). Essa distinção existe porque, sem `lstat()`, não haveria como inspecionar metadados do link em si (por exemplo, para detectar se algo é um link antes de decidir segui-lo, evitando loops de links simbólicos apontando um para o outro).

### 5. `ex5_fstat` — fstat() em um arquivo já aberto
```bash
./ex5_fstat <arquivo>
```
Abre o arquivo, usa `fstat(fd, &buf)`, identifica o tipo (regular/diretório/link/etc) e compara com o resultado de `stat()` no mesmo caminho.

**Racional:** `fstat()` é essencialmente o mesmo `stat()`, mas opera sobre um *file descriptor* já aberto em vez de um caminho no sistema de arquivos. Isso importa em dois cenários que `stat()` sozinho não cobre bem: (1) evitar uma *race condition* conhecida como TOCTOU (time-of-check to time-of-use), onde o arquivo poderia ser trocado/removido entre um `stat()` no caminho e uma abertura posterior — com `fstat()` a consulta é sobre o arquivo que já está de fato aberto, garantido pelo próprio kernel; (2) quando o programa só tem o fd em mãos (por exemplo, recebido via `dup()` ou herdado de outro processo) e não tem mais o caminho original disponível. O tipo do arquivo é identificado com as macros `S_ISREG`, `S_ISDIR`, `S_ISLNK` etc., que testam bits específicos de `st_mode` — a mesma máscara usada nas permissões, mas em outra faixa de bits. Como `open()` sem `O_NOFOLLOW` segue links por padrão, o fd nunca aponta para um link em si, por isso `fstat()` e `stat()` batem (mesmo inode) neste exercício.

### 6. `ex6_bytes_nulos` — contar bytes `\0` com lseek()
```bash
./ex6_bytes_nulos <arquivo_binario>
```
Percorre o arquivo byte a byte usando `lseek()` + `read()` (sem carregar tudo de uma vez) e conta quantos bytes nulos existem.

**Racional:** o enunciado pede para percorrer "sem `read()` tradicional", ou seja, sem ler o arquivo inteiro de uma vez num buffer grande. A solução usa `lseek(fd, 0, SEEK_END)` primeiro só para descobrir o tamanho total (mesma ideia do exercício 1), e depois entra num laço que faz `lseek(fd, pos, SEEK_SET)` seguido de `read()` de exatamente 1 byte a cada iteração, incrementando `pos`. Isso é deliberadamente ineficiente em I/O (uma chamada de sistema por byte) — o ganho aqui não é performance, é demonstrar o uso de `lseek()` para navegação explícita e controlada dentro do arquivo, byte a byte, em vez de depender do cursor avançar implicitamente como acontece em leituras sequenciais normais.

### 7. `ex7_truncar` — cortar um arquivo com lseek() + ftruncate()
```bash
cp arquivo_teste.txt copia.txt   # faça uma cópia, o programa modifica o arquivo!
./ex7_truncar copia.txt
```
⚠️ Este programa **modifica o arquivo passado como argumento** — sempre teste em uma cópia. Ele pula para o byte 20 com `lseek()`, escreve `"FIM\n"` e usa `ftruncate()` para cortar tudo que vinha depois (lseek() sozinho não trunca, só reposiciona o cursor).

**Racional:** este é o exercício onde o enunciado tem uma armadilha conceitual proposital. `lseek()` nunca altera o conteúdo ou o tamanho do arquivo — ele só move um ponteiro interno. Escrever `"FIM\n"` na posição 20 apenas *sobrescreve* os 4 bytes que já estavam ali; tudo que vinha depois do byte 24 continuaria existindo no arquivo, só que agora "escondido" depois do que foi escrito. Para de fato cortar o arquivo (reduzir seu tamanho para que nada sobre depois do que foi escrito), é necessário chamar `ftruncate(fd, tamanho)` explicitamente, passando como `tamanho` a posição atual do cursor após a escrita (`lseek(fd, 0, SEEK_CUR)`, que dá a posição sem mover nada — só para consultar onde o cursor parou). Por isso o programa some as duas chamadas: `write()` para colocar o conteúdo novo, `ftruncate()` para eliminar o restante.

### 8. `ex8_multiplos_arquivos` — stat em vários arquivos de uma vez
```bash
./ex8_multiplos_arquivos <arquivo1> [arquivo2] [arquivo3] ...
```
Para cada argumento, mostra tamanho, tipo (regular, diretório, link simbólico, etc — usa `lstat()` para não seguir links) e permissões.

**Racional:** o enunciado pede para exibir o tipo do arquivo incluindo "link simbólico" como uma opção possível — mas se o programa usasse `stat()` (que segue links), um link simbólico *nunca* apareceria como link, porque `stat()` reportaria o tipo do arquivo apontado, não do link em si (mesma lógica do exercício 4). Por isso o programa usa `lstat()`: cada arquivo passado como argumento é inspecionado sem seguir eventuais links, permitindo distinguir de fato um link simbólico de um arquivo regular. O laço simplesmente itera sobre `argv[1..argc-1]`, chama `lstat()` em cada um, e trata falhas individualmente com `perror()` + `continue` — assim um caminho inválido não derruba a análise dos demais arquivos da lista.

## Exemplo rápido de teste

```bash
make
echo "conteudo de teste" > teste.txt
./ex1_tamanho teste.txt
./ex3_stat teste.txt
ln -s teste.txt link_teste.txt
./ex4_stat_lstat link_teste.txt
./ex8_multiplos_arquivos teste.txt link_teste.txt .
```
