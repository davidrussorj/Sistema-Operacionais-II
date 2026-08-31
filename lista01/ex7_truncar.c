/* 7. Truncar arquivo com lseek() e write()
 *
 * lseek() sozinho so move o cursor: escrever "FIM\n" no byte 20 sobrescreve
 * o que estava ali, mas nao apaga o que vem depois. Para realmente cortar
 * o arquivo a partir dali, e preciso chamar ftruncate() apos a escrita.
 */
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Uso: %s <arquivo_de_texto>\n", argv[0]);
        return 1;
    }

    int fd = open(argv[1], O_WRONLY);
    if (fd == -1) {
        perror("open");
        return 1;
    }

    if (lseek(fd, 20, SEEK_SET) == -1) {
        perror("lseek");
        close(fd);
        return 1;
    }

    const char *msg = "FIM\n";
    if (write(fd, msg, 4) == -1) {
        perror("write");
        close(fd);
        return 1;
    }

    off_t pos_final = lseek(fd, 0, SEEK_CUR);
    if (ftruncate(fd, pos_final) == -1) {
        perror("ftruncate");
        close(fd);
        return 1;
    }

    printf("Arquivo '%s' truncado no byte %ld, apos escrever \"FIM\\n\"\n",
           argv[1], (long)pos_final);

    close(fd);
    return 0;
}
