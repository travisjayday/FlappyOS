; 
; Description:
; Draws the floor and the black bars onto the virtual buffer
; Note: does not draw the actual background color (blue) 
; The actual buffer background is drawn by clear_buffer:
; 
draw_background:

   	; Draw floor
	mov	si, 64000		; start at end of screen
	mov 	cx, 64000 - xres * floor_height 	; 36 pixel floor
	mov	bx, word [color_floor]	; move the floor color in bx (depends on color mode or b/w)

   d_f_pixel:				; floor label loop (draw_floor_pixel)
	dec 	si			; move to next pixel
	mov	[gs:si], bx		; move brown color
	cmp	si, cx			; check if last pixel drawn
	jne	d_f_pixel		; if not, draw next

   	; Draw black bars
	xor	si, si			; prepare to draw borders
	mov	cx, 35			; cx points to future, border is 35 px
	mov	ah, yres +1		; draw a little more than screensize to fill last left bar

   d_b_pixel:				; black bars label loop	(draw_bar_pixel)
	mov	[gs:si], byte 0x00	; move color into pixel
	inc	si			; move to next pixel
	cmp	si, cx			; check if last pixel reached
	jne	d_b_pixel		; if not, draw next pixel

	add	si, xres - 2 * 35	; start of right bar, compensates for last 2 bars
	add 	cx, xres		; future points to same location, just one row down
	
	dec	ah			; decrement row counter
	test	ah, ah			; check if row counter is zero
	jne	d_b_pixel		; if not, draw next row
	
	ret				; return from "draw_background" procedure

; Description:
; Changes the color-scheme to black/white by loading appropirate
; colors into their respective memory locations
; 
setup_blackwhite:
	mov	byte [color_dmgzone], 0x0F
	mov	byte [color_bar], 0x00
	mov	byte [color_beak], 0x00
	mov	word [color_back], 0x0F0F
	mov	byte [color_player], 0x00
	mov	word [color_floor], 0x0000
	
	ret


