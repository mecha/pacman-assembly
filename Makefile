AS := nasm -f elf64 -g -X gnu -Iinc
CC := gcc -c -g
LD := gcc -no-pie -g

TARGET := ./pacman
SRC_DIR := ./src
BUILD_DIR := ./.build

SRCS := $(shell find $(SRC_DIR) -name '*.asm' -or -name '*.c')
OBJS := $(SRCS:%=$(BUILD_DIR)/%.o)

# Link executable from object files
$(TARGET): $(OBJS)
	@echo "Linking $(TARGET)"
	@$(LD) -o $@ $^ $(LD_FLAGS)
	@echo -e "\033[0;32mBuild successful!\033[0m"

# Build object files from assembly source files
$(BUILD_DIR)/%.asm.o: %.asm
	@mkdir -p $(dir $@)
	@echo "Compiling ASM $<"
	@$(AS) -o $@ $<

# Build object files from C source files
$(BUILD_DIR)/%.c.o: %.c
	@mkdir -p $(dir $@)
	@echo "Compiling C $<"
	@$(CC) -o $@ $<

# Build and run target
.PHONY: run
run: $(TARGET)
	@$(TARGET) || echo -e "\033[0;31m[MAKE] Exited with code $$?\033[0m"

# Build and debug target
.PHONY: debug
debug: $(TARGET)
	@gdb $(TARGET)

# Delete build files and target
.PHONY: clean
clean:
	@test $(BUILD_DIR) != "/" && rm -rf $(BUILD_DIR)
	@rm -f $(TARGET)
