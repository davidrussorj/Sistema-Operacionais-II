/* 3. Usando stat() para informacoes de um arquivo */
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <time.h>

static void imprime_permissoes(mode_t modo) {
    char perm[10];
    perm[0] = (modo & S_IRUSR) ? 'r' : '-';
    perm[1] = (modo & S_IWUSR) ? 'w' : '-';
    perm[2] = (modo & S_IXUSR) ? 'x' : '-';
    perm[3] = (modo & S_IRGRP) ? 'r' : '-';
    perm[4] = (modo & S_IWGRP) ? 'w' : '-';
    perm[5] = (modo & S_IXGRP) ? 'x' : '-';
    perm[6] = (modo & S_IROTH) ? 'r' : '-';
    perm[7] = (modo & S_IWOTH) ? 'w' : '-';
    perm[8] = (modo & S_IXOTH) ? 'x' : '-';
    perm[9] = '\0';
    printf("Permissoes de acesso: %s\n", perm);
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Uso: %s <arquivo>\n", argv[0]);
        return 1;
    }

    struct stat info;
    if (stat(argv[1], &info) == -1) {
        perror("stat");
        return 1;
    }

    printf("Arquivo: %s\n", argv[1]);
    printf("Tamanho: %ld bytes\n", (long)info.st_size);
    printf("Numero de links: %lu\n", (unsigned long)info.st_nlink);
    printf("UID do dono: %d\n", info.st_uid);
    imprime_permissoes(info.st_mode);

    char data[64];
    struct tm *tm_info = localtime(&info.st_mtime);
    strftime(data, sizeof(data), "%d/%m/%Y %H:%M:%S", tm_info);
    printf("Ultima modificacao: %s\n", data);

    return 0;
}
