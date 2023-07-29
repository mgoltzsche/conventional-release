IMAGE ?= mgoltzsche/conventional-release
PLATFORMS ?= linux/arm64/v8,linux/amd64
BUILD_OPTS=--load

all: build

build-multiarch: PLATFORM=$(PLATFORMS)
build-multiarch: build
build:
	$(eval OPT=$(shell [ "$(PLATFORM)" ] && echo "--platform=$(PLATFORM)"))
	docker buildx build --force-rm $(OPT) $(BUILD_OPTS) -t $(IMAGE) .

test: build
	docker run --rm -v "`pwd`:/src" -w /src -u `id -u` \
		-e GITHUB_OUTPUT=/tmp/out \
		--entrypoint prepare-release \
		$(IMAGE)
