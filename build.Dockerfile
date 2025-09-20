ARG GO_VERSION=1.25.1
FROM golang:${GO_VERSION}-alpine

RUN apk add --no-cache gcc musl-dev
WORKDIR /build
