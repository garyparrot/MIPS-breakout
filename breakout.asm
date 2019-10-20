# vim:set syntax=mips:
# Macros {{{

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

.macro dprintr(%reg)
	sw $a0, jreg+0
	sw $v0, jreg+4
	add $a0, %reg, $zero
	li $v0, 1
	syscall
	lw $a0, jreg+0
	lw $v0, jreg+4
.end_macro
.macro dprintc(%chr)
	sw $a0, jreg+0
	sw $v0, jreg+4
	li $a0, %chr
	li $v0, 11
	syscall
	lw $a0, jreg+0
	lw $v0, jreg+4
.end_macro

.macro setFirstPixelPayload(%id, %direction)
	sw $t7, preg+0
	lw $t7, %direction
	sll $t7, $t7, 6
	or $t7, $t7, %id
	sw $t7, drawline_firstPixelPayload
	lw $t7, preg+0
.end_macro
.macro setMiddlePixelPayload(%id, %direction)
	sw $t7, preg+0
	lw $t7, %direction
	sll $t7, $t7, 6
	or $t7, $t7, %id
	sw $t7, drawline_middlePixelPayload
	lw $t7, preg+0
.end_macro
.macro setLastPixelPayload(%id, %direction)
	sw $t7, preg+0
	lw $t7, %direction
	sll $t7, $t7, 6
	or $t7, $t7, %id
	sw $t7, drawline_lastPixelPayload
	lw $t7, preg+0
.end_macro

.macro maxdiff(%a0,%a1,%a2,%a3,%res)
	fentry($a0,$a1,$a2,$a3)
	add $a0, %a0, $zero
	add $a1, %a1, $zero
	add $a2, %a2, $zero
	add $a3, %a3, $zero
	jal _maxdiff
	add %res, $v0, $zero
	fexit($a0,$a1,$a2,$a3)
.end_macro

.macro fentry(%a)
	addi $sp, $sp, -4
	sw %a, 0($sp)
.end_macro
.macro fentry(%a,%b)
	addi $sp, $sp, -8
	sw %a, 0($sp)
	sw %b, 4($sp)
.end_macro
.macro fentry(%a,%b,%c)
	addi $sp, $sp, -12
	sw %a, 0($sp)
	sw %b, 4($sp)
	sw %c, 8($sp)
.end_macro
.macro fentry(%a,%b,%c,%d)
	addi $sp, $sp, -16
	sw %a,  0($sp)
	sw %b,  4($sp)
	sw %c,  8($sp)
	sw %d, 12($sp)
.end_macro

.macro fexit(%a)
	lw %a, 0($sp)
	addi $sp, $sp, 4
.end_macro
.macro fexit(%a,%b)
	lw %a, 0($sp)
	lw %b, 4($sp)
	addi $sp, $sp, 8
.end_macro
.macro fexit(%a,%b,%c)
	lw %a, 0($sp)
	lw %b, 4($sp)
	lw %c, 8($sp)
	addi $sp, $sp, 12
.end_macro
.macro fexit(%a,%b,%c,%d)
	lw %a,  0($sp)
	lw %b,  4($sp)
	lw %c,  8($sp)
	lw %d, 12($sp)
	addi $sp, $sp, 16
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

.macro setStatusDestoryed(%block_id)
	sw %block_id, preg+0
	sw $t7, preg+4
	sw $t8, preg+8
	sll %block_id, %block_id, 4
	lw $t7, blocks+12(%block_id)
	lw $t8, blockStatusDestroyed
	or $t7, $t7, $t8
	sw $t7, blocks+12(%block_id)
	lw $t7, preg+4
	lw $t8, preg+8
	lw %block_id, preg+0
.end_macro

.macro drawBlockR(%block_id)
	addi $a0, %block_id, 0
	li $a1, 0
	jal drawBlock
.end_macro

.macro drawBlockI(%block_id)
	li $a0, %block_id
	li $a1, 0
	jal drawBlock
.end_macro

.macro sleep(%time)
	li $a0, %time
	li $v0, 32
	syscall
.end_macro

.macro panelRight(%reg)
	sw $t7, preg+0
	lw %reg, panelX
	lw $t7, panelWidth
	add %reg, %reg, $t7
	lw $t7, preg+0
.end_macro

.macro panelLeft(%reg)
	lw %reg, panelX
.end_macro

.macro terminate()
	li $v0, 10
	syscall
.end_macro

# }}}

# Data {{{

