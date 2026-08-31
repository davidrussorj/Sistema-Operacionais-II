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

### 2. `ex2_leitura_parcial` — ler partes específicas do arquivo
```bash
./ex2_leitura_parcial <arquivo>
```
Lê os primeiros 100 bytes, pula para o byte 200 com `lseek()` e lê mais 50 bytes. Funciona melhor em arquivos de texto com pelo menos 250 bytes.

### 3. `ex3_stat` — informações do arquivo com stat()
```bash
./ex3_stat <arquivo>
```
Mostra tamanho, número de links, UID do dono, permissões (rwx) e data/hora da última modificação.

### 4. `ex4_stat_lstat` — stat() vs lstat() em um link simbólico
```bash
ln -s arquivo.txt link.txt
./ex4_stat_lstat link.txt
```
Precisa criar o link simbólico antes de rodar. Mostra que `stat()` segue o link (retorna dados do arquivo real) e `lstat()` retorna dados do link em si.

### 5. `ex5_fstat` — fstat() em um arquivo já aberto
```bash
./ex5_fstat <arquivo>
```
Abre o arquivo, usa `fstat(fd, &buf)`, identifica o tipo (regular/diretório/link/etc) e compara com o resultado de `stat()` no mesmo caminho.

### 6. `ex6_bytes_nulos` — contar bytes `\0` com lseek()
```bash
./ex6_bytes_nulos <arquivo_binario>
```
Percorre o arquivo byte a byte usando `lseek()` + `read()` (sem carregar tudo de uma vez) e conta quantos bytes nulos existem.

### 7. `ex7_truncar` — cortar um arquivo com lseek() + ftruncate()
```bash
cp arquivo_teste.txt copia.txt   # faça uma cópia, o programa modifica o arquivo!
./ex7_truncar copia.txt
```
⚠️ Este programa **modifica o arquivo passado como argumento** — sempre teste em uma cópia. Ele pula para o byte 20 com `lseek()`, escreve `"FIM\n"` e usa `ftruncate()` para cortar tudo que vinha depois (lseek() sozinho não trunca, só reposiciona o cursor).

### 8. `ex8_multiplos_arquivos` — stat em vários arquivos de uma vez
```bash
./ex8_multiplos_arquivos <arquivo1> [arquivo2] [arquivo3] ...
```
Para cada argumento, mostra tamanho, tipo (regular, diretório, link simbólico, etc — usa `lstat()` para não seguir links) e permissões.

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
