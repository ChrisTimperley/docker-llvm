FROM ubuntu:xenial-20210416
# FROM ubuntu:noble-20240429
ARG DEBIAN_FRONTEND=noninteractive
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

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
        libbz2-dev \
        libffi-dev  \
        liblzma-dev \
        libncursesw5-dev \
        libreadline-dev \
        libsqlite3-dev  \
        libssl-dev \
        libxml2-dev \
        libxmlsec1-dev \
        musl-dev \
        ninja-build \
        software-properties-common \
        tk-dev \
        vim \
        wget \
        xz-utils \
        zlib1g-dev \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

ARG PYENV_VERSION="2.4.1"
RUN git clone https://github.com/pyenv/pyenv.git \
 && cd pyenv \
 && git checkout "v${PYENV_VERSION}" \
 && cd plugins/python-build \
 && ./install.sh

ARG PYTHON_VERSION="3.9.19"
RUN python-build "${PYTHON_VERSION}" /usr/local

ARG CMAKE_REPO_URL=https://github.com/Kitware/CMake
ARG CMAKE_VERSION="3.29.3"
RUN git clone "${CMAKE_REPO_URL}" /tmp/cmake \
 && cd /tmp/cmake \
 && git checkout "v${CMAKE_VERSION}" \
 && ./bootstrap \
 && make -j8 \
 && make install \
 && rm -rf /tmp/cmake

RUN add-apt-repository ppa:ubuntu-toolchain-r/test \
 && apt-get update \
 && apt-get install -y \
      gcc-8 \
      g++-8 \
 && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 800 --slave /usr/bin/g++ g++ /usr/bin/g++-8

ENV NINJA_VERSION="1.12.1"
RUN apt-get remove -y ninja-build \
 && cd /tmp \
 && git clone https://github.com/ninja-build/ninja \
 && cd ninja \
 && git checkout "v${NINJA_VERSION}" \
 && ./configure.py --bootstrap \
 && ./ninja all \
 && cp ./ninja /usr/local/bin \
 && rm -rf /tmp/ninja

ARG LLVM_DIR=/opt/llvm
ARG LLVM_VERSION="11.1.0"
RUN git clone https://github.com/llvm/llvm-project.git /tmp/llvm \
 && cd /tmp/llvm \
 && git checkout "llvmorg-${LLVM_VERSION}" \
 && mkdir build \
 && cd build \
 && cmake \
    -DCMAKE_INSTALL_PREFIX="${LLVM_DIR}" \
    -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra;compiler-rt" \
    -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind" \
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
