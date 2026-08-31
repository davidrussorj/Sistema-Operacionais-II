/* 8. Tamanho e tipo de multiplos arquivos (stat) */
#include <stdio.h>
#include <stdlib.h>
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
    printf("%s", perm);
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        fprintf(stderr, "Uso: %s <arquivo1> [arquivo2 ...]\n", argv[0]);
        return 1;
    }

    for (int i = 1; i < argc; i++) {
        /* lstat() em vez de stat(): assim um link simbolico aparece como
         * "link simbolico" em vez de aparecer como o tipo do arquivo alvo. */
        struct stat info;
        if (lstat(argv[i], &info) == -1) {
            fprintf(stderr, "%s: ", argv[i]);
            perror("lstat");
            continue;
        }

        printf("%-30s tamanho=%-10ld tipo=%-18s permissoes=",
               argv[i], (long)info.st_size, tipo_arquivo(info.st_mode));
        imprime_permissoes(info.st_mode);
        printf("\n");
    }

    return 0;
}
