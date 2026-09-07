# derper image

Self-hosted [Tailscale DERP](https://tailscale.com/kb/1232/derp-servers) relay +
STUN server image, pinned to a specific `tailscale.com/cmd/derper` version.

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
| push tag `vX.Y.Z` | `X.Y.Z` |
| manual `workflow_dispatch` (with `version` input) | `X.Y.Z` |
| weekly schedule | `latest` (rebuilt for base-image updates) |

## Bumping the derper version

Either:

1. Push a tag matching the derper release: `git tag v1.102.4 && git push --tags`, or
2. Edit `ARG VERSION=` in the `Dockerfile` (this is the default used by
   `main`/schedule builds) and push to `main`.

## Deploy

Ready-to-use manifests live in [deploy/](deploy/):

| Platform | File | Mode |
|---|---|---|
| Kubernetes / k3s | [deploy.yaml](deploy/deploy.yaml) | plain HTTP behind a Traefik Ingress (TLS terminated there) |
| Single host | [docker-compose.yml](deploy/docker-compose.yml) | plain HTTP/WS on `:8443` |

The `deploy.yaml` Ingress carries no cert secret, so Traefik serves its
default self-signed certificate; supply a trusted one (secret or TLSStore) if
your clients verify certificates.

## Run

Single container with derper terminating TLS itself (manual certs):

```bash
docker run -d --name derper \
  -p 443:8443 -p 3478:3478/udp \
  -v "$PWD/certs:/certs:ro" \
  -v derper-data:/home/derper \
  gogost/derper:1.102.3 \
  -a=0.0.0.0:8443 -http-port=8080 -stun=true -stun-port=3478 \
  -verify-clients=false -certmode=manual -certdir=/certs -hostname=derp.example.com \
  -c=/home/derper/derper.key
```

`-certdir` expects files named literally `<hostname>.crt` and `<hostname>.key`.
`-verify-clients=false` disables client verification (an open relay).

`-c` is mandatory for the non-root image (with root it would default to
`/var/lib/derper/derper.key`): it holds the relay's private key,
auto-generated on first start. The `-v derper-data:/home/derper` volume keeps
that identity across restarts — a fresh named volume is seeded from the
image's `/home/derper` (owned by the non-root user), so no extra `chown`.
