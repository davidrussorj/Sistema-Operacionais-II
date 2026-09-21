/* Exercicio 1 - gerador de processos zumbis (programa auxiliar do enunciado, usado para testar o ex2_przombies) */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main(int argc, char **argv) {
    if (argc > 2) {
        fprintf(stderr, "Uso: %s [<n>]\n", argv[0]);
        return 1;
    }

    long n = (argc == 1) ? 1 : atol(argv[1]);
    if (n <= 0) {
        fprintf(stderr, "Uso: %s [<n>]\n", argv[0]);
        return 1;
    }

    pid_t pid = fork();
    if (pid < 0) {
        perror("fork");
        return 1;
    }
    if (pid > 0)
        exit(0); /* passa para background */

    while (n-- > 0) {
        pid = fork();
        if (pid < 0) {
            perror("fork");
            continue;
        }
        if (pid == 0)
            exit(0); /* filhos falecem ... */
    }

    for (;;)
        pause(); /* ... e o pai nem liga */

    return 0;
}
