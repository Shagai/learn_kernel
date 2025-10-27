#!/usr/bin/env python3
import glob
import os
import sys
import time
import pexpect

OUT_DIR = "/work/out"
DEPLOY_DIR = "/work/out/images/qemuarm64"

os.makedirs(OUT_DIR, exist_ok=True)

# Pick the latest qemuboot.conf produced by the build
confs = sorted(glob.glob(os.path.join(DEPLOY_DIR, "core-image-minimal-qemuarm64.rootfs-*.qemuboot.conf")))
if not confs:
    print("No qemuboot.conf found under {}. Build the image first.".format(DEPLOY_DIR), file=sys.stderr)
    sys.exit(1)
# Find kernel Image and rootfs
kernels = sorted(glob.glob(os.path.join(DEPLOY_DIR, "Image--*.bin")))
rootfs = sorted(glob.glob(os.path.join(DEPLOY_DIR, "core-image-minimal-qemuarm64.rootfs-*.ext4")))
if not kernels or not rootfs:
    print("Missing kernel Image or rootfs ext4 in {}. Build may be incomplete.".format(DEPLOY_DIR), file=sys.stderr)
    sys.exit(1)
kernel = kernels[-1]
rootfs_img = rootfs[-1]

log_path = os.path.join(OUT_DIR, "qemu_hello_autoload.log")

# Launch qemu-system-aarch64 directly to avoid runqemu helper dependencies
cmd = (
    "qemu-system-aarch64 "
    "-M virt -cpu cortex-a57 -m 1024 -nographic "
    "-kernel {} "
    "-append \"root=/dev/vda rw console=ttyAMA0 earlycon\" "
    "-drive file={},format=raw,if=none,id=hd0 "
    "-device virtio-blk-device,drive=hd0 "
    "-netdev user,id=net0,hostfwd=tcp::2222-:22 -device virtio-net-device,netdev=net0"
).format(kernel, rootfs_img)

print("Launching: {}".format(cmd))
sys.stdout.flush()

# Spawn QEMU via runqemu and interact
# QEMU does not require TERM here; pexpect spawns directly
child = pexpect.spawn(cmd, encoding="utf-8", timeout=900)
with open(log_path, "w", encoding="utf-8") as log:
    child.logfile = log
    # Wait for login prompt
    child.expect([r"login:", r"Poky .* login:", r"qemuarm64 login:"])
    child.sendline("root")
    # Wait for shell prompt. BusyBox typically shows '#' promptly.
    child.expect([r"# ", r"#\r\n", r"#\n"], timeout=300)
    # Run checks
    child.sendline("echo '=== uname ===' && uname -a")
    child.expect(r"# ")
    child.sendline("echo '=== lsmod hello ===' && (lsmod | grep -i hello || true)")
    child.expect(r"# ")
    child.sendline("echo '=== dmesg hello ===' && (dmesg | grep -i hello || true)")
    child.expect(r"# ")
    child.sendline("echo '=== modinfo hello ===' && (modinfo hello || true)")
    child.expect(r"# ")
    # Power off the VM to exit cleanly
    child.sendline("poweroff")
    # Allow shutdown message; then the outer runqemu/qemu will exit
    try:
        child.expect(pexpect.EOF, timeout=300)
    except pexpect.TIMEOUT:
        # Force close if it hangs
        child.close(force=True)

print("Demo complete. Log saved to {}".format(log_path))
