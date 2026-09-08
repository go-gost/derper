# Build Tailscale's derper pinned to a specific version. Bump ARG VERSION (or
# push a `vX.Y.Z` tag) to change the derper release; CI reads this line as the
# default version.
#
# Cross-compiles natively: the build stage runs on the builder's arch
# (BUILDPLATFORM) and emits a GOOS/GOARCH target binary, so CI does NOT pay
# QEMU-emulated Go compilation for arm64 — only the tiny apk runtime stage
# runs under QEMU.
FROM --platform=$BUILDPLATFORM golang:1.27 AS build
ARG VERSION=v1.102.3
# No defaults for TARGETOS/TARGETARCH: an explicit default overrides BuildKit's
# auto-injected target value, so an arm64 build would stay TARGETARCH=amd64 and
# emit an amd64 binary into the arm64 image.
ARG TARGETOS
ARG TARGETARCH
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
      go install tailscale.com/cmd/derper@${VERSION} \
 && find "$(go env GOPATH)/bin" -type f -name derper -exec cp {} /derper \;

# Minimal runtime. Non-root (uid 10001). The container listens on 8443 and
# 3478/udp (both >1024), so no NET_BIND_SERVICE privilege is needed.
FROM alpine:3.23
RUN apk add --no-cache ca-certificates \
 && adduser -D -u 10001 derper
COPY --from=build /derper /usr/local/bin/derper
USER derper
EXPOSE 8443/tcp 3478/udp
ENTRYPOINT ["/usr/local/bin/derper"]
