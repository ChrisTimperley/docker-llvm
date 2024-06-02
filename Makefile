DOCKER_ORG=christimperley

llvm18:
	docker build --build-arg LLVM_VERSION=18.1.6 -t ${DOCKER_ORG}/$@ .

llvm18-stage-one:
	docker build --target stage_one --build-arg LLVM_VERSION=18.1.6 -t ${DOCKER_ORG}/$@ .

llvm18-alpine:
	docker build -f Dockerfile.alpine -t ${DOCKER_ORG}/$@ .

llvm12:
	docker build --build-arg LLVM_VERSION=12.0.1 -t ${DOCKER_ORG}/$@ .

llvm11:
	docker build --build-arg LLVM_VERSION=11.1.0 -t ${DOCKER_ORG}/$@ .

.PHONY: llvm11 llvm12 llvm18
