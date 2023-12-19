#!/usr/bin/make -f

.DEFAULT_GOAL := help

# env vars
.ONESHELL:
ARCH := $(shell uname -m)
ifeq ($(ARCH), arm64)
	BREW_PREFIX = /opt/homebrew
else
	BREW_PREFIX = /usr/local
endif
BREW   := $(BREW_PREFIX)/bin
PIP    := $(BREW_PREFIX)/lib/python3.11/site-packages

# Export paths
PATH   := $(BREW):$(PIP):$(PATH)
export PATH

# colors
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
WHITE  := $(shell tput -Txterm setaf 7)
CYAN   := $(shell tput -Txterm setaf 6)
RESET  := $(shell tput -Txterm sgr0)

all: help brew python ansible shellrc install
.PHONY: all

brew: ## install brew
	@echo "${GREEN}Installing brew...${RESET}"
	/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

python: ## install python
	@echo "${GREEN}Installing python...${RESET}"
	eval "$$(brew shellenv)" && brew install python@3.11

# ! has to be set globally after python directive
PYTHON := $(shell realpath $(BREW_PREFIX)/bin/python3.11)

ansible: python ## install ansible
	@echo "${GREEN}Installing ansible...${RESET}"
	$(PYTHON) -m pip install --upgrade pip
	$(PYTHON) -m pip install ansible ansible-lint

shellrc: ## append shellrc
	@echo "${YELLOW}Appending shellrc...${RESET}"
	if [ "$(shell echo $$SHELL)" = "/bin/zsh" ]; then \
		cp ~/.zshrc ~/.zshrc_`date +%Y%m%d%H%M%S`.bak; \
		echo 'export PATH="$(BREW):$(PIP):$$PATH"' > ~/.zshrc; \
		echo 'eval "$$(brew shellenv)"' >> ~/.zshrc; \
	else \
		cp ~/.bashrc ~/.bashrc_`date +%Y%m%d%H%M%S`.bak; \
		echo 'export PATH="$(BREW):$(PIP):$$PATH"' > ~/.bashrc; \
		echo 'eval "$$(brew shellenv)"' >> ~/.bashrc; \
	fi
	@echo "${GREEN}Please restart your shell...${RESET}"

install: brew python ansible shellrc ## install ansible dependencies
	@echo "${GREEN}Installing ansible dependencies...${RESET}"

help: ## show this help
	@echo ''
	@echo 'Usage:'
	@echo '    ${YELLOW}make${RESET} ${GREEN}<target>${RESET}'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} { \
		if (/^[a-zA-Z_-]+:.*?##.*$$/) {printf "    ${YELLOW}%-20s${GREEN}%s${RESET}\n", $$1, $$2} \
		else if (/^## .*$$/) {printf "  ${CYAN}%s${RESET}\n", substr($$1,4)} \
		}' $(MAKEFILE_LIST)
