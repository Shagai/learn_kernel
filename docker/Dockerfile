FROM ubuntu:24.04

# Yocto build deps (per Yocto Project ref manual) + QoL tools
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    locales tzdata ca-certificates \
    build-essential chrpath cpio diffstat gawk \
    git gzip bzip2 xz-utils zstd lz4 \
    python3 python3-pip python3-pexpect python3-git python3-jinja2 \
    file wget curl tar unzip \
    rsync sudo vim less \
    qemu-system-arm qemu-system-aarch64 \
    libsdl2-2.0-0 libegl1 \
    pkg-config \
    iproute2 iputils-ping \
    bison flex \
    gnupg \
 && rm -rf /var/lib/apt/lists/*

# Locale for bitbake log parsing comfort
RUN sed -i 's/# en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen \
 && locale-gen
ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

# Non-root user so host files are not owned by root
ARG USERNAME=builder
ARG UID=1000
ARG GID=1000
RUN set -eux; \
    if getent group ${GID} >/dev/null; then \
      EXISTING_GROUP="$(getent group ${GID} | cut -d: -f1)"; \
    else \
      groupadd -g ${GID} ${USERNAME}; \
      EXISTING_GROUP="${USERNAME}"; \
    fi; \
    useradd -m -u ${UID} -g "${EXISTING_GROUP}" -s /bin/bash ${USERNAME} || true; \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/90-${USERNAME}

WORKDIR /work
USER ${USERNAME}

# Preinstall repo helper and kas (optional, handy for advanced workflows)
RUN pip3 install --no-cache-dir --break-system-packages kas

# Default branch can be overridden at runtime
ENV YOCTO_BRANCH=scarthgap

# Keep cache and downloads in a well-known path mounted from host
ENV YOCTO_CACHE_DIR=/work/cache \
    DL_DIR=/work/cache/downloads \
    SSTATE_DIR=/work/cache/sstate

# Mark workspace safe for Git when mounted
RUN git config --global --add safe.directory /work

ENTRYPOINT ["/bin/bash"]
