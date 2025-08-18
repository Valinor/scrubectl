OUTPUT = main # Referenced as Handler in sar-template.json

APP_NAME ?= scrubectl
GOREL_ARGS ?= 
GOREL ?= goreleaser
GOPROXY = direct

# Verbose flag support
# Use VERBOSE=1 for verbose output (e.g., 'make test VERBOSE=1')
VERBOSE ?= 0
ifeq ($(VERBOSE),1)
	VERBOSE_FLAG = -v
	VERBOSE_TEST_FLAG = -v
	VERBOSE_BUILD_FLAG = --verbose
	VERBOSE_CURL_FLAG = -v
	Q =
else
	VERBOSE_FLAG =
	VERBOSE_TEST_FLAG =
	VERBOSE_BUILD_FLAG =
	VERBOSE_CURL_FLAG = -s
	Q = @
endif

# Tool versions
GOLANGCI_LINT_VERSION ?= v2.4.0
GORELEASER_VERSION ?= v2.11.2
UPX_VERSION ?= v4.2.4

# Tool installation paths
TOOLS_DIR := $(shell pwd)/.bin
GOLANGCI_LINT := $(TOOLS_DIR)/golangci-lint
GORELEASER_BIN := $(TOOLS_DIR)/goreleaser
UPX := $(TOOLS_DIR)/upx

# Detect OS and architecture
OS := $(shell uname -s | tr '[:upper:]' '[:lower:]')
ARCH := $(shell uname -m)
ifeq ($(ARCH),x86_64)
	ARCH := x86_64

endif
ifeq ($(ARCH),aarch64)
	ARCH := arm64
endif

.PHONY: install-deps
install-deps: install-golangci-lint install-goreleaser install-upx
	$(Q)echo "All development dependencies installed"

.PHONY: install-golangci-lint
install-golangci-lint:
	$(Q)echo "Installing golangci-lint $(GOLANGCI_LINT_VERSION)..."
	$(Q)mkdir -p $(TOOLS_DIR)
	@if [ ! -f $(GOLANGCI_LINT) ] || [ "$$($(GOLANGCI_LINT) --version 2>/dev/null | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+')" != "$(GOLANGCI_LINT_VERSION)" ]; then \
		curl $(VERBOSE_CURL_FLAG)SfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(TOOLS_DIR) $(GOLANGCI_LINT_VERSION); \
		echo "golangci-lint $(GOLANGCI_LINT_VERSION) installed"; \
	else \
		echo "golangci-lint $(GOLANGCI_LINT_VERSION) already installed"; \
	fi

.PHONY: install-goreleaser
install-goreleaser:
	$(Q)echo "Installing goreleaser $(GORELEASER_VERSION)..."
	$(Q)mkdir -p $(TOOLS_DIR)
	@if [ ! -f $(GORELEASER_BIN) ] || [ "$$($(GORELEASER_BIN) --version 2>/dev/null | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+')" != "$(GORELEASER_VERSION)" ]; then \
		curl $(VERBOSE_CURL_FLAG)SfL https://github.com/goreleaser/goreleaser/releases/download/$(GORELEASER_VERSION)/goreleaser_$(OS)_$(ARCH).tar.gz | tar -xz -C $(TOOLS_DIR) goreleaser; \
		chmod +x $(GORELEASER_BIN); \
		echo "goreleaser $(GORELEASER_VERSION) installed"; \
	else \
		echo "goreleaser $(GORELEASER_VERSION) already installed"; \
	fi

.PHONY: install-upx
install-upx:
	$(Q)echo "Installing upx $(UPX_VERSION)..."
	$(Q)mkdir -p $(TOOLS_DIR)
	@if [ ! -f $(UPX) ] || [ "$$($(UPX) --version 2>/dev/null | head -1 | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+')" != "$(UPX_VERSION)" ]; then \
		UPX_ARCH=$(ARCH); \
		if [ "$(ARCH)" = "x86_64" ]; then UPX_ARCH="amd64"; fi; \
		if [ "$(ARCH)" = "arm64" ]; then UPX_ARCH="arm64"; fi; \
		if [ "$(OS)" = "linux" ]; then \
			UPX_FILE="upx-$(UPX_VERSION:v%=%)-$${UPX_ARCH}_linux"; \
		elif [ "$(OS)" = "darwin" ]; then \
			UPX_FILE="upx-$(UPX_VERSION:v%=%)-amd64_macos"; \
		else \
			echo "Error: Unsupported OS $(OS) for UPX installation"; \
			exit 1; \
		fi; \
		curl $(VERBOSE_CURL_FLAG)SfL https://github.com/upx/upx/releases/download/$(UPX_VERSION)/$${UPX_FILE}.tar.xz | tar -xJ -C $(TOOLS_DIR) --strip-components=1 $${UPX_FILE}/upx; \
		chmod +x $(UPX); \
		echo "upx $(UPX_VERSION) installed"; \
	else \
		echo "upx $(UPX_VERSION) already installed"; \
	fi

