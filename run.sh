cargo build -Z build-std=core --target=src/target.json --release
as --32 src/start.s -o src/start.o
ld -m elf_i386 -o kernel.bin -T src/link.ld src/start.o target/target/release/libkfs_1.a
qemu-system-i386 -kernel kernel.bin -serial stdio
