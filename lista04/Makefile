SCRIPTS = $(wildcard ex*.sh)

all: check

check:
	chmod +x $(SCRIPTS)
	@for s in $(SCRIPTS); do bash -n "$$s" || exit 1; done
	@if command -v shellcheck > /dev/null; then shellcheck $(SCRIPTS); fi
	@echo "$(words $(SCRIPTS)) scripts prontos (sintaxe verificada)"

clean:
	rm -f arq.txt erros.txt

.PHONY: all check clean
