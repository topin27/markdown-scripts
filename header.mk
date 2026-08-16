#
# Makefile for compiling a Markdown-based wiki to HTML.
#

# =============================================================================
# Configuration
# =============================================================================

SHELL := /bin/bash
_SCRIPTS_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
MARKDOWN_COMPILER := bash $(_SCRIPTS_DIR)compile-markdown.sh

# =============================================================================
# File Discovery
# =============================================================================

MD_FILES := $(shell find . -type f -name "*.md" -not -path "./.venv/*" -not -path "./scripts/*")
HTML_FILES := $(patsubst %.md,%.html,$(MD_FILES))

# =============================================================================
# Main Targets
# =============================================================================

.PHONY: all help clean check

help:  ## Show help message.
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

all: $(HTML_FILES)  ## Build all markdown files.

clean:  ## Remove all generated HTML files.
	@echo "Cleaning up HTML files..."
	@find . -type f -name "*.html" -not -path "./.venv/*" -not -path "./.git/*" -delete

check:  ## Check for orphaned resource files (non-md files not linked by any markdown).
	@bash $(_SCRIPTS_DIR)check-orphaned.sh

# =============================================================================
# Pattern Rules
# =============================================================================

%.html: %.md
	@$(MARKDOWN_COMPILER) -o $@ $<