.data
	preg: .word 0,0,0,0,0,0,0,0,0
	jreg: .word 0,0,0,0,0,0,0,0,0
	screen_xsize: .word 128
	screen_ysize: .word 64
	screen_xbits: .word 7
	block_width:  .word 8
	block_height: .word 5
	totBlocks:    .word 45
	gaming: 	  .word 1 		# is the game running? 
	uWin:		  .word 0
	uLose: 		  .word 0
	gameCheating: .word 1		# cheating mode
	frame:		  .word 0		# current frame index, that mean this game can run continusely about 24 days 
	keyLeftMovement:  .word -6	
	keyRightMovement: .word  6
	
	# Blocks
	# xpos, ypos, color, destroyed
	blocks: .word  
          4,  0,16711680, 0, 20,  0,16711680, 0, 36,  0,16711680, 0, 52,  0,16711680, 0, 68,  0,16711680, 0, 84,  0,16711680, 0,100,  0,16711680, 0,116,  0,16711680, 0,
         12,  5,   65280, 0, 28,  5,   65280, 0, 44,  5,   65280, 0, 60,  5,   65280, 0, 76,  5,   65280, 0, 92,  5,   65280, 0,108,  5,   65280, 0,
          4, 10,     255, 0, 20, 10,     255, 0, 36, 10,     255, 0, 52, 10,     255, 0, 68, 10,     255, 0, 84, 10,     255, 0,100, 10,     255, 0,116, 10,     255, 0,
         12, 15,16776960, 0, 28, 15,16776960, 0, 44, 15,16776960, 0, 60, 15,16776960, 0, 76, 15,16776960, 0, 92, 15,16776960, 0,108, 15,16776960, 0,
          4, 20,16711935, 0, 20, 20,16711935, 0, 36, 20,16711935, 0, 52, 20,16711935, 0, 68, 20,16711935, 0, 84, 20,16711935, 0,100, 20,16711935, 0,116, 20,16711935, 0,
         12, 25,   65535, 0, 28, 25,   65535, 0, 44, 25,   65535, 0, 60, 25,   65535, 0, 76, 25,   65535, 0, 92, 25,0xe95cff, 2,108, 25,   65535, 0
    blockCollided: .word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
					     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
					     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
					     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    blockStatusDestroyed:   .word 0x1
    blockStatusSpecial:		.word 0x2
    blockRemaining:		    .word 45
    blockProgressSpeed:	    .word 30
  
    
    # panel
	panelX: 	.word 58
	panelY:		.word 61
	panelWidth: .word 13
	panelMoved: .word 1
	panelMovement:  .word 0
	panelColor: .word 0x00ffffff
	panelObjectId: .word 63
	panelStretch: .word 0

	# ball
	ballX:		.word 63
	ballY:		.word 55
	ballWidth:	.word 3
	ballHeight: .word 3
	ballMoved:  .word 1
	ballSpeedX: .word 0             # the value add to XMovement every frame
	ballSpeedY: .word 0             # the value add to YMovement every frame
	ballColor:  .word 0x00eeeeee	# warning: ball color must be unique to other color on the screen
	ballPostColor: .word 0x00efefef 
    ballXAccMovement: .word 0          # for every 1024 value, this ball moved one x pixel
    ballYAccMovement: .word 0          # for every 1024 value, this ball moved one y pixel
	ballXMovement: .word 0
	ballYMovement: .word 0
	ballFollowPanel:  	.word  1
	ballFollowOffsetX: 	.word  5
	ballFollowOffsetY:  .word -5
    ballInitialSpeedX:  .word  35		# warning: this value should be postive, if you want to change direction on start up, consult ballSpeedSignX
    ballInitialSpeedY:  .word  35		# warning: this value should be postive, if you want to change direction on start up, consult ballSpeedSignY
    ballTouchBottomWall: .word 0
    ballSpeedSignX: .word  1
    ballSpeedSignY: .word -1
    ballBonusSpeed: .word 0
    ballProgressSpeed: .word 0			# the progress speed for breaking blocks
    
    ballProgressInc: .word 64			# the increment for breaking a block
    ballPushForce: .word 256			# the bonus speed for panel pushing
    blockCollisionLRSpeed: .word 64		# the bonus speed for LR collision
    ballCollideCenter: .word -128		# the bonus speed for panel center collision
    
    bonusSpeedMaximum: .word  1600
    bonusSpeedMinimum: .word -512
    
    # collision code
    collisionCR: .word 3
    collisionLR: .word 2
    collisionTB: .word 1
    collisionNP: .word 0
    collisionPushByPanel: .word 4
    
    # drawline
    drawline_firstPixelPayload: 	.word 0
    drawline_lastPixelPayload:   	.word 0
    drawline_middlePixelPayload:	.word 0
    drawline_targetColor:			.word 0
    drawline_anyColor:				.word 1
    
    requireSpeedUpdate: .word 0
	
	# last frame system time
	lastms: 	.word 0
	passedms:   .word 0
	
	win_bitmap: .word 
            56, 30, 0x422400, 56, 31, 0x643a00, 56, 32, 0x4f2f00, 57, 28, 0x784700, 57, 29, 0x070502, 57, 30, 0x302617, 57, 31, 0x452f03, 57, 32, 0xdbac1a, 57, 33, 0xe1a312, 57, 34, 0x935a01, 
            58, 27, 0x895401, 58, 28, 0xf3c521, 58, 29, 0x2f2e28, 58, 30, 0x2c2c2b, 58, 32, 0x695b12, 58, 33, 0xfbce29, 58, 34, 0xf6ac1b, 58, 35, 0xab6903, 59, 26, 0x372000, 59, 27, 0xecb518, 
            59, 28, 0xfbdf2f, 59, 29, 0x070701, 59, 32, 0x5b4f10, 59, 33, 0xfbce29, 59, 34, 0xf7af21, 59, 35, 0xf29d15, 59, 36, 0x6c3e00, 60, 26, 0x945c01, 60, 27, 0xfddc2c, 60, 28, 0xfee230, 
            60, 29, 0x0d0b02, 60, 32, 0x94811b, 60, 33, 0x665622, 60, 34, 0xf6ae21, 60, 35, 0xf6a41e, 60, 36, 0xb97404, 61, 26, 0xba8007, 61, 27, 0xfee230, 61, 28, 0xfee230, 61, 29, 0x211d06, 
            61, 30, 0x312b09, 61, 31, 0x8a7a1a, 61, 32, 0xfbdc2e, 61, 33, 0x3e3921, 61, 34, 0xc2891f, 61, 35, 0xf6a41e, 61, 36, 0xd7890b, 62, 26, 0xbf8709, 62, 27, 0xfee230, 62, 28, 0xfee230, 
            62, 29, 0x262207, 62, 30, 0x9a891d, 62, 31, 0xefd52d, 62, 32, 0xfede2e, 62, 33, 0x464021, 62, 34, 0xb07c1f, 62, 35, 0xf6a41e, 62, 36, 0xdb8b0c, 63, 26, 0xab7003, 63, 27, 0xfee130, 
            63, 28, 0xfee230, 63, 29, 0x1e1c0c, 63, 30, 0x292929, 63, 31, 0x131103, 63, 32, 0xd3b926, 63, 33, 0x363220, 63, 34, 0xe3a120, 63, 35, 0xf6a41e, 63, 36, 0xca7f08, 64, 26, 0x6a3f00, 
            64, 27, 0xf9cc23, 64, 28, 0xfce02f, 64, 29, 0x292822, 64, 30, 0x191919, 64, 32, 0x695b13, 64, 33, 0xcea927, 64, 34, 0xf7b021, 64, 35, 0xf5a21b, 64, 36, 0x985c01, 65, 27, 0xc38708, 
            65, 28, 0xfadb2d, 65, 29, 0x070701, 65, 32, 0x584d0f, 65, 33, 0xfbce29, 65, 34, 0xf7af21, 65, 35, 0xda8a09, 65, 36, 0x221000, 66, 27, 0x2e1900, 66, 28, 0xc88b0a, 66, 29, 0x080601, 
            66, 32, 0xa18d1d, 66, 33, 0xfac724, 66, 34, 0xda900c, 66, 35, 0x523200, 67, 30, 0x352000, 67, 31, 0x855803, 67, 32, 0xba7f07, 67, 33, 0x8a5400, 67, 34, 0x1c0f00, 0,0,0
    lose_bitmap: .word
            56, 37, 0x250e07, 56, 38, 0x090202, 57, 35, 0x100202, 57, 36, 0x6a3927, 57, 37, 0x824a35, 57, 38, 0x6e3b2a, 57, 39, 0x040400, 58, 33, 0x2f140c, 58, 34, 0x653928, 58, 35, 0x603222, 
            58, 36, 0x8c5540, 58, 37, 0x8c533e, 58, 38, 0x834b37, 58, 39, 0x32150e, 59, 31, 0x270d06, 59, 32, 0x3b1a10, 59, 33, 0x764534, 59, 34, 0x9f6a58, 59, 35, 0x98624f, 59, 36, 0x925b46, 
            59, 37, 0x8c533e, 59, 38, 0x88503b, 59, 39, 0x482216, 60, 30, 0x31150c, 60, 31, 0x8e5b49, 60, 32, 0xb38c7f, 60, 33, 0xd8c5be, 60, 34, 0xb99284, 60, 35, 0xb79284, 60, 36, 0x5d4035, 
            60, 37, 0x88513c, 60, 38, 0x8b523d, 60, 39, 0x52291b, 61, 27, 0x180703, 61, 28, 0x2c130a, 61, 29, 0x845343, 61, 30, 0x875543, 61, 31, 0xb28171, 61, 32, 0xe0d6d3, 61, 33, 0x3a3a3a, 
            61, 34, 0xd8d1ce, 61, 35, 0xbd998c, 61, 36, 0x696969, 61, 37, 0x2e1b14, 61, 38, 0x8b523d, 61, 39, 0x582d1e, 62, 27, 0x5b2f20, 62, 28, 0x9d6c5c, 62, 29, 0xbf9183, 62, 30, 0xba8b7c, 
            62, 31, 0xb38373, 62, 32, 0xd8c2ba, 62, 33, 0xbbbbbb, 62, 34, 0xd5c0b9, 62, 35, 0xb48c7e, 62, 36, 0xa3a3a3, 62, 38, 0x764533, 62, 39, 0x5b2e1f, 63, 27, 0x37180f, 63, 28, 0xac7b6c, 
            63, 29, 0xc09384, 63, 30, 0xba8b7b, 63, 31, 0xb38373, 63, 32, 0xad7c6a, 63, 33, 0xb4897a, 63, 34, 0xa06c59, 63, 35, 0xb18879, 63, 36, 0xb6b6b6, 63, 38, 0x633a2b, 63, 39, 0x5c3020, 
            64, 28, 0x673b2b, 64, 29, 0xb68879, 64, 30, 0xb9897a, 64, 31, 0xb38373, 64, 32, 0xdac4bd, 64, 33, 0xb6b5b5, 64, 34, 0xd7c3bc, 64, 35, 0xb48c7e, 64, 36, 0xa2a2a2, 64, 38, 0x754533, 
            64, 39, 0x5a2e1e, 65, 28, 0x0d0202, 65, 29, 0x4f281b, 65, 30, 0x693a2a, 65, 31, 0xb07f6f, 65, 32, 0xe0d6d2, 65, 33, 0x404040, 65, 34, 0xd8d1ce, 65, 35, 0xbd9a8d, 65, 36, 0x676767, 
            65, 37, 0x2c1a13, 65, 38, 0x8b523d, 65, 39, 0x552b1d, 66, 30, 0x270f09, 66, 31, 0x895643, 66, 32, 0xad8476, 66, 33, 0xd4bfb8, 66, 34, 0xb68e80, 66, 35, 0xb68f81, 66, 36, 0x5e4034, 
            66, 37, 0x88513c, 66, 38, 0x8a513c, 66, 39, 0x4e2718, 67, 31, 0x1c0a06, 67, 32, 0x32160b, 67, 33, 0x6e3f2e, 67, 34, 0x9e6957, 67, 35, 0x96604c, 67, 36, 0x915b46, 67, 37, 0x8c533e, 
            67, 38, 0x884f3a, 67, 39, 0x442215, 68, 33, 0x230d06, 68, 34, 0x572d1e, 68, 35, 0x562a1c, 68, 36, 0x8a533f, 68, 37, 0x8c533e, 68, 38, 0x844b37, 68, 39, 0x32150e, 69, 35, 0x0b0303, 
            69, 36, 0x683726, 69, 37, 0x824935, 69, 38, 0x6e3a29, 69, 39, 0x0b0303, 70, 37, 0x1f0d05, 70, 38, 0x040400, 0,0,0




