[group('local')]
test:
  go test -coverprofile cover.out -coverpkg=./... -v ./...
  go tool cover -html cover.out -o cover.html

[group('local')]
make:
  go build

[group('local')]
lint:
  golangci-lint run --fix

plugin-name := "gotify-slack-webhook"
build-dir := "_build"
gotify-version := "master" # Or set to an specific version ("v.2.7.2" for example)

# Fetches the go version from gotify/server
get-go-version:
    #!/usr/bin/env bash
    set -e
    mkdir -p {{build-dir}}
    wget -O {{build-dir}}/gotify-server-go-version https://raw.githubusercontent.com/gotify/server/{{gotify-version}}/GO_VERSION
    cat {{build-dir}}/gotify-server-go-version

# Fetches go.mod from gotify/server and updates the current go.mod
update-go-mod:
    mkdir -p {{build-dir}}
    wget -O {{build-dir}}/gotify-server.mod https://raw.githubusercontent.com/gotify/server/{{gotify-version}}/go.mod
    go run github.com/gotify/plugin-api/cmd/gomod-cap -from {{build-dir}}/gotify-server.mod -to go.mod
    go mod tidy

# Builds the plugin for a specific architecture
_build arch:
    #!/usr/bin/env bash
    set -e
    mkdir -p {{build-dir}}
    GO_VERSION=$(cat {{build-dir}}/gotify-server-go-version)
    DOCKER_IMAGE="gotify/build:$GO_VERSION-linux-{{arch}}"
    if [[ "{{arch}}" == "arm64" ]]; then
        DOCKER_IMAGE="gotify-build-arm64"
        docker build . -f build.Dockerfile -t gotify-build-arm64 --build-arg GO_VERSION=$GO_VERSION
    fi

    docker run --rm -v "$PWD/.:/build" -w /build $DOCKER_IMAGE go build -mod=readonly -a -installsuffix cgo -ldflags="-w -s" -buildmode=plugin -o {{build-dir}}/{{plugin-name}}-linux-{{arch}}.so

# Build all architectures
build: _build "linux-amd64" _build "linux-arm-7" _build "linux-arm64"

# Runs gotify server with the plugin
run:
  docker run --rm -v "$PWD/{{build-dir}}:/app/data/plugins" -p 8080:80 gotify/server

# Setup build environment
setup: get-go-version update-go-mod

.PHONY: build setup
