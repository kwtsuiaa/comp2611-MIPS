#=================#
# THE DALEKS GAME #
#=================#

#---------- DATA SEGMENT ----------
	.data
dalek:	.word 0:399   
# assuming game object size 40x50
width:  .word 510    # 510 game board width
height: .word 505    # 450 game board height plus some space (55) for game state info
drwho:	.word 230 200	#Putting Drwho at the center of the board
msg0:	.asciiz "Enter the number of Daleks you want? "
msg1:	.asciiz "Invalid size!\n"
msg2:	.asciiz "Enter the seed for random number generator? "
msg3:	.asciiz "Dr. Who was hit!"
msg4:	.asciiz "Score: "
msg5:	.asciiz "Screwdriver: "
msg6:	.asciiz "Level: "
border1:	.asciiz "-----------------------------------------\n"
border2:	.asciiz "|                                       |\n"
space: .asciiz " "
newline: .asciiz "\n"

title: .asciiz "THE DALEKS GAME"
dalek_symbol:	.asciiz "dalek.png"
drwho_symbol1:	.asciiz	"drwho1.png"
drwho_symbol2:	.asciiz	"drwho2.png"
rubber_symbol:	.asciiz	"rubble.png"
backgroundImg: .asciiz "background.gif"
images: .word 0:4  # array for file name of all game images


#---------- TEXT SEGMENT ----------
	.text
	.globl __start
__start:


main:
#-------(Start main)------------------------------------------------

	jal setting				# the game setting

	# create image file name array
	la $t0, images
	la $t1, drwho_symbol1
	sw $t1, 0($t0)

	la $t1, drwho_symbol2
	sw $t1, 4($t0)

	la $t1, dalek_symbol
	sw $t1, 8($t0)

	la $t1, rubber_symbol
	sw $t1, 12($t0)

	jal createGame

	ori $s4, $zero, 1			# level = 1
	or $s7, $zero, $zero			# died = 0 (false)
	or $s2, $zero, $zero			# score = 0

	jal createGameObjects
	jal setGameStateOutput
	jal initgame				# initalize the game
	jal updateGameObjects

	li $v0, 100   # create and show the game screen
	li $a0, 4
	syscall

	j main1a

main1:
	jal redrawScreen   # redraw the updated game screen

main1a:
	
	li $v0, 32   # pause some milliseconds
	li $a0, 100
	syscall	

	beq $s7, $zero, main3			# if (!died) goto main3
	jal setGameoverOutput			# Drwho was hit by a dalek. GAME OVER!
	jal redrawScreen   # redraw the updated game screen
	j end_main
	
main3:
	jal drwho_moves				# read the user's input and Drwho moves
	jal daleks_move				# all daleks move
	jal update_state			# update the internal game states
	jal updateGameObjects

	jal is_lv_up
	beq $v0, $zero, main1			# if (!is_lv_up) goto main1
	addi $s4, $s4, 1			# increment level
	sll $s0, $s0, 1				# dalek_num = dalek_num * 2
	
	ori $t0, $zero, 99
	slt $t4, $t0, $s0
	beq $t4, $zero, main4
	ori $s0, $zero, 99
	
main4:	
	jal createGameObjects
	jal setGameStateOutput
	jal initgame
	jal updateGameObjects
	j main1

#-------(End main)--------------------------------------------------
end_main:

# Terminate the program
#----------------------------------------------------------------------
#li $v0, 100
#li $a0, 6
#syscall
ori $v0, $zero, 10
syscall

# Function: Setting up the game
setting:
#===================================================================


setting1:
	ori $t0, $zero, 100			# Max number of daleks
	
	la $a0, msg0				# Enter the number of Daleks you want?
	ori $v0, $zero, 4
	syscall
	
	ori $v0, $zero, 5			# cin >> dalek_num
	syscall
	or $s0, $v0, $zero

	slt $t4, $t0, $s0
	bne $t4, $zero, setting3
	slti $t4, $s0, 1
	bne $t4, $zero, setting3
	j setting2

setting3:
	la $a0, msg1
	ori $v0, $zero, 4			# Invalid size
	syscall
	j setting1

