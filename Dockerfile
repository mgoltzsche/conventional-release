FROM golang:1.20-alpine3.18 AS sv4git
ENV SV4GIT_VERSION=v2.9.0
RUN go install github.com/bvieira/sv4git/v2/cmd/git-sv@$SV4GIT_VERSION

FROM alpine:3.18
RUN apk add --update --no-cache git jq github-cli
COPY --from=sv4git /go/bin/git-sv /usr/local/bin/
COPY bin/* /usr/local/bin/
# GitHub Actions requires UID 1001
USER 1001
ENTRYPOINT ["/usr/local/bin/git-sv"]
