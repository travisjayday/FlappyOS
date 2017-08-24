clear_buffer:  
	xor 	si, si			; make sure acumulator starts at first pixel
	mov	ax, [color_back]	; cache background color
	
   zero_buf:
	mov 	word [gs:si], ax	; set background to lightblue
	add	si, 2			; increment accumulator (by 2 for moving words, 2 bytes)
	cmp	si, 64000		; check if si == 320 * 200 (screen buffer size. if not, must clear more)
	jne	zero_buf

	ret


; copies contents from virtual memory buffer to vram
switch_buffers:
	mov	si, gs			; use si as temp for gs addr (virtual memory segment)
	mov	ds, si			; move into datasegment the addr of virtual memory segment
	
	xor	si, si			; clear accumulators for string operation
	xor	di, di
	
	mov 	cx, 32000		; how many words to copy 320 * 200 / 2
	cld				; copy direction
	rep 	movsw			; repeat copy from ds:si to es:di until cx is 0 (copies buffer from memory to vram)
	xor	ax, ax
	mov	ds, ax			; restores data segment to reference databytes properly after switch_buffers	
	ret


