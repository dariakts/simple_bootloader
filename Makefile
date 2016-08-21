all:	bootloader-example.asm
	./script.sh	
	nasm bootloader.asm -o bootloader.bin
	echo "Please check than your bootloader.bin file is <=446 bytes long..."
	
install: bootloader-example.asm
	dd if=bootloader.bin of=/dev/sda bs=446 count=1 

clean: bootloader-example.asm
	rm bootloader.bin
	rm bootloader.asm
	echo "Files removed, you may wish to install grub/lilo now...."
