# GAME SIZE: 10 pixel width and 19 pixel height
# Controls:
# TO START: enter:
# 3: Hardest Difficulty
# 2: Second Hardest Difficulty
# 1: Third Hardest Difficulty
# Any other key: Easiest Difficulty

# When Playing:
# Press p to pause and unpause and q to quit
# Press a to shift column left and d to shift column right
# Press s to shift column down
# Press w to cycle column

.data
displayaddress:     .word       0x10008000
RED: .word 0xff0000
YELLOW: .word 0xffff00
BLUE: .word 0x0000ff
GREEN: .word 0x00ff00
TURQOUISE: .word 0x00ffff
PURPLE: .word 0xff00ff
GREY: .word 0x808080
BLACK: .word 0x000000
X_MAX: .word 10
Y_MAX: .word 19
WAITLIST_START: .word 0x100085d8
COLUMN_START: .word 0x100083a4
BOTTOM_LEFT: .word 0x10008c90
ADDR_KBRD: .word 0xffff0000
GAME_POINT: .word 0
WAIT_CYCLE: .word 100
DIFFICULTY_LEVEL: .word 0

TO_CLEAR_STACK: .space 400
GAMW_OVER_CONDITION_PIXEL: .word 0x100084a4


.text
# ...
re_start_the_game:
li $t1, 0x808080 # $t1 = Grey
li $s5, 0x808080 # $t1 = Grey
li $s0 0xff0000 #  $s0 = Red
li $s1 0xffff00 # $s1 = Yellow
li $s2 0x0000ff # s2 = Green

lw $t0, displayaddress # $t0 = base address for display

### user input difficulty level to start the game ###
input_difficulty:
    lw $t9, ADDR_KBRD               # $t0 = base address for keyboard
    lw $t8, 0($t9)                  # Load first word from keyboard
    beq $t8, 1, difficulty_input      # If first word 1, key is pressed
    j input_difficulty

# this is to react to what the keyboard is pressed
difficulty_input:                     # A key is pressed
    lw $t5, 4($t9)                  # Load second word from keyboard
    # arithmetic to calculate the difficulty level (wait cycle for each shifting)
    move $t6, $zero
    addi $t6, $t6, 3
    and $t7, $t6, $t5
    sw $t7, DIFFICULTY_LEVEL        # $t7 is the difficulty level (1, 2, or 3)

jal update_wait_cycle
    
# update the number of cycles (miliseconds) it should wait, before proceeding to the next shift
# 100 - 8 * DIFFICULTY_LEVEL - DIFFICULTY_LEVEL * (GAME_POINT //8)
# dont use $a0
# $t1 represents the difficulty level
# $t2 represents the current score

##### SETUP #####

### X ###

 # X Pointer
addiu $t0, $t0, 12 # Start 3 pixels from the left
addiu $t3, $zero, 6 # Start 6 pizels from the top 
sll $t3, $t3, 7
addu $t0, $t0, $t3

li $t3, 0 # X Counter

li $t4, 12 # X Max
li $t5, 20 # Y Max

sll $t7, $t5, 7 # Y Max Offset

X_LOOP: 
beq $t3, $t4, X_END

move $t8, $t0 # Use temp register for X offset
sw $s5, 0($t8)

addu $t8, $t8, $t7 # Offset by Y Max
sw $s5, 0($t8)

addiu $t3, $t3, 1
addiu $t0, $t0, 4

j X_LOOP

X_END:

### Y ###

# RESET start
lw $t0, displayaddress # $t0 = base address for display

# Y Pointer
addiu $t0, $t0, 12 # Start 3 pixels from the left
addiu $t3, $zero, 6 # Start 6 pizels from the top 
sll $t3, $t3, 7
addu $t0, $t0, $t3

li $t3, 0 # Y Counter

li $t4, 12 # X Max
li $t5, 20 # Y Max

# X max offset
sll $t7, $t4, 2
subiu $t7, $t7, 4

Y_LOOP:
beq $t3, $t5, Y_END

move $t8, $t0
sw $s5, 0($t8)

addu $t8, $t8, $t7
sw $s5, 0($t8)

addiu $t0, $t0, 128
addiu $t3, $t3, 1

j Y_LOOP

Y_END:

lw $t0, displayaddress # Store Column Pointer in $t0

##### MAIN MOVEMENT LOOP #####
jal REFILL_WAITLIST
jal DRAW_INIT
move $t0, $v0 # GET NEW POINTER
jal REFILL_WAITLIST















### MAIN LOOP WHERE GAME IS PLAYED


MAIN_LOOP: 

lw $s7, displayaddress
# SET SHIFT PARAMETERS
move $a0, $t0 # LOCATION TO SHIFT FROM
addi $t1, $t0, 128                  # load the address below the pointer
lw $t1, 0($t1)                      # load the color in that pixel
bne $t1, $zero, no_more_shift       # if the pixel below is not black, dont shift anymore
li $a1, 3 # SIZE OF SHIFT

jal SHIFT # CALL SHIFT
move $t0, $v0 # GET NEW POINTER
no_more_shift:
addu $t1, $t0, 128 # PEEK THE PIXEL BELOW POINTER
# GET COLOUR AT LOCATION $t0
lw $t2 0($t1)

li $t3, 0           # time counter, wating time before next shift-downward
# If pixel below is not empty then need to resolve collision
DETECT_COLLISION: beq $t2, $zero, NO_COLLISION
### DEAL WITH COLOURS THEN SCORING AND SUCH

RESOLVE:
jal FILL_STACK

move $a0, $v0 # GET STACK SIZE

lw $t1, GAME_POINT              # load the curent game point into $t1
add $t1, $t1, $a0               # inrement $t1 by the socre earned this round
sw $t1, GAME_POINT              # update the score to GAME_POINT


jal display_score               # display the score
tem_to_retrun:                  # this is simply a dummy return from display_score

jal update_wait_cycle
beq $a0, $zero, NO_CLEARS # IF STACK WAS NOT PUSHED TO, DONT SHIFT

