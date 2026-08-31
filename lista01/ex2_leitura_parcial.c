/* 2. Ler parte de um arquivo com lseek() */
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

    char buf1[101];
    ssize_t lidos1 = read(fd, buf1, 100);
    if (lidos1 == -1) {
        perror("read");
        close(fd);
        return 1;
    }
    buf1[lidos1] = '\0';
    printf("=== Primeiros %zd bytes ===\n%s\n", lidos1, buf1);

    if (lseek(fd, 200, SEEK_SET) == -1) {
        perror("lseek");
        close(fd);
        return 1;
    }

    char buf2[51];
    ssize_t lidos2 = read(fd, buf2, 50);
    if (lidos2 == -1) {
        perror("read");
        close(fd);
        return 1;
    }
    buf2[lidos2] = '\0';
    printf("=== %zd bytes a partir do byte 200 ===\n%s\n", lidos2, buf2);

    close(fd);
    return 0;
}