# }}}
	
.text
	# allocate space
	jal allocMemory
	
	# Clean screen on start up
	li $t0, 0
	lw $t1, screen_ysize
	lw $t2, screen_xbits
	sll $t1, $t1, 2
	sllv $t1, $t1, $t2
	clearScreen:
		sw $zero, 0x10040000($t0)
		addi $t0, $t0, 4
		bne $t0, $t1, clearScreen
	
	# init Blocks
	li $s0, 0
	lw $s1, totBlocks
	drawBlocksloop:
		drawBlockR($s0)
		addi $s0, $s0, 1
		bne $s0, $s1, drawBlocksloop
	drawBlocksloopExit:
	
	# init system time
	li $v0, 30			# retrieve system time in ms unit
	syscall
	sw $a0, lastms 		# store the lower 32 bit time to lastms
			
	# Game loop
	# For now on, $s7 store the frame number
	lw $s7, frame
	GameLoop:
		
		# next frame
		jal waitNextClock		
						
		# Handle user key event 
		jal handleInput
		
		# Let the ball move 
		jal movingEvent
		
		# handle collision
		jal collisionHandler
		
		# Test if game finished
		jal gameCheck
		
		# Drawing shit on the screen
		jal render
		
		# loop
		lw $t7, gaming
		bnez $t7, GameLoop
	
	# exit
	terminate()
	
# gameCheck {{{

	gameCheck:
		fentry($ra)
		
		# stretch the panel
		panelStretchingTest:
			lw $t0, panelStretch
			beqz $t0, speedUpdateTest
				lw $t1, panelX
				sub $t1, $t1, $t0
				sw $t1, panelX		# move panelX
				lw $t1, panelWidth
				add $t1, $t1, $t0
				add $t1, $t1, $t0
				sw $t1, panelWidth	# increase panelWidth 
				li $t0, 1
				sw $t0, panelMoved	# set panelMoved on
				sw $zero, panelStretch
		
		# require speed update
		speedUpdateTest:
			lw $t0, requireSpeedUpdate
			beqz $t0, winTest
				jal updateSpeed
				sw $zero, requireSpeedUpdate
	
		# test if all blocks been destroyed
		winTest:
			lw $t0, blockRemaining
			bnez $t0, loseTest
				li $t0, 1
				sw $t0, uWin
				sw $zero, gaming
		
		# test if the ball touched the ground
		loseTest:
			lw $t0, gameCheating
			lw $t1, ballTouchBottomWall
			bnez $t0, gameCheck_Exit	
			beqz $t1, gameCheck_Exit
				sw $zero, gaming
				sw $t1, uLose
		
		gameCheck_Exit:
		fexit($ra)
		jr $ra

# }}}

# waitNextClock {{{

	waitNextClock:
		sw $a0, jreg+0
		sw $a1, jreg+4
		sw $ra, jreg+8
		
		keepWaiting:
		li $v0, 30
		syscall					# now current ms been store in $a0
		lw $a1, lastms 			# load lastms into $a1
		jal diff 				# call it motherfucker
		beqz $v0, keepWaiting   # keep waiting until at least 1ms passed
		
		sw $v0, passedms		# store the millisecond been passed since last waiting.
		
		lw $a0, jreg+0
		lw $a1, jreg+4
		lw $ra, jreg+8
		jr $ra
	
	# given two 32bit value A and B, return the distance between two value
	diff:
		slt $v0, $a0, $a1
		bnez $v0, diff_condition2
		diff_condition1:
			subu $v0, $a0, $a1
			jr $ra
		diff_condition2:
			subu $v0, $a1, $a0
			jr $ra