jal CLEAR_STACK
jal SHIFT_DOWN # SHIFT DOWN

j RESOLVE # CHECK NEW SHIFTED BLOCKS

NO_CLEARS:

jal DRAW_INIT
move $t0, $v0 # GET NEW POINTER
jal REFILL_WAITLIST # SHOW NEXT BLOCK AFTER CURRENT

NO_COLLISION:

move $a0, $t0

jal main_run    #listen to any keyboard input

move $t0, $v0

addi $t3, $t3, 1    # increment by one for each cycle it waits
li $v0, 32
li $a0, 10
syscall
lw $t4, WAIT_CYCLE
# to-do: check that exact pixel filled or not to terminate it
beq $t3, $t4, MAIN_LOOP        # if it waits (or loops) 100 times, then move on to next shifting

j NO_COLLISION

# ##### TERMINATE #####
# j EXIT

# Function for getting next column
REFILL_WAITLIST:

li $t4, 12 # X Max
li $t5, 20 # Y Max

lw $s3, WAITLIST_START
move $t3, $zero # Counter
addiu $t4, $zero, 3 # Max Value

WAIT_LOOP: beq $t3, $t4, WAIT_END

li $v0, 42
li $a0, 0
li $a1, 6
syscall # Generate random colour

# Constants
li $t1, 1
li $t2, 2
li $t6, 3
li $t7, 4
li $t8, 5

# Update position before branch
move $t5, $t3
sll $t5, $t5, 7

addu $t5, $t5, $s3

# Branch
beq $a0, $zero, GET_RED
beq $a0, $t1, GET_YELLOW
beq $a0, $t2, GET_BLUE
beq $a0, $t6, GET_GREEN
beq $a0, $t7, GET_TURQOUISE
beq $a0, $t8, GET_PURPLE

GET_RED:
lw $s0, RED
sw $s0 0($t5)
j  GET_COL_END

GET_YELLOW:
lw $s0, YELLOW
sw $s0 0($t5)
j  GET_COL_END

GET_BLUE:
lw $s0, BLUE
sw $s0 0($t5)
j  GET_COL_END


GET_GREEN:
lw $s0, GREEN
sw $s0 0($t5)
j  GET_COL_END

GET_TURQOUISE:
lw $s0, TURQOUISE
sw $s0 0($t5)
j  GET_COL_END

GET_PURPLE:
lw $s0, PURPLE
sw $s0 0($t5)
j  GET_COL_END

GET_COL_END:

addiu $t3, $t3, 1

j WAIT_LOOP
WAIT_END:

jr $ra

### FUNCTION ###
# $a0 Colour of Pixel
# $a1 Location to Draw Pixel
DRAW_PIXEL: # DRAW SINGLE PIXEL

sw $a0 0($a1)
jr $ra

### FUNCTION ###
DRAW_INIT: # DRAW TOP 3 PIXELS

# LATER add a branch to flag game over
lw $t3, GAMW_OVER_CONDITION_PIXEL
lw $t4, 0($t3)
bne $t4, $zero, game_over            # if at this pixel, its not black, game over

### SETUP ###
li $t3, 3 # Max Iter
li $t4, 0 # Counter

### GET POINTER TO COLUMN
lw $t2, COLUMN_START
addiu $t2, $t2, -128

### GET POINTER TO WAITLIST
lw $t7, WAITLIST_START
addiu $t7, $t7, 256 # GET TO BOTTOM
DRAW_INIT_LOOP1: beq $t3, $t4, DRAW_INIT_LOOP1_END

move $t5, $t4 # COUNTER

### GET POINTER TO BOTTOM
move $t1, $t2
DRAW_INIT_LOOP2: beq $t5, $zero, DRAW_INIT_LOOP2_END

# PASS IN BOTTOM COLOUR
lw $a0 0($t1)

# PASS IN ADDRESS ONE BELOW
addiu $a1, $t1, 128

### CALL DRAW PIXEL
addi $sp, $sp, -4 # Move stack pointer to empty location
sw $ra, 0($sp) # Move Return Address to Stack
jal DRAW_PIXEL
lw $ra, 0($sp) # Move Return Address back
addi $sp, $sp, 4 # Move stack pointer to top element on stack

# DECREMENT COUNTER
addiu $t5, $t5, -1
# DECREMENT POINTER
addiu $t1, $t1, -128
j DRAW_INIT_LOOP2
DRAW_INIT_LOOP2_END:

# DRAW NEXT PIXEL OFF WAITLIST
lw $a0, 0($t7)
lw $s4, COLUMN_START
move $a1, $s4

addi $sp, $sp, -4 # Move stack pointer to empty location
sw $ra, 0($sp) # Move Return Address to Stack
jal DRAW_PIXEL
lw $ra, 0($sp) # Move Return Address back
addi $sp, $sp, 4 # Move stack pointer to top element on stack

li $v0, 32
li $a0, 100
syscall


addiu $t4, $t4, 1 # INCREMENT COUNTER
addiu $t2, $t2, 128 # INCREMENT COLUMN POINTER
addiu $t7, $t7, -128 # INCREMENT WAITLIST POINTER
j DRAW_INIT_LOOP1
DRAW_INIT_LOOP1_END:

# RETURNS THE BOTTOM OF THE COLUMN IN $v0
move $v0, $t2
jr $ra

### FUNCTION ###
# Shift the column starting at $a0, given it has length $a1
SHIFT:
move $t1, $a0 # POINTER
move $t2, $a1 # COUNTER
addiu $v0, $t1, 128 # STORE NEW BOTTOM ADDRESS

SHIFT_LOOP: beq $t2, $zero, SHIFT_LOOP_END

# PASS IN BOTTOM COLOUR
lw $a0 0($t1)

# PASS IN ADDRESS ONE BELOW
addiu $a1, $t1, 128

### CALL DRAW PIXEL
addi $sp, $sp, -4 # Move stack pointer to empty location
sw $ra, 0($sp) # Move Return Address to Stack
jal DRAW_PIXEL
lw $ra, 0($sp) # Move Return Address back
addi $sp, $sp, 4 # Move stack pointer to top element on stack

