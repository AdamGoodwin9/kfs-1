FROM alpine:latest

WORKDIR /home/kfs

# base packages
RUN apk update && apk add --no-cache curl build-base nasm grub xorriso rust cargo

# rust
RUN rustup default nightly && \
    rustup component add rust-src --toolchain nightly-x86_64-unknown-linux-gnu

ENTRYPOINT ["tail", "-f", "/dev/null"]