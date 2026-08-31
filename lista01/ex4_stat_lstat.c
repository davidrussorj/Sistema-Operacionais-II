/* 4. Comparacao entre stat() e lstat()
 *
 * Preparo: ln -s arquivo.txt link.txt
 * Uso: ./ex4_stat_lstat link.txt
 */
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Uso: %s <link_simbolico>\n", argv[0]);
        return 1;
    }

    struct stat st_via_stat, st_via_lstat;

    if (stat(argv[1], &st_via_stat) == -1) {
        perror("stat");
        return 1;
    }
    if (lstat(argv[1], &st_via_lstat) == -1) {
        perror("lstat");
        return 1;
    }

    printf("stat(\"%s\")  -> tamanho do ARQUIVO REAL apontado: %ld bytes\n",
           argv[1], (long)st_via_stat.st_size);
    printf("lstat(\"%s\") -> tamanho do LINK em si (caminho do alvo): %ld bytes\n",
           argv[1], (long)st_via_lstat.st_size);

    printf("\nDiferenca: stat() segue o link simbolico e retorna informacoes\n"
           "do arquivo para o qual ele aponta (o alvo). lstat() nao segue o\n"
           "link: retorna informacoes sobre o proprio link, cujo st_size e\n"
           "o numero de bytes do caminho armazenado dentro dele (o texto do\n"
           "destino), nao o tamanho do arquivo real.\n");

    return 0;
}
