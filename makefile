linker_script := src/linker.ld
CFLAGS= -c -I ../../include -std=gnu99 -ffreestanding -O2 -Wall -Wextra
LDFLAGS=-T $(linker_script) -I include -ffreestanding -O2 -nostdlib -lgcc
qemu-system-i386=../qemu/qemu-system-i386.exe
i686-elf-bin=../i686-elf-4.9.1-Linux-x86_64/bin
i686-elf-gcc=$(i686-elf-bin)/i686-elf-gcc
i686-elf-as=$(i686-elf-bin)/i686-elf-as
nasm=../nasm-2.13.03/nasm.exe
bin=build/osdev.bin
iso=build/osdev.iso

all: $(iso)
compile_run:
	make all && \
	make run
obj/kernel/idt.o: src/kernel/idt.asm
	$(nasm) -felf32 $^ -o obj/kernel/idt.o
obj/kernel/*.o: src/kernel/*.c
	@cd obj/kernel && \
	../../$(i686-elf-gcc) $(CFLAGS) $(subst src,../../src,$^)
obj/boot/boot.o: src/boot/*.asm
	$(nasm) -felf32 $^ -o obj/boot/boot.o
$(bin): obj/boot/boot.o obj/kernel/*.o obj/kernel/idt.o $(linker_script)
	@$(i686-elf-gcc) $(LDFLAGS) -o $(bin) obj/boot/boot.o obj/kernel/*.o -lgcc
$(iso): $(bin)
	cp $(bin) iso/boot/osdev.bin && \
	grub-mkrescue -o $(iso) iso
run: $(bin)
	$(qemu-system-i386) -kernel $(bin)
runiso: $(is)
	$(qemu-system-i386) -boot d $(iso)
clean:
	rm -rf obj/boot/*.o
	rm -rf obj/kernel/*.o
	rm -rf build/*
