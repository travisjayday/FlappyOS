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
%define damage_bar_height	60	; the height of "space" between bars
%define bar_speed		0x01	; speed that bars travel to the left

; BACKGROUND
%define floor_height		36	; floor is 36 px high	

; TEXT
%define font_s 			0x03	; the size of a side of a virtual font block
%define color_fnt 		0x0F	; color of the font


[bits 16]
[org 0x7E00]


section .text
start:
	xor	ax, ax			; temp to move into ds
	mov	ds, ax			; zero segment to access vars defined in ;Data secition

	; Setup VGA mode and memory buffers
	mov	ax, 0x13		; select VGA 16bit colors 320x200 mode
	int 	0x10			; call video update bios
	mov	ax, 0xA000		; Video memory startaddr
	mov	es, ax			; es = Real buffer video segment into segment register (for segment:offset format)
	mov	ax, buffer_addr		; temp storage of virtual buffer addr
	mov	gs, ax			; gs = Virtual buffer segment stored in GS (write to gs for buffering) 

	test	dl, dl			; if dl == 0, black and white was selected in the bootloader
	jne	gameloop		; if not, start game
	call 	setup_blackwhite	; else setup black/ white colors (found in src/background.asm)


   gameloop:
	; Handle keyboard input to set y_velociity if jumping
   	call 	handle_input		; checks if key was pressed, then jumps player. If 'P' was pressed, pauses game
					; (found in src/keyboard.asm)
  
	; Check if game is running (if gamestate == 0)
	cmp	byte [game_state], 0x01	; if gamestate == 1, game is paused
	je	game_paused		; if it's paused, skip all physics, moving bars, collision, etc
	
	; Process Game Logic
	call 	update_physics		; moves playeroffset down (bec of gravity); also decrements velocity bec of friction
	call	check_collision		; if player is inside bar range, check bar collision, if collided, calls lost_game;
					; (found in src/physics.asm) 
	call 	handle_barspawn		; moves bars on screen (subs bar_x_offset), checks if bar is out of screen
					; if it is, calls "rotate_damage_offsets" (found in src/bars.asm)
   game_paused:				

	; Draw Graphics to Buffer
	call 	clear_buffer		; prepare to draw, fills screen with background color
	call 	draw_bars		; draws bars to buffer
	call 	draw_player		; draws player to buffer
	call	draw_background		; draws floor and black bars to buffer
	
	mov	di, title_string	; di holds pointer to string start
	mov	dx, 50			; dx holds space start x offset 
	mov	si, 175			; si holds y_offset 
	call 	draw_string		; draws the "Flappy-OS" title to buffer

	mov	dx, 245			; x offset of digit 1, y_offset is same from last drawcall	
	call 	draw_score		; draws the score to buffer
	
	
   	; WAIT (sleep) for a little bit
	mov	ax, 0x8600		; specify for int 0x15 WAIT interupt
	mov	cx, 0x0000		; high word of wait time 
	mov	dx, 0x3240;3240		; low word of wait time	
	int 	0x15			; waits for cx:dx 1,000,000ths of a second
   
	; apply all graphical changes
	call 	switch_buffers		; moves drawing buffer to vram
	jmp 	gameloop	

; 
; Description: 
; Called when player collides with something. This ends the game by moving black pixels
; to vram from top to bottom to screen, then writing "OVER" on screen together with 
; the player's score. On keypress, procedure jumps to 0x7C00, thus restarting the 
; bootloader.
;
lost_game:
	mov	ax, 0x8600		; specify for int 0x15 WAIT interupt
	xor	cx, cx			; high word of wait time = 0
	mov	dx, 0x002f		; low word of wait time		

	xor 	si, si			; set pixel counter to 0 

   blacking_vram:
	int 	0x15			; waits for cx:dx 1,000,000ths of a second
   
	mov 	byte [es:si], 0x00	; move black into pixel
	inc 	si			; go to next pixel
	cmp	si, 64000		; check if last pixel reached
	jne	blacking_vram		; if not, jump to next pixel

	mov	word [color_back], 0x00 ; set virtual buffer background to black
	call 	clear_buffer		; fill the virtual buffer with black
	
	; write "OVER" string to virtual buffer
	mov	di, end_string		; di holds pointer to string start
	mov	dx, 120			; dx holds space start x offset 
	mov	si, 85			; si holds y_offset
	call 	draw_string		; write over string to virtual buffer

	mov	dx, 165 - 30		; dx holds x offset
	mov	si, 110			; si holds y_offset
	call	draw_score		; write score to vbuffer
	
	call	switch_buffers		; move vbuffer to vram 

   	; WAIT (sleep) for a second
	mov	ax, 0x8600		; specify wait call
	mov	cx, 0x000F		; high word of wait time 
	mov	dx, 0x3240		; low word of wait time	
	int 	0x15			; waits for cx:dx 1,000,000ths of a second

	call 	clear_keyb		; clear any previous input
	xor	ax, ax			; select read key
	int	0x16			; wait until keypress
		
	jmp 	0x7C00			; upon keypress, jump back to MBR, (run code in bootloader.asm)

 ; jumped to when a function is forced to exit prematurely
GLOBAL_RET: 
	ret

%include "src/bars.asm"
%include "src/background.asm"
%include "src/player.asm"
%include "src/buffers.asm"
%include "src/font_text.asm"
%include "src/physics.asm"
%include "src/keyboard.asm"
 
; DATA
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

; FILLER -- 3 sectors; total game size is 4 sectors (2KiB)
times 1536 - ($-$$) db 0



