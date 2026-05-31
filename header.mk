#
# Makefile for compiling a Markdown-based wiki to HTML.
#

# =============================================================================
# Configuration
# =============================================================================

SHELL := /bin/bash
BUILD_DIR := build
_SCRIPTS_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
MARKDOWN_COMPILER := bash $(_SCRIPTS_DIR)compile-markdown.sh

# =============================================================================
# File Discovery
# =============================================================================

MD_FILE ?=
MD_FILES := $(shell find . -type f -name "*.md" -not -path "./$(BUILD_DIR)/*" -not -path "./.venv/*")
HTML_FILES := $(patsubst %.md,$(BUILD_DIR)/%.html,$(MD_FILES))

# =============================================================================
# Main Targets
# =============================================================================

.PHONY: all help build clean check

help:  ## Show help message.
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

all: $(HTML_FILES)  ## Build all markdown files.
	@echo "Syncing assets to build directory..."
	@rsync -a --prune-empty-dirs \
		--exclude='*.md' \
		--exclude='$(BUILD_DIR)/' \
		--exclude='scripts/' \
		--exclude='.git/' \
		--exclude='.venv/' \
		--checksum . $(BUILD_DIR)/

_check_md_set:
	@if [ -z "$(MD_FILE)" ]; then echo "Error: MD_FILE is not set."; exit 1; fi

build: _check_md_set  ## Build a single markdown file. Usage: make build MD_FILE=path/to/file.md
	@$(MAKE) $(patsubst %.md,$(BUILD_DIR)/%.html,$(MD_FILE))

clean:  ## Remove the build directory.
	@echo "Cleaning up $(BUILD_DIR)/..."
	@rm -rf $(BUILD_DIR)

check:  ## Check for orphaned resource files (non-md files not linked by any markdown).
	@bash $(_SCRIPTS_DIR)check-orphaned.sh

# =============================================================================
# Pattern Rules
# =============================================================================

$(BUILD_DIR)/%.html: %.md
	@mkdir -p $(dir $@)
	@bash $(_SCRIPTS_DIR)compile-markdown.sh -o $@ $<
