/* 5. Usando fstat() */
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/stat.h>

static const char *tipo_arquivo(mode_t modo) {
    if (S_ISREG(modo))  return "regular";
    if (S_ISDIR(modo))  return "diretorio";
    if (S_ISLNK(modo))  return "link simbolico";
    if (S_ISCHR(modo))  return "dispositivo de caractere";
    if (S_ISBLK(modo))  return "dispositivo de bloco";
    if (S_ISFIFO(modo)) return "fifo/pipe";
    if (S_ISSOCK(modo)) return "socket";
    return "desconhecido";
}

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

    struct stat buf;
    if (fstat(fd, &buf) == -1) {
        perror("fstat");
        close(fd);
        return 1;
    }

    printf("fstat(fd) -> tipo: %s, tamanho: %ld bytes\n",
           tipo_arquivo(buf.st_mode), (long)buf.st_size);

    struct stat buf_stat;
    if (stat(argv[1], &buf_stat) == -1) {
        perror("stat");
        close(fd);
        return 1;
    }

    printf("stat()    -> tipo: %s, tamanho: %ld bytes\n",
           tipo_arquivo(buf_stat.st_mode), (long)buf_stat.st_size);

    if (buf.st_ino == buf_stat.st_ino && buf.st_size == buf_stat.st_size) {
        printf("Resultado igual: sim (mesmo inode, %lu)\n", (unsigned long)buf.st_ino);
    } else {
        printf("Resultado igual: nao\n");
    }

    close(fd);
    return 0;
}
