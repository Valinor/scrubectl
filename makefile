.PHONY: all build test fmt
all: build

test:
	go test ./pkg/scrubctl

build:
	go build -o bin/scrubctl

fmt:
	go fmt ./...