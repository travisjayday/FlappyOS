; 
; Description:
; This procedure moves bars around on screen. It checks if bars are too far,
; and if bar is about to go ofscreen, it calls rotate_damage_offsets to 
; quickly switch the damage offsets of the bars, thus creating the illusion
; of continuous motion
; 
handle_barspawn:
	; handles bar movement
	sub	word [bar_x_offset], bar_speed	; moves bar lefts

	cmp	word [bar_x_offset], -107	; check if bar is out of screen
	
	jge	GLOBAL_RET		; all bars are in screen, no bars are being split
	mov	word [bar_x_offset], 0	
	
	; first bar just touched the end of screen on left
	call 	rotate_damage_offsets	; rotates damage offsets to accomodate for setting offset to 0
	ret

; 
; Description: 
; Updates Damage offsets for all 3 bars. Bars only move 107 px, 
; so to trick continuous motion, damage offsets must be swapped 
; from right to left. This is what the function does. In addition,
; it generates a random offset for bar 0 (right-most) bar. Also increments
; player's score (bars_passed)
; 
rotate_damage_offsets:
	; dmg offset 0  goes to   dmg offset 2
	; dmg offset 2  goes to   dmg offset 1 
	; dmg offset 1  goes to   hell
	; dmg offset 0  gets      random num

	mov	al, [damage_offset]
	mov	cl, [damage_offset+2]

	mov	[damage_offset+2], al
	mov	[damage_offset+1], cl

	; Generate Pseudo random number for next bar
	mov	ah, 0x0			; select get bios time
	int 	0x1A			; call bios time interrupt. current ticks store in cx:dx
	mov	ax, dx			; move least significant ticks into ax
	mul 	ax			; square ax
	xor	ah, ah			; zero upper part
	mov	dl, 0x5			; prepare to divide al by 5
	div     dl			; divide al by 5
	add	al, 0xA			; add  y_offset (10px)
	
	mov	[damage_offset], al	; random numebr into next offset
	inc	byte [bars_passed]	; keep track of score

	ret



; 
; Description:
; Draws the enemy bars from left to right, one by one, line for line.
; A maximum of 3 bars are on the screen at any point in time
; The black side borders hide the bars from going too far off screen and reapearing at the other side
; Whilst drawing, procedure checks the danger zone start and end of each bar (bar ids 0-2)
; 	and if a danger zone starts, it draws another color (background)
; Each bar is 35 pixels wide, and the space between bars is 72 pixels
; 
; Registers Used in Function: 
; bl = bar id (current id of bar 2 draw)
; dh = danger zone start (pixel)
; dl = danger zone end	(pixel)
; bh = draw row counter
; al = current color to draw (change between color_danger and color_bar)
; 
draw_bars:
	xor	bx, bx			; bl = bar id to draw = 0
	mov 	si, xres		; si starts on row 1 to compensate for bar0 draw. Primes loop

   start_bar_line:
	xor	bh, bh			; set row counter to 0 (also needed for next instruction) 

	; calc damage offsets	
	mov	dh, [damage_offset+bx]	; damage offset start
	mov 	ah, dh			; ah=temp for getting damage offset end
	add 	ah, damage_bar_height	; 60 px damage bar height
	mov	dl, ah			; dl holds end of damage bar
	
  	; calc proper si offsets
	add	si, [bar_x_offset] 	; load start x_offset (regardless of bar id)

	mov	ax, 107			; mulitplied by bar id to get bar offset. 35 + 72 = 107. 0 * 107 = 0; 1 * 107 = 107 ...
	mul	bl			; result in ax; offset of bar at id
	add	si, ax			; si holds start pixel	
 
   	; prepare to draw
	mov	cx, si			; store end draw pixel in cx
	add	cx, 35			; bar width will be 35 px
	mov	al, [color_bar]		; al holds color 2 draw

	test 	dh, dh			; check if bar is active
	je	bar_finished		; if damage start is 0, don't draw bars. Used at start of game to hide first 3 bars
  
   d_bar:
	mov	[gs:si], al		; move color into pixel
	inc	si			; move to next pixel
	cmp 	si, cx			; check if end of bar line 
	jne	d_bar			; if not, draw next pixel
	
	inc	bh			; line finished; increment row counter
	
	; check if should terminate, draw damage zone, or draw bar color
	cmp	bh, yres		; check if end of screen reached
	je	bar_finished		; if so, jump to next bar
	
	cmp	bh, dh			; check if row counter is <= to danger zone start
	jle	skip_b_color_ch		; if row cnt <=	danger_zone start, skip changing color
	mov	al, [color_dmgzone]	; if row cnt >= danger_zone start, color == danger zone

	cmp	bh, dl			; check if row counter <= danger zone end
	jle	skip_b_color_ch		; if row cnt <= danger zone end, skip changing color
	mov	al, [color_bar]		; if row cnt >= danger zone end, change color to white

	; prepare to draw next line of bar
   skip_b_color_ch:			; skip bar color change, skips changes to al for bar dangr zone
	add	si, xres - 35		; go to next row 320 - 35, start of left line pixel
	add	cx, xres		; make future point to end of next line
	jmp	d_bar			; draw next line

	; finished drawing bar, prepare to draw next bar or termiate
   bar_finished: 
	cmp	bl, 0x02		; if true, all bars were drawn
	je	GLOBAL_RET		; if true, return from function
	inc 	bl			; if not inc bh (bar id) and draw next bar
	xor	si, si			; reset si for next draw
	jmp 	start_bar_line		; jump to next bar procedure



