FROM alpine:3.24
RUN apk add --update --no-cache git jq github-cli
ENV GITSV_VERSION=v3.0.2
RUN set -eux; \
	ARCH=$(uname -m | sed -E 's!^x86_64$!amd64!; s!^aarch64$!arm64!'); \
	wget -O - https://github.com/thegeeklab/git-sv/releases/download/${GITSV_VERSION}/git-sv-linux-${ARCH} > /usr/local/bin/git-sv; \
	chmod +x /usr/local/bin/git-sv; \
	git-sv --help >/dev/null || [ $? -eq 1 ]

COPY bin/* /usr/local/bin/
COPY config.yml /gitsv-home/.gitsv/
ENV HOME=/gitsv-home
# GitHub Actions requires UID 1001
USER 1001
ENTRYPOINT ["/usr/local/bin/git-sv"]
