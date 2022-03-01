FROM ubuntu:xenial-20210416
ARG DEBIAN_FRONTEND=noninteractive
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

# note that we need to install a newer version of cmake through a pass
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        apt-transport-https \
        build-essential \
        ca-certificates \
        curl \
        g++ \
        gcc \
        git \
        libboost-all-dev \
        musl-dev \
        ninja-build \
        python3 \
        python3-pip \
        software-properties-common \
        vim \
        wget \
        zlib1g-dev \
 && wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null \
  | gpg --dearmor - \
  | tee /etc/apt/trusted.gpg.d/kitware.gpg > /dev/null \
 && apt-add-repository 'deb https://apt.kitware.com/ubuntu/ xenial main' \
 && apt-get update \
 && apt-get install -y cmake \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

ARG LLVM_DIR=/opt/llvm
ARG LLVM_VERSION="11.1.0"
RUN git clone https://github.com/llvm/llvm-project.git /tmp/llvm \
 && cd /tmp/llvm \
 && git checkout "llvmorg-${LLVM_VERSION}" \
 && cd /tmp/llvm \
 && mkdir build \
 && cd build \
 && cmake \
    -DCMAKE_INSTALL_PREFIX="${LLVM_DIR}" \
    -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra;libcxx;libcxxabi;compiler-rt" \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_ENABLE_ASSERTIONS=true \
    -DLLVM_ENABLE_RTTI=true \
    -DLLVM_PARALLEL_LINK_JOBS=1 \
    -G Ninja \
    ../llvm \
 && ninja \
 && ninja install \
 && rm -rf /tmp/llvm
ENV PATH "${LLVM_DIR}/bin:${PATH}"
