#!/usr/bin/env bash

#   Copyright The containerd Authors.

#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at

#       http://www.apache.org/licenses/LICENSE-2.0

#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

#
# Releases and cross compile containerd.
#
set -eu -o pipefail

install_dependencies() {
  dpkg --add-architecture ${1}
  apt-get install crossbuild-essential-${1}
  apt-get install libseccomp-dev:${1}
}

# Add repositories with multiple architectures
cat <<EOF > /etc/apt/sources.list
deb [arch=amd64] http://archive.ubuntu.com/ubuntu/ bionic main multiverse restricted universe
deb [arch=armhf,arm64,ppc64el,s390x] http://ports.ubuntu.com/ubuntu-ports/ bionic main multiverse restricted universe
deb [arch=armhf,arm64,ppc64el,s390x] http://ports.ubuntu.com/ubuntu-ports/ bionic-updates main multiverse restricted universe
deb [arch=amd64] http://archive.ubuntu.com/ubuntu/ bionic-updates main multiverse restricted universe
deb [arch=amd64] http://security.ubuntu.com/ubuntu/ bionic-security main multiverse restricted universe
EOF

apt-get update

# Cross compile for the following architectures
CONTAINERD_ARCH=(
    amd64
    arm
    arm64
    ppc64le
    s390x
)

for arch in "${CONTAINERD_ARCH[@]}"; do
    make clean
    # Select the right compiler for each architecture
    # and install dependencies
    case ${arch} in
    arm)
      install_dependencies("armhf")
      CC="arm-linux-gnueabihf-gcc"
      ;;
    arm64)
      install_dependencies("arm64")
      CC="aarch64-linux-gnu-gcc"
      ;;
    ppc64le)
      install_dependencies("ppc64le")
      CC="powerpc64le-linux-gnu-gcc" 
      ;;
    s390x)
      install_dependencies("s390x")
      CC="s390x-linux-gnu-gcc" 
      ;;
    amd64)
      unset CC
      ;;
    esac

    make release GOARCH=${arch} CGO_ENABLED=1
done