setting2:
	la $a0, newline
	ori $v0, $zero, 4
	syscall

	la $a0, msg2				# Enter the seed for random number generator?
	ori $v0, $zero, 4
	syscall
	
	ori $v0, $zero, 5			# cin >> seed
	syscall
	or $s1, $v0, $zero

	ori $v0, $zero, 40    #set seed
	li $a0, 1
	or $a1, $s1, $zero
	syscall


	jr $ra

#---------------------------------------------------------------------------------------------------------------------
# Function: initalize to a new level
# Generate random positions for Drwho and the daleks
# Set the limit for screwdrivers

initgame: 			
#===================================================================


	addi $sp, $sp, -12
	sw $s5, 8($sp)
	sw $s6, 4($sp)
	sw $ra, 0($sp)

	ori $s3, $zero, 1
	
	la $s5, dalek
	sll $s6, $s0, 4
	add $s6, $s5, $s6
initgame_outer_loop:
	ori $a0, $zero, 48
	jal randnum
	
	sw $v0, 0($s5)
	
	ori $a0, $zero, 41
	jal randnum
	
	sw $v0, 4($s5)
	
	la $t2, drwho
	lw $t0, 0($t2)
	lw $t1, 0($s5)
	sub $t1, $t1, $t0
	sltiu $t0, $t1, 1
	sub $t3, $zero, $t0
	
	lw $t0, 4($t2)
	lw $t1, 4($s5)
	sub $t1, $t1, $t0
	sltiu $t0, $t1, 1
	sub $t3, $t3, $t0
	ori $t0, $zero, 2
	beq $t3, $t0, initgame_outer_loop
	
	sw $zero, 8($s5)
	la $t7, dalek
	addi $t7, $t7, -16
	
initgame_inner_loop:
	addi $t7, $t7, 16
	beq $t7, $s5, initgame_inner_loop_continue
	lw $t0, 0($t7)
	lw $t1, 0($s5)
	bne $t0, $t1, initgame_inner_loop
	lw $t0, 4($t7)
	lw $t1, 4($s5)
	bne $t0, $t1, initgame_inner_loop
	addi $s5, $s5, -16
	
initgame_inner_loop_continue:
	addi $s5, $s5, 16
	bne $s5, $s6, initgame_outer_loop

	
	lw $s5, 8($sp)
	lw $s6, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 12
	jr $ra

#---------------------------------------------------------------------------------------------------------------------
# Function: update game objects

updateGameObjects:				
#===================================================================


	addi $sp, $sp, -12
	sw $s5, 8($sp)
	sw $s6, 4($sp)
	sw $ra, 0($sp)


	la $t0, drwho
	lw $a2, 0($t0)
	lw $a3, 4($t0)

	li $v0, 100	# drwho's location
	li $a0, 12
	li $a1, 6				
	syscall

	li $v0, 100	# drwho's image index
	li $a0, 11
	li $a1, 6
	#addi $a2, $zero, 0	
	addi $a2, $v1, 0	#movement of drwho	
	syscall

	
	
	la $s5, dalek
	sll $s6, $s0, 4
	add $s6, $s6, $s5
	li $t9, 7
print2:
	lw $a2, 0($s5)
	lw $a3, 4($s5)
	li $v0, 100	# dalek's location
	li $a0, 12
	addi $a1, $t9, 0				
	syscall
	
	
	lw $t1, 8($s5)
	ori $t0, $zero,1
	beq $t1, $t0, print3
	ori $t0, $zero,2
	beq $t1, $t0, print5
	
	li $v0, 100	# dalek's image index
	li $a0, 11
	addi $a1, $t9, 0
	li $a2, 2	
	syscall

	j print4
	
print3:
	li $v0, 100	# dalek's image index
	li $a0, 11
	addi $a1, $t9, 0
	li $a2, 3	
	syscall
	j print4

print5:
	li $v0, 100	# dalek's image index
	li $a0, 11
	addi $a1, $t9, 0
	li $a2, -1	
	syscall

