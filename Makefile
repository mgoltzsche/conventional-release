IMAGE=mgoltzsche/conventional-release

all: build

build:
	docker build --force-rm -t $(IMAGE) .

test: build
	docker run --rm -v "`pwd`:/src" -w /src -u `id -u` -e GITHUB_OUTPUT=/tmp/out --entrypoint prepare-release $(IMAGE)
