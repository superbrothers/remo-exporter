# syntax = docker/dockerfile:1
FROM --platform=${BUILDPLATFORM} golang:1.18 AS base
WORKDIR /src
ENV CGO_ENABLED=0
COPY go.* .
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download

FROM base AS build
ARG TARGETOS
ARG TARGETARCH
RUN --mount=target=. \
    --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -o /out/remo-exporter .

FROM scratch AS bin-unix
COPY --from=build /out/remo-exporter /

FROM bin-unix AS bin-linux
FROM bin-unix AS bin-darwin

FROM bin-${TARGETOS} as bin

FROM gcr.io/distroless/static:nonroot
COPY --from=build /out/remo-exporter /
ENTRYPOINT ["/remo-exporter"]