print4:	
	addi $t9, $t9, 1
	addi $s5, $s5, 16
	bne $s5, $s6, print2
	
	li $v0, 100	# Score number
	li $a0, 14
	li $a1, 1
	addi $a2, $s2, 0	
	syscall

	li $v0, 100	# Scewdriver number
	li $a0, 14
	li $a1, 3
	addi $a2, $s3, 0	
	syscall

	li $v0, 100	# level number
	li $a0, 14
	li $a1, 5
	addi $a2, $s4, 0	
	syscall

	
finish:
	lw $s5, 8($sp)
	lw $s6, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 12
	
	jr $ra
	
#----------------------------------------------------------------------------------------------------------------------
# Function: set the game state's output objects

setGameStateOutput:				
#===================================================================


	li $t0, 485
	
	li $v0, 100	# Score string
	li $a0, 13
	li $a1, 0
	la $a2, msg4				
	syscall
	
	li $v0, 100	# Score string's location
	li $a0, 12
	li $a1, 0
	li $a2, 30
	move $a3, $t0				
	syscall

	li $v0, 100	# Score number
	li $a0, 14
	li $a1, 1
	addi $a2, $s2, 0	
	syscall
	
	li $v0, 100	# Score number's location
	li $a0, 12
	li $a1, 1
	li $a2, 80
	move $a3, $t0				
	syscall


	li $v0, 100	# Screwdriver string
	li $a0, 13
	li $a1, 2
	la $a2, msg5				
	syscall
	
	li $v0, 100	# Screwdriver string's location
	li $a0, 12
	li $a1, 2
	li $a2, 210
	move $a3, $t0				
	syscall

	li $v0, 100	# Scewdriver number
	li $a0, 14
	li $a1, 3
	addi $a2, $s3, 0	
	syscall
	
	li $v0, 100	# Scewdriver number's location
	li $a0, 12
	li $a1, 3
	li $a2, 300
	move $a3, $t0				
	syscall


	li $v0, 100	# level string
	li $a0, 13
	li $a1, 4
	la $a2, msg6				
	syscall
	
	li $v0, 100	# level string's location
	li $a0, 12
	li $a1, 4
	li $a2, 410
	move $a3, $t0				
	syscall

	li $v0, 100	# level number
	li $a0, 14
	li $a1, 5
	addi $a2, $s4, 0	
	syscall
	
	li $v0, 100	# level number's location
	li $a0, 12
	li $a1, 5
	li $a2, 460
	move $a3, $t0				
	syscall

	jr $ra
	
#----------------------------------------------------------------------------------------------------------------------
# Function: set the gameover output objects

setGameoverOutput:				
#===================================================================

############################
# Please add your code here#
############################

	li $v0, 100
	li $a0, 13
	li $a1, 8
	la $a2, msg3
	syscall
	
	li $v0, 100
	li $a0, 12
	li $a1, 8
	li $a2, 80
	li $a3, 240
	syscall
	
	li $v0, 100
	li $a0, 15
	li $a1, 8
	li $a2, 0xff0f00
	syscall
	
	li $v0, 100
	li $a0, 16
	li $a1, 8
	li $a2, 40
	li $a3, 1
	li $t0, 0
	syscall
	
	jr $ra

	
	
#----------------------------------------------------------------------------------------------------------------------
# Function: 1 read the user's input and 2 handle Drwho's movement

#note:  function drwho_moves returns a value (stored in $v1, make sure $v1 is not changed by other functions) for function dalek_moves
#	when $v1 == 1, legal keystroke is received, daleks can move one step towards drwho;
#	when $$v1 == 0, no (or illegal) keystroke is received, daleks should keep their positions and wait for the next keystroke
drwho_moves:
#===================================================================

