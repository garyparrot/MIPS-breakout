# vim:set syntax=mips:

# Game Display Setting:
#   Bitmap Display
#       Unit Width     : 2
#       Unit Width     : 2
#       Display Width  : 512
#       Display Height : 256
#       Base Address   : 0x10040000(heap)
#   Keyboard MMIO
#       Base Address   : 0xffff0000 (MARS default value

# TODO: Stable Game clock
# TODO: Make panel movement step based on panelWidth

# Macros {{{

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

.macro allocBitmap(%xsize, %ysize)
	fentry($t7,$a0,$v0)
	
	# sbrk: allocate space for bitmap  
	lw $a0, %xsize
	lw $t7, %ysize
	mul $a0, $a0, $t7
	li $v0, 9
	syscall
	
	fexit($t7,$a0,$v0)
.end_macro
.macro debug(%msg, %reg)
	fentry($a0)
	la $a0, %msg
	li $v0, 4
	syscall
	fexit($a0)
	dprintr(%reg)
	dprintc('\n')
.end_macro
.macro dprintr(%reg)
	fentry($a0,$v0)
	add $a0, %reg, $zero
	li $v0, 1
	syscall
	fexit($a0,$v0)
.end_macro
.macro dprintc(%chr)
	fentry($a0,$v0)
	li $a0, %chr
	li $v0, 11
	syscall
	fexit($a0,$v0)
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


.macro getXpos(%block_id,%save_target)
	fentry(%block_id)
	sll %block_id, %block_id, 4
	lw %save_target, blocks+0(%block_id)
	fexit(%block_id)
.end_macro

.macro getYpos(%block_id,%save_target)
	fentry(%block_id)
	sll %block_id, %block_id, 4
	lw %save_target, blocks+4(%block_id)
	fexit(%block_id)
.end_macro

.macro getColor(%block_id,%save_target)
	fentry(%block_id)
	sll %block_id, %block_id, 4
	lw %save_target, blocks+8(%block_id)
	fexit(%block_id)
.end_macro

.macro getStatus(%block_id,%save_target)
	fentry(%block_id)
	sll %block_id, %block_id, 4
	lw %save_target, blocks+12(%block_id)
	fexit(%block_id)
.end_macro

.macro setStatusDestoryed(%block_id)
	fentry(%block_id,$t7,$t8)
	
	sll %block_id, %block_id, 4
	lw $t7, blocks+12(%block_id)
	lw $t8, blockStatusDestroyed
	or $t7, $t7, $t8
	sw $t7, blocks+12(%block_id)
	
	fexit(%block_id,$t7,$t8)
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
	fentry($t7)
	lw %reg, panelX
	lw $t7, panelWidth
	add %reg, %reg, $t7
	fexit($t7)
.end_macro

.macro panelLeft(%reg)
	lw %reg, panelX
.end_macro

.macro terminate()
	li $v0, 10
	syscall
.end_macro

.macro slowHint(%offset)
	fentry($a0,$v0)
	la $a0, msg_runningSlow1
	li $v0, 4
	syscall
	fexit($a0,$v0)
	fentry($a0,$v0)
	move $a0, %offset
	li $v0, 1
	syscall
	fexit($a0,$v0)
	fentry($a0,$v0)
	la $a0, msg_runningSlow2
	li $v0, 4
	syscall
	fexit($a0,$v0)
.end_macro

# }}}

# Data {{{

