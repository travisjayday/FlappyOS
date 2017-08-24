;
; Description:
; Draws the player square on screen, with y offset of y_offset
;
draw_player:
	xor	bx, bx			; bl will be row counter; paintnig will stop if bl == p_width

	mov	ax, xres		; used to get linear space above player (row_width * row_count)
	mul 	word [y_offset]		; result will be in dx:ax (high, low bytes)
	mov	si, ax			; set start pixel to si

	mov	dh, [color_player]	; dh = color player
	mov	dl, [color_beak]	; dl = color beak
	

   start_p_drawrow:	
	inc	bl			; keep track of rows drawn.
	add	si, p_left_offset	; now si is at starting point to paint
   	mov	cx, si			; cx looks into the future
	add	cx, p_width		; cx will be the goal pixel
 
   draw_p_pixel:			; draws the player pixels
	inc	si			; go to next pixel (compensate for 0-start)
	mov	[gs:si], dh		; move white pixel to virtual memory at gs:si
	cmp	si, cx			; check if si caught up with cx
	jne	draw_p_pixel		; if not, draw next player pixel
	
	cmp	bl, 0x04		; check if beak row starts
	jle	no_beak			; if row <= 4, jump to no beak
	cmp	bl, 0x09		; check if beak row ended
	jge	no_beak			; if row >= 9 jump to no beak

   ; Else, Draw beak: 
	mov	cx, si			; dx will be in future where beak stops
	add	cx, beak_width		; add beak width 

   b_pixel:				; label for loop-drawing beak
	mov	byte [gs:si], dl	; move red pixel
	inc	si			; go to next pixel
	cmp 	si, cx			; check if next pixel is already equal to dx
	jne	b_pixel			; if it's not go to next pixel

	sub	si, beak_width		; subtract beak width from si to compensate for the next offset calculations 
	; it's as if beak was never drawn (si is same)

   no_beak:
	add	si, p_right_offset	; add offset of right of player
	
	cmp	bl, p_width		; check if p_width rows (height) have been drawn
	jne	start_p_drawrow		; if not, draw next row

   	; al still holds the y_offset pixel from mul operation; draw eye
	add 	ax, 4 * 320 + p_left_offset + 8		; move 4 rows down, add x_offset, 8 columns right
	mov	si, ax			
	mov	byte [gs:si], 0x00	; draw black eye

	ret


