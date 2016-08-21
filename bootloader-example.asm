; Minimal Linux Bootloader
; ========================

; @ author:	Sebastian Plotz
; @ version:	1.0
; @ date:	24.07.2012

; Copyright (C) 2012 Sebastian Plotz
; Copyright (C) 2016 Daria Kobtseva

; Minimal Linux Bootloader is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.

; Minimal Linux Bootloader is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
; GNU General Public License for more details.

; You should have received a copy of the GNU General Public License
; along with Minimal Linux Bootloader. If not, see <http://www.gnu.org/licenses/>.

; Memory layout
; =============

; 0x07c00 - 0x07dff	Mininal Linux Bootloader
;			+ partition table
;			+ MBR signature
; 0x10000 - 0x17fff	Real mode kernel
; 0x18000 - 0x1dfff	Stack and heap
; 0x1e000 - 0x1ffff	Kernel command line
; 0x20000 - 0x2fdff	temporal space for
;			protected-mode kernel

; base_ptr = 0x10000
; heap_end = 0xe000
; heap_end_ptr = heap_end - 0x200 = 0xde00
; cmd_line_ptr = base_ptr + heap_end = 0x1e000

org	0x7c00

	cli					    ; registers set up, no interruptions
	xor	ax, ax				; set to zero
	mov	ds, ax
	mov	ss, ax
	mov	sp, 0x7c00			; stack at 0000:7c00 (last address)
	mov	ax, 0x1000
	mov	es, ax
	sti
;	mov	si, message
;	call	print

load_kernel_bootsector:

	mov	eax, 0x0001			; load one sector
	xor	bx, bx				; no offset
	mov	cx, 0x1000			; load Kernel boot sector at 0x10000
	call	hdd_read

load_kernel_setup:

	xor	eax, eax
	mov	al, [es:0x1f1]			; number of sectors to load
	cmp	ax, 0				    ; 4 is default value if SETUP_SECTS = 0
	jne	load_kernel_setup.next
	mov	ax, 4
.next:
	mov	bx, 512				    ; 512 byte offset
	mov	cx, 0x1000
	call	hdd_read

version_check:

	cmp	word [es:0x206], 0x204		; protocol version >=2.04
	jb	error

set_headers:

	or	byte [es:0x211], 0xa0		; can_use_heap and quiet_flag
	mov	word [es:0x224], 0xde00		; heap_end_pointer
	mov	dword [es:0x228], 0x1e000	; cmd_line_pointer
	cld					; copy cmd_line
	mov	si, cmd_line
	mov	di, 0xe000
	mov	cx, cmd_length
	rep	movsb

load_protected_mode_kernel:

	mov	edx, [es:0x1f4]			; size of protected mode kernel
	shl	edx, 4
	call	load

;load_initrd:

;	mov	eax, [gdt.dest]			; initrd destination
;	mov	[es:0x218], eax			; set header for destination
;	mov	edx, [initrdSize]		; initrd size
;	mov	[es:0x21c], edx			; set header for ramdisk size
;	xor	eax, eax
;	mov	eax, [initrd_lba]
;	mov	[current_lba], eax		; new lba start
;	call 	load

start_kernel:

	cli
	mov	ax, 0x1000
	mov	ds, ax
	mov	es, ax
	mov	fs, ax
	mov	gs, ax
	mov	ss, ax
	mov	sp, 0xe000
	jmp	0x1020:0

; loads 127*512 bytes as long is they are to be loaded
load:
.loop:

	cmp	edx, 0				; still something left to load?
	je	load.end
	cmp	edx, 0xfe00			; less than 127*512 bytes to load
	jb	load.next
	mov	eax, 0x7f			; load 127 sectors
	xor	bx, bx				; no offset
	mov	cx, 0x2000			; temporary load to 0x2000
	call	hdd_read
	mov	cx, 0x7f00			; 127*512 bytes to copy to protected mode
	call	move_memory			; move to protected mode
	sub	edx, 0xfe00
	add	word [gdt.dest], 0xfe00		; add 127*512 bytes to dest location
	adc	byte [gdt.dest+2], 0
	jmp	short load.loop			; repeat loading

; loads sectors left + 1
.next:
	mov	eax, edx			; eax = bytes left to load
	shr	eax, 9				; sectors left to load
	inc 	eax				; load +1 sector in case of we have half a sector
	xor	bx, bx				; no offset
	mov	cx, 0x2000
	call 	hdd_read
	mov	ecx, edx
	shr	ecx, 1
	call	move_memory
	add	word [gdt.dest], 0xfe00
	adc	byte [gdt.dest+2], 0
.end:
	ret

hdd_read:

	push	edx
	mov	[dap.count], ax			; number of sectors to load (127 max)
	mov	[dap.offset], bx		; offset
	mov	[dap.segment], cx		; temporary load to segment
	mov	edx, [current_lba]		; lba value 'xxxxxxxxx'
	mov	[dap.lba], edx
	add	[current_lba], eax		; update current_lba
	mov	ah, 0x42
	mov	si, dap
	mov	dl, 0x80			; first hard disk
	int	0x13				; read from disk
	pop	edx
	ret

move_memory:

	push	edx
	push	es
	xor	ax, ax
	mov	es, ax
	mov	ah, 0x87
	mov	si, gdt
	int	0x15				; copy in protected mode
	pop	es
	pop	edx
	ret

print:
	push 	ax
.start:
	lodsb
	cmp	al, 0
	jz	print.end
	mov 	ah, 0x0e
	int	0x10
	jmp	print.start
.end:
	pop	ax
	ret

error:
	mov	si, error_message
	call	print

; Global Descriptor Table

gdt:

	times	16	db	0		; null descriptor
	dw	0xffff				; segment limit
.src:
	dw	0
	db	2
	db	0x93				; data access rights
	dw	0
	dw	0xffff				; segment limit
.dest:
	dw	0
	db	0x10				; load protected-mode kernel to 100000h
	db	0x93				; data access rights
	dw	0
	times	16	db	0

; Disk Address Packet

dap:

	db	0x10				; size of DAP
	db	0				; unused
.count:
	dw	0				; number of sectors
.offset:
	dw	0				; destination: offset
.segment:
	dw	0				; destination: segment
.lba:
	dd	0				; low bytes of LBA address
	dd	0				; high bytes of LBA address

; Data

current_lba	dd	lba_start		; initialize to first LBA address
cmd_line	db	'command_line', 0
cmd_length	equ	$ - cmd_line
error_message	db 	'Error! Kernel protocol version <2.04...', 0
;message	db	'Loading kernel...', 0

;initrdSize	dd	initramfs_size
;initrd_lba	dd	lba_initramfs_start