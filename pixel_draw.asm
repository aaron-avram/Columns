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

addu $s3, $t0, $zero # Store waitlist pointer in $s3

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
addiu $t4, $zero, 3 # Counter

WAIT_LOOP: beq $t3, $t4, WAIT_END

li $v0, 42
li $a0, 0
li $a1, 3
syscall # Generate random colour

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

move $s4, $t0 # Store column pointer base address (Maybe Memory)

#### STORAGE ####
# s0, s1, s2 --> Red Yellow Blue
# t0 --> Column pointer Cur Value
# s3 --> Waitlist pointer
# s4 --> Column pointer start value

li $v0, 10 # terminate the program gracefully
syscall