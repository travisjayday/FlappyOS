;
; Description: 
; Draws a string of drawable characters to screen at specified position
; 
; Parameters: 
; di = address of first drawable_char
; dx = x offset of string start
; si = y offset of string start 
;
draw_string: 
   writing_str: 	
	call 	draw_char		; draws char to screen
	add	di, 15			; go to next char
	add	dx, 15			; move along screen x offset
	cmp	[di], byte -0x01	; end of string reaached?
	jne	writing_str		; go to next 
	
	ret

;
; Description:
; Draws the current number of bars passed - 3 onto the screen
; 
; Parameters:
; dx = x offset of string start
; si = y offset of string start 
;
draw_score: 
	xor	bx, bx			; bx used as offset register

	mov	al, [bars_passed]	; number of bars passed (score)
	sub	al, 3			; compensate for the first 3 game bars (passed at start of game)	
	cmp	al, -0x01		; test if score is greater than 0
	jle 	GLOBAL_RET		; if not, return

	mov	cl, 0x0A		; divisor
	idiv 	cl			; get digits, qotient is in al (dig 1), remainder ah (dig 2)
	
	mov	cx, 0x02		; loop twice ( 2 DIGITS)	

	test	al, al			; al has first digit, test if it's zero
	je	single_digit		; if it's not zero, start looping for 2 digits

	mov	bl, al			; move first digit into bx (only when using double digits)i

   double_digit:
	imul	bx, 15			; digit offset in memory (each digit is 15 bytes)
	lea	di, [drawable_number+bx]; load address of number into di
	call 	draw_char		; draw digit

	add	dx, 7
   single_digit:
	add	dx, 8			; move horizontally to draw next digit
	mov	bl, ah			; move second digit into bl
	dec	cx			; dec loop counter
	test	cx, cx			; check if reached end
	jne	double_digit		; if not, draw next digit
	
	ret


; Description:
; Draws a character onto vga screen buffer linearly
; 
; Parameters:
; - macros:  
; font_s = Scale of char is a predefined macro "font_s" 
; color_fnt = Byte color of character to draw
; 
; - registers: 
; di = Reference to virtual pixel matrix
; si = yoffset of drawpoint start relative to top left corner
; dx = xoffset of drawpoint start relative to top left corner
; 
draw_char:
	pusha				; save reg for string loop (needed to write chars left to right) 
	imul	si, xres		; multiply by 320 to get top offset (rows)
	add	si, dx			; add x _offset to get pixel start location
	mov	cx, si			; cx will point to pixel end location
	add	cx, 3 * font_s		; add 3 times font scale to cx to get end position
	xor	dx, dx			; dh = row counter
	xor	bx, bx			; array offset counter used to loop through array pixel data
	mov	dl, font_s		; dl = pixel counter horizontal (each virtual block is 5 px wide) 
	mov	ah, font_s		; ah = pixel counter vertical  (each virtual block is 5 px tall)

   num_lineard:
	mov	al, [di + bx]		; get pixel from array data
	test	al, al			; check if al is 0
	je	skip_vblock		; if it's zero don't draw to buffer because it should be transparent
	mov	byte [gs:si], color_fnt	; write pixel , text color

   skip_vblock: 
	inc	si			; go to next pixel

	dec 	dl			; decrement horizontal pixel counter
	test	dl, dl			; if pixel counter is not 0
	jne	same_block		; skip going to next array pixl

	inc	bx			; if pixel counter == 0, go to next index in array
	mov	dl, font_s		; put 5 pixels into dl (block size)
   
   same_block:
	cmp	si, cx			; check if end of line reached
	jne	num_lineard		; if not, draw next pixel
	
	add	si, 320 - 3 * font_s 	; goto next line 
	add 	cx, 320			; cx points to future in next line

	sub	bx, 3			; subtract bx by 3 to compensate for horizontal accumulation
	dec	ah			; decrement row pixel counter (5px == 1 virtual block)
	test	ah, ah			; check if row == 0
	jne	same_block_v		; if it's not zero, just go to next line
	add	bx, 3			; else, add 3 to compensate for previous subtraction 
					; (next line will have new pixel data)
	mov	ah, font_s		; move new row counter into ah
  
   same_block_v:
	inc 	dh			; increment virtual blocks drawn
	cmp	dh, font_s * 5 		; if blocks draw == font_s * 5, if not draw next line
	jne	num_lineard	

	popa				; restore regs (to increment later in loop for drawing chars)
	ret



