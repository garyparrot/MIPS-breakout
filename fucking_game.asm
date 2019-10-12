.macro allocBitmap(%xsize, %ysize)
	sw $t7, preg+0
	sw $a0, preg+4
	sw $v0, preg+8
	
	# sbrk: allocate space for bitmap  
	lw $a0, %xsize
	lw $t7, %ysize
	mul $a0, $a0, $t7
	li $v0, 9
	syscall
	
	lw $t7, preg+0
	lw $a0, preg+4
	lw $v0, preg+8
.end_macro

.macro getXpos(%block_id,%save_target)
	sw %block_id, preg+0
	sll %block_id, %block_id, 4
	lw %save_target, blocks+0(%block_id)
	lw %block_id, preg+0
.end_macro

.macro getYpos(%block_id,%save_target)
	sw %block_id, preg+0
	sll %block_id, %block_id, 4
	lw %save_target, blocks+4(%block_id)
	lw %block_id, preg+0
.end_macro

.macro getColor(%block_id,%save_target)
	sw %block_id, preg+0
	sll %block_id, %block_id, 4
	lw %save_target, blocks+8(%block_id)
	lw %block_id, preg+0
.end_macro

.macro getStatus(%block_id,%save_target)
	sw %block_id, preg+0
	sll %block_id, %block_id, 4
	lw %save_target, blocks+12(%block_id)
	lw %block_id, preg+0
.end_macro

.macro drawBlockR(%block_id)
	addi $a0, %block_id, 0
	jal drawBlock
.end_macro

.macro drawBlockI(%block_id)
	li $a0, %block_id
	jal drawBlock
.end_macro

.macro sleep(%time)
	li $a0, %time
	li $v0, 32
	syscall
.end_macro

.macro terminate()
	li $v0, 10
	syscall
.end_macro

.data
	preg: .word 0,0,0,0,0,0,0,0,0
	jreg: .word 0,0,0,0,0,0,0,0,0
	screen_xsize: .word 128
	screen_ysize: .word 64
	screen_xbits: .word 7
	block_width:  .word 8
	block_height: .word 5
	totBlocks:    .word 45
	Gaming: 	  .word 1 		# is the game running? 
	frame:		  .word 0		# current frame index, that mean this game can run continusely about 24 days 
	
	# Blocks
	# xpos, ypos, color, destroyed
	blocks: .word  
          4,  0,16711680, 0, 20,  0,16711680, 0, 36,  0,16711680, 0, 52,  0,16711680, 0, 68,  0,16711680, 0, 84,  0,16711680, 0,100,  0,16711680, 0,116,  0,16711680, 0,
         12,  5,   65280, 0, 28,  5,   65280, 0, 44,  5,   65280, 0, 60,  5,   65280, 0, 76,  5,   65280, 0, 92,  5,   65280, 0,108,  5,   65280, 0,
          4, 10,     255, 0, 20, 10,     255, 0, 36, 10,     255, 0, 52, 10,     255, 0, 68, 10,     255, 0, 84, 10,     255, 0,100, 10,     255, 0,116, 10,     255, 0,
         12, 15,16776960, 0, 28, 15,16776960, 0, 44, 15,16776960, 0, 60, 15,16776960, 0, 76, 15,16776960, 0, 92, 15,16776960, 0,108, 15,16776960, 0,
          4, 20,16711935, 0, 20, 20,16711935, 0, 36, 20,16711935, 0, 52, 20,16711935, 0, 68, 20,16711935, 0, 84, 20,16711935, 0,100, 20,16711935, 0,116, 20,16711935, 0,
         12, 25,   65535, 0, 28, 25,   65535, 0, 44, 25,   65535, 0, 60, 25,   65535, 0, 76, 25,   65535, 0, 92, 25,   65535, 0,108, 25,   65535, 0
	panelX: 	.word 60
	panelWidth: .word 8
	
.text
	# allocate space
	jal allocMemory
	
	# init Blocks
	li $s0, 0
	lw $s1, totBlocks
	drawBlocksloop:
		drawBlockR($s0)
		addi $s0, $s0, 1
		bne $s0, $s1, drawBlocksloop
	drawBlocksloopExit:
	
	# Game loop
	# For now on, $s7 store the frame number
	lw $s7, frame
	GameLoop:
		
		# Handle user key event every 1 frame (equal 10ms)
		jal handleInput
		
		# Let the ball move every 10 frame (equal 100ms)
		
		# Redraw the shitty screen 
		
		# next frame
		sleep(10)
		addi $s7, $s7, 1
		
		# loop
		lw $t7, Gaming
		bnez $t7, GameLoop
	
	# exit
	terminate()
	
	
	
	
	
	
	
	

	# handle input
	handleInput:
		jr $ra	
		
	# allocate space for bitmap
	allocMemory:
		allocBitmap(screen_xsize, screen_ysize)
		jr $ra
		
	# Function for drawing block
	drawBlock:
		getXpos($a0,  $t0)
		getYpos($a0,  $t1)
		getColor($a0, $t2)
		sll $t3, $t0, 2 		# xscan in byte position
		lw  $t5, screen_xbits 	# get the bit size of screen width (for 512 width, it will be 9 bits)
		sllv $t4, $t1, $t5		# yoffset in position
		sll  $t4, $t4, 2		# yoffset in byte position
		
		lw  $t1, screen_xsize
		sll $t1, $t1, 2			# byte size of a row
		
		lw $t5, block_width
		sll $t5, $t5, 2			# the byte size of block width
		add $t5, $t5, $t3		# get the scan destination for x
		
		lw $t6, block_height
		
		# t0 = xpos
		# t1 = byte size of a row in screen
		# t2 = the color
		# t3 = xscan
		# t4 = yoffset
		# t5 = xscan-destination
		# t6 = remaining line
		nop
		draw_line:
			beq $t3, $t5, next_line		# if the line is finished, jump
			add $t7, $t3, $t4			# the byte position of target pixel
			sw $t2, 0x10040000($t7)		# draw pixel
			add $t3, $t3, 4				# move to next pixel
			j draw_line
			next_line:
			sll $t3, $t0, 2				# reset the xscan byte position to left-most pixel
			add $t4, $t4, $t1			# move yoffset to next line
			subi $t6, $t6, 1			# minus remaining line by 1
			bnez $t6, draw_line
		draw_line_finished:
		
		# exit function
		jr $ra
		
		
			
		
		
		
		
		