.data
	
	# display related
	screen_xsize: .word 256
	screen_ysize: .word 128
	screen_xbits: .word 8
	
	# Game status 
	gaming: 	  .word 1 		# is the game running? 
	uWin:		  .word 0
	uLose: 		  .word 0
	gameCheating: .word 0		# cheating mode
    blockCollided: .space 1024
    requireSpeedUpdate: .word 0

	# Blocks
	totBlocks:    		.word 45
    blockRemaining:	    .word 45
	blocks: .word  
	 17,  0,16726342, 0, 51,  0,16726342, 0, 85,  0,16726342, 0,119,  0,16726342, 0,153,  0,16726342, 0,187,  0,16726342, 0,221,  0,16726342, 0,
	  0, 10,16734826, 0, 34, 10,16734826, 0, 68, 10,16734826, 0,102, 10,16734826, 0,136, 10,16734826, 0,170, 10,16734826, 0,204, 10,16734826, 0,238, 10,16734826, 0,
	 17, 20,16734826, 0, 51, 20,16734826, 0, 85, 20,16734826, 0,119, 20,0xff0004, 2,153, 20,16734826, 0,187, 20,16734826, 0,221, 20,16734826, 0,
	  0, 30,16740995, 0, 34, 30,16740995, 0, 68, 30,16740995, 0,102, 30,16740995, 0,136, 30,16740995, 0,170, 30,16740995, 0,204, 30,16740995, 0,238, 30,16740995, 0,
	 17, 40,16745109, 0, 51, 40,16745109, 0, 85, 40,16745109, 0,119, 40,16745109, 0,153, 40,16745109, 0,187, 40,16745109, 0,221, 40,16745109, 0,
	  0, 50,16747937, 0, 34, 50,16747937, 0, 68, 50,16747937, 0,102, 50,16747937, 0,136, 50,16747937, 0,170, 50,16747937, 0,204, 50,16747937, 0,238, 50,16747937, 0,

	block_width:  .word 17
	block_height: .word 10


	# Game Properties
    ballProgressInc: 		.word  40			# the increment for breaking a block
    ballPushForce: 			.word  200			# the bonus speed for panel pushing
    blockCollisionLRSpeed:  .word  32			# the bonus speed for LR collision
    ballCollideCenter: 		.word -128			# the bonus speed for panel center collision
	keyLeftMovement:  		.word -14			# left movement distance of panel
	keyRightMovement: 		.word  14			# right movement distance of panel
    bonusSpeedMaximum: 		.word  1024			# the maximum value of bonus speed
    bonusSpeedMinimum: 		.word -512			# the minimum value of bonus speed

    # Game constant
    msg_runningSlow1:		.asciiz "[Warning] A significant delay detected, about "
    msg_runningSlow2:		.asciiz " ms\n"
    blockStatusDestroyed:   .word 0x1
    blockStatusSpecial:		.word 0x2
	sin_table: .word 
		0x00000000,
		0x3c8ef859,0x3d0ef2c6,0x3d565e3a,0x3d8edc7b,0x3db27eb6,0x3dd61305,0x3df996a2,0x3e0e8365,0x3e20305b,0x3e31d0d4,
		0x3e43636f,0x3e54e6cd,0x3e665991,0x3e77ba5f,0x3e8483ee,0x3e8d2057,0x3e95b1be,0x3e9e377a,0x3ea6b0de,0x3eaf1d43,
		0x3eb77c01,0x3ebfcc6f,0x3ec80de9,0x3ed03fc9,0x3ed8616b,0x3ee0722f,0x3ee87171,0x3ef05e93,0x3ef838f7,0x3f000000,
		0x3f03d989,0x3f07a8ca,0x3f0b6d77,0x3f0f2744,0x3f12d5e8,0x3f167918,0x3f1a108c,0x3f1d9bfd,0x3f211b24,0x3f248dba,
		0x3f27f37c,0x3f2b4c25,0x3f2e9772,0x3f31d521,0x3f3504f3,0x3f3826a7,0x3f3b39ff,0x3f3e3ebd,0x3f4134a5,0x3f441b7d,
		0x3f46f309,0x3f49bb12,0x3f4c7360,0x3f4f1bbd,0x3f51b3f3,0x3f543bce,0x3f56b31d,0x3f5919ae,0x3f5b6f51,0x3f5db3d7,
		0x3f5fe714,0x3f6208da,0x3f641901,0x3f66175e,0x3f6803c9,0x3f69de1d,0x3f6ba635,0x3f6d5bec,0x3f6eff20,0x3f708fb2,
		0x3f720d81,0x3f737870,0x3f74d063,0x3f76153f,0x3f7746ea,0x3f78654d,0x3f797051,0x3f7a67e1,0x3f7b4beb,0x3f7c1c5c,
		0x3f7cd925,0x3f7d8235,0x3f7e1781,0x3f7e98fd,0x3f7f069e,0x3f7f605c,0x3f7fa62f,0x3f7fd814,0x3f7ff605,0x3f800000
	cos_table: .word
		0x3f800000,
		0x3f7ff605,0x3f7fd814,0x3f7fa62f,0x3f7f605c,0x3f7f069e,0x3f7e98fd,0x3f7e1781,0x3f7d8235,0x3f7cd925,0x3f7c1c5c,
		0x3f7b4beb,0x3f7a67e2,0x3f797051,0x3f78654d,0x3f7746ea,0x3f76153f,0x3f74d063,0x3f737871,0x3f720d81,0x3f708fb2,
		0x3f6eff21,0x3f6d5bec,0x3f6ba635,0x3f69de1e,0x3f6803ca,0x3f66175e,0x3f641901,0x3f6208db,0x3f5fe714,0x3f5db3d7,
		0x3f5b6f51,0x3f5919ae,0x3f56b31d,0x3f543bcf,0x3f51b3f3,0x3f4f1bbd,0x3f4c7361,0x3f49bb13,0x3f46f30a,0x3f441b7d,
		0x3f4134a6,0x3f3e3ebd,0x3f3b39ff,0x3f3826a7,0x3f3504f3,0x3f31d522,0x3f2e9772,0x3f2b4c25,0x3f27f37c,0x3f248dbb,
		0x3f211b24,0x3f1d9bfe,0x3f1a108d,0x3f167918,0x3f12d5e8,0x3f0f2744,0x3f0b6d77,0x3f07a8ca,0x3f03d989,0x3f000000,
		0x3ef838f8,0x3ef05e94,0x3ee87172,0x3ee0722f,0x3ed8616c,0x3ed03fca,0x3ec80dea,0x3ebfcc70,0x3eb77c02,0x3eaf1d44,
		0x3ea6b0df,0x3e9e377a,0x3e95b1bf,0x3e8d2058,0x3e8483ef,0x3e77ba61,0x3e665993,0x3e54e6cf,0x3e436370,0x3e31d0d6,
		0x3e20305d,0x3e0e8366,0x3df996a6,0x3dd61308,0x3db27eb9,0x3d8edc7f,0x3d565e41,0x3d0ef2cd,0x3c8ef868,0x32e62a9a,

    # collision code
    collisionCR: .word 3
    collisionLR: .word 2
    collisionTB: .word 1
    collisionNP: .word 0
    collisionPushByPanel: .word 4
    
    # panel
	panelX: 	.word 128
	panelY:		.word 120
	panelWidth: .word 37
	panelMoved: .word 1
	panelMovement:  .word 0
	panelColor: .word 0x00ffffff
	panelObjectId: .word 255
	panelStretch: .word 0
    panelLastMoveDir: .word 0			# last direction

	# ball
	ballX:		.word 144
	ballY:		.word 115
	ballWidth:	.word 5
	ballHeight: .word 5
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
    ballInitialSpeed:	.word  1000		# warning: this value should be postive, if you want to change direction on start up, consult ballSpeedSign
    ballTouchBottomWall: .word 0
    ballSpeedSignX: .word  1
    ballSpeedSignY: .word -1
    ballBonusSpeed: .word 0
    ballProgressSpeed: .word 0			# the progress speed for breaking blocks
    ballAngle: .word 45
    
    # drawline
    drawline_firstPixelPayload: 	.word 0
    drawline_lastPixelPayload:   	.word 0
    drawline_middlePixelPayload:	.word 0
    drawline_targetColor:			.word 0
    drawline_anyColor:				.word 1
    
	# last frame system time
	lastms: 	.word 0
	passedms:   .word 0
	
	# pixel art
	bitmap_scale: .word 2
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
    
