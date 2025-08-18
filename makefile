.PHONY: all build test fmt
all: build

test:
	go test ./pkg/...

build:
	go build -o bin/scrubectl

fmt:
	go fmt ./...