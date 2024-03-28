# syntax=docker/dockerfile:1.4
FROM golang:latest as dive-builder
WORKDIR /app
ARG GOLANG_CI_VERSION=${GOLANG_CI_VERSION:-v1.52.2}
ARG GOBOUNCER_VERSION=${GOBOUNCER_VERSION:-v0.4.0}
ARG GORELEASER_VERSION=${GORELEASER_VERSION:-v1.19.1}
ARG GOSIMPORTS_VERSION=${GOSIMPORTS_VERSION:-v0.3.8}
ARG CHRONICLE_VERSION=${CHRONICLE_VERSION:-v0.6.0}
ARG GLOW_VERSION=${GLOW_VERSION:-v1.5.0}
ENV CGO_ENABLED="0"
ENV GOOS="linux"
ENV GOARCH="amd64"
COPY --link ./ /app
RUN go mod download
RUN curl -sSfL https://raw.githubusercontent.com/anchore/chronicle/main/install.sh | sh -s -- ${CHRONICLE_VERSION}
RUN curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- ${GOLANG_CI_VERSION}
RUN curl -sSfL https://raw.githubusercontent.com/wagoodman/go-bouncer/master/bouncer.sh | sh -s -- ${GOBOUNCER_VERSION}
RUN go install github.com/goreleaser/goreleaser@${GORELEASER_VERSION}
RUN go install github.com/rinchsan/gosimports/cmd/gosimports@${GOSIMPORTS_VERSION}
RUN go install github.com/charmbracelet/glow@${GLOW_VERSION}
RUN go build -ldflags="-s -w" -o /app/build/dive

FROM alpine:3.18 as dive
ARG DOCKER_CLI_VERSION=${DOCKER_CLI_VERSION:-26.0.0}
RUN wget -O- https://download.docker.com/linux/static/stable/$(uname -m)/docker-${DOCKER_CLI_VERSION}.tgz | \
    tar -xzf - docker/docker --strip-component=1 && \
    mv docker /usr/local/bin
COPY --chown=1000:1000 --chmod=0755 --link --from=dive-builder /app/build/dive /usr/local/bin/dive
ENTRYPOINT ["/usr/local/bin/dive"]