# DECREMENT COUNTER
addiu $t2, $t2, -1
# DECREMENT POINTER
addiu $t1, $t1, -128

j SHIFT_LOOP
SHIFT_LOOP_END:
addiu $t1, $t1, 128 # RESET TO TOP POSITION
sw $zero 0($t1) # OVERWRITE TO BLACK TO CREATE SHIFT

jr $ra



# this is detect if keyboard is pressed
# Arguments: $a0 the pointer to the current location
# Returns: $v0 new output value
main_run:                           # part of this function is from the starter code
    move $t0, $a0
    lw $t9, ADDR_KBRD               # $t0 = base address for keyboard
    lw $t8, 0($t9)                  # Load first word from keyboard
    beq $t8, 1, keyboard_input      # If first word 1, key is pressed
    move $v0, $t0
    jr $ra

# this is to react to what the keyboard is pressed
keyboard_input:                             # A key is pressed, part of this function is from the starter code
    lw $t5, 4($t9)                          # Load second word from keyboard
    beq $t5, 0x77, shuffle                  # Check if the key W was pressed
    beq $t5, 0x61, shiftL                   # Check if the key A was pressed
    beq $t5, 0x64, shiftR                   # Check if the key D was pressed
    beq $t5, 0x73, shift_down               # Check if the key S was pressed
    beq $t5, 0x70, pause_for_next_p         # Check if the key P was pressed
    beq $t5, 0x71, EXIT                     # Check if the key Q was pressed, quit the game
    

    j main_run

shuffle:
    subi $t0, $t0, 256
    lw $t6, 0($t0)
    lw $t7, 128($t0)
    lw $t8, 256($t0) 
    
    
    sw $t8, 0($t0)          # paint the first unit (i.e., top-left) red
    sw $t6, 128($t0)          # paint the second unit on the first row green
    sw $t7, 256($t0)        # paint the first unit on the second row blue
    addi $t0, $t0, 256
    move $v0, $t0
    jr $ra
    
shiftL:
    lw $s0 -4($t0)
    bne $s0, $zero, SHIFTL_END
    subi $t0, $t0, 256
    lw $t6, 0($t0)          # load the current color from the top 
    lw $t7, 128($t0)
    lw $t8, 256($t0) 
    
    lw $s3, BLACK
    sw $s3, 0($t0)          # paint the first unit (i.e., top-left) red
    sw $s3, 128($t0)          # paint the second unit on the first row green
    sw $s3, 256($t0)
    

    
    sub $t0, $t0, 4
    sw $t6, 0($t0)          # paint the first unit (i.e., top-left) red
    sw $t7, 128($t0)          # paint the second unit on the first row green
    sw $t8, 256($t0)
    addi $t0, $t0, 256
    
    SHIFTL_END:
    
    move $v0, $t0
    jr $ra
    
shiftR:
    lw $s0 4($t0)
    bne $s0, $zero, SHIFTR_END
    subi $t0, $t0, 256
    lw $t6, 0($t0)          # load the current color from the top 
    lw $t7, 128($t0)
    lw $t8, 256($t0) 
    
    lw $s3, BLACK
    sw $s3, 0($t0)          # paint the first unit (i.e., top-left) red
    sw $s3, 128($t0)          # paint the second unit on the first row green
    sw $s3, 256($t0)

    
    add $t0, $t0, 4
    sw $t6, 0($t0)          # paint the first unit (i.e., top-left) red
    sw $t7, 128($t0)          # paint the second unit on the first row green
    sw $t8, 256($t0)
    addi $t0, $t0, 256
    
    SHIFTR_END:
    
    move $v0, $t0
    jr $ra
    
shift_down:
    lw $s0 128($t0)
    bne $s0, $zero, SHIFT_DOWN_END
    subi $t0, $t0, 256      # to correct that the pointer pointing the the first pixel
    lw $t6, 0($t0)          # load the current color from the top 
    lw $t7, 128($t0)
    lw $t8, 256($t0) 
    
    lw $s3, BLACK
    sw $s3, 0($t0)          # paint the first unit (i.e., top-left) red
    sw $s3, 128($t0)          # paint the second unit on the first row green
    sw $s3, 256($t0)

    addi $t0, $t0, 128
    sw $t6, 0($t0)          # paint the first unit (i.e., top-left) red
    sw $t7, 128($t0)          # paint the second unit on the first row green
    sw $t8, 256($t0)
    addi $t0, $t0, 256
    
    SHIFT_DOWN_END:
    
    move $v0, $t0
    jr $ra

pause_for_next_p:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    
# $a1 is x
# $a2 is y
# a3 is the length for each segment of line
draw_pasued:
    lw $t9, RED                     # set up color
    move $s6, $t3

    addi $a1, $zero, 3
    move $a2, $zero
    addi $a3, $zero, 3
    # draw P
    jal draw_horizontal_line
    jal draw_vertical_line
    addi $a2, $a2, 2
    jal draw_vertical_line
    jal draw_horizontal_line
    addi $a2, $a2, -2
    addi $a1, $a1, 2
    jal draw_vertical_line
    addi $a1, $a1, -2
    
    # space for each word
    addi $a1, $a1, 4
    
    # draw A
    jal draw_horizontal_line
    jal draw_vertical_line
    addi $a1, $a1, 2
    jal draw_vertical_line
    addi $a2, $a2, 2
    jal draw_vertical_line
    addi $a1, $a1, -2
    jal draw_horizontal_line
    jal draw_vertical_line
    addi $a2, $a2, 2
    addi $a2, $a2, -4
    
    # space for each word
    addi $a1, $a1, 4
    
    # draw U

    jal draw_vertical_line
    addi $a1, $a1, 2
    jal draw_vertical_line
    addi $a2, $a2, 2
    jal draw_vertical_line
    addi $a1, $a1, -2
    jal draw_vertical_line
    addi $a2, $a2, 2
    jal draw_horizontal_line
    addi $a2, $a2, -4
    
    # space for each word
    addi $a1, $a1, 4
    
    # draw S
    jal draw_vertical_line
    jal draw_horizontal_line            # draw three horizontal line first
    addi $a2, $a2, 2
    jal draw_horizontal_line
    addi $a2, $a2, 2
    jal draw_horizontal_line            # (x, y) at the most bottom-left
    addi $a1, $a1, 2
    addi $a2, $a2, -2
    jal draw_vertical_line
    addi $a1, $a1, -2
    addi $a2, $a2, -2
    
    # space for each word
    addi $a1, $a1, 4
    
    # draw E
    jal draw_horizontal_line            # draw three horizontal line first
    addi $a2, $a2, 2
    jal draw_horizontal_line
    addi $a2, $a2, 2
    jal draw_horizontal_line            # (x, y) at the most bottom-left
    addi $a2, $a2, -2
    jal draw_vertical_line
    addi $a2, $a2, -2
    jal draw_vertical_line
    
    # space for each word
    addi $a1, $a1, 4
    
    # draw D
    jal draw_vertical_line
    addi $a3, $zero, 2
    jal draw_horizontal_line
    addi $a2, $a2, 2
    addi $a3, $zero, 3
    jal draw_vertical_line
    addi $a3, $zero, 2
    addi $a2, $a2, 2
    jal draw_horizontal_line
    addi $a2, $a2, -3
    addi $a1, $a1, 2
    addi $a3, $zero, 3
    jal draw_vertical_line
    
