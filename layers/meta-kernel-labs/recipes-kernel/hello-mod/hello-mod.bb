SUMMARY = "Simple Hello World out-of-tree kernel module"
DESCRIPTION = "A minimal example kernel module built with Yocto for learning."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=1d3b9ff6f7b1b79a6f4d6f4f2f1b6a8b"

SRC_URI = " \
    file://hello.c \
    file://Makefile \
    file://LICENSE \
"

S = "${WORKDIR}"

inherit module

# Package name for module auto-load helper
RPROVIDES:${PN} += "kernel-module-hello"

# Auto-load on boot to verify it works in QEMU
KERNEL_MODULE_AUTOLOAD += "hello"

EXTRA_OEMAKE += "KERNELRELEASE=${KERNEL_VERSION}" 
