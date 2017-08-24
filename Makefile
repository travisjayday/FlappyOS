#!/bin/bash

# creates floppy.img and starts bochs for debugging
debug: image
	rm loader.bin flappy.bin
	bochs -q -rc debug.rc

# only creates floppy.img used for other sections
image: flappy.asm bootloader.asm clean
	nasm -f bin flappy.asm -o flappy.bin
	nasm -f bin bootloader.asm -o loader.bin
	dd if=/dev/zero of=floppy.img bs=1024 count=1440
	dd if=loader.bin of=floppy.img bs=512 seek=0 count=1 conv=notrunc
	dd if=flappy.bin of=floppy.img bs=512 seek=1 count=3 conv=notrunc

# writes OS to USB automatically at /dev/sdb 
usb:	image
	@echo ""
	@echo "[Warning] This operation will overwrite the bootsector of physical disk /dev/sdb"
	@echo "Press [Enter] to continue, [^C] to abort"
	@read input
	dd if=floppy.img of=/dev/sdb bs=512 count=4
	rm loader.bin flappy.bin floppy.img

# creates a burnable ISO image 
iso:	image
	genisoimage -quiet -V 'FLAPPYOS' -input-charset iso8859-1 -o iso_flappy.iso -b floppy.img -hide floppy.img floppy.img
	rm flappy.bin loader.bin floppy.img

# removes all possible files created by make
clean:
	rm -f loader.bin flappy.bin floppy.img iso_flappy.iso