wait_till_next_input:
    lw $t9, ADDR_KBRD                   
    lw $t8, 0($t9)                      # load to see if the keyboard is pressed
    beq $t8, 1, check_second_input      # If first word 1, key is pressed
    j wait_till_next_input
    
    
check_second_input:
    lw $t8, 4($t9)                      # load the input
    beq $t8, 0x70, pause_end            # if p is pressed second time, end pausing
    j pause_for_next_p                  # otherwise, keep wait till next p
    

pause_end:

remove_draw_pasued:
    lw $t9, BLACK                     # set up color
    # draw P
    addi $a1, $zero, 3
    move $a2, $zero
    addi $a3, $zero, 3
    
    jal draw_horizontal_line
    jal draw_vertical_line
    addi $a2, $a2, 2
    jal draw_vertical_line
    jal draw_horizontal_line
    addi $a2, $a2, -2
    addi $a1, $a1, 2
    jal draw_vertical_line
    addi $a1, $a1, -2
    
    # space for each word
    addi $a1, $a1, 4
    
    # draw A
    jal draw_horizontal_line
    jal draw_vertical_line
    addi $a1, $a1, 2
    jal draw_vertical_line
    addi $a2, $a2, 2
    jal draw_vertical_line
    addi $a1, $a1, -2
    jal draw_horizontal_line
    jal draw_vertical_line
    addi $a2, $a2, 2
    addi $a2, $a2, -4
    
    # space for each word
    addi $a1, $a1, 4
    
    # draw U

    jal draw_vertical_line
    addi $a1, $a1, 2
    jal draw_vertical_line
    addi $a2, $a2, 2
    jal draw_vertical_line
    addi $a1, $a1, -2
    jal draw_vertical_line
    addi $a2, $a2, 2
    jal draw_horizontal_line
    addi $a2, $a2, -4
    
    # space for each word
    addi $a1, $a1, 4
    
    # draw S
    jal draw_vertical_line
    jal draw_horizontal_line            # draw three horizontal line first
    addi $a2, $a2, 2
    jal draw_horizontal_line
    addi $a2, $a2, 2
    jal draw_horizontal_line            # (x, y) at the most bottom-left
    addi $a1, $a1, 2
    addi $a2, $a2, -2
    jal draw_vertical_line
    addi $a1, $a1, -2
    addi $a2, $a2, -2
    
    # space for each word
    addi $a1, $a1, 4
    
    # draw E
    jal draw_horizontal_line            # draw three horizontal line first
    addi $a2, $a2, 2
    jal draw_horizontal_line
    addi $a2, $a2, 2
    jal draw_horizontal_line            # (x, y) at the most bottom-left
    addi $a2, $a2, -2
    jal draw_vertical_line
    addi $a2, $a2, -2
    jal draw_vertical_line
    
    # space for each word
    addi $a1, $a1, 4
    
    # draw D
    jal draw_vertical_line
    addi $a3, $zero, 2
    jal draw_horizontal_line
    addi $a2, $a2, 2
    addi $a3, $zero, 3
    jal draw_vertical_line
    addi $a3, $zero, 2
    addi $a2, $a2, 2
    jal draw_horizontal_line
    addi $a2, $a2, -3
    addi $a1, $a1, 2
    addi $a3, $zero, 3
    jal draw_vertical_line
    
    

    move $v0, $t0
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    move $t3, $s6
    jr $ra
    
### FUNCTION: FILL STACK
### Loop through the grid and flag which pixels need to be removed
### Args: None
### Returns: ($v0) stack size
FILL_STACK:
la $s6, TO_CLEAR_STACK
li $s2, 0 # STACK SIZE

# OUTER_LOOP
lw $s0, Y_MAX # MAXIMUM Y counter
li $t4, 0 # Y counter
lw $t7, BOTTOM_LEFT # POINTER
FILL_Y_LOOP: beq $t4, $s0, END_FILL_Y_LOOP

li $t5, 0 # count empty pixels for early return
lw $s1, X_MAX # MAXIMUM X counter
li $t6, 0 # X counter

FILL_X_LOOP: beq $t6, $s1, END_FILL_X_LOOP

lw $s3 0($t7) # Current Colour
beq $s3, $zero, END_ROW # IF BLACK QUIT EARLY

lw $s4 -128($t7) # Colour one above current
CHECK_COL1: bne $s3, $s4, END_COL # IF NO MATCH SKIP

lw $s5 -256($t7) # Colour two above current
CHECK_COL2: bne $s4, $s5, END_COL # IF NO MATCH SKIP

move $s7, $t7 # GET POINTER TO REMOVE VALUES