title_string:
	; F
	db	1, 1, 1
	db 	1, 0, 0
	db 	1, 1, 1
	db 	1, 0, 0
	db 	1, 0, 0

	; L 	[title_string + 1 * 15] 
	db 	1, 0, 0
	db 	1, 0, 0
	db 	1, 0, 0
	db 	1, 0, 0
	db 	1, 1, 1

	; A
	db 	1, 1, 1
	db 	1, 0, 1
	db	1, 1, 1
	db 	1, 0, 1
	db 	1, 0, 1

	; P
	db	1, 1, 1
	db 	1, 0, 1
	db 	1, 1, 1
	db 	1, 0, 0
	db 	1, 0, 0

	; P
	db	1, 1, 1
	db 	1, 0, 1
	db 	1, 1, 1
	db 	1, 0, 0
	db 	1, 0, 0

	; Y 
	db	1, 0, 1
	db 	1, 0, 1
	db 	1, 1, 1
	db 	0, 1, 0
	db 	0, 1, 0

	; "-" 
	db	0, 0, 0
	db 	0, 0, 0
	db 	1, 1, 1
	db 	0, 0, 0
	db 	0, 0, 0

	; O
	db	0, 0, 0
	db 	1, 1, 1
	db 	1, 0, 1
	db 	1, 0, 1
	db 	1, 1, 1

	; S
	db 	1, 1, 1
	db 	1, 0, 0
	db 	1, 1, 1
	db 	0, 0, 1
	db 	1, 1, 1
	
	; end of string
	db 	-0x01

end_string:
	; O
	db	1, 1, 1
	db	1, 0, 1
	db 	1, 0, 1
	db 	1, 0, 1
	db 	1, 1, 1

	; V
	db 	1, 0, 1
	db 	1, 0, 1
	db	1, 0, 1
	db 	1, 0, 1
	db 	0, 1, 0

	; E
	db 	1, 1, 1
	db 	1, 0, 0
	db	1, 1, 1
	db 	1, 0, 0
	db 	1, 1, 1

	; R
	db 	1, 1, 1
	db 	1, 0, 1
	db	1, 1, 0
	db 	1, 0, 1
	db 	1, 0, 1



	; end of string
	db 	-0x01

drawable_number:
	; 0
	db 	1, 1, 1
	db	1, 0, 1
	db 	1, 0, 1
	db 	1, 0, 1
	db 	1, 1, 1

	; 1
	db 	0, 1, 0
	db	0, 1, 0
	db 	0, 1, 0
	db 	0, 1, 0
	db 	0, 1, 0

	; 2
	db	1, 1, 1
	db	0, 0, 1
	db 	1, 1, 1
	db	1, 0, 0
	db	1, 1, 1


	; 3
	db 	1, 1, 1
	db	0, 0, 1
	db 	1, 1, 1
	db 	0, 0, 1
	db 	1, 1, 1

	; 4
	db 	1, 0, 1
	db	1, 0, 1
	db 	1, 1, 1
	db 	0, 0, 1
	db 	0, 0, 1

	; 5
	db 	1, 1, 1
	db	1, 0, 0
	db 	1, 1, 1
	db 	0, 0, 1
	db 	1, 1, 1

	; 6
	db 	1, 1, 1
	db	1, 0, 0
	db 	1, 1, 1
	db 	1, 0, 1
	db 	1, 1, 1

	; 7
	db 	1, 1, 1
	db	0, 0, 1
	db 	0, 0, 1
	db 	0, 0, 1
	db 	0, 0, 1

	; 8
	db 	1, 1, 1
	db	1, 0, 1
	db 	1, 1, 1
	db 	1, 0, 1
	db 	1, 1, 1

	; 9
	db 	1, 1, 1
	db	1, 0, 1
	db 	1, 1, 1
	db 	0, 0, 1
	db 	0, 0, 1



