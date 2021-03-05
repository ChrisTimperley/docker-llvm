FROM alpine:3.13.2 as build
RUN apk --no-cache add \
      binutils-gold \
      cmake \
      gcc \
      git \
      g++ \
      lld \
      make \
      musl-dev \
      ninja \
      python3 \
      zlib-dev

WORKDIR /tmp/llvm
ARG LLVM_VERSION=11.1.0
RUN git clone https://github.com/llvm/llvm-project.git /tmp/llvm \
 && git checkout "llvmorg-${LLVM_VERSION}"

RUN mkdir build \
 && cd build \
 && cmake \
    -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra" \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_PARALLEL_LINK_JOBS=1 \
    -G Ninja \
    ../llvm \
 && cd build \
 && ninja \
 && ninja install

RUN rm -rf /tmp/llvm