############################
# Please add your code here#
############################
	addi $sp, $sp, -12
	sw $ra, 0($sp)
	sw $s5, 4($sp)
	sw $s6, 8($sp)
	jal getInput

	la $t0, drwho
	lw $t1, 0($t0)
	lw $t2, 4($t0)
        
        ori $t3, $zero, 52
	beq $v0, $t3, l
	ori $t3, $zero, 54
        beq $v0, $t3, ri
        ori $t3, $zero, 50
	beq $v0, $t3, d
	ori $t3, $zero, 56
	beq $v0, $t3, u
	ori $t3, $zero, 55
	beq $v0, $t3, ul
	ori $t3, $zero, 57
	beq $v0, $t3, ur
	ori $t3, $zero, 49
	beq $v0, $t3, dl
	ori $t3, $zero, 51
	beq $v0, $t3, dr
	ori $t3, $zero, 53
	beq $v0, $t3, s
	ori $t3, $zero, 116
	beq $v0, $t3, t
	ori $t3, $zero, 114
	beq $v0, $t3, r
	j illegal

	l:
	subi $t1, $t1 ,10
	addi $t3, $zero, 0
	slti $t3, $t1, 20
	bne $t3, $zero, illegal
	sw $t1, 0($t0)
	addi $v1 , $zero, 1
	j finished
	
	ri:
	addi $t1, $t1, 10
	addi $t3, $zero, 0
	slti $t3, $t1, 470
	beq $t3, $zero, illegal
	sw $t1, 0($t0)
	addi $v1 , $zero, 1
	j finished
	
	u:
	subi $t2, $t2 ,10
	addi $t3,$zero,0
	slti $t3, $t2, 20
	bne $t3, $zero, illegal 
	sw $t2, 4($t0)
	addi $v1 , $zero, 1
	j finished
	
	d:
	addi $t2, $t2 ,10
	addi $t3,$zero,0
	slti $t3, $t2, 400
	beq $t3, $zero, illegal
	sw $t2, 4($t0)
	addi $v1 , $zero, 1
	j finished

	ul:
	subi $t2, $t2 ,10
	addi $t3,$zero,0
	slti $t3, $t2, 20
	bne $t3, $zero, illegal
	subi $t1, $t1 ,10
	addi $t3, $zero, 0
	slti $t3, $t1, 20
	bne $t3, $zero, illegal 
	sw $t1, 0($t0)
	sw $t2, 4($t0)
	addi $v1 , $zero, 1
	j finished

	ur:
	subi $t2, $t2 ,10
	addi $t3,$zero,0
	slti $t3, $t2, 20
	bne $t3, $zero, illegal 
	addi $t1, $t1, 10
	addi $t3, $zero, 0
	slti $t3, $t1, 470
	beq $t3, $zero, illegal
	sw $t1, 0($t0)
	sw $t2, 4($t0)
	addi $v1 , $zero, 1
	j finished

	dl:
	addi $t2, $t2 ,10
	addi $t3,$zero,0
	slti $t3, $t2, 400
	beq $t3, $zero, illegal
	subi $t1, $t1 ,10
	addi $t3, $zero, 0
	slti $t3, $t1, 20
	bne $t3, $zero, illegal 
	sw $t1, 0($t0)
	sw $t2, 4($t0)
	addi $v1 , $zero, 1
	j finished

	dr:
	addi $t2, $t2 ,10
	addi $t3,$zero,0
	slti $t3, $t2, 400
	beq $t3, $zero, illegal
	addi $t1, $t1, 10
	addi $t3, $zero, 0
	slti $t3, $t1, 470
	beq $t3, $zero, illegal
	sw $t1, 0($t0)
	sw $t2, 4($t0)
	addi $v1 , $zero, 1
	j finished

	s:
	addi $v1 , $zero, 1
	j finished

	t:
	la $t1, drwho	
	li $a0, 47
	jal randnum
	sw $v0, 0($t1)
	li $a0, 40
	jal randnum
	sw $v0, 4($t1)
	addi $v1, $zero,1
	j finished
	
	r:
	beq $s3, $zero, illegal
	la $t0, drwho
	lw $t1, 0($t0)
	lw $t2, 4($t0)
	la $s5, dalek
	sll $s6, $s0, 4
	add $s6, $s5, $s6
	
	checking:
	lw $t3, 0($s5)
	lw $t4, 4($s5)
	lw $t7, 8($s5)
	bne $t7,$zero,looping
	
	sub $t5,$t1,$t3
	slti $t6,$t5,60
	slti $t7,$t5,-60
	bne $t7,$zero,looping
	beq $t6,$zero,looping
	
	sub $t5,$t2,$t4
	slti $t6,$t5,60
	slti $t7,$t5,-60
	bne $t7,$zero,looping
	beq $t6,$zero,looping
	

	addi $t8,$zero,2
        sw $t8, 8($s5)
	
	looping:
	addi $s5,$s5,16
	bne $s5,$s6,checking
	addi $s3,$s3,-1
	addi $v1 , $zero, 1
	
	j finished

	illegal:
	addi $v1 , $zero, 0
	j finished

	finished:
	lw $ra, 0($sp)
	lw $s5, 4($sp)
	lw $s6, 8($sp)
	addi $sp, $sp, 12
	jr $ra
	
	

