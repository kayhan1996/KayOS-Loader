COMPILER ?= aarch64-elf

COPS = -ggdb -nostdlib -nostartfiles -ffreestanding 
ASMOPS = -ggdb -nostdlib -nostartfiles -ffreestanding 

BUILD_DIR = build/objects
BIN_DIR = build/bin
SRC_DIR = src
#COMMON_SRC_DIR = src
OBJ_DIR = objects
HEADER_DIR = include

all : build

clean :
	rm -rf $(BUILD_DIR)
	rm -rf $(BIN_DIR)/*
	rm ../build/kernel*

#DIFFERENTIAL BUILDS FOR OBJECT FILES

#DIFFERENTIAL BUILDS FOR *.c files
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c
	@echo	"START: Creating object files from kernel *.c files"
	mkdir -p $(@D)
	$(COMPILER)-gcc $(COPS) -I$(HEADER_DIR) -c $<  -o $@

# $(BUILD_DIR)/%.o: $(COMMON_SRC_DIR)/%.c
# 	@echo	"START: Creating object files from common *.c files"
# 	mkdir -p $(@D)
# 	$(COMPILER)-gcc $(COPS) -I$(HEADER_DIR) -c $<  -o $@

#DIFFERENTIAL BUILDS FOR *.S files
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.S
	@echo	"START: Creating object files from *.S files"
	mkdir -p $(@D)
	$(COMPILER)-gcc $(ASMOPS) -I$(HEADER_DIR) -c $< -o $@

C_FILES = $(wildcard $(SRC_DIR)/*.c)
# COMMON_C_FILES = $(wildcard $(COMMON_SRC_DIR)/*.c)
ASM_FILES = $(wildcard $(SRC_DIR)/*.S)

OBJ_FILES = $(C_FILES:$(SRC_DIR)/%.c=$(BUILD_DIR)/%.o)
# OBJ_FILES += $(COMMON_C_FILES:$(COMMON_SRC_DIR)/%.c=$(BUILD_DIR)/%.o)
OBJ_FILES += $(ASM_FILES:$(SRC_DIR)/%.S=$(BUILD_DIR)/%.o)

HEADER_FILES += $(wildcard $(HEADER_DIR))

build: $(OBJ_FILES) $(HEADER_FILES)
	@echo $(OBJ_FILES)
	mkdir -p $(BIN_DIR)
	$(COMPILER)-ld -g -T linker.ld -o $(BIN_DIR)/kernel8.elf  $(OBJ_FILES)

	#CREATE OBJECT DUMP OF KERNEL IMAGE
	objdump -S --disassemble $(BIN_DIR)/kernel8.elf > kernel8.dump
	#OPTIONAL, STRIPS KERNEL OF DEBUG SYMBOLS INTO SEPERATE FILE
	$(COMPILER)-objcopy --only-keep-debug $(BIN_DIR)/kernel8.elf kernel.sym
	$(COMPILER)-objcopy --strip-debug $(BIN_DIR)/kernel8.elf
	$(COMPILER)-objcopy $(BIN_DIR)/kernel8.elf -O binary ../build/kernel8.img

run : build
	qemu-system-aarch64 -s -S -m 1G -M raspi3 -serial stdio -kernel ../build/kernel8.img -d mmu -d int
