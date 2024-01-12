if [ ! -f "./kernel.bin" ]; then
    bash make_bin.sh
fi

mkdir -p isodir/boot/grub
cp kernel.bin isodir/boot/myos.bin
cp src/grub.cfg isodir/boot/grub/grub.cfg
grub-mkrescue -o kernel.iso isodir