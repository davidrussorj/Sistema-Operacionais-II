/* 1. Usando lseek() para medir o tamanho do arquivo */
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Uso: %s <arquivo>\n", argv[0]);
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

    printf("Tamanho do arquivo '%s': %ld bytes\n", argv[1], (long)tamanho);

    close(fd);
    return 0;
}
