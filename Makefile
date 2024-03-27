# Compiler, Linker, Commands
CC := cargo
AS := as
LD := ld
RM := rm -f

# Project's Directories
SRC_DIR := src
OBJ_DIR := obj
BIN_DIR := bin

# Flags, Libraries, Includes
ASFLAGS := --32
LDFLAGS := -m elf_i386 -T $(SRC_DIR)/link.ld

# Sources, Objects, Binary
SRCS_ASM := $(wildcard $(SRC_DIR)/*.s)
OBJS_ASM := $(patsubst $(SRC_DIR)/%.s, $(OBJ_DIR)/%.o, $(SRCS_ASM))
BIN := kernel.bin
ISO := kernel.iso

# Rust static library
TARGET_TRIPLE := i386-unknown-none
RUST_LIB := target/$(TARGET_TRIPLE)/release/libkfs_1.a

all: $(BIN_DIR)/$(BIN)

# Binary
$(BIN_DIR)/$(BIN): $(RUST_LIB) $(OBJS_ASM)
	@mkdir -p $(BIN_DIR)
	$(LD) $(LDFLAGS) -o $@ $(OBJS_ASM) $(RUST_LIB)

# Rust
$(RUST_LIB): $(wildcard $(SRC_DIR)/*.rs)
	$(CC) build -Z build-std=core,alloc --target=$(TARGET_TRIPLE).json --release

# Assembly
$(OBJS_ASM): $(SRCS_ASM)
	@mkdir -p $(OBJ_DIR)
	$(AS) $(ASFLAGS) -o $@ $<

check-multiboot: $(BIN_DIR)/$(BIN)
	grub-file --is-x86-multiboot $< && echo "Multiboot confirmed" || echo "The file is not multiboot"

make-iso: $(BIN_DIR)/$(BIN)
	@mkdir -p isodir/boot/grub
	@cp $< isodir/boot/myos.bin
	@cp $(SRC_DIR)/grub.cfg isodir/boot/grub/grub.cfg
	grub-mkrescue -o $(BIN_DIR)/$(ISO) isodir

run-bin: $(BIN_DIR)/$(BIN)
	qemu-system-i386 -kernel $<

run-iso: make-iso
	qemu-system-i386 -cdrom $(BIN_DIR)/$(ISO)

docker:
	docker build -t kfs .
	docker run -v $(PWD):/home/kfs -it kfs

clean:
	$(RM) -r $(OBJ_DIR)

fclean: clean
	$(RM) -r target
	$(RM) -r $(BIN_DIR)
	$(RM) -r isodir

re: fclean all

.PHONY: all clean fclean re check-multiboot make-iso run-bin run-iso
