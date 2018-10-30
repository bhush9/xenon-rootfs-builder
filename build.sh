#!/bin/sh

set -ex

export ARCH=arm64
export DIST=bionic

# configure the live-build
lb config \
        --mode ubuntu \
        --distribution $DIST \
        --binary-images none \
        --memtest none \
        --source false \
        --archive-areas "main restricted universe multiverse" \
        --apt-source-archives true \
        --architectures $ARCH \
        --linux-flavours none \
        --bootloader none \
        --initramfs-compression lzma \
        --initsystem none \
        --chroot-filesystem plain \
        --apt-options "--yes -o Debug::pkgProblemResolver=true" \
        --compression gzip \
        --system normal \
        --zsync false \
        --linux-packages=none \
        --backports true \
        --apt-recommends false \
        --initramfs=none

. /etc/os-release # to get access to version_codename; NB: of host container!

apt install -y dirmngr gnupg1
GPG="gpg1"
ARGS="--batch --verbose"

# Copy the customization
cp -rf customization/* config/

$GPG --list-keys
$GPG \
  $ARGS \
  --no-default-keyring \
  --primary-keyring config/archives/packages.key \
  --keyserver pool.sks-keyservers.net \
  --recv-keys 'CB87 A99C D05E 5E0C 7017  4A68 E8AF 1B0B 45D8 3EBD'

$GPG \
  $ARGS \
  --no-default-keyring \
  --primary-keyring config/archives/packages.key \
  --keyserver pool.sks-keyservers.net \
  --recv-keys '444D ABCF 3667 D028 3F89  4EDD E6D4 7362 5575 1E5D'

chmod 644 config/archives/packages.key

# build the rootfs
lb build

# live-build itself is meh, it creates the tarball with directory structure of binary/boot/filesystem.dir
# so we pass --binary-images none to lb config and create tarball on our own
if [ -e "binary/boot/filesystem.dir" ]; then
        (cd "binary/boot/filesystem.dir/" && tar -c *) | gzip -9 --rsyncable > "xenon-rootfs.tar.gz"
        ls -lah
        chmod 644 "xenon-rootfs.tar.gz"
fi
