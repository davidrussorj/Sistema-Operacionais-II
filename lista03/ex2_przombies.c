/* Exercicio 2 - daemon przombies: varre /proc de n em n segundos e loga processos zumbis */
#include <ctype.h>
#include <dirent.h>
#include <fcntl.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define ARQUIVO_LOG "przombies.log"

static int log_fd;

static void trata_sigterm(int sig) {
    (void)sig;
    const char msg[] = "== daemon finalizado por SIGTERM ==\n";
    write(log_fd, msg, sizeof(msg) - 1);
    close(log_fd);
    _exit(0);
}

static int eh_pid(const char *nome) {
    if (*nome == '\0')
        return 0;
    for (const char *p = nome; *p != '\0'; p++)
        if (!isdigit((unsigned char)*p))
            return 0;
    return 1;
}

static void escreve(const char *texto) {
    write(log_fd, texto, strlen(texto));
}

static void varre_zumbis(void) {
    DIR *proc = opendir("/proc");
    if (proc == NULL) {
        perror("opendir /proc");
        return;
    }

    escreve("==========================================\n");

    struct dirent *entrada;
    while ((entrada = readdir(proc)) != NULL) {
        if (!eh_pid(entrada->d_name))
            continue;

        char caminho[280];
        snprintf(caminho, sizeof(caminho), "/proc/%s/status", entrada->d_name);

        FILE *status = fopen(caminho, "r");
        if (status == NULL)
            continue; /* processo pode ter terminado entre o readdir e o fopen */

        char nome[256] = "";
        char estado = '\0';
        int ppid = -1;
        char linha[256];
        while (fgets(linha, sizeof(linha), status) != NULL) {
            if (strncmp(linha, "Name:", 5) == 0)
                sscanf(linha, "Name:%255s", nome);
            else if (strncmp(linha, "State:", 6) == 0)
                sscanf(linha, "State: %c", &estado);
            else if (strncmp(linha, "PPid:", 5) == 0)
                sscanf(linha, "PPid:%d", &ppid);
        }
        fclose(status);

        if (estado == 'Z') {
            char linha_log[600];
            snprintf(linha_log, sizeof(linha_log), "%s %d %s\n", entrada->d_name, ppid, nome);
            escreve(linha_log);
        }
    }

    closedir(proc);
}

int main(int argc, char **argv) {
    if (argc != 2) {
        fprintf(stderr, "Uso: %s <intervalo_em_segundos>\n", argv[0]);
        return 1;
    }

    int intervalo = atoi(argv[1]);
    if (intervalo <= 0) {
        fprintf(stderr, "Uso: %s <intervalo_em_segundos>\n", argv[0]);
        return 1;
    }

    log_fd = open(ARQUIVO_LOG, O_WRONLY | O_CREAT | O_APPEND, 0644);
    if (log_fd < 0) {
        perror("open");
        return 1;
    }

    struct sigaction act_term;
    memset(&act_term, 0, sizeof(act_term));
    act_term.sa_handler = trata_sigterm;
    sigemptyset(&act_term.sa_mask);
    if (sigaction(SIGTERM, &act_term, NULL) < 0)
        perror("sigaction SIGTERM");

    /* invulneravel a qualquer outro sinal que possa ser ignorado */
    struct sigaction act_ign;
    memset(&act_ign, 0, sizeof(act_ign));
    act_ign.sa_handler = SIG_IGN;
    sigemptyset(&act_ign.sa_mask);
    for (int sig = 1; sig <= 31; sig++) {
        if (sig == SIGKILL || sig == SIGSTOP || sig == SIGTERM)
            continue;
        sigaction(sig, &act_ign, NULL);
    }

    pid_t pid = fork();
    if (pid < 0) {
        perror("fork");
        return 1;
    }
    if (pid > 0)
        exit(0); /* pai devolve o prompt, filho segue em background */

    escreve("PID PPID Nome do Programa\n");

    for (;;) {
        sleep(intervalo);
        varre_zumbis();
    }

    return 0;
}
