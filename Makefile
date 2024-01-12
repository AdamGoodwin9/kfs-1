# Compiler, Linker, Commands
CC := cargo build
AS := as
LD := ld
RM := rm -f

SRC_DIR := src
OBJ_DIR := obj
BIN_DIR := bin

# Flags, Libraries, Includes
CFLAGS := -Z build-std=core
ASFLAGS := --32
LDFLAGS := -m elf_i386 -T $(SRC_DIR)/link.ld
LIBS := 

# Sources, Objects, Binary
SRCS := $(wildcard $(SRC_DIR)/*.rs $(SRC_DIR)/*.s)
OBJS := $(patsubst $(SRC_DIR)/%.s, $(OBJ_DIR)/%.o, $(filter %.s, $(SRCS))) \
        $(patsubst $(SRC_DIR)/%.rs, $(OBJ_DIR)/%.o, $(filter %.rs, $(SRCS)))
BIN := kernel.bin

all: $(BIN_DIR)/$(BIN)

# Binary
$(BIN_DIR)/$(BIN): $(OBJS)
	$(LD) $(LDFLAGS) -o $@ $^ $(LIBS)

# Rust
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.rs
    @mkdir -p $(@D)
    @$(CC) --target=src/target.json --release

# Assembly
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.s
	@mkdir -p $(@D)
	$(AS) $(ASFLAGS) -o $@ $<

check-multiboot:
    @grub-file --is-x86-multiboot $(BIN_DIR)/$(BIN) && echo "File is multiboot" || echo "File is not multiboot"

make-iso: $(BIN_DIR)/$(BIN)
    @mkdir -p isodir/boot/grub
    @cp $(BIN_DIR)/$(BIN) isodir/boot/myos.bin
    @cp $(SRC_DIR)/grub.cfg isodir/boot/grub/grub.cfg
    @grub-mkrescue -o $(BIN_DIR)/kernel.iso isodir

run-bin: $(BIN_DIR)/$(BIN)
    qemu-system-i386 -kernel $(BIN_DIR)/$(BIN)

run-iso: make-iso
    qemu-system-i386 -cdrom $(BIN_DIR)/kernel.iso

clean:
	$(RM) $(OBJ_DIR)/*.o

fclean: clean
	$(RM) $(BIN_DIR)/$(BIN)

re: fclean all

.PHONY: all clean fclean re