#----------------------------------------------------------------------------------------------------------------------
# Function: move the daleks

daleks_move:
#===================================================================

	addi $sp, $sp, -8
	sw $s5, 4($sp)
	sw $s6, 0($sp)

	la $t0, drwho
	lw $t2, 0($t0)
	lw $t3, 4($t0)

	la $s5, dalek
	sll $s6, $s0, 4
	add $s6, $s5, $s6

	#if no (illegal) keystroke is received, daleks should keep still
	beq $v1, 0, daleks_move_end

daleks_move_loop:
	lw $t0, 8($s5)
	bne $t0, $zero, daleks_move_continue

#update x coordinate
	lw $t4, 0($s5)
	slt $t0, $t2, $t4
	beq $t2, $t4, dalek_x_upd
	beq $t0, 0, dalek_x_add_10
	beq $t0, 1, dalek_x_min_10
	
dalek_x_add_10:
	addi, $t4, $t4, 10
	j dalek_x_upd
dalek_x_min_10:
	addi, $t4, $t4, -10
	j dalek_x_upd
dalek_x_upd:	
	sw $t4, 0($s5)

#update y coordinate	
	lw $t5, 4($s5)

	slt $t0, $t3, $t5
	beq $t3, $t5, dalek_y_upd
	beq $t0, 0, dalek_y_add_10
	beq $t0, 1, dalek_y_min_10
	
dalek_y_add_10:
	addi, $t5, $t5, 10
	j dalek_y_upd
dalek_y_min_10:
	addi, $t5, $t5, -10
	j dalek_y_upd
dalek_y_upd:
	sw $t5, 4($s5)

daleks_move_continue:
	addi $s5, $s5, 16
	bne $s5, $s6, daleks_move_loop
	
	lw $s5, 4($sp)
	lw $s6, 0($sp)
	addi $sp, $sp, 8

	
daleks_move_end:			
	jr $ra

#----------------------------------------------------------------------------------------------------------------------
# Function: updating the internal game states like score, also checking any new rubber and life state of Drwho

update_state:
#===================================================================

############################
# Please add your code here#
############################
addi $sp, $sp, -12
sw $s5, 8($sp)
sw $s6, 4($sp)
sw $ra, 0($sp)

la $t0, drwho
lw $t1, 0($t0)
lw $t2, 4($t0)

la $s5, dalek
sll $s6, $s0, 4
add $s6, $s5, $s6

##########
addi $t8,$zero,2
##########

Isdrwhodied:
lw $t3, 0($s5)
lw $t4, 4($s5)
lw $t5, 8($s5)
beq $t5, $t8, next
bne $t1, $t3, next
bne $t2, $t4, next

addi $s7,$zero,1
j exit

next:
addi $s5, $s5, 16
bne $s5, $s6, Isdrwhodied

checkcollision:
la $s5, dalek
sll $s6, $s0, 4
add $s6, $s5, $s6
loop1:
lw $t0, 8($s5)
beq $t0, $t8, looping1
lw $t1, 0($s5)
lw $t2, 4($s5)
la $t3, dalek
loop2:
beq $t3, $s5, looping2
lw $t4, 8($t3)
beq $t4, $t8, looping2
lw $t5, 0($t3)
bne $t5, $t1, looping2
lw $t6, 4($t3)
bne $t6, $t2, looping2

dalek1:
beq $t4, $zero, update1
addi $t7,$zero,1
sw $t7, 8($t3)
dalek2:
beq $t0, $zero, update2
sw $t7, 8($s5)
j looping2

