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
	Gaming: 	  .word 1 		# is the game running? 
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
         12, 25,   65535, 0, 28, 25,   65535, 0, 44, 25,   65535, 0, 60, 25,   65535, 0, 76, 25,   65535, 0, 92, 25,   65535, 0,108, 25,   65535, 0
    
    # panel
	panelX: 	.word 58
	panelY:		.word 60
	panelWidth: .word 13
	panelMoved: .word 1
	panelMovement:  .word 0
	panelColor: .word 0x00ffffff
	panelObjectId: .word 63

	# ball
	ballX:		.word 63
	ballY:		.word 55
	ballWidth:	.word 3
	ballHeight: .word 3
	ballMoved:  .word 1
	ballSpeedX: .word 0             # the value add to XMovement every frame
	ballSpeedY: .word 0             # the value add to YMovement every frame
	ballColor:  .word 0x00eeeeee	# warning: ball color must be unique to other color on the screen
    ballXAccMovement: .word 0          # for every 1024 value, this ball moved one x pixel
    ballYAccMovement: .word 0          # for every 1024 value, this ball moved one y pixel
	ballXMovement: .word 0
	ballYMovement: .word 0
	ballFollowPanel:  	.word  1
	ballFollowOffsetX: 	.word  5
	ballFollowOffsetY:  .word -5
    ballInitialSpeedX:  .word  300
    ballInitialSpeedY:  .word -150
    
    # collision code
    collisionCR: .word 3
    collisionLR: .word 2
    collisionTB: .word 1
    
    # drawline
    drawline_firstPixelPayload: 	.word 0
    drawline_lastPixelPayload:   	.word 0
    drawline_middlePixelPayload:	.word 0
	
	# last frame system time
	lastms: 	.word 0
	passedms:   .word 0

# }}}
	
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
		
		# Drawing shit on the screen
		jal render

		# loop
		lw $t7, Gaming
		bnez $t7, GameLoop
	
	# exit
	terminate()

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
			# move ball based on passed time, current speed
			# note we better move this ball 1 pixel at a time 
			# otherwise the ball might cross some object :(
			
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

		jr $ra

# }}}
	
# collisionHandler {{{

	collisionHandler:

        addi $sp, $sp, -12
        sw $s0, 0($sp)
        sw $s1, 4($sp)
        sw $ra, 8($sp)
	
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
				lw $t0, ballSpeedX
				sub $t0, $zero, $t0		# negative speed-x
				sw $t0, ballSpeedX
				j afterCollision
									
			on_topWallCollision:
			on_bottomWallCollision:
				lw $t0, ballSpeedY
				sub $t0, $zero, $t0
				sw $t0, ballSpeedY		# negative speed-y
				j afterCollision
				
			afterCollision:
				sw $zero, ballXMovement		# remove movement
				sw $zero, ballYMovement
			
			on_handleCollisionWithWall_End:

			# TODO: handle collision between ball and block

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
						jal collision_event
						
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

        lw $s0, 0($sp)
        lw $s1, 4($sp)
        lw $ra, 8($sp)
        addi $sp, $sp, 12
		
		jr $ra
		
	# Once collision happened, this subroutin get called
	# $a0: the if of object who collide with ball
	# $a1: the direction code 
	collision_event:
		
		add $sp, $sp, -4
		sw $ra, 0($sp)
		
		# test panel collision
		next_collision_0:
			lw $t0, panelObjectId
			bne $t0, $a0, next_collision_1
			
			jal collision_change_ball_movement
		
		next_collision_1:
		
		lw $ra, 0($sp)
		add $sp, $sp, 4
		
		jr $ra
		
	# Change ball movement based on collision direction code
	# $a1: the direction code
	collision_change_ball_movement:
		lw $t0, collisionLR
		lw $t1, collisionTB
		lw $t2, collisionCR
		beq $t0, $a1, collisionLR_movement
		beq $t1, $a1, collisionTB_movement
		beq $t2, $a1, collisionCR_movement
		jr $ra
		collisionCR_movement:
			# TODO: Implement CR movement		
		
		collisionLR_movement:
			sw $zero, ballXMovement
			sw $zero, ballYMovement
			lw $t0, ballSpeedX
			sub $t0, $zero, $t0
			sw $t0, ballSpeedX
			jr $ra
		collisionTB_movement:
			sw $zero, ballXMovement
			sw $zero, ballYMovement
			lw $t0, ballSpeedY
			sub $t0, $zero, $t0
			sw $t0, ballSpeedY
			jr $ra
		
