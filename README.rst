docker-alpine-clang-llvm11
==========================

Provides an Alpine-based (3.13.2) Docker image with Clang and LLVM 11,
built from source.

.. code::

  $ docker build -t christimperley/alpine-clang-llvm11 .

In addition to providing LLVM, Clang, and Clang tools, built from source,
the following apk packages are provided as part of this image:

* binutils-gold
* cmake
* gcc
* git
* g++
* lld
* make
* musl-dev
* ninja
* python3
* zlib-dev