# -------------------------------------------
# -  main: the main entry of breakout game  -
# -------------------------------------------
main:
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

# -------------------------------------
# -  gameCheck: checking game status. -
# -------------------------------------
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

# -------------------------------------------------------------------------
# -  waitNextClock: Wait for a frame time, it should be greater than 1ms  -
# -------------------------------------------------------------------------
	waitNextClock:
		fentry($a0,$a1,$ra)
		
		keepWaiting:
		li $v0, 30
		syscall					# now current ms been store in $a0
		lw $a1, lastms 			# load lastms into $a1
		jal diff 				# call it motherfucker
		sltiu $t0, $v0, 20		
		bnez $t0, keepWaiting   # keep waiting until at least 1ms passed
		
		sw $v0, passedms		# store the millisecond been passed since last waiting.
		sltiu $t0, $v0, 30		# if the fps is lower than 10, show a warning.
		bnez $t0, nothing_ok
			slowHint($v0)
		nothing_ok:
		sw $a0, lastms
		
		fexit($a0,$a1,$ra)
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

# -----------------------------------------------------
# -  movingEvent: game procedure, make the ball move  -
# -----------------------------------------------------
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
	
    # -----------------------------------------------------
    # -  ballReverseYSpeed: flip ball's y speed direction -
    # -----------------------------------------------------
	ballReverseYSpeed:
		lw $t0, ballSpeedSignY
		sub $t0, $zero, $t0
		sw $t0, ballSpeedSignY
		li $t0, 1
		sw $t0, requireSpeedUpdate
		
		jr $ra
		
    # --------------------------------------------------------------
    # -  setBallDirection: setting the ball's moving direction     -
    # -                    $a0: the x direction                    -
    # -                    $a1: the y direction                    -
    # -                         1 for right/down direction         -
    # -                        -1 for left/up direction            -
    # -                         0 for no changes                   -
    # --------------------------------------------------------------
	setBallDirection:
		
		setX:
			beqz $a0, setY
			sw $a0, ballSpeedSignX
		setY:
			beqz $a1, okkkk
			sw $a1, ballSpeedSignY
		
		okkkk:
			li $t0, 1
			sw $t0, requireSpeedUpdate
			jr $ra
		
	
    # -----------------------------------------------------
    # -  ballReverseXSpeed: flip ball's x speed direction -
    # -----------------------------------------------------
	ballReverseXSpeed:
		lw $t0, ballSpeedSignX
		sub $t0, $zero, $t0
		sw $t0, ballSpeedSignX
		li $t0, 1
		sw $t0, requireSpeedUpdate
		
		jr $ra
	
    # -----------------------------------------------------------
    # -  increaseBonusSpeed: increase the bonus speed for ball  -
    # -                      $a0: the increment for bonus speed -
    # -----------------------------------------------------------
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
		
    # -----------------------------------------------------------------
    # -  increaseProgressSpeed: increase the progress speed for ball  -
    # -                         $a0: the increment for progress speed -
    # -----------------------------------------------------------------
	increaseProgressSpeed:

		lw $t0, ballProgressSpeed
		add $t0, $t0, $a0
		sw $t0, ballProgressSpeed
		li $t0, 1
		sw $t0, requireSpeedUpdate

		jr $ra
	
    # ----------------------------------------------------------------------
    # -  increaseBallAngle: increase ball's angle by $a0                   -
    # -                     $a0: the increment of ball angle in degree unit-
    # -                 
    # -                     Notice the angle will be limit in 25~90        -
    # ----------------------------------------------------------------------
	increaseBallAngle:
		lw $t0, ballAngle
		add $t0, $a0, $t0

		# test if the value exceed 90 or less than 0
		li $t1, 75
		bgt $t0, $t1, toomuch
		li $t1, 25
		blt $t0, $t1, tooless
		j nothing_you

		toomuch:
			li $t0, 75
			j nothing_you
		tooless:
			li $t0, 25
			j nothing_you
		nothing_you:

		sw $t0, ballAngle
		li $t0, 1
		sw $t0, requireSpeedUpdate

		jr $ra
		
		
    # -------------------------------
    # -  updateSpeed: update speed  -
    # -------------------------------
	updateSpeed:
		# formula for X speed: speedSign * initialSpeed * cos(angle) * ( 1 + progress_speed / 1024 + bonus_speed / 1024 )
		# formula for Y speed: speedSign * initialSpeed * sin(angle) * ( 1 + progress_speed / 1024 + bonus_speed / 1024 )
		# speedSign will be 1 or -1, based on the moving direction. Change when collision with wall or blocks
		# progress speed come from game progress, every time a block been destroyed, the value increase.
		# bonus speed based on other event. e.g. ball pushed by panel / ball hitting on the center of board
		fentry($s0,$s1,$s2,$s3)
		lw $s1 ballAngle
		sll $s1, $s1, 2
		
		lw $s0, ballInitialSpeed
		lw $t0, ballProgressSpeed
		lw $t1, ballBonusSpeed
		li $t2, 1024
		add $t0, $t0, $t1
		add $t0, $t0, $t2		# $t0 = ( 1024 + bonus_speed + progress_speed )
		mtc1 $s0, $f0			# load everything into coprocesss1 registers
		mtc1 $t0, $f1
		mtc1 $t2, $f2
		lwc1 $f3, cos_table($s1)
		cvt.s.w $f0, $f0		# convert them into single floating point value
		cvt.s.w $f1, $f1
		cvt.s.w $f2, $f2
		div.s $f1, $f1, $f2		# $f1 = ( 1024 + bonus_speed + progress_speed )  / 1024
		mul.s $f0, $f0, $f1
		mul.s $f0, $f0, $f3		# $f1 = $f1 * cos(angle)
		cvt.w.s $f0, $f0
		mfc1 $s0, $f0			# get the speed
		
		lw $t1, ballSpeedSignX
		mul $s0, $s0, $t1
		sw $s0, ballSpeedX
		
		lw $s0, ballInitialSpeed
		lw $t0, ballProgressSpeed
		lw $t1, ballBonusSpeed
		li $t2, 1024
		add $t0, $t0, $t1
		add $t0, $t0, $t2		# $t0 = ( 1024 + bonus_speed + progress_speed )
		mtc1 $s0, $f0			# load everything into coprocesss1 registers
		mtc1 $t0, $f1
		mtc1 $t2, $f2
		lwc1 $f3, sin_table($s1)
		cvt.s.w $f0, $f0		# convert them into single floating point value
		cvt.s.w $f1, $f1
		cvt.s.w $f2, $f2
		div.s $f1, $f1, $f2		# $f1 = ( 1024 + bonus_speed + progress_speed )  / 1024
		mul.s $f0, $f0, $f1
		mul.s $f0, $f0, $f3		# $f1 = $f1 * sin(angle)
		cvt.w.s $f0, $f0
		mfc1 $s0, $f0			# get the speed
		
		lw $t1, ballSpeedSignY
		mul $s0, $s0, $t1
		sw $s0, ballSpeedY
		
		fexit($s0,$s1,$s2,$s3)
		jr $ra
		
