/* 6. Contar bytes nulos (\0) em um arquivo com lseek() */
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Uso: %s <arquivo_binario>\n", argv[0]);
        return 1;
    }

    int fd = open(argv[1], O_RDONLY);
    if (fd == -1) {
        perror("open");
        return 1;
    }

    off_t tamanho = lseek(fd, 0, SEEK_END);
    if (tamanho == -1) {
        perror("lseek");
        close(fd);
        return 1;
    }

    long contador = 0;
    unsigned char byte;

    for (off_t pos = 0; pos < tamanho; pos++) {
        if (lseek(fd, pos, SEEK_SET) == -1) {
            perror("lseek");
            close(fd);
            return 1;
        }
        if (read(fd, &byte, 1) != 1) {
            perror("read");
            close(fd);
            return 1;
        }
        if (byte == 0) {
            contador++;
        }
    }

    printf("Arquivo '%s': %ld bytes nulos (\\0) em %ld bytes totais\n",
           argv[1], contador, (long)tamanho);

    close(fd);
    return 0;
}
