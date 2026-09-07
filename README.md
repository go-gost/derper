# derper image

Self-hosted [Tailscale DERP](https://tailscale.com/kb/1232/derp-servers) relay +
STUN server image for [go-gost](https://gost.run) p2p, pinned to a specific
`tailscale.com/cmd/derper` version.

Built image: [`gogost/derper`](https://hub.docker.com/r/gogost/derper) (multi-arch `linux/amd64` + `linux/arm64`).

## Local build

```bash
docker build --build-arg VERSION=v1.102.3 -t derper:v1.102.3 .
```

## CI

GitHub Actions (`.github/workflows/build.yaml`) builds and pushes to Docker Hub on:

| Trigger | Image tag |
|---|---|
| push to `main` | `latest` |
| push tag `vX.Y.Z` | `vX.Y.Z` and `X.Y.Z` |
| manual `workflow_dispatch` (with `version` input) | `vX.Y.Z` and `X.Y.Z` |
| weekly schedule | `latest` (rebuilt for base-image updates) |

## Bumping the derper version

Either:

1. Push a tag matching the derper release: `git tag v1.102.4 && git push --tags`, or
2. Edit `ARG VERSION=` in the `Dockerfile` (this is the default used by
   `main`/schedule builds) and push to `main`.

## Run

```bash
docker run -d --name derper \
  -p 443:8443 -p 3478:3478/udp \
  -v "$PWD/certs:/certs:ro" \
  gogost/derper:v1.102.3 \
  -a=0.0.0.0:8443 -http-port=8080 -stun=true -stun-port=3478 \
  -verify-clients=false -certmode=manual -certdir=/certs -hostname=derp.example.com
```

`-certdir` expects files named literally `<hostname>.crt` and `<hostname>.key`.
`-verify-clients=false` is required for go-gost p2p (open relay).
