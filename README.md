# simple_bootloader
A simple bootloader that works with an LFS linux.

## Overwiev

This is a simple bootloader for x86 architecture using only one stage and hardcoded on hard disk. It comes with a script and a Makefile to provide a simplified installation proces but you can also install it manually by editing .asm file, compiling and copying binary file on your hard disk.

### Characteristics

- Supported architecture: x86
- Linux kernel: yes
- Initrd/Ramdisk: yes (in theory)
- Installation method: hardcoded at installation 
- Configurable: yes (kernel, initrd)

### Dependancies

- nasm
- make

## Installation

### Installation using Makefile

 Your kernel and initrd files should not be fragmented. Check it with hdparm -- fibmap filename command. You should only have one output.
 
 You need to have sudo privileges in order to perform bootloader installation

 The script provided uses the first kernel and initrd image it found in /boot directory. If you have several kernel or initrd images or they’re not located in /boot directory please use manual installation directives
 
- `root@host # > make`
- choose your installation options

### Manual installation

 Your kernel and initrd files should not be fragmented. Check it with hdparm -- fibmap filename command. You should only have one output.
 
 You need to have sudo privileges in order to perform bootloader installation.
 
- `root@host # > cp bootloader-example bootloader.asm`
- `root@host # > vim bootloader.asm`
- edit _bootloader.asm_ file and replace _lba_start_, _command_line_, _initramfs_size_, _lba_initramfs_start_ with due values
- `root@host # > nasm bootloader.asm –o bootloader.bin`
- check that _bootloader.bin_ is less than 446 bytes (`root@host # > ls –lh`) 
- `root@host # > dd if=bootloader.bin of=/dev/sdX bs=446 count=1` (X is your / partition number)
 
  
