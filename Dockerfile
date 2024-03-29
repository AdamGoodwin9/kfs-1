FROM debian:bullseye-slim

WORKDIR /home/kfs

# Base packages
RUN apt update && apt install build-essential curl grub-pc xorriso -y

# Create a regular user 'user'
RUN useradd -m user && \
    echo "user:user" | chpasswd && \
    usermod -aG sudo user

# Change ownership of the workdir
RUN chown -R user:user /home/kfs

# Switch to the user
USER user

# Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    . "$HOME/.cargo/env" && \
    rustup toolchain install nightly-x86_64-unknown-linux-gnu && \
    rustup component add rust-src --toolchain nightly-x86_64-unknown-linux-gnu

ENTRYPOINT ["/bin/bash"]