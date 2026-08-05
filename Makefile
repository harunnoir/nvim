NVIM ?= nvim
STYLUA ?= stylua
SHELLCHECK ?= shellcheck

.PHONY: format check test shellcheck

format:
	$(STYLUA) init.lua lua bin/mason_install.lua tests/toggles.lua

shellcheck:
	find bin tests -name '*.sh' -print0 | xargs -0 -n1 bash -n
	@if command -v $(SHELLCHECK) >/dev/null 2>&1; then \
		find bin tests -name '*.sh' -print0 | xargs -0 $(SHELLCHECK); \
	else \
		printf 'shellcheck not installed; skipping static shell analysis\n'; \
	fi

check:
	@if command -v $(STYLUA) >/dev/null 2>&1; then \
		$(STYLUA) --check init.lua lua bin/mason_install.lua tests/toggles.lua; \
	else \
		printf 'stylua not installed; skipping Lua style check\n'; \
	fi
	$(MAKE) shellcheck
	$(MAKE) test

test:
	./tests/installer.sh
	./tests/startup.sh