# }}}
	
# movingEvent {{{

	movingEvent:
		moveBall:
			# move ball every frame
			# note we better move this ball 1 pixel at a time 
			# otherwise the ball might cross some object :(
			
			# determine if the ball should follow the panel
			lw $t0, ballFollowPanel
			beqz $t0, noFollow
				lw $t0, panelMovement
				beqz $t0, onMoveBall_exit	# the panel make no move at all
				sw $t0, ballXMovement
				li $t0, 1
				sw $t0, ballMoved
				j onMoveBall_exit
			noFollow:
			
            lw $t0, ballSpeedX          # retrieve motion stuff
            lw $t1, ballSpeedY
            lw $t2, ballXAccMovement    
            lw $t3, ballYAccMovement
            add $t2, $t0, $t2           # calcuate the new accumulated movement of ball
            add $t3, $t1, $t3
            sra $t0, $t2, 10            # div it by 1024, now we got the real movement in pixel
            sra $t1, $t3, 10
            sw $t0, ballXMovement       # store the movement to ballMovement 
            sw $t1, ballYMovement
                bnez $t0, yes_it_is_moving             # if there is some movement, we mark ballMoved on
                bnez $t1, yes_it_is_moving
                j c
                yes_it_is_moving:
                li $t4, 1
                sw $t4, ballMoved
                c:
            sll $t0, $t0, 10            # mul it by 1024
            sll $t1, $t1, 10
            sub $t2, $t2, $t0           # remove these accumulated movement
            sub $t3, $t3, $t1
            sw $t2, ballXAccMovement    # store it back
            sw $t3, ballYAccMovement

		onMoveBall_exit:

		jr $ra

# }}}
	
# ball speed & direction {{{
	
	# Reverse the speed of Y direction
	ballReverseYSpeed:
		lw $t0, ballSpeedSignY
		sub $t0, $zero, $t0
		sw $t0, ballSpeedSignY
		li $t0, 1
		sw $t0, requireSpeedUpdate
		
		jr $ra
		
	# $a0, the x direction. 1 move right, -1 move left, 0 no changes
	# $a1, the y direction. 1 move down, -1 move up, 0 no changes
	setBallDirection:
		
		setX:
			beqz $a0, setY
			lw $a0, ballSpeedSignX
		setY:
			beqz $a1, okkkk
			lw $a1, ballSpeedSignY
			
		okkkk:
			jr $ra
		
	
	# Reverse the speed of X direction
	ballReverseXSpeed:
		lw $t0, ballSpeedSignX
		sub $t0, $zero, $t0
		sw $t0, ballSpeedSignX
		li $t0, 1
		sw $t0, requireSpeedUpdate
		
		jr $ra
	
	# $a0: the speed gonna increase	
	increaseBonusSpeed:
		lw $t0, ballBonusSpeed
		add $t0, $t0, $a0
		
		# trim bonus speed value if exceed its max/min value
		lw $t1, bonusSpeedMaximum
			sgt $t2, $t0, $t1
			beqz $t2, valueOk1
			add $t0, $t1, $zero
		valueOk1:
		lw $t1, bonusSpeedMinimum
			slt $t2, $t0, $t1
			beqz $t2, valueOk2
			add $t0, $t1, $zero
		valueOk2:
		
		sw $t0, ballBonusSpeed
		
		li $t0, 1
		sw $t0, requireSpeedUpdate
		
		jr $ra
		
	increaseProgressSpeed:

		lw $t0, ballProgressSpeed
		add $t0, $t0, $a0
		sw $t0, ballProgressSpeed
		li $t0, 1
		sw $t0, requireSpeedUpdate

		jr $ra
		
	# update the ball speed
	updateSpeed:
		# formula for speed: speedSign * initialSpeed * ( 1 + progress speed / 1024 ) * ( 1 + bonus speed / 1024 ) 
		# speedSign will be 1 or -1, based on the moving direction. Change when collision with wall or blocks
		# progress speed come from game progress, every time a block been destroyed, the value increase.
		# bonus speed based on other event. e.g. ball pushed by panel / ball hitting on the center of board
		fentry($s0,$s1,$s2,$s3)
		
		lw $s0, ballInitialSpeedX
		lw $s1, ballProgressSpeed
		lw $s2, ballBonusSpeed
		li $s3, 1024
		add $s1, $s1, $s3
		add $s2, $s2, $s3
		mtc1 $s0, $f0			# load everything into coprocesss1 registers
		mtc1 $s1, $f1
		mtc1 $s2, $f2
		mtc1 $s3, $f3
		cvt.s.w $f0, $f0		# convert them into single floating point value
		cvt.s.w $f1, $f1
		cvt.s.w $f2, $f2
		cvt.s.w $f3, $f3
		div.s $f1, $f1, $f3		# doing calculate
		div.s $f2, $f2, $f3
		mul.s $f0, $f0, $f1
		mul.s $f0, $f0, $f2
		cvt.w.s $f0, $f0
		mfc1 $s0, $f0			# get the speed
		
		lw $s1, ballSpeedSignX
		mul $s0, $s0, $s1
		sw $s0, ballSpeedX
				
		lw $s0, ballInitialSpeedY
		lw $s1, ballProgressSpeed
		lw $s2, ballBonusSpeed
		li $s3, 1024
		add $s1, $s1, $s3
		add $s2, $s2, $s3
		mtc1 $s0, $f0			# load everything into coprocesss1 registers
		mtc1 $s1, $f1
		mtc1 $s2, $f2
		mtc1 $s3, $f3
		cvt.s.w $f0, $f0		# convert them into single floating point value
		cvt.s.w $f1, $f1
		cvt.s.w $f2, $f2
		cvt.s.w $f3, $f3
		div.s $f1, $f1, $f3		# doing calculate
		div.s $f2, $f2, $f3
		mul.s $f0, $f0, $f1
		mul.s $f0, $f0, $f2
		cvt.w.s $f0, $f0
		mfc1 $s0, $f0			# get the speed
		
		lw $s1, ballSpeedSignY
		mul $s0, $s0, $s1
		sw $s0, ballSpeedY
		
		fexit($s0,$s1,$s2,$s3)
		jr $ra
		
# }}}
	
