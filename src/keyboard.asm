; Description:
; Determines if key is in keyboard buffer, if so checks if key is == 'P'.
; if it is, pauses game. Else, checks if player is NOT jumping.
; If player's current jump is almost done, adds to player velocity
; to start jumping. Also moves 0x00 into game_state (game = started)
;
handle_input:
	; Check if key is in buffer
	mov	ah, 0x01		; peak if key is present in keyboard buffer, if not ax is 0; else it's keycode
	int	0x16			; calls peeking if new key in keyboard buffer
	jz	GLOBAL_RET		; if ax is zero, skip handling input bec no key pressed
		
	cmp	al, 'P'			; compare with 'P'
	je	pause_pressed
	cmp	al, 'p'
	je	pause_pressed	
	
	cmp	byte [vel_friction_cnt], friction - 2	; only jump if last jump is almost finished
	jle	GLOBAL_RET


	call 	clear_keyb		; clears the keyboard buffer to accomodate for the pressed key  

	mov	byte [game_state], 0x00	; set game running
	mov	[y_velocity], word jmp_vel	; start jump velocity

	ret

   pause_pressed:
	call 	clear_keyb
	cmp	byte [game_state], 0x00
	je	pause_g
	mov	byte [game_state], 0x00
	ret
   pause_g: 
	mov	byte [game_state], 0x01
	ret


;
; Description:
; Helper that clears keystroke buffer directly ( 0040:001A := 0040:001C )
;
clear_keyb: 		  		
	push 	ds			; save segment registers
	push 	es			; needed for movsw

 	mov 	bx, 0x40		; temp for storing 0x40 in es
 	mov 	es, bx			; es = 0x40
 	mov 	ds, bx			; ds = 0x40 (also store 0x40 in ds)
	mov 	di, 0x1A		; 
 	mov 	si, 0x1C
 	movsw				; move word from ds:si to es:di
	
	pop es
	pop ds
	ret

;