# PUSH CURRENT
sll $t9, $s2, 2 # GET OFFSET FOR STACK POINTER
addu $t9, $t9, $s6 # GET PLACE TO PUT NEW VALUE
sw $s7, 0($t9) # PUSH

# DO THIS TWICE MORE
addiu $s7, $s7, -128 # UP 1
addiu $t9, $t9, 4 # FREE SPACE
sw $s7, 0($t9) # PUSH

addiu $s7, $s7, -128 # UP 1
addiu $t9, $t9, 4 # FREE SPACE
sw $s7, 0($t9) # PUSH

addiu $s2, $s2, 3 # UPDATE STACK SIZE

END_COL:

lw $s3 0($t7) # Current Colour
beq $s3, $zero, END_ROW # IF BLACK QUIT EARLY

lw $s4 -124($t7) # Colour one right diag from current
CHECK_RDIAG1: bne $s3, $s4, END_RDIAG # IF NO MATCH SKIP

lw $s5 -248($t7) # Colour two right diag from current
CHECK_RDIAG2: bne $s4, $s5, END_RDIAG # IF NO MATCH SKIP

move $s7, $t7 # GET POINTER TO REMOVE VALUES

# PUSH CURRENT
sll $t9, $s2, 2 # GET OFFSET FOR STACK POINTER
addu $t9, $t9, $s6 # GET PLACE TO PUT NEW VALUE
sw $s7, 0($t9) # PUSH

# DO THIS TWICE MORE
addiu $s7, $s7, -124 # DIAG 1
addiu $t9, $t9, 4 # FREE SPACE
sw $s7, 0($t9) # PUSH

addiu $s7, $s7, -124 # DIAG 1
addiu $t9, $t9, 4 # FREE SPACE
sw $s7, 0($t9) # PUSH

addiu $s2, $s2, 3 # UPDATE STACK SIZE

END_RDIAG:

lw $s3 0($t7) # Current Colour
beq $s3, $zero, END_ROW # IF BLACK QUIT EARLY

lw $s4 -132($t7) # Colour one left diag from current
CHECK_LDIAG1: bne $s3, $s4, END_LDIAG # IF NO MATCH SKIP

lw $s5 -264($t7) # Colour two left diag from current
CHECK_LDIAG2: bne $s4, $s5, END_LDIAG # IF NO MATCH SKIP

move $s7, $t7 # GET POINTER TO REMOVE VALUES

# PUSH CURRENT
sll $t9, $s2, 2 # GET OFFSET FOR STACK POINTER
addu $t9, $t9, $s6 # GET PLACE TO PUT NEW VALUE
sw $s7, 0($t9) # PUSH

# DO THIS TWICE MORE
addiu $s7, $s7, -132 # DIAG 1
addiu $t9, $t9, 4 # FREE SPACE
sw $s7, 0($t9) # PUSH

addiu $s7, $s7, -132 # DIAG 1
addiu $t9, $t9, 4 # FREE SPACE
sw $s7, 0($t9) # PUSH

addiu $s2, $s2, 3 # UPDATE STACK SIZE

END_LDIAG:

lw $s3 0($t7) # Current Colour
beq $s3, $zero, END_ROW # IF BLACK QUIT EARLY

lw $s4 4($t7) # Colour one row from current
CHECK_ROW1: bne $s3, $s4, END_ROW # IF NO MATCH SKIP

lw $s5 8($t7) # Colour two row from current
CHECK_ROW2: bne $s4, $s5, END_ROW # IF NO MATCH SKIP

move $s7, $t7 # GET POINTER TO REMOVE VALUES

# PUSH CURRENT
sll $t9, $s2, 2 # GET OFFSET FOR STACK POINTER
addu $t9, $t9, $s6 # GET PLACE TO PUT NEW VALUE
sw $s7, 0($t9) # PUSH

# DO THIS TWICE MORE
addiu $s7, $s7, 4 # across 1
addiu $t9, $t9, 4 # FREE SPACE
sw $s7, 0($t9) # PUSH

addiu $s7, $s7, 4 # across 1
addiu $t9, $t9, 4 # FREE SPACE
sw $s7, 0($t9) # PUSH

addiu $s2, $s2, 3 # UPDATE STACK SIZE

END_ROW:

addiu $t6, $t6, 1 # INCREMENT X COUNTER
addiu $t7, $t7, 4 # MOVE POINTER OVER
bne $s3, $zero, FILL_X_LOOP
addiu $t5, $t5, 1
j FILL_X_LOOP
END_FILL_X_LOOP:

beq $t5, $s1, END_FILL_Y_LOOP # If all black row can stop
# Increment
addiu $t4, $t4, 1 # Y COUNTER ++
sll $t8, $t4, 7 # GET NEW HEIGHT
lw $t7, BOTTOM_LEFT # RESET X
subu $t7, $t7, $t8 # SHIFT Y UP

j FILL_Y_LOOP

END_FILL_Y_LOOP:

move $v0, $s2
jr $ra

### FUNCTION: CLEAR STACK
### Pop stack and remove flagged colours
### Args: ($a0) stack size
CLEAR_STACK:
move $s0, $a0 # STACK SIZE
la $s1, TO_CLEAR_STACK # STACK POINTER

CLEAR_LOOP: beq $s0, $zero, CLEARED
addiu $t6, $s0, -1 # GET CORRECT INDEX
sll $t6, $t6, 2 # GET OFFSET
addu $t6, $t6, $s1 # GET POINTER TO CUR
lw $t7 0($t6) # GET STACK ELEMENT
sw $zero 0($t6) # CLEAR VALUE
sw $zero 0($t7) # PAINT PIXEL IN ADDRESS BLACK
addiu $s0, $s0, -1 # DECREMENT COUNTER
j CLEAR_LOOP

CLEARED:
jr $ra

### SHIFT DOWN
### SHIFT BLOCKS DOWN AFTER REMOVING COLLISIONS
### NO ARGUMENTS OR RETURN VALUES
SHIFT_DOWN:
lw $s2 GREY # CONST