# }}}
	
# collisionHandler {{{

    # ------------------------------------------------------------------
    # -  collisionHandler: game procedure for handle object collision  -
    # ------------------------------------------------------------------
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
            li $t0, 256
            li $t1, 0
            keep_do_it_LOL:
            	sw $zero, blockCollided($t1)
            	addi $t1, $t1, 4
            	subi $t0, $t0, 1
            	bnez $t0, keep_do_it_LOL
            
            li $a2, 1		# allow movement change at the first collision
            
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
						andi $a0, $t4, 0xff		# object id
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
							li $a0, '\n'
							li $v0, 11
							syscall
							
							li $a2, 0		# disable movement change for later collision event
							
						
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
	# $a1: (deprecated) the direction code, this arguement already deprecated, this argument it doesn't affect anything.
	# $a2: shall this collision event trigger movement chages
	#	   in order to prevent bug caused by collide with multiple instance
	#	   movement change should occur once a frame
	collision_event:
		fentry($ra,$s0,$s1,$s2)
		fentry($s3)
		
		# Test the collision direction, there is three possible value, LF(Left-Right), TB(Top-Bottom), CR(Corner)
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
			li $t3, 3	# if the object id is 255, the ball must be hit by panel
		
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
				lw $a1, collisionCR
				j finally_done
			
			finally_done:
			
		# test panel collision
		next_collision_0:
			lw $t0, panelObjectId
			bne $t0, $a0, next_collision_1
			
			lw $t1, collisionPushByPanel
			bne $t1, $a1, ok_nothing
			pushByPanel:
				lw $t0, ballHeight
				sub $t0, $zero, $t0
				sw $t0, ballYMovement
				sw $t0, ballMoved

				fentry($a0)
					# increase speed due to pushing
					lw $a0, ballPushForce
					jal increaseBonusSpeed
				fexit($a0)
				
				# change ball direction based on the pushing direction
				fentry($a0, $a1)
					lw $a0, panelLastMoveDir
					li $a1, -1
					
					beqz $a2, ok_nothing
					jal setBallDirection
				fexit($a0,$a1)
				

				
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
				
				# Change the movement of ball based on collision info
				beqz $a2, next_collision_1
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
			
			beqz $a2, next_collision_2
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
		fentry($ra,$a0,$a1)
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
			j collisionMovement_end
		
		collisionLR_movement:
			sw $zero, ballXMovement
			sw $zero, ballYMovement
			jal ballReverseXSpeed
			j collisionMovement_end
		collisionTB_movement:
			sw $zero, ballXMovement
			sw $zero, ballYMovement
			jal ballReverseYSpeed
			
		collisionMovement_end:
		
		changeAngle:
			# if the collided object is panel, change angle based on the hitting position
			lw $t0, panelObjectId
			bne $a0, $t0, changeAngle_end
			
			lw $t0, panelWidth
			srl $t0, $t0, 1
			lw $t1, panelX
			add $t0, $t1, $t0
			addi $t0, $t0, 1		# $t0 = the coordinate of panel center
			lw $t1, ballX
			lw $t2, ballWidth
			srl $t2, $t2, 1
			add $t1, $t2, $t1
			addi $t1, $t1, 1		# $t1 = the coordinate of ball 
			sub $t0, $t0, $t1
			abs $t0, $t0			# $t0 = distance between panel and ball x coordinate
			
			lw $t1, panelWidth
			srl $t1, $t1, 2
			sub $a0, $t1, $t0
			jal increaseBallAngle
			
		changeAngle_end:
		
		fexit($ra,$a0,$a1)
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

    # ------------------------------------------------------------------
    # -  render: game procedure for painting object on bitmap display  -
    # ------------------------------------------------------------------
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
			sw $zero, ballXMovement
			sw $zero, ballYMovement
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
			lw $t2, panelObjectId
			sw $t2, drawline_firstPixelPayload
			sw $t2, drawline_lastPixelPayload
			sw $t2, drawline_middlePixelPayload
			
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
			lw $a1, bitmap_scale
			jal drawPixelArt
		testWin_end:
			
			
		testLose:	
			lw $t0, uLose
			beqz $t0, testLose_end
			la $a0, lose_bitmap
			lw $a1, bitmap_scale
			jal drawPixelArt
		testLose_end: 
			
			
		on_exit:
			lw $ra, 0($sp)
			add $sp, $sp, 4
			jr $ra
	
	# draw Pixel art
	# $a0, the beginning of pixel art array address, each entry are 3 word long, represent [x,y,color]. The array is null-terminated
	# $a1, the scale factor of bitmap
	drawPixelArt:
		fentry($a0,$s0,$s1,$a1)
		
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
			
			# scale
			move $s0, $a1	# x
			move $s1, $a1	# y
			mul $t0, $t0, $s0
			mul $t1, $t1, $s0
			
			pixel_art_scale_loop1:
				beqz $s1, pixel_art_scale_loop1_end
				pixel_art_scale_loop2:
					beqz $s0, pixel_art_scale_loop2_end
					# calcuate byte offset of that pixel
					lw $t3, screen_xbits
					move $t4, $t0
					move $t5, $t1
					add $t4, $t4, $s0
					add $t5, $t5, $s1
					sll $t4, $t4, 2
					sll $t5, $t5, 2
					sllv $t5, $t5, $t3
					add $t5, $t5, $t4
				
					# store the color
					sw $t2, 0x10040000($t5)
															
					# minus
					addi $s0, $s0, -1
					j pixel_art_scale_loop2
				pixel_art_scale_loop2_end:
				move $s0, $a1
				addi $s1, $s1, -1
				j pixel_art_scale_loop1
			pixel_art_scale_loop1_end:

			addi $a0, $a0, 12
			j keep_drawing_pixelart
		stop_drawing_pixelart:
		
		fexit($a0,$s0,$s1,$a1)
		jr $ra
	

