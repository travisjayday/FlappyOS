[bits 16]
[org 0x7c00]

section .text
boot:
	jmp start
	times 3-($-$$) DB 0x90   ; Support 2 or 3 byte encoded JMPs before BPB.

    	; Dos 4.0 EBPB 1.44MB floppy
    	OEMname:           db    "mkfs.fat"  ; mkfs.fat is what OEMname mkdosfs uses
    	bytesPerSector:    dw    512
    	sectPerCluster:    db    1
    	reservedSectors:   dw    1
    	numFAT:            db    2
    	numRootDirEntries: dw    224
    	numSectors:        dw    2880
    	mediaType:         db    0xf0
   	numFATsectors:     dw    9
    	sectorsPerTrack:   dw    18
    	numHeads:          dw    2
    	numHiddenSectors:  dd    0
    	numSectorsHuge:    dd    0
    	driveNum:          db    0
    	reserved:          db    0
    	signature:         db    0x29
    	volumeID:          dd    0x2d7e5a1a
    	volumeLabel:       db    "NO NAME    "
    	fileSysType:       db    "FAT12   "

start:
	; init segment registers
	xor	ax, ax
	mov	ds, ax
	mov 	es, ax

	; prepare to read sector into memory
	mov 	si, 0x02	; maximum attempts - 1
	mov	al, 0x03	; load 1 sector 
	mov	bx, 0x7E00	; load after bootloader
	mov	cx, 0x0002	; cylinder 0, sector 2
	mov	dl, 0	   	; select boot drive
	xor	dh, dh		; head is 0

   read_sectors:	
	mov	ah, 0x02	; select read sectors into memory
	int 	0x13		; call read into memroy
	jnc	read_succ	; if no carrying, then read succeeded
	dec	si		; else, decrement attempts
	jc	read_fail	; if si == 0, ran out of attempts, end
	xor	ah, ah		; select reset disk system 
	int	0x13		; call disk service
	jnc	read_sectors	; if not carried, didn't fail. retry
   
	; read failed
   read_fail:
	cli			; stop interrupts
	hlt			; halt
	jmp read_fail		; just to be safe to always hang
	
   read_succ:
	; INIT video textmode
	mov	ah, 0x00
	int	0x10
 
	; write hello message
	mov	si, msg_entry	; load str addr into si
	call 	write_cstring	; write string 2 scrn
	
	xor	ah, ah		; select int 16, ah = 0, keyboard read
	int 	0x16		; call read key 
	call 	clear_screen	; clears scrn	

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
	mov	dl, 0x01
	jmp	start_game
   
   start_bw_game:
	xor	dl, dl		; dl = 0, meaning that black/white is selected
   
   start_game:
	jmp	0x7E00



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

; 
; Description: 
; Writes String to screen 
; 
; Parameters: 
; si = string address
; 
write_cstring:
	mov	ah, 0x0E	; select bios write char service 
   in_string:
	mov	al, [si] 	; move char into al
	inc	si		; inc str addr
	test 	al, al		; check if al == 0
	je	return_write_s	; if so, end of string reached, return
	int	0x10		; else, write char 2 scrn
	jmp write_cstring	; continue to next char

   return_write_s
	ret

; DATA
msg_entry:
	db "Welcome to FlappyOS!", 0x0A, 0x0D, \
	   "by Travis Ziegler", 0x0A, 0x0A, 0x0D, 0x00 \

msg_graphic_prompt: 
	db "  -[C]olor", 0x0A, 0x0D, \
	   "  -[B]lack/white", 0x0A, 0x0D, \
	   "  -[E]xit game", 0x0A, 0x0A, 0x0D, "Graphic Mode [C/B/E]? ", 0x00

msg_readfail:
	db "[ERROR] Failed to read sectors from boot device. Aborting...", 0x00

msg_invalid_input:
	db 0x0A, 0x0D, "Invalid input!", 0x00

; Sector filler and Boot signature
times 510 - ($-$$) db 0
dw 0xaa55


