bits 16
org 0x7c00

;section .text
boot:
	jmp start
	nop

	OEMLabel		db "FLAPPYOS"	; Disk label
	BytesPerSector		dw 512		; Bytes per sector
	SectorsPerCluster	db 1		; Sectors per cluster
	ReservedForBoot		dw 1		; Reserved sectors for boot record
	NumberOfFats		db 2		; Number of copies of the FAT
	RootDirEntries		dw 224		; Number of entries in root dir
						; (224 * 32 = 7168 = 14 sectors to read)
	LogicalSectors		dw 2880		; Number of logical sectors
	MediumByte		db 0F0h		; Medium descriptor byte
	SectorsPerFat		dw 9		; Sectors per FAT
	SectorsPerTrack		dw 18		; Sectors per track (36/cylinder)
	Sides			dw 2		; Number of sides/heads
	HiddenSectors		dd 0		; Number of hidden sectors
	LargeSectors		dd 0		; Number of LBA sectors
	DriveNo			dw 0		; Drive No: 0
	Signature		db 41		; Drive signature: 41 for floppy
	VolumeID		dd 00000000h	; Volume ID: any number
	VolumeLabel		db "FLAPPYOS   "; Volume Label: any 11 chars
	FileSystem		db "FAT12   "	; File system type: don't change

drive_n: db 0
start:
	; init segment registers
	xor	ax, ax
	mov	ds, ax
	mov 	es, ax

	cli				; Disable interrupts while changing stack
	mov ss, ax
	mov sp, 0x7C00			; Set up stack space below bootloader
	sti				; Restore interrupts

	; NOTE: A few early BIOSes are reported to improperly set DL
	mov	[drive_n], dl
	
	mov	si, msg_found		; load str addr into si
	call 	write_cstring		; write string 2 scrn
	

	; prepare to read sector into memory
	mov 	si, 0x04	; maximum attempts - 1
	mov	bx, 0x7E00	; load after bootloader
	mov	cx, 0x0002	; cylinder 0, sector 2
	mov	dl, [drive_n]  	; select boot drive
	xor	dh, dh		; head is 0

   read_sectors:	
	xor	ax, ax		; select reset disk system 
	int	0x13		; call disk service

	test	si, si
	jz	read_fail	; if si < 0, ran out of attempts, end
	dec	si		; else, decrement attempts

	mov	ah, 0x02	; select read sectors into memory
	mov	al, 0x03	; read 3 sectors

	int 	0x13		; call read into memroy
	jc 	read_sectors
   
   read_succ:
	; INIT video textmode
	xor	ax, ax
	int	0x10

 	; write hello message
	mov	si, msg_entry	; load str addr into si
	call 	write_cstring	; write string 2 scrn
	
	; print graphic selection prompt
	mov	si, msg_graphic_prompt
	call 	write_cstring
	
   get_graphic_mode:
	xor	ah, ah		; keyboard read service
	int	0x16		; call read key, key is in al reg
	
	cmp	al, 0x42	; cmp with 'B' (black/white)
	je	start_bw_game	; jmp to start black white game
	cmp	al, 0x62	; cmp with 'b' (black/white
	je	start_bw_game	; jmp to start black white game

	cmp	al, 0x43	; cmp with 'C' (color)
	je	start_c_game	; jmp to start color game
	cmp	al, 0x63	; cmp with 'c' (color)
	je	start_c_game	; jmp to start color game

	cmp	al, 0x45	; cmp with 'E' (exit)
	je	exit_game	; exit the personal computer
	cmp	al, 0x65	; cmp with 'e' (exit)
	je 	exit_game	; exit the personal computer

	mov 	si, msg_invalid_input
	call 	write_cstring
	jmp 	get_graphic_mode

   exit_game: 
	; magic from stackoverflow warm reboot
	; assembles to jmp far ptr 0x0FFFF:0
	; which is the reset vector
	db 0x0ea		
	dw 0x0
	dw 0xffff

   start_c_game:
	mov	dh, 0x01
	jmp	start_game
   
   start_bw_game:
	xor	al, al		; al = 0, meaning that black/white is selected
   
   start_game:
	mov	dl, [drive_n]	
	jmp	0x0000:0x7E00

%if 0
; 
; Description: 
; Scrolls the screen to clear screen
; 
clear_screen:
	mov	ax, 0x0600 	; function 07 (scroll) al = 0 (scroll whole win)
	mov	bh, 0x07	; white on black chars
	mov	cx, 0x184F		; top left: row = 0; col = 0
	mov	dx, 0x0		; bottom right: row = 0x18, color = 0x4F
	int 	0x10
	
	ret
%endif

; 
; Description: 
; Writes String to screen 
; 
; Parameters: 
; si = string address
;
; Notes: 
; Does NOT modify any registers except for si
; 
write_cstring:
	push 	ax
	mov	ah, 0x0E	; select bios write char service 
   in_string:
	mov	al, [si] 	; move char into al
	int	0x10		; else, write char 2 scrn
	inc	si		; inc str addr
	cmp 	byte [si], 0x00
	jne	in_string	   

	pop 	ax
	ret
; 
; Description:
; Called upon when a fatal disk read error occurs
;
read_fail:
	mov 	si, msg_read_fail
	call	write_cstring
	hlt			; halt
	jmp $

; DATA
msg_found: 
	db "Bootloader Found...", 0x00

msg_read_fail: 
	db "Error: Disk Read Failure", 0x00

msg_entry:
	db "Welcome to FlappyOS!", 0x0A, 0x0D, \
	   "by Travis Ziegler", 0x0A, 0x0A, 0x0D, 0x0 \

msg_graphic_prompt: 
	db "Main Menu:", 0x0A, 0x0D, \
	   "  -[C]olor", 0x0A, 0x0D, \
	   "  -[B]lack/white", 0x0A, 0x0D, \
	   "  -[E]xit game", 0x0A, 0x0A, 0x0D, "Graphic Mode [C/B/E]? ", 0x00

msg_invalid_input:
	db 0x0A, 0x0D, "Invalid input!", 0x00


; MBR Partition table so that USB can be booted in HDD mode
times 0x1b4 - ($-$$) db 0	; start of partition table

; 0x1b4
db "12345678", 0x0, 0x0		; 10 byte unique id

; 0x1be 		; Partition 1 
db 0x80			; boot indicator flag = on

; start sector
db 0			; starting head = 0
db 0b00000001	; cyilinder = 0, sector = 1 (2 cylinder high bits, and sector. 00 000001 = high bits db 0x00)
db 0			; 7-0 bits of cylinder (insgesamt 9 bits) 

; filesystem type
db 1			; filesystem type = fat12

; end sector = 2880th sector? I doubt this matters much...
db 1			; ending head = 1
db 18			; cyilinder = 79, sector = 18 (2 cylinder high bits, and sector. 00 000001 = high bits db 0x00)
db 79			; 7-0 bits of cylinder (insgesamt 9 bits) 

dd 0			; 32 bit value of number of sectors between MBR and partition

dd 2880			; 32 bit - total number of sectors in disk

; 0x1ce			; Partition 2
times 16 db 0

; 0x1de			; Partition 3
times 16 db 0

; 0x1ee			; Parititon 4
times 16 db 0

dw 0xaa55