# OUTER_LOOP
lw $s0, Y_MAX # MAXIMUM Y counter
li $t4, 0 # Y counter
lw $t7, BOTTOM_LEFT # POINTER
SHIFT_Y_LOOP: beq $t4, $s0, END_SHIFT_Y_LOOP

li $t5, 0 # count empty pixels for early return
lw $s1, X_MAX # MAXIMUM X counter
li $t6, 0 # X counter

SHIFT_X_LOOP: beq $t6, $s1, END_SHIFT_X_LOOP

move $t8, $t7

CHECK_SHIFT:
lw $s3 0($t8) # Current Colour

lw $s4 128($t8) # Colour one below current

TO_SHIFT1: beq $s3, $zero, NO_SHIFT # CHECK THAT CUR COLOUR IS NOT BLACK
TO_SHIFT2: beq $s3 , $s2, NO_SHIFT # CHECK THAT CUR COLOUR IS NOT GREY
TO_SHIFT3: bne $s4 , $zero, NO_SHIFT # CHECK THAT BELOW COLOUR IS BLACK
# Swap to produce shift
sw $s4 0($t8)
sw $s3 128($t8)

addiu $t8, $t8, 128
j CHECK_SHIFT

NO_SHIFT:

addiu $t6, $t6, 1 # INCREMENT X COUNTER
addiu $t7, $t7, 4 # MOVE POINTER OVER
j SHIFT_X_LOOP
END_SHIFT_X_LOOP:

# Increment
addiu $t4, $t4, 1 # Y COUNTER ++
sll $t8, $t4, 7 # GET NEW HEIGHT
lw $t7, BOTTOM_LEFT # RESET X
subu $t7, $t7, $t8 # SHIFT Y UP

j SHIFT_Y_LOOP

END_SHIFT_Y_LOOP:
jr $ra




### FUNCTION: DISPLAY SCORE ###
# $a0 will be the score, dont tocuh this one
# $a1 will be the x location
# $a2 will be the y location



    
display_score:

clean_score_display:
    move $a1, $zero
    addi $a1, $a1, 17
    move $a2, $zero
    addi $a2, $a2, 16
    move $a3, $zero
    addi $a3, $a3, 15
    lw $t9, BLACK
    move $t6, $zero             # clean_up counter
clean_up_loop:
    jal draw_horizontal_line
    addi $t6, $t6, 1
    addi $a2, $a2, 1
    bne $t6, 7, clean_up_loop
    
    lw $t2, GAME_POINT
    move $s4, $t2
    jal display_score_init
    
draw_next_digit:
    li $t1, 10 
    # show the least significant digit one by one, by dividing 10 
    div $s4, $t1
    mfhi $s3                    # store the remainder in $t3, the last digit
    mflo $s4                    # store the digits left in $t2
    lw $t9, RED
    beq $s3, 0, draw_zero
    beq $s3, 1, draw_one
    beq $s3, 2, draw_two
    beq $s3, 3, draw_three
    beq $s3, 4, draw_four
    beq $s3, 5, draw_five
    beq $s3, 6, draw_six
    beq $s3, 7, draw_seven
    beq $s3, 8, draw_eight
    beq $s3, 9, draw_nine
    
after_draw:
    # jal display_score_init
    addi $a1, $a1, -5
    bne $s4, 0, draw_next_digit
    j tem_to_retrun

    
    
    
# initialize $a1, $a2 to the correct coordinate
display_score_init:

    move $a1, $zero                 
    move $a2, $zero
    add $a1, $zero, 27              # x offset
    add $a2, $zero, 16              # y offset
    move $a3, $zero
    add $a3, $a3, 4                 # set the length to 4
    jr $ra
    
# always start from the top-left of that digit
draw_zero:

    jal draw_horizontal_line
    jal draw_vertical_line
    addi $a1, $a1, 3
    jal draw_vertical_line
    addi $a2, $a2, 3
    jal draw_vertical_line
    addi $a1, $a1, -3
    jal draw_vertical_line
    addi $a2, $a2, 3
    jal draw_horizontal_line
    addi $a2, $a2, -6
    j after_draw
    
draw_one:

    addi $a1, $a1, 3
    jal draw_vertical_line
    addi $a2, $a2, 3
    jal draw_vertical_line
    addi $a2, $a2, -3
    addi $a1, $a1, -3
    j after_draw
        
draw_two:

    jal draw_horizontal_line            # draw three horizontal line first
    addi $a2, $a2, 3
    jal draw_horizontal_line
    addi $a2, $a2, 3
    jal draw_horizontal_line            # (x, y) at the most bottom-left
    addi $a2, $a2, -3
    jal draw_vertical_line              # draw the other two vertical line
    addi $a2, $a2, -3
    addi $a1, $a1, 3
    jal draw_vertical_line
    addi $a1, $a1, -3
    j after_draw
draw_three:

    jal draw_horizontal_line            # draw three horizontal line first
    addi $a2, $a2, 3
    jal draw_horizontal_line
    addi $a2, $a2, 3
    jal draw_horizontal_line            # (x, y) at the most bottom-left
    addi $a2, $a2, -3
    addi $a1, $a1, 3
    jal draw_vertical_line
    addi $a2, $a2, -3
    jal draw_vertical_line
    addi $a1, $a1, -3
    j after_draw
    
draw_four:

    jal draw_vertical_line
    addi $a2, $a2, 3
    jal draw_horizontal_line
    addi $a2, $a2, -3
    addi $a1, $a1, 3
    jal draw_vertical_line
    addi $a2, $a2, 3
    jal draw_vertical_line
    addi $a2, $a2, -3
    addi $a1, $a1, -3
    j after_draw
    
draw_five:

    jal draw_vertical_line
    jal draw_horizontal_line            # draw three horizontal line first
    addi $a2, $a2, 3
    jal draw_horizontal_line
    addi $a2, $a2, 3
    jal draw_horizontal_line            # (x, y) at the most bottom-left
    addi $a1, $a1, 3
    addi $a2, $a2, -3
    jal draw_vertical_line
    addi $a1, $a1, -3
    addi $a2, $a2, -3
    j after_draw
