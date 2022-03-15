IMAGE ?= ghcr.io/superbrothers/remo-exporter
TAG ?= dev
ARCH ?= amd64
ALL_ARCH ?= amd64 arm64
QEMU_VERSION ?= 6.1.0-8

.PHONY: build
build:
ifneq ($(ARCH),amd64)
	docker run --rm --privileged multiarch/qemu-user-static:$(QEMU_VERSION) --reset -p yes
	docker buildx version
	BUILDER=$$(docker buildx create --use)
endif
	docker buildx build --pull --load --platform $(ARCH) -t $(IMAGE)-$(ARCH):$(TAG) .
ifneq ($(ARCH),amd64)
	docker buildx rm "$${BUILDER}"
endif

build-%:
	$(MAKE) ARCH=$* build

.PHONY: build-all
build-all: $(addprefix build-,$(ALL_ARCH))

.PHONY: push
push:
	docker push $(IMAGE)-$(ARCH):$(TAG)

push-%:
	$(MAKE) ARCH=$* push

.PHONY: push-all
push-all: $(addprefix push-,$(ALL_ARCH))

.PHONY: push-manifest
push-manifest:
	docker manifest create --amend $(IMAGE):$(TAG) $(shell echo $(ALL_ARCH) | sed -e "s~[^ ]*~$(IMAGE)\-&:$(TAG)~g")
	@for arch in $(ALL_ARCH); do docker manifest annotate --arch $${arch} $(IMAGE):$(TAG) $(IMAGE)-$${arch}:$(TAG); done
	docker manifest push --purge $(IMAGE):$(TAG)

.PHONY: all-push
all-push: push-all push-manifest
