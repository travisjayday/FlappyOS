;
; Description:
; Updats player gravity, then checks if jumping. If jumping, subtracts 
; y_velocity from y_offset, then decreases y_velocity if friction_cnt is 0.
; If friction_cnt is not 0, it decrements friction cnt.
;
update_physics:
	; always add constant downward velocity due to gravity	
	add 	word [y_offset], 0x03	; downward velocity = 3

	cmp	word [y_velocity], 0x0	; check if jumping (jumping if velocity > 0) 
	je 	GLOBAL_RET		; if it's zero, skip decreasing velocity

   	; Jumping currently. In a jump, therefore must decrease velocity bec of friction	
	mov	cx, [y_velocity]	; use cx as temp for storing current velocity
	sub	[y_offset], cx		; subtract current velocity from y_offset
   	
	; vel_friction_cnt is used as a counter to smooth the subtraction of velocity from y_offset. 
	; The greater it is, the less frequent velocity is subtracted form y_offset
	
	dec	byte [vel_friction_cnt]	; decreement velocity_friction_cnt 
	jne	GLOBAL_RET		; if velocity_friction_counter is not zero, skip
   	
	; decrementing velocity and subtracting velocity from y_offset
	sub	[y_velocity], word 0x1
	mov	[vel_friction_cnt], byte friction
	
	ret

; 
; Description: 
; Checks if player is colliding with floor or sky, then evaluates 
; if player is inside a bar area. If player is inside a bar area 
; (ie the 35 px widh of a bar), then ial	
; t checks if player is insi
; the danger zone of the bar. If it is, it jumps to game_lost:
; 
check_collision:
	; Evaluate if player is colliding with floor or sky
	cmp	word [y_offset], yres - floor_height - p_width +1	; check if player collides with floor
	jge	lost_game			; if so, lost game
	
	cmp	word [y_offset], -p_width * 10	; check if player is too high
	jle 	lost_game		; because negative numbers are greater than positive numbers
	
	; Check if should check bar collision
	cmp	byte [bars_passed], 2	; if not passed first 3 bars, it's ok if collision
	jle	GLOBAL_RET		; just return if game hasn't started yet

	; is player in a bar area? 
	cmp	word [bar_x_offset], -22; less than if player is inside bar area
	jge	GLOBAL_RET		; if greater, player is not in bar area

	cmp	word [bar_x_offset], -72; bar is to the left of player
	jle	GLOBAL_RET		; if less than, player is not in bar area
	
	; Check bar collision
	xor	ax, ax			
	mov	al, [damage_offset+1]	; use al as temp for damage offset start
	cmp	[y_offset], ax		; check top bounds
	
	jle	lost_game		; if player y < top bar y --> collision

	add	ax, damage_bar_height - p_width +2; check bottom bounds
	cmp	[y_offset], ax		;
	jge	lost_game		; if player y > bottom bar - player width --> collision

	ret