draw_six:

    jal draw_vertical_line              
    addi $a2, $a2, 3
    jal draw_vertical_line
    addi $a2, $a2, -3
    jal draw_horizontal_line            # draw three horizontal line first
    addi $a2, $a2, 3
    jal draw_horizontal_line
    addi $a2, $a2, 3
    jal draw_horizontal_line            # (x, y) at the most bottom-left
    addi $a2, $a2, -3
    addi $a1, $a1, 3
    jal draw_vertical_line
    addi $a1, $a1, -3
    addi $a2, $a2, -3
    j after_draw
draw_seven:

    jal draw_horizontal_line
    addi $a1, $a1, 3
    jal draw_vertical_line
    addi $a2, $a2, 3
    jal draw_vertical_line
    addi $a1, $a1, -3
    addi $a2, $a2, -3
    j after_draw
draw_eight:

    jal draw_horizontal_line
    jal draw_vertical_line
    addi $a1, $a1, 3
    jal draw_vertical_line
    addi $a2, $a2, 3
    jal draw_vertical_line
    addi $a1, $a1, -3
    jal draw_horizontal_line
    jal draw_vertical_line
    addi $a2, $a2, 3
    jal draw_horizontal_line
    addi $a2, $a2, -6
    j after_draw
    
draw_nine:

    jal draw_horizontal_line
    jal draw_vertical_line
    addi $a2, $a2, 3
    jal draw_horizontal_line
    addi $a2, $a2, -3
    addi $a1, $a1, 3
    jal draw_vertical_line
    addi $a2, $a2, 3
    jal draw_vertical_line
    addi $a1, $a1, -3
    addi $a2, $a2, -3
    j after_draw
 


# s1 is the location for top-left pixel
# a1 is x coordinate, do not modify it
# a2 is y coordinate, do not modify it
# a3 is the length, do not modify it
# any modificaation stored in corresponding $t register
draw_vertical_line:                         # citation: part of this function is from class demo
    lw $s1, displayaddress
    sll $t1, $a1, 2                         # multiply the X coordinate by 4 to get the horizontal offset, stored in $t1
    add $t4, $s1, $t1                       # add this horizontal offset to $s1, store the result in $t4
    sll $t2, $a2, 7                         # multiply the Y coordinate by 128 to get the vertical offset, stored in $t2
    add $t4, $t4, $t2                       # add this vertical offset to $t4, store the result in $t4

    # Make a loop to draw a line.
    sll $t3, $a3, 7                         # calculate the difference between the starting value for $t4 and the end value.
    add $t5, $t4, $t3                       # set stopping location for $t4
    vertical_line_loop_start:
    beq $t4, $t5, vertical_line_loop_end    # check if $t0 has reached the final location of the line

    sw $t9, 0( $t4 )                        # paint the current pixel red
    addi $t4, $t4, 128                      # move $t0 to the next pixel in the row.
    j vertical_line_loop_start              # jump to the start of the loop
vertical_line_loop_end:
    jr $ra    

# s1 is the location for top-left pixel
# a1 is x coordinate, do not modify it
# a2 is y coordinate, do not modify it
# a3 is the length, do not modify it
# any modificaation stored in corresponding $t register
draw_horizontal_line:                       # citation: part of this function is from class demo
    lw $s1, displayaddress
    sll $t1, $a1, 2                         # multiply the X coordinate by 4 to get the horizontal offset, stored in $t1
    add $t4, $s1, $t1                       # add this horizontal offset to $s1, store the result in $t4
    sll $t2, $a2, 7                         # multiply the Y coordinate by 128 to get the vertical offset, stored in $t2
    add $t4, $t4, $t2                       # add this vertical offset to $t4, store the result in $t4
    
    # Make a loop to draw a line.
    sll $t3, $a3, 2                         # calculate the difference between the starting value for $t4 and the end value.
    add $t5, $t4, $t3                       # set stopping location for $t4
horizontal_line_loop_start:
    beq $t4, $t5, horizontal_line_loop_end  # check if $t0 has reached the final location of the line
    
    sw $t9, 0( $t4 )                        # paint the current pixel red
    addi $t4, $t4, 4                        # move $t0 to the next pixel in the row.
    j horizontal_line_loop_start            # jump to the start of the loop
horizontal_line_loop_end:
    jr $ra

draw_diagonal_line:                         # citation: part of this function is from class demo
    lw $s1, displayaddress
    sll $t1, $a1, 2                         # multiply the X coordinate by 4 to get the horizontal offset, stored in $t1
    add $t4, $s1, $t1                       # add this horizontal offset to $s1, store the result in $t4
    sll $t2, $a2, 7                         # multiply the Y coordinate by 128 to get the vertical offset, stored in $t2
    add $t4, $t4, $t2                       # add this vertical offset to $t4, store the result in $t4
    
    # Make a loop to draw a line.
    mult $t3, $a3, 132                      # calculate the difference between the starting value for $t4 and the end value.
    add $t5, $t4, $t3                       # set stopping location for $t4
diagona_line_loop_start:
    beq $t4, $t5, diagona_line_loop_end     # check if $t0 has reached the final location of the line
    
    sw $t9, 0( $t4 )                        # paint the current pixel red
    addi $t4, $t4, 132                      # move $t0 to the next pixel in the row.
    j diagona_line_loop_start               # jump to the start of the loop
diagona_line_loop_end:
    jr $ra     

update_wait_cycle:

    lw $t1, DIFFICULTY_LEVEL
    lw $t2, GAME_POINT
    srl $t2, $t2, 2                 # divide the score by 4
    mul $t2, $t2, $t1               # DIFFICULTY_LEVEL * (GAME_POINT //8), stored in $t2
    li $t3, 100                     # initial wait cycles
    sll $t1, $t1, 3                 # 8 * DIFFICULTY_LEVEL
    sub $t3, $t3, $t1               # 100 - 8 * DIFFICULTY_LEVEL - DIFFICULTY_LEVEL
    sub $t3, $t3, $t2               # 100 - 8 * DIFFICULTY_LEVEL - DIFFICULTY_LEVEL * (GAME_POINT //8)
    li $t4, 10
    blt $t3, $t4, max_sped_reached
    sw $t3, WAIT_CYCLE