# }}}
	
# render {{{

	render:
		# TODO: Optimize the render process
		
		addi $sp, $sp, -4
		sw $ra, 0($sp)
	
		testPanel:
			lw $t0, panelMoved
			beqz $t0, testBlocks	# test if panel moved
			sw $zero, panelMoved	# reset flag
			
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
			lw $t0, collisionLR
			lw $t1, collisionTB
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
			
			# determine if the ball should follow the panel
				lw $t0, ballFollowPanel
				beqz $t0, a
				lw $t0, panelMovement
				sw $t0, ballXMovement
				li $t0, 1
				sw $t0, ballMoved
				a:
			
			# done
			
		testBlocks:
			# TODO: Implement block render it :(
			
		testBall:
			
			lw $t0, ballMoved
			beqz $t0, on_exit	
			
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
			
			clearBalls:
				beq $s4, $s1, clearBallsEnd
				
				add $a0, $s0, $zero	  # begin of x
				add $a1, $s0, $s2	  # end of x
				add $a2, $s1, $zero	  # y
				add $a3, $zero, $zero # clear color
					
				jal drawline
					
				addi $s1, $s1, 1
				j clearBalls
			clearBallsEnd:
			
			# change the position of that fucking shit			
			lw $s0, ballX
			lw $s1, ballY
			lw $s2, ballWidth
			lw $s3, ballHeight
			lw $t0, ballXMovement
			lw $t1, ballYMovement
			add $s0, $s0, $t0
			add $s1, $s1, $t1
			sw $s0, ballX
			sw $s1, ballY
			sw $zero ballMoved
			
			# draw it like it hot
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
			
		on_exit:
			lw $ra, 0($sp)
			add $sp, $sp, 4
			jr $ra

# }}}

# handleInput {{{

	# handle input
	handleInput:
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
			j handleInput_exit
		
		right_move:
			lw $t1, keyRightMovement
			sw $t1, panelMovement
			sw $t1, panelMoved
			j handleInput_exit
		
		shoot_ball:
            sw $zero, ballFollowPanel
            lw $t0, ballInitialSpeedX
            sw $t0, ballSpeedX
            lw $t0, ballInitialSpeedY
            sw $t0, ballSpeedY
			j handleInput_exit
		
		handleInput_exit:
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

# }}}
		
# drawline {{{

	# This method draw a line between [$a0, $a1) with color $a3 on y $a2
	drawline:
		addi $sp, $sp, -16
		sw $a0, 0($sp)
		sw $a1, 4($sp)
		sw $a2, 8($sp)
		
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
		or $t1, $a3, $t5				# compose payload with color code
		sw $t1, 0x10040000($a0)			# store first payload
		addi $a0, $a0, 4
		
		or $t1, $a3, $t6				# compose payload with color code
		addi $a1, $a1, -4				# minus target by one pixel
		
		keep_drawing:
			slt $t0,$a0, $a1			# test if $a0 < $a1
			beqz $t0 end_of_drawline	
			
			sw $t1, 0x10040000($a0)		# paint color on bitmap
			addi $a0, $a0, 4			# move to next pixel
			
			j keep_drawing
		end_of_drawline:
		
		or $t1, $a3, $t7				# compose payload with color code
		sw $t1, 0x10040000($a0)			# store it back
		
		lw $a0, 0($sp)
		lw $a1, 4($sp)
		lw $a2, 8($sp)
		addi $sp, $sp, 16
		
		jr $ra

# }}}