# }}}

# handleInput {{{

    # -------------------------------------------------------
    # -  handleInput: game procedure for handle user input  -
    # -------------------------------------------------------
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
			li $t1, -1
			sw $t1, panelLastMoveDir
			lw $t1, keyLeftMovement
			sw $t1, panelMovement
			sw $t1, panelMoved
			j testMovment_validity
		
		right_move:
			li $t1, 1
			sw $t1, panelLastMoveDir
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
			sw $zero, drawline_firstPixelPayload
			sw $zero, drawline_middlePixelPayload
			sw $zero, drawline_lastPixelPayload
		end_if_0000:
		
		# raindrop, draw top
		add $a0, $s0, $zero
		add $a1, $s0, $s3
		add $a2, $s1, $zero
		add $a3, $s2, $zero
		bnez $s6, end_if_0001
			sw $s7, drawline_firstPixelPayload
			sw $s7, drawline_middlePixelPayload
			sw $s7, drawline_lastPixelPayload
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
				sw $s7, drawline_firstPixelPayload
				sw $s7, drawline_middlePixelPayload
				sw $s7, drawline_lastPixelPayload
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
			sw $s7, drawline_firstPixelPayload
			sw $s7, drawline_middlePixelPayload
			sw $s7, drawline_lastPixelPayload
		end_if_0003:
		jal drawline

		fexit($s4,$s6,$s7,$ra)
		fexit($s0,$s1,$s2,$s3)
		fexit($a0,$a1,$a2,$a3)		
		# exit function
		jr $ra

# }}}
		
# drawline {{{

    # ---------------------------------------------------------------------------------------------------------------------------
    # -  drawline: draw a line on screen                                                                                        -
    # -            $a0: the index of first x coordinate                                                                         -
    # -            $a1: the index of end x coordinate                                                                           -
    # -            $a2: the index of y coordinate                                                                               -
    # -            $a2: color                                                                                                   -   
    # -   global parameter                                                                                                      -
    # -      drawline_firstPixelPayload : Payload for first pixel                                                               -
    # -      drawline_middlePixelPayload: Payload for middle pixel                                                              -
    # -      drawline_lastPixelPayload  : Payload for last pixel                                                                -
    # -      drawline_targetColor       : Only draw pixel on specific color                                                     -
    # -      drawline_anyColor          : Draw pixel on any color, this parameter will overwrite rule of targetColor if enabled -
    # ---------------------------------------------------------------------------------------------------------------------------
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