max_sped_reached:
    jr $ra


game_over:

### clean Bipmap ### 
    # __init__
    move $a1, $zero                 
    move $a2, $zero
    add $a3, $zero, 32                 # set the length to 32
    move $t8, $zero
    lw $t9, BLACK
    
clean_loop:
    beq $t8, 31, finish_cleaning
    jal draw_horizontal_line
    addi $a2, $a2, 1
    addi $t8, $t8, 1
    j clean_loop

finish_cleaning:
    # 1. display GAME OVER
    
    # setup display location 
    move $a1, $zero                 
    move $a2, $zero
    add $a1, $zero, 5              # x offset
    add $a2, $zero, 7              # y offset
    move $a3, $zero
    add $a3, $a3, 4                 # set the length to 4
    lw $t9, RED
    
    # draw G
    jal draw_horizontal_line
    jal draw_vertical_line
    addi $a1, $a1, 3
    addi $a2, $a2, 3
    jal draw_vertical_line
    addi $a1, $a1, -3
    jal draw_horizontal_line
    jal draw_vertical_line
    addi $a2, $a2, 3
    jal draw_horizontal_line
    addi $a2, $a2, -6
    
    # space for each word
    addi $a1, $a1, 5
    
    # draw A
    jal draw_horizontal_line
    jal draw_vertical_line
    addi $a1, $a1, 3
    jal draw_vertical_line
    addi $a2, $a2, 3
    jal draw_vertical_line
    addi $a1, $a1, -3
    jal draw_horizontal_line
    jal draw_vertical_line
    addi $a2, $a2, 3
    addi $a2, $a2, -6
    
    # space for each word
    addi $a1, $a1, 5
    
    # draw M
    jal draw_horizontal_line
    jal draw_vertical_line
    addi $a1, $a1, 3
    jal draw_vertical_line
    addi $a2, $a2, 3
    jal draw_vertical_line
    addi $a1, $a1, -3
    jal draw_vertical_line
    addi $a2, $a2, 3
    addi $a2, $a2, -6
    addi $a1, $a1, 3
    jal draw_horizontal_line
    jal draw_vertical_line
    addi $a1, $a1, 3
    jal draw_vertical_line
    addi $a2, $a2, 3
    jal draw_vertical_line
    addi $a1, $a1, -3
    jal draw_vertical_line
    addi $a2, $a2, 3
    addi $a2, $a2, -6
    
    # space for each word
    addi $a1, $a1, 5
    
    # draw E
    jal draw_horizontal_line            # draw three horizontal line first
    addi $a2, $a2, 3
    jal draw_horizontal_line
    addi $a2, $a2, 3
    jal draw_horizontal_line            # (x, y) at the most bottom-left
    addi $a2, $a2, -3
    jal draw_vertical_line
    addi $a2, $a2, -3
    jal draw_vertical_line
    
    # space for next line
    add $a1, $zero, 5              # x offset
    add $a2, $zero, 19              # y offset
    
    # draw O
    jal draw_horizontal_line
    jal draw_vertical_line
    addi $a1, $a1, 3
    jal draw_vertical_line
    addi $a2, $a2, 3
    jal draw_vertical_line
    addi $a1, $a1, -3
    jal draw_vertical_line
    addi $a2, $a2, 3
    jal draw_horizontal_line
    addi $a2, $a2, -6
    
    # space for each word
    addi $a1, $a1, 5
    
    # draw U
    jal draw_vertical_line
    addi $a1, $a1, 3
    jal draw_vertical_line
    addi $a2, $a2, 3
    jal draw_vertical_line
    addi $a1, $a1, -3
    jal draw_vertical_line
    addi $a2, $a2, 3
    jal draw_horizontal_line
    addi $a2, $a2, -6
    
    # space for each word
    addi $a1, $a1, 5
    
    # draw E
    jal draw_horizontal_line
    addi $a2, $a2, 3
    jal draw_horizontal_line
    addi $a2, $a2, 3
    jal draw_horizontal_line
    addi $a2, $a2, -3
    jal draw_vertical_line
    addi $a2, $a2, -3
    jal draw_vertical_line
    
    # space for each word
    addi $a1, $a1, 5
    
    # draw R
    jal draw_horizontal_line
    jal draw_vertical_line
    addi $a2, $a2, 3
    jal draw_vertical_line
    jal draw_horizontal_line
    addi $a2, $a2, -3
    addi $a1, $a1, 3
    jal draw_vertical_line
    addi $a1, $a1, -3
    addi $a2, $a2, 3
    jal draw_diagonal_line
    
    # 2. press R retry 
    move $t1, $zero                 # time counter
    addi $a0, $zero, 1000
    addi $v0, $zero, 32
    
        
press_r_retry:
    addi $t1, $t1, 1                # incr the time by 1
    lw $t9, ADDR_KBRD               # $t9 = base address for keyboard
    lw $t8, 0($t9)                  # Load first word from keyboard
    beq $t8, 1, check_if_its_r      # If first word 1, key is pressed
    beq $t1, 10, EXIT               # after wating 10 sec, exit\
    syscall
    j press_r_retry
    

check_if_its_r:
    lw $t5, 4($t9)                  # Load second word from keyboard
    beq $t5, 0x72, set_up_retry     # Check if the key r was pressed
    j press_r_retry


set_up_retry:                 
    move $a1, $zero                 
    move $a2, $zero
    add $a3, $zero, 32                 # set the length to 32
    move $t8, $zero
    lw $t9, BLACK
    
clean_up_game_over:
    beq $t8, 31, reset_variables
    jal draw_horizontal_line
    addi $a2, $a2, 1
    addi $t8, $t8, 1
    j clean_up_game_over

reset_variables:
    li $t1, 100
    sw $t1, WAIT_CYCLE
    sw $zero, GAME_POINT
    j re_start_the_game

EXIT: 
li $v0, 10
syscall