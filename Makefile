DOCKER_ORG=christimperley

llvm11:
	docker build --build-arg LLVM_VERSION=11.1.0 -t ${DOCKER_ORG}/$@ .

llvm12:
	docker build --build-arg LLVM_VERSION=12.0.1 -t ${DOCKER_ORG}/$@ .

.PHONY: llvm11 llvm12
