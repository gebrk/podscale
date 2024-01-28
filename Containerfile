FROM docker.io/library/alpine as fetch

# Add curl and ca-certs
RUN apk add ca-certificates curl

# Download the latests static tailscale
RUN set -euo pipefail \
    && curl -o /tailscale.tgz -sSL https://pkgs.tailscale.com/stable/tailscale_latest_amd64.tgz \
    && tar xf /tailscale.tgz -C / --strip-components 1

FROM scratch

ENV TS_LOGS_DIR=/state/

ADD state/ /state/
# Nab ca-certificates from Alpine rather than maintain a local copy
COPY --from=fetch /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=fetch tailscale tailscaled /

CMD ["/tailscaled", "-statedir", "/state", "-tun", "userspace-networking", "-socket", "/tailscaled.sock"]