# collisionHandler {{{

	collisionHandler:
        fentry($s0,$s1,$ra)
	
		handleBall:

            lw $t0, ballX
            lw $t2, ballXMovement
            lw $t1, ballY
            lw $t3, ballYMovement
            add $s0, $t0, $t2 	# the ball left x position of next frame
            add $s1, $t1, $t3	# the ball top  y position of next frame
            lw $t4, ballWidth
            lw $t5, ballHeight
            add $s2, $s0, $t4	# the ball right x position of next frame
            add $s3, $s1, $t5	# the ball bottom y position of next frame

            
			slti $t0, $s0, 0
			bnez $t0, on_leftWallCollision		# test if ball collide with left wall
			
			lw $t1, screen_xsize
			sgt $t0, $s2, $t1
			bnez $t0, on_rightWallCollision		# test if ball collide with right wall
			
			slti $t0, $s1, 0
			bnez $t0, on_topWallCollision		# test if ball collide with top wall
			
			lw $t1, screen_ysize
			sgt $t0, $s3, $t1
			bnez $t0, on_bottomWallCollision
			
			# Nothing happened
			j on_handleCollisionWithWall_End
			
			on_leftWallCollision:
			on_rightWallCollision:
				jal ballReverseXSpeed
				j afterCollision


			on_bottomWallCollision:	
				li $t0, 1
				sw $t0, ballTouchBottomWall
			on_topWallCollision:
				jal ballReverseYSpeed
				j afterCollision
				
			afterCollision:
				sw $zero, ballXMovement		# remove movement
				sw $zero, ballYMovement
			
			on_handleCollisionWithWall_End:

            # Test if any color code intersection. if so, read the color payload 
            # trigger different operation up on color code
            # modify ball movement and speed up on operation
            lw $t0, ballX
            lw $t1, ballY 
            lw $t2, ballXMovement
            lw $t3, ballYMovement
            
            or $t4, $t2, $t3
            beqz $t4, onCollisionHandlerExit	# if there is no movement, we don't have to check collision
            
            add $s0, $t0, $t2           # $s0 = pixel of new ballX
            add $s1, $t1, $t3           # $s1 = pixel of new ballY
            lw $s2, ballWidth           # $s2 = remaining width
            lw $s3, ballHeight          # $s3 = remaining height
            
            # clear collided tag
            li $t0, 64
            li $t1, 0
            keep_do_it_LOL:
            	sw $zero, blockCollided($t1)
            	addi $t1, $t1, 4
            	subi $t0, $t0, 1
            	bnez $t0, keep_do_it_LOL
            
            loop_rows:
                beqz $s3, loop_rows_end         # no more height for scanning
	            lw $t8, screen_xbits
                sllv $t2, $s1, $t8
                sll  $t2, $t2, 2                # $t2 = offset y
                sll  $t3, $s0, 2                # $t3 = offset x
                add  $s4, $t2, $t3              # $s4 = $t2 + $t3, scan offset for next row
                    keep_scanning666:
                        lw $t4, 0x10040000($s4) # $t4 = specific pixel
						lw $t7, ballColor		# $t7 = color of ball
                        beq $t4, $t7, continue_scanning666		# if this is the ball itself, scan next pixel
                        beqz $t4, continue_scanning666			# if there is nothing, scan next pixel 
                        
                        srl $t4, $t4, 24        # $t4 = payload of specific pixel
						andi $a0, $t4, 0x3f		# object id
						andi $a1, $t4, 0xc0		
						srl  $a1, $a1, 6		# collision direction
						
						# if the object already collided, don't do that again
						sll $t8, $a0, 2
						lw $t8, blockCollided($t8)
						bnez $t8, continue_scanning666
							# call it 
							jal collision_event
							
							# set collided tag 
							sll $t8, $a0, 2
							sw $a0, blockCollided($t8)
						
							# print collision object id
							li $v0, 1
							syscall
							li $a0, ' '
							li $v0, 11
							syscall
							add $a0, $a1, $zero
							li $v0, 1
							syscall
							li $a0, '\n'
							li $v0, 11
							syscall
						
						continue_scanning666:
                        subi $s2, $s2, 1
                        addi $s4, $s4, 4
                        bnez $s2, keep_scanning666

                lw $s2, ballWidth                # reload width
                subi $s3, $s3, 1                # minus one height
                addi $s1, $s1, 1                # yoffset plus one
                j loop_rows
             loop_rows_end:

		onCollisionHandlerExit:

        fexit($s0,$s1,$ra)
		
		jr $ra
		
	# Once collision happened, this subroutin get called
	# $a0: the id of object who collide with ball
	# $a1: the direction code 
	collision_event:
		fentry($ra,$s0,$s1,$s2)
		fentry($s3)
		
		# if target is a CR collision
		# Test if this is a real corner collision or not
		lw $t0, collisionCR
		bne $a1, $t0, next_collision_0
			jal getObjectLR
			addi $t0, $v0, 0		# $t0 = object left
			addi $t1, $v1, 0		# $t1 = object right
			lw $t2, ballX			# $t2 = ball left
			lw $t3, ballWidth		# 
			add $t3, $t2, $t3		# $t3 = ball right
			fentry($t0,$t1,$t2,$t3)
			maxdiff($t0,$t1,$t2,$t3,$s0) # $s0 x direction max distance between object with ball
			fexit($t0,$t1,$t2,$t3)
			sub $t0, $t1, $t0
			sub $t1, $t3, $t2
			add $s1, $t0, $t1		# $s1 total width of two object
			
			jal getObjectTB
			addi $t0, $v0, 0		# $t0 = object top
			addi $t1, $v1, 0		# $t1 = object bottom
			lw $t2, ballY			# $t2 = ball top
			lw $t3, ballHeight		# 
			add $t3, $t2, $t3		# $t3 = ball bottom
			
			fentry($t0,$t1,$t2,$t3)
			maxdiff($t0,$t1,$t2,$t3,$s2) # $s2 y direction max distance between object with ball
			fexit($t0,$t1,$t2,$t3)
			
			sub $t0, $t1, $t0
			sub $t1, $t3, $t2
			add $s3, $t0, $t1		# $s3 total height of two object
			
			slt $s0, $s0, $s1		# $s0 == 1 if two object intersect in x direction
			slt $s1, $s2, $s3		# $s1 == 1 if two object intersect in y direction
			sll $s0, $s0, 1
			or $s0, $s0, $s1		# now $s0 is a two bit value, first bit for y and second bit for x
			
			li $t0, 1	# LR
			li $t1, 2	# TB
			li $t2, 0	# CR
			li $t3, 3	# if the object id is 63, the ball must be hit by panel
		
			nop
			nop
			nop
			nop
			nop
			nop
			
			beq $t0, $s0, set_as_LR
			beq $t1, $s0, set_as_TB
			beq $t2, $s0, be_yourself_CR
			beq $t3, $s0, push
			
			set_as_LR:
				lw $a1, collisionLR
				j finally_done
			set_as_TB:
				lw $a1, collisionTB
				j finally_done
			push:
				lw $a1, collisionPushByPanel
				j finally_done
			be_yourself_CR:
				j finally_done
			
			finally_done:
		
			dprintc('c')
			dprintc(':')
			dprintr($a1)
			dprintc('\n')
			
		
		# test panel collision
		next_collision_0:
			lw $t0, panelObjectId
			bne $t0, $a0, next_collision_1
			
			lw $t1, collisionPushByPanel
			bne $t1, $a1, ok_nothing
			pushByPanel:
				li $t0, -3
				sw $t0, ballYMovement
				sw $t0, ballMoved

				fentry($a0)
					# increase speed due to pushing
					lw $a0, ballPushForce
					jal increaseBonusSpeed
				fexit($a0)
				
				# change ball direction based on the pushing direction
				fentry($a0, $a1)
					lw $a0, panelMovement
					sge $a0, $a0, $zero
					bnez $a0, postive		# if movement >  0
					slt $a0, $a0, $zero
					bnez $a0, negative		# if movement <  0
					li $a0, 0				# if movement == 0
					j ok6666
						negative:
							li $a0, -1
						postive:
							li $a0,  1
						ok6666:
					li $a1, -1
					
					jal setBallDirection
				fexit($a0,$a1)
				
				dprintc('P')
				dprintc('\n')
				
				j next_collision_1
						
			ok_nothing:
			
				# Test if the ball hitting the center of panel
				# Center area will be half of the panel, and locate in the middle of panel.
				# if the bottom center spot of ball intersect with the center area, we call this center collision
				# and we decrease the speed of ball
				lw $t0, panelX
				lw $t1, panelWidth
				srl $t1, $t1, 1
				add $t0, $t0, $t1		# $t0 = the center point
				lw $t1, ballX
				lw $t2, ballWidth
				srl $t2, $t2, 1
				add $t1, $t1, $t2		# t1 = the bottom center point
				
				sub $t0, $t0, $t1
				abs $t0, $t0			# the distance between two point
				lw $t1, panelWidth
				srl $t1, $t1, 1
				slt $t0, $t0, $t1		# test if the ball hitting the center area
				beqz $t0, ok_nothing2
					
					fentry($a0)
						lw $a0, ballCollideCenter
						jal increaseBonusSpeed
					fexit($a0)
			
			ok_nothing2:
				
				jal collision_change_ball_movement
		
		# test block collision
		next_collision_1:
			lw $t0, totBlocks
			slt $t1, $a0, $t0
			beqz $t1, next_collision_2
			
			fentry($a0)
				# increase progress speed because this block been destroyed
				lw $a0, ballProgressInc
				jal increaseProgressSpeed
				# increase bonus speed if this is a LR collision
				lw $t8, collisionLR
				bne $t8, $a1, notLR
					lw $a0, blockCollisionLRSpeed
					jal increaseBonusSpeed
				notLR:
			fexit($a0)
			
			# test if this is a special block
			getStatus($a0, $t0)
			lw $t1, blockStatusSpecial
			and $t0, $t1, $t0
				beqz $t0, you_are_mediocre
				# scretch the length of panel on next frame
				li $t0, 2
				sw $t0, panelStretch
			you_are_mediocre:
			
			setStatusDestoryed($a0)
			
			jal collision_change_ball_movement
			
		next_collision_2:
		
		fexit($s3)
		fexit($ra,$s0,$s1,$s2)
		jr $ra
	
	# this function return the left, right coordinate of specific object	
	# $a0 = the specific id of that object
	# $v0 = the left most coordinate 
	# $v1 = the right most coordinate
	getObjectLR:
		lw $t0, panelObjectId
		bne $t0, $a0, that_is_a_block
			lw $v0, panelX
			lw $v1, panelWidth
			add $v1, $v0, $v1
			jr $ra
		that_is_a_block:
			lw $t8, panelMovement
			getXpos($a0, $v0)
			lw $v1, block_width
			add $v1, $v0, $v1
			add $v1, $v1, $t8
			add $v0, $v0, $t8
			jr $ra
			
	# this function return the top, bottom coordinate of specific object	
	# $a0 = the specific id of that object
	# $v0 = the left most coordinate 
	# $v1 = the right most coordinate
	getObjectTB:
		lw $t0, panelObjectId
		bne $t0, $a0, that_is_a_block2
			lw $v0, panelY
			# oops we represent the panel like always 1 pixel height
			addi $v1, $v0, 1
			jr $ra
		that_is_a_block2:
			getYpos($a0, $v0)
			lw $v1, block_height
			add $v1, $v0, $v1
			jr $ra	
		
	# Change ball movement based on collision direction code
	# $a0: the object id 
	# $a1: the direction code
	collision_change_ball_movement:
		fentry($ra)
		lw $t0, collisionLR
		lw $t1, collisionTB
		lw $t2, collisionCR
		beq $t0, $a1, collisionLR_movement
		beq $t1, $a1, collisionTB_movement
		beq $t2, $a1, collisionCR_movement
		j collisionMovement_end
		
		collisionCR_movement:
			sw $zero, ballXMovement
			sw $zero, ballYMovement
			jal ballReverseXSpeed
			jal ballReverseYSpeed
			dprintc('R')
			dprintc('\n')
			j collisionMovement_end
		
		collisionLR_movement:
			sw $zero, ballXMovement
			sw $zero, ballYMovement
			jal ballReverseXSpeed
			dprintc('L')
			dprintc('\n')
			j collisionMovement_end
		collisionTB_movement:
			sw $zero, ballXMovement
			sw $zero, ballYMovement
			jal ballReverseYSpeed
			dprintc('T')
			dprintc('\n')
			
		collisionMovement_end:
		fexit($ra)
		jr $ra
	
	# this subroutine calcuate the max distance between two integer set {$a0, $a1}, {$a2, $a3}
	_maxdiff:
		sub $t0, $a0, $a3
		sub $t1, $a3, $a0
		sub $t2, $a1, $a2
		sub $t3, $a2, $a1
			bge $t0, $t1, t0_is_bigger
			add $t0, $t1, $zero
			t0_is_bigger:
			bge $t2, $t3, t2_is_bigger
			add $t2, $t3, $zero
			t2_is_bigger:
			
		bge $t2, $t0, t2_is_bigger2
		t0_is_bigger2:
			add $v0, $t0, $zero
			jr $ra
		t2_is_bigger2:
			add $v0, $t2, $zero
			jr $ra
		
