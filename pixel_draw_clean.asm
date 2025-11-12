.data
displayaddress:     .word       0x10008000

# ...

.text
# ...
li $t1, 0x808080 # $t1 = Grey
li $s0 0xff0000 #  $s0 = Red
li $s1 0xffff00 # $s1 = Yellow
li $s2 0x0000ff # s2 = Green

lw $t0, displayaddress # $t0 = base address for display

#### STORAGE ####
# s0, s1, s2 --> Red Yellow Blue
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

# Calculate X value for column pointer
sll $t1, $t4, 1
addiu $t1, $t1, 12

# Store X value
addu $t0, $t0, $t1

# Calculate Y value for column pointer
addiu $t1, $zero, 7 # Add an extra 1 to start in grid
sll $t1, $t1, 7

# Store Y value
addu $t0, $t0, $t1

move $s4, $t0 # Store column pointer base address (Maybe Memory)

##### MAIN MOVEMENT LOOP #####
jal REFILL_WAITLIST
jal DRAW_INIT
move $t0, $v0 # GET NEW POINTER

MAIN_LOOP: 

# SET SHIFT PARAMETERS
move $a0, $t0
li $a1, 3
jal SHIFT # CALL SHIFT
move $t0, $v0 # GET NEW POINTER

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

addu $s3, $s4, $zero # Store waitlist pointer in $s3 (First put column pointer

# Calculate X offset for waitlist pointer
sll $t1, $t4, 1
addiu $t1, $t1, 28

# Store X value
addu $s3, $s3, $t1

# Calculate Y offset for waitlist pointer
addiu $t1, $zero, 4 # Add an extra 1 to start in grid
sll $t1, $t1, 7

# Store Y value
addu $s3, $s3, $t1

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
sw $s0 0($t5)
j  GET_COL_END

GET_YELLOW:
sw $s1 0($t5)
j  GET_COL_END

GET_BLUE:
sw $s2 0($t5)
j  GET_COL_END

GET_COL_END:

addiu $t3, $t3, 1

j WAIT_LOOP
WAIT_END:

jr $ra

### FUNCTION ###
# Need a0, a1 to have colour and address respectively
DRAW_PIXEL: # DRAW SINGLE PIXEL

# LATER add a branch to flag collisions
sw $a0 0($a1)
jr $ra

### FUNCTION ###
DRAW_INIT: # DRAW TOP 3 PIXELS

# LATER add a branch to flag game over

### SETUP ###
li $t3, 3 # Max Iter
li $t4, 0 # Counter

### GET POINTER TO COLUMN
addiu $t2, $s4, -128

### GET POINTER TO WAITLIST
move $t7, $s3
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