update1:
addi $s2,$s2,10
addi $t7,$zero,1
sw $t7, 8($t3)
j dalek2

update2:
addi $s2,$s2,10
addi $t7,$zero,1
sw $t7, 8($s5)
j looping2

looping1:
addi $s5,$s5,16
bne $s5,$s6,loop1
j exit

looping2:
addi $t3,$t3,16
bne  $t3,$s6,loop2
j looping1

exit:
lw $s5, 8($sp)
lw $s6, 4($sp)
lw $ra, 0($sp)
addi $sp, $sp, 12
jr $ra
	
	
#----------------------------------------------------------------------------------------------------------------------
# Function: check if a new level is reached	
# return $v0: 0 -- false, 1 -- true

is_lv_up:
#===================================================================

############################
# Please add your code here#
############################
addi $sp, $sp, -12
sw $s5, 8($sp)
sw $s6, 4($sp)
sw $ra, 0($sp)

la $s5, dalek
sll $s6, $s0, 4
add $s6, $s5, $s6

loooop:
lw $t1, 8($s5)
bne $t1, $zero, levelup
j nochange

 levelup:
addi $s5,$s5,16
bne $s5,$s6,loooop

li $v0, 1

lw $s5, 8($sp)
lw $s6, 4($sp)
lw $ra, 0($sp)
addi $sp, $sp, 12
jr $ra

nochange:
li $v0, 0

lw $s5, 8($sp)
lw $s6, 4($sp)
lw $ra, 0($sp)
addi $sp, $sp, 12
jr $ra
	
	
#----------------------------------------------------------------------------------------------------------------------
# Function: get keystroke character from keyboard
# return $v0: ASCII value of keystroke character

getInput:
#===================================================================
	addi $v0, $zero, 0

	lui $t8, 0xffff
	lw $t7, 0($t8)
	andi $t7,$t7,1
	beq $t7, $zero, getInput1
	lw $v0, 4($t8)

getInput1:	
	jr $ra

#----------------------------------------------------------------------------------------------------------------------


# Function: generate a random number and return it times 10 in $v0
# $a0 = range
randnum:
#===================================================================
	li $v0, 42
	addi $a1, $a0, 0
	li $a0, 1 
	syscall
	li $t0, 10
	mult $t0, $a0 
	mflo $v0

	jr $ra
#----------------------------------------------------------------------------------------------------------------------


## Function: create game
createGame:
#===================================================================
	li $v0, 100	
	li $a0, 1

	la $t0, width
	lw $a1, ($t0) 
	la $t0, height
	lw $a2, ($t0)

	la $a3, title
	la $t0, backgroundImg
	syscall

	li $v0, 100
	li $a0, 3
	li $a1, 4
	la $a2, images
	syscall
 
	jr $ra
#----------------------------------------------------------------------------------------------------------------------
## Function: create game objects
createGameObjects:
#===================================================================

	li $v0, 100	
	li $a0, 2
	addi $a1, $s0, 8   # besides daleks, need 8 extra game objects for Drwho and text outputs
	syscall
 
	jr $ra
#----------------------------------------------------------------------------------------------------------------------

## Function: redraw game screen
redrawScreen:
#===================================================================
	li $v0, 100   # redraw the updated game screen
	li $a0, 5
	syscall

	jr $ra
#----------------------------------------------------------------------------------------------------------------------
## Function: pause execution for X milliseconds from the specified time T (some moment ago). If the current time is not less than (T + X), pause for only 1ms.    
# $a0 = specified time T (lower 32 bits of the time returned from a previous syscalll of code 30)
# $a1 = X amount of time to pause in milliseconds 
pauseExecution:
#===================================================================
	andi $a0, $a0, 0x3fffffff
	add $t0, $a0, $a1

	li $v0, 30
	syscall
	andi $a0, $a0, 0x3fffffff

	sub $a0, $a0, $t0

	bgt $a0, $zero, positiveTime
	li $a0, 1     # pause for at least 1ms

positiveTime:

	li $v0, 32	 
	syscall

	jr $ra
#----------------------------------------------------------------------------------------------------------------------