# }}}
	
# render {{{

	render:
		# TODO: Optimize the render process
		
		addi $sp, $sp, -4
		sw $ra, 0($sp)
			
		testBlocks:
			li $s0, 0
			lw $s1, totBlocks
				loop_blockDestoryed_check:
				
				beq $s0, $s1, loop_blockDestoryed_check_end
				getStatus($s0, $t0)				# retrieve the state of specific block
				lw $t1, blockStatusDestroyed
				and $t0, $t0, $t1
					beqz $t0, continue_aaa	# test if the block has been destoryed
					
					# if so, remove block from bitmap
					add $a0, $s0, $zero
					li $a1, 1
					jal drawBlock
					
					lw $t0, blockRemaining		# minus remaining block counter by one
					sub $t0, $t0, 1
					sw $t0, blockRemaining
					
					sll $t0, $s0, 4
					sw $zero, blocks+12($t0)	# clear status
					
					continue_aaa:				# end of if
				addi $s0, $s0, 1
				j loop_blockDestoryed_check
				
				loop_blockDestoryed_check_end:
			
			
		testBall:
			
			lw $t0, ballMoved
			beqz $t0, testBall_end	
			
			lw $s0, ballX
			lw $s1, ballY
			lw $s2, ballWidth
			lw $s3, ballHeight
			
			# remove the ball from the field
			add $s4, $s1, $s3
					
			# no payload require for ball		
			sw $zero, drawline_firstPixelPayload
			sw $zero, drawline_lastPixelPayload
			sw $zero, drawline_middlePixelPayload
			# draw color on condition
			sw $zero, drawline_anyColor
			lw $t0, ballColor
			sw $t0, drawline_targetColor
			
			fillBallWithPostColor:
				beq $s4, $s1, fillBallWithPostColorEnd
				
				add $a0, $s0, $zero	  # begin of x
				add $a1, $s0, $s2	  # end of x
				add $a2, $s1, $zero	  # y
				lw  $a3, ballPostColor # post color
					
				jal drawline
					
				addi $s1, $s1, 1
				j fillBallWithPostColor
			fillBallWithPostColorEnd:
			
			# change the position of that fucking shit			
			lw $s0, ballX
			lw $s1, ballY
			lw $s2, ballWidth
			lw $s3, ballHeight
			lw $t0, ballXMovement
			lw $t1, ballYMovement
			add $s0, $s0, $t0		# $s0 = the new position for ball X
			add $s1, $s1, $t1		# $s1 = the new position for ball Y
			lw $s5, ballX			# We store the original position for later use
			lw $s6, ballY			# We store the original position for later use
			sw $s0, ballX
			sw $s1, ballY
			sw $zero ballMoved
			
			# draw color on any condition
			li $t0, 1
			sw $t0, drawline_anyColor
			
			# draw it like it's hot
			add $s4, $s1, $s3
			drawBalls:
				beq $s4, $s1, drawBallsEnd
					
				add $a0, $s0, $zero	# begin of x
				add $a1, $s0, $s2	# end of x
				add $a2, $s1, $zero	# y
				lw  $a3, ballColor  # color of ball
					
				jal drawline
					
				addi $s1, $s1, 1
				j drawBalls
			drawBallsEnd:
			
			# only draw color on post ball color
			sw $zero, drawline_anyColor
			lw $t0, ballPostColor
			sw $t0, drawline_targetColor
			
			# remove old ball color from field
			add $s4, $s6, $s3
			removeOldBall:
				beq $s4, $s6, removeOldBallEnd
				
				add $a0, $s5, $zero
				add $a1, $s5, $s2
				add $a2, $s6, $zero
				li  $a3, 0
				
				jal drawline
				
				addi $s6, $s6, 1
				j removeOldBall
				
			removeOldBallEnd:
			
			li $t0, 1
			sw $t0, drawline_anyColor
			
		testBall_end:
			
		testPanel:
			lw $t0, panelMoved
			beqz $t0, testPanel_end	# test if panel moved
			sw $zero, panelMoved	# reset flag
			
			# remove panel frome the field
			sw $zero, drawline_firstPixelPayload
			sw $zero, drawline_middlePixelPayload
			sw $zero, drawline_lastPixelPayload
			lw $a0, panelX			# begin of drawing
			lw $a1, panelWidth
			add $a1, $a1, $a0		# end of drawing
			lw $a2, panelY			# yoffset
			li $a3, 0				# no color
			jal drawline
			
			# draw it with movement
			lw $t0, collisionCR
			lw $t1, collisionCR
			sll $t0, $t0, 6
			sll $t1, $t1, 6
			lw $t2, panelObjectId
			or $t0, $t0, $t2
			or $t1, $t1, $t2
			sw $t0, drawline_firstPixelPayload
			sw $t0, drawline_lastPixelPayload
			sw $t1, drawline_middlePixelPayload
			
			lw $t0, panelMovement
			add $a0, $a0, $t0		# begin of drawing
			add $a1, $a1, $t0		# end of drawing
			lw $a2, panelY
			lw $a3, panelColor
			jal drawline
				
			# update panel
			lw $t1, panelX
			lw $t0, panelMovement
			add $t1, $t1, $t0
			sw $t1, panelX
			sw $zero, panelMovement
		testPanel_end:
			
		testWin:
			lw $t0, uWin
			beqz $t0, testWin_end
			la $a0, win_bitmap
			jal drawPixelArt
		testWin_end:
			
			
		testLose:	
			lw $t0, uLose
			beqz $t0, testLose_end
			la $a0, lose_bitmap
			jal drawPixelArt
		testLose_end: 
			
			
		on_exit:
			lw $ra, 0($sp)
			add $sp, $sp, 4
			jr $ra
	
	# draw Pixel art
	# $a0, the beginning of pixel art array address, each entry are 3 word long, represent [x,y,color]. The array is null-terminated, means [0,0,0]		
	drawPixelArt:
		fentry($a0)
		
		keep_drawing_pixelart:
			lw $t0, 0($a0)
			lw $t1, 4($a0)
			lw $t2, 8($a0)
			
			# test if terminated
			li $t4, 0
			sne $t5, $t0, $zero
			add $t4, $t4, $t5
			sne $t5, $t1, $zero
			add $t4, $t4, $t5
			sne $t5, $t2, $zero
			add $t4, $t4, $t5
			beqz $t4, stop_drawing_pixelart 
			
			# calcuate byte offset of that pixel
			lw $t3, screen_xbits
			sll $t0, $t0, 2
			sll $t1, $t1, 2
			sllv $t1, $t1, $t3
			add $t0, $t0, $t1
			
			# store the color
			sw $t2, 0x10040000($t0)
			
			addi $a0, $a0, 12
			j keep_drawing_pixelart
		stop_drawing_pixelart:
		
		fexit($a0)
		jr $ra
	

