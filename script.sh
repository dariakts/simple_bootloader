#!/bin/bash

first_kernel=`ls /boot/ | grep vmlinuz | head -n1`
lba_start=`hdparm --fibmap /boot/$first_kernel | awk '{ print $2 }' | sed -n 5p`
first_initramfs=`ls /boot/ | grep initrd | head -n1`
lba_initramfs_start=`hdparm --fibmap /boot/$first_initramfs | awk '{ print $2 }' | sed -n 5p`
initramfs_size=`stat -c %s /boot/$first_initramfs`

function creation {

	echo -e "What is the kernel command line? \c"
	read cmd_line
	echo -e "The address is: $lba_start"
	echo -e "The command line is: $cmd_line" 
	cp bootloader-example.asm bootloader.asm
	sed -i 's/lba_start/'$lba_start'/g' bootloader.asm
	sed -i 's@command_line@'$cmd_line'@g' bootloader.asm
	echo "Bootloader file created. Installing..."
}

function bootloader {
	echo -e "Bootloader creation - 1: With initramfs 2: Without initramfs \c"
	read initramfs
	if [ "$initramfs" -eq 1 ]
		then	
			echo -e "With initramfs installation \n"
			echo -e "Type of installation - 1: Automatic 2: Manual \c"
			read install_type
			if [ "$install_type" -eq 1 ]
			then	
				echo -e "Automatic installation \n"
				echo -e "The initramfs address is: $lba_initramfs_start"
				echo -e "The initramfs size is: $initramfs_size"
				creation
				sed -i 's/lba_initramfs_start/'$lba_initramfs_start'/g' bootloader.asm
				sed -i 's/initramfs_size/'$initramfs_size'/g' bootloader.asm
							

			elif [ "$install_type" -eq 2 ]
			then	
				echo -e "Manual installation \n"
				echo -e "What is the initramfs image lba start address? \c"
				read lba_initramfs_start
				echo -e "What is the initramfs size in bytes? \c"
				read initramfs_size
				echo -e "What is the kernel image lba start address? \c"
				read lba_start
				echo -e "The initramfs address is: $lba_initramfs_start"
				echo -e "The initramfs size is: $initramfs_size"
				creation
				sed -i 's/lba_initramfs_start/'$lba_initramfs_start'/g' bootloader.asm
				sed -i 's/initramfs_size/'$initramfs_size'/g' bootloader.asm

			else	echo -e "Error! \c"
			fi

	elif [ "$initramfs" -eq 2 ]
	then	
		echo -e "Without initramfs installation \n"
		echo -e "Type of installation - 1: Automatic 2: Manual \c"
		read install_type
		if [ "$install_type" -eq 1 ]
		then
			echo -e "Automatic installation \n"
			creation

		elif [ "$install_type" -eq 2 ]
		then	
			echo -e "Manual installation \n"
			echo -e "What is the kernel image lba start address? \c"
			read lba_start
			echo -e "What is the kernel command line? \c"
			read cmd_line
			creation

		else	echo -e "Error! \c"
		fi

	else	echo -e "Error! \c"
	fi
}

bootloader
