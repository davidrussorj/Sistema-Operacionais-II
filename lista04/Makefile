# Makefile da Lista 4 (Shell Script)
#
# Shell script não é compilado; o make faz o papel equivalente:
#   make         dá permissão de execução e verifica a sintaxe dos scripts
#   make test    faz o mesmo e roda a bateria de testes automáticos
# Nenhum script gera arquivos, então não há "make clean".

# Todos os exercícios (ex*.sh) e o testador.
SCRIPTS = $(wildcard ex*.sh)
TESTADOR = testes/rodar_testes.sh

all: check

# chmod +x  permite rodar como ./script (slide 23).
# bash -n   lê cada script e só verifica a sintaxe, sem executar nada; o
#           laço para no primeiro erro (exit 1).
# shellcheck é opcional: se estiver instalado, faz também a análise
#           estática (aspas faltando, comparações erradas etc.).
check:
	chmod +x $(SCRIPTS) $(TESTADOR)
	@for s in $(SCRIPTS) $(TESTADOR); do bash -n "$$s" || exit 1; done
	@if command -v shellcheck > /dev/null; then shellcheck $(SCRIPTS) $(TESTADOR); fi
	@echo "$(words $(SCRIPTS)) scripts prontos (sintaxe verificada)"

# Roda os testes de todos os exercícios. Para testar só alguns:
#   ./testes/rodar_testes.sh 3 4
test: check
	./$(TESTADOR)

.PHONY: all check test