.PHONY: test
test:
	$(Q)go test $(VERBOSE_TEST_FLAG) ./... -coverprofile=coverage.out

.PHONY: test-verbose
test-verbose:
	$(Q)go test -v ./... -coverprofile=coverage.out

.PHONY: test-coverage
test-coverage: test
	go tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report generated: coverage.html"

.PHONY: go-build
go-build: install-goreleaser
	$(Q)$(GORELEASER_BIN) build --snapshot --clean --id scrubectl $(VERBOSE_BUILD_FLAG) $(GOREL_ARGS)

.PHONY: clean
clean:
	rm -f $(OUTPUT) $(PACKAGED_TEMPLATE) bootstrap coverage.out coverage.html
	rm -rf dist/

.PHONY: clean-all
clean-all: clean
	rm -rf $(TOOLS_DIR)

.PHONY: config
config:
	go mod download

.PHONY: vet
vet: install-golangci-lint
	$(GOLANGCI_LINT) run

.PHONY: lint
lint: vet

.PHONY: fmt
fmt:
	$(Q)go fmt $(VERBOSE_FLAG) ./...
	$(Q)go mod tidy $(VERBOSE_FLAG)

main: main.go install-goreleaser
	$(Q)echo $(GORELEASER_BIN) build --clean $(VERBOSE_BUILD_FLAG) $(GOREL_ARGS)
	$(Q)$(GORELEASER_BIN) build --clean $(VERBOSE_BUILD_FLAG) $(GOREL_ARGS)

.PHONY: build
build: clean main

.PHONY: release
release: install-goreleaser
	$(Q)$(GORELEASER_BIN) release --clean $(VERBOSE_BUILD_FLAG) $(GOREL_ARGS)

.PHONY: dry-run
dry-run: 
	$(MAKE) GOREL_ARGS=--skip=publish release


.PHONY: dev
dev: go-build
	@echo "Running development build for $(OS)/$(ARCH)..."
	@if [ "$(ARCH)" = "arm64" ]; then \
		BINARY_PATH="dist/scrubectl_$(OS)_arm64_v8.2/scrubectl"; \
	elif [ "$(ARCH)" = "x86_64" ]; then \
		BINARY_PATH="dist/scrubectl_$(OS)_amd64_v1/scrubectl"; \
	else \
		BINARY_PATH=$$(find dist/ -name "scrubectl_$(OS)_*" -type f | head -1); \
	fi; \
	if [ ! -f "$$BINARY_PATH" ]; then \
		echo "Error: Binary not found at $$BINARY_PATH. Available binaries:"; \
		find dist/ -name "scrubectl*" -type f || echo "No binaries found in dist/"; \
		exit 1; \
	fi; \
	echo "Using binary: $$BINARY_PATH"; \
	$$BINARY_PATH \
		--config-file config.yaml \
		--log-file /dev/stdout \
		--log-level debug
		
.PHONY: check-tools
check-tools:
	@echo "Checking installed tools..."
	@if [ -f $(GOLANGCI_LINT) ]; then echo "✓ golangci-lint: $$($(GOLANGCI_LINT) --version)"; else echo "✗ golangci-lint: not installed"; fi
	@if [ -f $(GORELEASER_BIN) ]; then echo "✓ goreleaser: $$($(GORELEASER_BIN) --version)"; else echo "✗ goreleaser: not installed"; fi
	@if [ -f $(UPX) ]; then echo "✓ upx: $$($(UPX) --version 2>/dev/null | head -1)"; else echo "✗ upx: not installed"; fi
	@echo "Go version: $$(go version)"

.PHONY: setup
setup: install-deps config
	@echo "Development environment setup complete"

.PHONY: all build test fmt
all: build

