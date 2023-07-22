FROM alpine:3.18
RUN apk add --update --no-cache git jq github-cli
ENV SV4GIT_VERSION=2.9.0
RUN set -eux; \
	PLATFORM=$(uname -s | tr '[:upper:]' '[:lower:]')_$(uname -m | sed -E 's!^x86_64$!amd64!; s!^aarch64$!arm64!'); \
	wget -O - https://github.com/bvieira/sv4git/releases/download/v2.9.0/git-sv_${SV4GIT_VERSION}_${PLATFORM}.tar.gz | tar -xzf - -C /usr/local/bin; \
	git-sv --help >/dev/null || [ $? -eq 1 ]

COPY bin/* /usr/local/bin/
COPY config.yml /sv4git-home/
ENV SV4GIT_HOME=/sv4git-home
# GitHub Actions requires UID 1001
USER 1001
ENTRYPOINT ["/usr/local/bin/git-sv"]
