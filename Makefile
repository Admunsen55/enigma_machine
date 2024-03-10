# Define compiler and flags
NASM = nasm
NASM_FLAGS = -f elf32

CC = gcc
CFLAGS = -m32

# Define linker and flags
LD = ld
LD_FLAGS = -m elf_i386

# Define source files
ASM_SOURCES = enigma.asm
C_SOURCES = main.c

# Define object files
ASM_OBJECTS = $(ASM_SOURCES:.asm=.o)
C_OBJECTS = $(C_SOURCES:.c=.o)

# Define output file
OUTPUT = enigma

# Build rule
all: $(OUTPUT)

$(OUTPUT): $(ASM_OBJECTS) $(C_OBJECTS)
    $(LD) $(LD_FLAGS) -o $(OUTPUT) $(ASM_OBJECTS) $(C_OBJECTS)

# Compile assembly files
%.o: %.asm
    $(NASM) $(NASM_FLAGS) $< -o $@

# Compile C files
%.o: %.c
    $(CC) $(CFLAGS) -c $< -o $@

# Clean rule
clean:
    rm -f $(ASM_OBJECTS) $(C_OBJECTS) $(OUTPUT)
