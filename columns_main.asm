.data
displayaddress:     .word       0x10008000
RED: .word 0xff0000
YELLOW: .word 0xffff00
BLUE: .word 0x0000ff
GREY: .word 0x808080
WAITLIST_START: .word 0x100085d8
COLUMN_START: .word 0x100083a4

# ...

# FULLY DOCUMENT REGISTER USAGE

.text
# ...
li $t1, 0x808080 # $t1 = Grey
li $s5, 0x808080 # $t1 = Grey
li $s0 0xff0000 #  $s0 = Red
li $s1 0xffff00 # $s1 = Yellow
li $s2 0x0000ff # s2 = Green

lw $t0, displayaddress # $t0 = base address for display

#### STORAGE #### WILL MOVE THESE TO MEMORY
# s0, s1, s2 --> Red Yellow Blue
# s5 --> Grey
# t0 --> Column pointer Cur Value
# s3 --> Waitlist pointer
# s4 --> Column pointer start value

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
sw $t1, 0($t8)

addu $t8, $t8, $t7 # Offset by Y Max
sw $t1, 0($t8)

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
sw $t1, 0($t8)

addu $t8, $t8, $t7
sw $t1, 0($t8)

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

MAIN_LOOP: 

# SET SHIFT PARAMETERS
move $a0, $t0
li $a1, 3
jal SHIFT # CALL SHIFT
move $t0, $v0 # GET NEW POINTER
addu $t1, $t0, 128 # PEEK THE PIXEL BELOW POINTER

# GET COLOUR AT LOCATION $t0
lw $t2 0($t1)

# If pixel below is not empty then need to resolve collision
DETECT_COLLISION: beq $t2, $zero, NO_COLLISION
### DEAL WITH COLOURS THEN SCORING AND SUCH
lw $s5, GREY
DETECT_GREY: bne $t2, $s5, NOT_GREY
jal DRAW_INIT
move $t0, $v0 # GET NEW POINTER
jal REFILL_WAITLIST # SHOW NEXT BLOCK AFTER CURRENT

NOT_GREY:

NO_COLLISION:



li $v0, 32
li $a0, 1000
syscall

j MAIN_LOOP

##### TERMINATE #####
j EXIT

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
li $a1, 3
syscall # Generate random colour

# Constants
li $t1, 1
li $t2, 2

# Update position before branch
move $t5, $t3
sll $t5, $t5, 7

addu $t5, $t5, $s3

# Branch
beq $a0, $zero, GET_RED
beq $a0, $t1, GET_YELLOW
beq $a0, $t2, GET_BLUE

GET_RED:
lw $s0, RED
sw $s0 0($t5)
j  GET_COL_END

GET_YELLOW:
lw $s1, YELLOW
sw $s1 0($t5)
j  GET_COL_END

GET_BLUE:
lw $s2, BLUE
sw $s2 0($t5)
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
li $a0, 1000
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

EXIT: 
lw $t0, displayaddress # Store Column Pointer in $t0