# }}}

# handleInput {{{

	# handle input
	handleInput:
		fentry($ra)
		lw $t1, 0xffff0000
		andi $t1, $t1, 0x1
		beqz $t1, handleInput_exit
		lw $t0, 0xffff0004
		sw $zero, 0xffff0004
		
		beq $t0, 'a', left_move
		beq $t0, 'A', left_move
		beq $t0, 'd', right_move
		beq $t0, 'D', right_move
		beq $t0, 'w', shoot_ball
		j handleInput_exit
		
		left_move:
			lw $t1, keyLeftMovement
			sw $t1, panelMovement
			sw $t1, panelMoved
			j testMovment_validity
		
		right_move:
			lw $t1, keyRightMovement
			sw $t1, panelMovement
			sw $t1, panelMoved
			j testMovment_validity
		
		shoot_ball:
            sw $zero, ballFollowPanel
            li $t0, 1
			sw $t0, requireSpeedUpdate
			j handleInput_exit
		
		testMovment_validity:
		
		# test if the movement will go beyond the screen
		lw $t0, panelX
		lw $t1, panelMovement
		add $t0, $t0, $t1
			slt $t0, $t0, $zero
			beqz $t0, nothing1	 # if left_pixel < 0, execute following instruction
			lw $t0, panelX
			sub $t0, $zero, $t0		
			sw $t0, panelMovement	# adjust movement in order to avoid panel coordinate underflow 0
			nothing1:
		lw $t0, panelX
		lw $t1, panelMovement
		lw $t2, panelWidth
		add $t0, $t0, $t1
		add $t0, $t0, $t2
		lw $t1, screen_xsize
			sge $t0, $t0, $t1
			beqz $t0, nothing2  # if right_pixel >= xsize, execute following instruction
			panelRight($t0)
			sub $t0, $t1, $t0
			sw $t0, panelMovement	# adjust movement in order to avoid panel coordinate overflow xsize
			nothing2:
		
		handleInput_exit:
		
			fexit($ra)
			jr $ra	
		
	# allocate space for bitmap
	allocMemory:
		allocBitmap(screen_xsize, screen_ysize)
		jr $ra
		
	# Function for drawing block
	# $a0, the block id
	# $a1, indicate that wipe out this block from bitmap
	drawBlock:
		fentry($a0,$a1,$a2,$a3)
		fentry($s0,$s1,$s2,$s3)
		fentry($s4,$s6,$s7,$ra)
		add $s7, $a0, $zero 		# $s7 = the id of block
		add $s6, $a1, $zero			# $s6 = indicate balabala
		
		getXpos ($a0, $s0)			# $s0 = x pos 
		getYpos ($a0, $s1)			# $s1 = y pos
		getColor($a0, $s2)			# $s2 = color
		lw $s3, block_width			# $s3 = width
		lw $s4, block_height		# $s4 = height
		
		
		beqz $s6, end_if_0000
			li $s2, 0				# no color
			setFirstPixelPayload ($zero, collisionNP)
			setMiddlePixelPayload($zero, collisionNP)
			setLastPixelPayload  ($zero, collisionNP)
		end_if_0000:
		
		# raindrop, draw top
		add $a0, $s0, $zero
		add $a1, $s0, $s3
		add $a2, $s1, $zero
		add $a3, $s2, $zero
		bnez $s6, end_if_0001
			setFirstPixelPayload ($s7, collisionCR)
			setMiddlePixelPayload($s7, collisionTB)
			setLastPixelPayload  ($s7, collisionCR)
		end_if_0001:
		jal drawline
		
		# move to next line
		sub $s4, $s4, 2
		add $s1, $s1, 1
		
		# draw middle
		loop_drawblock:
			add $a0, $s0, $zero
			add $a1, $s0, $s3
			add $a2, $s1, $zero
			add $a3, $s2, $zero
			bnez $s6, end_if_0002
				setFirstPixelPayload ($s7, collisionLR)
				setMiddlePixelPayload($s7, collisionNP)
				setLastPixelPayload  ($s7, collisionLR)
			end_if_0002:
			jal drawline
			addi $s1, $s1, 1
			subi $s4, $s4, 1
			bnez $s4, loop_drawblock
		
		# raindrop, draw bottom
		add $a0, $s0, $zero
		add $a1, $s0, $s3
		add $a2, $s1, $zero
		add $a3, $s2, $zero
		bnez $s6, end_if_0003
			setFirstPixelPayload ($s7, collisionCR)
			setMiddlePixelPayload($s7, collisionTB)
			setLastPixelPayload  ($s7, collisionCR)
		end_if_0003:
		jal drawline

		fexit($s4,$s6,$s7,$ra)
		fexit($s0,$s1,$s2,$s3)
		fexit($a0,$a1,$a2,$a3)		
		# exit function
		jr $ra

