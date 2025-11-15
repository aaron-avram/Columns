.data
displayaddress:     .word       0x10008000
RED: .word 0xff0000
YELLOW: .word 0xffff00
BLUE: .word 0x0000ff
GREY: .word 0x808080
BLACK: .word 0x000000
X_MAX: .word 10
Y_MAX: .word 18
WAITLIST_START: .word 0x100085d8
COLUMN_START: .word 0x100083a4
BOTTOM_LEFT: .word 0x10008c90
ADDR_KBRD: .word 0xffff0000

TO_CLEAR_STACK: .space 400

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












### MAIN LOOP WHERE GAME IS PLAYED


MAIN_LOOP: 

# SET SHIFT PARAMETERS
move $a0, $t0 # LOCATION TO SHIFT FROM
li $a1, 3 # SIZE OF SHIFT
jal SHIFT # CALL SHIFT
move $t0, $v0 # GET NEW POINTER
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
beq $t3, 25, MAIN_LOOP        # if it waits (or loops) 100 times, then move on to next shifting

j NO_COLLISION

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
main_run:
    move $t0, $a0
    lw $t9, ADDR_KBRD               # $t0 = base address for keyboard
    lw $t8, 0($t9)                  # Load first word from keyboard
    beq $t8, 1, keyboard_input      # If first word 1, key is pressed
    move $v0, $t0
    jr $ra

# this is to react to what the keyboard is pressed
keyboard_input:                     # A key is pressed
    lw $t5, 4($t9)                  # Load second word from keyboard
    beq $t5, 0x73, shuffle     # Check if the key q was pressed
    beq $t5, 0x61, shiftL
    beq $t5, 0x64, shiftR

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

EXIT: 
lw $t0, displayaddress # Store Column Pointer in $t0