make:Image

.PHONY: clean qemu-run

objects = demo.o bootsect.o

qemu-run:Image
	- @qemu-system-i386 -boot a -fda Image

bootsect.o:bootsect.s
	- @as --32 -o bootsect.o bootsect.s

bootsect:bootsect.o
	- @ld -T ld_boot.ld bootsect.o -o bootsect
	- @objcopy -O binary -j .text bootsect

demo.o:demo.s
	- @as --32 -o demo.o demo.s

demo:demo.o
	- @ld -T  ld_boot.ld demo.o -o demo
	- @objcopy -O binary -j .text demo

Image:bootsect
	- @dd if=bootsect of=Image count=1 bs=512
	#- @dd if=demo of=Image count=4 bs=512 seek=1
	- @echo "Img have been done"
clean:
	- @rm -f bootsect demo Image
	- @rm -f $(objects)
