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
HOME := $(shell echo $$HOME)
PATH := $(HOME)/.local/bin:$(BREW):$(PIP):$(PATH)
export PATH

# colors
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
WHITE  := $(shell tput -Txterm setaf 7)
CYAN   := $(shell tput -Txterm setaf 6)
RESET  := $(shell tput -Txterm sgr0)

all: help xcode brew python log ansible devbox shellrc install
.PHONY: all

# Check if bin is already installed
define cmd
$(shell \
  if command -v $(1) >/dev/null 2>&1; then \
    echo "$(1) is already installed." >&2; \
    echo "1"; \
  else \
    echo "0"; \
  fi \
)
endef

xcode: ## install xcode
	@if [ -d "/Library/Developer/CommandLineTools" ]; then \
		echo "Command line tools are already installed."; \
	else \
		echo "Installing xcode command line tools..."; \
		xcode-select --install; \
	fi
	@if /usr/bin/xcrun cc 2>&1 | grep -q "license"; then \
		echo "License needs to be accepted. Attempting to accept..."; \
		if command -v xcodebuild >/dev/null 2>&1; then \
			sudo xcodebuild -license accept; \
		else \
			echo "xcodebuild not found. Using xcrun to accept license..."; \
			sudo /usr/bin/xcrun cc; \
		fi; \
	else \
		echo "License already accepted."; \
	fi

brew: ## install brew
	@if [ $(call cmd,brew) -eq 0 ]; then \
		echo "${GREEN}Installing brew...${RESET}"; \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
	fi

python: ## install python
	@if [ $(call cmd,python3.11) -eq 0 ]; then \
		echo "${GREEN}Installing python...${RESET}"; \
		eval "$$(brew shellenv)" && brew install python@3.11; \
	fi

# ! has to be set globally after python directive
PYTHON := $(shell realpath $(BREW_PREFIX)/bin/python3.11)

log: ## ensure ansible log exists with correct permissions
	@if [ ! -f /var/log/ansible.log ]; then \
		echo "${YELLOW}Creating Ansible log file...${RESET}"; \
		sudo touch /var/log/ansible.log; \
		sudo chmod 666 /var/log/ansible.log; \
	elif [ "$$(stat -f %Lp /var/log/ansible.log)" != "666" ]; then \
		echo "${YELLOW}Updating Ansible log file permissions...${RESET}"; \
		sudo chmod 666 /var/log/ansible.log; \
	else \
		echo "${GREEN}Ansible log file exists with correct permissions.${RESET}"; \
	fi

ansible: python log ## install ansible
	@if [ $(call cmd,ansible) -eq 0 ]; then \
		echo "${GREEN}Installing ansible...${RESET}"; \
		$(PYTHON) -m pip install --upgrade pip --quiet; \
		$(PYTHON) -m pip install ansible ansible-lint --quiet; \
	fi

devbox: brew ## install devbox
	@if [ $(call cmd,devbox) -eq 0 ]; then \
		echo "${GREEN}Installing devbox...${RESET}"; \
		mkdir -p $(HOME)/.local/bin; \
		curl -fsSL https://get.jetify.com/devbox | \
		sed 's|readonly INSTALL_DIR="/usr/local/bin"|readonly INSTALL_DIR="$(HOME)/.local/bin"|' | \
		bash; \
	fi

shellrc: ## append shellrc
	@echo "${YELLOW}Appending shellrc...${RESET}"
	@if [ "$(shell echo $$SHELL)" = "/bin/zsh" ]; then \
		if [ -f $(HOME)/.zshrc ]; then \
			cp $(HOME)/.zshrc $(HOME)/.zshrc_$$(date +%Y%m%d%H%M%S).bak; \
		fi; \
		echo 'export PATH="$(PATH)"' > $(HOME)/.zshrc; \
		echo 'eval "$$(brew shellenv)"' >> $(HOME)/.zshrc; \
	else \
		if [ -f $(HOME)/.bashrc ]; then \
			cp $(HOME)/.bashrc $(HOME)/.bashrc_$$(date +%Y%m%d%H%M%S).bak; \
		fi; \
		echo 'export PATH="$(PATH)"' > $(HOME)/.bashrc; \
		echo 'eval "$$(brew shellenv)"' >> $(HOME)/.bashrc; \
	fi
	@echo "${GREEN}Please restart your shell...${RESET}"

install: xcode brew python ansible devbox shellrc ## install ansible dependencies
	@echo "${GREEN}All ansible dependencies installed${RESET}"

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
