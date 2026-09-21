#!/bin/bash
# Demonstra o ex2_przombies: sobe o daemon, gera zumbis com ex1_gerador_zumbis,
# espera dois ciclos de varredura, mostra o log e finaliza o daemon com SIGTERM.
set -e
cd "$(dirname "$0")/.."

rm -f przombies.log

./ex2_przombies 2
echo "daemon iniciado em background (o proprio programa faz fork e devolve o prompt)"

./ex1_gerador_zumbis 3
sleep 5

echo "--- log apos os zumbis serem gerados ---"
cat przombies.log

DAEMON_REAL_PID=$(pgrep -f "^\./ex2_przombies 2$" | head -n1)
echo "--- enviando SIGTERM para o daemon (pid $DAEMON_REAL_PID) ---"
kill -TERM "$DAEMON_REAL_PID"
sleep 1

echo "--- log final (deve terminar com a mensagem de SIGTERM) ---"
cat przombies.log
