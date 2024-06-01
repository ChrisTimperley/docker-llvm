ARG LLVM_DIR=/opt/llvm

FROM ubuntu:xenial-20210416 AS base
# FROM ubuntu:noble-20240429
ARG DEBIAN_FRONTEND=noninteractive
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        autoconf \
        libtool \
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

 # manually install PPA (ubuntu-toolchain-r/test): http://ppa.launchpad.net/ubuntu-toolchain-r/test/ubuntu
RUN apt-get update \
 && apt-get install -y \
     lsb-release \
 && echo "deb http://ppa.launchpad.net/ubuntu-toolchain-r/test/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/ubuntu-toolchain-r-test.list \
 && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 60C317803A41BA51845E371A1E9377A2BA9EF27F \
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

ARG LLVM_VERSION="11.1.0"
RUN git clone https://github.com/llvm/llvm-project.git /tmp/llvm \
 && cd /tmp/llvm \
 && git checkout "llvmorg-${LLVM_VERSION}" \
 && mkdir build

# STAGE ONE
#
# LLVM_ENABLE_LIBCXX=ON \
# LLVM_STATIC_LINK_CXX_STDLIB=ON \
# LLVM_ENABLE_LLD=true \
FROM base as stage_one
ARG LLVM_DIR
RUN cd /tmp/llvm/build \
 && cmake \
    -DCMAKE_INSTALL_PREFIX="${LLVM_DIR}" \
    -DLLVM_ENABLE_PROJECTS="lldb;lld;clang;clang-tools-extra;compiler-rt" \
    -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind" \
    -DLLVM_TARGETS_TO_BUILD="X86;AArch64;ARM" \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_ENABLE_ASSERTIONS=true \
    -DLLVM_ENABLE_RTTI=true \
    -DLLVM_PARALLEL_LINK_JOBS=1 \
    -G Ninja \
    ../llvm \
 && ninja \
 && ninja install

# NOTE this works ONLY for Linux x86_64; breaks for AAarch64 and ARM due to LD_LIBRARY_PATH
FROM base as stage_two
ARG LLVM_DIR
COPY --from=stage_one /opt/llvm /opt/llvm
ENV PATH "${LLVM_DIR}/bin:${PATH}"
ENV LD_LIBRARY_PATH "${LLVM_DIR}/lib/x86_64-unknown-linux-gnu:${LLVM_DIR}/lib:${LD_LIBRARY_PATH}"
ENV C_INCLUDE_PATH "${LLVM_DIR}/include:${C_INCLUDE_PATH}"
ENV CPLUS_INCLUDE_PATH "${LLVM_DIR}/include:${CPLUS_INCLUDE_PATH}"
RUN cd /tmp/llvm/build \
 && cmake \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_INSTALL_PREFIX="${LLVM_DIR}" \
    -DLLVM_ENABLE_PROJECTS="lldb;lld;clang;clang-tools-extra;compiler-rt" \
    -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind" \
    -DLLVM_TARGETS_TO_BUILD="X86;AArch64;ARM" \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_ENABLE_ASSERTIONS=true \
    -DLLVM_ENABLE_RTTI=true \
    -DLLVM_PARALLEL_LINK_JOBS=1 \
    -DLLVM_ENABLE_LIBCXX=ON \
    -DLLVM_ENABLE_LLVM_LIBC=ON \
    -DLLVM_ENABLE_LLD=true \
    -G Ninja \
    ../llvm \
 && ninja \
 && ninja install

# NOTE this works ONLY for Linux x86_64; breaks for AAarch64 and ARM due to LD_LIBRARY_PATH
FROM base as stage_three
ARG LLVM_DIR
COPY --from=stage_two /opt/llvm /opt/llvm
ENV PATH "${LLVM_DIR}/bin:${PATH}"
ENV LD_LIBRARY_PATH "${LLVM_DIR}/lib/x86_64-unknown-linux-gnu:${LLVM_DIR}/lib:${LD_LIBRARY_PATH}"
ENV C_INCLUDE_PATH "${LLVM_DIR}/include:${C_INCLUDE_PATH}"
ENV CPLUS_INCLUDE_PATH "${LLVM_DIR}/include:${CPLUS_INCLUDE_PATH}"
RUN cd /tmp/llvm/build \
 && cmake \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_EXE_LINKER_FLAGS="-lc++abi" \
    -DCMAKE_SHARED_LINKER_FLAGS="-lc++abi" \
    -DCMAKE_INSTALL_PREFIX="${LLVM_DIR}" \
    -DLLVM_ENABLE_PROJECTS="lldb;lld;clang;clang-tools-extra;compiler-rt" \
    -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind" \
    -DLLVM_TARGETS_TO_BUILD="X86;AArch64;ARM" \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_ENABLE_ASSERTIONS=true \
    -DLLVM_ENABLE_RTTI=true \
    -DLLVM_PARALLEL_LINK_JOBS=1 \
    -DLLVM_ENABLE_LIBCXX=ON \
    -DLLVM_STATIC_LINK_CXX_STDLIB=ON \
    -DLLVM_ENABLE_LLVM_LIBC=ON \
    -DLLVM_ENABLE_LLD=true \
    -G Ninja \
    ../llvm \
 && ninja \
 && ninja install

#
# #    -DLIBCXX_ENABLE_SHARED=NO \
# #    -DLIBCXX_ENABLE_STATIC=YES \
# # RUN cd /tmp/llvm/build \
# #  && cmake \
# #     -DCMAKE_BUILD_TYPE=Release \
# #     -DCMAKE_C_COMPILER=clang \
# #     -DCMAKE_CXX_COMPILER=clang++ \
# #     -DCMAKE_INSTALL_PREFIX="${LLVM_DIR}" \
# #     -DLIBCXXABI_USE_LLVM_UNWINDER=YES \
# #     -DLIBCXX_CXX_ABI=libcxxabi \
# #     -DCLANG_ENABLE_BOOTSTRAP=ON \
# #     -DBUILD_SHARED_LIBS=OFF \
# #     -DCMAKE_AR=llvm-ar \
# #     -DCMAKE_EXE_LINKER_FLAGS="-lc++ -lc++abi -lunwind -lm -lpthread" \
# #     -DLLVM_ENABLE_PROJECTS="lldb;lld;clang;clang-tools-extra;compiler-rt" \
# #     -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind" \
# #     -DLLVM_TARGETS_TO_BUILD="X86;AArch64;ARM" \
# #     -DLLVM_ENABLE_ASSERTIONS=true \
# #     -DLLVM_ENABLE_RTTI=true \
# #     -DLLVM_PARALLEL_LINK_JOBS=1 \
# #     -DLLVM_ENABLE_LIBCXX=ON \
# #     -DLLVM_ENABLE_LLVM_LIBC=ON \
# #     -DLLVM_ENABLE_LLD=true \
# #     -G Ninja \
# #     ../llvm \
# #  && ninja \
# #  && ninja install
#
