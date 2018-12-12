make:Image

.PHONY: clean qemu-run

objects = setup.o bootsect.o

qemu-run:Image
	- @qemu-system-i386 -boot a -fda Image

bootsect.o:bootsect.s
	- @as --32 -o bootsect.o bootsect.s

bootsect:bootsect.o
	- @ld -T ld_boot.ld bootsect.o -o bootsect
	- @objcopy -O binary -j .text bootsect

setup.o:setup.s
	- @as --32 -o setup.o setup.s

setup:setup.o
	- @ld -T  ld_boot.ld setup.o -o setup
	- @objcopy -O binary -j .text setup

Image:bootsect setup
	- @dd if=bootsect of=Image count=1 bs=512
	- @dd if=setup of=Image count=4 bs=512 seek=1
	- @echo "Img have been done"
clean:
	- @rm -f bootsect setup Image
	- @rm -f $(objects)