# }}}
		
# drawline {{{

	# This method draw a line between [$a0, $a1) with color $a3 on y $a2
	drawline:
		fentry($a0,$a1,$a2,$s0)
		
		lw $t2, drawline_anyColor
		lw $s0, drawline_targetColor
		andi $s0, $s0, 0xffffff
		
		# loading extra argument from global :p
		# this is a hack, Don't do it at home
		lw $t5, drawline_firstPixelPayload
		lw $t6, drawline_middlePixelPayload
		lw $t7, drawline_lastPixelPayload
		sll $t5, $t5, 24
		sll $t6, $t6, 24
		sll $t7, $t7, 24
		
		# transform $a0, $a1, $a2 into byte offset
		sll $a0, $a0, 2
		sll $a1, $a1, 2
		lw  $t0, screen_xbits
		sllv $a2, $a2, $t0
		sll $a2, $a2, 2
		add $a0, $a0, $a2
		add $a1, $a1, $a2
		
		# This code is a serious joke, just like the assignment itself :p
		bnez $t2, justDraw1
		lw $t4, 0x10040000($a0)			# get color
		andi $t4, $t4, 0xffffff			# strip alpha channel
		bne $t4, $s0, DONOT1 			# test if the color match, if so don't paint it
			justDraw1:
			or $t1, $a3, $t5				# compose payload with color code
			sw $t1, 0x10040000($a0)			# store first payload
		DONOT1:
		addi $a0, $a0, 4
		
		or $t1, $a3, $t6				# compose payload with color code
		addi $a1, $a1, -4				# minus target by one pixel
		
		keep_drawing:
			slt $t0,$a0, $a1			# test if $a0 < $a1
			beqz $t0 end_of_drawline	
			
			bnez $t2, justDraw2
			lw $t4, 0x10040000($a0)			# get color
			andi $t4, $t4, 0xffffff			# strip alpha channel
			bne $t4, $s0, DONOT2 			# test if the color match, if so don't paint it
				justDraw2:	
				sw $t1, 0x10040000($a0)		# paint color on bitmap
			DONOT2:
			addi $a0, $a0, 4			# move to next pixel
			
			j keep_drawing
		end_of_drawline:
		
		bnez $t2, justDraw3
		lw $t4, 0x10040000($a0)			# get color
		andi $t4, $t4, 0xffffff			# strip alpha channel
		bne $t4, $s0, DONOT3			# test if the color match, if so don't paint it
			justDraw3:
			or $t1, $a3, $t7				# compose payload with color code
			sw $t1, 0x10040000($a0)			# store it back
		DONOT3:
		
		fexit($a0,$a1,$a2,$s0)
		jr $ra

# }}}
