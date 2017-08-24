; MACRO CONSTANTS

; PLAYER
%define p_width			0x0A	; player width
%define p_left_offset		70	; space between left margin and player's left side
%define p_right_offset 		240	; space between right margin and player's right side; for linear player drawing purposes (xres - p_width - p_left_offset)
%define beak_width		0x05	; the horizontal length of the beak
%define friction		0x06	; the higher this is, the longer the jump lasts
%define jmp_vel			0x06	; the higher this is, the faster the jump is

; SCREEN 
%define xres			320	; VGA resolution width
%define yres			200	; VGA resolution height
%define buffer_addr		0x1000	; start of offscrean buffer

; BARS
%define damage_bar_height	60

; BACKGROUND
%define floor_height		36	; floor is 35 px high	

; TEXT
%define font_s 			0x03
%define color_fnt 		0x0F


[bits 16]
[org 0x7E00]


section .text
start:
	xor	ax, ax
	mov	ds, ax			; zero segment to access vars defined in ;Data secition

	; Setup VGA mode and memory buffers
	mov	ax, 0x13		; VGA 16bit colors 320x200 mode
	int 	0x10			; call video update bios
	mov	ax, 0xA000		; Video memory startaddr
	mov	es, ax			; es = Real buffer video segment into segment register (for segment:offset format)
	mov	ax, buffer_addr		; temp storage of virtual buffer addr
	mov	gs, ax			; gs = Virtual buffer segment stored in GS

	test	dl, dl			; if dl == 0, black and white is selected
	jne	gameloop		; if not, start game
	call 	setup_blackwhite	; else setup black/ white colors


   gameloop:
	; Handle keyboard input to set y_velociity if jumping
   	call 	handle_input
  
	; Check if game is running (if gamestate == 0)
	cmp	byte [game_state], 0x01	; if gamestate == 1, game is paused
	je	game_paused		; if it's paused, skip all physics, moving bars, collision, etc
	
	call 	update_physics
	call 	handle_barspawn

   game_paused:

	call 	clear_buffer		; prepare to draw, fills screen with background color
	call 	draw_bars		; draws bars
	call 	draw_player		; draw player
	call	draw_background		; draws floor and black bars
	
	mov	di, title_string	; di holds pointer to string start
	mov	dx, 50			; dx holds space start x offset 
	mov	si, 175			; si holds y_offset 
	call 	draw_string		; draws the "Flappy-OS" title 

	mov	dx, 245			; x offset of digit 1, y_offset is same from last drawcall	
	call 	draw_score		; draws the score on screen
	
	call	check_collision		; if player is inside bar range, check bar collision
	
   	; WAIT (sleep) for a little bit
	mov	ax, 0x8600		; specify for int 0x15 WAIT interupt
	mov	cx, 0x0000		; high word of wait time 
	mov	dx, 0x3240;3240		; low word of wait time	
	int 	0x15			; waits for cx:dx 1,000,000ths of a second
   
	call 	switch_buffers		; move drawing buffer to vram
	jmp 	gameloop	


; jumped to when a function is forced to exit prematurely
GLOBAL_RET: 
	ret


%include "src/bars.asm"
%include "src/background.asm"
%include "src/player.asm"
%include "src/buffers.asm"
%include "src/font_text.asm"

handle_barspawn:
	; handles bar spawning
	sub	word [bar_x_offset], 0x01

	cmp	word [bar_x_offset], -107
	
	jne	GLOBAL_RET		; all bars are in screen, no bars are being split
	mov	word [bar_x_offset], 0	
	
	; first bar just touched the end of screen on left
	call 	rotate_damage_offsets	; rotates damage offsets to accomodate for setting offset to 0
	ret

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
; 
; Description: 
;
lost_game:
	xor 	si, si			; set pixel counter to 0 

	mov	ax, 0x8600		; specify for int 0x15 WAIT interupt
	xor	cx, cx			; high word of wait time 
	mov	dx, 0x002f		; low word of wait time		

   blacking_vram:
	int 	0x15			; waits for cx:dx 1,000,000ths of a second
   
	mov 	byte [es:si], 0x00	; move black into pixel
	inc 	si			; go to next pixel
	cmp	si, 64000		; check if last pixel reached
	jne	blacking_vram		; if not, jump to next pixel

	mov	word [color_back], 0x0000 ; set virtual buffer background to black
	call 	clear_buffer		; fill the virtual buffer with black
	
	; write "OVER" string to virtual buffer
	mov	di, end_string		; di holds pointer to string start
	mov	dx, 120			; dx holds space start x offset 
	mov	si, 85			; si holds y_offset
	call 	draw_string		; write over string to virtual buffer

	mov	dx, 165 - 30
	mov	si, 110
	call	draw_score
	
	call	switch_buffers

   	; WAIT (sleep) for a second
	mov	ax, 0x8600
	mov	cx, 0x000F		; high word of wait time 
	mov	dx, 0x3240		; low word of wait time	
	int 	0x15			; waits for cx:dx 1,000,000ths of a second

	call 	clear_keyb		; clear any previous input
	xor	ax, ax			; select read key
	int	0x16			; wait until keypress
		
	jmp 	0x7C00			; upon keypress, jump back to MBR, (run code in bootloader.asm)
		
	ret

;
; Description:
; Clears keystroke buffer directly ( 0040:001A := 0040:001C )
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
; 
; Description: 
; Updates Damage offsets for all 3 bars. Bars only move 107 px, 
; so to trick continuous motion, damage offsets must be swapped 
; from right to left. This is what the function does. In addition,
; it generates a random offset for bar 0 (right-most) bar. 
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

	inc	byte [bars_passed]

	ret


;DATA
game_state:				; if 0x0, no gravity effects bird
	db	0x01			; set to 1 after first keypress
	
y_offset:				; space between top of scrn and top of player 
	dw	yres / 2 - p_width / 2  ; center player on scrn

y_velocity: 				; gets subtracted from y_offset when vel_friction_cnt is 0
	dw 	0x00
	
vel_friction_cnt:			; gets decremented every frame and reset if 0
	db 	friction		; the higher it is, the "softer" the jump is

bar_x_offset: 				; the space between the left of scrn and start of bar drawing
	dw 	0x0
	
damage_offset:				; the start of the no-go zones for each bar
	db 	0, 0, 0		

no_collision: 				; skip bar collision detection if no_collision > 0
	db 	40 * 3			; skip first 3 bars

bars_passed:				; incremented when a new bar "spawns"
	db	0x0			; keeps track of score

; COLORS
color_dmgzone:				; color of no-go zones inside the bars (usually backround color)
	db 	0x09			; light blue

color_bar:				; color of the bars
	db	0x0A			; green

color_beak:				; color of the player's beak
	db	0x04			; red 

color_back: 				; color of the background 
	dw	0x0909			; blue
	
color_floor:				; color of the floor
	dw 	0x0606			; brown

color_player:				; color of the player
	db	0x0E			; yellow	

; FILLER -- 3 sectors
times 1536 - ($-$$) db 0



