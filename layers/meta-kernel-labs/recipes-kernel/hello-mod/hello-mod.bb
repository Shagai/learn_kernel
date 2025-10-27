SUMMARY = "Simple Hello World out-of-tree kernel module"
DESCRIPTION = "A minimal example kernel module built with Yocto for learning."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=7ae2be7fb1637141840314b51970a9f7"

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

### Let module.bbclass drive kernel build context; no extra vars needed
# EXTRA_OEMAKE += "KERNELRELEASE=${KERNEL_VERSION}"
