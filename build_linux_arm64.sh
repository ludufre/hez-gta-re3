#!/bin/bash
# Builds a native Linux aarch64 reVC binary (e.g. Raspberry Pi 5) inside a debian:bookworm linux/arm64 container.
# Output: bin/linux-arm64-librw_gl3_glfw-oal/Release/reVC
#
# Usage from the repo root (works on an Apple Silicon Mac or any arm64 Docker host):
#   docker run --rm --platform linux/arm64 -v "$PWD:/src" -w /src debian:bookworm bash /src/build_linux_arm64.sh
set -ex
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq build-essential git uuid-dev \
  libglfw3-dev libopenal-dev libsndfile1-dev libmpg123-dev libgl1-mesa-dev >/dev/null

# The bundled premake5Linux is x86_64 only; build premake for arm64
if ! command -v premake5; then
  git clone -q --depth 1 -b v5.0.0-beta2 https://github.com/premake/premake-core /tmp/premake-core
  make -C /tmp/premake-core -f Bootstrap.mak linux -j"$(nproc)" >/dev/null
  cp /tmp/premake-core/bin/release/premake5 /usr/local/bin/
fi

# The prebuild step writes GitSHA1.cpp, but a parallel make can ask for it first
git config --global --add safe.directory /src
sh printHash.sh src/extras/GitSHA1.cpp

# Bookworm ships glfw 3.3, so let GLFW read the keyboard instead of the X server
premake5 --with-librw --no-x11-keyboard gmake2
# The decompiled code expects x86 char signedness and does a lot of type punning
export CFLAGS="-fsigned-char -fno-strict-aliasing" CXXFLAGS="-fsigned-char -fno-strict-aliasing"
make -C build config=release_linux-arm64-librw_gl3_glfw-oal -j"$(nproc)"
